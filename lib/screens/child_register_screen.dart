import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

class ChildRegisterScreen extends StatefulWidget {
  const ChildRegisterScreen({super.key});

  @override
  State<ChildRegisterScreen> createState() => _ChildRegisterScreenState();
}

class _ChildRegisterScreenState extends State<ChildRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  DateTime? _dataNascimento;
  String? _nivelSuporte;
  bool _carregando = false;

  static const List<String> _niveisSuporte = [
    'Nível 1 - Requer apoio',
    'Nível 2 - Requer apoio substancial',
    'Nível 3 - Requer apoio muito substancial',
    'Não informado',
  ];

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _observacoesCtrl.dispose();
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

  Future<void> _selecionarDataNascimento() async {
    final agora = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: DateTime(2018),
      firstDate: DateTime(1990),
      lastDate: agora,
    );

    if (data != null) {
      setState(() {
        _dataNascimento = data;
      });
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  Future<void> _salvarCrianca() async {
    if (!_formKey.currentState!.validate()) return;

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      _mostrarMensagem('Usuário não autenticado.');
      return;
    }

    setState(() => _carregando = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final childRef = firestore.collection('children').doc();

      await childRef.set({
        'id': childRef.id,
        'nome': _nomeCtrl.text.trim(),
        'dataNascimento': _dataNascimento == null
            ? null
            : Timestamp.fromDate(_dataNascimento!),
        'nivelSuporte': _nivelSuporte,
        'observacoes': _observacoesCtrl.text.trim(),
        'responsavelPrincipalId': usuario.uid,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      await firestore.collection('child_links').doc().set({
        'childId': childRef.id,
        'userId': usuario.uid,
        'papel': 'responsavel_principal',
        'status': 'aprovado',
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      await firestore.collection('users').doc(usuario.uid).update({
        'statusVinculo': 'ativo',
        'childIdAtual': childRef.id,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (_) {
      _mostrarMensagem('Não foi possível cadastrar a criança.');
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textoData = _dataNascimento == null
        ? 'Selecionar data de nascimento'
        : _formatarData(_dataNascimento!);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Cadastro da criança'),
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
                  Icons.child_care_outlined,
                  size: 64,
                  color: Color(0xFF5B6EF5),
                ),

                const SizedBox(height: 16),

                Text(
                  'Cadastrar criança',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Essas informações serão usadas para organizar a rotina e os cuidados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                ),

                const SizedBox(height: 32),

                TextFormField(
                  controller: _nomeCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome da criança',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    final nome = valor?.trim() ?? '';

                    if (nome.isEmpty) {
                      return 'Informe o nome da criança.';
                    }

                    if (nome.length < 2) {
                      return 'Nome muito curto.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _carregando ? null : _selecionarDataNascimento,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(textoData),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _nivelSuporte,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Nível de suporte',
                    prefixIcon: Icon(Icons.psychology_alt_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _niveisSuporte
                      .map(
                        (nivel) =>
                            DropdownMenuItem(value: nivel, child: Text(nivel)),
                      )
                      .toList(),
                  onChanged: _carregando
                      ? null
                      : (valor) {
                          setState(() {
                            _nivelSuporte = valor;
                          });
                        },
                  validator: (valor) {
                    if (valor == null) {
                      return 'Selecione o nível de suporte.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _observacoesCtrl,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Observações importantes',
                    hintText:
                        'Ex.: alergias, sensibilidades, rotina, gatilhos, preferências...',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _carregando ? null : _salvarCrianca,
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
                      : const Text('Salvar e continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
