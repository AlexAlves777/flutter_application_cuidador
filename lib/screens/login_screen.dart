import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import 'child_question_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'support_pending_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  final _auth = AuthService();

  bool _carregando = false;
  bool _senhaVisivel = false;
  bool _lembrarEmail = false;

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    final lembrarEmail = prefs.getBool('lembrar_email') ?? false;
    final emailSalvo = prefs.getString('email_salvo') ?? '';

    if (!mounted) return;

    setState(() {
      _lembrarEmail = lembrarEmail;

      if (lembrarEmail) {
        _emailCtrl.text = emailSalvo;
      }
    });
  }

  Future<void> _salvarPreferenciasLogin(String email) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('lembrar_email', _lembrarEmail);

    if (_lembrarEmail) {
      await prefs.setString('email_salvo', email);
    } else {
      await prefs.remove('email_salvo');
    }
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

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;

    setState(() => _carregando = true);

    try {
      await _auth.entrar(
        email: email,
        senha: senha,
      );

      await _salvarPreferenciasLogin(email);

      final dadosUsuario = await _auth.buscarDadosUsuario();
      final dados = dadosUsuario.data();

      if (!mounted) return;

      if (dados == null) {
        _mostrarMensagem('Dados do usuário não encontrados.');
        return;
      }

      final perfil = dados['perfil']?.toString() ?? '';
      final statusVinculo = dados['statusVinculo']?.toString() ?? '';

      if (statusVinculo == 'ativo') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              nomeUsuario: dados['nome']?.toString(),
            ),
          ),
        );
        return;
      }

      if (statusVinculo == 'precisa_definir_crianca') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChildQuestionScreen(
              perfil: perfil,
            ),
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SupportPendingScreen(),
        ),
      );
    } on FirebaseAuthException catch (erro) {
      _mostrarMensagem(AuthService.traduzirErro(erro));
    } catch (_) {
      _mostrarMensagem('Não foi possível entrar. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _esqueciSenha() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _mostrarMensagem('Digite seu e-mail no campo acima primeiro.');
      return;
    }

    try {
      await _auth.esqueciSenha(email);

      _mostrarMensagem(
        'Enviamos um e-mail para redefinir sua senha.',
        erro: false,
      );
    } on FirebaseAuthException catch (erro) {
      _mostrarMensagem(AuthService.traduzirErro(erro));
    } catch (_) {
      _mostrarMensagem('Não foi possível enviar o e-mail de redefinição.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Entrar'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F8FC),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Color(0xFF5B6EF5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bem-vindo de volta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entre para acessar a rotina, registros e cuidados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 32),
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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_carregando) {
                        _entrar();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _senhaVisivel
                              ? Icons.visibility_off
                              : Icons.visibility,
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
                        return 'Informe sua senha.';
                      }

                      if (valor.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _lembrarEmail,
                    onChanged: _carregando
                        ? null
                        : (valor) {
                            setState(() {
                              _lembrarEmail = valor ?? false;
                            });
                          },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Lembrar meu e-mail'),
                    subtitle: const Text('Sua senha não será salva.'),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _carregando ? null : _esqueciSenha,
                      child: const Text('Esqueci a senha'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _carregando ? null : _entrar,
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
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Não tem conta?'),
                      TextButton(
                        onPressed: _carregando
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                        child: const Text('Cadastre-se'),
                      ),
                    ],
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
