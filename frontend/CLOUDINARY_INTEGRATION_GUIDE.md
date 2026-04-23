# Cloudinary Integration Guide for SafeTrack

## 📋 Overview

This guide explains how to integrate Cloudinary image storage with Firebase Firestore in your SafeTrack Flutter application. Images are uploaded to Cloudinary, and only the secure URLs are stored in Firestore as strings.

---

## 🔧 Setup Instructions

### 1. Add Dependencies

Add these packages to your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0           # For HTTP multipart requests
  path: ^1.8.3           # For file path manipulation
  image_picker: ^1.0.4   # For picking images from camera/gallery
  cloud_firestore: ^5.6.8 # For Firestore database
  firebase_auth: ^5.5.4  # For user authentication
```

Run:
```bash
flutter pub get
```

---

### 2. Configure Cloudinary

#### Create Upload Preset (IMPORTANT!)

1. Go to [Cloudinary Dashboard](https://cloudinary.com/console)
2. Navigate to **Settings** → **Upload**
3. Scroll to **Upload presets**
4. Click **Add upload preset**
5. Configure:
   - **Preset name**: `safetrack_preset`
   - **Signing mode**: `Unsigned` (for client-side uploads)
   - **Folder**: `safetrack` (optional, for organization)
   - **Access mode**: `Public`
6. Click **Save**

#### Update Configuration

In `lib/services/cloudinary_service.dart`, update:

```dart
static const String _cloudName = 'dg3ektpvo'; // Your cloud name
static const String _uploadPreset = 'safetrack_preset'; // Your preset name
```

---

## 📁 Project Structure

```
lib/
├── services/
│   ├── cloudinary_service.dart      # Cloudinary upload service
│   ├── media_url_service.dart       # Firestore URL management
│   └── auth_service.dart            # (existing)
├── screens/
│   └── examples/
│       └── cloudinary_example_screen.dart  # Example implementation
└── utils/
    └── app_colors.dart              # (existing)
```

---

## 🚀 How It Works

### Complete Workflow

```
1. User picks image (Camera/Gallery)
   ↓
2. Image uploaded to Cloudinary via HTTP multipart
   ↓
3. Cloudinary returns secure_url
   ↓
4. URL saved to Firestore as STRING
   ↓
5. Image displayed using URL
```

---

## 💻 Code Examples

### Example 1: Simple Upload

```dart
import 'dart:io';
import 'package:safetrack/services/cloudinary_service.dart';
import 'package:safetrack/services/media_url_service.dart';

Future<void> uploadImage(File imageFile) async {
  try {
    // Step 1: Upload to Cloudinary
    String imageUrl = await CloudinaryService.uploadImage(imageFile);
    
    // Step 2: Save URL to Firestore
    await MediaUrlService().saveImageUrl(imageUrl);
    
    print('✅ Upload complete! URL: $imageUrl');
  } catch (e) {
    print('❌ Upload failed: $e');
  }
}
```

### Example 2: Upload with Metadata

```dart
Future<void> uploadIncidentImage(File imageFile, String incidentId) async {
  try {
    // Upload to Cloudinary in specific folder
    String imageUrl = await CloudinaryService.uploadImage(
      imageFile,
      folder: 'safetrack/incidents',
    );
    
    // Save with metadata
    await MediaUrlService().saveImageUrl(
      imageUrl,
      metadata: {
        'type': 'incident_image',
        'incidentId': incidentId,
        'location': 'Lahore, Pakistan',
        'description': 'Road accident evidence',
      },
    );
    
    print('✅ Incident image uploaded!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

### Example 3: Upload Multiple Images

```dart
Future<void> uploadMultipleImages(List<File> imageFiles) async {
  try {
    // Upload all images to Cloudinary
    List<String> imageUrls = await CloudinaryService.uploadMultipleImages(
      imageFiles,
      folder: 'safetrack/gallery',
    );
    
    // Save all URLs to Firestore
    await MediaUrlService().saveMultipleImageUrls(imageUrls);
    
    print('✅ Uploaded ${imageUrls.length} images!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

### Example 4: Display Images from Firestore

```dart
import 'package:flutter/material.dart';
import 'package:safetrack/services/media_url_service.dart';

class ImageGallery extends StatefulWidget {
  @override
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  List<Map<String, dynamic>> images = [];
  
  @override
  void initState() {
    super.initState();
    loadImages();
  }
  
  Future<void> loadImages() async {
    List<Map<String, dynamic>> fetchedImages = 
        await MediaUrlService().getUserImages();
    setState(() => images = fetchedImages);
  }
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        String imageUrl = images[index]['imageUrl'];
        
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.broken_image);
          },
        );
      },
    );
  }
}
```

### Example 5: Real-time Image Stream

```dart
import 'package:flutter/material.dart';
import 'package:safetrack/services/media_url_service.dart';

class RealtimeImageGallery extends StatelessWidget {
  final MediaUrlService _mediaService = MediaUrlService();
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _mediaService.streamUserImages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No images yet'));
        }
        
        List<Map<String, dynamic>> images = snapshot.data!;
        
        return ListView.builder(
          itemCount: images.length,
          itemBuilder: (context, index) {
            String imageUrl = images[index]['imageUrl'];
            return Image.network(imageUrl);
          },
        );
      },
    );
  }
}
```

---

## 🔐 Security Best Practices

### ✅ DO's

1. **Use Upload Presets**: Never expose API secrets in client code
2. **Validate File Size**: Limit uploads to reasonable sizes (e.g., 5MB)
3. **Validate File Type**: Only allow image formats (jpg, png, etc.)
4. **Use Folders**: Organize images in Cloudinary folders
5. **Add Timestamps**: Include upload timestamps in metadata
6. **User Authentication**: Only allow authenticated users to upload
7. **Rate Limiting**: Implement upload limits per user

### ❌ DON'Ts

1. **Never** expose API secret in client code
2. **Never** allow unlimited file sizes
3. **Never** skip file type validation
4. **Never** allow anonymous uploads in production
5. **Never** store sensitive data in image metadata

---

## 📊 Firestore Data Structure

### Collection: `mediaUrl`

```json
{
  "documentId": "auto-generated-id",
  "imageUrl": "https://res.cloudinary.com/dg3ektpvo/image/upload/v1234567890/safetrack/image.jpg",
  "uploadedAt": "2026-01-23T06:30:00.000Z",
  "uploadedBy": "user-uid-123",
  "userEmail": "user@example.com",
  "type": "incident_image",
  "fileName": "image.jpg",
  "fileSize": 1234567
}
```

---

## 🎨 Image Optimization Tips

### 1. Compress Before Upload

```dart
final XFile? image = await ImagePicker().pickImage(
  source: ImageSource.gallery,
  imageQuality: 80, // Compress to 80% quality
  maxWidth: 1920,   // Max width
  maxHeight: 1080,  // Max height
);
```

### 2. Use Cloudinary Transformations

Display optimized images:

```dart
// Original URL
String originalUrl = 'https://res.cloudinary.com/dg3ektpvo/image/upload/v1234/image.jpg';

// Optimized URL (300x300 thumbnail)
String thumbnailUrl = originalUrl.replaceFirst(
  '/upload/',
  '/upload/w_300,h_300,c_fill/',
);

// Display thumbnail
Image.network(thumbnailUrl);
```

### 3. Lazy Loading

```dart
Image.network(
  imageUrl,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator(
      value: loadingProgress.expectedTotalBytes != null
          ? loadingProgress.cumulativeBytesLoaded / 
            loadingProgress.expectedTotalBytes!
          : null,
    );
  },
);
```

---

## 🧪 Testing

### Test Upload Preset

Run this test to verify your Cloudinary setup:

```dart
import 'dart:io';
import 'package:safetrack/services/cloudinary_service.dart';

Future<void> testCloudinaryUpload() async {
  try {
    // Use a test image file
    File testImage = File('path/to/test/image.jpg');
    
    String imageUrl = await CloudinaryService.uploadImage(testImage);
    
    print('✅ Test successful!');
    print('Image URL: $imageUrl');
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
```

---

## 🐛 Troubleshooting

### Issue: "Upload preset not found"

**Solution**: Create upload preset in Cloudinary dashboard with name `safetrack_preset`

### Issue: "Invalid signature"

**Solution**: Ensure upload preset is set to "Unsigned" mode

### Issue: "File too large"

**Solution**: Compress image before upload or increase Cloudinary limits

### Issue: "Network error"

**Solution**: Check internet connection and Cloudinary service status

### Issue: "Permission denied"

**Solution**: Ensure user is authenticated before upload

---

## 📱 Integration with Existing Screens

### Add to Report Screen

```dart
// In your report.dart file
import 'package:safetrack/services/cloudinary_service.dart';
import 'package:safetrack/services/media_url_service.dart';

Future<void> submitIncidentWithImage(File imageFile) async {
  // Upload image
  String imageUrl = await CloudinaryService.uploadImage(
    imageFile,
    folder: 'safetrack/incidents',
  );
  
  // Save incident with image URL
  await FirebaseFirestore.instance.collection('incidents').add({
    'description': 'Incident description',
    'imageUrl': imageUrl, // Store URL as STRING
    'timestamp': FieldValue.serverTimestamp(),
  });
}
```

---

## 📈 Performance Optimization

1. **Compress images** before upload (use `imageQuality` parameter)
2. **Use thumbnails** for list views
3. **Implement pagination** for large image collections
4. **Cache images** using `cached_network_image` package
5. **Lazy load** images in lists

---

## 🔄 Migration from Firebase Storage

If you're currently using Firebase Storage:

```dart
// Old way (Firebase Storage)
String downloadUrl = await FirebaseStorage.instance
    .ref('images/${fileName}')
    .putFile(imageFile)
    .then((snapshot) => snapshot.ref.getDownloadURL());

// New way (Cloudinary)
String imageUrl = await CloudinaryService.uploadImage(imageFile);
```

**Benefits of Cloudinary:**
- ✅ Faster uploads
- ✅ Built-in image transformations
- ✅ Better CDN performance
- ✅ More storage space
- ✅ Advanced image optimization

---

## 📞 Support

For issues or questions:
1. Check Cloudinary documentation: https://cloudinary.com/documentation
2. Review Firebase Firestore docs: https://firebase.google.com/docs/firestore
3. Check console logs for detailed error messages

---

## ✅ Checklist

Before deploying to production:

- [ ] Created Cloudinary upload preset
- [ ] Updated cloud name and preset in code
- [ ] Tested image upload from camera
- [ ] Tested image upload from gallery
- [ ] Verified URLs are saved to Firestore
- [ ] Tested image display from URLs
- [ ] Implemented error handling
- [ ] Added file size validation
- [ ] Added file type validation
- [ ] Implemented user authentication
- [ ] Tested on both Android and iOS (if applicable)

---

## 🎉 You're All Set!

Your SafeTrack app now has professional-grade image storage with Cloudinary and Firebase Firestore integration!
