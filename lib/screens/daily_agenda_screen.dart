import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DailyAgendaScreen extends StatefulWidget {
  const DailyAgendaScreen({super.key});

  @override
  State<DailyAgendaScreen> createState() => _DailyAgendaScreenState();
}

class _DailyAgendaScreenState extends State<DailyAgendaScreen> {
  static const _primary = Color(0xFF5B6EF5);
  static const _pageBackground = Color(0xFFF7F8FC);

  static const _activityTypes = [
    'Rotina',
    'Consulta',
    'Terapia',
    'Medicamento',
    'Escola',
    'Alimentação',
    'Sono',
    'Outro',
  ];

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late Future<String?> _activeChildId;
  DateTime _selectedDate = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

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

  CollectionReference<Map<String, dynamic>> _agenda(String childId) {
    return _firestore
        .collection('children')
        .doc(childId)
        .collection('agenda_items');
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _displayDate(DateTime date) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    return '${date.day} de ${months[date.month - 1]}';
  }

  String _weekday(DateTime date) {
    const weekdays = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

    return weekdays[date.weekday - 1];
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Selecionar data',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );

    if (date != null && mounted) {
      setState(() {
        _selectedDate = _dateOnly(date);
      });
    }
  }

  Future<void> _openActivityForm(String childId) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ActivityFormSheet(
          activityTypes: _activityTypes,
          selectedDateLabel: _displayDate(_selectedDate),
          onSave:
              ({
                required String title,
                required String type,
                required String notes,
                required String? timeLabel,
                required int? timeInMinutes,
              }) async {
                final user = _auth.currentUser;

                if (user == null) {
                  throw Exception('Usuário não autenticado.');
                }

                await _agenda(childId).add({
                  'titulo': title,
                  'tipo': type,
                  'observacoes': notes,
                  'data': Timestamp.fromDate(_selectedDate),
                  'dataKey': _dateKey(_selectedDate),
                  'horario': timeLabel,
                  'horarioMinutos': timeInMinutes,
                  'concluida': false,
                  'childId': childId,
                  'criadoPor': user.uid,
                  'criadoEm': FieldValue.serverTimestamp(),
                  'atualizadoEm': FieldValue.serverTimestamp(),
                });
              },
        );
      },
    );

    if (saved == true && mounted) {
      _showMessage('Atividade salva com sucesso.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setCompleted({
    required String childId,
    required String id,
    required bool completed,
  }) async {
    try {
      await _agenda(childId).doc(id).update({
        'concluida': completed,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível atualizar a atividade.');
      }
    }
  }

  Future<void> _confirmDeletion({
    required String childId,
    required String id,
    required String title,
  }) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir atividade?'),
          content: Text('“$title” será removida da agenda.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (delete != true) {
      return;
    }

    try {
      await _agenda(childId).doc(id).delete();
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível excluir a atividade.');
      }
    }
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
            title: const Text('Agenda diária'),
            centerTitle: true,
            backgroundColor: _pageBackground,
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            onPressed: () {
              _openActivityForm(childId);
            },
            icon: const Icon(Icons.add),
            label: const Text('Atividade'),
          ),
          body: Column(
            children: [
              _DateStrip(
                selectedDate: _selectedDate,
                weekday: _weekday,
                onSelect: (date) {
                  setState(() {
                    _selectedDate = _dateOnly(date);
                  });
                },
                onPickDate: _pickDate,
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _agenda(childId)
                      .where('dataKey', isEqualTo: _dateKey(_selectedDate))
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const _AgendaFeedback(
                        icon: Icons.cloud_off_outlined,
                        title: 'Não foi possível carregar a agenda',
                        subtitle: 'Verifique sua conexão e tente novamente.',
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snapshot.data!.docs.toList()
                      ..sort((a, b) {
                        final aMinutes =
                            (a.data()['horarioMinutos'] as int?) ?? 9999;
                        final bMinutes =
                            (b.data()['horarioMinutos'] as int?) ?? 9999;

                        return aMinutes.compareTo(bMinutes);
                      });

                    final completed = items.where((item) {
                      return item.data()['concluida'] == true;
                    }).length;

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _DailyHeader(
                            date: _selectedDate,
                            total: items.length,
                            completed: completed,
                          ),
                        ),
                        if (items.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _AgendaFeedback(
                              icon: Icons.event_available_outlined,
                              title: 'Tudo tranquilo por aqui',
                              subtitle:
                                  'Adicione uma atividade para organizar este dia.',
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            sliver: SliverList.separated(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final data = item.data();
                                final title =
                                    data['titulo'] as String? ??
                                    'Esta atividade';

                                return _AgendaItem(
                                  data: data,
                                  onChanged: (completed) {
                                    _setCompleted(
                                      childId: childId,
                                      id: item.id,
                                      completed: completed,
                                    );
                                  },
                                  onDelete: () {
                                    _confirmDeletion(
                                      childId: childId,
                                      id: item.id,
                                      title: title,
                                    );
                                  },
                                );
                              },
                              separatorBuilder: (_, _) {
                                return const SizedBox(height: 10);
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityFormSheet extends StatefulWidget {
  final List<String> activityTypes;
  final String selectedDateLabel;
  final Future<void> Function({
    required String title,
    required String type,
    required String notes,
    required String? timeLabel,
    required int? timeInMinutes,
  })
  onSave;

  const _ActivityFormSheet({
    required this.activityTypes,
    required this.selectedDateLabel,
    required this.onSave,
  });

  @override
  State<_ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends State<_ActivityFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();
  final _notesController = TextEditingController();

  late String _type;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.activityTypes.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  String _timeLabelFromNumbers({required int hour, required int minute}) {
    final hourText = hour.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');

    return '$hourText:$minuteText';
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final hourText = _hourController.text.trim();
    final minuteText = _minuteController.text.trim();

    String? timeLabel;
    int? timeInMinutes;

    if (hourText.isNotEmpty && minuteText.isNotEmpty) {
      final hour = int.parse(hourText);
      final minute = int.parse(minuteText);

      timeLabel = _timeLabelFromNumbers(hour: hour, minute: minute);

      timeInMinutes = hour * 60 + minute;
    }

    try {
      await widget.onSave(
        title: _titleController.text.trim(),
        type: _type,
        notes: _notesController.text.trim(),
        timeLabel: timeLabel,
        timeInMinutes: timeInMinutes,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Erro ao salvar atividade: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a atividade.')),
        );
    }
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
            child: Form(
              key: _formKey,
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
                    'Nova atividade',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Para ${widget.selectedDateLabel}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    enabled: !_saving,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'O que está planejado?',
                      hintText: 'Ex.: Terapia ocupacional',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a atividade.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: widget.activityTypes.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _type = value;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _hourController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Hora',
                            hintText: 'HH',
                            prefixIcon: Icon(Icons.schedule_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final hourText = value?.trim() ?? '';
                            final minuteText = _minuteController.text.trim();

                            if (hourText.isEmpty && minuteText.isEmpty) {
                              return null;
                            }

                            if (hourText.isEmpty) {
                              return 'Informe';
                            }

                            final hour = int.tryParse(hourText);

                            if (hour == null || hour < 0 || hour > 23) {
                              return '0 a 23';
                            }

                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minuteController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Minuto',
                            hintText: 'MM',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final minuteText = value?.trim() ?? '';
                            final hourText = _hourController.text.trim();

                            if (hourText.isEmpty && minuteText.isEmpty) {
                              return null;
                            }

                            if (minuteText.isEmpty) {
                              return 'Informe';
                            }

                            final minute = int.tryParse(minuteText);

                            if (minute == null || minute < 0 || minute > 59) {
                              return '0 a 59';
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Horário opcional. Use o formato 24h, por exemplo: 08:30 ou 16:45.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    enabled: !_saving,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      hintText: 'Algo importante para lembrar? (opcional)',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Salvar atividade'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.selectedDate,
    required this.weekday,
    required this.onSelect,
    required this.onPickDate,
  });

  final DateTime selectedDate;
  final String Function(DateTime) weekday;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final firstDay = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final date = firstDay.add(Duration(days: index));

                final selected =
                    date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;

                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    onSelect(date);
                  },
                  child: Container(
                    width: 39,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF5B6EF5) : null,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekday(date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onPickDate,
            tooltip: 'Escolher outra data',
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF5B6EF5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyHeader extends StatelessWidget {
  const _DailyHeader({
    required this.date,
    required this.total,
    required this.completed,
  });

  final DateTime date;
  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    final today = DateUtils.isSameDay(date, DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            today ? 'Hoje' : '${date.day} de ${months[date.month - 1]}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            total == 0
                ? 'Nenhum compromisso planejado'
                : '$completed de $total ${total == 1 ? 'atividade concluída' : 'atividades concluídas'}',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completed / total,
                minHeight: 7,
                backgroundColor: const Color(0xFFE5E7EB),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgendaItem extends StatelessWidget {
  const _AgendaItem({
    required this.data,
    required this.onChanged,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final completed = data['concluida'] as bool? ?? false;
    final title = data['titulo'] as String? ?? 'Atividade sem título';
    final type = data['tipo'] as String? ?? 'Outro';
    final time = data['horario'] as String?;
    final notes = data['observacoes'] as String? ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          onChanged(!completed);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: completed,
                activeColor: const Color(0xFF5B6EF5),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: completed
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF1F2937),
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (time != null)
                          _Tag(icon: Icons.schedule_outlined, label: time),
                        _Tag(icon: Icons.label_outline, label: type),
                      ],
                    ),
                    if (notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          notes,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções da atividade',
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) {
                  return const [
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text(
                          'Excluir',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _AgendaFeedback extends StatelessWidget {
  const _AgendaFeedback({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
  const _NoActiveChild({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Agenda diária'),
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
                'Cadastre ou selecione uma criança para começar a organizar a rotina.',
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
