import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CrisisModeScreen extends StatefulWidget {
  const CrisisModeScreen({super.key});

  @override
  State<CrisisModeScreen> createState() => _CrisisModeScreenState();
}

class _CrisisModeScreenState extends State<CrisisModeScreen> {
  static const _pageBackground = Color(0xFFF7F8FC);

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late Future<String?> _activeChildId;

  @override
  void initState() {
    super.initState();
    _activeChildId = _findActiveChildId();
  }

  Future<String?> _findActiveChildId() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final userDocument = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    return userDocument.data()?['childIdAtual'] as String?;
  }

  CollectionReference<Map<String, dynamic>> _records(String childId) {
    return _firestore
        .collection('children')
        .doc(childId)
        .collection('behavior_records');
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _timeLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<int> _findCrisisAlertMinutes(String childId) async {
    final childDocument = await _firestore
        .collection('children')
        .doc(childId)
        .get();

    final data = childDocument.data();

    if (data == null) {
      return 5;
    }

    final configuredValue = data['tempoAlertaCriseMinutos'];

    if (configuredValue is int && configuredValue > 0) {
      return configuredValue;
    }

    return 5;
  }

  Future<void> _startCrisis(String childId) async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Usuário não autenticado.');
      return;
    }

    final now = DateTime.now();
    final alertMinutes = await _findCrisisAlertMinutes(childId);

    try {
      await _records(childId).add({
        'titulo': 'Crise em andamento',
        'tipo': 'Crise',
        'intensidade': 3,
        'gatilho': '',
        'estrategia': '',
        'observacoes': '',
        'statusCrise': 'em_andamento',
        'origemRegistro': 'botao_crise',
        'inicioCrise': Timestamp.fromDate(now),
        'fimCrise': null,
        'duracaoSegundos': null,
        'tempoAlertaMinutos': alertMinutes,
        'alertaEmitido': false,
        'ambienteCalmanteAtivo': false,
        'data': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
        'dataKey': _dateKey(now),
        'horario': _timeLabel(now),
        'horarioMinutos': now.hour * 60 + now.minute,
        'childId': childId,
        'criadoPor': user.uid,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível iniciar o registro da crise.');
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _ongoingCrisisStream(
    String childId,
  ) {
    return _records(childId)
        .where('tipo', isEqualTo: 'Crise')
        .where('statusCrise', isEqualTo: 'em_andamento')
        .limit(1)
        .snapshots();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _activeChildId,
      builder: (context, childSnapshot) {
        if (childSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _pageBackground,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final childId = childSnapshot.data;

        if (childId == null || childId.isEmpty) {
          return _NoActiveChild(
            onRetry: () {
              setState(() {
                _activeChildId = _findActiveChildId();
              });
            },
          );
        }

        return Scaffold(
          backgroundColor: _pageBackground,
          appBar: AppBar(
            title: const Text('Modo crise'),
            centerTitle: true,
            backgroundColor: _pageBackground,
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _ongoingCrisisStream(childId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _CrisisFeedback(
                  icon: Icons.cloud_off_outlined,
                  title: 'Não foi possível carregar o modo crise',
                  subtitle: 'Verifique sua conexão e tente novamente.',
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return _StartCrisisView(
                  onStart: () {
                    _startCrisis(childId);
                  },
                );
              }

              final crisis = docs.first;

              return _OngoingCrisisView(
                childId: childId,
                recordId: crisis.id,
                data: crisis.data(),
                records: _records(childId),
              );
            },
          ),
        );
      },
    );
  }
}

class _StartCrisisView extends StatelessWidget {
  final VoidCallback onStart;

  const _StartCrisisView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        const Icon(
          Icons.emergency_outlined,
          size: 76,
          color: Color(0xFFE53935),
        ),
        const SizedBox(height: 20),
        Text(
          'Registrar crise agora',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Use este modo para registrar uma crise em andamento, acompanhar o tempo e finalizar quando a criança se acalmar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          ),
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow),
          label: const Text(
            'Iniciar registro de crise',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 18),
        const _InfoBox(
          icon: Icons.info_outline,
          text:
              'Depois de iniciar, o app vai mostrar um cronômetro, permitir encerrar a crise e salvar gatilho, estratégia e observações.',
        ),
      ],
    );
  }
}

class _OngoingCrisisView extends StatefulWidget {
  final String childId;
  final String recordId;
  final Map<String, dynamic> data;
  final CollectionReference<Map<String, dynamic>> records;

  const _OngoingCrisisView({
    required this.childId,
    required this.recordId,
    required this.data,
    required this.records,
  });

  @override
  State<_OngoingCrisisView> createState() => _OngoingCrisisViewState();
}

class _OngoingCrisisViewState extends State<_OngoingCrisisView> {
  Timer? _timer;
  late DateTime _startedAt;
  late Duration _elapsed;

  var _localAlertAlreadyShown = false;
  var _calmingVisible = false;

  @override
  void initState() {
    super.initState();

    _startedAt = _readStartedAt();
    _elapsed = DateTime.now().difference(_startedAt);
    _localAlertAlreadyShown = widget.data['alertaEmitido'] == true;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _elapsed = DateTime.now().difference(_startedAt);
      });

      _checkAlert();
    });
  }

  @override
  void didUpdateWidget(covariant _OngoingCrisisView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.recordId != widget.recordId) {
      _startedAt = _readStartedAt();
      _elapsed = DateTime.now().difference(_startedAt);
      _localAlertAlreadyShown = widget.data['alertaEmitido'] == true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  DateTime _readStartedAt() {
    final timestamp = widget.data['inicioCrise'];

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return DateTime.now();
  }

  int _alertMinutes() {
    final value = widget.data['tempoAlertaMinutos'];

    if (value is int && value > 0) {
      return value;
    }

    return 5;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _checkAlert() async {
    if (_localAlertAlreadyShown) {
      return;
    }

    final alertLimit = Duration(minutes: _alertMinutes());

    if (_elapsed < alertLimit) {
      return;
    }

    _localAlertAlreadyShown = true;

    await widget.records.doc(widget.recordId).update({
      'alertaEmitido': true,
      'alertaEmitidoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'A crise passou de ${_alertMinutes()} minutos. Alerta registrado.',
          ),
        ),
      );
  }

  Future<void> _toggleCalmingMode() async {
    final newValue = !_calmingVisible;

    setState(() {
      _calmingVisible = newValue;
    });

    await widget.records.doc(widget.recordId).update({
      'ambienteCalmanteAtivo': newValue,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _finishCrisis() async {
    final result = await showModalBottomSheet<_FinishCrisisResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _FinishCrisisSheet(elapsed: _elapsed);
      },
    );

    if (result == null) {
      return;
    }

    final now = DateTime.now();

    try {
      await widget.records.doc(widget.recordId).update({
        'titulo': 'Crise registrada',
        'statusCrise': 'resolvida',
        'fimCrise': Timestamp.fromDate(now),
        'duracaoSegundos': _elapsed.inSeconds,
        'intensidade': result.intensity,
        'gatilho': result.trigger,
        'estrategia': result.strategy,
        'observacoes': result.notes,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Crise finalizada e registrada.')),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Não foi possível finalizar a crise.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertLimit = _alertMinutes();
    final alertReached = _elapsed >= Duration(minutes: alertLimit);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Material(
          color: alertReached ? const Color(0xFFFFEBEE) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Icon(
                  alertReached
                      ? Icons.notification_important_outlined
                      : Icons.timer_outlined,
                  size: 58,
                  color: const Color(0xFFE53935),
                ),
                const SizedBox(height: 16),
                Text(
                  'Crise em andamento',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatDuration(_elapsed),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE53935),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alertReached
                      ? 'Tempo de alerta atingido.'
                      : 'Alerta configurado para $alertLimit minutos.',
                  style: TextStyle(
                    color: alertReached
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFF6B7280),
                    fontWeight: alertReached
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _finishCrisis,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Encerrar crise'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _toggleCalmingMode,
          icon: Icon(
            _calmingVisible
                ? Icons.visibility_off_outlined
                : Icons.spa_outlined,
          ),
          label: Text(
            _calmingVisible
                ? 'Ocultar ambiente calmante'
                : 'Ativar ambiente calmante',
          ),
        ),
        const SizedBox(height: 18),
        if (_calmingVisible) const _CalmingPanel(),
        const SizedBox(height: 18),
        const _InfoBox(
          icon: Icons.notifications_active_outlined,
          text:
              'Nesta versão, o app registra o alerta no histórico. Notificações reais em outros celulares exigem Firebase Cloud Messaging, que entra em uma próxima etapa.',
        ),
      ],
    );
  }
}

class _CalmingPanel extends StatelessWidget {
  const _CalmingPanel();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ambiente calmante',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reduza estímulos, mantenha uma fala calma e use as estratégias definidas pelo responsável.',
              style: TextStyle(color: Color(0xFF374151), height: 1.4),
            ),
            const SizedBox(height: 14),
            const _CalmingStep(
              icon: Icons.volume_off_outlined,
              text: 'Reduzir barulhos e estímulos do ambiente.',
            ),
            const _CalmingStep(
              icon: Icons.light_mode_outlined,
              text: 'Evitar luz forte ou mudança brusca de ambiente.',
            ),
            const _CalmingStep(
              icon: Icons.favorite_outline,
              text: 'Usar objeto, rotina ou recurso de conforto da criança.',
            ),
            const _CalmingStep(
              icon: Icons.self_improvement_outlined,
              text: 'Dar tempo e espaço para regulação.',
            ),
          ],
        ),
      ),
    );
  }
}

class _CalmingStep extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CalmingStep({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF374151), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishCrisisResult {
  final int intensity;
  final String trigger;
  final String strategy;
  final String notes;

  const _FinishCrisisResult({
    required this.intensity,
    required this.trigger,
    required this.strategy,
    required this.notes,
  });
}

class _FinishCrisisSheet extends StatefulWidget {
  final Duration elapsed;

  const _FinishCrisisSheet({required this.elapsed});

  @override
  State<_FinishCrisisSheet> createState() => _FinishCrisisSheetState();
}

class _FinishCrisisSheetState extends State<_FinishCrisisSheet> {
  final _triggerController = TextEditingController();
  final _strategyController = TextEditingController();
  final _notesController = TextEditingController();

  var _intensity = 3;

  @override
  void dispose() {
    _triggerController.dispose();
    _strategyController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _finish() {
    Navigator.of(context).pop(
      _FinishCrisisResult(
        intensity: _intensity,
        trigger: _triggerController.text.trim(),
        strategy: _strategyController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Finalizar crise',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duração: ${_formatDuration(widget.elapsed)}',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: _intensity,
                  decoration: const InputDecoration(
                    labelText: 'Intensidade percebida',
                    prefixIcon: Icon(Icons.speed_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 - Muito leve')),
                    DropdownMenuItem(value: 2, child: Text('2 - Leve')),
                    DropdownMenuItem(value: 3, child: Text('3 - Moderada')),
                    DropdownMenuItem(value: 4, child: Text('4 - Alta')),
                    DropdownMenuItem(value: 5, child: Text('5 - Muito alta')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _intensity = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _triggerController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'O que pode ter gerado a crise?',
                    hintText: 'Ex.: barulho, fome, mudança de rotina',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _strategyController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'O que ajudou a acalmar?',
                    hintText: 'Ex.: pausa sensorial, colo, objeto de conforto',
                    prefixIcon: Icon(Icons.healing_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Observações finais',
                    hintText:
                        'Descreva o contexto, sinais percebidos e resposta.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _finish,
                  child: const Text('Salvar e encerrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFF374151), height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrisisFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CrisisFeedback({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: const Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActiveChild extends StatelessWidget {
  final VoidCallback onRetry;

  const _NoActiveChild({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Modo crise'),
        backgroundColor: const Color(0xFFF7F8FC),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.child_care_outlined,
                size: 64,
                color: Color(0xFF5B6EF5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma criança ativa',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cadastre ou selecione uma criança para usar o modo crise.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
