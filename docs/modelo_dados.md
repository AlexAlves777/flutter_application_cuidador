# Modelo de Dados - Aplicativo Cuidador

## 1. Objetivo

Este documento descreve o modelo de dados utilizado na POC do Aplicativo Cuidador.

O sistema utiliza Firebase Authentication para autenticação e Cloud Firestore como banco de dados NoSQL.

---

## 2. Visão geral

As principais coleções utilizadas são:

```txt
users
children
child_links
```

Além disso, cada criança possui subcoleções:

```txt
children/{childId}/agenda_items
children/{childId}/behavior_records
```

---

## 3. Coleção `users`

A coleção `users` armazena os dados principais dos usuários cadastrados.

### Caminho

```txt
users/{uid}
```

### Campos

| Campo | Tipo | Descrição |
|---|---|---|
| `uid` | String | Identificador do usuário no Firebase Auth |
| `nome` | String | Nome do usuário |
| `email` | String | E-mail do usuário |
| `perfil` | String | Perfil selecionado no cadastro |
| `codigoVinculo` | String | Código usado para vínculo com responsável |
| `statusVinculo` | String | Status atual do usuário |
| `childIdAtual` | String ou null | Criança ativa selecionada pelo usuário |
| `papelAtual` | String | Papel atual do usuário no vínculo |
| `parentescoAtual` | String | Parentesco ou função atual |
| `aprovadoPor` | String | UID do usuário que aprovou o vínculo |
| `criadoEm` | Timestamp | Data de criação |
| `atualizadoEm` | Timestamp | Data da última atualização |

### Status possíveis

| Status | Significado |
|---|---|
| `precisa_definir_crianca` | Usuário responsável ainda precisa cadastrar ou vincular criança |
| `aguardando_vinculo` | Usuário aguarda aprovação de vínculo |
| `ativo` | Usuário liberado para acessar a Home |

---

## 4. Coleção `children`

A coleção `children` armazena os dados das crianças cadastradas.

### Caminho

```txt
children/{childId}
```

### Campos

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | String | Identificador da criança |
| `nome` | String | Nome da criança |
| `dataNascimento` | Timestamp | Data de nascimento |
| `nivelSuporte` | String | Nível de suporte informado |
| `observacoes` | String | Observações gerais |
| `responsavelPrincipalId` | String | UID do responsável que cadastrou |
| `tempoAlertaCriseMinutos` | Number | Tempo para alerta no modo crise |
| `preferenciasAmbienteCalmante` | String | Preferências para acalmar |
| `alergias` | String | Alergias conhecidas |
| `sensibilidades` | String | Sensibilidades sensoriais |
| `criadoEm` | Timestamp | Data de criação |
| `atualizadoEm` | Timestamp | Data da última atualização |

---

## 5. Coleção `child_links`

A coleção `child_links` representa o vínculo entre usuários e crianças.

### Caminho

```txt
child_links/{linkId}
```

### Campos

| Campo | Tipo | Descrição |
|---|---|---|
| `childId` | String | ID da criança vinculada |
| `userId` | String | ID do usuário vinculado |
| `nomeUsuario` | String | Nome do usuário vinculado |
| `emailUsuario` | String | E-mail do usuário vinculado |
| `papel` | String | Papel do usuário no vínculo |
| `parentesco` | String | Parentesco ou função |
| `status` | String | Status do vínculo |
| `criadoPor` | String | UID de quem criou o vínculo |
| `aprovadoPor` | String | UID de quem aprovou |
| `removidoPor` | String | UID de quem removeu |
| `criadoEm` | Timestamp | Data de criação |
| `aprovadoEm` | Timestamp | Data de aprovação |
| `removidoEm` | Timestamp | Data de remoção |
| `atualizadoEm` | Timestamp | Data da última atualização |

### Status possíveis

| Status | Significado |
|---|---|
| `aprovado` | Vínculo ativo |
| `pendente` | Vínculo aguardando aprovação |
| `rejeitado` | Vínculo rejeitado |
| `removido` | Vínculo removido |

### Papéis possíveis

| Papel | Descrição |
|---|---|
| `pai` | Pai da criança |
| `mae` | Mãe da criança |
| `responsavel_principal` | Responsável principal |
| `cuidador` | Cuidador autorizado |
| `rede_apoio` | Pessoa da rede de apoio |

---

## 6. Subcoleção `agenda_items`

A subcoleção `agenda_items` armazena as atividades da agenda diária da criança.

### Caminho

```txt
children/{childId}/agenda_items/{itemId}
```

### Campos

| Campo | Tipo | Descrição |
|---|---|---|
| `titulo` | String | Título da atividade |
| `tipo` | String | Tipo da atividade |
| `observacoes` | String | Observações sobre a atividade |
| `data` | Timestamp | Data da atividade |
| `dataKey` | String | Data em formato `yyyy-MM-dd` |
| `horario` | String | Horário formatado |
| `horarioMinutos` | Number | Horário convertido em minutos |
| `concluida` | Boolean | Indica se a atividade foi concluída |
| `childId` | String | ID da criança |
| `criadoPor` | String | UID do usuário criador |
| `criadoEm` | Timestamp | Data de criação |
| `atualizadoEm` | Timestamp | Data da última atualização |

---

## 7. Subcoleção `behavior_records`

A subcoleção `behavior_records` armazena registros de comportamento, observações e crises.

### Caminho

```txt
children/{childId}/behavior_records/{recordId}
```

### Campos

| Campo | Tipo | Descrição |
|---|---|---|
| `titulo` | String | Título ou resumo do registro |
| `tipo` | String | Tipo do registro |
| `intensidade` | Number | Intensidade percebida |
| `gatilho` | String | Possível gatilho observado |
| `estrategia` | String | Estratégia utilizada |
| `observacoes` | String | Observações gerais |
| `statusCrise` | String ou null | Status da crise |
| `origemRegistro` | String | Origem do registro |
| `inicioCrise` | Timestamp ou null | Início da crise |
| `fimCrise` | Timestamp ou null | Fim da crise |
| `duracaoSegundos` | Number ou null | Duração da crise |
| `tempoAlertaMinutos` | Number | Tempo configurado para alerta |
| `alertaEmitido` | Boolean | Indica se alerta foi emitido |
| `alertaEmitidoEm` | Timestamp ou null | Momento em que alerta foi emitido |
| `ambienteCalmanteAtivo` | Boolean | Indica se ambiente calmante foi ativado |
| `data` | Timestamp | Data do registro |
| `dataKey` | String | Data em formato `yyyy-MM-dd` |
| `horario` | String | Horário formatado |
| `horarioMinutos` | Number | Horário em minutos |
| `childId` | String | ID da criança |
| `criadoPor` | String | UID do usuário criador |
| `criadoEm` | Timestamp | Data de criação |
| `atualizadoEm` | Timestamp | Data da última atualização |

### Tipos de registro

| Tipo | Descrição |
|---|---|
| `Crise` | Registro de crise |
| `Observação positiva` | Registro positivo |
| `Alimentação` | Registro relacionado à alimentação |
| `Sono` | Registro relacionado ao sono |
| `Sensorial` | Registro relacionado a estímulos sensoriais |
| `Comunicação` | Registro relacionado à comunicação |
| `Socialização` | Registro relacionado à interação social |
| `Outro` | Registro genérico |

### Status de crise

| Status | Descrição |
|---|---|
| `em_andamento` | Crise em andamento |
| `resolvida` | Crise encerrada |
| `registrada` | Crise registrada manualmente |

---

## 8. Relacionamentos principais

### Usuário e criança

Um usuário pode estar vinculado a uma ou mais crianças por meio da coleção `child_links`.

```txt
users/{uid}
child_links/{linkId}
children/{childId}
```

### Criança e agenda

Uma criança possui vários itens de agenda.

```txt
children/{childId}/agenda_items/{itemId}
```

### Criança e comportamento

Uma criança possui vários registros de comportamento.

```txt
children/{childId}/behavior_records/{recordId}
```

---

## 9. Criança ativa

O campo `childIdAtual` no documento do usuário define qual criança está ativa no momento.

Esse campo é usado pelas telas:

- Agenda diária.
- Comportamento e crises.
- Modo crise.
- Informações da criança.
- Rede de apoio.
- Resumo e relatórios.

---

## 10. Observações

O modelo atual atende à POC.

Para produção, recomenda-se:

- Melhorar regras de segurança.
- Validar permissões por perfil.
- Usar índices adequados no Firestore.
- Avaliar Cloud Functions para processos críticos.
- Implementar logs/auditoria para alterações sensíveis.