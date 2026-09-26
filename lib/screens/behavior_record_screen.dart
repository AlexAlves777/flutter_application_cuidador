import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _BehaviorPeriod { day, week, month }

class BehaviorRecordScreen extends StatefulWidget {
  const BehaviorRecordScreen({super.key});

  @override
  State<BehaviorRecordScreen> createState() => _BehaviorRecordScreenState();
}

class _BehaviorRecordScreenState extends State<BehaviorRecordScreen> {
  static const _primary = Color(0xFF5B6EF5);
  static const _pageBackground = Color(0xFFF7F8FC);

  static const _recordTypes = [
    'Crise',
    'Observação positiva',
    'Alimentação',
    'Sono',
    'Sensorial',
    'Comunicação',
    'Socialização',
    'Outro',
  ];

  static const _filters = [
    'Todos',
    'Crises',
    'Observações',
    'Alimentação',
    'Sono',
    'Sensorial',
    'Comunicação',
    'Socialização',
  ];

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late Future<String?> _activeChildId;

  DateTime _selectedDate = _dateOnly(DateTime.now());
  _BehaviorPeriod _period = _BehaviorPeriod.day;
  String _selectedFilter = 'Todos';

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

  DateTime _periodStart() {
    switch (_period) {
      case _BehaviorPeriod.day:
        return _selectedDate;
      case _BehaviorPeriod.week:
        return _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
      case _BehaviorPeriod.month:
        return DateTime(_selectedDate.year, _selectedDate.month);
    }
  }

  DateTime _periodEnd() {
    switch (_period) {
      case _BehaviorPeriod.day:
        return _selectedDate;
      case _BehaviorPeriod.week:
        return _periodStart().add(const Duration(days: 6));
      case _BehaviorPeriod.month:
        return DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    }
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

  String _periodLabel() {
    final start = _periodStart();
    final end = _periodEnd();

    switch (_period) {
      case _BehaviorPeriod.day:
        return _displayDate(_selectedDate);
      case _BehaviorPeriod.week:
        return '${start.day}/${start.month} até ${end.day}/${end.month}';
      case _BehaviorPeriod.month:
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

        return '${months[_selectedDate.month - 1]} de ${_selectedDate.year}';
    }
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

  Future<void> _openBehaviorForm(String childId) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _BehaviorFormSheet(
          recordTypes: _recordTypes,
          selectedDateLabel: _displayDate(_selectedDate),
          onSave:
              ({
                required String title,
                required String type,
                required int intensity,
                required String trigger,
                required String strategy,
                required String notes,
                required String? timeLabel,
                required int? timeInMinutes,
              }) async {
                final user = _auth.currentUser;

                if (user == null) {
                  throw Exception('Usuário não autenticado.');
                }

                await _records(childId).add({
                  'titulo': title,
                  'tipo': type,
                  'intensidade': intensity,
                  'gatilho': trigger,
                  'estrategia': strategy,
                  'observacoes': notes,
                  'statusCrise': type == 'Crise' ? 'registrada' : null,
                  'origemRegistro': 'manual',
                  'data': Timestamp.fromDate(_selectedDate),
                  'dataKey': _dateKey(_selectedDate),
                  'horario': timeLabel,
                  'horarioMinutos': timeInMinutes,
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
      _showMessage('Registro salvo com sucesso.');
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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
  ) {
    if (_selectedFilter == 'Todos') {
      return items;
    }

    if (_selectedFilter == 'Crises') {
      return items.where((item) {
        return item.data()['tipo'] == 'Crise';
      }).toList();
    }

    if (_selectedFilter == 'Observações') {
      return items.where((item) {
        return item.data()['tipo'] != 'Crise';
      }).toList();
    }

    return items.where((item) {
      return item.data()['tipo'] == _selectedFilter;
    }).toList();
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
          title: const Text('Excluir registro?'),
          content: Text('“$title” será removido dos registros.'),
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
      await _records(childId).doc(id).delete();
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível excluir o registro.');
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
            title: const Text('Comportamento e crises'),
            centerTitle: true,
            backgroundColor: _pageBackground,
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            onPressed: () {
              _openBehaviorForm(childId);
            },
            icon: const Icon(Icons.add),
            label: const Text('Novo registro'),
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
              _PeriodSelector(
                selectedPeriod: _period,
                onChanged: (period) {
                  setState(() {
                    _period = period;
                  });
                },
              ),
              _FilterChips(
                filters: _filters,
                selectedFilter: _selectedFilter,
                onChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _records(childId)
                      .where(
                        'dataKey',
                        isGreaterThanOrEqualTo: _dateKey(_periodStart()),
                      )
                      .where(
                        'dataKey',
                        isLessThanOrEqualTo: _dateKey(_periodEnd()),
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const _BehaviorFeedback(
                        icon: Icons.cloud_off_outlined,
                        title: 'Não foi possível carregar os registros',
                        subtitle: 'Verifique sua conexão e tente novamente.',
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allItems = snapshot.data!.docs.toList()
                      ..sort((a, b) {
                        final aDate = a.data()['dataKey'] as String? ?? '';
                        final bDate = b.data()['dataKey'] as String? ?? '';

                        final dateCompare = bDate.compareTo(aDate);

                        if (dateCompare != 0) {
                          return dateCompare;
                        }

                        final aMinutes =
                            (a.data()['horarioMinutos'] as int?) ?? 9999;
                        final bMinutes =
                            (b.data()['horarioMinutos'] as int?) ?? 9999;

                        return aMinutes.compareTo(bMinutes);
                      });

                    final filteredItems = _applyFilter(allItems);

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _BehaviorSummary(
                            label: _periodLabel(),
                            allItems: allItems,
                          ),
                        ),
                        if (filteredItems.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _BehaviorFeedback(
                              icon: Icons.psychology_alt_outlined,
                              title: 'Nenhum registro encontrado',
                              subtitle:
                                  'Use os filtros ou adicione um novo registro de comportamento.',
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            sliver: SliverList.separated(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final data = item.data();
                                final title =
                                    data['titulo'] as String? ??
                                    'Este registro';

                                return _BehaviorItem(
                                  data: data,
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

class _BehaviorFormSheet extends StatefulWidget {
  final List<String> recordTypes;
  final String selectedDateLabel;
  final Future<void> Function({
    required String title,
    required String type,
    required int intensity,
    required String trigger,
    required String strategy,
    required String notes,
    required String? timeLabel,
    required int? timeInMinutes,
  })
  onSave;

  const _BehaviorFormSheet({
    required this.recordTypes,
    required this.selectedDateLabel,
    required this.onSave,
  });

  @override
  State<_BehaviorFormSheet> createState() => _BehaviorFormSheetState();
}

class _BehaviorFormSheetState extends State<_BehaviorFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();
  final _triggerController = TextEditingController();
  final _strategyController = TextEditingController();
  final _notesController = TextEditingController();

  late String _type;
  var _intensity = 3;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.recordTypes.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _triggerController.dispose();
    _strategyController.dispose();
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
        intensity: _intensity,
        trigger: _triggerController.text.trim(),
        strategy: _strategyController.text.trim(),
        notes: _notesController.text.trim(),
        timeLabel: timeLabel,
        timeInMinutes: timeInMinutes,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Erro ao salvar registro: $error');
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
          const SnackBar(content: Text('Não foi possível salvar o registro.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final crisisSelected = _type == 'Crise';

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
                    crisisSelected ? 'Registrar crise' : 'Novo registro',
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
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de registro',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: widget.recordTypes.map((item) {
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
                  TextFormField(
                    controller: _titleController,
                    enabled: !_saving,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: crisisSelected
                          ? 'Resumo da crise'
                          : 'Resumo da observação',
                      hintText: crisisSelected
                          ? 'Ex.: Crise após mudança de rotina'
                          : 'Ex.: Aceitou bem um novo alimento',
                      prefixIcon: const Icon(Icons.edit_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe um resumo.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _intensity,
                    decoration: const InputDecoration(
                      labelText: 'Intensidade',
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
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _intensity = value;
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
                    controller: _triggerController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Possível gatilho',
                      hintText: 'Ex.: barulho alto, fome, mudança de rotina',
                      prefixIcon: Icon(Icons.warning_amber_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _strategyController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Estratégia usada',
                      hintText: 'Ex.: pausa sensorial, comunicação visual',
                      prefixIcon: Icon(Icons.healing_outlined),
                      border: OutlineInputBorder(),
                    ),
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
                      hintText: 'Descreva o contexto e o que aconteceu.',
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
                        : const Text('Salvar registro'),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final date = firstDay.add(Duration(days: index));

                final selected = DateUtils.isSameDay(date, selectedDate);

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

class _PeriodSelector extends StatelessWidget {
  final _BehaviorPeriod selectedPeriod;
  final ValueChanged<_BehaviorPeriod> onChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _PeriodChip(
            label: 'Hoje',
            selected: selectedPeriod == _BehaviorPeriod.day,
            onTap: () {
              onChanged(_BehaviorPeriod.day);
            },
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: 'Semana',
            selected: selectedPeriod == _BehaviorPeriod.week,
            onTap: () {
              onChanged(_BehaviorPeriod.week);
            },
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: 'Mês',
            selected: selectedPeriod == _BehaviorPeriod.month,
            onTap: () {
              onChanged(_BehaviorPeriod.month);
            },
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        onTap();
      },
      selectedColor: const Color(0xFFE8EAFF),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF5B6EF5) : const Color(0xFF374151),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _FilterChips({
    required this.filters,
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter == selectedFilter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) {
              onChanged(filter);
            },
            selectedColor: const Color(0xFFE8EAFF),
            labelStyle: TextStyle(
              color: selected
                  ? const Color(0xFF5B6EF5)
                  : const Color(0xFF374151),
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}

class _BehaviorSummary extends StatelessWidget {
  final String label;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> allItems;

  const _BehaviorSummary({required this.label, required this.allItems});

  String _mostCommonTrigger() {
    final counts = <String, int>{};

    for (final item in allItems) {
      final trigger = (item.data()['gatilho'] as String? ?? '').trim();

      if (trigger.isEmpty) {
        continue;
      }

      counts[trigger] = (counts[trigger] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return 'Nenhum gatilho informado';
    }

    final entries = counts.entries.toList()
      ..sort((a, b) {
        return b.value.compareTo(a.value);
      });

    return entries.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final total = allItems.length;
    final crises = allItems.where((item) {
      return item.data()['tipo'] == 'Crise';
    }).length;
    final observations = total - crises;
    final ongoingCrises = allItems.where((item) {
      return item.data()['statusCrise'] == 'em_andamento';
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Resumo dos comportamentos registrados.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Crises',
                  value: '$crises',
                  icon: Icons.emergency_outlined,
                  color: const Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'Observações',
                  value: '$observations',
                  icon: Icons.notes_outlined,
                  color: const Color(0xFF5B6EF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TriggerCard(
            trigger: _mostCommonTrigger(),
            ongoingCrises: ongoingCrises,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
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

class _TriggerCard extends StatelessWidget {
  final String trigger;
  final int ongoingCrises;

  const _TriggerCard({required this.trigger, required this.ongoingCrises});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.insights_outlined, color: Color(0xFF10B981)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ongoingCrises > 0
                    ? '$ongoingCrises crise em andamento'
                    : 'Gatilho mais citado: $trigger',
                style: const TextStyle(color: Color(0xFF374151), height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BehaviorItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  const _BehaviorItem({required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final title = data['titulo'] as String? ?? 'Registro sem título';
    final type = data['tipo'] as String? ?? 'Outro';
    final intensity = data['intensidade'] as int? ?? 3;
    final time = data['horario'] as String?;
    final trigger = data['gatilho'] as String? ?? '';
    final strategy = data['estrategia'] as String? ?? '';
    final notes = data['observacoes'] as String? ?? '';
    final status = data['statusCrise'] as String?;

    final isCrisis = type == 'Crise';
    final isOngoing = status == 'em_andamento';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCrisis
                  ? Icons.emergency_outlined
                  : Icons.psychology_alt_outlined,
              color: isCrisis
                  ? const Color(0xFFE53935)
                  : const Color(0xFF5B6EF5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (time != null)
                        _Tag(icon: Icons.schedule_outlined, label: time),
                      _Tag(icon: Icons.label_outline, label: type),
                      _Tag(
                        icon: Icons.speed_outlined,
                        label: 'Intensidade $intensity',
                      ),
                      if (isOngoing)
                        const _Tag(
                          icon: Icons.timer_outlined,
                          label: 'Em andamento',
                        ),
                    ],
                  ),
                  if (trigger.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Gatilho: $trigger',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (strategy.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Estratégia: $strategy',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      notes,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Opções do registro',
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
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Tag({required this.icon, required this.label});

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

class _BehaviorFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BehaviorFeedback({
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
        title: const Text('Comportamento e crises'),
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
                'Cadastre ou selecione uma criança para começar a acompanhar comportamentos.',
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
