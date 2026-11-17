import 'package:bolsozen/domain/models/auth_failure.dart';
import 'package:bolsozen/domain/services/auth_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nome', () {
    for (final input in [
      'Ana',
      '  João da Conceição  ',
      'Li',
      'É🪷',
      'a' * 80,
    ]) {
      test('aceita nome válido ${input.runes.length}', () {
        expect(AuthValidation.name(input), isNull);
      });
    }
    for (final input in ['', ' ', '\t\n', 'A', ' A ', '🪷', 'a' * 81]) {
      test('rejeita nome inválido ${input.runes.length}', () {
        expect(AuthValidation.name(input)?.kind, AuthFailureKind.invalidName);
      });
    }
    test(
      'espaços externos não contam no limite; internos não são removidos',
      () {
        expect(AuthValidation.name('  ${'a' * 80}  '), isNull);
        expect(
          AuthValidation.name('A${' ' * 79}B')?.kind,
          AuthFailureKind.invalidName,
        );
        expect(AuthValidation.name('A B'), isNull);
      },
    );
  });

  group('E-mail', () {
    for (final input in [
      'ana@example.com',
      '  ANA+M4@EXAMPLE.COM  ',
      'joão@exemplo.com',
      'a@sub.example.com',
    ]) {
      test('aceita formato válido $input', () {
        expect(AuthValidation.email(input), isNull);
      });
    }
    for (final input in [
      '',
      ' ',
      'ana',
      '@example.com',
      'ana@',
      'ana@example',
      'a@@b.com',
      'a b@example.com',
      'a@ex ample.com',
      'a\nb@example.com',
    ]) {
      test('rejeita formato inválido $input', () {
        expect(AuthValidation.email(input)?.kind, AuthFailureKind.invalidEmail);
      });
    }
    test(
      'normaliza trim/lowercase, mantém alias e acentuação, é idempotente',
      () {
        const input = '  JOÃO+M4@EXAMPLE.COM  ';
        final normalized = AuthValidation.normalizeEmail(input);
        expect(normalized, 'joão+m4@example.com');
        expect(AuthValidation.normalizeEmail(normalized), normalized);
        expect(input, '  JOÃO+M4@EXAMPLE.COM  ');
      },
    );
  });

  group('Senhas', () {
    test('cadastro exige senha e pelo menos oito caracteres', () {
      expect(
        AuthValidation.registrationPassword('')?.kind,
        AuthFailureKind.passwordRequired,
      );
      expect(
        AuthValidation.registrationPassword('1234567')?.kind,
        AuthFailureKind.weakPassword,
      );
      expect(AuthValidation.registrationPassword('12345678'), isNull);
      expect(AuthValidation.registrationPassword('a' * 1000), isNull);
    });
    test('login exige somente string não vazia, inclusive senha antiga', () {
      expect(
        AuthValidation.loginPassword('')?.kind,
        AuthFailureKind.passwordRequired,
      );
      expect(AuthValidation.loginPassword('a'), isNull);
      expect(AuthValidation.loginPassword(' '), isNull);
      expect(AuthValidation.loginPassword('curta'), isNull);
    });
    test('cadastro conta runes Unicode, não unidades UTF-16', () {
      expect(
        AuthValidation.registrationPassword('🪷' * 4)?.kind,
        AuthFailureKind.weakPassword,
      );
      expect(
        AuthValidation.registrationPassword('🪷' * 7)?.kind,
        AuthFailureKind.weakPassword,
      );
      expect(AuthValidation.registrationPassword('🪷' * 8), isNull);
      expect(AuthValidation.registrationPassword('áéíóúçãõ'), isNull);
    });
    test('espaços da senha contam e não são normalizados', () {
      const password = ' senha  ';
      expect(password.runes.length, 8);
      expect(AuthValidation.registrationPassword(password), isNull);
      expect(AuthValidation.passwordConfirmation(password, password), isNull);
      expect(
        AuthValidation.passwordConfirmation(password, password.trim())?.kind,
        AuthFailureKind.passwordMismatch,
      );
      expect(AuthValidation.registrationPassword(' ' * 8), isNull);
      expect(password, ' senha  ');
    });
    test(
      'confirmação obrigatória e comparação exata, sem casefold/Unicode NFC',
      () {
        expect(
          AuthValidation.passwordConfirmation('abcdefgh', '')?.kind,
          AuthFailureKind.confirmationRequired,
        );
        expect(
          AuthValidation.passwordConfirmation('abcdefgh', 'abcdefgh'),
          isNull,
        );
        expect(
          AuthValidation.passwordConfirmation('abcdefgh', 'Abcdefgh')?.kind,
          AuthFailureKind.passwordMismatch,
        );
        expect(
          AuthValidation.passwordConfirmation(
            'ábcdefgh',
            'a\u0301bcdefgh',
          )?.kind,
          AuthFailureKind.passwordMismatch,
        );
        expect(
          AuthValidation.passwordConfirmation('abcdefgh', 'abcdefgh ')?.kind,
          AuthFailureKind.passwordMismatch,
        );
      },
    );
  });
}
