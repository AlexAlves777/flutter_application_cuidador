import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get mudancasDeAutenticacao {
    return _auth.authStateChanges();
  }

  User? get usuarioAtual {
    return _auth.currentUser;
  }

  Future<UserCredential> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String perfil,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );

    final usuario = credencial.user;

    if (usuario == null) {
      throw Exception('Não foi possível criar o usuário.');
    }

    await usuario.updateDisplayName(nome.trim());

    await _firestore.collection('users').doc(usuario.uid).set({
      'uid': usuario.uid,
      'nome': nome.trim(),
      'email': email.trim(),
      'perfil': perfil,
      'codigoVinculo': _gerarCodigoVinculo(usuario.uid),
      'statusVinculo': _definirStatusInicial(perfil),
      'childIdAtual': null,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });

    return credencial;
  }

  Future<UserCredential> entrar({
    required String email,
    required String senha,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<void> sair() {
    return _auth.signOut();
  }

  Future<void> esqueciSenha(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> buscarDadosUsuario() async {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw Exception('Nenhum usuário autenticado.');
    }

    return _firestore.collection('users').doc(usuario.uid).get();
  }

  String _definirStatusInicial(String perfil) {
    final perfilNormalizado = perfil.toLowerCase();

    if (perfilNormalizado == 'rede de apoio' ||
        perfilNormalizado == 'cuidador') {
      return 'aguardando_vinculo';
    }

    return 'precisa_definir_crianca';
  }

  String _gerarCodigoVinculo(String uid) {
    if (uid.length < 6) {
      return uid.toUpperCase();
    }

    return uid.substring(0, 6).toUpperCase();
  }

  static String traduzirErro(FirebaseAuthException erro) {
    switch (erro.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Este usuário foi desativado.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'Login por e-mail e senha não está ativado no Firebase.';
      case 'network-request-failed':
        return 'Falha de conexão. Verifique sua internet.';
      default:
        return 'Erro de autenticação: ${erro.message ?? erro.code}';
    }
  }
}
