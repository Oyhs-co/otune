import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/lyrics/application/lyrics_providers.dart';
import 'package:otune/features/lyrics/domain/entities/lyrics.dart';
import 'package:otune/features/lyrics/domain/repositories/lyrics_repository.dart';

/// Estado de la letra activa en la reproducción actual.
class ActiveLyricsState {
  final Lyrics? lyrics;
  final int currentLineIndex;

  const ActiveLyricsState({
    this.lyrics,
    this.currentLineIndex = -1,
  });

  ActiveLyricsState copyWith({
    Lyrics? lyrics,
    int? currentLineIndex,
  }) {
    return ActiveLyricsState(
      lyrics: lyrics ?? this.lyrics,
      currentLineIndex: currentLineIndex ?? this.currentLineIndex,
    );
  }
}

/// Notificador que sincroniza la posición del audio con la línea de la letra.
class LyricsSyncNotifier extends Notifier<ActiveLyricsState> {
  @override
  ActiveLyricsState build() {
    return const ActiveLyricsState();
  }

  Future<void> loadLyrics(String trackId, String filePath) async {
    final repository = ref.read(lyricsRepositoryProvider);
    final lyrics = await repository.getLyricsForTrack(trackId, filePath);
    state = state.copyWith(lyrics: lyrics, currentLineIndex: -1);
  }

  void updatePosition(Duration position) {
    final lyrics = state.lyrics;
    if (lyrics == null || lyrics.isEmpty) return;

    int index = -1;
    for (int i = 0; i < lyrics.lines.length; i++) {
      if (lyrics.lines[i].timestamp <= position) {
        index = i;
      } else {
        break;
      }
    }

    if (index != state.currentLineIndex) {
      state = state.copyWith(currentLineIndex: index);
    }
  }

  void clear() {
    state = const ActiveLyricsState();
  }
}

/// Proveedor del sincronizador de letras.
final lyricsSyncProvider = NotifierProvider<LyricsSyncNotifier, ActiveLyricsState>(() {
  return LyricsSyncNotifier();
});


  ActiveLyricsState copyWith({
    Lyrics? lyrics,
    int? currentLineIndex,
  }) {
    return ActiveLyricsState(
      lyrics: lyrics ?? this.lyrics,
      currentLineIndex: currentLineIndex ?? this.currentLineIndex,
    );
  }
}

/// Notificador que sincroniza la posición del audio con la línea de la letra.
class LyricsSyncNotifier extends StateNotifier<ActiveLyricsState> {
  final LyricsRepository _repository;

  LyricsSyncNotifier(this._repository) : super(const ActiveLyricsState());

  void loadLyrics(String trackId, String filePath) async {
    final lyrics = await _repository.getLyricsForTrack(trackId, filePath);
    state = state.copyWith(lyrics: lyrics, currentLineIndex: -1);
  }

  void updatePosition(Duration position) {
    final lyrics = state.lyrics;
    if (lyrics == null || lyrics.isEmpty) return;

    int index = -1;
    for (int i = 0; i < lyrics.lines.length; i++) {
      if (lyrics.lines[i].timestamp <= position) {
        index = i;
      } else {
        break;
      }
    }

    if (index != state.currentLineIndex) {
      state = state.copyWith(currentLineIndex: index);
    }
  }

  void clear() {
    state = const ActiveLyricsState();
  }
}

/// Proveedor del sincronizador de letras.
final lyricsSyncProvider = StateNotifierProvider<LyricsSyncNotifier, ActiveLyricsState>((ref) {
  final repository = ref.watch(lyricsRepositoryProvider);
  return LyricsSyncNotifier(repository);
});
