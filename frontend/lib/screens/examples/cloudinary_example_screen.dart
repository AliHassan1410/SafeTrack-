import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safetrack/services/cloudinary_service.dart';
import 'package:safetrack/services/media_url_service.dart';
import 'package:safetrack/utils/app_colors.dart';

/// Example screen demonstrating Cloudinary + Firestore integration
/// Shows complete workflow: Pick Image → Upload to Cloudinary → Save URL to Firestore → Display Images
class CloudinaryExampleScreen extends StatefulWidget {
  const CloudinaryExampleScreen({super.key});

  @override
  State<CloudinaryExampleScreen> createState() => _CloudinaryExampleScreenState();
}

class _CloudinaryExampleScreenState extends State<CloudinaryExampleScreen> {
  final ImagePicker _picker = ImagePicker();
  final MediaUrlService _mediaUrlService = MediaUrlService();
  
  bool _isUploading = false;
  List<Map<String, dynamic>> _userImages = [];
  bool _isLoadingImages = false;

  @override
  void initState() {
    super.initState();
    _loadUserImages();
  }

  /// Load user's uploaded images from Firestore
  Future<void> _loadUserImages() async {
    setState(() => _isLoadingImages = true);
    
    try {
      List<Map<String, dynamic>> images = await _mediaUrlService.getUserImages();
      setState(() {
        _userImages = images;
        _isLoadingImages = false;
      });
    } catch (e) {
      setState(() => _isLoadingImages = false);
      _showErrorSnackBar('Failed to load images: $e');
    }
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compress image to reduce upload time
      );
      
      if (image != null) {
        await _uploadImageToCloudinary(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image from camera: $e');
    }
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image to reduce upload time
      );
      
      if (image != null) {
        await _uploadImageToCloudinary(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image from gallery: $e');
    }
  }

  /// Upload image to Cloudinary and save URL to Firestore
  Future<void> _uploadImageToCloudinary(File imageFile) async {
    setState(() => _isUploading = true);
    
    try {
      // Step 1: Upload image to Cloudinary
      _showInfoSnackBar('Uploading image to Cloudinary...');
      String imageUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'safetrack/incidents', // Organize by folder
      );
      
      // Step 2: Save image URL to Firestore
      _showInfoSnackBar('Saving image URL to Firestore...');
      await _mediaUrlService.saveImageUrl(
        imageUrl,
        metadata: {
          'type': 'incident_image',
          'fileName': imageFile.path.split('/').last,
          'fileSize': await imageFile.length(),
        },
      );
      
      // Step 3: Reload images to show the new upload
      await _loadUserImages();
      
      setState(() => _isUploading = false);
      _showSuccessSnackBar('Image uploaded successfully! ✅');
      
    } catch (e) {
      setState(() => _isUploading = false);
      _showErrorSnackBar('Upload failed: $e');
    }
  }

  /// Delete image record from Firestore
  Future<void> _deleteImage(String documentId) async {
    try {
      await _mediaUrlService.deleteImageRecord(documentId);
      await _loadUserImages();
      _showSuccessSnackBar('Image deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete image: $e');
    }
  }

  /// Show success message
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show info message
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.secondary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cloudinary Integration',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Upload Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF1E40AF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Upload Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Images are uploaded to Cloudinary\nURLs are stored in Firestore',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickImageFromCamera,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isUploading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'Uploading...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),

          // Images Grid Section
          Expanded(
            child: _isLoadingImages
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _userImages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_rounded,
                              size: 80,
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No images uploaded yet',
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.6),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap camera or gallery to upload',
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.4),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUserImages,
                        color: AppColors.primary,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _userImages.length,
                          itemBuilder: (context, index) {
                            return _buildImageCard(_userImages[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Build individual image card
  Widget _buildImageCard(Map<String, dynamic> imageData) {
    String imageUrl = imageData['imageUrl'] ?? '';
    String documentId = imageData['id'] ?? '';
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Display
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primary,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image_rounded,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // View Full Image
                IconButton(
                  onPressed: () => _showFullImage(imageUrl),
                  icon: const Icon(Icons.fullscreen_rounded),
                  color: AppColors.primary,
                  iconSize: 22,
                ),
                // Delete Image
                IconButton(
                  onPressed: () => _confirmDelete(documentId),
                  icon: const Icon(Icons.delete_rounded),
                  color: AppColors.secondary,
                  iconSize: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show full image in dialog
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm delete dialog
  void _confirmDelete(String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This will remove the image record from Firestore. The image will remain in Cloudinary.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(documentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
