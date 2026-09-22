import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/application/playback_controller.dart';

class PlaybackProgress extends ConsumerStatefulWidget {
  const PlaybackProgress({super.key});

  @override
  ConsumerState<PlaybackProgress> createState() => _PlaybackProgressState();
}

class _PlaybackProgressState extends ConsumerState<PlaybackProgress> {
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
    final session = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final theme = Theme.of(context);

    final track = session.currentTrack;
    final position = session.position;
    final duration = session.duration;

    final maxDurationMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final currentPosMs = position.inMilliseconds
        .clamp(0, maxDurationMs.toInt())
        .toDouble();
    final sliderPositionMs = _dragTrackId == track?.id
        ? (_dragPositionMs ?? currentPosMs)
        : currentPosMs;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              Text(
                _formatDuration(position),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatDuration(duration),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
