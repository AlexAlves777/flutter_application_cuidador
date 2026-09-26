import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'behavior_record_screen.dart';
import 'crisis_mode_screen.dart';
import 'daily_agenda_screen.dart';
import 'support_network_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  final String? nomeUsuario;

  const HomeScreen({super.key, this.nomeUsuario});

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

  void _abrirAgendaDiaria(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DailyAgendaScreen()));
  }

  void _abrirRegistroComportamento(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BehaviorRecordScreen()));
  }

  void _abrirModoCrise(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CrisisModeScreen()));
  }

  void _abrirRedeApoio(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SupportNetworkScreen()));
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
            onPressed: () {
              _sair(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
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
              'Acompanhe a rotina, os comportamentos e os cuidados importantes da criança.',
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            _CrisisActionCard(
              onTap: () {
                _abrirModoCrise(context);
              },
            ),
            const SizedBox(height: 18),
            _HomeCard(
              icon: Icons.calendar_today_outlined,
              title: 'Agenda diária',
              description: 'Consultas, terapias, escola e atividades.',
              onTap: () {
                _abrirAgendaDiaria(context);
              },
            ),
            const SizedBox(height: 12),
            _HomeCard(
              icon: Icons.psychology_alt_outlined,
              title: 'Comportamento e crises',
              description:
                  'Visualize registros, filtros, crises e observações.',
              onTap: () {
                _abrirRegistroComportamento(context);
              },
            ),
            const SizedBox(height: 12),
            _HomeCard(
              icon: Icons.group_outlined,
              title: 'Rede de apoio',
              description: 'Gerencie cuidadores e pessoas autorizadas.',
              onTap: () {
                _abrirRedeApoio(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CrisisActionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CrisisActionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registrar crise agora',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFB71C1C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Inicie um registro rápido, acompanhe o tempo e finalize quando a criança se acalmar.',
                      style: TextStyle(color: Color(0xFF7F1D1D), height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFB71C1C)),
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
