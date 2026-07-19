import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Media Gallery Widget
/// Handles product image management with drag-to-reorder functionality
class MediaGalleryWidget extends StatefulWidget {
  final List<String> images;
  final Function(List<String>) onImagesUpdated;

  const MediaGalleryWidget({
    super.key,
    required this.images,
    required this.onImagesUpdated,
  });

  @override
  State<MediaGalleryWidget> createState() => _MediaGalleryWidgetState();
}

class _MediaGalleryWidgetState extends State<MediaGalleryWidget> {
  final ImagePicker _picker = ImagePicker();
  int? _draggedIndex;

  Future<void> _addImage() async {
    HapticFeedback.selectionClick();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_library',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final updatedImages = List<String>.from(widget.images)..add(image.path);
        widget.onImagesUpdated(updatedImages);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image added successfully'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _removeImage(int index) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedImages = List<String>.from(widget.images)
                ..removeAt(index);
              widget.onImagesUpdated(updatedImages);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image removed'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _reorderImages(int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();

    final updatedImages = List<String>.from(widget.images);
    final item = updatedImages.removeAt(oldIndex);
    updatedImages.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    widget.onImagesUpdated(updatedImages);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Images',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.images.length}/10',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 20.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.images.length + 1,
              itemBuilder: (context, index) {
                if (index == widget.images.length) {
                  // Add image button
                  return GestureDetector(
                    onTap: widget.images.length < 10 ? _addImage : null,
                    child: Container(
                      width: 20.h,
                      margin: EdgeInsets.only(right: 2.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: theme.colorScheme.outline,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'add_photo_alternate',
                            color: widget.images.length < 10
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                            size: 32,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            widget.images.length < 10
                                ? 'Add Image'
                                : 'Max 10 images',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: widget.images.length < 10
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Image item
                return LongPressDraggable<int>(
                  data: index,
                  feedback: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(2.w),
                    child: Container(
                      width: 20.h,
                      height: 20.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2.w),
                        child: CustomImageWidget(
                          imageUrl: widget.images[index],
                          width: 20.h,
                          height: 20.h,
                          fit: BoxFit.cover,
                          semanticLabel: 'Product image ${index + 1}',
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: 20.h,
                    height: 20.h,
                    margin: EdgeInsets.only(right: 2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2.w),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                  onDragStarted: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _draggedIndex = index;
                    });
                  },
                  onDragEnd: (_) {
                    setState(() {
                      _draggedIndex = null;
                    });
                  },
                  child: DragTarget<int>(
                    onAcceptWithDetails: (draggedIndex) {
                      _reorderImages(draggedIndex.data, index);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Stack(
                        children: [
                          Container(
                            width: 20.h,
                            height: 20.h,
                            margin: EdgeInsets.only(right: 2.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2.w),
                              border: Border.all(
                                color: candidateData.isNotEmpty
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2.w),
                              child: CustomImageWidget(
                                imageUrl: widget.images[index],
                                width: 20.h,
                                height: 20.h,
                                fit: BoxFit.cover,
                                semanticLabel: 'Product image ${index + 1}',
                              ),
                            ),
                          ),
                          if (index == 0)
                            Positioned(
                              top: 1.h,
                              left: 1.h,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(1.w),
                                ),
                                child: Text(
                                  'Main',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 1.h,
                            right: 3.w,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: EdgeInsets.all(1.w),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error,
                                  shape: BoxShape.circle,
                                ),
                                child: CustomIconWidget(
                                  iconName: 'close',
                                  color: theme.colorScheme.onError,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Long press and drag to reorder images. First image will be the main product image.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}