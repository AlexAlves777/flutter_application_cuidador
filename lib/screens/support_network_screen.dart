import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupportNetworkScreen extends StatefulWidget {
  const SupportNetworkScreen({super.key});

  @override
  State<SupportNetworkScreen> createState() => _SupportNetworkScreenState();
}

class _SupportNetworkScreenState extends State<SupportNetworkScreen> {
  static const _primary = Color(0xFF5B6EF5);
  static const _pageBackground = Color(0xFFF7F8FC);

  static const _relationships = [
    'Avô',
    'Avó',
    'Tio',
    'Tia',
    'Primo',
    'Prima',
    'Irmão',
    'Irmã',
    'Cuidador',
    'Outro',
  ];

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

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection('users');
  }

  CollectionReference<Map<String, dynamic>> get _childLinks {
    return _firestore.collection('child_links');
  }

  String _normalizeCode(String value) {
    return value.trim().replaceAll(' ', '').toUpperCase();
  }

  String _roleFromRelationship(String relationship) {
    if (relationship == 'Cuidador') {
      return 'cuidador';
    }

    return 'rede_apoio';
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'aprovado':
        return 'Aprovado';
      case 'pendente':
        return 'Pendente';
      case 'rejeitado':
        return 'Rejeitado';
      case 'removido':
        return 'Removido';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'aprovado':
        return const Color(0xFF10B981);
      case 'pendente':
        return const Color(0xFFF59E0B);
      case 'rejeitado':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Future<void> _openAddPersonSheet(String childId) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddSupportPersonSheet(
          relationships: _relationships,
          onAdd: ({required String code, required String relationship}) async {
            await _addSupportPerson(
              childId: childId,
              code: code,
              relationship: relationship,
            );
          },
        );
      },
    );

    if (added == true && mounted) {
      _showMessage('Pessoa vinculada com sucesso.');
    }
  }

  Future<void> _addSupportPerson({
    required String childId,
    required String code,
    required String relationship,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Usuário não autenticado.');
    }

    final normalizedCode = _normalizeCode(code);

    if (normalizedCode.isEmpty) {
      throw Exception('Informe o código de vínculo.');
    }

    final usersResult = await _users
        .where('codigoVinculo', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (usersResult.docs.isEmpty) {
      throw Exception('Nenhum usuário encontrado com esse código.');
    }

    final targetUserDocument = usersResult.docs.first;
    final targetUserId = targetUserDocument.id;
    final targetUserData = targetUserDocument.data();

    if (targetUserId == currentUser.uid) {
      throw Exception('Você não pode vincular a si mesmo.');
    }

    final existingLinks = await _childLinks
        .where('childId', isEqualTo: childId)
        .get();

    final alreadyLinked = existingLinks.docs.any((document) {
      final data = document.data();
      final sameUser = data['userId'] == targetUserId;
      final status = data['status'] as String? ?? '';

      return sameUser && status != 'removido';
    });

    if (alreadyLinked) {
      throw Exception('Essa pessoa já está vinculada à criança.');
    }

    final linkDocument = _childLinks.doc();
    final role = _roleFromRelationship(relationship);

    final batch = _firestore.batch();

    batch.set(linkDocument, {
      'childId': childId,
      'userId': targetUserId,
      'nomeUsuario': targetUserData['nome'] ?? '',
      'emailUsuario': targetUserData['email'] ?? '',
      'papel': role,
      'parentesco': relationship,
      'status': 'aprovado',
      'criadoPor': currentUser.uid,
      'aprovadoPor': currentUser.uid,
      'criadoEm': FieldValue.serverTimestamp(),
      'aprovadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });

    batch.set(_users.doc(targetUserId), {
      'statusVinculo': 'ativo',
      'childIdAtual': childId,
      'papelAtual': role,
      'parentescoAtual': relationship,
      'aprovadoPor': currentUser.uid,
      'atualizadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> _confirmRemovePerson({
    required String childId,
    required String linkId,
    required String userId,
    required String name,
  }) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover da rede de apoio?'),
          content: Text('$name perderá o acesso à criança selecionada.'),
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
              child: const Text('Remover', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (remove != true) {
      return;
    }

    await _removePerson(childId: childId, linkId: linkId, userId: userId);
  }

  Future<void> _removePerson({
    required String childId,
    required String linkId,
    required String userId,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      _showMessage('Usuário não autenticado.');
      return;
    }

    if (userId == currentUser.uid) {
      _showMessage('Você não pode remover seu próprio vínculo.');
      return;
    }

    try {
      final userDocument = await _users.doc(userId).get();
      final userData = userDocument.data();

      final batch = _firestore.batch();

      batch.update(_childLinks.doc(linkId), {
        'status': 'removido',
        'removidoPor': currentUser.uid,
        'removidoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      if (userData?['childIdAtual'] == childId) {
        batch.update(_users.doc(userId), {
          'statusVinculo': 'aguardando_vinculo',
          'childIdAtual': FieldValue.delete(),
          'papelAtual': FieldValue.delete(),
          'parentescoAtual': FieldValue.delete(),
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        _showMessage('Pessoa removida da rede de apoio.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível remover a pessoa.');
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
                _activeChildId = _findActiveChildId();
              });
            },
          );
        }

        return Scaffold(
          backgroundColor: _pageBackground,
          appBar: AppBar(
            title: const Text('Rede de apoio'),
            centerTitle: true,
            backgroundColor: _pageBackground,
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            onPressed: () {
              _openAddPersonSheet(childId);
            },
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Adicionar'),
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _childLinks
                .where('childId', isEqualTo: childId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _SupportFeedback(
                  icon: Icons.cloud_off_outlined,
                  title: 'Não foi possível carregar a rede de apoio',
                  subtitle: 'Verifique sua conexão e tente novamente.',
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final links =
                  snapshot.data!.docs.where((document) {
                    final status = document.data()['status'] as String? ?? '';

                    return status != 'removido';
                  }).toList()..sort((a, b) {
                    final aStatus = a.data()['status'] as String? ?? '';
                    final bStatus = b.data()['status'] as String? ?? '';

                    if (aStatus == bStatus) {
                      final aName = a.data()['nomeUsuario'] as String? ?? '';
                      final bName = b.data()['nomeUsuario'] as String? ?? '';

                      return aName.compareTo(bName);
                    }

                    if (aStatus == 'aprovado') {
                      return -1;
                    }

                    return 1;
                  });

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _SupportHeader(totalPeople: links.length),
                  ),
                  if (links.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _SupportFeedback(
                        icon: Icons.group_outlined,
                        title: 'Nenhuma pessoa vinculada',
                        subtitle:
                            'Adicione cuidadores ou familiares usando o código de vínculo.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList.separated(
                        itemCount: links.length,
                        itemBuilder: (context, index) {
                          final link = links[index];
                          final data = link.data();
                          final currentUserId = _auth.currentUser?.uid;
                          final userId = data['userId'] as String? ?? '';
                          final isCurrentUser = userId == currentUserId;

                          return _SupportPersonCard(
                            linkData: data,
                            isCurrentUser: isCurrentUser,
                            displayStatus: _displayStatus,
                            statusColor: _statusColor,
                            onRemove: () {
                              final name =
                                  data['nomeUsuario'] as String? ?? 'Usuário';

                              _confirmRemovePerson(
                                childId: childId,
                                linkId: link.id,
                                userId: userId,
                                name: name,
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
        );
      },
    );
  }
}

class _SupportHeader extends StatelessWidget {
  final int totalPeople;

  const _SupportHeader({required this.totalPeople});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pessoas autorizadas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gerencie quem pode acompanhar a rotina, os registros e os cuidados da criança.',
            style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF5B6EF5),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      totalPeople == 1
                          ? '1 pessoa vinculada'
                          : '$totalPeople pessoas vinculadas',
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportPersonCard extends StatelessWidget {
  final Map<String, dynamic> linkData;
  final bool isCurrentUser;
  final String Function(String status) displayStatus;
  final Color Function(String status) statusColor;
  final VoidCallback onRemove;

  const _SupportPersonCard({
    required this.linkData,
    required this.isCurrentUser,
    required this.displayStatus,
    required this.statusColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = linkData['nomeUsuario'] as String? ?? 'Usuário sem nome';
    final email = linkData['emailUsuario'] as String? ?? '';
    final relationship = linkData['parentesco'] as String? ?? 'Não informado';
    final role = linkData['papel'] as String? ?? 'rede_apoio';
    final status = linkData['status'] as String? ?? 'aprovado';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE8EAFF),
              foregroundColor: const Color(0xFF5B6EF5),
              child: Text(
                name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrentUser ? '$name (você)' : name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _Tag(
                        icon: Icons.family_restroom_outlined,
                        label: relationship,
                      ),
                      _Tag(
                        icon: Icons.badge_outlined,
                        label: role == 'cuidador'
                            ? 'Cuidador'
                            : 'Rede de apoio',
                      ),
                      _StatusTag(
                        label: displayStatus(status),
                        color: statusColor(status),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isCurrentUser)
              PopupMenuButton<String>(
                tooltip: 'Opções',
                onSelected: (value) {
                  if (value == 'remove') {
                    onRemove();
                  }
                },
                itemBuilder: (_) {
                  return const [
                    PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        leading: Icon(
                          Icons.person_remove_alt_1_outlined,
                          color: Colors.red,
                        ),
                        title: Text(
                          'Remover',
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

class _AddSupportPersonSheet extends StatefulWidget {
  final List<String> relationships;
  final Future<void> Function({
    required String code,
    required String relationship,
  })
  onAdd;

  const _AddSupportPersonSheet({
    required this.relationships,
    required this.onAdd,
  });

  @override
  State<_AddSupportPersonSheet> createState() => _AddSupportPersonSheetState();
}

class _AddSupportPersonSheetState extends State<_AddSupportPersonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  late String _relationship;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _relationship = widget.relationships.first;
  }

  @override
  void dispose() {
    _codeController.dispose();

    super.dispose();
  }

  Future<void> _add() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.onAdd(
        code: _codeController.text,
        relationship: _relationship,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      final message = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
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
                    'Adicionar à rede',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Informe o código de vínculo enviado pela pessoa que será adicionada.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _codeController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Código de vínculo',
                      hintText: 'Ex.: A1B2C3',
                      prefixIcon: Icon(Icons.qr_code_2_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o código de vínculo.';
                      }

                      if (value.trim().length < 4) {
                        return 'Código muito curto.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _relationship,
                    decoration: const InputDecoration(
                      labelText: 'Parentesco ou função',
                      prefixIcon: Icon(Icons.family_restroom_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: widget.relationships.map((relationship) {
                      return DropdownMenuItem<String>(
                        value: relationship,
                        child: Text(relationship),
                      );
                    }).toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _relationship = value;
                            });
                          },
                  ),
                  const SizedBox(height: 20),
                  const _InfoBox(
                    icon: Icons.info_outline,
                    text:
                        'Após adicionar, essa pessoa terá acesso à criança ativa no aplicativo.',
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _saving ? null : _add,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1_outlined),
                    label: Text(
                      _saving ? 'Adicionando...' : 'Adicionar pessoa',
                    ),
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

class _StatusTag extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
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

class _SupportFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SupportFeedback({
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
        title: const Text('Rede de apoio'),
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
                'Cadastre ou selecione uma criança para gerenciar a rede de apoio.',
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
