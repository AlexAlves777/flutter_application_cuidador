# Regras de Negócio - Aplicativo Cuidador

## 1. Objetivo

Este documento descreve as principais regras de negócio da POC do Aplicativo Cuidador.

As regras de negócio definem como o sistema deve se comportar em cada fluxo, como cadastro, vínculo, criança ativa, agenda, comportamento, crise e rede de apoio.

---

## 2. Perfis de usuário

O aplicativo possui os seguintes perfis:

| Perfil | Descrição |
|---|---|
| Pai | Responsável familiar pela criança |
| Mãe | Responsável familiar pela criança |
| Responsável principal | Usuário principal responsável pelo cadastro e gestão da criança |
| Cuidador | Pessoa autorizada a apoiar os cuidados da criança |
| Rede de apoio | Familiar ou pessoa próxima autorizada a acompanhar informações da criança |

---

## 3. Cadastro de usuário

### RN-001 - Todo usuário deve criar uma conta

Para acessar o aplicativo, o usuário deve informar:

- Nome.
- E-mail.
- Senha.
- Perfil.

---

### RN-002 - O usuário deve ser criado no Firebase Authentication

Ao finalizar o cadastro, o sistema deve criar o usuário no Firebase Authentication.

---

### RN-003 - O usuário deve ser criado no Firestore

Após criar o usuário no Firebase Authentication, o sistema deve criar um documento na coleção:

```txt
users
```

Esse documento deve armazenar os dados principais do usuário.

---

## 4. Cadastro de Pai, Mãe ou Responsável principal

### RN-004 - Responsáveis devem informar se já existe criança cadastrada

Quando o usuário escolher o perfil Pai, Mãe ou Responsável principal, o sistema deve perguntar se a criança já está cadastrada.

---

### RN-005 - Se a criança não estiver cadastrada

Se o usuário informar que a criança ainda não está cadastrada, o sistema deve direcioná-lo para a tela de cadastro da criança.

Após cadastrar a criança, o usuário deve ir para a Home.

---

### RN-006 - Se a criança já estiver cadastrada

Se o usuário informar que a criança já está cadastrada, o sistema deve direcioná-lo para a tela de Aguardando vínculo.

---

## 5. Cadastro de Cuidador ou Rede de apoio

### RN-007 - Cuidador e Rede de apoio não entram direto na Home

Usuários com perfil Cuidador ou Rede de apoio devem ir para a tela de Aguardando vínculo após o cadastro.

---

### RN-008 - Todo usuário deve ter um código de vínculo

O sistema deve gerar ou armazenar um código de vínculo para cada usuário.

Esse código será usado pelo responsável para adicionar o usuário à rede de apoio da criança.

---

### RN-009 - Status inicial de Cuidador e Rede de apoio

O status inicial de Cuidador e Rede de apoio deve ser:

```txt
aguardando_vinculo
```

---

## 6. Cadastro da criança

### RN-010 - O responsável pode cadastrar uma criança

O responsável pode cadastrar uma criança informando:

- Nome.
- Data de nascimento.
- Nível de suporte.
- Observações.

---

### RN-011 - Ao cadastrar uma criança, o sistema deve criar o vínculo inicial

Quando uma criança for cadastrada, o sistema deve criar um vínculo aprovado entre o responsável e a criança.

Esse vínculo deve ser salvo na coleção:

```txt
child_links
```

---

### RN-012 - Após cadastrar a criança, o responsável deve ficar ativo

Após o cadastro da criança, o sistema deve atualizar o usuário responsável com:

```txt
statusVinculo = ativo
childIdAtual = ID da criança cadastrada
```

---

## 7. Criança ativa

### RN-013 - O sistema deve usar uma criança ativa

O aplicativo trabalha com o conceito de criança ativa.

A criança ativa é definida no campo:

```txt
users/{uid}.childIdAtual
```

---

### RN-014 - As telas principais dependem da criança ativa

As seguintes telas dependem da criança ativa:

- Informações da criança.
- Agenda diária.
- Comportamento e crises.
- Modo crise.
- Rede de apoio.
- Resumo e relatórios.

---

### RN-015 - O usuário pode trocar a criança ativa

Na tela Crianças vinculadas, o usuário pode selecionar outra criança como ativa.

---

## 8. Rede de apoio

### RN-016 - O responsável pode adicionar pessoas por código

O responsável pode adicionar um cuidador ou pessoa da rede de apoio usando o código de vínculo dessa pessoa.

---

### RN-017 - O usuário não pode vincular a si mesmo

O sistema não deve permitir que o usuário adicione o próprio código de vínculo.

---

### RN-018 - O mesmo usuário não pode ser vinculado duas vezes à mesma criança

O sistema não deve permitir vínculo duplicado ativo entre o mesmo usuário e a mesma criança.

---

### RN-019 - Na POC, o vínculo é aprovado automaticamente

Na versão atual da POC, quando o responsável adiciona uma pessoa por código, o vínculo já é criado como aprovado.

---

### RN-020 - O responsável pode remover uma pessoa da rede de apoio

Ao remover uma pessoa da rede de apoio:

- O vínculo deve receber status `removido`.
- A pessoa deve deixar de aparecer na lista.
- Se aquela criança era a criança ativa da pessoa removida, o campo `childIdAtual` deve ser removido.

---

## 9. Agenda diária

### RN-021 - O usuário pode criar atividades

O usuário pode criar atividades para a criança ativa.

As atividades são salvas em:

```txt
children/{childId}/agenda_items
```

---

### RN-022 - O usuário pode marcar atividades como concluídas

O usuário pode marcar uma atividade da agenda como concluída.

---

### RN-023 - O usuário pode excluir atividades

O usuário pode excluir atividades cadastradas na agenda.

---

## 10. Comportamento e crises

### RN-024 - O usuário pode registrar comportamentos

O usuário pode registrar comportamentos da criança ativa.

Os registros são salvos em:

```txt
children/{childId}/behavior_records
```

---

### RN-025 - O sistema deve permitir tipos diferentes de registro

Os tipos disponíveis são:

- Crise.
- Observação positiva.
- Alimentação.
- Sono.
- Sensorial.
- Comunicação.
- Socialização.
- Outro.

---

### RN-026 - O usuário pode filtrar registros

O usuário pode filtrar os registros por tipo.

---

## 11. Modo crise

### RN-027 - O usuário pode iniciar uma crise

Ao iniciar uma crise, o sistema deve criar um registro com:

```txt
tipo = Crise
statusCrise = em_andamento
origemRegistro = botao_crise
```

---

### RN-028 - O sistema deve exibir um cronômetro

Enquanto a crise estiver em andamento, o sistema deve exibir um cronômetro.

---

### RN-029 - O sistema deve emitir alerta visual

Se a crise ultrapassar o tempo configurado no campo:

```txt
tempoAlertaCriseMinutos
```

o sistema deve exibir um alerta visual.

---

### RN-030 - O usuário pode encerrar uma crise

Ao encerrar uma crise, o usuário deve informar:

- Intensidade.
- Gatilho.
- Estratégia usada.
- Observações finais.

O sistema deve atualizar o registro com:

```txt
statusCrise = resolvida
fimCrise
duracaoSegundos
```

---

## 12. Informações da criança

### RN-031 - O usuário pode editar dados da criança ativa

O usuário pode editar:

- Nome.
- Data de nascimento.
- Nível de suporte.
- Tempo de alerta de crise.
- Alergias.
- Sensibilidades.
- Preferências para acalmar.
- Observações gerais.

---

### RN-032 - O tempo de alerta deve ser usado no Modo crise

O campo `tempoAlertaCriseMinutos` deve ser usado pelo Modo crise para definir quando o alerta visual será exibido.

---

## 13. Minha conta

### RN-033 - O usuário pode visualizar os dados da conta

Na tela Minha conta, o usuário pode visualizar:

- Nome.
- E-mail.
- Perfil.
- Status do vínculo.
- Código de vínculo.
- Criança ativa.

---

### RN-034 - O usuário pode editar o nome

O usuário pode alterar o próprio nome.

---

### RN-035 - O usuário pode solicitar redefinição de senha

O sistema deve permitir o envio de e-mail de redefinição de senha.

---

### RN-036 - O usuário pode sair da conta

O usuário pode fazer logout pela tela Minha conta.

---

## 14. Resumo e relatórios

### RN-037 - Os relatórios devem considerar a criança ativa

A tela Resumo e relatórios deve exibir dados apenas da criança ativa.

---

### RN-038 - O resumo deve exibir indicadores principais

A tela deve mostrar:

- Crises hoje.
- Crises na semana.
- Agenda concluída hoje.
- Observações positivas.
- Total de registros.
- Gatilho mais frequente.
- Últimos registros.

---

## 15. Segurança na POC

### RN-039 - Usuário precisa estar autenticado

Para acessar os dados do aplicativo, o usuário deve estar autenticado.

---

### RN-040 - Regras de segurança serão melhoradas em produção

Na POC, as regras do Firestore são mais permissivas para facilitar os testes.

Em uma versão de produção, o sistema deve validar:

- Se o usuário está vinculado à criança.
- Se o vínculo está aprovado.
- Se o perfil permite aquela ação.
- Se o usuário pode editar ou apenas visualizar dados.

---

## 16. Observações finais

As regras deste documento representam o comportamento esperado da POC.

Algumas regras foram simplificadas para facilitar o desenvolvimento e a validação do conceito.