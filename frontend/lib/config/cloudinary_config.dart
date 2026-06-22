/// Cloudinary Configuration for SafeTrack
/// 
/// IMPORTANT: Before using Cloudinary integration, complete these steps:
/// 
/// 1. CREATE UPLOAD PRESET IN CLOUDINARY DASHBOARD:
///    - Go to: https://cloudinary.com/console
///    - Navigate to: Settings → Upload → Upload presets
///    - Click: "Add upload preset"
///    - Configure:
///      * Preset name: safetrack_preset
///      * Signing mode: Unsigned
///      * Folder: safetrack (optional)
///      * Access mode: Public
///    - Click: Save
/// 
/// 2. UPDATE CONFIGURATION BELOW:
///    - Replace CLOUD_NAME with your Cloudinary cloud name
///    - Replace UPLOAD_PRESET with your preset name
/// 
/// 3. SECURITY NOTES:
///    - Never expose API secret in client code
///    - Use unsigned upload presets for client-side uploads
///    - Implement server-side validation for production
///    - Add file size and type restrictions
/// 
/// 4. FIRESTORE RULES:
///    Add these rules to your Firestore security rules:
///    ```
///    match /mediaUrl/{document} {
///      allow read: if request.auth != null;
///      allow create: if request.auth != null && 
///                    request.resource.data.uploadedBy == request.auth.uid;
///      allow update, delete: if request.auth != null && 
///                             resource.data.uploadedBy == request.auth.uid;
///    }
///    ```

class CloudinaryConfig {
  // ========================================
  // CLOUDINARY CONFIGURATION
  // ========================================
  
  /// Your Cloudinary cloud name
  /// Find it at: https://cloudinary.com/console
  static const String cloudName = 'dg3ektpvo';
  
  /// Upload preset name (must be created in Cloudinary dashboard)
  /// This should be an UNSIGNED preset for client-side uploads
  static const String uploadPreset = 'safetrack_preset';
  
  /// API Key (for reference only - not used in client code)
  /// NEVER expose API secret in client-side code!
  static const String apiKey = '245744998953585';
  
  // ========================================
  // FIREBASE CONFIGURATION
  // ========================================
  
  /// Firestore collection name for storing image URLs
  static const String firestoreCollection = 'mediaUrl';
  
  // ========================================
  // UPLOAD SETTINGS
  // ========================================
  
  /// Maximum file size in bytes (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  
  /// Maximum file size in MB (for display)
  static const int maxFileSizeMB = 5;
  
  /// Allowed image formats
  static const List<String> allowedFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
  
  /// Default folder in Cloudinary
  static const String defaultFolder = 'safetrack';
  
  /// Image quality for compression (1-100)
  static const int imageQuality = 80;
  
  /// Maximum image width for upload
  static const int maxImageWidth = 1920;
  
  /// Maximum image height for upload
  static const int maxImageHeight = 1080;
  
  // ========================================
  // CLOUDINARY FOLDERS (for organization)
  // ========================================
  
  static const String incidentImagesFolder = 'safetrack/incidents';
  static const String profileImagesFolder = 'safetrack/profiles';
  static const String evidenceImagesFolder = 'safetrack/evidence';
  static const String reportImagesFolder = 'safetrack/reports';
  
  // ========================================
  // HELPER METHODS
  // ========================================
  
  /// Get Cloudinary upload URL
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  
  /// Validate file size
  static bool isFileSizeValid(int fileSizeBytes) {
    return fileSizeBytes <= maxFileSizeBytes;
  }
  
  /// Validate file format
  static bool isFileFormatValid(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    return allowedFormats.contains(extension);
  }
  
  /// Get human-readable file size
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  
  /// Generate thumbnail URL from original Cloudinary URL
  static String getThumbnailUrl(String originalUrl, {int width = 300, int height = 300}) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }
    String transformation = 'w_$width,h_$height,c_fill,q_auto,f_auto';
    return originalUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }
  
  /// Generate optimized URL with auto format and quality
  static String getOptimizedUrl(String originalUrl) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }
    String transformation = 'q_auto,f_auto';
    return originalUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }
}

// ========================================
// SETUP CHECKLIST
// ========================================

/// Complete this checklist before using Cloudinary:
/// 
/// [ ] Created Cloudinary account
/// [ ] Created upload preset named 'safetrack_preset'
/// [ ] Set preset to 'Unsigned' mode
/// [ ] Updated cloudName in this file
/// [ ] Updated uploadPreset in this file
/// [ ] Added Firestore security rules
/// [ ] Tested image upload
/// [ ] Tested image display
/// [ ] Implemented error handling
/// [ ] Added file size validation
/// [ ] Added file type validation
/// [ ] Tested on real device
/// [ ] Reviewed security settings
