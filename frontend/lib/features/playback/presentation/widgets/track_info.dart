import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/application/playback_controller.dart';

class TrackInfo extends ConsumerWidget {
  const TrackInfo({super.key, this.isCentered = true, this.isHeadline = false});

  final bool isCentered;
  final bool isHeadline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playbackControllerProvider);
    final track = session.currentTrack;
    final theme = Theme.of(context);

    final title = track?.title ?? 'Sin pista seleccionada';
    final artist =
        track?.artist ??
        (track == null
            ? 'Carga una pista para comenzar'
            : 'Artista desconocido');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isCentered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: isHeadline
              ? theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )
              : theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          artist,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
