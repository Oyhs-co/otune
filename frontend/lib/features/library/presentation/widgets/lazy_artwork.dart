import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/design_system/widgets/artwork_placeholder.dart';
import 'package:otune/features/library/application/library_providers.dart';

/// Artwork de biblioteca resuelto bajo demanda (SPEC artwork-management,
/// FR-AW-003): la fila consulta el blob sólo cuando se construye y muestra
/// el placeholder estable si la pista no tiene carátula, fue descartada por
/// tamaño o dejó de existir.
class LazyArtwork extends ConsumerStatefulWidget {
  const LazyArtwork({
    required this.trackId,
    this.size = ArtworkSize.small,
    super.key,
  });

  final String trackId;
  final ArtworkSize size;

  @override
  ConsumerState<LazyArtwork> createState() => _LazyArtworkState();
}

class _LazyArtworkState extends ConsumerState<LazyArtwork> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  Future<void> _resolve() async {
    final cache = ref.read(artworkCacheProvider);
    if (cache.contains(widget.trackId)) {
      if (!mounted) return;
      setState(() => _bytes = cache.get(widget.trackId));
      return;
    }

    try {
      final bytes = await ref
          .read(libraryRepositoryProvider)
          .getTrackArtwork(widget.trackId);
      if (!mounted) return;
      cache.put(widget.trackId, bytes);
      setState(() => _bytes = bytes);
    } on Object {
      // Pista eliminada o base de datos no disponible: placeholder.
      if (!mounted) return;
      setState(() => _bytes = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArtworkPlaceholder(
      size: widget.size,
      child: _bytes != null
          ? Image.memory(
              _bytes!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            )
          : null,
    );
  }
}
