import 'package:flutter/material.dart';
import 'package:otune/core/design_system/design_tokens.dart';

/// Define los tamaños estándar para las portadas de música en la aplicación.
enum ArtworkSize {
  small,
  medium,
  large,
}

class ArtworkPlaceholder extends StatelessWidget {
  const ArtworkPlaceholder({
    super.key,
    required this.size,
    this.child,
  });

  final ArtworkSize size;
  final Widget? child;

  double get _dimension {
    switch (size) {
      case ArtworkSize.small:
        return DesignTokens.artworkSmall;
      case ArtworkSize.medium:
        return DesignTokens.artworkMedium;
      case ArtworkSize.large:
        return DesignTokens.artworkLarge;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dimension,
      height: _dimension,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: child ?? _buildDefaultPlaceholder(context),
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.music_note,
        size: _dimension * 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
    );
  }
}
