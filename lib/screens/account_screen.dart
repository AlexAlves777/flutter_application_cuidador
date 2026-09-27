import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'welcome_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const _primary = Color(0xFF5B6EF5);
  static const _pageBackground = Color(0xFFF7F8FC);

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();

  final _nameController = TextEditingController();

  var _savingName = false;
  var _sendingPasswordReset = false;
  var _nameLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  User? get _currentUser {
    return _auth.currentUser;
  }

  DocumentReference<Map<String, dynamic>> _userDocument(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<String?> _findChildName(String? childId) async {
    if (childId == null || childId.isEmpty) {
      return null;
    }

    final childDocument = await _firestore
        .collection('children')
        .doc(childId)
        .get();

    return childDocument.data()?['nome'] as String?;
  }

  String _displayText(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return 'Não informado';
    }

    return text;
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'ativo':
        return 'Ativo';
      case 'aguardando_vinculo':
        return 'Aguardando vínculo';
      case 'precisa_definir_crianca':
        return 'Precisa definir criança';
      case 'pendente':
        return 'Pendente';
      case 'aprovado':
        return 'Aprovado';
      case 'rejeitado':
        return 'Rejeitado';
      default:
        return _displayText(status);
    }
  }

  String _displayProfile(String profile) {
    switch (profile.toLowerCase()) {
      case 'pai':
        return 'Pai';
      case 'mãe':
      case 'mae':
        return 'Mãe';
      case 'responsável principal':
      case 'responsavel principal':
        return 'Responsável principal';
      case 'rede de apoio':
        return 'Rede de apoio';
      case 'cuidador':
        return 'Cuidador';
      default:
        return _displayText(profile);
    }
  }

  void _loadName(Map<String, dynamic> data) {
    if (_nameLoaded) {
      return;
    }

    final savedName = data['nome'] as String?;
    final authName = _currentUser?.displayName;

    _nameController.text = savedName?.trim().isNotEmpty == true
        ? savedName!.trim()
        : authName?.trim() ?? '';

    _nameLoaded = true;
  }

  Future<void> _saveName(String uid) async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Informe seu nome.');
      return;
    }

    setState(() {
      _savingName = true;
    });

    try {
      await _currentUser?.updateDisplayName(name);

      await _userDocument(uid).set({
        'nome': name,
        'atualizadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      _showMessage('Nome atualizado.');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Não foi possível atualizar o nome.');
    } finally {
      if (mounted) {
        setState(() {
          _savingName = false;
        });
      }
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      _showMessage('E-mail não encontrado.');
      return;
    }

    setState(() {
      _sendingPasswordReset = true;
    });

    try {
      await _authService.esqueciSenha(email);

      if (!mounted) {
        return;
      }

      _showMessage('E-mail de redefinição de senha enviado.');
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(AuthService.traduzirErro(error));
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Não foi possível enviar o e-mail de redefinição.');
    } finally {
      if (mounted) {
        setState(() {
          _sendingPasswordReset = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _authService.sair();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair da conta?'),
          content: const Text(
            'Você precisará fazer login novamente para acessar o aplicativo.',
          ),
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
              child: const Text('Sair', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
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
    final user = _currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _pageBackground,
        body: _AccountFeedback(
          icon: Icons.lock_outline,
          title: 'Usuário não autenticado',
          subtitle: 'Faça login novamente para acessar sua conta.',
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocument(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: _pageBackground,
            body: _AccountFeedback(
              icon: Icons.cloud_off_outlined,
              title: 'Não foi possível carregar a conta',
              subtitle: 'Verifique sua conexão e tente novamente.',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: _pageBackground,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final document = snapshot.data!;
        final data = document.data() ?? {};

        _loadName(data);

        final email = user.email ?? data['email'] as String? ?? '';
        final profile = _displayProfile(data['perfil'] as String? ?? '');
        final status = _displayStatus(data['statusVinculo'] as String? ?? '');
        final code = _displayText(data['codigoVinculo']);
        final childId = data['childIdAtual'] as String?;

        return Scaffold(
          backgroundColor: _pageBackground,
          appBar: AppBar(
            title: const Text('Minha conta'),
            centerTitle: true,
            backgroundColor: _pageBackground,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                _AccountHeader(
                  name: _nameController.text.trim().isEmpty
                      ? 'Usuário'
                      : _nameController.text.trim(),
                  email: email,
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Dados da conta',
                  icon: Icons.person_outline,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: !_savingName,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _savingName
                          ? null
                          : () {
                              _saveName(user.uid);
                            },
                      icon: _savingName
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_savingName ? 'Salvando...' : 'Salvar nome'),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'E-mail',
                      value: _displayText(email),
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Perfil',
                      value: profile,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Status',
                      value: status,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Vínculo',
                  icon: Icons.link_outlined,
                  children: [
                    _CodeBox(code: code),
                    const SizedBox(height: 14),
                    FutureBuilder<String?>(
                      future: _findChildName(childId),
                      builder: (context, childSnapshot) {
                        final childName =
                            childSnapshot.data?.trim().isNotEmpty == true
                            ? childSnapshot.data!.trim()
                            : 'Nenhuma criança ativa';

                        return _InfoRow(
                          icon: Icons.child_care_outlined,
                          label: 'Criança ativa',
                          value: childName,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Segurança',
                  icon: Icons.lock_outline,
                  children: [
                    const _InfoBox(
                      text:
                          'Para alterar a senha, enviaremos um e-mail de redefinição para o endereço cadastrado.',
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _sendingPasswordReset
                          ? null
                          : () {
                              _sendPasswordReset(email);
                            },
                      icon: _sendingPasswordReset
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.password_outlined),
                      label: Text(
                        _sendingPasswordReset
                            ? 'Enviando...'
                            : 'Enviar redefinição de senha',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Sessão',
                  icon: Icons.logout,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair da conta'),
                    ),
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

class _AccountHeader extends StatelessWidget {
  final String name;
  final String email;

  const _AccountHeader({required this.name, required this.email});

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
                Icons.person_outline,
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
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email.trim().isEmpty ? 'E-mail não informado' : email,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF5B6EF5)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  final String code;

  const _CodeBox({required this.code});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Código de vínculo',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            SelectableText(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esse código pode ser usado por um responsável para vincular você à rede de apoio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), height: 1.35),
            ),
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
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
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

class _AccountFeedback extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AccountFeedback({
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
