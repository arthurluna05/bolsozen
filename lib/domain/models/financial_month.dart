/// Competência mensal no calendário local do dispositivo.
final class FinancialMonth {
  FinancialMonth(this.year, this.month) {
    if (year < 1 || year > 9999 || month < 1 || month > 12) {
      throw ArgumentError('Competência mensal inválida');
    }
  }

  factory FinancialMonth.fromDate(DateTime date) {
    final local = date.toLocal();
    return FinancialMonth(local.year, local.month);
  }

  final int year;
  final int month;
  String get key =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  FinancialMonth shift(int months) {
    final date = DateTime(year, month + months);
    return FinancialMonth(date.year, date.month);
  }

  bool contains(DateTime date) => this == FinancialMonth.fromDate(date);

  @override
  bool operator ==(Object other) =>
      other is FinancialMonth && other.year == year && other.month == month;
  @override
  int get hashCode => Object.hash(year, month);
}
