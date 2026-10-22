# Tarefa: Sistema de Progressão de Burocracias nas Ligações (modo debug)

## Contexto
Este é um jogo de telefonista em que o jogador recebe ligações e as transfere numa mesa operadora. Com o passar dos dias, o supervisor e as autoridades vão impor novas regras burocráticas. O jogador escolhe se segue cada regra ou se a infringe. Infringir gera consequências (advertências, flags narrativas), mas nunca é impedido pelo sistema.

O jogo já tem:
- sistema de ligações e transferência;
- mecânica de escuta com medidor de desconfiança;
- sistema de advertências e pontos de eficiência;
- ciclo de dias/noites;
- menu de debug.

## Objetivo
Implementar a infraestrutura das 4 burocracias descritas abaixo, **acessível apenas pelo menu de debug**. Nada deve alterar o fluxo atual do jogo. Futuramente o roteiro vai ativar cada regra em dias específicos. Por isso tudo deve ser orientado a dados e ativável por API, sem lógica hardcoded no fluxo principal.

## Antes de codar
1. Explore o projeto e mapeie:
   - como uma ligação é representada (dados, estados, ciclo de vida);
   - onde a transferência é validada e executada;
   - como funcionam escuta/desconfiança, advertências, eficiência e o relógio do jogo;
   - como o menu de debug é estruturado.
2. Apresente um resumo curto desse mapeamento e o plano de arquivos/classes que pretende criar ou alterar. **Aguarde minha confirmação antes de implementar.**

## Restrições
- Zero impacto no gameplay normal: com todas as regras desativadas, o jogo se comporta exatamente como hoje.
- Use uma feature flag global (`BureaucracyDebugEnabled` ou equivalente) e flags individuais por regra.
- Siga as convenções de código, nomenclatura e organização de pastas já existentes no projeto.
- Não implemente conteúdo de roteiro (diálogos finais, personagens fixos). Use dados de teste claramente marcados como tal.
- Toda escolha do jogador que infringe regra deve ser **permitida**, registrada e penalizada. Nunca bloqueie a ação.

## Extensibilidade (requisito obrigatório)
O sistema deve permitir adicionar novas burocracias no futuro com o mínimo de esforço, sem alterar o núcleo nem as regras existentes. As B1–B4 devem ser implementadas como **exemplos desse padrão**, não como casos especiais.

- **Regras plugáveis:** cada burocracia é uma implementação independente de `BureaucracyRule`. O `BureaucracyManager` não conhece regras específicas: ele apenas itera sobre as regras registradas. Nada de `switch`/`if` por tipo de regra no núcleo.
- **Registro orientado a dados:** regras são declaradas em dados (assets, JSON, ScriptableObjects ou o padrão de configuração do projeto), com id, parâmetros, dias de vigência e gravidades. Adicionar uma variação de regra existente, como um novo número bloqueado ou uma nova janela de horário, não exige código.
- **Ganchos genéricos no ciclo da ligação:** exponha pontos de extensão que qualquer regra pode usar, sem modificar a mesa operadora. Por exemplo:
  - `OnCallStarted`
  - `OnBeforeTransfer` (validação)
  - `OnTransferCompleted`
  - `OnCallEnded`
  - `OnListeningChanged`
  - `OnNightStart` / `OnNightEnd`
  - `OnDayStart`

  Cada regra assina só os ganchos de que precisa.
- **Resultado padronizado:** toda regra retorna o mesmo tipo de resultado (`Permitido`, `Infração(gravidade, motivo)`, `RequerAcao`). A resolução de múltiplas infrações (aplicar a maior) e o registro no `DecisionLog` acontecem num único lugar.
- **Metadados de ligação extensíveis:** além dos campos tipados atuais, a ligação deve ter um dicionário genérico de metadados (`Dictionary<string, object>` ou equivalente) para que novas regras guardem dados próprios sem alterar a estrutura base da ligação.
- **Sistemas auxiliares desacoplados:** gerador de códigos, fila de recados, inventário de fitas e acordos de redirecionamento devem ser serviços independentes, reutilizáveis por regras futuras. Uma regra nova pode, por exemplo, usar o gerador de códigos sem depender da B3.
- **Debug genérico:** o menu de debug deve listar automaticamente todas as regras registradas, com toggle e edição dos parâmetros expostos. Uma regra nova aparece no debug sem código de UI extra. Botões de cenários de teste podem ser declarados pela própria regra.
- **Documentação do padrão:** crie um guia curto (comentário de topo ou arquivo `BUREAUCRACY_RULES.md`) explicando passo a passo como criar uma nova burocracia, usando uma das B1–B4 como referência.
- **Equipamentos da mesa vinculados a regras:** uma regra pode declarar, em dados, os equipamentos que exige na mesa comutadora. A mesa deve ter um mecanismo genérico de slots/equipamentos liberáveis (`UnlockEquipment(id)`, `IsUnlocked(id)`), com estado persistente no save. A B4 é o primeiro uso desse mecanismo. Burocracias futuras que precisem de novos objetos na mesa devem usá-lo sem alterar a lógica da mesa.

## Arquitetura proposta
Adapte à engine e ao padrão do projeto.

### 1. Núcleo
- **`BureaucracyRule`** (base/interface): `id`, `tipo`, `ativa`, `diaInicio`, `diaFim` opcional, parâmetros específicos, e um método que avalia uma tentativa de transferência e retorna um resultado (`Permitido`, `Infração(gravidade, motivo)`, `RequerAcao`).
- **`BureaucracyManager`**: registro das regras ativas, API pública para ativar/desativar/modificar regras em runtime (`Activate(ruleId)`, `Deactivate`, `UpdateParams`) e um ponto único de validação chamado pela mesa operadora antes de concluir uma transferência.
- **`PenaltyLevel`**: `Media`, `Grave`, `Gravissima`, integrado ao sistema de advertências existente. O mapeamento regra→gravidade fica configurável em dados.
    - **Regra de acúmulo:** se uma mesma transferência gerar mais de uma infração (de regras diferentes ou do sistema de número errado já existente), aplique **apenas a advertência de maior gravidade**. Ordem: Média < Grave < Gravíssima. Todas as infrações detectadas devem ser registradas no `DecisionLog`, mas só a maior vira advertência efetiva.
- **`DecisionLog`**: registro de cada decisão relevante do jogador (dia, hora, ligação, regra, escolha, resultado). Ele vai alimentar consequências narrativas futuras e o questionamento das autoridades.

### 2. Extensão dos dados de ligação
Campos novos, todos opcionais e com default neutro:
- `callerName`, `callerSurname`, `willIdentify` (sim / não / só se insistir);
- `isMessageOnly`, mais o recado e o destinatário do recado;
- `isUrgent`, `urgencyReason`;
- `authCodeSpoken` (código dito pelo emissor, pode estar errado ou ausente);
- `secretSignal` (estalo, apito, palavra), com um gancho para áudio/texto;
- `isSuspicious`, `keywords[]` (palavras-chave gravações);
- `wantsNextCode` (personagem que pede o próximo código de autorização).

## Burocracias

### B1. Identificação obrigatória
- Quando ativa, o emissor deve dizer nome e sobrenome no início da ligação.
- Se o emissor se recusar, o jogador pode encerrar sem transferir ou transferir mesmo assim. Transferir sem identificação gera **advertência média**.
- **Recados:** o emissor pode recusar o nome e deixar apenas um recado para alguém.
  - Crie um `MessageQueue` que guarda recados pendentes vinculados a um destinatário.
  - Quando o destinatário ligar (ou receber ligação), o jogador recebe a opção de repassar ou não o recado.
  - Registre a escolha no `DecisionLog`. A penalidade por repassar recado anônimo fica configurável, com default de nenhuma.

### B2. Números bloqueados
- Lista de estabelecimentos bloqueados, cada um com regras opcionais:
  - **janela de horário**, por exemplo "bar liberado até 21h" (avaliar pelo relógio do jogo);
  - **liberação por código de autorização**, por exemplo o hospital em dias de alta demanda.
    - Reutiliza o sistema de códigos da B3: com o código correto, a transferência é permitida.
    - Sem código ou com código errado, o número é tratado como bloqueado comum: transferir gera **advertência grave**, e não gravíssima.
- **Qualquer transferência para número bloqueado gera advertência grave**, inclusive ligações urgentes.
- Ligações **urgentes** para número bloqueado (parentes no hospital etc.): o jogador aceita ou nega. Aceitar gera advertência grave. Registre também como decisão moral no `DecisionLog`.
- **Redirecionamento condicional com sinal:** um personagem pede que ligações para X (bloqueado) sejam transferidas para Y somente quando o emissor der um sinal combinado (estalo, apito, palavra).
  - O jogador pode aceitar ou recusar o acordo. Registre a escolha.
  - Com o acordo ativo, a tentativa de transferência é avaliada assim:

    | Emissor pede | Sinal | Jogador transfere para | Resultado |
    |---|---|---|---|
    | X | sim | Y | Permitido. Sem advertência, apenas registro no `DecisionLog`. |
    | X | sim | X | O emissor reclama: advertência média, usando o sistema de número errado já existente. |
    | X | não | (não transfere, avisa o bloqueio) | Permitido. Comportamento correto. |
    | X | não | X | Advertência grave (número bloqueado). |
    | X | não | Y | Número errado comum: advertência média, pelo sistema já existente. |
    | X | sim | X | O emissor reclama (número errado, média) e X está bloqueado (grave). Aplica-se a maior: advertência grave. |

  - A advertência por "número errado" no caso com sinal deve vir da reclamação do emissor, reaproveitando o fluxo existente, e não de uma regra nova da B2.
  - Sem acordo ativo, o sinal não tem efeito e a ligação segue as regras normais de bloqueio.
- As regras de bloqueio devem poder ser alteradas em runtime: adicionar/remover números, mudar horários, ativar/desativar acordos de redirecionamento.

### B3. Ligações que exigem código de autorização
- Estabelecimentos marcados exigem um código alfanumérico dito pelo emissor a cada transferência.
- **Gerador de códigos:**
  - Interface `IAuthCodeGenerator` com `GetCode(dia, indice)`.
  - Códigos nunca se repetem e devem seguir um padrão dedutível pelo jogador.
  - **O padrão definitivo ainda não foi definido.** Implemente apenas um gerador placeholder simples (por exemplo, letra +2 e número +7 por dia: `K-07`, `M-14`, `O-21`...), claramente marcado como temporário.
  - A troca do padrão deve exigir só uma nova implementação da interface, sem mexer na validação, no debug ou nas outras regras.
- Validação: código correto, código errado, sem código.
- Transferir sem código ou com código errado gera **advertência gravíssima**.
- **Pedido do próximo código:** um personagem sem código pede o próximo código para um plano contra o governo. O jogador escolhe entre revelar o código (o sistema fornece o código seguinte do gerador) e recusar. Registre como decisão de alto peso narrativo.

### B4. Gravação de conversas em fitas
- **Inventário de fitas:** 3 por noite, configurável, resetado a cada noite.
- **Fluxo:** autoridades marcam ligações como suspeitas → jogador insere uma fita → ativa o modo escuta já existente → a gravação acontece enquanto a escuta está ativa.
- **Palavras-chave:** cada ligação suspeita tem `keywords[]` associadas a trechos do diálogo. Uma palavra-chave só é capturada se a escuta estiver ativa naquele trecho. A desconfiança existente continua valendo, então o jogador precisa gerenciar quando escutar.
- **Fita gravada:** guarda a ligação de origem, as palavras-chave capturadas e um "valor de informação" calculado.
- **Ações com a fita:** entregar às autoridades (gera pontos de eficiência proporcionais ao valor) ou descartar (a fita é perdida e não volta ao inventário).
- **Sem gravação:** se o jogador não gravar nada numa noite com pedidos de gravação, não há penalidade imediata. Registre um flag `authorities_questioning_pending` para o roteiro usar nos dias seguintes.
- **Equipamentos bloqueados até a regra ser introduzida:** o porta-fitas e o leitor/gravador **não existem na mesa comutadora** no início do jogo. Eles só aparecem quando a B4 é ativada pela primeira vez.
  - Antes disso, não devem ser visíveis, interativos nem ocupar espaço de interação na mesa, apenas um slot fechado deve ser mostrado.
  - A ativação dispara um gancho (`OnEquipmentUnlocked` ou equivalente) para que o roteiro possa, no futuro, encenar a chegada dos equipamentos (fala do supervisor, animação de instalação etc.). Por enquanto basta o gancho, sem conteúdo.
  - Depois de liberados, os equipamentos permanecem na mesa mesmo se a regra for desativada depois. Desativar a regra só interrompe os pedidos de gravação. Deixe isso configurável caso o roteiro precise removê-los.
  - Enquanto a regra está ativa, o inventário de fitas e o fluxo de gravação funcionam como descrito abaixo.

## Menu de debug
Crie uma seção "Burocracias" com:
- toggle global e toggles individuais para B1–B4;
- seletor de dia atual (simula a progressão) e ajuste do relógio do jogo, para testar janelas de horário;
- editor simples da lista de números bloqueados, horários e números que exigem autorização;
- visualização do código de autorização do dia atual e dos próximos N dias;
- botões para gerar ligações de teste de cada cenário:
  - emissor identificado, emissor que se recusa, recado anônimo;
  - ligação para bloqueado, ligação urgente para bloqueado, ligação com sinal secreto, ligação sem sinal;
  - código correto, código errado, sem código, pedido do próximo código;
  - ligação suspeita com palavras-chave, ligação suspeita sem nada relevante;
  - hospital bloqueado com código correto e sem código;
  - acordo de redirecionamento: as quatro combinações de sinal × destino da tabela da B2.
- controle de fitas: quantidade atual, resetar, listar fitas gravadas e valor de cada uma;
- visualizador do `DecisionLog` e das advertências geradas na sessão;
- botão "resetar estado de burocracias".
- controle de equipamentos da mesa: listar equipamentos liberáveis, liberar/remover cada um manualmente e simular o gancho de chegada.

## Critérios de aceite
- Com a feature flag desligada, nenhum comportamento do jogo muda.
- Cada cenário de teste do debug pode ser executado e produz a penalidade/registro correto.
- Regras podem ser ativadas, desativadas e alteradas em runtime, sem reiniciar.
- O gerador de códigos produz sequência sem repetição e determinística por dia.
- A captura de palavras-chave respeita o estado da escuta e a desconfiança existente.
- Toda decisão relevante aparece no `DecisionLog`.
- O código está documentado com comentários explicando como o roteiro deve acionar cada regra no futuro.
- Quando uma transferência gera múltiplas infrações, apenas a de maior gravidade é aplicada, e todas aparecem no `DecisionLog`.
- Adicionar uma nova burocracia exige apenas criar uma nova classe de regra e sua entrada de dados, sem alterar o `BureaucracyManager`, a mesa operadora, as regras existentes ou o menu de debug.
- Como prova, inclua uma regra de exemplo mínima e desativada por padrão (por exemplo, "limite de duração de ligação") criada só seguindo o guia, e confirme no resumo final que nenhum arquivo do núcleo precisou ser alterado.
- Com a B4 nunca ativada, porta-fitas e leitor/gravador não aparecem nem podem ser usados na mesa.
- Ao ativar a B4, os equipamentos aparecem e o gancho de liberação é disparado uma única vez.

## Fora do escopo
- Integração com o roteiro real e com os dias definitivos.
- Diálogos finais, vozes, arte e UI definitiva.
- Consequências narrativas de longo prazo (apenas registrar as decisões).

## Ao terminar
Entregue um resumo com:
- arquivos criados/alterados;
- como usar cada recurso do debug;
- exemplos de como o roteiro deve ativar cada burocracia via API;
- limitações conhecidas e sugestões.
- passo a passo de como adicionar uma nova burocracia, referenciando o guia criado.