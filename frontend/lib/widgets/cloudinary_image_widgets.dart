import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';

/// Reusable widget for displaying Cloudinary images
/// Handles loading states, errors, and provides consistent styling
class CloudinaryImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showLoadingIndicator;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CloudinaryImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showLoadingIndicator = true,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        
        if (!showLoadingIndicator) {
          return placeholder ?? const SizedBox.shrink();
        }
        
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_rounded,
                    size: 50,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Cloudinary image with thumbnail optimization
/// Automatically generates optimized thumbnail URLs
class CloudinaryThumbnail extends StatelessWidget {
  final String imageUrl;
  final int width;
  final int height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CloudinaryThumbnail({
    super.key,
    required this.imageUrl,
    this.width = 300,
    this.height = 300,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  /// Generate Cloudinary transformation URL for thumbnails
  String _getThumbnailUrl() {
    // Check if URL is from Cloudinary
    if (!imageUrl.contains('cloudinary.com')) {
      return imageUrl; // Return original if not Cloudinary
    }

    // Insert transformation parameters
    String transformation = 'w_$width,h_$height,c_fill,q_auto,f_auto';
    return imageUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }

  @override
  Widget build(BuildContext context) {
    return CloudinaryImage(
      imageUrl: _getThumbnailUrl(),
      width: width.toDouble(),
      height: height.toDouble(),
      fit: fit,
      borderRadius: borderRadius,
    );
  }
}

/// Avatar widget using Cloudinary image
class CloudinaryAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? placeholder;

  const CloudinaryAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 40,
    this.backgroundColor,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.background,
      child: ClipOval(
        child: CloudinaryThumbnail(
          imageUrl: imageUrl,
          width: (radius * 2).toInt(),
          height: (radius * 2).toInt(),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Full screen image viewer
class CloudinaryImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? title;

  const CloudinaryImageViewer({
    super.key,
    required this.imageUrl,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: title != null ? Text(title!) : null,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CloudinaryImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  /// Show full screen image viewer
  static void show(BuildContext context, String imageUrl, {String? title}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CloudinaryImageViewer(
          imageUrl: imageUrl,
          title: title,
        ),
      ),
    );
  }
}

/// Image grid from list of URLs
class CloudinaryImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final Function(String imageUrl)? onImageTap;

  const CloudinaryImageGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.childAspectRatio = 1.0,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        String imageUrl = imageUrls[index];
        
        return GestureDetector(
          onTap: () {
            if (onImageTap != null) {
              onImageTap!(imageUrl);
            } else {
              CloudinaryImageViewer.show(context, imageUrl);
            }
          },
          child: CloudinaryThumbnail(
            imageUrl: imageUrl,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}

/// Carousel/Slider for multiple images
class CloudinaryImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;

  const CloudinaryImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
  });

  @override
  State<CloudinaryImageCarousel> createState() => _CloudinaryImageCarouselState();
}

class _CloudinaryImageCarouselState extends State<CloudinaryImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    Future.delayed(widget.autoPlayInterval, () {
      if (mounted && _pageController.hasClients) {
        int nextPage = (_currentPage + 1) % widget.imageUrls.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return CloudinaryImage(
                imageUrl: widget.imageUrls[index],
                height: widget.height,
                fit: BoxFit.cover,
              );
            },
          ),
          
          // Page indicators
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
