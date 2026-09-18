import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otune/core/design_system/widgets/artwork_placeholder.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/queue_view_provider.dart';
import 'package:otune/features/playback/domain/entities/playback_session.dart';
import 'package:otune/features/playback/domain/entities/queue_item.dart';
import 'package:otune/features/playback/domain/entities/queue_view_mode.dart';

/// Superficie adaptativa para visualizar y gestionar la cola.
class QueueSheet extends ConsumerWidget {
  const QueueSheet({this.asDialog = false, super.key});

  final bool asDialog;

  static void show(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    unawaited(
      isWide
          ? showDialog<void>(
              context: context,
              builder: (context) => const Dialog(
                child: SizedBox(
                  width: 520,
                  height: 680,
                  child: QueueSheet(asDialog: true),
                ),
              ),
            )
          : showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => const QueueSheet(),
            ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final viewMode = ref.watch(queueViewModeProvider);

    if (asDialog) {
      return _buildContent(
        context,
        ref,
        theme,
        session,
        controller,
        viewMode,
        null,
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: _buildContent(
                context,
                ref,
                theme,
                session,
                controller,
                viewMode,
                scrollController,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    PlaybackSession session,
    PlaybackController controller,
    QueueViewMode viewMode,
    ScrollController? scrollController,
  ) {
    final items = session.queueItems;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Cola de reproducción (${items.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<QueueViewMode>(
                tooltip: 'Cambiar vista de la cola',
                icon: const Icon(Icons.view_module_outlined),
                onSelected: (mode) =>
                    ref.read(queueViewModeProvider.notifier).mode = mode,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: QueueViewMode.list,
                    child: Text('Lista'),
                  ),
                  const PopupMenuItem(
                    value: QueueViewMode.detailed,
                    child: Text('Detallado'),
                  ),
                ],
              ),
              if (items.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                  label: const Text('Vaciar'),
                  onPressed: () {
                    final snapshot = session.queue;
                    unawaited(controller.clearQueue());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Cola vaciada'),
                        action: SnackBarAction(
                          label: 'Deshacer',
                          onPressed: () =>
                              unawaited(controller.restoreQueue(snapshot)),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (items.isEmpty)
          Expanded(child: _buildEmptyState(context, theme))
        else ...[
          _buildSectionLabel(
            theme,
            session.currentTrack == null
                ? 'A continuación'
                : 'Reproduciendo ahora · ${session.currentTrack!.title}',
          ),
          _buildSectionLabel(theme, 'A continuación'),
          Expanded(
            child: _buildQueueList(
              context,
              scrollController,
              items,
              session,
              controller,
              theme,
              viewMode,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.queue_music, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'La cola está vacía',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.library_music),
            label: const Text('Ir a la biblioteca'),
            onPressed: () {
              Navigator.of(context).pop();
              context.goNamed('library');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(
    BuildContext context,
    ScrollController? scrollController,
    List<QueueItem> items,
    PlaybackSession session,
    PlaybackController controller,
    ThemeData theme,
    QueueViewMode viewMode,
  ) {
    return ReorderableListView.builder(
      scrollController: scrollController,
      itemCount: items.length,
      onReorderItem: (oldIndex, newIndex) {
        controller.moveQueueItem(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final isCurrent = index == session.currentIndex;
        final artwork = item.track.albumArt == null
            ? Icon(
                isCurrent ? Icons.volume_up_rounded : Icons.music_note_rounded,
                color: isCurrent
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              )
            : ArtworkPlaceholder(
                size: ArtworkSize.small,
                child: Image.memory(item.track.albumArt!, fit: BoxFit.cover),
              );

        return ListTile(
          key: ValueKey(item.id),
          leading: artwork,
          title: Text(
            item.track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: viewMode == QueueViewMode.detailed
              ? Text(
                  '${item.track.artist ?? 'Artista desconocido'}\n'
                  '${item.track.uri}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : Text(
                  item.track.artist ?? 'Artista desconocido',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Eliminar de la cola',
                onPressed: () => _removeItem(context, controller, item, index),
              ),
              const Icon(Icons.drag_handle),
            ],
          ),
          onTap: () => unawaited(controller.playQueueItem(index)),
        );
      },
    );
  }

  void _removeItem(
    BuildContext context,
    PlaybackController controller,
    QueueItem item,
    int index,
  ) {
    controller.removeFromQueue(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.track.title}" eliminado'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => controller.restoreQueueItem(item, index),
        ),
      ),
    );
  }
}
