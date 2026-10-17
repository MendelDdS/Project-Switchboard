# Lições aprendidas

Erros que já aconteceram neste projeto e o que fazer para não repetir.

## Design (o que o usuário esperava e não foi o que eu fiz)

- **Modelar a mesa como o usuário imagina, não como a mesa real.** Implementei pares de cabos (vermelho + azul)
  com chaves FALAR/TOCAR, fiel às mesas antigas. Para o usuário, o vermelho era "o cabo do fone"; tirar o
  vermelho depois de transferir derrubava a ligação, e isso pareceu errado. A mecânica foi refeita (FONE + saídas
  + cabos de conexão). **Antes de uma mecânica grande, descreva o modelo físico em 3–4 linhas e confirme.**
- **Um momento de história não pode encerrar o sistema.** O final disparava ~75 s depois da linha 07 e as
  ligações paravam. O usuário queria o turno vivo até 06:00. Eventos de roteiro se encaixam no laço; não o substituem.
- **Comece conservador na intensidade.** Ligações simultâneas demais e conversas curtas demais foram corrigidas
  depois. Deixe esses números em constantes no topo do arquivo e diga ao usuário quais são.
- **Encurtar o turno sem mexer no relógio comprime as ligações em tempo real.** O turno passou de 8 h para 6 h com
  1 min de jogo por segundo: as mesmas ~10 ligações caíram em 6 min reais e viraram avalanche. Pense no ritmo em
  **segundos reais** entre ligações (uma transferência + registro leva ~40 s para uma pessoa).
- **O robô perfeito não mede o ritmo.** Ele resolve cada ligação em poucos segundos; com 12–32 min entre ligações
  ele ia bem e uma pessoa não dava conta. Para mexer no ritmo, meça com `--human` (5 s por ação).
- **Testes headless presos ao relógio real são lentos e instáveis.** Com `Engine.time_scale` alto e tempo real, as
  falas (um timer por letra) ficam presas ao quadro e as métricas mudam com a carga da máquina. `--fixed-fps 60` simula
  quadro a quadro sem esperar o relógio: a suíte caiu de ~4,5 min para ~1 min e ficou repetível.
- **O robô perfeito não enxerga bola de neve.** Retornos (quem liga de novo) só aparecem quando alguém falha; o
  robô `--clumsy` (deixa 1 em 3 tocar) mede isso. Mecânica que gera ligações precisa de freio (esperar a mesa esvaziar).
- **Ajuste de ritmo tem efeito colateral.** Conversas mais longas prendem cabos por mais tempo e causam falta de
  cabo livre. Meça o efeito (robô) e relate o trade-off junto com a mudança.
- **Não tratar o que já está no código como decisão de design.** As 4 ligações "principais" com horário fixo eram
  resto do protótipo; o usuário quer tudo sorteado, exceto o roteiro da noite. Ao estender uma estrutura antiga,
  pergunte se ela ainda vale.
- **Quando mudar algo que o usuário não pediu** (ex.: mover o final para 06:00, manter o botão Atender),
  diga explicitamente na resposta.

- **Mapa que cresce: decida a numeração antes da disposição.** As ruas novas dos bairros vizinhos ganharam outro
  nome onde continuavam a mesma linha ("a Avenida Brasil vira XV de Novembro"), e o usuário estranhou com razão. Rua
  que continua mantém o nome e a numeração segue; por isso o bairro novo fica do lado para onde os números crescem
  (leste e sul da Vila Serena), sem renumerar o que já existia.
- **A perspectiva do cenário inteiro sai do mesmo ponto central da câmera** (os olhos do operador, `_vp`, `EYE`,
  `Z0`), pedido do usuário. Antes de desenhar qualquer peça, ponha-a na sala em medidas de verdade e projete pela
  câmera; nunca acerte a inclinação peça por peça na tela. Confira as medidas que a câmera dá: a janela parecia vista
  de cima porque a parede dela estava a 44 cm da cabeça e o peitoril 38 cm abaixo dos olhos, e cada desenho feito
  "no olho" (a espessura do vão pintada na parede, a vista de frente com a nossa calçada) contradizia a sala. O que é
  de fora e só aparece pelo vidro pode ter a câmera própria, mas nada nela pode encostar no que a sala já mostra.

### A prateleira, os tampos e os interurbanos (outubro de 2026)

- **Esqueci o ângulo de visão duas vezes.** A plaquinha do FONE e o tampo dos lugares vagos ficam deitados na
  prateleira, e eu os desenhei retos, de frente ("e novamente você esquecendo do ângulo de visão!"). Antes de desenhar
  uma peça, decida em que plano ela está: deitada no tampo, na prateleira ou no papel, as laterais fogem para os olhos.
- **...e a inclinação precisa bater com a dos vizinhos.** O tampo na perspectiva exata do ponto de fuga ficou bem mais
  inclinado que os pares de buracos ao lado, que usam um desencontro fixo e estilizado (`PAIR_SHIFT`, a pedido). Na
  prateleira, a referência é `front_of`: tudo o que fica deitado nela segue essa inclinação. Compare a peça nova com o
  que está ao lado, na captura, antes de mostrar.
- **Texto de pixel não se inclina.** As letras da plaquinha deslocadas linha a linha viraram borrão, mesmo a 1/3 da
  inclinação; a placa inclinada com as letras retas ficou "muito ruim". Ficou reta. Peça com texto, reta; sem texto
  (o tampo), na inclinação da prateleira.
- **Não enfeite sem perguntar.** A placa no cabo do FONE, para diferenciá-lo, foi "horrível". Para diferenciar uma
  peça, descreva 2 ou 3 opções antes de desenhar.
- **Disposição tem significado.** Nas duas fileiras, alternei as pontas a um passo igual e as cores se misturaram
  ("junte os cabos de mesma cor!!!!": as duas pontas são a mesma ligação). Depois fiz um tampo só para os dois lugares
  vagos, mas cada setor libera um par: um tampo por par. Antes de reorganizar, liste o que tem de continuar junto e o
  que cada lugar representa no jogo.
- **Perspectiva exata num padrão repetido parece bagunça.** O desencontro das fileiras variava de 20 a 32 px de uma
  coluna para a outra. Em fileira, passo fixo.
- **Forma em perspectiva se ancora no meio do que cobre.** Ancorado na beira da frente, o tampo fugia para a direita
  dos buracos.
- **Para centrar no pixel, mesma paridade de largura.** A plaquinha de 21 px sob o plug de 20 sobrava meio pixel para
  um lado, e o usuário viu. Largura par sob peça par.
- **Peça nova com o material e as proporções da sala.** O tampo em níquel (`_draw_metal`) ficou claro demais na sala
  escura (refeito com o metal do painel); depois, fino demais, e com dois parafusos nos lados em vez de um em cada
  canto, como se prende uma chapa. Pense no objeto de verdade antes de desenhar.

## Lógica

- **Toda espera na agenda precisa de limite.** A linha 07 só tocava com a mesa em silêncio e as ligações principais
  nunca desistiam: se o jogador deixasse uma tocando, o turno nunca terminava. Solução: `latest` (máx. 30 min de
  espera) e `GIVE_UP_SEC` para as principais. Achado pelo robô, não pelo teste dirigido.
- **Robô que joga o turno inteiro acha bugs que cenários não acham.** Rode alguns turnos completos depois de
  mexer na agenda, no fim de ligação ou nos cabos.
- **Registros do caderno são `Dictionary`: compare com `is_same()`.** `==` compara conteúdo, e `Array.erase` usa
  `==` (dois registros iguais se confundem). As ligações eram `Dictionary` no protótipo; hoje são `PhoneCall` (objeto),
  então `==` e `live.erase(c)` comparam a referência e são seguros.
- **Ao iterar `live` e poder encerrar ligações no meio**, itere sobre `live.duplicate()` (`end_call` remove da lista).

- **Mudou a geometria dos buracos: procure tudo o que sai dela.** A fileira da frente ficou 14 px abaixo, mas o fio
  continuava repousando na linha da de trás (`_floor()` = `SHELF_HOLE_Y`), e o plug da frente travava antes de entrar.
  O teste não pegou: depois de `SEAT_WAIT` o plug assenta de qualquer jeito. Ao mexer em `hole()`, procure
  `SHELF_HOLE_Y`, `floor_y`, `lip_y` e `HOLE_LIP`. Para ver se algum plug trava, compare quantos quadros cada ponta
  leva para assentar antes e depois da mudança (`go_home` até sair de `ropes`): travado leva uns 15 a mais. A
  distância medida de fora não serve: é a do quadro anterior, e o plug anda vários px por quadro.
- **Número novo fora dos setores quebra as regras "só do setor".** Os troncos (9xx) valem para a cidade toda:
  `GameData.in_service` e o teste "a agenda da noite 1 só pede o setor 3" precisaram saber disso.

## GDScript / Godot 4.6

- **`:=` falha com valor sem tipo** ("Cannot infer the type of variable"): acesso a `Dictionary`, ternário com
  Variant, retorno de método de objeto sem tipo. Declare o tipo: `var live: bool = ...`, `var cc: int = ...`.
- **Lambda multilinha dentro de literal de dicionário/argumento** é frágil no parser. Atribua a uma variável
  (`var fn := func(): ...`) e depois use.
- **Um `Control` só recebe clique dentro do próprio retângulo.** Para o encaixe do FONE (fora da mesa),
  sobrescreva `_has_point`.
- **`class_name` curto colide com variável local.** A classe de textos `T` quebrou o `city_map.gd`, que tinha
  `var T := Transform2D(...)` no `_draw`: dentro da função, `T.Key` virava membro de Transform2D. Procure o nome antes.
- **Dentro da própria classe, `Key` e `T.Key` não são o mesmo tipo** para o analisador ("Cannot pass T.Key as Key"):
  `T.text()` recebe `int`.
- **Chave de tradução igual ao texto** (ex.: `MANUAL`) parece "sem tradução" para quem confere `T.text(k) != nome`.
  Dê nomes que não coincidam com o texto.
- **`get_tree().create_timer()` ignora a pausa por padrão** (`process_always = true`). Com `get_tree().paused`, todo
  timer do jogo precisa de `create_timer(t, false)`, senão ligações desistem e falas andam com o jogo pausado.
- **`randomize()` em `_ready` anula `seed()` chamado no teste**: para repetir a agenda, passe `-- --seed=N` (o Main
  lê antes de sortear). Mesmo com semente, detalhes que dependem do tempo de quadro variam; para reproduzir um caso
  exato, monte as ligações à mão no teste.
- **Cordas de Verlet ficam em zigue-zague logo depois de um plug "teleportar"** (teste que usa `place` direto).
  É transitório: espere ~240 quadros antes da captura. No jogo, o arraste é gradual e não acontece.
- **`const X = preload("res://....tres")` confunde o analisador de tipos**: os itens de arrays tipados do Resource
  aparecem como "o script street.gd" e não como `Street`, e o `for` tipado, retorno `-> Street` e parâmetros
  tipados falham. Use `static var CONTENT: GameContent = load(...)`: o analisador passa a usar os tipos declarados.
- **`PackedStringArray` não tem `map()`, `filter()` nem `pick_random()`**: converta com `Array(...)` ou use
  `GameData.pick()`.
- **Array tipado + literal = Array sem tipo**: `typed + [x]` não pode ser atribuído a `Array[T]`; use `append`/
  `append_array`. `filter()`/`map()` também devolvem `Array` sem tipo: função com `-> Array[T]` que retorna um
  `filter()` falha; declare `-> Array`. Pelo mesmo motivo, nos testes use `m.sched.clear()` em vez de `m.sched = []`.
- **`ResourceSaver.save` com sub-resources sem caminho embute tudo no arquivo pai.** Para o pai referenciar
  arquivos próprios, salve o filho e use a instância recarregada (`load(caminho)`), que tem `resource_path`.
- **Autoloads não existem quando o Godot compila um script `-s`.** Um teste que declara tipos (`var m: Main`) cujos
  scripts usam o autoload `Sfx` falha com "Identifier not found: Sfx" e o Godot fica parado até o limite de tempo.
  Nos testes, deixe sem tipo o que depende de autoload, e não chame nem função estática dessas classes pelo nome
  (`CityMap.seg_geom`): chame pela instância sem tipo (`city.seg_geom`). Sem compilar, o teste fica parado.
- **Um StyleBox com margem interna muda o tamanho mínimo do container.** O painel de papel com `content_margin` 6
  fez a coluna direita pedir 12 px a mais; o nó raiz (anchors com grow nos dois lados) cresceu e deslocou tudo 6 px.
  Ao migrar para containers, confira `get_combined_minimum_size()` dos nós principais.
- **Containers com `mouse_filter` PASS bloqueiam cliques em irmãos atrás deles.** O encaixe do FONE fica dentro do
  telefone, mas quem trata o clique é a mesa: o telefone e os containers acima do encaixe precisam de IGNORE.
  O mesmo vale para overlays de tela cheia (`Ending`) que ficam visíveis com alfa 0.

- **O `_ready` dos filhos roda antes do `_ready` do pai.** A lista telefônica montava as páginas com os setores
  ainda não definidos pelo Main. O que os filhos precisam no `_ready` deles (noite, setores) o Main carrega no
  `_enter_tree`.

- **Os players do `Sfx` são reaproveitados (pool).** Para cortar um som, guarde o player e confira se o `stream`
  ainda é o dele antes de `stop()`; logo depois do corte, outro som pode ocupar o mesmo player.

- **`class_name` novo não existe até reimportar.** Rodando só pela linha de comando, o cache de classes globais
  (`.godot/global_script_class_cache.cfg`) não é atualizado: todo script que usa a classe nova dá parse error, e os
  testes travam até o limite de tempo. `tests/run.sh` agora começa com `--import`.
- **Fonte de pixel só fica nítida nos múltiplos do tamanho de desenho** (Departure Mono: 11, 22, 33, 44) e, com
  `stretch/mode = canvas_items`, é rasterizada no tamanho real da tela: abaixo de 1280×720 o texto de 11 px borra
  (sem suavização, os traços de 1 px somem de vez, como acontecia com Pixelify/VT323). Importe com suavização, sem
  hinting e sem sub-pixel. Ao trocar tamanhos por regex, filtre só os argumentos de tamanho: uma troca cega mudou
  `cx - 15` (posição) e a largura de uma caixa.

- **Na exportação, a conversão de `.tres` para binário esvaziou todos os `PackedStringArray`** do `content.tres`
  (listas de objetos e textos soltos sobreviveram). O jogo exportado quebrava em `pick_random()` de lista vazia, e
  os testes passavam porque leem o `.tres` de texto. Desligado com `editor/export/convert_text_resources_to_binary=false`.
  **Sempre rode o pacote exportado** (`--export-pack` + `--main-pack`) antes de entregar um executável.

- **Camadas da mesa: a variável usada numa camada de baixo desce para ela.** O `_draw_trunks` (painel) passou a ler
  `exchange`, declarado na mesa (topo): o erro derrubou as camadas de cima e o Main, e a mensagem só dizia "Could not
  resolve class". Para achar a camada quebrada, `--check-only -s scripts/ui/switchboard_<camada>.gd`, uma por uma (o
  erro de `Sfx` ali é só a falta do autoload).
- **O `_ready` do `FoneSocket` sobrescreve o `custom_minimum_size` da cena**: mudar só o `.tscn` não muda nada.
- **O `test_flow` é uma função só, enorme**: um nome de variável repetido (`other`) é erro de análise e nenhum
  cenário roda. Use nomes específicos.

## Ferramentas e testes

- **`assert` que falha em script `-s` não fecha o Godot**: o processo trava. Rode com limite de tempo
  (processo em segundo plano + `kill` depois de N s) e leia o log inteiro.
- **Não passe a saída do Godot direto por `grep`/`head`**: o buffer esconde tudo até o fim, e o teste parece
  travado. Grave em arquivo e filtre depois.
- **Captura de tela precisa de janela**: rode sem `--headless`.
- **Arquivo editado por `sed`/python fica "modificado desde a leitura"** para a ferramenta de edição: releia
  antes de usar Write/Edit.
- **O visualizador de imagens pode mostrar uma versão antiga de um PNG com o mesmo nome.** Ao comparar
  capturas antes/depois, salve com nomes novos (ou em pasta nova) a cada rodada.
- **Heredoc sem aspas (`<<EOF`) executa crases e `$(...)`**: um comentário com `` `-- --seed=N` `` virou comando.
  Use `<<'EOF'` quando o texto tiver crases.
- **Teste que conta ligações em `live` precisa medir a diferença, não o total.** Retornos de cenários anteriores
  tocam no meio do teste (eles esperam a mesa esvaziar): `live.size() == 2` falhava às vezes e passou a falhar sempre
  quando outro cenário deixou o teste mais longo. Guarde o tamanho antes e confira `antes + 1`.
- **Um assert errado no teste parece bug do jogo.** Antes de mexer no código, confira se a expectativa do teste
  está certa (ex.: contar linhas da transcrição depois de a linha "(Em espera.)" já ter entrado).
- **Captura com `--out` absoluto foi gravada dentro do projeto** (`private/`). Use caminho relativo, em `build/`.
- **Mudou o `ui.csv` com o editor aberto: peça o foco no editor na hora.** Sem `--import`, as `.translation` só se
  refazem quando o editor ganha foco; até lá o `test_flow` para na conferência das traduções e não testa o resto.
  Mexa nos textos primeiro e avise o usuário logo, não no fim.
- **Teste com número fixo quebra quando a constante muda** (`free_patches() == 3` com 5 cabos): use `b.patches`.
- **Para rodar um cenário só enquanto outro falha**, copie-o para um `tests/test_<x>.gd` temporário (a cabeça do
  `test_flow`, o cenário e `finish("nome")`) e apague depois.
- **Peça que aparece só mais tarde muda a altura da interface.** O botão Encerrar turno (às 23:40) deixa o bilhete
  do turno 2 px mais alto que a faixa encolhida, e a tela inteira subiria. Ao encolher uma faixa, meça
  `get_combined_minimum_size()` também com tudo o que pode aparecer nela.
- **Objeto de papel na mesa é solto, não arrastado até um alvo.** O arrastar do Godot (`_get_drag_data`) leva uma
  imagem até onde ele aceita soltar e o objeto volta para o lugar: o usuário pediu bilhetes e carimbo livres, que ficam
  onde são soltos, como o cartão do despacho. Para peças físicas, faça o arrastar próprio (pegar, levar, soltar).
- **Objeto novo na sala segue a câmera dela.** A prancheta pendurada "ao lado da mesa comutadora" saiu de frente, na
  parede, e destoou: o usuário pediu na lateral do painel, na perspectiva da sala (`_p3`). Nada na sala é desenhado de
  frente fora da câmera, nem um prendedor.
- **O nome de um objeto da sala (ao passar o mouse) é desenhado embaixo da mesa comutadora.** O `SceneView` desenha o
  contorno e o nome (`Background.draw_hover`), e o `Board` fica por cima dele: o nome da prancheta, centrado sobre ela
  na lateral do painel, saía cortado. Objeto novo perto da mesa: confira com `shot.tscn -- --hover=id`.
- **Objeto em pé na mesa de uma ferramenta é visto em 3/4, da cadeira.** O carimbo desenhado de cima era um bloco chato;
  o usuário mandou uma referência com tampo, frente e cabo à vista. Papel deitado (bilhete, cartão) fica de cima;
  o que tem altura mostra a frente e o tampo.
- **Objeto real tem que ser desenhado a partir de uma referência real.** O carimbo inventado (caixa com plaqueta e um
  cabo de 28 px em texto) não parecia um carimbo e o cabo saía achatado; o usuário mandou a foto de um numerador de
  escritório. Antes de desenhar um objeto do mundo real, peça ou procure a referência e copie as proporções dela
  (o cabo alto, a haste, o corpo, as pernas, a sapata), não só os materiais. Copie também o ângulo: o primeiro redesenho
  ficou largo e de frente, e o usuário mandou a referência em pixel art, fina e vista de cima (tampos à vista, peças
  redondas como elipses deitadas).
- **Peça de máquina desenhada tem que estar presa e funcionar como a de verdade.** A sapata do carimbo ficou solta
  embaixo das pernas (as pernas acabavam no tampo dela), e o aperto descia 6 px sem chegar ao papel: o usuário pediu
  as pernas até o fundo da sapata e as rodas encostando no papel antes de a marca aparecer. Ao animar ou montar um
  objeto, siga o caminho físico: o que segura o quê e onde o movimento termina.
- **Animação de algo que acontece com a ferramenta fechada tem que valer quando ela abre.** O bilhete só saía da fenda
  se fosse impresso com o calculógrafo aberto, e foi só esse caso que a captura conferiu; no jogo, a conversa acaba
  com o jogador na mesa comutadora, e ao abrir o bilhete já estava deitado. Confira o caminho comum do jogador (a
  ferramenta fechada quando o evento acontece), não só o que a captura monta.
- **Desenho em jogo não pode precisar de legenda.** O seletor do carimbo ganhou "0 1 2 D", copiado do numerador de
  verdade (o modo de repetição), e o usuário não entendeu: o jogador não tem como saber. Detalhe realista que só faz
  sentido para quem conhece o objeto fica sem letras (riscos, marcas) ou sai.
- **"Encostar" tem que se ver: o que bate cobre o lugar onde bate.** O aperto do carimbo descia até as rodas, mas
  parava no meio da janela e o papel continuava à vista embaixo delas; parecia não chegar. No contato, a peça tampa a
  área toda, a sombra dela encurta, e a batida precisa de peso: descer acelerando, parar seco, segurar um instante,
  voltar freando, a mesa sacudindo e o som do impacto. Um movimento senoidal, liso e simétrico, não bate em nada.
- **O resultado de uma ação física sai onde ela aconteceu.** O bilhete empurrava a marca do carimbo para dentro do papel
  (um `clamp` para ela caber inteira), e carimbado na beira a marca aparecia longe da janela. Não corrija a posição em
  silêncio: recorte o que cai fora e resolva a validade por regra (o borrão), à vista do jogador.
- **Tamanho na sala se confere em centímetros, pela câmera (`Background._cm`), contra os vizinhos e os plugs.** O
  calculógrafo refeito ficou no espaço da miniatura antiga (14 cm), com bilhetes de 5 cm e um carimbo de 2 cm, e o
  usuário viu que os plugs (~12 cm em pé, 2,5 cm de grossura) ficavam maiores que carimbo, listas e relógio. Antes de
  desenhar um objeto, diga o tamanho de verdade dele e confira na conta, não só se cabe no lugar.
- **Menos relevo não é tirar o sombreado.** Pedido "menos protuberância no aro da tomada", deixei o aro num tom só com
  um chanfro de 1 px, e o usuário viu que os detalhes tinham sumido. Para achatar uma peça em pixel art, aproxime os
  tons (o claro e o escuro mais perto do meio) e encurte a sombra, mantendo o desenho e os tons que ela tinha.
- **Miniatura confere a proporção de cada peça com a aberta, não só o tamanho total.** A máquina do calculógrafo da sala
  tinha 22 × 2,6 cm (8,7 : 1) e a aberta 632 × 104 (6 : 1): o usuário viu a miniatura "larga demais". E o que fica nos
  cantos da frente de uma mesinha em perspectiva abre para fora do que está atrás dela (perto, tudo fica maior): a
  almofada e a caixinha encostadas nos cantos passavam dos lados da máquina e o conjunto parecia torto. Afaste dos
  cantos o que tem de parecer alinhado.
- **Ação nova ganha tecla própria, não carona numa existente.** A chave de escuta foi posta no Tab, que vira outra coisa
  conforme a linha (Transferir ou escutar), e o usuário pediu a tecla Z, separada, com o nome dela no console. Uma
  tecla que muda de sentido pelo estado pega o jogador de surpresa (Tab apertado para transferir abria a escuta).
- **Fala ouvida se confere por quem a diz e pelo que essa pessoa pode ter ouvido.** Avaliei "Psiu. Acho que ouvi alguém
  respirando" → "Eu também ouvi" como boa, e o usuário lembrou que só faz sentido na boca de quem estava calado (quem
  fala acha que a respiração é do outro); a resposta, de quem falava, tem de mostrar isso ("Achei que era você...").
  Conferindo o código, achei também a vez da conversa trocando de pessoa quando a pergunta ficava sem resposta.
- **Texto com prazo tem de caber na leitura.** A escuta usava a velocidade da fala com o operador (~36 letras/s), que
  serve quando o texto fica parado esperando a resposta; com a suspeita contando, o usuário não conseguia ler antes de
  ser descoberto. Ao pôr um relógio sobre um texto, faça a conta das letras por segundo contra o tempo do relógio.
- **Pausa nova soma com as que já existem.** A hesitação de 2 s antes da resposta vinha depois do `GAP` de 1 s que toda
  fala já tem: eram 3 s, e o usuário pediu 1.
- **Estágios de uma reação param o que corre por baixo.** A desconfiança em estágios (silêncio, pergunta, resposta)
  rodava por cima da conversa escrita, que seguia andando: ela acabava e eles se despediam antes da pergunta, e o
  silêncio "não fazia efeito". Tentei primeiro só arrumar a tela (o resto da fala embaixo do aviso), e o usuário
  apontou a causa: o tempo da conversa normal continuava rolando. Ao montar estados por cima de um fluxo, decida o que
  acontece com o fluxo em cada estado.
- **Cada estado tem de durar o que duraria de verdade.** Os estágios da desconfiança esperavam a suspeita subir de um
  nível ao outro, e o silêncio durava 6 a 20 s conforme o lugar: ninguém fica tanto calado numa ligação. Ao ligar um
  estado da ficção a um contador, confira quanto tempo ele dura em cada caso, e prefira o tempo fixo quando a ficção
  pede uma reação ("calam-se, perguntam, respondem").
- **Teste novo tem de falhar com o erro que ele cobre.** O da pergunta sem resposta passou com o erro de volta: um
  lambda do teste guardava a conversa anterior (GDScript captura a variável de quando o lambda foi criado), e a chave
  descia depois de a pergunta acabar, pelo caminho errado. Ao escrever um teste de regressão, ponha o erro de volta e
  veja o teste falhar.
- **Esperar uma coisa da mesa não é silêncio na linha.** O relógio da conversa fiada seguia correndo com o destino
  chamando; sem resposta, ela entrava junto da opção da alternativa e atrapalhava. Um contador de "tempo parado" tem
  de recomeçar quando a espera do sistema acaba e a vez volta ao jogador.
- **Mudar a escala não é multiplicar tudo por 0,75.** Na base 960, a vinheta acabava a 124 px do pé (166 × 0,75), mas
  o console, feito de texto em 11, não encolheu na mesma medida (142 px): ficou uma faixa escura por cima dele. E os
  botões de volume, desenhados à mão em `background.gd`, ficaram no tamanho antigo e passavam da beira do móvel. O que
  encosta em outra peça se mede pela peça (onde ela começa, o espaço entre as duas), e cada desenho com medidas em px
  tem de ser revisto na troca de escala, não só os que aparecem no diff.
- **No recorte que o usuário manda, pergunte-se qual parte é a queixa antes de mexer.** "As fontes estão grandes,
  grossas e descentralizadas" num recorte com o título "ENTRADAS" e as plaquinhas: mudei os números das plaquinhas,
  e a queixa era o título (em 11, encostado nelas). Meça cada candidato no recorte (o que está fora do centro, o que
  é maior que o resto) e, com dois candidatos, diga qual vai mexer.
- **Na redução de escala, o que encaixa em outra coisa tem de continuar maior que ela.** A caixinha dos bilhetes foi
  a 75% (176) e o bilhete ficou com 190: passou a ser mais largo que a caixa onde entra. Depois de reduzir, confira os
  pares recipiente/conteúdo (caixa e bilhete, furo e plug, fenda e cartão).
- **Detalhe novo num desenho de poucos pixels: olhe a junção com o que encosta nele.** A bota de borracha no plug
  encaixado, mais larga que o fio, fez o fio parecer colado de lado num caroço; e o trecho reto do fio, de 5 px no
  eixo do plug, ficava mais comprido que o próprio plug visto de frente (~3 px), deitado por cima dele.
- **"Não empurra mais" se mede no pior caso, não numa captura.** Pus as teclas em grade e disse que a sala não pulava
  mais olhando uma emergência com duas fileiras de respostas; o usuário viu crescer de novo. A altura que uma tela pede
  é a soma dos mínimos do que pode aparecer junto (aviso, falas, três fileiras de respostas, barra, espaços): some isso,
  ou meça o maior `get_combined_minimum_size` passando pelos estágios, nos três idiomas, antes de dizer que cabe.
- **Pixel perfeito não vale mais que a sensação do objeto.** Tirei o crescimento do cartão, do bilhete e do carimbo
  na mão (a 1,06, umas fileiras de pixels dobram por um instante) e o usuário preferiu que crescessem: a subida para
  perto dos olhos pesa mais que a regularidade dos pixels durante o arraste. Em interação (pegar, soltar, apertar),
  proponha a troca antes de tirar o efeito.
- **Encolheu a escala de um desenho, confira o que tem tamanho fixo nele.** Com a câmera da vista recuada (`OUT_F`) e a
  igreja diminuída (`CHURCH_K`), a cruz, o relógio e o brilho dele (em px, fora da escala) ficaram maiores que a torre e
  pareciam um poste aceso; e o facho dos faróis, inteiro até a ponta, virou uma laje cinza que alargava os carros.
  Detalhes soltos ao acaso numa área pequena (as janelas da rua do cruzamento) parecem ruído: ponha-os numa grade.
- **Não compare `Vector2.x` (32 bits) com um `float` (64 bits) com `==`.** O carro guardava a posição da frente num
  `Vector2` e depois perguntava `face.x == x` para saber se era a frente: dava falso, e a frente dos carros vindo na
  nossa direção acendia as lanternas vermelhas. Guarde a decisão num `bool`.
- **A silhueta é o que se lê, não a medida.** A perua tinha a proporção certa e parecia baixa: os vidros quase pretos
  sumiam no asfalto escuro atrás, e só a lataria (0,7 m de altura) aparecia. Antes de mexer na medida, veja se cada
  parte se separa do fundo.
- **Peça de poucos pixels precisa de tom próprio.** O teto da picape, visto de viés, vira uma tira de 1–2 px entre o
  para-brisa e a parede de trás; no mesmo tom dos vidros, a cabine parecia quebrada. Para achar o defeito, desenhe a
  geometria ampliada fora do jogo (as mesmas contas de `_o`, em Python): na captura, 8 px não dizem o que é cada peça.
- **Desenho por camadas (pintor) sem descartar a face de trás mostra o que devia estar escondido.** O para-brisa do
  fusca saía visto por trás, por cima do teto. Superfície inclinada desenhada por cima das outras precisa conferir se
  está virada para os olhos (`faces`, em `_draw_car`). E a silhueta tem de fechar: degrau sem chapa vira buraco.
  Corrigiu um modelo de carro, confira todos nas duas mãos, indo e vindo (a geometria ampliada fora do jogo mostra
  todos de uma vez).
- **Grande-angular estica a profundidade longe do meio.** Fachadas paralelas à janela não mostram isso, mas o carro,
  a 60° do eixo, se inclinava para o ponto de fuga até parecer ter metade da largura do comprimento. Perspectiva certa
  não é o que se lê: encolha a profundidade só no que tem volume (`CAR_DEPTH`). E forma recuada da beira para "parecer
  arredondada" deixa fresta onde nada a cobre.
- **"Escuro porque é buraco" não vale para o anel em volta.** Disse que as tomadas ficavam como estavam por serem
  furo; o usuário mostrou o anel preto por fora do aro niquelado, a plaquinha e a alavanca com a mesma beira. Ao
  separar contorno de buraco, olhe cada pixel escuro da peça ampliada: só o que fica **dentro** da abertura é buraco;
  o fio escuro **em volta** da silhueta é contorno, mesmo numa peça que tem furo.
- **Tirar o contorno muda a leitura do volume.** O anel preto em volta da tomada achatava o aro; sem ele, a quina mais
  escura que a face e a face indo do claro ao escuro fizeram o aro voltar a ser uma cúpula, defeito já corrigido antes.
  Ao tirar ou trocar uma beira, compare com o que o HISTORICO diz da peça (`#mesa-comutadora`) e confira a forma de
  novo, não só a cor da beira. Peça chata: face quase num tom só, a luz e a sombra só na quina.
- **O `_ready` do pai vem depois do dos filhos.** O `GameView` punha a gradação de cor no `_ready` dele, e o `Main`,
  filho dele, pedia a do clima da noite no `_ready` próprio, antes: não havia material, a noite ficava na gradação de
  sempre e a troca de clima falhava ("shader_parameter/... does not exist"). A captura montava a tela em outra ordem e
  saía certa, então a aprovação foi pela captura e o jogo estava errado. O que um filho usa no `_ready` vai no
  `_enter_tree` do pai; e confira no jogo (`app.tscn`), não só na captura, o que depende da ordem dos nós.
- **Luz que aparece de dois lados é uma luz só.** O carro desenhava o farol e a lanterna do lado de cá e, com a frente
  ou a traseira virada para nós, o par de faróis ou de lanternas dela: a do lado e a do par na mesma quina eram a mesma
  lâmpada vista duas vezes, e a traseira do Fusca tinha três lanternas (o usuário mostrou ampliado). Quando duas vistas
  do mesmo objeto se juntam (lado e frente), cada peça entra numa só; confira contando as peças na captura ampliada.
- **Shader num nó vale também para o que ele mesmo desenha.** O shader da luz posto no `SceneView` (o `TextureRect`
  do cenário) lia a textura e ignorava a cor do desenho; a etiqueta do objeto sob o mouse, desenhada no `_draw` dele,
  saiu como um retângulo branco (o usuário mostrou). Shader de efeito vai num nó que só mostra a imagem; o que é
  interface por cima fica num nó filho sem o material. E no Godot 4 o `COLOR` do `fragment` já chega como a textura
  vezes a cor do desenho: parta dele, não de `texture(TEXTURE, UV)`; multiplicando os dois, a cor sai ao quadrado e o
  cenário inteiro escureceu (o usuário viu). Depois de pôr um material, compare a captura com e sem ele
  (`--lamp=0`) e confira com o mouse sobre um objeto (`--hover=id`).
- **Shader com parâmetro só atualizado quando muda: compare tudo o que ele lê.** As luzes de fora pela janela
  (`_window_lights`) só recebiam parâmetros quando a lista de luzes mudava, mas o shader também lê o vidro (`_glass`),
  que muda com a persiana andando: fechada e aberta, o shader ficava com o vidro velho e pintava de vermelho o pedaço
  descoberto (o usuário viu). O estado comparado leva todo parâmetro que o shader usa; capturas com a persiana parada
  não mostram isso: conferir mexendo nela.
- **Camada que lê o que outra desenhou precisa saber quando isso mudou.** A camada de cima (`_over`) acende no brilho
  as luzes que a sala declara ao se desenhar (`_glows`), mas só se redesenhava pelo estado dela: uma luz que acendia
  (a ocorrência na unidade de despacho) ficava um quadradinho chapado, sem o brilho e o centro claro, até o mouse
  passar e a redesenhar (o usuário viu). Ela era pedida junto com a sala, e o pedido dos objetos (feito durante o
  desenho da sala) ia depois: desenhava antes de eles declararem as luzes. Agora o desenho dos objetos é que a pede
  (`_props_layer.draw` → `_over.queue_redraw`). Um primeiro conserto pelo estado (`hash(_glows)`) a redesenhava um
  quadro depois, e a luz piscava ao erguer o objeto com o mouse. Capturas esperam a sala assentar e não mostram nada
  disso: conferir quadro a quadro (um teste temporário que anota a lista de luzes) com o jogo correndo.
- **Luz de estado acende pelo que o operador sabe, não pelo que o jogo já sabe.** A luz de ocorrência da unidade de
  despacho seguia `Fleet.incidents`, que recebe a emergência quando ela toca: acendia antes de alguém atender (o
  usuário viu). Agora só com uma ligação dela atendida (`PhoneCall.answered`, `Main._alert`).
- **O objeto erguido pelo mouse se desenha em outra camada (`_lifted`): o que ele declara precisa ir junto.** A luz das
  lâmpadas dos objetos no tampo (`_spills`) só era recolhida da camada dos objetos; com o mouse em cima da unidade de
  despacho, ela sumia (o usuário viu). E a lista do erguido se esvazia quando ele assenta (no desenho dos objetos, com
  `_up_id` vazio): esquecida, a luz contava em dobro depois de o mouse sair. Quem acrescenta algo que o objeto declara ao desenhar (luz, brilho, contorno)
  confere com `--hover=id`.
- **Texto mudado no `ui.csv` com o editor aberto: as `.translation` (no git) só se refazem na importação.** Sem ela, o
  jogo e as capturas usam o texto antigo (a plaqueta do turno continuou "18:00–00:00" e o `%` deu erro de formatação).
  Sem `--import` no projeto, gere num worktree (copie o csv, importe lá, traga as `ui.*.translation`).
- **Raio de luz em pixel art: leque liso, não fatias finas de força sorteada.** Os raios crepusculares em 160 cunhas,
  cada uma com a sua força ao acaso, riscavam o céu de linhas (o usuário achou estranho). A cor vai em cada beira das
  fatias, variando devagar com o ângulo, e o desenho interpola entre elas. E um halo grande num pedaço pequeno de céu à
  vista cobre o degradê todo: o azul do dia que "não melhorava" estava embaixo do halo do sol; meça os pixels da
  captura antes de mexer na paleta.
- **Luz translúcida laranja por cima de céu azul dá cinza.** O clarão do horizonte e o halo do sol, quentes, ficavam
  de dia e deixavam o céu atrás da igreja cinza (o usuário viu): o que é do nascer some ou troca para branco quando o
  céu fica azul. E a ordem de desenho decide quem corta quem: as nuvens, desenhadas depois dos raios, picotavam a
  sombra da igreja.
- **Brilho somado por cima da cidade apaga silhueta fina.** O risco da lente, na camada `_rays` (ADD), passava na
  altura do braço da cruz às 5h45 e o desbotava (o usuário viu): efeito de luz que corta a vista na horizontal vai no
  céu, embaixo da cidade. Capture os minutos em que o efeito anda por cima de detalhe de 1 px, não só os redondos.
- **Ponto solto de 1 px no chão parece sujeira, claro ou escuro.** Os brilhos de sol no grão da faixa de luz (e antes
  os pontos escuros) saíram a pedido: na vista em 2×, textura de chão vai em faixas e degradês, não em pixels soltos.
- **Sol entrando por uma janela tem forma, não é brilho.** Uma mancha redonda e lisa no pé do vidro, acendendo a mesa
  em volta dos objetos sem sombra deles, pareceu uma lâmpada atrás da caneca (o usuário: "muito ruim"). Luz direta =
  a abertura projetada, de beira nítida, com o caixilho e as sombras compridas do que estiver nela; o liso fica para a
  luz difusa.
- **Voz de bicho sintetizada com fonte áspera soa como barulho.** O galo (dente de serra com aspereza e ruído, filtrado
  para soar longe) saiu a pedido como "barulho"; o sabiá, de senos limpos com entrada e saída lentas, ficou. Bicho só
  entra se der para fazer com tom limpo; o que pede timbre rouco (galo, cachorro de perto) fica de fora ou bem longe.
