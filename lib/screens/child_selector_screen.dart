import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'child_register_screen.dart';

class ChildSelectorScreen extends StatefulWidget {
  const ChildSelectorScreen({super.key});

  @override
  State<ChildSelectorScreen> createState() => _ChildSelectorScreenState();
}

class _ChildSelectorScreenState extends State<ChildSelectorScreen> {
  static const _primary = Color(0xFF5B6EF5);
  static const _pageBackground = Color(0xFFF7F8FC);

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late Future<_ChildSelectorData> _selectorDataFuture;

  String? _savingChildId;

  @override
  void initState() {
    super.initState();
    _selectorDataFuture = _loadSelectorData();
  }

  Future<_ChildSelectorData> _loadSelectorData() async {
    final user = _auth.currentUser;

    if (user == null) {
      return const _ChildSelectorData(children: [], canRegisterChild: false);
    }

    final userDocument = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDocument.data() ?? {};
    final activeChildId = userData['childIdAtual'] as String?;
    final profile = userData['perfil'] as String? ?? '';
    final canRegisterChild = _canRegisterChild(profile);

    final linksSnapshot = await _firestore
        .collection('child_links')
        .where('userId', isEqualTo: user.uid)
        .get();

    final childIds = <String>{};
    final linkByChildId = <String, Map<String, dynamic>>{};

    for (final linkDocument in linksSnapshot.docs) {
      final linkData = linkDocument.data();
      final status = linkData['status'] as String? ?? '';
      final childId = linkData['childId'] as String? ?? '';

      if (status != 'aprovado' || childId.isEmpty) {
        continue;
      }

      childIds.add(childId);
      linkByChildId.putIfAbsent(childId, () => linkData);
    }

    if (activeChildId != null && activeChildId.isNotEmpty) {
      childIds.add(activeChildId);
    }

    final children = <_ChildItem>[];

    for (final childId in childIds) {
      final childDocument = await _firestore
          .collection('children')
          .doc(childId)
          .get();

      final childData = childDocument.data();

      if (!childDocument.exists || childData == null) {
        continue;
      }

      final linkData = linkByChildId[childId];

      children.add(
        _ChildItem(
          id: childId,
          name: _displayText(childData['nome'], fallback: 'Criança sem nome'),
          birthDate: _readDate(childData['dataNascimento']),
          supportLevel: _displayText(childData['nivelSuporte']),
          relationship: _displayRelationship(linkData),
          isActive: childId == activeChildId,
        ),
      );
    }

    children.sort((a, b) {
      if (a.isActive && !b.isActive) {
        return -1;
      }

      if (!a.isActive && b.isActive) {
        return 1;
      }

      return a.name.compareTo(b.name);
    });

    return _ChildSelectorData(
      children: children,
      activeChildId: activeChildId,
      canRegisterChild: canRegisterChild,
    );
  }

  bool _canRegisterChild(String profile) {
    final normalizedProfile = profile.toLowerCase().trim();

    return normalizedProfile == 'pai' ||
        normalizedProfile == 'mãe' ||
        normalizedProfile == 'mae' ||
        normalizedProfile == 'responsável principal' ||
        normalizedProfile == 'responsavel principal';
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

  String _displayText(dynamic value, {String fallback = 'Não informado'}) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }

  String _displayRelationship(Map<String, dynamic>? linkData) {
    if (linkData == null) {
      return 'Criança ativa';
    }

    final relationship = linkData['parentesco'] as String?;
    final role = linkData['papel'] as String?;

    if (relationship != null && relationship.trim().isNotEmpty) {
      return relationship.trim();
    }

    switch (role) {
      case 'responsavel_principal':
        return 'Responsável principal';
      case 'cuidador':
        return 'Cuidador';
      case 'rede_apoio':
        return 'Rede de apoio';
      case 'pai':
        return 'Pai';
      case 'mae':
        return 'Mãe';
      default:
        return 'Vínculo aprovado';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Nascimento não informado';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return 'Nascimento: $day/$month/$year';
  }

  Future<void> _selectChild(_ChildItem child) async {
    if (child.isActive) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Usuário não autenticado.');
      return;
    }

    setState(() {
      _savingChildId = child.id;
    });

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'childIdAtual': child.id,
        'statusVinculo': 'ativo',
        'atualizadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      _showMessage('${child.name} definida como criança ativa.');

      setState(() {
        _selectorDataFuture = _loadSelectorData();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Não foi possível selecionar a criança.');
    } finally {
      if (mounted) {
        setState(() {
          _savingChildId = null;
        });
      }
    }
  }

  Future<void> _openChildRegister() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChildRegisterScreen()));

    if (!mounted) {
      return;
    }

    setState(() {
      _selectorDataFuture = _loadSelectorData();
    });
  }

  void _refresh() {
    setState(() {
      _selectorDataFuture = _loadSelectorData();
    });
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
    return FutureBuilder<_ChildSelectorData>(
      future: _selectorDataFuture,
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
              title: const Text('Crianças vinculadas'),
              centerTitle: true,
              backgroundColor: _pageBackground,
            ),
            body: _ChildSelectorFeedback(
              icon: Icons.cloud_off_outlined,
              title: 'Não foi possível carregar as crianças',
              subtitle: 'Verifique sua conexão e tente novamente.',
              actionLabel: 'Tentar novamente',
              onAction: _refresh,
            ),
          );
        }

        final selectorData =
            snapshot.data ??
            const _ChildSelectorData(children: [], canRegisterChild: false);

        final activeChild = selectorData.children
            .where((child) => child.isActive)
            .cast<_ChildItem?>()
            .firstOrNull;

        return Scaffold(
          backgroundColor: _pageBackground,
          appBar: AppBar(
            title: const Text('Crianças vinculadas'),
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
          floatingActionButton: selectorData.canRegisterChild
              ? FloatingActionButton.extended(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  onPressed: _openChildRegister,
                  icon: const Icon(Icons.add),
                  label: const Text('Cadastrar'),
                )
              : null,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: [
                _SelectorHeader(
                  totalChildren: selectorData.children.length,
                  activeChildName: activeChild?.name,
                ),
                const SizedBox(height: 18),
                if (selectorData.children.isEmpty)
                  _ChildSelectorFeedback(
                    icon: Icons.child_care_outlined,
                    title: 'Nenhuma criança vinculada',
                    subtitle: selectorData.canRegisterChild
                        ? 'Cadastre uma criança para começar a usar o aplicativo.'
                        : 'Você ainda não possui vínculo aprovado com uma criança.',
                    actionLabel: selectorData.canRegisterChild
                        ? 'Cadastrar criança'
                        : null,
                    onAction: selectorData.canRegisterChild
                        ? _openChildRegister
                        : null,
                  )
                else
                  ...selectorData.children.map((child) {
                    final isSaving = _savingChildId == child.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ChildCard(
                        child: child,
                        formattedBirthDate: _formatDate(child.birthDate),
                        isSaving: isSaving,
                        onSelect: () {
                          _selectChild(child);
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectorHeader extends StatelessWidget {
  final int totalChildren;
  final String? activeChildName;

  const _SelectorHeader({
    required this.totalChildren,
    required this.activeChildName,
  });

  @override
  Widget build(BuildContext context) {
    final totalText = totalChildren == 1
        ? '1 criança vinculada'
        : '$totalChildren crianças vinculadas';

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
                Icons.family_restroom_outlined,
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
                    'Crianças',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalText,
                    style: const TextStyle(color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeChildName == null
                        ? 'Nenhuma criança ativa'
                        : 'Ativa: $activeChildName',
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

class _ChildCard extends StatelessWidget {
  final _ChildItem child;
  final String formattedBirthDate;
  final bool isSaving;
  final VoidCallback onSelect;

  const _ChildCard({
    required this.child,
    required this.formattedBirthDate,
    required this.isSaving,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: child.isActive || isSaving ? null : onSelect,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: child.isActive
                    ? const Color(0xFF5B6EF5)
                    : const Color(0xFFE8EAFF),
                foregroundColor: child.isActive
                    ? Colors.white
                    : const Color(0xFF5B6EF5),
                child: Text(
                  child.name.trim().isEmpty
                      ? '?'
                      : child.name.trim()[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedBirthDate,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (child.isActive)
                          const _StatusTag(
                            icon: Icons.check_circle_outline,
                            label: 'Ativa',
                            color: Color(0xFF10B981),
                          ),
                        _StatusTag(
                          icon: Icons.link_outlined,
                          label: child.relationship,
                          color: const Color(0xFF5B6EF5),
                        ),
                        if (child.supportLevel != 'Não informado')
                          _StatusTag(
                            icon: Icons.volunteer_activism,
                            label: child.supportLevel,
                            color: const Color(0xFF6B7280),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSaving)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (child.isActive)
                const Icon(Icons.check_circle, color: Color(0xFF10B981))
              else
                TextButton(onPressed: onSelect, child: const Text('Usar')),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildSelectorFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ChildSelectorFeedback({
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
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChildSelectorData {
  final List<_ChildItem> children;
  final String? activeChildId;
  final bool canRegisterChild;

  const _ChildSelectorData({
    required this.children,
    required this.canRegisterChild,
    this.activeChildId,
  });
}

class _ChildItem {
  final String id;
  final String name;
  final DateTime? birthDate;
  final String supportLevel;
  final String relationship;
  final bool isActive;

  const _ChildItem({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.supportLevel,
    required this.relationship,
    required this.isActive,
  });
}
