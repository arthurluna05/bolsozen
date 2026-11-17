import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/firebase/data_failure.dart';
import '../../domain/models/auth_failure.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/services/auth_validation.dart';

enum SessionPhase {
  checking,
  public,
  authenticating,
  loadingProfile,
  missingProfile,
  profileError,
  ready,
  sessionError,
}

/// Sessão deriva exclusivamente do stream real, não do retorno isolado de login.
/// O controller não guarda senha, credenciais, objetos Firebase ou Future de login.
final class SessionController extends ChangeNotifier {
  factory SessionController({
    required AuthRepository auth,
    required UserRepository users,
  }) => SessionController._(auth, users);
  SessionController._(this._auth, this._users);

  final AuthRepository _auth;
  final UserRepository _users;
  StreamSubscription<AuthUser?>? _subscription;
  bool _disposed = false,
      _started = false,
      _authBusy = false,
      _writingProfile = false,
      _logoutBusy = false,
      _resetBusy = false;
  int _identityVersion = 0, _profileVersion = 0, _streamVersion = 0;
  SessionPhase _phase = SessionPhase.checking;
  AuthUser? _user;
  UserProfile? _profile;
  AuthFailure? _authFailure;
  AuthFailure? _passwordResetFailure;
  DataFailure? _profileFailure;
  String? _pendingUid, _pendingName, _retryUid, _retryName;

  SessionPhase get phase => _phase;
  AuthUser? get user => _user;
  UserProfile? get profile => _profile;
  AuthFailure? get authFailure => _authFailure;
  AuthFailure? get passwordResetFailure => _passwordResetFailure;
  bool get isResettingPassword => _resetBusy;
  bool get isSigningOut => _logoutBusy;
  bool get canSignOut => _user != null && !_authBusy && !_logoutBusy;
  bool get hasPendingProfileCreation =>
      _retryUid == _user?.uid && _retryName != null;
  DataFailure? get profileFailure => _profileFailure;
  int get navigationVersion => _identityVersion;
  bool get isBusy =>
      _authBusy ||
      _writingProfile ||
      _logoutBusy ||
      _resetBusy ||
      _phase == SessionPhase.authenticating ||
      _phase == SessionPhase.loadingProfile;
  bool get isReady =>
      _phase == SessionPhase.ready &&
      _user != null &&
      _profile?.userId == _user!.uid;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _listen();
  }

  void _listen() {
    final version = ++_streamVersion;
    try {
      _subscription = _auth.authStateChanges().listen(
        (user) {
          if (!_disposed && version == _streamVersion) _onAuth(user);
        },
        onError: (Object error) {
          if (!_disposed && version == _streamVersion) _sessionError(error);
        },
        onDone: () {
          if (!_disposed && version == _streamVersion) {
            _sessionError(const AuthFailure(AuthFailureKind.unavailable));
          }
        },
      );
    } catch (error) {
      _sessionError(error);
    }
  }

  void _clearIdentity(AuthUser? user) {
    _identityVersion++;
    _profileVersion++;
    _user = user;
    _profile = null;
    _profileFailure = null;
    _authFailure = null;
    _passwordResetFailure = null;
    _retryUid = _retryName = null;
  }

  void _onAuth(AuthUser? next) {
    final changed = _user?.uid != next?.uid || _user?.email != next?.email;
    if (changed) _clearIdentity(next);
    _user = next;
    if (next == null) {
      if (!_authBusy) _pendingUid = _pendingName = null;
      _profile = null;
      _profileVersion++;
      _phase = _authBusy ? SessionPhase.authenticating : SessionPhase.public;
      _notify();
      return;
    }
    if (_authBusy) {
      _phase = SessionPhase.authenticating;
      _notify();
      return; // Cadastro ainda não confirmou a identidade à qual pertence o nome.
    }
    if (_pendingUid != null) {
      final name = _pendingUid == next.uid ? _pendingName : null;
      _pendingUid = _pendingName = null;
      unawaited(_loadProfile(createName: name));
    } else if (changed ||
        _phase == SessionPhase.checking ||
        _phase == SessionPhase.sessionError ||
        _phase == SessionPhase.authenticating) {
      unawaited(_loadProfile());
    }
  }

  void _sessionError(Object error) {
    _clearIdentity(null);
    _pendingUid = _pendingName = null;
    _authFailure = error is AuthFailure
        ? error
        : const AuthFailure(AuthFailureKind.unknown);
    _phase = SessionPhase.sessionError;
    _notify();
  }

  Future<void> retrySession() async {
    if (_disposed ||
        _phase != SessionPhase.sessionError ||
        _authBusy ||
        _logoutBusy) {
      return;
    }
    ++_streamVersion;
    _phase = SessionPhase.checking;
    _notify();
    await _subscription?.cancel();
    if (_disposed) return;
    _phase = SessionPhase.checking;
    _authFailure = null;
    _notify();
    _listen();
  }

  bool _current(int identity, int request, String uid) =>
      !_disposed &&
      _identityVersion == identity &&
      _profileVersion == request &&
      _user?.uid == uid;

  Future<void> _loadProfile({String? createName}) async {
    if (_disposed || _user == null) return;
    final uid = _user!.uid;
    final identity = _identityVersion;
    final request = ++_profileVersion;
    _profile = null;
    _profileFailure = null;
    _phase = SessionPhase.loadingProfile;
    if (createName != null) {
      _writingProfile = true;
      _retryUid = uid;
      _retryName = createName;
    }
    _notify();
    try {
      if (createName != null) {
        await _users.ensureProfile(
          displayName: createName,
          expectedUserId: uid,
        );
        if (!_current(identity, request, uid)) return;
      }
      final value = await _users.fetch(expectedUserId: uid);
      if (!_current(identity, request, uid)) return;
      if (value != null &&
          (value.userId != uid ||
              AuthValidation.normalizeEmail(value.email) != _user!.email)) {
        throw const DataFailure(
          DataFailureKind.invalidData,
          'Não foi possível confirmar o perfil desta sessão.',
        );
      }
      _profile = value;
      _phase = value == null ? SessionPhase.missingProfile : SessionPhase.ready;
      if (value != null) _retryUid = _retryName = null;
    } catch (error) {
      if (!_current(identity, request, uid)) return;
      _profile = null;
      _profileFailure = error is DataFailure
          ? error
          : const DataFailure(
              DataFailureKind.invalidData,
              'Não foi possível carregar um perfil válido. Tente novamente.',
            );
      _phase = SessionPhase.profileError;
    } finally {
      if (createName != null) _writingProfile = false;
      _notify();
    }
  }

  Future<void> retryProfile() async {
    if (_disposed || isBusy || _phase != SessionPhase.profileError) return;
    await _loadProfile(createName: _retryUid == _user?.uid ? _retryName : null);
  }

  Future<void> completeProfile({required String displayName}) async {
    if (_disposed || isBusy || _phase != SessionPhase.missingProfile) return;
    final failure = AuthValidation.name(displayName);
    if (failure != null) {
      _authFailure = failure;
      _notify();
      return;
    }
    _authFailure = null;
    await _loadProfile(createName: displayName.trim());
  }

  Future<void> signIn({required String email, required String password}) =>
      _authenticate(() => _auth.signIn(email: email, password: password));

  /// Uma operação compartilhada entre rotas públicas, sem armazenar o e-mail.
  Future<bool> sendPasswordReset({required String email}) async {
    if (_disposed || isBusy || _phase != SessionPhase.public) return false;
    final invalid = AuthValidation.email(email);
    if (invalid != null) {
      _passwordResetFailure = invalid;
      _notify();
      return false;
    }
    final identity = _identityVersion;
    _resetBusy = true;
    _passwordResetFailure = null;
    _notify();
    try {
      await _auth.sendPasswordReset(email: email);
      return !_disposed &&
          _identityVersion == identity &&
          _phase == SessionPhase.public;
    } catch (error) {
      if (!_disposed && _identityVersion == identity) {
        _passwordResetFailure = error is AuthFailure
            ? error
            : const AuthFailure(AuthFailureKind.unknown);
      }
      return false;
    } finally {
      _resetBusy = false;
      _notify();
    }
  }

  /// Cria a conta uma vez; falha parcial é recuperada pela gravação do perfil.
  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
    required String confirmation,
  }) async {
    if (_disposed || isBusy || _phase != SessionPhase.public) return;
    final failure =
        AuthValidation.name(displayName) ??
        AuthValidation.email(email) ??
        AuthValidation.registrationPassword(password) ??
        AuthValidation.passwordConfirmation(password, confirmation);
    if (failure != null) {
      _authFailure = failure;
      _notify();
      return;
    }
    await _authenticate(
      () => _auth.signUp(email: email, password: password),
      createName: displayName.trim(),
    );
  }

  Future<void> _authenticate(
    Future<AuthUser> Function() call, {
    String? createName,
  }) async {
    if (_disposed || isBusy || _phase != SessionPhase.public) return;
    final identity = _identityVersion;
    _authBusy = true;
    _authFailure = null;
    _phase = SessionPhase.authenticating;
    _notify();
    try {
      final value = await call();
      if (_disposed) return;
      // Aceita somente a transição esperada público -> UID confirmado.
      if (_identityVersion == identity && _user == null) {
        _pendingUid = value.uid;
        _pendingName = createName;
      } else if (_identityVersion == identity + 1 && _user?.uid == value.uid) {
        _authBusy = false;
        await _loadProfile(createName: createName);
      }
    } catch (error) {
      if (!_disposed && _identityVersion == identity) {
        _authFailure = error is AuthFailure
            ? error
            : const AuthFailure(AuthFailureKind.unknown);
      }
    } finally {
      _authBusy = false;
      if (!_disposed &&
          _phase == SessionPhase.authenticating &&
          _pendingUid == null) {
        if (_user == null) {
          _phase = SessionPhase.public;
        } else {
          await _loadProfile();
        }
      }
      _notify();
    }
  }

  Future<void> signOut() async {
    if (_disposed || _authBusy || _logoutBusy) return;
    final uid = _user?.uid;
    final identity = _identityVersion;
    _profileVersion++; // Nenhuma leitura/escrita antiga pode reabrir a árvore.
    _pendingUid = _pendingName = null;
    _logoutBusy = true;
    _authFailure = null;
    _notify();
    try {
      await _auth.signOut();
      if (_disposed) return;
      if (_user?.uid == uid && _identityVersion == identity) {
        _clearIdentity(null);
        _phase = SessionPhase.public;
      }
    } catch (error) {
      if (!_disposed && _user?.uid == uid && _identityVersion == identity) {
        _authFailure = error is AuthFailure
            ? error
            : const AuthFailure(AuthFailureKind.unknown);
        if (_phase == SessionPhase.loadingProfile) {
          _phase = SessionPhase.profileError;
          _profileFailure = const DataFailure(
            DataFailureKind.unavailable,
            'Não foi possível confirmar a saída. Tente novamente.',
          );
        } else if (_phase == SessionPhase.authenticating) {
          _phase = _user == null
              ? SessionPhase.public
              : SessionPhase.missingProfile;
        }
      }
    } finally {
      _logoutBusy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _profileVersion++;
    _streamVersion++;
    _pendingUid = _pendingName = _retryUid = _retryName = null;
    _user = null;
    _profile = null;
    final subscription = _subscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.dispose();
  }
}
