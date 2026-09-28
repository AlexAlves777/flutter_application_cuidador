import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _pageBackground = Color(0xFFF7F8FC);

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late Future<_ReportsData> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReports();
  }

  Future<_ReportsData> _loadReports() async {
    final user = _auth.currentUser;

    if (user == null) {
      return const _ReportsData.empty();
    }

    final userDocument = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    final childId = userDocument.data()?['childIdAtual'] as String?;

    if (childId == null || childId.isEmpty) {
      return const _ReportsData.empty();
    }

    final childDocument = await _firestore
        .collection('children')
        .doc(childId)
        .get();

    final childData = childDocument.data();

    if (!childDocument.exists || childData == null) {
      return const _ReportsData.empty();
    }

    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final weekKeys = List.generate(7, (index) {
      final date = today.subtract(Duration(days: index));
      return _dateKey(date);
    });

    final agendaSnapshot = await _firestore
        .collection('children')
        .doc(childId)
        .collection('agenda_items')
        .where('dataKey', isEqualTo: todayKey)
        .get();

    final behaviorSnapshot = await _firestore
        .collection('children')
        .doc(childId)
        .collection('behavior_records')
        .where('dataKey', whereIn: weekKeys)
        .get();

    final agendaItems = agendaSnapshot.docs.map((doc) => doc.data()).toList();

    final behaviorRecords = behaviorSnapshot.docs.map((doc) {
      return _BehaviorRecord.fromMap(id: doc.id, data: doc.data());
    }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final todayRecords = behaviorRecords.where((record) {
      return record.dataKey == todayKey;
    }).toList();

    final crisesToday = todayRecords.where((record) {
      return record.isCrisis;
    }).length;

    final crisesWeek = behaviorRecords.where((record) {
      return record.isCrisis;
    }).length;

    final positiveWeek = behaviorRecords.where((record) {
      return record.type == 'Observação positiva';
    }).length;

    final completedAgendaToday = agendaItems.where((item) {
      return item['concluida'] == true;
    }).length;

    final mostCommonTrigger = _findMostCommonTrigger(behaviorRecords);

    final recentRecords = behaviorRecords.take(5).toList();

    return _ReportsData(
      hasActiveChild: true,
      childName: _displayText(childData['nome'], fallback: 'Criança'),
      agendaToday: agendaItems.length,
      completedAgendaToday: completedAgendaToday,
      crisesToday: crisesToday,
      crisesWeek: crisesWeek,
      positiveWeek: positiveWeek,
      totalWeekRecords: behaviorRecords.length,
      mostCommonTrigger: mostCommonTrigger,
      recentRecords: recentRecords,
    );
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _displayText(dynamic value, {String fallback = 'Não informado'}) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }

  String _findMostCommonTrigger(List<_BehaviorRecord> records) {
    final counters = <String, int>{};
    final displayNames = <String, String>{};

    for (final record in records) {
      final trigger = record.trigger.trim();

      if (trigger.isEmpty) {
        continue;
      }

      final normalized = trigger.toLowerCase();

      counters[normalized] = (counters[normalized] ?? 0) + 1;
      displayNames.putIfAbsent(normalized, () => trigger);
    }

    if (counters.isEmpty) {
      return 'Não informado';
    }

    var selectedKey = counters.keys.first;

    for (final key in counters.keys) {
      if ((counters[key] ?? 0) > (counters[selectedKey] ?? 0)) {
        selectedKey = key;
      }
    }

    return displayNames[selectedKey] ?? 'Não informado';
  }

  void _refresh() {
    setState(() {
      _reportsFuture = _loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReportsData>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _pageBackground,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: _pageBackground,
            appBar: AppBar(
              title: const Text('Resumo e relatórios'),
              centerTitle: true,
              backgroundColor: _pageBackground,
            ),
            body: _ReportsFeedback(
              icon: Icons.cloud_off_outlined,
              title: 'Não foi possível carregar o resumo',
              subtitle: 'Verifique sua conexão e tente novamente.',
              actionLabel: 'Tentar novamente',
              onAction: _refresh,
            ),
          );
        }

        final reports = snapshot.data ?? const _ReportsData.empty();

        if (!reports.hasActiveChild) {
          return Scaffold(
            backgroundColor: _pageBackground,
            appBar: AppBar(
              title: const Text('Resumo e relatórios'),
              centerTitle: true,
              backgroundColor: _pageBackground,
            ),
            body: _ReportsFeedback(
              icon: Icons.child_care_outlined,
              title: 'Nenhuma criança ativa',
              subtitle:
                  'Selecione ou cadastre uma criança para visualizar os indicadores.',
              actionLabel: 'Atualizar',
              onAction: _refresh,
            ),
          );
        }

        return Scaffold(
          backgroundColor: _pageBackground,
          appBar: AppBar(
            title: const Text('Resumo e relatórios'),
            centerTitle: true,
            backgroundColor: _pageBackground,
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                icon: const Icon(Icons.refresh),
                onPressed: _refresh,
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                _ReportsHeader(childName: reports.childName),
                const SizedBox(height: 18),
                _StatsGrid(reports: reports),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Gatilho mais frequente',
                  icon: Icons.warning_amber_outlined,
                  children: [
                    _InfoBox(
                      title: reports.mostCommonTrigger,
                      subtitle:
                          'Baseado nos registros da última semana que possuem gatilho preenchido.',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Últimos registros',
                  icon: Icons.history,
                  children: [
                    if (reports.recentRecords.isEmpty)
                      const _EmptyState(
                        text:
                            'Nenhum registro de comportamento encontrado na última semana.',
                      )
                    else
                      ...reports.recentRecords.map((record) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecentRecordTile(record: record),
                        );
                      }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  final String childName;

  const _ReportsHeader({required this.childName});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8EAFF),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFF5B6EF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo da rotina',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    childName,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Indicadores dos últimos 7 dias.',
                    style: TextStyle(color: Color(0xFF4B5563)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _ReportsData reports;

  const _StatsGrid({required this.reports});

  @override
  Widget build(BuildContext context) {
    final agendaText = reports.agendaToday == 0
        ? '0'
        : '${reports.completedAgendaToday}/${reports.agendaToday}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              width: cardWidth,
              icon: Icons.emergency_outlined,
              title: 'Crises hoje',
              value: reports.crisesToday.toString(),
              subtitle: 'Registros de hoje',
            ),
            _StatCard(
              width: cardWidth,
              icon: Icons.trending_up_outlined,
              title: 'Crises semana',
              value: reports.crisesWeek.toString(),
              subtitle: 'Últimos 7 dias',
            ),
            _StatCard(
              width: cardWidth,
              icon: Icons.check_circle_outline,
              title: 'Agenda hoje',
              value: agendaText,
              subtitle: 'Concluídas / total',
            ),
            _StatCard(
              width: cardWidth,
              icon: Icons.sentiment_satisfied_alt_outlined,
              title: 'Positivas',
              value: reports.positiveWeek.toString(),
              subtitle: 'Observações positivas',
            ),
            _StatCard(
              width: cardWidth,
              icon: Icons.assignment_outlined,
              title: 'Registros',
              value: reports.totalWeekRecords.toString(),
              subtitle: 'Total da semana',
            ),
            _StatCard(
              width: cardWidth,
              icon: Icons.psychology_alt_outlined,
              title: 'Acompanhamento',
              value: reports.totalWeekRecords > 0 ? 'Ativo' : 'Vazio',
              subtitle: 'Base de análise',
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF5B6EF5)),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF5B6EF5)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoBox({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF5B6EF5)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRecordTile extends StatelessWidget {
  final _BehaviorRecord record;

  const _RecentRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: record.isCrisis
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFE8EAFF),
              foregroundColor: record.isCrisis
                  ? const Color(0xFFE53935)
                  : const Color(0xFF5B6EF5),
              child: Icon(
                record.isCrisis
                    ? Icons.emergency_outlined
                    : Icons.psychology_alt_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.type} • ${record.formattedDateTime}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  if (record.trigger.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Gatilho: ${record.trigger}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6B7280), height: 1.35),
        ),
      ),
    );
  }
}

class _ReportsFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ReportsFeedback({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportsData {
  final bool hasActiveChild;
  final String childName;
  final int agendaToday;
  final int completedAgendaToday;
  final int crisesToday;
  final int crisesWeek;
  final int positiveWeek;
  final int totalWeekRecords;
  final String mostCommonTrigger;
  final List<_BehaviorRecord> recentRecords;

  const _ReportsData({
    required this.hasActiveChild,
    required this.childName,
    required this.agendaToday,
    required this.completedAgendaToday,
    required this.crisesToday,
    required this.crisesWeek,
    required this.positiveWeek,
    required this.totalWeekRecords,
    required this.mostCommonTrigger,
    required this.recentRecords,
  });

  const _ReportsData.empty()
    : hasActiveChild = false,
      childName = '',
      agendaToday = 0,
      completedAgendaToday = 0,
      crisesToday = 0,
      crisesWeek = 0,
      positiveWeek = 0,
      totalWeekRecords = 0,
      mostCommonTrigger = 'Não informado',
      recentRecords = const [];
}

class _BehaviorRecord {
  final String id;
  final String title;
  final String type;
  final String trigger;
  final String dataKey;
  final DateTime dateTime;

  const _BehaviorRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.trigger,
    required this.dataKey,
    required this.dateTime,
  });

  bool get isCrisis {
    return type == 'Crise';
  }

  String get formattedDateTime {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }

  factory _BehaviorRecord.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final title = data['titulo'] as String?;
    final type = data['tipo'] as String?;
    final trigger = data['gatilho'] as String?;
    final dataKey = data['dataKey'] as String?;

    final date = _readRecordDate(data['data']);
    final minutes = data['horarioMinutos'];

    final normalizedMinutes = minutes is int ? minutes : 0;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
    ).add(Duration(minutes: normalizedMinutes));

    return _BehaviorRecord(
      id: id,
      title: title?.trim().isNotEmpty == true ? title!.trim() : 'Registro',
      type: type?.trim().isNotEmpty == true ? type!.trim() : 'Outro',
      trigger: trigger?.trim() ?? '',
      dataKey: dataKey ?? '',
      dateTime: dateTime,
    );
  }

  static DateTime _readRecordDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }
}
