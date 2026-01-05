// core/utils/image_url_builder.dart
import 'dart:developer' as developer;

/// Safe image URL builder for network images
/// Validates and constructs safe URLs for CachedNetworkImage
class ImageUrlBuilder {
  /// Build a safe residence image URL from API response
  /// 
  /// Returns empty string if URL is invalid (prevents network errors)
  /// Returns validated absolute URL if valid
  static String buildResidenceImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      developer.log('[IMAGE] Empty image path → using placeholder', name: 'ImageUrlBuilder');
      return '';
    }

    final trimmedPath = path.trim();
    
    // Try to parse as URI
    final uri = Uri.tryParse(trimmedPath);
    if (uri == null || !uri.isAbsolute) {
      developer.log('[IMAGE] Invalid image URL → $trimmedPath', name: 'ImageUrlBuilder');
      return '';
    }

    // Validate scheme (must be http or https)
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      developer.log('[IMAGE] Invalid URL scheme → ${uri.scheme}', name: 'ImageUrlBuilder');
      return '';
    }

    // Validate host exists
    if (uri.host.isEmpty) {
      developer.log('[IMAGE] Missing host in URL → $trimmedPath', name: 'ImageUrlBuilder');
      return '';
    }

    final finalUrl = uri.toString();
    developer.log('[IMAGE] Final URL: $finalUrl', name: 'ImageUrlBuilder');
    return finalUrl;
  }
}

