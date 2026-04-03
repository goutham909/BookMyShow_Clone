import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Loads network [url] with a simple placeholder and error fallback.
class CatalogImage extends StatelessWidget {
  const CatalogImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final child = Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppTokens.surfaceMuted,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, _, __) => Container(
        color: AppTokens.surfaceMuted,
        alignment: Alignment.center,
        child: Icon(Icons.movie_outlined, color: AppTokens.textSecondary),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
