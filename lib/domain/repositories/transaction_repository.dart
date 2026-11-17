import '../models/category.dart';
import '../models/financial_transaction.dart';

/// Implementações futuras são vinculadas a um único UID autenticado.
/// Cursor deve pertencer à mesma consulta/usuário; null inicia a leitura.
abstract interface class TransactionRepository {
  Future<List<FinancialTransaction>> fetchPage({
    FinancialTransaction? after,
    int limit = 100,
  });

  /// Gera ID na camada de dados; auditoria e UID não são escolhidos pela tela.
  Future<String> create({
    required TransactionType type,
    required int amountCents,
    required Category category,
    required String description,
    required DateTime occurredAt,
  });
  Future<void> update(FinancialTransaction transaction);
  Future<void> delete(String id);
}
