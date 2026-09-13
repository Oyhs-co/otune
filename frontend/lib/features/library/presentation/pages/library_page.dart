import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/application/state/library_scan_state.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:file_picker/file_picker.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  Future<void> _handleScanFolder(WidgetRef ref) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    await ref.read(libraryScanProvider.notifier).scanDirectory(selectedDirectory);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scanState = ref.watch(libraryScanProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Biblioteca'),
        actions: [
          IconButton(
            icon: scanState.isScanning 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.folder_open),
            onPressed: scanState.isScanning ? null : () => _handleScanFolder(ref),
            tooltip: 'Escanear carpeta',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              scanState.status,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LibraryTrack>>(
              future: ref.read(libraryRepositoryProvider).getAllTracks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar la biblioteca: ${snapshot.error}'));
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Center(
                    child: Text('No hay canciones. ¡Escanea una carpeta para empezar!'),
                  );
                }

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final track = list[index];
                    return ListTile(
                      title: Text(track.title),
                      subtitle: Text('${track.artist ?? 'Artista desconocido'} • ${track.album ?? 'Álbum desconocido'}'),
                      trailing: const Icon(Icons.play_arrow_rounded),
                      onTap: () {
                        ref.read(playbackControllerProvider.notifier).playTrack(
                          TrackRef(id: track.id, uri: 'file://${track.path}', title: track.title),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
