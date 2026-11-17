import 'package:firebase_core/firebase_core.dart';

enum DataFailureKind {
  unauthenticated,
  sessionChanged,
  permissionDenied,
  unavailable,
  notFound,
  invalidData,
  unknown,
}

final class DataFailure implements Exception {
  const DataFailure(this.kind, this.message);
  final DataFailureKind kind;
  final String message;
  @override
  String toString() => message;
}

Future<T> guardData<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on DataFailure {
    rethrow;
  } on FirebaseException catch (error) {
    throw switch (error.code) {
      'permission-denied' => const DataFailure(
        DataFailureKind.permissionDenied,
        'Você não tem permissão para acessar esses dados.',
      ),
      'unauthenticated' => const DataFailure(
        DataFailureKind.unauthenticated,
        'Entre na sua conta para continuar.',
      ),
      'not-found' => const DataFailure(
        DataFailureKind.notFound,
        'Registro não encontrado.',
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => const DataFailure(
        DataFailureKind.unavailable,
        'Não foi possível acessar os dados. Verifique sua conexão e tente novamente.',
      ),
      _ => const DataFailure(
        DataFailureKind.unknown,
        'Não foi possível concluir a operação. Tente novamente.',
      ),
    };
  } on ArgumentError {
    throw const DataFailure(
      DataFailureKind.invalidData,
      'Os dados informados são inválidos.',
    );
  } on FormatException {
    throw const DataFailure(
      DataFailureKind.invalidData,
      'O registro contém dados inválidos.',
    );
  }
}
