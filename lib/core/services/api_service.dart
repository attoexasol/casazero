import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../auth/pending_2fa_policy.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../logging/diagnostic_logger.dart';
import 'session_expiry_service.dart';
import 'storage_service.dart';

class ApiService extends getx.GetxService {
  late Dio _dio;
  final StorageService _storageService = getx.Get.find();

  ApiService() {
    print('[ApiService] baseUrl=${ApiConstants.BASE_URL}');
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.BASE_URL,
        connectTimeout: const Duration(
          milliseconds: AppConstants.CONNECTION_TIMEOUT,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.RECEIVE_TIMEOUT,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.extra['_diag_start_ms'] =
              DateTime.now().millisecondsSinceEpoch;

          // While the login 2FA challenge is unfinished (pending2FA), the
          // stored token only proves the password step. Client-side, allow
          // only OTP send/verify and auth endpoints; reject everything else.
          if (_storageService.isPending2FA &&
              !Pending2FAPolicy.isAllowedEndpoint(options.path)) {
            print(
              '⛔ [API BLOCKED — pending 2FA] ${options.method} ${options.uri}',
            );
            DiagnosticLogger.instance.warning(
              'API ${options.method} ${_sanitizedEndpoint(options)}',
              metadata: <String, Object?>{
                'blocked_pending_2fa': true,
              },
            );
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                message: 'BLOCKED_PENDING_2FA',
              ),
            );
          }

          // Add access token to headers and log for debugging
          final token = _storageService.getAccessToken();

          // Ensure we always use the same token everywhere
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }

          print('🌐 [API REQUEST] ${options.method} ${options.uri}');
          print('🔑 [API TOKEN] ${token ?? 'NO_TOKEN_FOUND'}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logApiDiagnostics(
            response.requestOptions,
            statusCode: response.statusCode,
          );
          return handler.next(response);
        },
        onError: (error, handler) async {
          _logApiDiagnostics(
            error.requestOptions,
            statusCode: error.response?.statusCode,
            error: error,
          );
          if (error.response?.statusCode == 401 &&
              _shouldHandleSessionExpiry(error.requestOptions)) {
            if (await _refreshToken()) {
              return handler.resolve(await _retry(error.requestOptions));
            }

            await SessionExpiryService.handleSessionExpired();

            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: DioExceptionType.cancel,
                message: 'SESSION_EXPIRED',
              ),
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    DiagnosticLogger.instance.info('Token refresh started');
    try {
      final refreshToken = _storageService.getRefreshToken();
      if (refreshToken == null) {
        DiagnosticLogger.instance.warning(
          'Token refresh failed',
          metadata: <String, Object?>{'reason': 'no_refresh_token'},
        );
        return false;
      }

      final response = await _dio.post(
        ApiConstants.REFRESH_TOKEN,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        await _storageService.saveAccessToken(response.data['access_token']);
        await _storageService.saveRefreshToken(response.data['refresh_token']);
        DiagnosticLogger.instance.info('Token refresh completed');
        return true;
      }
      DiagnosticLogger.instance.warning(
        'Token refresh failed',
        metadata: <String, Object?>{'status': response.statusCode},
      );
      return false;
    } catch (e) {
      DiagnosticLogger.instance.error('Token refresh failed', error: e);
      return false;
    }
  }

  bool _shouldHandleSessionExpiry(RequestOptions options) {
    if (SessionExpiryService.isHandling || SessionExpiryService.isSigningOut) {
      return false;
    }
    if (_isAuthEndpoint(options.path)) return false;

    final authHeader = options.headers['Authorization']?.toString();
    if (authHeader == null || authHeader.isEmpty) return false;

    return _storageService.getAccessToken() != null;
  }

  bool _isAuthEndpoint(String path) {
    const authEndpoints = {
      ApiConstants.LOGIN,
      ApiConstants.LOGOUT,
      ApiConstants.REFRESH_TOKEN,
      ApiConstants.FORGOT_PASSWORD,
      ApiConstants.RESET_PASSWORD,
    };

    for (final endpoint in authEndpoints) {
      if (path == endpoint || path.endsWith(endpoint)) {
        return true;
      }
    }
    return false;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    // Ensure the latest token is attached on retry
    final freshToken = _storageService.getAccessToken();
    if (freshToken != null && freshToken.isNotEmpty) {
      requestOptions.headers['Authorization'] = 'Bearer $freshToken';
    } else {
      requestOptions.headers.remove('Authorization');
    }

    print('🔄 [API RETRY] ${requestOptions.method} ${requestOptions.uri}');
    print('🔑 [API RETRY TOKEN] ${freshToken ?? 'NO_TOKEN_FOUND'}');

    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // Generic GET request
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParams);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic POST request
  Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic PUT request
  Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic DELETE request
  Future<Response> delete(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.delete(endpoint, data: data);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    String errorMessage = 'An error occurred';

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      errorMessage =
          'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      // Log full error response for debugging (e.g. document upload failures)
      print('❌ [API ERROR RESPONSE] Status: $statusCode');
      print('❌ [API ERROR RESPONSE] Body: ${error.response?.data}');

      // Handle specific HTTP status codes
      if (statusCode == 403) {
        errorMessage = 'Access forbidden. Please check your permissions.';
      } else if (statusCode == 401) {
        errorMessage = 'Unauthorized. Please log in again.';
      } else if (statusCode == 404) {
        errorMessage = 'Resource not found.';
      } else if (statusCode != null && statusCode >= 500) {
        errorMessage = 'Server error. Please try again later.';
      }

      // Safely extract error message from response
      if (error.response?.data != null) {
        final responseData = error.response!.data;
        if (responseData is Map<String, dynamic>) {
          final extractedMessage =
              responseData['message'] ?? responseData['error'];
          if (extractedMessage is String) {
            errorMessage = extractedMessage;
          } else if (extractedMessage != null) {
            errorMessage = extractedMessage.toString();
          }
        } else if (responseData is String) {
          // Check if response is HTML (like 403 Forbidden page)
          if (responseData.trim().startsWith('<!DOCTYPE') ||
              responseData.trim().startsWith('<html')) {
            // Don't return HTML, use status code based message
            if (statusCode == 403) {
              errorMessage = 'Access forbidden. Please check your permissions.';
            } else if (statusCode == 401) {
              errorMessage = 'Unauthorized. Please log in again.';
            } else {
              errorMessage = 'Server returned an error. Please try again.';
            }
          } else {
            // Valid string error message
            errorMessage = responseData;
          }
        }
      }

      // Fallback if no specific message was set
      if (errorMessage == 'An error occurred') {
        errorMessage = 'Server error occurred';
      }
    } else if (error.type == DioExceptionType.cancel) {
      if (error.message == 'SESSION_EXPIRED' ||
          SessionExpiryService.isHandling) {
        errorMessage = 'Your session has expired. Please sign in again.';
      } else {
        errorMessage = 'Request cancelled';
      }
    } else {
      errorMessage = 'Network error. Please try again.';
    }

    return errorMessage;
  }

  String _sanitizedEndpoint(RequestOptions options) {
    var path = options.path;
    if (path.startsWith('http')) {
      try {
        path = Uri.parse(path).path;
      } catch (_) {}
    }
    final int queryIndex = path.indexOf('?');
    if (queryIndex >= 0) {
      path = path.substring(0, queryIndex);
    }
    return path;
  }

  int _requestDurationMs(RequestOptions options) {
    final Object? start = options.extra['_diag_start_ms'];
    if (start is int) {
      return DateTime.now().millisecondsSinceEpoch - start;
    }
    return 0;
  }

  void _logApiDiagnostics(
    RequestOptions options, {
    int? statusCode,
    DioException? error,
  }) {
    try {
      final String endpoint = _sanitizedEndpoint(options);
      final int durationMs = _requestDurationMs(options);
      final Map<String, Object?> meta = <String, Object?>{
        'status': statusCode,
        'duration_ms': durationMs,
      };

      if (error == null) {
        DiagnosticLogger.instance.info(
          'API ${options.method} $endpoint',
          metadata: meta,
        );
        return;
      }

      meta['error_type'] = error.type.name;
      meta['error'] = _safeNetworkError(error);
      DiagnosticLogger.instance.error(
        'API ${options.method} $endpoint',
        metadata: meta,
      );
    } catch (_) {}
  }

  String _safeNetworkError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Timeout';
      case DioExceptionType.connectionError:
        return 'Connection error';
      case DioExceptionType.badCertificate:
        return 'Bad certificate';
      case DioExceptionType.badResponse:
        final int? status = error.response?.statusCode;
        if (status == 401) return 'Unauthorized';
        if (status == 403) return 'Forbidden';
        if (status == 404) return 'Not found';
        if (status != null && status >= 500) return 'Server error';
        return 'Bad response';
      case DioExceptionType.cancel:
        return error.message ?? 'Cancelled';
      case DioExceptionType.unknown:
        return 'Network error';
    }
  }
}
