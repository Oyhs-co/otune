import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/lyrics/application/lyrics_sync_notifier.dart';
import 'package:otune/features/playback/application/playback_controller.dart';

class LyricsWidget extends ConsumerStatefulWidget {
  const LyricsWidget({super.key});

  @override
  ConsumerState<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends ConsumerState<LyricsWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(int index) {
    if (index < 0) return;
    final offset = index * 45.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset - (MediaQuery.of(context).size.height / 3),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lyricsSyncProvider);
    final controller = ref.read(playbackControllerProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveLine(state.currentLineIndex);
    });

    if (state.lyrics == null || state.lyrics!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay letras disponibles para esta pista',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final lines = state.lyrics!.lines;
    final currentIndex = state.currentLineIndex;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.3,
      ),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        final isActive = index == currentIndex;

        return InkWell(
          onTap: () async {
            await controller.seek(line.timestamp);
          },
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: isActive ? 24 : 18,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Text(line.text, textAlign: TextAlign.center),
            ),
          ),
        );
      },
    );
  }
}
