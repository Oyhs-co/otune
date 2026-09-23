import 'dart:math';

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

/// Pantalla de reproducción actual.
///
/// Layout (columna vertical):
/// 1. zona flexible con portada/letras + información de pista;
/// 2. barra de progreso;
/// 3. controles de reproducción.
///
/// La zona central limita el artwork a `DesignTokens.artworkLarge` y escala
/// según el ancho y alto reales para evitar overflow y huecos descompensados.
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
          final isNarrow = constraints.maxWidth < 480;
          final horizontalPadding = isNarrow
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
              children: [
                // Zona flexible: portada + título (o letras). Ocupa el resto
                // del espacio y centra su contenido verticalmente.
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showLyrics
                        ? const Center(
                            key: ValueKey('lyrics'),
                            child: LyricsWidget(),
                          )
                        : _ArtworkSection(
                            key: const ValueKey('artwork'),
                            availableWidth:
                                constraints.maxWidth - horizontalPadding * 2,
                          ),
                  ),
                ),
                // Progreso y controles: tamaño fijo, anclados abajo.
                const PlaybackProgress(),
                const SizedBox(height: DesignTokens.spaceS),
                const PlaybackControls(),
                const SizedBox(height: DesignTokens.spaceXS),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Sección de portada e información de pista, centrada en el espacio
/// disponible, con el artwork escalado al alto y ancho reales sin desbordar.
class _ArtworkSection extends StatelessWidget {
  const _ArtworkSection({required this.availableWidth, super.key});

  /// Ancho útil del cuerpo de la página ya sin padding horizontal.
  final double availableWidth;

  /// Espacio vertical reservado para la información de pista y el
  /// espaciado entre artwork y textos.
  static const double _infoReservedHeight = 96;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final artworkSize = max(
          DesignTokens.artworkMedium,
          min(
            DesignTokens.artworkLarge,
            min(availableWidth, maxHeight - _infoReservedHeight),
          ),
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ArtworkPanel(size: artworkSize, isLarge: true),
            const SizedBox(height: DesignTokens.spaceL),
            // Los textos largos se truncan; la info no desplaza el artwork.
            const TrackInfo(isHeadline: true),
          ],
        );
      },
    );
  }
}
