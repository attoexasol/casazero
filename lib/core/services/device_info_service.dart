// core/services/device_info_service.dart

import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

// WEB / PLATFORM SUPPORT
import 'package:flutter/foundation.dart' show kIsWeb;
// This is safe – just don't call Platform.* when kIsWeb == true
import 'dart:io' show Platform;

class DeviceInfoService extends GetxService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// -------------------------------
  /// DEVICE ID
  /// -------------------------------
  Future<String> getDeviceId() async {
    try {
      if (kIsWeb) {
        // Simple stable ID for web – adjust if you need something fancier
        return 'web-device';
      }

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id ??
            'unknown-android-${DateTime.now().millisecondsSinceEpoch}';
      }

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ??
            'unknown-ios-${DateTime.now().millisecondsSinceEpoch}';
      }

      return 'unknown-${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('Error getting device ID: $e');
      return 'unknown-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// -------------------------------
  /// DEVICE NAME
  /// -------------------------------
  Future<String> getDeviceName() async {
    try {
      if (kIsWeb) {
        return 'Web Browser';
      }

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      }

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      }

      return 'Unknown Device';
    } catch (e) {
      print('Error getting device name: $e');
      return 'Unknown Device';
    }
  }

  /// -------------------------------
  /// PLATFORM
  /// -------------------------------
  String getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// -------------------------------
  /// LOCATION
  /// -------------------------------
  Future<Map<String, double>> getLocation() async {
    if (kIsWeb) {
      // No GPS on web (unless using browser API explicitly)
      return {'lat': 0.0, 'lng': 0.0};
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return {'lat': 0.0, 'lng': 0.0};

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'lat': 0.0, 'lng': 0.0};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {'lat': 0.0, 'lng': 0.0};
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return {
        'lat': position.latitude,
        'lng': position.longitude,
      };
    } catch (e) {
      print('Error getting location: $e');
      return {'lat': 0.0, 'lng': 0.0};
    }
  }

  /// -------------------------------
  /// IP ADDRESS
  /// -------------------------------
  Future<String> getIPAddress() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ip'] ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      print('Error getting IP address: $e');
      return 'unknown';
    }
  }

  /// -------------------------------
  /// DEVICE INFO BUNDLE
  /// -------------------------------
  Future<Map<String, dynamic>> getDeviceInfoForLogin() async {
    try {
      final results = await Future.wait([
        getDeviceId(),
        getDeviceName(),
        getLocation(),
        getIPAddress(),
      ]);

      final location = results[2] as Map<String, double>;

      return {
        'device_id': results[0],
        'device_name': results[1],
        'platform': getPlatform(),
        'lat': location['lat'],
        'lng': location['lng'],
        'ip_address': results[3],
      };
    } catch (e) {
      print('Error getting device info for login: $e');
      return {
        'device_id': 'unknown-${DateTime.now().millisecondsSinceEpoch}',
        'device_name': 'Unknown Device',
        'platform': getPlatform(),
        'lat': 0.0,
        'lng': 0.0,
        'ip_address': 'unknown',
      };
    }
  }
}
