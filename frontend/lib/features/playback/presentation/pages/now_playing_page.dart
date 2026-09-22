import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/design_system/design_tokens.dart';
import 'package:otune/features/lyrics/presentation/widgets/lyrics_widget.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/presentation/widgets/artwork_panel.dart';
import 'package:otune/features/playback/presentation/widgets/playback_controls.dart';
import 'package:otune/features/playback/presentation/widgets/playback_progress.dart';
import 'package:otune/features/playback/presentation/widgets/queue_sheet.dart';
import 'package:otune/features/playback/presentation/widgets/track_info.dart';

class NowPlayingPage extends ConsumerStatefulWidget {
  const NowPlayingPage({super.key});

  @override
  ConsumerState<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends ConsumerState<NowPlayingPage> {
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);

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
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () => QueueSheet.show(context),
            tooltip: 'Cola de reproducción',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'remove') {
                controller.removeFromQueue(session.currentTrack?.id ?? '');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'remove',
                enabled: session.currentTrack != null,
                child: const Text('Eliminar de la cola'),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 480
              ? DesignTokens.spaceM
              : DesignTokens.spaceXL;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              DesignTokens.spaceL,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: DesignTokens.artworkLarge,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showLyrics
                          ? const Center(
                              key: ValueKey('lyrics'),
                              child: LyricsWidget(),
                            )
                          : const Column(
                              key: ValueKey('artwork'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ArtworkPanel(size: 300, isLarge: true),
                                SizedBox(height: DesignTokens.spaceL),
                                TrackInfo(isHeadline: true),
                              ],
                            ),
                    ),
                  ),
                ),
                const PlaybackProgress(),
                const PlaybackControls(),
              ],
            ),
          );
        },
      ),
    );
  }
}
