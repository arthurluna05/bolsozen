import 'dart:ui';

/// Tons da prancha TEL-04/TEL-06, isolados para não redesenhar o tema aprovado.
/// Amostras raster variam com antialias/gradiente; não são medidas Figma.
abstract final class FinancialVisualTokens {
  // Paleta da rosca TEL-08; identificação textual acompanha cada segmento.
  static const reportPalette = [
    Color(0xFF0E7D68),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4055),
    Color(0xFF7337D2),
    Color(0xFF2876ED),
    Color(0xFFA7F3D0),
    Color(0xFF6B7280),
  ];
  static const balanceStart = Color(0xFF01855C);
  static const balanceEnd = Color(0xFF00694C);
  static const avatar = Color(0xFF7AE09D);
  static const food = Color(0xFFEF4055);
  static const foodSurface = Color(0xFFFEE1E3);
  static const transport = Color(0xFF2876ED);
  static const transportSurface = Color(0xFFDAE5FD);
  static const leisure = Color(0xFF7337D2);
  static const leisureSurface = Color(0xFFEEE2FC);
  static const shopping = Color(0xFFF58B16);
  static const shoppingSurface = Color(0xFFFEEEDC);
  static const incomeSurface = Color(0xFFCEFDDE);
  // Contraste de texto pequeno preservado, próximo ao vermelho da referência.
  static const expenseText = Color(0xFFD91032);

  /// Texto de controles sobre rosa, com contraste >= 4,5:1.
  static const expenseControlText = Color(0xFFC4102D);
}
