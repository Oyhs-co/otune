import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/application/playback_controller.dart';

class ArtworkPanel extends ConsumerWidget {
  const ArtworkPanel({super.key, this.size = 140, this.isLarge = false});

  final double size;
  final bool isLarge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playbackControllerProvider);
    final track = session.currentTrack;
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(isLarge ? 20 : 12),
        boxShadow: isLarge
            ? [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isLarge ? 20 : 12),
        child: track?.albumArt != null
            ? Image.memory(
                track!.albumArt!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : Icon(
                Icons.music_note_rounded,
                size: size * 0.4,
                color: theme.colorScheme.primary,
              ),
      ),
    );
  }
}
