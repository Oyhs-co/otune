import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otune/core/database/app_database.dart';
import 'package:otune/features/library/data/repositories/drift_library_repository.dart';
import 'package:otune/features/library/domain/repositories/library_repository.dart';

/// Proveedor de la base de datos de la aplicación.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Proveedor del repositorio de la biblioteca.
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftLibraryRepository(db);
});
