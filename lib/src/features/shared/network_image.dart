import 'package:flutter/material.dart';

/// A robust network image widget that handles loading, errors, and iOS
/// compatibility issues gracefully. Use this instead of raw Image.network
/// throughout the app for consistent behavior across platforms.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;

  /// Shown while loading. Defaults to a subtle shimmer container.
  final Widget? placeholder;

  /// Shown on error. Defaults to an icon placeholder.
  final Widget? errorWidget;

  /// If set, clips the image with this border radius.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      // Force no-cache headers to work around iOS aggressive caching issues
      headers: const {'Accept': '*/*'},
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[AppNetworkImage] load failed: $url — $error');
        return errorWidget ??
            _DefaultErrorPlaceholder(width: width, height: height);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            _DefaultLoadingPlaceholder(width: width, height: height);
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

class _DefaultLoadingPlaceholder extends StatelessWidget {
  const _DefaultLoadingPlaceholder({this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    );
  }
}

class _DefaultErrorPlaceholder extends StatelessWidget {
  const _DefaultErrorPlaceholder({this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.outline,
          size: 32,
        ),
      ),
    );
  }
}
