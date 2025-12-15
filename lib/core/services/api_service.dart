import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService extends getx.GetxService {
  late Dio _dio;
  final StorageService _storageService = getx.Get.find();

  ApiService() {
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
        onError: (error, handler) async {
          // Handle token refresh on 401
          if (error.response?.statusCode == 401) {
            if (await _refreshToken()) {
              // Retry the request
              return handler.resolve(await _retry(error.requestOptions));
            }
            // Refresh failed - clear stale tokens
            await _storageService.clearAccessToken();
            await _storageService.clearRefreshToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = _storageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiConstants.REFRESH_TOKEN,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        await _storageService.saveAccessToken(response.data['access_token']);
        await _storageService.saveRefreshToken(response.data['refresh_token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
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
     
      print(data);
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
  Future<Response> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
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
      errorMessage = error.response?.data['message'] ?? 'Server error occurred';
    } else if (error.type == DioExceptionType.cancel) {
      errorMessage = 'Request cancelled';
    } else {
      errorMessage = 'Network error. Please try again.';
    }

    return errorMessage;
  }
}
