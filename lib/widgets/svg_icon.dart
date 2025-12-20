import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG 图标组件，支持本地和网络 SVG
class SvgIcon extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final ColorFilter? colorFilter;

  const SvgIcon({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.colorFilter,
  });

  bool get isNetworkPath => path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (isNetworkPath) {
      return SvgPicture.network(
        path,
        width: width,
        height: height,
        colorFilter: colorFilter,
        placeholderBuilder: (_) => _buildPlaceholder(),
        errorBuilder: (context, error, stackTrace) {
          debugPrint('SvgIcon network error: $error for $path');
          return _buildErrorIcon();
        },
      );
    } else {
      return SvgPicture.asset(
        path,
        width: width,
        height: height,
        colorFilter: colorFilter,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('SvgIcon asset error: $error for $path');
          return _buildErrorIcon();
        },
      );
    }
  }

  Widget _buildPlaceholder() {
    return SizedBox(
      width: width ?? 24,
      height: height ?? 24,
      child: const Center(
        child: SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Icon(
      Icons.music_note,
      size: (width ?? height ?? 24) * 0.8,
      color: Colors.white24,
    );
  }
}
