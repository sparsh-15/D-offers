import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';
import 'auth_store.dart';

class UploadService {
  static final UploadService instance = UploadService._();
  UploadService._();

  MediaType _contentTypeForFile(File imageFile) {
    final extension = imageFile.path.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType.parse('image/jpeg');
      case 'png':
        return MediaType.parse('image/png');
      case 'gif':
        return MediaType.parse('image/gif');
      case 'webp':
        return MediaType.parse('image/webp');
      default:
        return MediaType.parse('image/jpeg');
    }
  }

  Future<String> _uploadSingleImage(File imageFile, String endpoint) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: _contentTypeForFile(imageFile),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['url'] as String;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to upload image');
    }
  }

  Future<List<String>> _uploadMultipleImages(
    List<File> imageFiles,
    String endpoint,
  ) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    for (final file in imageFiles) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          file.path,
          contentType: _contentTypeForFile(file),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final images = data['images'] as List;
      return images.map((img) => img['url'] as String).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to upload images');
    }
  }

  Future<String> uploadImage(File imageFile) {
    return _uploadSingleImage(imageFile, '/upload/image');
  }

  Future<List<String>> uploadMultipleImages(List<File> imageFiles) {
    return _uploadMultipleImages(imageFiles, '/upload/images');
  }

  Future<String> uploadShopLogo(File imageFile) {
    return _uploadSingleImage(imageFile, '/upload/shop-logo');
  }

  Future<List<String>> uploadShopImages(List<File> imageFiles) {
    return _uploadMultipleImages(imageFiles, '/upload/shop-images');
  }

  MediaType _getMediaTypeForDocument(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return MediaType.parse('application/pdf');
      case 'jpg':
      case 'jpeg':
        return MediaType.parse('image/jpeg');
      case 'png':
        return MediaType.parse('image/png');
      case 'gif':
        return MediaType.parse('image/gif');
      case 'webp':
        return MediaType.parse('image/webp');
      default:
        return MediaType.parse('application/octet-stream');
    }
  }

  Future<String> uploadDocument(File file) async {
    // Validate file size (max 10MB)
    final fileSize = await file.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw Exception('File size must be less than 10MB');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/upload/document');
    final request = http.MultipartRequest('POST', uri);

    final token = AuthStore.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'document',
        file.path,
        contentType: _getMediaTypeForDocument(file),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['url'] as String;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to upload document');
    }
  }
}
