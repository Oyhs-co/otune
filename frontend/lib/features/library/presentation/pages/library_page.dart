import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/domain/services/library_scanner.dart';
import 'package:otune/features/library/data/services/file_system_library_scanner.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';
import 'package:file_picker/file_picker.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool _isScanning = false;
  String _scanStatus = 'No se ha realizado ningún escaneo';

  Future<void> _handleScanFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    setState(() {
      _isScanning = true;
      _scanStatus = 'Escaneando...';
    });

    final db = ref.read(databaseProvider);
    final scanner = FileSystemLibraryScanner(db);

    await for (final event in scanner.scanDirectory(selectedDirectory)) {
      if (event is ScanProgress) {
        setState(() {
          _scanStatus = 'Procesando: ${event.currentFile} (${event.filesProcessed}/${event.totalFilesFound})';
        });
      } else if (event is ScanComplete) {
        setState(() {
          _scanStatus = 'Escaneo completado. ${event.totalTracksIndexed} pistas indexadas.';
          _isScanning = false;
        });
      } else if (event is ScanError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${event.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Biblioteca'),
        actions: [
          IconButton(
            icon: _isScanning 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.folder_open),
            onPressed: _isScanning ? null : _handleScanFolder,
            tooltip: 'Escanear carpeta',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _scanStatus,
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
          ],
        ),
      ),
    );
  }
}
