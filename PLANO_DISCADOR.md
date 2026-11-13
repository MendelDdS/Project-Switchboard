# Plano: o discador (ligações feitas pelo operador)

Hoje o operador só recebe ligações. Com este plano, ele passa a fazer ligações por um discador na mesa: escolhe o
número, ouve chamar, conversa um pouco pelas opções de sempre e desliga. Algumas ligações vão ser do roteiro.

**O nome.** Na foto, o que fica à direita da bandeja é um **disco** (disco de discagem, o rotativo). O nosso tem
teclas, então o nome técnico é **teclado de discagem**; "discador" também se usa e é o que vai na interface e no
código (`Dialer`).

**Já houve um teclado de discagem** (HISTORICO, item 2): ele servia para transferir e saiu quando os cabos entraram.
O deste plano não transfere nada: só faz as ligações do próprio operador. Transferir continua sendo só pelos cabos.

---

## 1. Decisões (confirmadas em 29/10/2026)

1. **O setor:** Vila Serena (os números 3xx), onde fica a Rádio Serena (390). Os outros setores ficam para depois.
2. **Onde fica:** na prateleira da mesa comutadora, no lugar da almofada dos broches, que foi para a esquerda dele.
   O tampo dos equipamentos antes dela ficou curto (ainda não serve para nada).
3. **Sem o FONE:** o fone do operador já é ligado direto na mesa. Enquanto a ligação feita dura, ela é a ligação em
   foco e quem estava com o FONE fica em espera; ao terminar, o foco volta para o FONE.
4. **Só o clique:** clicado na prateleira, o discador abre de perto como as outras ferramentas (`Tools.DIALER`), e o
   jogador clica nas teclas. Nada de teclado do computador.
5. **O teclado antigo (item 2 do HISTORICO):** fica de fora; este novo pode ser testado e ajustado.

**Estado:** fases 1 a 4 implementadas; em 05/11/2026 a fase 3 chegou ao Centro e ao Alto da Serra (todo número da cidade atende, menos os do despacho) (abaixo, o plano com essas decisões aplicadas).

---

## 2. Como funciona para o jogador

1. No discador aberto, ele digita até 3 algarismos. O visor mostra o número e cada tecla faz um bipe.
2. **Discar**: o visor mostra "CHAMANDO", ouve-se o "tuuu" (`ringback`) de 2 a 4 vezes e o lugar atende.
3. **A conversa** aparece na tela da conversa do console, como todas as outras:
   - quem atende diz a fala de atendimento ("Rádio Serena, boa noite! O que deseja?");
   - aparecem as opções: até 2 perguntas daquele lugar ("Qual a programação de hoje?") e **[Encerrar ligação]**;
   - escolhida uma pergunta, vem a resposta e depois sobra só [Encerrar ligação], para não esticar a conversa;
   - [Encerrar ligação]: o operador diz "Vou desligar agora, obrigado.", a pessoa se despede e a linha cai.
4. **Encerrar** (a tecla vermelha), a qualquer momento:
   - chamando ou em conversa, desliga;
   - com o número só digitado, apaga o número.
5. **Os outros casos:**
   - número que não existe: tom de ocupado curto e "NÃO EXISTE";
   - número de um setor que o operador não atende: "NÃO COMPLETA";
   - tronco interurbano (9xx): "USE O TRONCO";
   - polícia, bombeiros e hospital (`dispatch_only`): "USE O DESPACHO";
   - número sem conversa escrita: toca até "NÃO ATENDE". A fase 3 fechou isso: todo número da cidade atende (o Armazém Ferreira, 288, não depois de `fita_armas_entregue`).
6. **Durante a ligação:**
   - Atender, Transferir e Escutar ficam apagadas;
   - Desligar do console faz o mesmo que Encerrar;
   - o relógio do turno não para.

---

## 3. Modelo e lógica

**A ligação**
- `PhoneCall.Kind.OUTGOING`, um tipo novo. O `data` é o que respondeu:
  - a entrada da lista (`DirectoryEntry`);
  - ou a ligação do roteiro (`DialCall`, seção 4).
- **Foco:**
  - `Main._focus()` devolve a ligação feita enquanto ela dura (quem estava com o FONE fica em espera);
  - o resto da conversa já segue o foco (`Conversation._until_on_line`, `PhonePanel.show_call`).

**No `Main`**
- `Main.dial(number: String)`, pública, para o discador, o painel de debug e os testes:
  - valida o número;
  - cria a ligação;
  - toca o "tuuu";
  - entrega a ligação a `Conversation`.
- `Main.hang_up_dial()` encerra a ligação feita.

**Na conversa**
- `Conversation._outgoing(c)`:
  - toca o roteiro (`play_steps`, se for `DialCall`) ou o atendimento sorteado;
  - as opções são as do `choose`;
  - as falas do operador (`OP_DIAL_BYE`, `CHOICE_DIAL_BYE` "[Encerrar ligação]") vão em `T.Key`.

**No fim da ligação**
- `end_call(c, End.OPERATOR | End.CALLER)` com `OUTGOING`:
  - `Supervisor.call_ended` ignora a ligação (sem advertência nem retorno);
  - nada vai para o caderno de fichas (`Notebook.add`);
  - a conversa entra na prancheta (`CALL_LOG`).

**A linha**
- A linha do lugar chamado fica ocupada enquanto o operador fala com ele: quem pedir esse número nesse meio-tempo
  encontra ocupado.
- Esse estado fica no `Exchange`, dono único das linhas: `Exchange.seize(number)` ao chamar, `release` ao terminar.

**Sorteio**
- Pelo `randf` global, que segue `--seed`.

**Debug (F1)**
- Um campo "Discar" com o número.
- Um botão "Ligação do roteiro aqui" que dispara a `DialCall` da noite.

---

## 4. Dados (`data/`)

**Conversa do dia a dia, por lugar.** Reaproveita o `ChatTopic`, o assunto de conversa fiada, sem recurso novo:

```gdscript
# DirectoryEntry
## Quando o operador liga para cá (`Dialer`): cada atendimento é um assunto (`ChatTopic`): a `line` é como atendem
## ("Rádio Serena, boa noite! O que deseja?") e as `replies`, as perguntas que o operador pode fazer, cada uma com a
## resposta (`follow`) e os marcadores dela (`sets`). `requires` e `weather` valem como na conversa fiada. Vazio:
## ninguém atende.
@export var answers: Array[ChatTopic] = []
## A despedida quando o operador encerra (vazio: uma das gerais, `GameContent.dial_byes`).
@export var bye := ""
```

Detalhes desse formato:
- **Mais de um atendimento por lugar** (2 ou 3), sorteados, para a mesma ligação não se repetir.
- **Marcadores:** `requires` deixa a cidade lembrar do que já aconteceu (depois da batida, o hotel atende diferente).
  `ChatReply.sets` liga marcadores ao perguntar.
- **Palavras-chave** (`[tipo:texto]`, `Clue`) podem ir na resposta e caem nas anotações da lista, como na escuta.

**Ligações do roteiro.** Recurso novo, `DialCall` (`scripts/data/dial_call.gd`), um por arquivo em `data/dial/`:

```gdscript
class_name DialCall
extends Resource
## Uma ligação que o operador faz e que o roteiro precisa: discando `number` (que pode nem estar na lista), quando os
## marcadores baterem e na hora certa, ela toca no lugar do atendimento de sempre.
@export var number := ""
@export var requires: PackedStringArray = []   ## StoryFlags.allows
@export var from := 0.0                        ## minutos depois das 18h em que atende...
@export var to := 720.0                        ## ...e até quando
@export var voice := ""                        ## vazio: a do lugar
@export var steps: Array[PrankStep] = []       ## o roteiro falado (CALLER, OPERATOR com `sets`, PAUSE, END, EFFECT)
@export var sets: PackedStringArray = []       ## marcadores ao terminar inteira
@export var once := true                       ## depois de feita, o número volta ao de sempre
```

- **Onde fica:**
  - `Night.dial` guarda as ligações daquela noite;
  - `GameContent.dial` guarda as de qualquer noite.
  - A ordem de procura é: a da noite, depois as gerais, depois o atendimento do lugar, e por fim ninguém atende.
- **O formato do roteiro** é o mesmo dos trotes e da desconhecida (`PrankStep`). Nada novo para aprender ao
  escrever, e o efeito "flick", a lâmpada piscando, também funciona aqui.
- **Marcador automático:** `ligou_<número>_<noite>`, como o `sinalizador_N`. Com ele, uma `StoryCall` pode retornar
  a ligação mais tarde (`requires`), sem código novo.
- **Número fora da lista:** é possível de propósito, para o roteiro (um número ouvido na ligação desconhecida, por
  exemplo). O `test_content` só confere que o número tem 3 algarismos e que não é um tronco.
- **Já gravado no save**, sem mudar o `Progress.VERSION`: os marcadores (`StoryFlags`). Fica para decidir se é
  preciso lembrar quais ligações `once` já foram feitas: um marcador automático basta.

**Textos**
- **Falas em português no Resource**, com `tr()` ao mostrar e as traduções em `translations/content.{en,es}.po`
  (`tools/update_translations.gd`).
- **Interface:**
  - visor: `DIAL_CALLING`, `DIAL_BUSY`, `DIAL_NO_ANSWER`, `DIAL_NO_NUMBER`, `DIAL_NOT_SERVED`, `DIAL_TRUNK`,
    `DIAL_DISPATCH`, `DIAL_ON_LINE`, `DIAL_ENDED`;
  - etiquetas: `DIAL_KEY`, `DIAL_END`.

---

## 5. O visual

O discador segue a mesa: plástico creme da série Ruptura, placa oliva, teclas na cor das chaves de escuta, tela do
console e lâmpada da mesa. Tudo em pixel art 1x1, sem contorno preto (a beira é o tom da peça na luz ou na sombra).

**Lugar e tamanho**
- Na prateleira: uma caixinha deitada de 62 px à direita, no meio do vão entre a almofada e o fim dela (`Dialer`, `scripts/ui/dialer.gd`), linha a linha na
  inclinação da prateleira como a almofada, com a placa oliva, o visor, a lâmpada e o teclado em miniatura.
- De perto: a ferramenta `Tools.DIALER` (`scenes/ui/dial_view.tscn`, `scripts/ui/dial_view.gd`), a chapa oliva com o
  visor e as teclas do console (`KeyCapStyle`).
- O `test_layout` confere as folgas na prateleira.

**As partes, da esquerda para a direita**
1. **A moldura:** chapa oliva de cantos redondos (`Switchboard.round_rect`, `Pal.BOARD_FACE`/`BOARD_METAL`).
   - Uma fresta escura em volta, com os cantos quebrados, como os equipamentos da coluna.
   - A luz da luminária pega o alto da chapa (`_draw_room_light`) e ela escurece com a sala, como a miniatura.
2. **O visor** (uns 34 × 13 px), um poço escuro no fundo das telas (`Pal.BOARD_INSET`):
   - os algarismos em **7 segmentos desenhados à mão** (3 × 5, a regra da fonte não deixa letra acima de 11 num objeto
     da sala), no verde da fala do operador (`ConsoleMini.INK["op"]`);
   - os segmentos apagados levemente visíveis, como num visor fluorescente de verdade;
   - os acesos com brilho fraco: `Bloom.clear(self)` no começo do `_draw` e `Bloom.light` em cada um;
   - embaixo dos algarismos, a palavra do estado em `PixelArt.tiny` (maiúsculas 3×5, com acento): "CHAMANDO",
     "EM LINHA 01:12"...;
   - o vidro com o reflexo na diagonal, como nas telas do console (`ScreenGlass`).
3. **A lâmpada de linha**, ao lado do visor, uma lâmpada da mesa (vidro leitoso no aro creme, `_draw_lamp`):
   - âmbar piscando enquanto chama;
   - verde em conversa;
   - vermelha no ocupado e no "não atende".
   - Ela acende rápido e apaga devagar, como as do painel (`LAMP_ON_SEC`/`LAMP_OFF_SEC`).
4. **O teclado**, 3 × 4 teclas de uns 9 × 8 px com 2 px entre elas:
   - 1 2 3 / 4 5 6 / 7 8 9 / **Discar 0 Encerrar**: as duas teclas de ação ocupam os cantos de baixo, no lugar do
     \* e do # de um telefone;
   - os algarismos gravados em `PixelArt.tiny`, na tinta do painel (`Pal.BOARD_INK`);
   - teclas de número no ciano das chaves de escuta (`Pal.KEY_CAP`), com o tampo em relevo e 1 px de frente mais
     escura;
   - **Discar** com uma tampa verde e **Encerrar** com uma tampa vermelha, nas cores das teclas Atender e Desligar do
     console (`KeyCapStyle.color` no `phone_panel.tscn`), cada uma com um fone desenhado à mão (levantado e no
     gancho);
   - apertada, a tecla desce 1 px e a frente some (como `KeyCapStyle.SUNK`);
   - sob o mouse, a tecla sobe e mostra a etiqueta de fita crepe com o nome ("Discar", "Encerrar"), como os objetos
     da mesa.
5. **Em cima da chapa,** a palavra "DISCADOR" gravada em `PixelArt.tiny` e o selo da companhia (`Switchboard.badge`),
   como no painel.

**Redesenho**
- Uma camada só, com estado comparado no `_process`: o número, o estado, a tecla apertada, a tecla sob o mouse, a
  luz e o escuro da sala.
- A piscada da lâmpada e o brilho do visor vão no `modulate`, nunca nas cores das imagens guardadas.
- Mexeu no desenho: medir com o `medir.gd`.

**O console de baixo**
- A tela da conversa mostra "Ligação para 390 · Rádio Serena AM" no alto.
- Atender, Transferir e Escutar ficam apagadas, como quando não há ligação.

---

## 6. Som (`SfxSynth`, barramento Phone)

- Bipe de tecla:
  - curto e suave, um tom por algarismo, na família dos bipes que substituíram a campainha antiga (HISTORICO 12: a
    campainha irritava);
  - baixo, para não cansar com muitas ligações;
  - um bipe grave para o 4º algarismo, que não entra.
- Discar: uma sequência rápida e baixa de cliques, a central puxando o número.
- Chamando: o `ringback` que já existe.
- Ocupado: tom curto intermitente, novo.
- Atendeu e desligou: os cliques de linha (`click`).
- Tudo sintetizado no `SfxSynth.build()`, sem chamar função por amostra, e o volume só por `Sfx.fade`.

---

## 7. Fases

| Fase | O que entra | Pronto quando |
|---|---|---|
| **1. Modelo e fluxo** | `Kind.OUTGOING`, `Main.dial`, `Conversation._outgoing`, `DirectoryEntry.answers/bye`, `DialCall`, `Night.dial`, `GameContent.dial`, `Exchange.seize`, marcador automático, debug, sons | ligar pelo F1 funciona do começo ao fim, com testes |
| **2. O discador na mesa** | `Dialer` na prateleira, o de perto (`DialView`, `Tools.DIALER`): visor, lâmpada, teclado, etiquetas | capturas aprovadas por você, `test_layout`, `test_keys` e medição de desempenho |
| **3. Conteúdo do setor** | atendimentos dos 12 números de Vila Serena, 2 ou 3 cada, com 2 ou 3 perguntas, mais as traduções | `test_content` cobrando que todo número do setor atende |
| **4. Roteiro** | só a estrutura (`DialCall` de exemplo nos testes, sem fala de história); você escreve as do roteiro | `test_flow` com uma `DialCall` de teste mudando marcadores |

Na fase 3, as falas do dia a dia (rádio, bar, posto...) são um **rascunho para você revisar**, como pediu. As do
roteiro ficam com você: o plano só prepara o formato e confere.

**Testes**
- `test_dial`, novo:
  - discar e conversar;
  - número inexistente, fora do setor, tronco e despacho;
  - Encerrar chamando, Encerrar com o número digitado;
  - uma ligação que chega no meio;
  - prioridade da `DialCall` e os marcadores dela;
  - a linha ocupada para quem pede o mesmo número.
- `test_content`: atendimentos com fala, perguntas e respostas, traduções no `.po`, números das `DialCall` válidos.
- `test_layout`: a almofada e o discador folgados na prateleira.

**Documentação**
- `CLAUDE.md`: uma linha no "Modelo das ligações" e na "Entrada".
- `scripts/ui/CLAUDE.md`: o `Dialer`, na mesa comutadora.
- `README.md`: como escrever um atendimento e uma `DialCall`.
- `HISTORICO.md`: o pedido.

---

## 8. Sugestões de melhoria

**Feitas em 29/10/2026:** 1 (rediscar), 2 (horário), 3 (palavras-chave nas respostas) e 5 (o retorno, pelo
marcador `ligou_<número>_N`, receita no `README`); em 13/11/2026: 4 (atendimentos da ocasião em 11 lugares, `ChatTopic.from_night`/`to_night`, falas sugeridas a revisar), 6 (a seta "↗" no registro) e 8 (o passo "dialed" no treinamento); a 7 não entra (o tempo perdido já pune). Também: a espera de quem está com o FONE e o cabo solto na linha chamada.

Conferidas com o `CLAUDE.md` e o `HISTORICO.md`, incluindo o que já saiu.

1. **Rediscar:** Discar com o visor vazio liga para o último número, sem tecla nova. Ajuda quando o lugar não atendeu.
2. **Horário de funcionamento:** `DirectoryEntry.closes`.
   - Depois dessa hora, o comércio não atende (a oficina e a borracharia fecham; o bar, o hotel e o posto não).
   - Dá vida à cidade e cumpre o "todo número serve para alguma coisa".
3. **Ligar para investigar:** respostas com palavras-chave (`[tipo:texto]`) vão para as anotações da lista,
   como na escuta. Assim, ligar para o hotel depois da batida pode render uma pista, e o discador vira ferramenta do
   mistério, não só curiosidade.
4. **Cidade que lembra:** usar o `requires` dos atendimentos com os marcadores que já existem. Exemplos:
   - o hotel nervoso depois da batida da noite 13;
   - a rádio comentando o toque de recolher nas noites 9 a 14;
   - ninguém atendendo no apartamento da família que fugiu na noite 14.
5. **O lugar retorna:** uma `DialCall` liga um marcador e uma `StoryCall` da mesma noite ou da seguinte liga de
   volta, com `requires`. Não precisa de código: fica como receita no `README`.
6. **A prancheta mostra as ligações feitas** com uma marca própria (uma seta saindo), para separar das recebidas.
7. **Consequência leve, opcional:** ligação particular longa com chamadas tocando na mesa vira advertência leve de
   "uso da linha".
   - Só se você quiser: muda o equilíbrio do turno.
   - Se entrar, precisa recalibrar (`tools/calibrar.sh`).
8. **Um passo no treinamento:** a Cecília mostra o discador (`LessonStep`), para o jogador saber que ele existe sem
   aviso na tela. As falas ficam com você.
