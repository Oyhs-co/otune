import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/features/lyrics/data/repositories/local_lyrics_repository.dart';
import 'package:otune/features/lyrics/data/services/lrc_parser_impl.dart';
import 'package:otune/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:otune/features/lyrics/domain/services/lrc_parser.dart';

/// Proveedor del parser de LRC.
final lrcParserProvider = Provider<LrcParser>((ref) {
  return LrcParserImpl();
});

/// Proveedor del repositorio de letras.
final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) {
  final parser = ref.watch(lrcParserProvider);
  return LocalLyricsRepository(parser);
});
