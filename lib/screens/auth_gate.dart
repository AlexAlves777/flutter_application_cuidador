import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'child_question_screen.dart';
import 'home_screen.dart';
import 'support_pending_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.mudancasDeAutenticacao,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final usuario = snapshot.data;

        if (usuario == null) {
          return const WelcomeScreen();
        }

        return FutureBuilder(
          future: authService.buscarDadosUsuario(),
          builder: (context, dadosSnapshot) {
            if (dadosSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (dadosSnapshot.hasError) {
              return const _AuthGateErrorScreen(
                mensagem: 'Não foi possível carregar seus dados.',
              );
            }

            final documento = dadosSnapshot.data;

            if (documento == null || !documento.exists) {
              return const _AuthGateErrorScreen(
                mensagem: 'Dados do usuário não encontrados.',
              );
            }

            final dados = documento.data();

            if (dados == null) {
              return const _AuthGateErrorScreen(
                mensagem: 'Perfil do usuário incompleto.',
              );
            }

            final nome = dados['nome']?.toString();
            final perfil = dados['perfil']?.toString() ?? '';
            final statusVinculo = dados['statusVinculo']?.toString() ?? '';

            if (statusVinculo == 'ativo') {
              return HomeScreen(
                nomeUsuario: nome,
              );
            }

            if (statusVinculo == 'precisa_definir_crianca') {
              return ChildQuestionScreen(
                perfil: perfil,
              );
            }

            return const SupportPendingScreen();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F8FC),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _AuthGateErrorScreen extends StatelessWidget {
  final String mensagem;

  const _AuthGateErrorScreen({
    required this.mensagem,
  });

  Future<void> _sair(BuildContext context) async {
    await AuthService().sair();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 72,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  mensagem,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Saia e entre novamente. Se o problema continuar, o cadastro pode estar incompleto no banco.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _sair(context),
                  child: const Text('Sair e voltar ao início'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
