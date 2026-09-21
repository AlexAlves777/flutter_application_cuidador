# Cuidador - Aplicativo de Apoio à Rotina de Famílias Atípicas

Aplicativo mobile desenvolvido em Flutter para apoiar pais, responsáveis, cuidadores e rede de apoio na organização da rotina de crianças neurodivergentes, com foco inicial em crianças com TEA.

O projeto faz parte de uma POC acadêmica/TCC e tem como objetivo centralizar informações importantes da criança, rotina diária, registros de comportamento, vínculos de apoio e dados básicos de acompanhamento.

---

## Objetivo do projeto

O aplicativo busca auxiliar famílias e cuidadores na gestão da rotina da criança, permitindo:

- Cadastro de responsáveis, cuidadores e rede de apoio;
- Cadastro de uma ou mais crianças;
- Controle de vínculos entre usuários e crianças;
- Persistência de login;
- Recuperação de sessão ao fechar e abrir o app;
- Registro inicial dos dados da criança;
- Base para futuras funcionalidades como agenda, medicamentos, terapias, laudos e registros comportamentais.

---

## Tecnologias utilizadas

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Shared Preferences
- Android Studio
- Git/GitHub

---

## Funcionalidades já implementadas

### Autenticação

- Cadastro de usuário com Firebase Authentication;
- Login com e-mail e senha;
- Logout;
- Recuperação de sessão ao reabrir o aplicativo;
- Opção de lembrar e-mail no login;
- Tratamento de erros comuns de autenticação.

### Cadastro de usuário

Perfis disponíveis:

- Pai
- Mãe
- Responsável principal
- Cuidador
- Rede de apoio

### Fluxo de cadastro

Para perfis responsáveis:

```txt
Cadastro de usuário
→ Pergunta se a criança já está cadastrada
→ Caso não esteja, cadastra a criança
→ Cria vínculo aprovado
→ Vai para Home