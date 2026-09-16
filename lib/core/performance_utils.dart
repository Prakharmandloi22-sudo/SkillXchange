import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PerformanceUtils {
  /// Optimizes Cloudinary URLs for faster loading by requesting resized/compressed versions.
  static String optimizeCloudinaryUrl(String url, {int? width, int? height, bool isVideo = false}) {
    if (!url.contains('cloudinary.com')) return url;
    
    // Logic for raw URLs from our CloudinaryService
    String transform = 'f_auto,q_auto';
    if (width != null) transform += ',w_$width,c_limit';
    
    if (isVideo) {
      return url
          .replaceAll('.mp4', '.jpg')
          .replaceFirst('/video/upload/', '/video/upload/$transform,so_0/');
    }
    return url.replaceFirst('/upload/', '/upload/$transform/');
  }

  /// Returns a optimized image widget with caching.
  static Widget buildOptimizedImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    int? targetWidth,
    int? targetHeight,
    bool isVideo = false,
  }) {
    if (url.isEmpty) {
      return placeholder ?? Container(color: Colors.white10);
    }

    final optimizedUrl = optimizeCloudinaryUrl(
      url, 
      width: targetWidth ?? (width?.toInt()), 
      height: targetHeight ?? (height?.toInt()),
      isVideo: isVideo,
    );

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? Container(
        color: Colors.white.withValues(alpha: 0.05),
        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      errorWidget: (context, url, error) => errorWidget ?? const Icon(Icons.error_outline, color: Colors.white24),
      fadeInDuration: const Duration(milliseconds: 300),
      memCacheWidth: targetWidth ?? (width != null ? (width * 2).toInt() : null), // Higher density for quality
      memCacheHeight: targetHeight ?? (height != null ? (height * 2).toInt() : null),
    );
  }
}
