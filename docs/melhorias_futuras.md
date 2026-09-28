# Melhorias Futuras - Aplicativo Cuidador

## 1. Objetivo

Este documento descreve melhorias futuras para o Aplicativo Cuidador.

A POC implementa os principais fluxos funcionais, mas algumas funcionalidades podem ser evoluídas em versões futuras para aumentar segurança, usabilidade, acessibilidade e valor prático para famílias e cuidadores.

---

## 2. Segurança e permissões

### 2.1 Regras avançadas no Firestore

Atualmente, as regras de segurança da POC são mais permissivas para facilitar o desenvolvimento e os testes.

Em uma versão de produção, as rules devem validar:

- Se o usuário está autenticado.
- Se o usuário possui vínculo aprovado com a criança.
- Se o papel do usuário permite leitura.
- Se o papel do usuário permite escrita.
- Se o usuário pode gerenciar rede de apoio.
- Se o usuário pode editar informações sensíveis da criança.

---

### 2.2 Controle por perfil

Implementar permissões diferentes para cada perfil:

| Perfil | Permissões futuras |
|---|---|
| Pai/Mãe/Responsável | Gerenciar criança, rede de apoio, agenda, registros e configurações |
| Cuidador | Registrar rotina, comportamento e crises |
| Rede de apoio | Visualizar informações autorizadas e registrar apoio |
| Criança | Acesso simplificado para pedir ajuda, se aplicável |

---

### 2.3 Auditoria

Registrar eventos importantes, como:

- Alteração de dados da criança.
- Inclusão de pessoa na rede de apoio.
- Remoção de vínculo.
- Alteração de tempo de alerta de crise.
- Encerramento de crise.

---

## 3. Notificações

### 3.1 Firebase Cloud Messaging

Implementar notificações push com Firebase Cloud Messaging.

Exemplos:

- Lembrete de consulta.
- Lembrete de terapia.
- Lembrete de medicamento.
- Alerta de crise em andamento.
- Aviso para rede de apoio.
- Aviso de atividade atrasada.

---

### 3.2 Notificações locais

Implementar notificações locais para lembretes básicos no próprio dispositivo.

Exemplos:

- Atividade da agenda próxima do horário.
- Terapia marcada.
- Medicamento ou cuidado recorrente.
- Revisão diária da rotina.

---

## 4. Relatórios avançados

### 4.1 Gráficos

Adicionar gráficos para facilitar a análise.

Exemplos:

- Crises por semana.
- Registros por tipo.
- Gatilhos mais frequentes.
- Atividades concluídas por período.
- Horários com maior ocorrência de crise.

---

### 4.2 Filtros avançados

Permitir filtrar informações por:

- Período.
- Tipo de registro.
- Intensidade.
- Gatilho.
- Usuário que registrou.
- Criança selecionada.

---

### 4.3 Exportação

Permitir exportar relatórios em:

- PDF.
- CSV.
- Planilha.

Esses relatórios podem ser compartilhados com profissionais de saúde, terapeutas ou escola.

---

## 5. Modo crise avançado

### 5.1 Ambiente calmante personalizado

Permitir cadastrar preferências específicas, como:

- Sons calmantes.
- Frases de apoio.
- Imagens preferidas.
- Orientações individuais.
- Sequência de ações recomendadas.

---

### 5.2 Acionamento da rede de apoio

Durante uma crise, permitir notificar pessoas específicas da rede de apoio.

Exemplos:

- Responsável principal.
- Cuidador.
- Familiar autorizado.
- Pessoa de emergência definida pela família.

---

### 5.3 Histórico detalhado de crise

Criar tela específica para histórico de crises com:

- Duração.
- Intensidade.
- Gatilho.
- Estratégia usada.
- Observações.
- Evolução ao longo do tempo.

---

## 6. Gestão de múltiplas crianças

### 6.1 Perfis familiares

Permitir que um responsável gerencie múltiplas crianças com mais recursos.

---

### 6.2 Permissões por criança

Permitir que uma pessoa da rede de apoio tenha acesso a uma criança, mas não a outra.

Exemplo:

- Um cuidador pode acompanhar a Criança A.
- Outro cuidador pode acompanhar a Criança B.
- Um responsável pode administrar todas.

---

### 6.3 Responsáveis secundários

Permitir cadastrar mais de um responsável com permissão administrativa.

Exemplos:

- Pai.
- Mãe.
- Responsável legal.
- Responsável secundário.

---

## 7. Rede de apoio avançada

### 7.1 Solicitações pendentes

Alterar o fluxo atual para permitir:

- Solicitação de vínculo.
- Aprovação.
- Rejeição.
- Histórico de aprovações.

Na POC, o vínculo é aprovado diretamente quando o responsável adiciona uma pessoa por código. Em uma versão futura, o processo pode ser mais controlado.

---

### 7.2 Convite por link

Permitir gerar link de convite para facilitar a entrada de cuidadores e familiares.

---

### 7.3 Níveis de acesso

Criar níveis diferentes, por exemplo:

| Nível | Permissão |
|---|---|
| Visualização | Apenas visualizar rotina |
| Registro | Pode criar registros |
| Administração | Pode gerenciar informações e rede |

---

## 8. Acessibilidade

### 8.1 Interface acessível

Melhorar:

- Contraste.
- Tamanho de fonte.
- Botões maiores.
- Ícones mais claros.
- Textos objetivos.
- Redução de poluição visual.

---

### 8.2 Modo simplificado

Criar modo simplificado para uso rápido em momentos de crise.

Esse modo pode apresentar apenas as ações essenciais, com botões grandes e poucas opções na tela.

---

### 8.3 Leitura por voz

Adicionar suporte para leitura de informações importantes.

Exemplos:

- Orientações durante crise.
- Atividades do dia.
- Avisos importantes.

---

## 9. Modo criança

Criar uma interface específica para a criança, com botões simples.

Exemplos:

- Preciso de ajuda.
- Estou nervoso.
- Quero ficar em silêncio.
- Quero meu objeto favorito.
- Quero falar com meu responsável.

Essa funcionalidade deve ser avaliada com cuidado para não gerar sobrecarga sensorial.

---

## 10. Integração com profissionais

Permitir que profissionais autorizados acompanhem registros.

Exemplos:

- Psicólogo.
- Terapeuta ocupacional.
- Fonoaudiólogo.
- Professor.
- Médico.

Essa funcionalidade exigiria regras de privacidade e autorização mais rígidas.

---

## 11. Testes automatizados

### 11.1 Testes unitários

Criar testes para regras internas e funções auxiliares.

Exemplos:

- Formatação de datas.
- Validação de campos.
- Regras de status.
- Conversão de horários em minutos.

---

### 11.2 Testes de widget

Criar testes para telas principais.

Exemplos:

- Tela de login.
- Tela de cadastro.
- Home.
- Agenda.
- Modo crise.
- Minha conta.

---

### 11.3 Testes de integração

Criar testes para fluxos completos, como:

- Cadastro.
- Login.
- Cadastro de criança.
- Registro de crise.
- Rede de apoio.
- Troca de criança ativa.

---

## 12. Melhorias técnicas

### 12.1 Separação em camadas

Evoluir a estrutura do projeto para camadas mais definidas:

```txt
screens
services
repositories
models
widgets
```

---

### 12.2 Modelos tipados

Criar classes Dart para representar:

- Usuário.
- Criança.
- Vínculo.
- Agenda.
- Registro de comportamento.
- Crise.

---

### 12.3 Tratamento de erros

Padronizar mensagens de erro para:

- Falha de internet.
- Erro de permissão.
- Documento não encontrado.
- Usuário não autenticado.
- Falha de gravação.

---

### 12.4 Loading e estados vazios

Melhorar telas com:

- Skeleton loading.
- Estados vazios mais explicativos.
- Botões de tentar novamente.
- Mensagens amigáveis para ausência de dados.

---

## 13. Publicação

### 13.1 Android

Preparar versão Android para publicação ou distribuição interna.

Atividades futuras:

- Gerar build release.
- Configurar assinatura do app.
- Criar ícone final.
- Revisar nome e identidade visual.
- Testar em aparelho físico.

---

### 13.2 iOS

Preparar suporte iOS com ambiente macOS e Xcode.

Atividades futuras:

- Configurar projeto iOS.
- Testar em simulador iOS.
- Testar em iPhone físico.
- Ajustar permissões e configurações específicas.

---

### 13.3 Ambientes

Separar ambientes:

- Desenvolvimento.
- Homologação.
- Produção.

Isso ajuda a evitar que testes alterem dados reais.

---

## 14. Privacidade

Em versões futuras, será necessário reforçar:

- Consentimento dos responsáveis.
- Controle de acesso aos dados da criança.
- Política de privacidade.
- Exclusão de conta e dados.
- Histórico de acessos.
- Proteção de informações sensíveis.

---

## 15. Melhorias de experiência do usuário

### 15.1 Onboarding

Criar um fluxo inicial explicando:

- O objetivo do aplicativo.
- Como cadastrar uma criança.
- Como adicionar rede de apoio.
- Como registrar uma crise.
- Como usar os relatórios.

---

### 15.2 Ajuda dentro do app

Adicionar textos de ajuda em telas importantes.

Exemplos:

- Como usar o código de vínculo.
- O que é criança ativa.
- Como registrar uma crise.
- Como interpretar o resumo.

---

### 15.3 Padronização visual

Melhorar consistência visual entre telas:

- Espaçamentos.
- Botões.
- Ícones.
- Cores.
- Tipografia.
- Mensagens de erro e sucesso.

---

## 16. Conclusão

As melhorias futuras representam a evolução natural da POC.

A versão atual valida o conceito principal: organizar rotina, registrar comportamento e crise, gerenciar rede de apoio e acompanhar informações importantes da criança.

As próximas versões devem focar em segurança, acessibilidade, notificações, relatórios avançados, controle de permissões e preparação para uso real.