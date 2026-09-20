import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'child_question_screen.dart';
import 'support_pending_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  final _auth = AuthService();

  static const List<String> _tiposPerfil = [
    'Pai',
    'Mãe',
    'Responsável principal',
    'Rede de apoio',
    'Cuidador',
  ];

  String? _tipoSelecionado;

  bool _carregando = false;
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto, {bool erro = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  bool _perfilVaiDiretoParaVinculo(String perfil) {
    final perfilNormalizado = perfil.toLowerCase();

    return perfilNormalizado == 'rede de apoio' ||
        perfilNormalizado == 'cuidador';
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;
    final perfil = _tipoSelecionado!;

    setState(() => _carregando = true);

    try {
      await _auth.cadastrarUsuario(
        nome: nome,
        email: email,
        senha: senha,
        perfil: perfil,
      );

      if (!mounted) return;

      if (_perfilVaiDiretoParaVinculo(perfil)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SupportPendingScreen()),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChildQuestionScreen(perfil: perfil)),
      );
    } on FirebaseAuthException catch (erro) {
      _mostrarMensagem(AuthService.traduzirErro(erro));
    } catch (_) {
      _mostrarMensagem('Não foi possível criar sua conta. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Criar conta'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F8FC),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 64,
                  color: Color(0xFF5B6EF5),
                ),

                const SizedBox(height: 16),

                Text(
                  'Criar sua conta',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Informe seus dados e escolha seu papel na rotina da criança.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                ),

                const SizedBox(height: 32),

                TextFormField(
                  controller: _nomeCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    final nome = valor?.trim() ?? '';

                    if (nome.isEmpty) {
                      return 'Informe seu nome.';
                    }

                    if (nome.length < 2) {
                      return 'Nome muito curto.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    final email = valor?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Informe seu e-mail.';
                    }

                    if (!email.contains('@') || !email.contains('.')) {
                      return 'E-mail inválido.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _senhaCtrl,
                  obscureText: !_senhaVisivel,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _senhaVisivel = !_senhaVisivel;
                        });
                      },
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Informe uma senha.';
                    }

                    if (valor.length < 6) {
                      return 'A senha precisa ter pelo menos 6 caracteres.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _tipoSelecionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de perfil',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _tiposPerfil
                      .map(
                        (tipo) =>
                            DropdownMenuItem(value: tipo, child: Text(tipo)),
                      )
                      .toList(),
                  onChanged: _carregando
                      ? null
                      : (valor) {
                          setState(() {
                            _tipoSelecionado = valor;
                          });
                        },
                  validator: (valor) {
                    if (valor == null) {
                      return 'Selecione um tipo de perfil.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _carregando ? null : _cadastrar,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _carregando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Cadastrar'),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: _carregando
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Já tenho conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
