import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/models/user_profile.dart';
import '../domain/repositories/transaction_repository.dart';
import '../presentation/controllers/financial_controller.dart';
import '../presentation/controllers/session_controller.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/transactions/transaction_form_screen.dart';
import '../presentation/screens/transactions/transactions_screen.dart';

/// Dono de uma única instância financeira para uma identidade pronta do gate.
class MainShell extends StatefulWidget {
  const MainShell({
    required this.session,
    required this.profile,
    required this.transactions,
    super.key,
  });

  final SessionController session;
  final UserProfile profile;
  final TransactionRepository transactions;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  FinancialController? _financial;
  late final int _identityVersion;
  int _index = 0;
  bool _formOpen = false;

  bool get _ready =>
      widget.session.isReady &&
      widget.session.navigationVersion == _identityVersion &&
      widget.session.user?.uid == widget.profile.userId &&
      _financial?.expectedUserId == widget.profile.userId;

  @override
  void initState() {
    super.initState();
    _identityVersion = widget.session.navigationVersion;
    if (widget.session.isReady &&
        widget.session.user?.uid == widget.profile.userId) {
      _financial = FinancialController(
        transactions: widget.transactions,
        session: widget.session,
        expectedUserId: widget.profile.userId,
      );
      unawaited(_financial!.load());
    }
  }

  Future<void> _openTransaction() async {
    if (!_ready || _formOpen) return;
    _formOpen = true;
    try {
      // Este contexto pertence ao Navigator privado do SessionGate.
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TransactionFormScreen(controller: _financial!),
        ),
      );
      // O controller já confirmou a recarga; voltar não consulta novamente.
    } finally {
      _formOpen = false;
    }
  }

  @override
  void dispose() {
    _financial?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      if (!_ready) return const SizedBox.shrink();
      final financial = _financial!;
      return Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            DashboardScreen(
              controller: financial,
              profile: widget.profile,
              onAddTransaction: _openTransaction,
              onViewTransactions: () => setState(() => _index = 1),
            ),
            TransactionsScreen(
              controller: financial,
              onAddTransaction: _openTransaction,
            ),
            ProfileScreen(session: widget.session, profile: widget.profile),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) {
            if (_ready) setState(() => _index = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Transações',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      );
    },
  );
}
