import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/design_system/providers/badge_provider.dart';
import 'package:otune/core/permissions/permission_service.dart';
import 'package:otune/features/library/application/library_search_provider.dart';
import 'package:otune/features/library/application/library_view_provider.dart';
import 'package:otune/features/library/application/state/library_scan_state.dart';
import 'package:otune/features/library/domain/entities/track.dart';
import 'package:otune/features/library/presentation/widgets/library_empty_state.dart';
import 'package:otune/features/library/presentation/widgets/library_scan_banner.dart';
import 'package:otune/features/library/presentation/widgets/library_track_list.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/domain/entities/track_ref.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(librarySearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleScanFolder() async {
    final hasPermission = await PermissionService().requestMediaPermissions();

    if (!hasPermission) {
      if (!mounted) return;
      ref
          .read(badgeProvider.notifier)
          .show(
            message:
                'Se requiere permiso de almacenamiento para escanear música',
            type: BadgeType.error,
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
        .playTrack(TrackRef.fromLibraryTrack(track));
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(libraryViewModeProvider);

    // El shell adaptativo proporciona el AppBar con el título de sección y
    // las acciones de biblioteca; la página no monta barras propias.
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const LibraryScanBanner(),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar canciones, artistas...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(librarySearchQueryProvider.notifier)
                                  .updateQuery('');
                              setState(() {});
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    ref
                        .read(librarySearchQueryProvider.notifier)
                        .updateQuery(value.trim());
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LibraryTrack>>(
              future: ref.watch(filteredTracksProvider.future),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar la biblioteca: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(filteredTracksProvider);
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final tracks = snapshot.data ?? <LibraryTrack>[];
                final query = ref.watch(libraryDebouncedQueryProvider).trim();
                if (tracks.isEmpty) {
                  return LibraryEmptyState(
                    message: query.isEmpty
                        ? 'Tu biblioteca está vacía'
                        : 'No hay canciones que coincidan con "$query"',
                    buttonText: query.isEmpty ? 'Escanear carpeta' : '',
                    onButtonPressed: _handleScanFolder,
                    icon: query.isEmpty ? Icons.music_note : Icons.search_off,
                  );
                }

                return LibraryTrackList(
                  tracks: tracks,
                  onTrackSelected: _playTrack,
                  viewMode: viewMode,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
