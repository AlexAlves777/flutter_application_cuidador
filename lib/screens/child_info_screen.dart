import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChildInfoScreen extends StatefulWidget {
  const ChildInfoScreen({super.key});

  @override
  State<ChildInfoScreen> createState() => _ChildInfoScreenState();
}

class _ChildInfoScreenState extends State<ChildInfoScreen> {
  static const _primary = Color(0xFF5B6EF5);
  static const _pageBackground = Color(0xFFF7F8FC);

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _sensitivitiesController = TextEditingController();
  final _calmingPreferencesController = TextEditingController();

  final List<String> _supportLevels = [
    'Não informado',
    'Nível 1 - Requer apoio',
    'Nível 2 - Requer apoio substancial',
    'Nível 3 - Requer apoio muito substancial',
    'Outro',
  ];

  final List<int> _alertMinuteOptions = [1, 2, 3, 5, 10, 15, 20, 30];

  late Future<String?> _activeChildId;

  DateTime? _birthDate;
  String _supportLevel = 'Não informado';
  int _alertMinutes = 5;

  var _formLoaded = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _activeChildId = _findActiveChildId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _allergiesController.dispose();
    _sensitivitiesController.dispose();
    _calmingPreferencesController.dispose();

    super.dispose();
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

  DocumentReference<Map<String, dynamic>> _childDocument(String childId) {
    return _firestore.collection('children').doc(childId);
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Selecionar data';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  void _loadForm(Map<String, dynamic> data) {
    if (_formLoaded) {
      return;
    }

    final savedSupportLevel = data['nivelSuporte'] as String?;
    final savedAlertMinutes = data['tempoAlertaCriseMinutos'];

    _nameController.text = data['nome'] as String? ?? '';
    _notesController.text = data['observacoes'] as String? ?? '';
    _allergiesController.text = data['alergias'] as String? ?? '';
    _sensitivitiesController.text = data['sensibilidades'] as String? ?? '';
    _calmingPreferencesController.text =
        data['preferenciasAmbienteCalmante'] as String? ?? '';

    _birthDate = _readDate(data['dataNascimento']);

    if (savedSupportLevel != null && savedSupportLevel.trim().isNotEmpty) {
      if (!_supportLevels.contains(savedSupportLevel)) {
        _supportLevels.add(savedSupportLevel);
      }

      _supportLevel = savedSupportLevel;
    }

    if (savedAlertMinutes is int && savedAlertMinutes > 0) {
      if (!_alertMinuteOptions.contains(savedAlertMinutes)) {
        _alertMinuteOptions.add(savedAlertMinutes);
        _alertMinuteOptions.sort();
      }

      _alertMinutes = savedAlertMinutes;
    }

    _formLoaded = true;
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 5, now.month, now.day),
      firstDate: DateTime(1990),
      lastDate: now,
      helpText: 'Selecione a data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _birthDate = selectedDate;
    });
  }

  Future<void> _save(String childId) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _childDocument(childId).update({
        'nome': _nameController.text.trim(),
        'dataNascimento': _birthDate == null
            ? null
            : Timestamp.fromDate(_birthDate!),
        'nivelSuporte': _supportLevel,
        'tempoAlertaCriseMinutos': _alertMinutes,
        'alergias': _allergiesController.text.trim(),
        'sensibilidades': _sensitivitiesController.text.trim(),
        'preferenciasAmbienteCalmante': _calmingPreferencesController.text
            .trim(),
        'observacoes': _notesController.text.trim(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      _showMessage('Informações da criança atualizadas.');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Não foi possível salvar as informações.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
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
                _formLoaded = false;
                _activeChildId = _findActiveChildId();
              });
            },
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _childDocument(childId).snapshots(),
          builder: (context, childDocumentSnapshot) {
            if (childDocumentSnapshot.hasError) {
              return const Scaffold(
                backgroundColor: _pageBackground,
                body: _ChildInfoFeedback(
                  icon: Icons.cloud_off_outlined,
                  title: 'Não foi possível carregar os dados',
                  subtitle: 'Verifique sua conexão e tente novamente.',
                ),
              );
            }

            if (!childDocumentSnapshot.hasData) {
              return const Scaffold(
                backgroundColor: _pageBackground,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final childDocument = childDocumentSnapshot.data!;

            if (!childDocument.exists || childDocument.data() == null) {
              return const Scaffold(
                backgroundColor: _pageBackground,
                body: _ChildInfoFeedback(
                  icon: Icons.child_care_outlined,
                  title: 'Criança não encontrada',
                  subtitle:
                      'Não foi possível encontrar os dados da criança ativa.',
                ),
              );
            }

            _loadForm(childDocument.data()!);

            return Scaffold(
              backgroundColor: _pageBackground,
              appBar: AppBar(
                title: const Text('Informações da criança'),
                centerTitle: true,
                backgroundColor: _pageBackground,
              ),
              body: SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    children: [
                      _HeaderCard(
                        childName: _nameController.text.trim().isEmpty
                            ? 'Criança'
                            : _nameController.text.trim(),
                        birthDate: _formatDate(_birthDate),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Dados principais',
                        icon: Icons.child_care_outlined,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            enabled: !_saving,
                            decoration: const InputDecoration(
                              labelText: 'Nome da criança',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o nome da criança.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: _saving ? null : _selectBirthDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data de nascimento',
                                prefixIcon: Icon(Icons.event_outlined),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _formatDate(_birthDate),
                                style: TextStyle(
                                  color: _birthDate == null
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _supportLevel,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Nível de suporte',
                              prefixIcon: Icon(Icons.volunteer_activism),
                              border: OutlineInputBorder(),
                            ),
                            items: _supportLevels.map((level) {
                              return DropdownMenuItem<String>(
                                value: level,
                                child: Text(
                                  level,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            onChanged: _saving
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setState(() {
                                      _supportLevel = value;
                                    });
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Configurações de crise',
                        icon: Icons.emergency_outlined,
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: _alertMinutes,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Tempo para alerta de crise',
                              prefixIcon: Icon(Icons.timer_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: _alertMinuteOptions.map((minutes) {
                              return DropdownMenuItem<int>(
                                value: minutes,
                                child: Text(
                                  minutes == 1
                                      ? '1 minuto'
                                      : '$minutes minutos',
                                ),
                              );
                            }).toList(),
                            onChanged: _saving
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }

                                    setState(() {
                                      _alertMinutes = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          const _InfoBox(
                            text:
                                'Esse tempo será usado no Modo crise para avisar quando a crise passar do limite configurado.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Cuidados importantes',
                        icon: Icons.health_and_safety_outlined,
                        children: [
                          TextFormField(
                            controller: _allergiesController,
                            enabled: !_saving,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Alergias',
                              hintText:
                                  'Ex.: medicamentos, alimentos, produtos...',
                              prefixIcon: Icon(Icons.warning_amber_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _sensitivitiesController,
                            enabled: !_saving,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Sensibilidades',
                              hintText:
                                  'Ex.: sons altos, luz forte, toque, cheiros...',
                              prefixIcon: Icon(Icons.sensors_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _calmingPreferencesController,
                            enabled: !_saving,
                            minLines: 2,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Preferências para acalmar',
                              hintText:
                                  'Ex.: ambiente silencioso, luz baixa, objeto favorito...',
                              prefixIcon: Icon(Icons.self_improvement_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Observações gerais',
                        icon: Icons.notes_outlined,
                        children: [
                          TextFormField(
                            controller: _notesController,
                            enabled: !_saving,
                            minLines: 4,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Observações',
                              hintText:
                                  'Informações importantes para responsáveis, cuidadores e rede de apoio.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _saving
                        ? null
                        : () {
                            _save(childId);
                          },
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Salvando...' : 'Salvar informações'),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String childName;
  final String birthDate;

  const _HeaderCard({required this.childName, required this.birthDate});

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
                Icons.child_care_outlined,
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
                    childName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nascimento: $birthDate',
                    style: const TextStyle(color: Color(0xFF4B5563)),
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
  final String text;

  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFF97316)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFF7C2D12), height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildInfoFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ChildInfoFeedback({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        title: const Text('Informações da criança'),
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
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cadastre ou selecione uma criança para editar as informações.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
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
