import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/design_system/design_tokens.dart';
import 'package:otune/core/design_system/widgets/artwork_placeholder.dart';
import 'package:otune/features/lyrics/presentation/widgets/lyrics_widget.dart';
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
  bool _showLyrics = false;

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
    final artist =
        track?.artist ??
        (track == null
            ? 'Carga una pista para comenzar'
            : 'Artista desconocido');

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
            icon: Icon(
              _showLyrics ? Icons.music_note_rounded : Icons.lyrics_rounded,
              color: _showLyrics ? theme.colorScheme.primary : null,
            ),
            onPressed: () => setState(() => _showLyrics = !_showLyrics),
            tooltip: _showLyrics ? 'Mostrar portada' : 'Mostrar letras',
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 480
              ? DesignTokens.spaceM
              : DesignTokens.spaceXL;
          final contentHeight = constraints.maxHeight < 700 ? 300.0 : 380.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              DesignTokens.spaceL,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: contentHeight,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showLyrics
                        ? const Center(
                            key: ValueKey('lyrics'),
                            child: LyricsWidget(),
                          )
                        : Column(
                            key: const ValueKey('artwork'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  child: ArtworkPlaceholder(
                                    size: ArtworkSize.large,
                                    child: track?.albumArt != null
                                        ? Image.memory(
                                            track!.albumArt!,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: DesignTokens.spaceL),
                              Text(
                                title,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: DesignTokens.spaceS),
                              Text(
                                artist,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceM),
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
                    await controller.seek(
                      Duration(milliseconds: newMs.toInt()),
                    );
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
                        style: theme.textTheme.labelMedium,
                      ),
                      Text(
                        _formatDuration(duration),
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        session.isShuffle
                            ? Icons.shuffle_rounded
                            : Icons.shuffle,
                        color: session.isShuffle
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      onPressed: controller.toggleShuffle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, size: 48),
                      onPressed: controller.skipPrevious,
                    ),
                    FloatingActionButton.large(
                      onPressed: controller.togglePlayPause,
                      child: Icon(
                        session.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 48,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 48),
                      onPressed: controller.skipNext,
                    ),
                    IconButton(
                      icon: Icon(
                        session.repeatMode == RepeatMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: session.repeatMode != RepeatMode.off
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      onPressed: controller.cycleRepeatMode,
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spaceL),
              ],
            ),
          );
        },
      ),
    );
  }
}
