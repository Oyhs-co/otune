import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otune/core/permissions/permission_service.dart';
import 'package:otune/features/library/application/library_providers.dart';
import 'package:otune/features/library/application/state/library_scan_state.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/presentation/widgets/library_track_list.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  Future<void> _handleScanFolder() async {
    final hasPermission = await PermissionService().requestMediaPermissions();

    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se requiere permiso de almacenamiento para escanear música',
          ),
        ),
      );
      return;
    }

    final selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory == null || !mounted) return;

    await ref
        .read(libraryScanProvider.notifier)
        .scanDirectory(selectedDirectory);
  }

  Future<void> _playTrack(LibraryTrack track) async {
    await ref
        .read(playbackControllerProvider.notifier)
        .playTrack(
          TrackRef(
            id: track.id,
            uri: 'file://${track.path}',
            title: track.title,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(libraryScanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Biblioteca'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: scanState.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open),
            onPressed: scanState.isScanning ? null : _handleScanFolder,
            tooltip: 'Escanear carpeta',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              scanState.status,
              style: Theme.of(context).textTheme.bodySmall,
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
                  return Center(
                    child: Text(
                      'Error al cargar la biblioteca: ${snapshot.error}',
                    ),
                  );
                }

                final tracks = snapshot.data ?? <LibraryTrack>[];
                if (tracks.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay canciones. ¡Escanea una carpeta para empezar!',
                    ),
                  );
                }

                return LibraryTrackList(
                  tracks: tracks,
                  onTrackSelected: _playTrack,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
