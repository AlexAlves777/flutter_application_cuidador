import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  final String? nomeUsuario;

  const HomeScreen({super.key, this.nomeUsuario});

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
    final nome = nomeUsuario?.trim().isNotEmpty == true
        ? nomeUsuario!.trim()
        : 'usuário';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Início'),
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
              Text(
                'Olá, $nome!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Aqui ficará a rotina diária, os registros de comportamento e os cuidados importantes.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 24),

              _HomeCard(
                icon: Icons.calendar_today_outlined,
                title: 'Agenda diária',
                description: 'Consultas, terapias, escola e atividades.',
                onTap: () {},
              ),

              const SizedBox(height: 12),

              _HomeCard(
                icon: Icons.psychology_alt_outlined,
                title: 'Registro de comportamento',
                description: 'Anote observações importantes da rotina.',
                onTap: () {},
              ),

              const SizedBox(height: 12),

              _HomeCard(
                icon: Icons.group_outlined,
                title: 'Rede de apoio',
                description: 'Gerencie cuidadores e pessoas autorizadas.',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: const Color(0xFF5B6EF5)),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      description,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
