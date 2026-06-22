/// Example: How to integrate Cloudinary into your existing Report screen
/// 
/// This file shows how to add Cloudinary image upload to your incident reporting
/// 
/// STEPS TO INTEGRATE:
/// 
/// 1. Import the required services at the top of your report.dart file:
/// 
///    import 'dart:io';
///    import 'package:safetrack/services/cloudinary_service.dart';
///    import 'package:safetrack/services/media_url_service.dart';
/// 
/// 2. Add state variables to your _ReportIncidentScreenState class:
/// 
///    List<File> _selectedImages = [];
///    List<String> _uploadedImageUrls = [];
///    bool _isUploadingImages = false;
/// 
/// 3. Add method to pick images:
/// 
///    Future<void> _pickImage(ImageSource source) async {
///      try {
///        final XFile? image = await ImagePicker().pickImage(
///          source: source,
///          imageQuality: 80,
///          maxWidth: 1920,
///          maxHeight: 1080,
///        );
///        
///        if (image != null) {
///          setState(() {
///            _selectedImages.add(File(image.path));
///          });
///        }
///      } catch (e) {
///        ScaffoldMessenger.of(context).showSnackBar(
///          SnackBar(content: Text('Failed to pick image: $e')),
///        );
///      }
///    }
/// 
/// 4. Add method to upload images to Cloudinary:
/// 
///    Future<void> _uploadImagesToCloudinary() async {
///      if (_selectedImages.isEmpty) return;
///      
///      setState(() => _isUploadingImages = true);
///      
///      try {
///        // Upload all images to Cloudinary
///        List<String> imageUrls = await CloudinaryService.uploadMultipleImages(
///          _selectedImages,
///          folder: 'safetrack/incidents',
///        );
///        
///        setState(() {
///          _uploadedImageUrls = imageUrls;
///          _isUploadingImages = false;
///        });
///        
///        ScaffoldMessenger.of(context).showSnackBar(
///          const SnackBar(
///            content: Text('Images uploaded successfully!'),
///            backgroundColor: Colors.green,
///          ),
///        );
///      } catch (e) {
///        setState(() => _isUploadingImages = false);
///        ScaffoldMessenger.of(context).showSnackBar(
///          SnackBar(content: Text('Upload failed: $e')),
///        );
///      }
///    }
/// 
/// 5. Update your submit incident method to include image URLs:
/// 
///    Future<void> _submitIncident() async {
///      // First, upload images if any
///      if (_selectedImages.isNotEmpty && _uploadedImageUrls.isEmpty) {
///        await _uploadImagesToCloudinary();
///      }
///      
///      try {
///        // Create incident document
///        DocumentReference incidentRef = await FirebaseFirestore.instance
///            .collection('incidents')
///            .add({
///          'description': _descriptionController.text,
///          'location': _locationController.text,
///          'timestamp': FieldValue.serverTimestamp(),
///          'reportedBy': FirebaseAuth.instance.currentUser?.uid,
///          'imageUrls': _uploadedImageUrls, // Store URLs as array of strings
///          'status': 'pending',
///        });
///        
///        // Optionally, save to mediaUrl collection for tracking
///        if (_uploadedImageUrls.isNotEmpty) {
///          await MediaUrlService().saveMultipleImageUrls(
///            _uploadedImageUrls,
///            metadata: {
///              'type': 'incident_image',
///              'incidentId': incidentRef.id,
///              'location': _locationController.text,
///            },
///          );
///        }
///        
///        // Show success message
///        ScaffoldMessenger.of(context).showSnackBar(
///          const SnackBar(
///            content: Text('Incident reported successfully!'),
///            backgroundColor: Colors.green,
///          ),
///        );
///        
///        // Navigate back or clear form
///        Navigator.pop(context);
///        
///      } catch (e) {
///        ScaffoldMessenger.of(context).showSnackBar(
///          SnackBar(content: Text('Failed to submit incident: $e')),
///        );
///      }
///    }
/// 
/// 6. Add UI to display selected images in your build method:
/// 
///    // Add this in your form, before the submit button
///    if (_selectedImages.isNotEmpty)
///      Container(
///        height: 120,
///        margin: const EdgeInsets.symmetric(vertical: 16),
///        child: ListView.builder(
///          scrollDirection: Axis.horizontal,
///          itemCount: _selectedImages.length,
///          itemBuilder: (context, index) {
///            return Stack(
///              children: [
///                Container(
///                  width: 120,
///                  height: 120,
///                  margin: const EdgeInsets.only(right: 8),
///                  decoration: BoxDecoration(
///                    borderRadius: BorderRadius.circular(12),
///                    image: DecorationImage(
///                      image: FileImage(_selectedImages[index]),
///                      fit: BoxFit.cover,
///                    ),
///                  ),
///                ),
///                Positioned(
///                  top: 4,
///                  right: 12,
///                  child: GestureDetector(
///                    onTap: () {
///                      setState(() {
///                        _selectedImages.removeAt(index);
///                      });
///                    },
///                    child: Container(
///                      padding: const EdgeInsets.all(4),
///                      decoration: const BoxDecoration(
///                        color: Colors.red,
///                        shape: BoxShape.circle,
///                      ),
///                      child: const Icon(
///                        Icons.close,
///                        color: Colors.white,
///                        size: 16,
///                      ),
///                    ),
///                  ),
///                ),
///              ],
///            );
///          },
///        ),
///      ),
/// 
/// 7. Add image picker buttons in your UI:
/// 
///    Row(
///      children: [
///        Expanded(
///          child: ElevatedButton.icon(
///            onPressed: () => _pickImage(ImageSource.camera),
///            icon: const Icon(Icons.camera_alt),
///            label: const Text('Camera'),
///          ),
///        ),
///        const SizedBox(width: 12),
///        Expanded(
///          child: ElevatedButton.icon(
///            onPressed: () => _pickImage(ImageSource.gallery),
///            icon: const Icon(Icons.photo_library),
///            label: const Text('Gallery'),
///          ),
///        ),
///      ],
///    ),
/// 
/// 8. Show upload progress:
/// 
///    if (_isUploadingImages)
///      const Padding(
///        padding: EdgeInsets.all(16.0),
///        child: Column(
///          children: [
///            CircularProgressIndicator(),
///            SizedBox(height: 8),
///            Text('Uploading images to Cloudinary...'),
///          ],
///        ),
///      ),
/// 
/// 
/// COMPLETE EXAMPLE FOR INCIDENT SUBMISSION:
/// 
/// ```dart
/// Future<void> submitIncidentWithImages() async {
///   try {
///     // 1. Upload images to Cloudinary
///     List<String> imageUrls = [];
///     if (_selectedImages.isNotEmpty) {
///       setState(() => _isUploadingImages = true);
///       
///       imageUrls = await CloudinaryService.uploadMultipleImages(
///         _selectedImages,
///         folder: 'safetrack/incidents',
///       );
///       
///       setState(() => _isUploadingImages = false);
///     }
///     
///     // 2. Save incident to Firestore with image URLs
///     await FirebaseFirestore.instance.collection('incidents').add({
///       'description': _descriptionController.text,
///       'location': _locationController.text,
///       'imageUrls': imageUrls, // Array of Cloudinary URLs
///       'timestamp': FieldValue.serverTimestamp(),
///       'reportedBy': FirebaseAuth.instance.currentUser?.uid,
///       'status': 'pending',
///     });
///     
///     // 3. Success!
///     ScaffoldMessenger.of(context).showSnackBar(
///       const SnackBar(content: Text('Incident reported successfully!')),
///     );
///     
///     Navigator.pop(context);
///   } catch (e) {
///     setState(() => _isUploadingImages = false);
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('Error: $e')),
///     );
///   }
/// }
/// ```
/// 
/// 
/// DISPLAYING INCIDENT IMAGES IN HISTORY:
/// 
/// ```dart
/// // In your incident history screen
/// import 'package:safetrack/widgets/cloudinary_image_widgets.dart';
/// 
/// // Display images from incident
/// Widget buildIncidentImages(List<dynamic> imageUrls) {
///   if (imageUrls.isEmpty) return const SizedBox.shrink();
///   
///   return SizedBox(
///     height: 100,
///     child: ListView.builder(
///       scrollDirection: Axis.horizontal,
///       itemCount: imageUrls.length,
///       itemBuilder: (context, index) {
///         return GestureDetector(
///           onTap: () {
///             CloudinaryImageViewer.show(
///               context,
///               imageUrls[index],
///               title: 'Incident Evidence',
///             );
///           },
///           child: CloudinaryThumbnail(
///             imageUrl: imageUrls[index],
///             width: 100,
///             height: 100,
///             borderRadius: BorderRadius.circular(8),
///           ),
///         );
///       },
///     ),
///   );
/// }
/// ```
/// 
/// 
/// FIRESTORE STRUCTURE FOR INCIDENTS:
/// 
/// ```json
/// {
///   "incidents": {
///     "incident_id_123": {
///       "description": "Road accident on Ring Road",
///       "location": "Ring Road, Lahore",
///       "imageUrls": [
///         "https://res.cloudinary.com/dg3ektpvo/image/upload/v1234/safetrack/incidents/image1.jpg",
///         "https://res.cloudinary.com/dg3ektpvo/image/upload/v1234/safetrack/incidents/image2.jpg"
///       ],
///       "timestamp": "2026-01-23T06:30:00.000Z",
///       "reportedBy": "user_uid_123",
///       "status": "pending"
///     }
///   }
/// }
/// ```
/// 
/// 
/// BENEFITS:
/// - ✅ Images stored on Cloudinary CDN (fast delivery)
/// - ✅ Only URLs stored in Firestore (saves database space)
/// - ✅ Automatic image optimization
/// - ✅ Multiple images per incident
/// - ✅ Easy to display with provided widgets
/// - ✅ Scalable and production-ready
/// 
/// 
/// NEXT STEPS:
/// 1. Create Cloudinary upload preset
/// 2. Update configuration in cloudinary_config.dart
/// 3. Add the code snippets above to your report.dart
/// 4. Test image upload and submission
/// 5. Deploy to production
