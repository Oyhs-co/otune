import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/design_system/widgets/artwork_placeholder.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/domain/entities/playback_modes.dart';

class NowPlayingPage extends ConsumerStatefulWidget {
  const NowPlayingPage({super.key});

  @override
  ConsumerState<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends ConsumerState<NowPlayingPage> {
  double? _dragPositionMs;
  String? _dragTrackId;

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);

    final track = session.currentTrack;
    final title = track?.title ?? 'Sin pista seleccionada';
    final artist = track?.artist ?? (track == null ? 'Carga una pista para comenzar' : 'Artista desconocido');

    final position = session.position;
    final duration = session.duration;
    final maxDurationMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final currentPosMs = position.inMilliseconds.clamp(0, maxDurationMs.toInt()).toDouble();
    final sliderPositionMs = _dragTrackId == track?.id ? (_dragPositionMs ?? currentPosMs) : currentPosMs;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {}, // Add track options later
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Artwork
            Center(
              child: ArtworkPlaceholder(
                size: ArtworkSize.large,
                child: track?.albumArt != null
                    ? Image.memory(track!.albumArt!, fit: BoxFit.cover)
                    : null,
              ),
            ),
            const SizedBox(height: 48),
            // Track Info
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              artist,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 48),
            // Progress Slider
            Slider(
              value: sliderPositionMs.clamp(0, maxDurationMs),
              max: maxDurationMs,
              onChanged: (newMs) {
                setState(() {
                  _dragTrackId = track?.id;
                  _dragPositionMs = newMs;
                });
              },
              onChangeEnd: (newMs) async {
                await controller.seek(Duration(milliseconds: newMs.toInt()));
                setState(() {
                  _dragPositionMs = null;
                  _dragTrackId = null;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position), style: theme.textTheme.labelMedium),
                  Text(_formatDuration(duration), style: theme.textTheme.labelMedium),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Main Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    session.isShuffle ? Icons.shuffle_rounded : Icons.shuffle,
                    color: session.isShuffle ? theme.colorScheme.primary : null,
                  ),
                  onPressed: controller.toggleShuffle,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 48),
                  onPressed: () => controller.skipPrevious(),
                ),
                FloatingActionButton.large(
                  onPressed: () => controller.togglePlayPause(),
                  child: Icon(session.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 48),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 48),
                  onPressed: () => controller.skipNext(),
                ),
                IconButton(
                  icon: Icon(
                    session.repeatMode == RepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                    color: session.repeatMode != RepeatMode.off ? theme.colorScheme.primary : null,
                  ),
                  onPressed: controller.cycleRepeatMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
