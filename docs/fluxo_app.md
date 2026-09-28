# Fluxo Macro do Aplicativo Cuidador

## 1. Objetivo do documento

Este documento descreve o fluxo macro de navegação e funcionamento da POC do Aplicativo Cuidador.

O objetivo é apresentar, de forma organizada, como o usuário acessa o sistema, cadastra a criança, utiliza os módulos principais e gerencia a rede de apoio.

---

## 2. Visão geral do aplicativo

O Aplicativo Cuidador é uma solução mobile voltada ao apoio da rotina de famílias com crianças que necessitam de acompanhamento, organização de atividades, registro de comportamento, registro de crises e participação de uma rede de apoio.

A POC contempla os seguintes módulos:

- Autenticação.
- Cadastro de criança.
- Seleção de criança ativa.
- Agenda diária.
- Registro de comportamento e crises.
- Modo crise.
- Rede de apoio.
- Informações da criança.
- Minha conta.
- Resumo e relatórios.

---

## 3. Perfis de usuário

O sistema considera os seguintes perfis:

| Perfil | Descrição |
|---|---|
| Pai | Responsável familiar pela criança |
| Mãe | Responsável familiar pela criança |
| Responsável principal | Usuário principal responsável pelo cadastro e gestão da criança |
| Cuidador | Pessoa vinculada para apoiar os cuidados da criança |
| Rede de apoio | Familiar ou pessoa próxima autorizada a acompanhar informações da criança |

---

## 4. Fluxo inicial de acesso

Ao abrir o aplicativo, o usuário pode:

- Entrar com uma conta existente.
- Criar uma nova conta.

O sistema utiliza Firebase Authentication para login e cadastro de usuários.

---

## 5. Fluxo de cadastro de usuário

### 5.1 Cadastro de Pai, Mãe ou Responsável principal

1. O usuário informa nome, e-mail, senha e perfil.
2. O sistema cria a conta no Firebase Authentication.
3. O sistema cria o documento do usuário na coleção `users`.
4. O app pergunta se a criança já está cadastrada.

### Possibilidades

| Resposta | Fluxo |
|---|---|
| Sim, já existe criança cadastrada | Usuário vai para tela de Aguardando vínculo |
| Não, quero cadastrar agora | Usuário vai para tela de Cadastro da criança |

---

### 5.2 Cadastro de Cuidador ou Rede de apoio

1. O usuário informa nome, e-mail, senha e perfil.
2. O sistema cria a conta no Firebase Authentication.
3. O sistema cria o documento do usuário na coleção `users`.
4. O campo `statusVinculo` é definido como `aguardando_vinculo`.
5. O app direciona o usuário para a tela de Aguardando vínculo.
6. O usuário visualiza seu código de vínculo.

---

## 6. Fluxo de cadastro da criança

Quando o responsável informa que ainda não existe uma criança cadastrada, ele acessa a tela de Cadastro da criança.

### Dados cadastrados

- Nome.
- Data de nascimento.
- Nível de suporte.
- Observações.

### Após salvar

O sistema:

1. Cria um documento na coleção `children`.
2. Cria um vínculo aprovado na coleção `child_links`.
3. Atualiza o documento do usuário com:
   - `statusVinculo: ativo`.
   - `childIdAtual`.
4. Redireciona o usuário para a Home.

---

## 7. Fluxo de login

Ao realizar login, o sistema verifica o status do usuário.

| Status | Destino |
|---|---|
| `ativo` | Home |
| `precisa_definir_crianca` | Pergunta sobre criança cadastrada |
| `aguardando_vinculo` | Tela de Aguardando vínculo |

---

## 8. Tela de Aguardando vínculo

Essa tela é exibida quando o usuário ainda não possui acesso ativo a uma criança.

Ela pode aparecer para:

- Cuidador.
- Rede de apoio.
- Responsável que informou que a criança já existe, mas ainda não foi vinculado.

### Informações exibidas

- Mensagem informando que a conta aguarda aprovação.
- Código de vínculo do usuário.
- Orientação para enviar o código ao responsável.
- Opção de sair da conta.

---

## 9. Home

A Home é a tela principal do aplicativo.

Ela apresenta acesso aos principais módulos:

- Registrar crise agora.
- Resumo e relatórios.
- Crianças vinculadas.
- Informações da criança.
- Agenda diária.
- Comportamento e crises.
- Rede de apoio.
- Minha conta.

A Home deve aparecer apenas quando o usuário estiver com acesso ativo.

---

## 10. Fluxo de criança ativa

O sistema trabalha com o conceito de criança ativa por meio do campo:

```txt
users/{uid}.childIdAtual
```

Esse campo indica qual criança será usada nos módulos principais.

### Módulos que dependem da criança ativa

- Informações da criança.
- Agenda diária.
- Comportamento e crises.
- Modo crise.
- Rede de apoio.
- Resumo e relatórios.

Se não houver criança ativa, as telas devem exibir uma mensagem orientando o usuário a cadastrar ou selecionar uma criança.

---

## 11. Tela Crianças vinculadas

A tela Crianças vinculadas permite:

- Visualizar crianças associadas ao usuário.
- Identificar a criança ativa.
- Trocar a criança ativa.
- Cadastrar outra criança, quando o perfil permitir.

### Perfis que podem cadastrar nova criança

- Pai.
- Mãe.
- Responsável principal.

### Fluxo de troca de criança ativa

1. O usuário acessa a tela Crianças vinculadas.
2. O sistema lista as crianças associadas ao usuário.
3. O usuário seleciona uma criança.
4. O sistema atualiza o campo `childIdAtual` no documento do usuário.
5. Os módulos passam a usar a nova criança ativa.

---

## 12. Tela Informações da criança

Essa tela permite visualizar e editar dados importantes da criança ativa.

### Dados editáveis

- Nome.
- Data de nascimento.
- Nível de suporte.
- Tempo de alerta de crise.
- Alergias.
- Sensibilidades.
- Preferências para acalmar.
- Observações gerais.

O campo `tempoAlertaCriseMinutos` é utilizado pelo Modo crise para emitir alerta visual quando a crise ultrapassa o tempo configurado.

---

## 13. Agenda diária

A tela Agenda diária permite gerenciar atividades da criança ativa.

### Funcionalidades

- Criar atividade.
- Definir tipo.
- Definir horário.
- Inserir observações.
- Marcar atividade como concluída.
- Excluir atividade.

Os dados são salvos em:

```txt
children/{childId}/agenda_items/{itemId}
```

---

## 14. Comportamento e crises

A tela Comportamento e crises permite registrar eventos observados no dia a dia.

### Tipos de registro

- Crise.
- Observação positiva.
- Alimentação.
- Sono.
- Sensorial.
- Comunicação.
- Socialização.
- Outro.

### Funcionalidades

- Criar registro.
- Informar intensidade.
- Informar gatilho.
- Informar estratégia usada.
- Inserir observações.
- Filtrar registros por tipo.
- Excluir registro.

Os dados são salvos em:

```txt
children/{childId}/behavior_records/{recordId}
```

---

## 15. Modo crise

O Modo crise é um fluxo rápido para registrar uma crise em andamento.

### Início da crise

Ao iniciar uma crise, o sistema cria um registro com:

- Tipo: `Crise`.
- Status: `em_andamento`.
- Início da crise.
- Tempo de alerta configurado.
- Criança ativa.
- Usuário que criou o registro.

### Durante a crise

A tela exibe:

- Cronômetro.
- Ambiente calmante.
- Alerta visual quando o tempo configurado é ultrapassado.

### Encerramento da crise

Ao encerrar a crise, o usuário informa:

- Intensidade.
- Gatilho.
- Estratégia usada.
- Observações finais.

O registro é atualizado com:

- Status: `resolvida`.
- Fim da crise.
- Duração em segundos.
- Dados finais preenchidos.

---

## 16. Rede de apoio

A tela Rede de apoio permite ao responsável gerenciar pessoas vinculadas à criança ativa.

### Funcionalidades

- Listar pessoas vinculadas.
- Adicionar pessoa por código de vínculo.
- Definir parentesco ou função.
- Remover pessoa da rede de apoio.

### Fluxo de vínculo

1. Cuidador ou rede de apoio cria conta.
2. O app exibe o código de vínculo.
3. O responsável acessa Rede de apoio.
4. O responsável informa o código.
5. O sistema cria vínculo aprovado em `child_links`.
6. O sistema atualiza o usuário vinculado com `statusVinculo: ativo` e `childIdAtual`.

---

## 17. Minha conta

A tela Minha conta permite ao usuário visualizar e gerenciar seus dados.

### Funcionalidades

- Visualizar nome.
- Editar nome.
- Visualizar e-mail.
- Visualizar perfil.
- Visualizar status do vínculo.
- Visualizar código de vínculo.
- Visualizar criança ativa.
- Enviar e-mail de redefinição de senha.
- Sair da conta.

O botão de sair da conta fica centralizado nessa tela para evitar ações duplicadas na Home.

---

## 18. Resumo e relatórios

A tela Resumo e relatórios apresenta indicadores da criança ativa.

### Indicadores exibidos

- Crises registradas hoje.
- Crises na semana.
- Atividades concluídas hoje.
- Observações positivas na semana.
- Total de registros na semana.
- Gatilho mais frequente.
- Últimos registros de comportamento.

O objetivo é apoiar responsáveis e cuidadores na identificação de padrões da rotina e comportamento.

---

## 19. Fluxo resumido

```txt
Abertura do app
→ Login ou Cadastro
→ Verificação do status do usuário
→ Cadastro de criança ou Aguardando vínculo ou Home
→ Seleção da criança ativa
→ Uso dos módulos principais
→ Registro e acompanhamento da rotina
```

---

## 20. Fluxo resumido por perfil

### Pai, Mãe ou Responsável principal

```txt
Cadastro
→ Pergunta se criança já existe
→ Cadastro da criança ou Aguardando vínculo
→ Home
→ Gerenciamento dos módulos
```

### Cuidador ou Rede de apoio

```txt
Cadastro
→ Aguardando vínculo
→ Responsável adiciona por código
→ Home
→ Acesso aos módulos permitidos na POC
```

---

## 21. Observações

A POC prioriza o fluxo funcional e a integração com Firebase.

Alguns recursos podem ser evoluídos em versões futuras, como:

- Notificações push.
- Permissões mais rígidas por perfil.
- Relatórios gráficos.
- Integração com profissionais de saúde.
- Testes automatizados.