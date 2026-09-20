import 'package:flutter/material.dart';

import 'child_register_screen.dart';
import 'support_pending_screen.dart';

class ChildQuestionScreen extends StatelessWidget {
  final String perfil;

  const ChildQuestionScreen({super.key, required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Criança cadastrada'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F8FC),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              const Icon(
                Icons.child_care_outlined,
                size: 72,
                color: Color(0xFF5B6EF5),
              ),

              const SizedBox(height: 24),

              Text(
                'A criança já está cadastrada?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Se a criança ainda não existe no aplicativo, você poderá cadastrá-la agora. Se ela já existe, será necessário aguardar o vínculo com o responsável.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF6B7280),
                ),
              ),

              const Spacer(),

              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const SupportPendingScreen(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sim, já está cadastrada'),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const ChildRegisterScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Não, quero cadastrar agora'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
