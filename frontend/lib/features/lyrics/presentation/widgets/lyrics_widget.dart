import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/lyrics/application/lyrics_sync_notifier.dart';

class LyricsWidget extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lyricsSyncProvider);

    if (state.lyrics == null || state.lyrics!.isEmpty) {
      return const Center(
        child: Text('No hay letras disponibles para esta pista'),
      );
    }

    final lines = state.lyrics!.lines;
    final currentIndex = state.currentLineIndex;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        final isActive = index == currentIndex;

        return AnimatedDefaultTextStyle(
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(line.text, textAlign: TextAlign.center),
          ),
        );
      },
    );
  }
}
