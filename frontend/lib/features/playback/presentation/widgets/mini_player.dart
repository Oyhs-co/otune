import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otune/core/design_system/design_tokens.dart';
import 'package:otune/core/design_system/widgets/artwork_placeholder.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/domain/entities/playback_failure.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

/// Mini-reproductor persistente que vive en el AppShell.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final track = session.currentTrack;

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        reverseDuration: const Duration(milliseconds: 160),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: track == null
            ? const SizedBox(key: ValueKey('empty-mini-player'))
            : _MiniPlayerContent(
                key: ValueKey(track.id),
                track: track,
                isPlaying: session.isPlaying,
                errorMessage: session.playback.hasError
                    ? PlaybackFailure.categorize(
                        engineMessage: session.playback.errorMessage,
                        uri: track.uri,
                      ).message
                    : null,
                onTap: () => _navigateToNowPlaying(context),
                onPrevious: () => unawaited(controller.skipPrevious()),
                onPlayPause: () => unawaited(controller.togglePlayPause()),
                onNext: () => unawaited(controller.skipNext()),
              ),
      ),
    );
  }

  void _navigateToNowPlaying(BuildContext context) {
    unawaited(context.pushNamed('now-playing'));
  }
}

class _MiniPlayerContent extends StatelessWidget {
  const _MiniPlayerContent({
    required this.track,
    required this.isPlaying,
    required this.onTap,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    this.errorMessage,
    super.key,
  });

  final TrackRef track;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  /// Mensaje de error clasificado mostrado en lugar del artista cuando la
  /// reproducción falla (S3-3).
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: DesignTokens.spaceXS,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
              vertical: DesignTokens.spaceS,
            ),
            child: Row(
              children: [
                ArtworkPlaceholder(
                  size: ArtworkSize.small,
                  child: track.albumArt != null
                      ? Image.memory(track.albumArt!, fit: BoxFit.cover)
                      : null,
                ),
                const SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        errorMessage ?? track.artist ?? 'Artista desconocido',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: errorMessage == null
                            ? null
                            : TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontStyle: FontStyle.italic,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceXS),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  tooltip: 'Pista anterior',
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: onPrevious,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  tooltip: isPlaying ? 'Pausar' : 'Reproducir',
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  onPressed: onPlayPause,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  tooltip: 'Siguiente pista',
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: onNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
