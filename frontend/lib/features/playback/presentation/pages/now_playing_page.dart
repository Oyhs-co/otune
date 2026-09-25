import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/design_system/design_tokens.dart';
import 'package:otune/features/lyrics/presentation/widgets/lyrics_widget.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/domain/entities/playback_failure.dart';
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
/// La zona central limita el artwork según el ancho disponible y la altura
/// real, escalando los espacios y el tamaño del artwork mediante
/// [DesignTokens.scale] para aprovechar todo el espacio disponible en
/// tablets y pantallas grandes, y usando [SafeArea] para respetar la barra
/// de estado y la barra de navegación de Android.
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
    final failureState = ref.watch(playbackFailureProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final scale = DesignTokens.scale(MediaQuery.sizeOf(context).width);

    // El error se muestra mientras el motor lo reporta y también cuando la
    // reproducción quedó detenida por la política de fallos (DR-003 de la
    // SPEC playback_error_policy): el motor en idle no debe ocultarlo.
    final engineError = session.playback.hasError;
    final stalledFailure =
        failureState.failure != null && !session.isPlaying && !engineError
        ? failureState.failure
        : null;

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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 480;
            final horizontalPadding = isNarrow
                ? DesignTokens.spaceM * scale
                : DesignTokens.spaceXL * scale;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                DesignTokens.spaceL * scale,
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
                              scale: scale,
                            ),
                    ),
                  ),
                  // Superficie de error accionable (S3-3): aparece sobre el
                  // progreso cuando el motor reporta un fallo o cuando la
                  // reproducción se detuvo por la política de fallos.
                  if (engineError || stalledFailure != null) ...[
                    _PlaybackErrorBanner(
                      failure: engineError
                          ? PlaybackFailure.categorize(
                              engineMessage: session.playback.errorMessage,
                              uri: session.currentTrack?.uri ?? '',
                            )
                          : stalledFailure!,
                      onRetry: () => unawaited(controller.retryCurrentTrack()),
                    ),
                    SizedBox(height: DesignTokens.spaceS * scale),
                  ],
                  // Progreso y controles: tamaño fijo, anclados abajo.
                  const PlaybackProgress(),
                  SizedBox(height: DesignTokens.spaceS * scale),
                  const PlaybackControls(),
                  const SizedBox(height: DesignTokens.spaceXS),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Banner de error de reproducción con acción de reintento (S3-3).
class _PlaybackErrorBanner extends StatelessWidget {
  const _PlaybackErrorBanner({required this.failure, required this.onRetry});

  final PlaybackFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: Text(
              failure.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceS),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

/// Sección de portada e información de pista, centrada en el espacio
/// disponible, con el artwork escalado al alto y ancho reales sin desbordar.
class _ArtworkSection extends StatelessWidget {
  const _ArtworkSection({
    required this.availableWidth,
    required this.scale,
    super.key,
  });

  /// Ancho útil del cuerpo de la página ya sin padding horizontal.
  final double availableWidth;

  /// Factor de escala responsivo derivado del ancho de pantalla.
  final double scale;

  /// Espacio vertical reservado para la información de pista y el
  /// espaciado entre artwork y textos.
  static const double _infoReservedHeight = 96;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        // Artwork más grande en pantallas anchos (tabletas, foldables).
        final artworkMax = availableWidth >= 600
            ? DesignTokens.artworkXLarge
            : DesignTokens.artworkLarge;
        final artworkSize = max(
          DesignTokens.artworkMedium,
          min(
            artworkMax,
            min(availableWidth, maxHeight - _infoReservedHeight * scale),
          ),
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ArtworkPanel(size: artworkSize, isLarge: true),
            SizedBox(height: DesignTokens.spaceL * scale),
            // Los textos largos se truncan; la info no desplaza el artwork.
            const TrackInfo(isHeadline: true),
          ],
        );
      },
    );
  }
}
