# Cloudinary Quick Reference - SafeTrack

## 🚀 Quick Start (3 Steps)

### Step 1: Create Upload Preset
```
1. Go to https://cloudinary.com/console
2. Settings → Upload → Upload presets
3. Add preset: name = "safetrack_preset", mode = "Unsigned"
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Upload Your First Image
```dart
import 'dart:io';
import 'package:safetrack/services/cloudinary_service.dart';
import 'package:safetrack/services/media_url_service.dart';

// Upload image
String imageUrl = await CloudinaryService.uploadImage(imageFile);

// Save URL to Firestore
await MediaUrlService().saveImageUrl(imageUrl);
```

---

## 📝 Common Code Snippets

### Pick Image from Camera
```dart
import 'package:image_picker/image_picker.dart';

final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(
  source: ImageSource.camera,
  imageQuality: 80,
);

if (image != null) {
  File imageFile = File(image.path);
  // Upload imageFile
}
```

### Pick Image from Gallery
```dart
final XFile? image = await picker.pickImage(
  source: ImageSource.gallery,
  imageQuality: 80,
);
```

### Upload to Cloudinary
```dart
String imageUrl = await CloudinaryService.uploadImage(
  imageFile,
  folder: 'safetrack/incidents',
);
```

### Save URL to Firestore
```dart
await MediaUrlService().saveImageUrl(
  imageUrl,
  metadata: {
    'type': 'incident',
    'description': 'Road accident',
  },
);
```

### Display Image
```dart
import 'package:safetrack/widgets/cloudinary_image_widgets.dart';

CloudinaryImage(
  imageUrl: 'https://res.cloudinary.com/...',
  width: 200,
  height: 200,
  borderRadius: BorderRadius.circular(12),
)
```

### Display Thumbnail
```dart
CloudinaryThumbnail(
  imageUrl: imageUrl,
  width: 150,
  height: 150,
)
```

### Get User Images
```dart
List<Map<String, dynamic>> images = 
    await MediaUrlService().getUserImages();

for (var image in images) {
  String url = image['imageUrl'];
  print(url);
}
```

### Real-time Stream
```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: MediaUrlService().streamUserImages(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    List<Map<String, dynamic>> images = snapshot.data!;
    return ListView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Image.network(images[index]['imageUrl']);
      },
    );
  },
)
```

---

## 🎨 Widget Examples

### Basic Image
```dart
CloudinaryImage(
  imageUrl: imageUrl,
  width: 300,
  height: 200,
  fit: BoxFit.cover,
)
```

### Avatar
```dart
CloudinaryAvatar(
  imageUrl: profileImageUrl,
  radius: 40,
)
```

### Image Grid
```dart
CloudinaryImageGrid(
  imageUrls: ['url1', 'url2', 'url3'],
  crossAxisCount: 3,
  onImageTap: (url) {
    CloudinaryImageViewer.show(context, url);
  },
)
```

### Image Carousel
```dart
CloudinaryImageCarousel(
  imageUrls: imageUrls,
  height: 250,
  autoPlay: true,
)
```

### Full Screen Viewer
```dart
CloudinaryImageViewer.show(
  context,
  imageUrl,
  title: 'Incident Evidence',
);
```

---

## 🔐 Firestore Security Rules

Add to your `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /mediaUrl/{document} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                    request.resource.data.uploadedBy == request.auth.uid;
      allow update, delete: if request.auth != null && 
                             resource.data.uploadedBy == request.auth.uid;
    }
  }
}
```

---

## ⚙️ Configuration

Update in `lib/config/cloudinary_config.dart`:

```dart
static const String cloudName = 'YOUR_CLOUD_NAME';
static const String uploadPreset = 'YOUR_PRESET_NAME';
```

---

## 🐛 Common Errors & Solutions

| Error | Solution |
|-------|----------|
| "Upload preset not found" | Create preset in Cloudinary dashboard |
| "Invalid signature" | Set preset to "Unsigned" mode |
| "File too large" | Compress image or increase limits |
| "Network error" | Check internet connection |
| "Permission denied" | Ensure user is authenticated |

---

## 📊 Firestore Document Structure

```json
{
  "imageUrl": "https://res.cloudinary.com/...",
  "uploadedAt": Timestamp,
  "uploadedBy": "user-uid",
  "userEmail": "user@example.com",
  "type": "incident_image",
  "fileName": "image.jpg",
  "fileSize": 1234567
}
```

---

## 🎯 Image Optimization

### Compress on Upload
```dart
final XFile? image = await picker.pickImage(
  source: ImageSource.gallery,
  imageQuality: 80,      // 80% quality
  maxWidth: 1920,        // Max width
  maxHeight: 1080,       // Max height
);
```

### Use Thumbnails
```dart
// Original: https://res.cloudinary.com/.../upload/.../image.jpg
// Thumbnail: https://res.cloudinary.com/.../upload/w_300,h_300,c_fill/.../image.jpg

String thumbnailUrl = CloudinaryConfig.getThumbnailUrl(originalUrl);
```

---

## 📱 Complete Upload Flow

```dart
Future<void> uploadIncidentImage() async {
  try {
    // 1. Pick image
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (image == null) return;
    
    // 2. Upload to Cloudinary
    String imageUrl = await CloudinaryService.uploadImage(
      File(image.path),
      folder: 'safetrack/incidents',
    );
    
    // 3. Save URL to Firestore
    String docId = await MediaUrlService().saveImageUrl(
      imageUrl,
      metadata: {
        'type': 'incident',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    // 4. Success!
    print('✅ Upload complete! Doc ID: $docId');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

## 🔗 Useful Links

- [Cloudinary Dashboard](https://cloudinary.com/console)
- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Firebase Console](https://console.firebase.google.com)
- [Image Picker Package](https://pub.dev/packages/image_picker)

---

## ✅ Pre-Launch Checklist

- [ ] Upload preset created and tested
- [ ] Firestore security rules added
- [ ] File size validation implemented
- [ ] File type validation implemented
- [ ] Error handling added
- [ ] Loading states implemented
- [ ] Tested on real device
- [ ] Images displaying correctly
- [ ] Delete functionality working
- [ ] Performance optimized

---

## 💡 Pro Tips

1. **Always compress images** before upload
2. **Use thumbnails** for list views
3. **Implement pagination** for large collections
4. **Cache images** for better performance
5. **Add retry logic** for failed uploads
6. **Show upload progress** to users
7. **Validate file types** before upload
8. **Limit file sizes** to save bandwidth
9. **Use folders** to organize images
10. **Test on slow networks**

---

## 📞 Need Help?

Check the full documentation: `CLOUDINARY_INTEGRATION_GUIDE.md`
