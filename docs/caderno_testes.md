# Caderno de Testes - Aplicativo Cuidador

## 1. Objetivo

Este documento descreve os testes manuais da POC do Aplicativo Cuidador.

O objetivo é validar os principais fluxos do sistema:

- Cadastro e login de usuários.
- Cadastro e seleção de criança.
- Agenda diária.
- Registro de comportamento.
- Registro e acompanhamento de crise.
- Rede de apoio.
- Informações da criança.
- Minha conta.
- Resumo e relatórios.

---

## 2. Ambiente de teste

| Item | Descrição |
|---|---|
| Aplicativo | Aplicativo Cuidador |
| Plataforma | Android |
| Ambiente | Emulador Android |
| Backend | Firebase Authentication e Cloud Firestore |
| Banco de dados | Firestore |
| Tipo de teste | Teste manual funcional |
| Responsável pelo teste | Alex Alves |

---

## 3. Massa de dados sugerida

### Conta responsável

| Campo | Valor sugerido |
|---|---|
| Nome | Responsável Teste |
| E-mail | responsavel.teste@gmail.com |
| Senha | 123456 |
| Perfil | Pai, Mãe ou Responsável principal |

### Conta cuidador

| Campo | Valor sugerido |
|---|---|
| Nome | Cuidador Teste |
| E-mail | cuidador.teste@gmail.com |
| Senha | 123456 |
| Perfil | Cuidador |

### Criança

| Campo | Valor sugerido |
|---|---|
| Nome | Criança Teste |
| Data de nascimento | 10/05/2018 |
| Nível de suporte | Nível 2 - Requer apoio substancial |
| Observações | Necessita de rotina visual e ambiente calmo |

---

## 4. Status dos testes

| Status | Significado |
|---|---|
| Pendente | Ainda não testado |
| Aprovado | Funcionou conforme esperado |
| Reprovado | Não funcionou conforme esperado |
| Bloqueado | Não foi possível testar por dependência ou erro anterior |

---

# 5. Casos de teste

---

## CT-001 - Criar conta de responsável

| Campo | Descrição |
|---|---|
| Módulo | Cadastro |
| Objetivo | Validar criação de conta para Pai, Mãe ou Responsável principal |
| Pré-condição | App instalado e Firebase configurado |
| Status | Aprovado |

### Passos

1. Abrir o aplicativo.
2. Acessar a tela de cadastro.
3. Informar nome, e-mail e senha.
4. Selecionar perfil Pai, Mãe ou Responsável principal.
5. Clicar em cadastrar.

### Resultado esperado

- O usuário deve ser criado no Firebase Authentication.
- O documento do usuário deve ser criado na coleção `users`.
- O app deve redirecionar para a pergunta sobre criança cadastrada.

---

## CT-002 - Criar conta de cuidador

| Campo | Descrição |
|---|---|
| Módulo | Cadastro |
| Objetivo | Validar criação de conta para Cuidador |
| Pré-condição | App instalado e Firebase configurado |
| Status | Aprovado |

### Passos

1. Abrir o aplicativo.
2. Acessar a tela de cadastro.
3. Informar nome, e-mail e senha.
4. Selecionar perfil Cuidador.
5. Clicar em cadastrar.

### Resultado esperado

- O usuário deve ser criado no Firebase Authentication.
- O documento do usuário deve ser criado na coleção `users`.
- O campo `statusVinculo` deve ficar como `aguardando_vinculo`.
- O app deve abrir a tela de Aguardando vínculo.
- A tela deve exibir o código de vínculo.

---

## CT-003 - Login com usuário cadastrado

| Campo | Descrição |
|---|---|
| Módulo | Login |
| Objetivo | Validar login com e-mail e senha |
| Pré-condição | Usuário já cadastrado |
| Status | Aprovado |

### Passos

1. Abrir o aplicativo.
2. Acessar a tela de login.
3. Informar e-mail e senha válidos.
4. Clicar em entrar.

### Resultado esperado

- O app deve autenticar o usuário.
- Se o usuário estiver ativo, deve abrir a Home.
- Se o usuário estiver aguardando vínculo, deve abrir a tela de Aguardando vínculo.
- Se o usuário precisar cadastrar criança, deve abrir o fluxo de cadastro de criança.

---

## CT-004 - Recuperação de senha

| Campo | Descrição |
|---|---|
| Módulo | Login |
| Objetivo | Validar envio de e-mail de redefinição de senha |
| Pré-condição | Usuário já cadastrado |
| Status | Aprovado |

### Passos

1. Abrir a tela de login.
2. Informar um e-mail cadastrado.
3. Clicar em esqueci minha senha.

### Resultado esperado

- O Firebase deve enviar e-mail de redefinição de senha.
- O app deve exibir mensagem de sucesso.

---

## CT-005 - Cadastrar criança

| Campo | Descrição |
|---|---|
| Módulo | Cadastro da criança |
| Objetivo | Validar cadastro inicial da criança |
| Pré-condição | Usuário responsável logado |
| Status | Aprovado |

### Passos

1. Fazer login com usuário responsável.
2. Informar que ainda não existe criança cadastrada.
3. Preencher os dados da criança.
4. Salvar.

### Resultado esperado

- O documento da criança deve ser criado na coleção `children`.
- O vínculo deve ser criado na coleção `child_links`.
- O usuário deve receber `childIdAtual`.
- O `statusVinculo` do usuário deve ser atualizado para `ativo`.
- O app deve abrir a Home.

---

## CT-006 - Acessar Home

| Campo | Descrição |
|---|---|
| Módulo | Home |
| Objetivo | Validar carregamento da tela inicial |
| Pré-condição | Usuário ativo e logado |
| Status | Aprovado |
### Observação

Para usuários com perfil Cuidador ou Rede de apoio, o card "Rede de apoio" não deve ser exibido na Home.

Esse card deve aparecer apenas para Pai, Mãe ou Responsável principal.

### Passos

1. Fazer login com usuário ativo.
2. Aguardar abertura da Home.

### Resultado esperado

- A Home deve ser exibida.
- O botão de Minha conta deve aparecer no topo.
- Os cards principais devem aparecer.
- O botão de registrar crise agora deve aparecer em destaque.

---

## CT-007 - Editar informações da criança

| Campo | Descrição |
|---|---|
| Módulo | Informações da criança |
| Objetivo | Validar edição dos dados da criança ativa |
| Pré-condição | Usuário ativo com criança cadastrada |
| Status | Pendente |

### Passos

1. Acessar Home.
2. Clicar em Informações da criança.
3. Editar alergias, sensibilidades, preferências para acalmar e tempo de alerta.
4. Salvar informações.

### Resultado esperado

- Os dados devem ser salvos no documento da criança em `children`.
- O campo `tempoAlertaCriseMinutos` deve ser atualizado.
- O app deve exibir mensagem de sucesso.

---

## CT-008 - Criar item na agenda diária

| Campo | Descrição |
|---|---|
| Módulo | Agenda diária |
| Objetivo | Validar criação de atividade na agenda |
| Pré-condição | Usuário ativo com criança ativa |
| Status | Pendente |

### Passos

1. Acessar Home.
2. Clicar em Agenda diária.
3. Clicar em adicionar atividade.
4. Preencher título, tipo, horário e observações.
5. Salvar.

### Resultado esperado

- A atividade deve ser criada em `children/{childId}/agenda_items`.
- A atividade deve aparecer na lista da agenda.

---

## CT-009 - Marcar atividade como concluída

| Campo | Descrição |
|---|---|
| Módulo | Agenda diária |
| Objetivo | Validar conclusão de uma atividade |
| Pré-condição | Existir atividade cadastrada na agenda |
| Status | Pendente |

### Passos

1. Acessar Agenda diária.
2. Selecionar uma atividade.
3. Marcar como concluída.

### Resultado esperado

- A atividade deve atualizar o campo `concluida` para `true`.
- A interface deve mostrar a atividade como concluída.

---

## CT-010 - Excluir atividade da agenda

| Campo | Descrição |
|---|---|
| Módulo | Agenda diária |
| Objetivo | Validar exclusão de atividade |
| Pré-condição | Existir atividade cadastrada na agenda |
| Status | Pendente |

### Passos

1. Acessar Agenda diária.
2. Selecionar uma atividade.
3. Excluir a atividade.

### Resultado esperado

- A atividade deve ser removida da subcoleção `agenda_items`.
- A atividade não deve aparecer mais na lista.

---

## CT-011 - Criar registro de comportamento

| Campo | Descrição |
|---|---|
| Módulo | Comportamento e crises |
| Objetivo | Validar criação de registro manual de comportamento |
| Pré-condição | Usuário ativo com criança ativa |
| Status | Pendente |

### Passos

1. Acessar Home.
2. Clicar em Comportamento e crises.
3. Clicar em Novo registro.
4. Selecionar tipo de registro.
5. Preencher intensidade, gatilho, estratégia e observações.
6. Salvar.

### Resultado esperado

- O registro deve ser criado em `children/{childId}/behavior_records`.
- O registro deve aparecer na lista.
- Os filtros devem permitir localizar o registro criado.

---

## CT-012 - Filtrar registros de comportamento

| Campo | Descrição |
|---|---|
| Módulo | Comportamento e crises |
| Objetivo | Validar filtros por tipo de registro |
| Pré-condição | Existirem registros de comportamento cadastrados |
| Status | Pendente |

### Passos

1. Acessar Comportamento e crises.
2. Selecionar os filtros disponíveis.
3. Alternar entre Todos, Crises, Observações, Alimentação, Sono e outros.

### Resultado esperado

- A lista deve exibir apenas registros compatíveis com o filtro selecionado.
- O app não deve apresentar erro visual ou tela vermelha.

---

## CT-013 - Iniciar modo crise

| Campo | Descrição |
|---|---|
| Módulo | Modo crise |
| Objetivo | Validar início de registro de crise |
| Pré-condição | Usuário ativo com criança ativa |
| Status | Pendente |

### Passos

1. Acessar Home.
2. Clicar em Registrar crise agora.
3. Clicar em Iniciar registro de crise.

### Resultado esperado

- Um registro deve ser criado em `behavior_records`.
- O campo `tipo` deve ser `Crise`.
- O campo `statusCrise` deve ser `em_andamento`.
- O cronômetro deve iniciar na tela.

---

## CT-014 - Encerrar crise

| Campo | Descrição |
|---|---|
| Módulo | Modo crise |
| Objetivo | Validar encerramento de uma crise em andamento |
| Pré-condição | Existir crise em andamento |
| Status | Pendente |

### Passos

1. Acessar Modo crise.
2. Clicar em Encerrar crise.
3. Preencher intensidade, gatilho, estratégia e observações finais.
4. Salvar.

### Resultado esperado

- O registro deve ser atualizado.
- O campo `statusCrise` deve ser `resolvida`.
- O campo `fimCrise` deve ser preenchido.
- O campo `duracaoSegundos` deve ser preenchido.
- O app deve retornar para estado sem crise em andamento.

---

## CT-015 - Alerta de tempo de crise

| Campo | Descrição |
|---|---|
| Módulo | Modo crise |
| Objetivo | Validar alerta quando crise ultrapassa tempo configurado |
| Pré-condição | Criança com `tempoAlertaCriseMinutos` configurado |
| Status | Pendente |

### Passos

1. Acessar Informações da criança.
2. Definir tempo de alerta como 1 minuto.
3. Salvar.
4. Acessar Modo crise.
5. Iniciar uma crise.
6. Aguardar mais de 1 minuto.

### Resultado esperado

- O app deve exibir alerta visual.
- O campo `alertaEmitido` deve ser atualizado para `true`.

---

## CT-016 - Criar conta de rede de apoio e copiar código

| Campo | Descrição |
|---|---|
| Módulo | Rede de apoio |
| Objetivo | Validar geração e exibição do código de vínculo |
| Pré-condição | App instalado |
| Status | Pendente |

### Passos

1. Criar uma conta como Cuidador ou Rede de apoio.
2. Aguardar abertura da tela de Aguardando vínculo.
3. Copiar o código exibido.

### Resultado esperado

- A tela deve exibir o código de vínculo.
- O usuário deve permanecer aguardando aprovação.

---

## CT-017 - Vincular cuidador à criança

| Campo | Descrição |
|---|---|
| Módulo | Rede de apoio |
| Objetivo | Validar vínculo de cuidador por código |
| Pré-condição | Existir conta de cuidador aguardando vínculo e conta responsável ativa |
| Status | Pendente |

### Passos

1. Fazer login com responsável.
2. Acessar Rede de apoio.
3. Clicar em Adicionar.
4. Informar o código do cuidador.
5. Selecionar parentesco/função.
6. Salvar.

### Resultado esperado

- Deve ser criado um documento em `child_links`.
- O cuidador deve aparecer na lista de rede de apoio.
- O usuário cuidador deve ter `statusVinculo` atualizado para `ativo`.
- O usuário cuidador deve receber `childIdAtual`.

---

## CT-018 - Login com cuidador vinculado

| Campo | Descrição |
|---|---|
| Módulo | Rede de apoio |
| Objetivo | Validar acesso do cuidador após aprovação |
| Pré-condição | Cuidador vinculado à criança |
| Status | Pendente |

### Passos

1. Sair da conta responsável.
2. Fazer login com a conta do cuidador.
3. Aguardar redirecionamento.

### Resultado esperado

- O cuidador deve sair da tela de Aguardando vínculo.
- O app deve abrir a Home.
- O cuidador deve conseguir acessar dados da criança ativa conforme permitido pela POC.

---

## CT-019 - Remover pessoa da rede de apoio

| Campo | Descrição |
|---|---|
| Módulo | Rede de apoio |
| Objetivo | Validar remoção de cuidador ou rede de apoio |
| Pré-condição | Existir pessoa vinculada na rede de apoio |
| Status | Pendente |

### Passos

1. Fazer login com responsável.
2. Acessar Rede de apoio.
3. Selecionar pessoa vinculada.
4. Clicar em Remover.
5. Confirmar remoção.

### Resultado esperado

- O vínculo deve ser atualizado para `removido`.
- A pessoa não deve aparecer mais na lista.
- O usuário removido deve voltar para `aguardando_vinculo` se aquela era sua criança ativa.

---

## CT-020 - Visualizar Minha conta

| Campo | Descrição |
|---|---|
| Módulo | Minha conta |
| Objetivo | Validar exibição dos dados do usuário |
| Pré-condição | Usuário logado |
| Status | Pendente |

### Passos

1. Acessar Home.
2. Clicar no ícone de perfil no topo.
3. Visualizar os dados da conta.

### Resultado esperado

- A tela deve exibir nome, e-mail, perfil, status, código de vínculo e criança ativa.
- A tela não deve apresentar erro visual.

---

## CT-021 - Editar nome em Minha conta

| Campo | Descrição |
|---|---|
| Módulo | Minha conta |
| Objetivo | Validar edição do nome do usuário |
| Pré-condição | Usuário logado |
| Status | Pendente |

### Passos

1. Acessar Minha conta.
2. Editar o campo Nome.
3. Clicar em Salvar nome.

### Resultado esperado

- O nome deve ser atualizado no Firebase Authentication.
- O nome deve ser atualizado no documento do usuário em `users`.
- O app deve exibir mensagem de sucesso.

---

## CT-022 - Enviar redefinição de senha pela Minha conta

| Campo | Descrição |
|---|---|
| Módulo | Minha conta |
| Objetivo | Validar envio de e-mail de redefinição |
| Pré-condição | Usuário logado com e-mail válido |
| Status | Pendente |

### Passos

1. Acessar Minha conta.
2. Clicar em Enviar redefinição de senha.

### Resultado esperado

- O Firebase deve enviar e-mail de redefinição.
- O app deve exibir mensagem de sucesso.

---

## CT-023 - Sair da conta pela Minha conta

| Campo | Descrição |
|---|---|
| Módulo | Minha conta |
| Objetivo | Validar logout |
| Pré-condição | Usuário logado |
| Status | Pendente |

### Passos

1. Acessar Minha conta.
2. Clicar em Sair da conta.
3. Confirmar saída.

### Resultado esperado

- O usuário deve ser deslogado.
- O app deve voltar para a tela inicial ou login.

---

## CT-024 - Listar crianças vinculadas

| Campo | Descrição |
|---|---|
| Módulo | Crianças vinculadas |
| Objetivo | Validar listagem de crianças associadas ao usuário |
| Pré-condição | Usuário com pelo menos uma criança vinculada |
| Status | Pendente |

### Passos

1. Acessar Home.
2. Clicar em Crianças vinculadas.

### Resultado esperado

- A tela deve listar as crianças vinculadas ao usuário.
- A criança ativa deve aparecer marcada.
- O botão de cadastrar deve aparecer para Pai, Mãe ou Responsável principal.

---

## CT-025 - Trocar criança ativa

| Campo | Descrição |
|---|---|
| Módulo | Crianças vinculadas |
| Objetivo | Validar troca da criança ativa |
| Pré-condição | Usuário com mais de uma criança vinculada |
| Status | Pendente |

### Passos

1. Acessar Crianças vinculadas.
2. Selecionar outra criança.
3. Clicar em Usar.

### Resultado esperado

- O campo `childIdAtual` do usuário deve ser atualizado.
- As telas de agenda, comportamento, crise, informações e relatórios devem usar a nova criança ativa.

---

## CT-026 - Visualizar resumo e relatórios

| Campo | Descrição |
|---|---|
| Módulo | Resumo e relatórios |
| Objetivo | Validar exibição dos indicadores principais |
| Pré-condição | Usuário ativo com criança ativa |
| Status | Pendente |

### Passos

1. Acessar Home.
2. Clicar em Resumo e relatórios.

### Resultado esperado

- A tela deve exibir:
  - Crises hoje.
  - Crises na semana.
  - Agenda hoje.
  - Observações positivas.
  - Total de registros.
  - Gatilho mais frequente.
  - Últimos registros.
- A tela não deve apresentar erro visual.

---

## CT-027 - Atualizar resumo e relatórios

| Campo | Descrição |
|---|---|
| Módulo | Resumo e relatórios |
| Objetivo | Validar atualização manual dos indicadores |
| Pré-condição | Usuário ativo com criança ativa |
| Status | Pendente |

### Passos

1. Acessar Resumo e relatórios.
2. Clicar no ícone de atualizar.

### Resultado esperado

- Os indicadores devem ser recarregados.
- O app não deve apresentar erro visual.

---

## CT-028 - Validar persistência de sessão

| Campo | Descrição |
|---|---|
| Módulo | Autenticação |
| Objetivo | Validar permanência do login após fechar e abrir app |
| Pré-condição | Usuário logado |
| Status | Pendente |

### Passos

1. Fazer login.
2. Fechar o aplicativo.
3. Abrir o aplicativo novamente.

### Resultado esperado

- O usuário deve continuar autenticado.
- O app deve redirecionar para a tela correta de acordo com o status do usuário.

---

## CT-029 - Validar erro de login

| Campo | Descrição |
|---|---|
| Módulo | Login |
| Objetivo | Validar tratamento de credenciais inválidas |
| Pré-condição | App instalado |
| Status | Pendente |

### Passos

1. Acessar Login.
2. Informar e-mail ou senha incorretos.
3. Clicar em entrar.

### Resultado esperado

- O app deve exibir mensagem de erro amigável.
- O app não deve travar.

---

## CT-030 - Validar usuário sem criança ativa

| Campo | Descrição |
|---|---|
| Módulo | Fluxo geral |
| Objetivo | Validar comportamento quando não há criança ativa |
| Pré-condição | Usuário sem `childIdAtual` |
| Status | Pendente |

### Passos

1. Fazer login com usuário sem criança ativa.
2. Acessar telas que dependem de criança ativa.

### Resultado esperado

- O app deve exibir mensagem informando que não há criança ativa.
- O app não deve apresentar tela vermelha.
- O app deve orientar o usuário a cadastrar ou selecionar uma criança.

---

---

## CT-031 - Validar ocultação da Rede de apoio para Cuidador

| Campo | Descrição |
|---|---|
| Módulo | Home / Permissões |
| Objetivo | Validar que o card Rede de apoio não aparece para usuários com perfil Cuidador |
| Pré-condição | Usuário Cuidador cadastrado, vinculado e com acesso ativo à Home |
| Status | Aprovado |

### Passos

1. Fazer login com uma conta de Cuidador.
2. Aguardar abertura da Home.
3. Verificar os cards exibidos na tela inicial.

### Resultado esperado

- A Home deve ser exibida normalmente.
- O card "Rede de apoio" não deve aparecer para o perfil Cuidador.
- Os demais módulos permitidos na POC devem continuar aparecendo.

### Observação

A tela Rede de apoio deve ficar disponível apenas para usuários com perfil Pai, Mãe ou Responsável principal.

## 6. Checklist final da rodada de testes

| Item | Status |
|---|---|
| Cadastro de responsável testado | Pendente |
| Cadastro de cuidador testado | Pendente |
| Login testado | Pendente |
| Cadastro de criança testado | Pendente |
| Agenda testada | Pendente |
| Comportamento testado | Pendente |
| Modo crise testado | Pendente |
| Rede de apoio testada | Pendente |
| Informações da criança testada | Pendente |
| Minha conta testada | Pendente |
| Crianças vinculadas testada | Pendente |
| Resumo e relatórios testado | Pendente |
| Logout testado | Pendente |
| Persistência de sessão testada | Pendente |
| Fluxos com erro testados | Pendente |

---

## 7. Observações encontradas durante os testes

Use esta seção para registrar problemas encontrados.

### Problema 1

| Campo | Descrição |
|---|---|
| Data |  |
| Caso de teste |  |
| Tela |  |
| Descrição do problema |  |
| Evidência |  |
| Status |  |

### Problema 2

| Campo | Descrição |
|---|---|
| Data |  |
| Caso de teste |  |
| Tela |  |
| Descrição do problema |  |
| Evidência |  |
| Status |  |