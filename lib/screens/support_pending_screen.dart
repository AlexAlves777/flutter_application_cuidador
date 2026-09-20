import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'welcome_screen.dart';

class SupportPendingScreen extends StatelessWidget {
  const SupportPendingScreen({super.key});

  String _gerarCodigoUsuario() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.length < 6) {
      return 'INDISPONIVEL';
    }

    return uid.substring(0, 6).toUpperCase();
  }

  Future<void> _sair(BuildContext context) async {
    await AuthService().sair();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final codigo = _gerarCodigoUsuario();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Aguardando vínculo'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F8FC),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => _sair(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              const Icon(
                Icons.hourglass_empty_rounded,
                size: 72,
                color: Color(0xFF5B6EF5),
              ),

              const SizedBox(height: 24),

              Text(
                'Aguardando aprovação',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Envie o código abaixo para o responsável principal. Depois que ele aprovar seu vínculo, você poderá acessar a rotina da criança.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Seu código temporário',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      codigo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              OutlinedButton(
                onPressed: () => _sair(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sair'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
