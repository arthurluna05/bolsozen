/// Conversão textual exata, sem ponto flutuante. Entradas são valores positivos.
abstract final class Money {
  static int parseCents(String input) {
    final text = input.trim().replaceFirst(RegExp(r'^R\$\s*'), '');
    if (!RegExp(r'^(?:[0-9]+|[0-9]{1,3}(?:\.[0-9]{3})+)(?:,[0-9]{1,2})?$')
        .hasMatch(text)) {
      throw const FormatException('Valor monetário inválido');
    }
    final parts = text.replaceAll('.', '').split(',');
    final digits =
        parts[0] + (parts.length == 2 ? parts[1].padRight(2, '0') : '00');
    final cents = int.tryParse(digits);
    if (cents == null || cents <= 0) {
      throw const FormatException(
        'Informe valor maior que zero em centavos válidos',
      );
    }
    return cents;
  }

  /// Também apresenta saldo zero/negativo, sem converter dinheiro para double.
  static String formatCents(int cents) {
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
