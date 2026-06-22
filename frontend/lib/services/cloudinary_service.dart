import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;

/// Cloudinary Service for SafeTrack
/// Handles secure image uploads to Cloudinary and returns image URLs
class CloudinaryService {
  // Cloudinary Configuration
  static const String _cloudName = 'dg3ektpvo';
  static const String _uploadPreset =
      'safetrack_preset'; // You need to create this in Cloudinary dashboard

  // Cloudinary Upload URL
  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload image to Cloudinary using HTTP multipart request
  ///
  /// Parameters:
  /// - [imageFile]: The image file to upload (from camera or gallery)
  /// - [folder]: Optional folder name in Cloudinary (default: 'safetrack')
  ///
  /// Returns:
  /// - String: Secure URL of the uploaded image
  ///
  /// Throws:
  /// - Exception: If upload fails or network error occurs
  static Future<String> uploadImage({
    File? file,
    Uint8List? bytes,
    String folder = 'safetrack',
    String? fileName,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;
      request.fields['timestamp'] =
          DateTime.now().millisecondsSinceEpoch.toString();

      http.MultipartFile multipartFile;
      if (file != null) {
        String ext = path.extension(file.path);
        String name =
            fileName ??
            'safetrack_${DateTime.now().millisecondsSinceEpoch}$ext';
        multipartFile = await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: name,
        );
      } else if (bytes != null) {
        String name =
            fileName ??
            'safetrack_${DateTime.now().millisecondsSinceEpoch}.jpg';
        multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: name,
        );
      } else {
        throw Exception('No file or bytes provided');
      }
      request.files.add(multipartFile);

      print('📤 Uploading image to Cloudinary...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        String secureUrl = responseData['secure_url'];
        print(' Image uploaded successfully!');
        print(' Image URL: $secureUrl');
        return secureUrl;
      } else {
        print(' Upload failed with status: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print(' Error uploading image: $e');
      throw Exception('Error uploading image: $e');
    }
  }

  /// Upload multiple images to Cloudinary
  ///
  /// Parameters:
  /// - [imageFiles]: List of image files to upload
  /// - [folder]: Optional folder name in Cloudinary
  ///
  /// Returns:
  /// - List<String>: List of secure URLs of uploaded images
  static Future<List<String>> uploadMultipleImages(
    List<File> imageFiles, {
    String folder = 'safetrack',
  }) async {
    List<String> imageUrls = [];

    for (var imageFile in imageFiles) {
      try {
        String url = await uploadImage(file: imageFile, folder: folder);
        imageUrls.add(url);
      } catch (e) {
        print(' Failed to upload image: ${imageFile.path}');
        // Continue with other images even if one fails
      }
    }

    return imageUrls;
  }

  /// Delete image from Cloudinary (optional - requires API key and secret)
  /// Note: For production, implement this on your backend for security
  ///
  /// Parameters:
  /// - [publicId]: The public ID of the image to delete
  ///
  /// This method is commented out as it requires API secret which should
  /// not be exposed in client-side code. Implement on backend if needed.
  /*
  static Future<bool> deleteImage(String publicId) async {
    // This should be implemented on your backend server
    // Never expose your API secret in client-side code
    throw UnimplementedError('Delete should be implemented on backend');
  }
  */
}
