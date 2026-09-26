import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'welcome_screen.dart';

class SupportPendingScreen extends StatelessWidget {
  const SupportPendingScreen({super.key});

  Future<String> _buscarCodigoVinculo() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return 'INDISPONIVEL';
    }

    final document = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final code = document.data()?['codigoVinculo'] as String?;

    if (code != null && code.trim().isNotEmpty) {
      return code.trim().toUpperCase();
    }

    if (uid.length < 6) {
      return uid.toUpperCase();
    }

    return uid.substring(0, 6).toUpperCase();
  }

  Future<void> _sair(BuildContext context) async {
    await AuthService().sair();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              _sair(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _buscarCodigoVinculo(),
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final codigo = snapshot.data ?? 'CARREGANDO';

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 72,
                    color: Color(0xFF5B6EF5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Conta aguardando aprovação',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Envie seu código de vínculo para o responsável pela criança. Depois que ele adicionar você na rede de apoio, seu acesso será liberado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Seu código de vínculo',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 8),
                        if (loading)
                          const CircularProgressIndicator()
                        else
                          SelectableText(
                            codigo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Esse código deve ser informado ao pai, mãe ou responsável principal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {
                      _sair(context);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
