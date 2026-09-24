/// Tokens de diseño globales para mantener la coherencia visual en toda la
/// aplicación.
abstract final class DesignTokens {
  // Espaciado
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXL = 32;

  // Radios de borde
  static const double radiusS = 4;
  static const double radiusM = 8;
  static const double radiusL = 12;
  static const double radiusXL = 20;

  // Tamaños de Artwork
  static const double artworkSmall = 48;
  static const double artworkMedium = 120;
  static const double artworkLarge = 340;
  static const double artworkXLarge = 420;

  /// Factor de escala responsivo basado en el ancho de pantalla.
  /// 1.0 en móvil (~360px), ~1.5 en tableta grande (~800px).
  static double scale(double screenWidth) {
    const minPhone = 360.0;
    const maxTablet = 800.0;
    final t = ((screenWidth - minPhone) / (maxTablet - minPhone)).clamp(
      0.0,
      1.0,
    );
    return 1.0 + t * 0.5;
  }
}
