/// Conversão textual exata, sem ponto flutuante. Entradas são valores positivos.
abstract final class Money {
  /// Faixa interoperável com os inteiros do SDK JavaScript/Firestore Web.
  static const maxSafeCents = 9007199254740991;
  static const isJavaScript = bool.fromEnvironment('dart.library.js_interop');

  static void requireSafeCents(int cents) {
    if (cents > maxSafeCents || cents < -maxSafeCents) {
      throw const FormatException(
        'Valor excede a precisão suportada. Máximo: R\$ 90.071.992.547.409,91.',
      );
    }
  }

  static int parseCents(String input) {
    final text = input.trim().replaceFirst(RegExp(r'^R\$\s*'), '');
    if (!RegExp(r'^(?:[0-9]+|[0-9]{1,3}(?:\.[0-9]{3})+)(?:,[0-9]{1,2})?$')
        .hasMatch(text)) {
      throw const FormatException('Valor monetário inválido');
    }
    final parts = text.replaceAll('.', '').split(',');
    final digits =
        parts[0] + (parts.length == 2 ? parts[1].padRight(2, '0') : '00');
    final cents = BigInt.parse(digits);
    if (cents <= BigInt.zero) {
      throw const FormatException(
        'Informe valor maior que zero em centavos válidos',
      );
    }
    if (cents > BigInt.from(maxSafeCents)) {
      throw const FormatException(
        'Valor excede a precisão suportada. Máximo: R\$ 90.071.992.547.409,91.',
      );
    }
    return cents.toInt();
  }

  /// Também apresenta saldo zero/negativo, sem converter dinheiro para double.
  static String formatCents(int cents) {
    // A VM conserva a formatação histórica de inteiros nativos exatos.
    // Na Web, recusar inclusive números arredondados antes desta chamada.
    if (isJavaScript) requireSafeCents(cents);
    final digits = BigInt.from(cents).abs().toString().padLeft(3, '0');
    final whole = digits
        .substring(0, digits.length - 2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (match) => '${match[1]}.',
        );
    return '${cents < 0 ? '-' : ''}R\$ $whole,${digits.substring(digits.length - 2)}';
  }
}
