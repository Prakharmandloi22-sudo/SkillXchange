import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as p;

import '../core/config.dart';

class CloudinaryService {
  static const String _cloudName = AppConfig.cloudinaryCloudName;
  static const String _uploadPreset = AppConfig.cloudinaryUploadPreset;

  late final CloudinaryPublic _cloudinary;

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  Future<String> uploadProfileImage(File imageFile) async {
    if (_cloudName.isEmpty) throw Exception('CLOUDINARY_CLOUD_NAME is not configured');
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'profile_photos',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<String> uploadVideo(File videoFile) async {
    if (_cloudName.isEmpty) throw Exception('CLOUDINARY_CLOUD_NAME is not configured');
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/video/upload'),
      );
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        videoFile.path,
        filename: p.basename(videoFile.path),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return data['secure_url'] as String;
      } else {
        final errorData = json.decode(response.body);
        final msg = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('Cloudinary error (${response.statusCode}): $msg');
      }
    } catch (e) {
      // Fallback to library upload
      try {
        final response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            videoFile.path,
            folder: 'discovery_videos',
            resourceType: CloudinaryResourceType.Auto,
          ),
        );
        return response.secureUrl;
      } catch (innerErr) {
        throw Exception('Video upload failed: $e');
      }
    }
  }

  Future<String> uploadPostMedia(File file, bool isVideo) async {
    if (_cloudName.isEmpty) {
      throw Exception('Cloudinary Cloud Name is missing.');
    }
    
    // Attempt 1: Using provided preset
    try {
      return await _uploadWithPreset(file, isVideo, _uploadPreset);
    } catch (e) {
      final errorStr = e.toString();
      final isAuthError = errorStr.contains('401') || errorStr.contains('Unauthorized');
      final isMissingPreset = errorStr.contains('preset not found') || errorStr.contains('400');
      
      if ((isAuthError || isMissingPreset) && _uploadPreset != 'ml_default') {
        // Attempt 2: Fallback to standard ml_default
        try {
          debugPrint('PRIMARY_PRESET_FAIL: Attempting fallback to ml_default');
          return await _uploadWithPreset(file, isVideo, 'ml_default');
        } catch (inner) {
          throw _handleCloudinaryError(inner, 'ml_default');
        }
      }
      throw _handleCloudinaryError(e, _uploadPreset);
    }
  }

  Future<String> _uploadWithPreset(File file, bool isVideo, String preset) async {
    final type = isVideo ? 'video' : 'image';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$type/upload');
    
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = preset
      ..fields['folder'] = 'pulse_posts'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['secure_url'];
    } else {
      // Return the detailed message from Cloudinary if available
      String message = 'Status ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null && errorData['error']['message'] != null) {
          message = errorData['error']['message'];
        }
      } catch (_) {}
      
      throw Exception('Cloudinary Error ($preset): $message');
    }
  }

  Exception _handleCloudinaryError(dynamic e, String preset) {
    final errorMsg = e.toString();
    if (errorMsg.contains('401') || errorMsg.contains('Unauthorized')) {
      return Exception('Cloudinary 401: Unauthorized. Cloud: "$_cloudName", Preset: "$preset". Please ensure the preset is "Unsigned" in settings.');
    }
    return Exception('Post upload failure ($preset): $errorMsg');
  }
}
