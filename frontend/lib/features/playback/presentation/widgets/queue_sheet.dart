import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/playback/application/playback_controller.dart';
import 'package:otune/features/playback/application/queue_view_provider.dart';
import 'package:otune/features/playback/domain/entities/playback_session.dart';
import 'package:otune/features/playback/domain/entities/queue_item.dart';
import 'package:otune/features/playback/domain/entities/queue_view_mode.dart';

/// Hoja modal o vista para visualizar y gestionar los elementos de la cola.
class QueueSheet extends ConsumerWidget {
  const new({super.key});

  /// Abre la cola en un modal inferior estandarizado.
  static void show(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
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
    final items = session.queueItems;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Barra de arrastre
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
            // Cabecera
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cola de reproducción (${items.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      PopupMenuButton<QueueViewMode>(
                        icon: const Icon(Icons.view_module_outlined),
                        onSelected: (mode) =>
                            ref.read(queueViewModeProvider.notifier).mode =
                                mode,
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
                          icon: const Icon(
                            Icons.delete_sweep_rounded,
                            size: 20,
                          ),
                          label: const Text('Vaciar'),
                          onPressed: () {
                            unawaited(controller.clearQueue());
                            Navigator.of(context).pop();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Lista de canciones
            if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'La cola está vacía',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
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
        );
      },
    );
  }

  Widget _buildQueueList(
    BuildContext context,
    ScrollController scrollController,
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
        final key = ValueKey(item.id);

        if (viewMode == QueueViewMode.detailed) {
          return ListTile(
            key: key,
            leading: item.track.albumArt != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.memory(
                      item.track.albumArt!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    isCurrent
                        ? Icons.volume_up_rounded
                        : Icons.music_note_rounded,
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
            title: Text(
              item.track.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.track.artist ?? 'Artista desconocido'),
                Text(item.track.uri, style: theme.textTheme.labelSmall),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => controller.removeFromQueue(item.id),
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
            onTap: () => unawaited(controller.playQueueItem(index)),
          );
        }

        return ListTile(
          key: key,
          leading: item.track.albumArt != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    item.track.albumArt!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  isCurrent
                      ? Icons.volume_up_rounded
                      : Icons.music_note_rounded,
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
          title: Text(
            item.track.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
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
                onPressed: () {
                  controller.removeFromQueue(item.id);
                },
              ),
              const Icon(Icons.drag_handle),
            ],
          ),
          onTap: () {
            unawaited(controller.playQueueItem(index));
          },
        );
      },
    );
  }
}
