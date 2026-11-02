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
- **Na prateleira, a inclinação é a dos pares de plugs; junto da lateral, a da lateral.** Os tampos erraram sete vezes: finos e colados na largura
  do passo (356), crescendo ao dividir o vão (357), flutuando com a sombra afastada (358), retos (sem angulação, 360) e
  pelo ponto de fuga da câmera da sala (`_eye`: mais inclinados que os plugs ao lado, 361). O usuário mostrou com
  riscos: as beiras paralelas à reta de um par (a ponta da frente `PAIR_SHIFT` à esquerda da de trás, `front_of`;
  `_lean`). E a beira junto da lateral da mesa fica paralela a ela (362: com a inclinação dos plugs, "errou a parte
  direita novamente"; fugindo dela para o ponto de fuga, pendia mais que a lateral, que está noutra coluna): cada beira
  copia o ângulo da vizinha dela, medido na vizinha (`_receding` na beira da prateleira). A referência de uma peça
  deitada é a peça vizinha no mesmo plano, do jeito que o jogo já a desenha, não a conta "de verdade" da câmera; numa
  dúvida entre as duas, pergunte mostrando as duas. Antes de mostrar, meça o ângulo da vizinha na captura (as listras
  de luminância por linha) e compare com o da peça. A textura vai junto, esticada
  linha a linha (`_cover_px`); o que é redondo e pequeno (parafuso) vai por cima, sem esticar (vira serrilhado). Não
  troque a inclinação para consertar outra coisa (textura, sombra, alinhamento). Texto não se inclina (abaixo).
  Tamanho e lugar fixos, do espaço que existe; sombra de peça deitada, colada; confira as noites 1, 5 e 9. Alinhar
  com os plugs também é na altura: os tampos centrados na prateleira e os buracos 4 px abaixo do meio pareciam
  desencontrados (363); peças lado a lado no mesmo plano dividem o mesmo meio. Imagem do usuário que contradiz a
  captura: meça a dele (pixels por linha) antes de mexer; um jogo aberto antes da mudança mostra o desenho antigo.
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
- **Travou no `RasterizerCanvasGLES3::_render_batch` ("Index p_index = 1 is out of bounds (size() = 1)")?** É o buffer
  de itens do renderizador de compatibilidade estourando (`item_buffer_size`): a vista no amanhecer passava de 16384 e
  travava às vezes, conforme o comando que caía na virada; uma mudança pequena que só muda a ordem dos desenhos
  (o reflexo nas janelas, pedido 279) já fazia travar 4 em 5 vezes. Conte os itens (`RENDER_INFO_OBJECTS_IN_FRAME`)
  antes de procurar o erro no seu código; com 4096 ele trava sempre, um bom jeito de reproduzir.
- **O `hash()` de um `Vector2` não serve de sorteio**: os últimos algarismos seguem os números de entrada (o resto
  por 1000 do hash da janela crescia com a altura dela, e só o primeiro andar brilhava). Para um número por objeto,
  `rand_from_seed(hash(x))[0]`.

- **Função estática de classe não pode ter nome de método do `Script`.** `Main.reload()` chamava o
  `GDScript.reload()` (recarregar o código: "Cannot reload script while instances exist"), não a função do Main; o
  mesmo vale para `new`, `get_base_script`, `can_instantiate`... Escolha outro nome (`Main.restart`).
- **Trocar de cena no meio de um clique deixa a cena velha fora da árvore e viva até o fim do quadro.** O
  `reload_current_scene()` a tira na hora: a `SubViewport` do `GameView` seguia entregando o evento fora da árvore
  (`is_input_handled: !is_inside_tree()`) e as esperas por quadro (`await get_tree().process_frame`) acordavam sem
  árvore (`get_tree()` nulo). Recomece por `Main.restart`: depois do clique, libera a cena velha de uma vez (as esperas
  pendentes somem junto, sem erro) e só então carrega a nova.

- **`await` numa corrotina de Resource às vezes devolve o `GDScriptFunctionState`.** O gerente das burocracias
  (nó) esperava `await regra.call_started(c)` (Resource) e o `greet` recebia, de vez em quando (1 em 4 rodadas, sem
  semente), o estado da corrotina no lugar do `bool`: a ligação parava depois da primeira fala. Os ganchos das regras
  ficaram síncronos (devolvem as falas; o nó as diz). Instabilidade só sem semente: rode o teste várias vezes sem
  `--seed` antes de confiar nele.

## Ferramentas e testes

- **`assert` que falha em script `-s` não fecha o Godot**: o processo trava. Rode com limite de tempo
  (processo em segundo plano + `kill` depois de N s) e leia o log inteiro.
- **Não passe a saída do Godot direto por `grep`/`head`**: o buffer esconde tudo até o fim, e o teste parece
  travado. Grave em arquivo e filtre depois.
- **Captura de tela precisa de janela**: rode sem `--headless`. **Uma de cada vez, e a janela pequena no canto**
  (`--resolution 160x90 --position 0,0`, antes do `--path`): a imagem sai da `SubViewport` do `shot.gd`, não da
  janela, e saem iguais. Várias em paralelo (`&` num laço) abriam uma janela de Godot atrás da outra na tela de quem
  está trabalhando, e o usuário notou. Capture só o que a conferência precisa.
- **Script da captura com erro deixa a janela preta e parada, e o comando só volta no limite de 2 min.** Um erro de
  parse no `tools/shot.gd` (um `m` usado fora da função onde ele existe, numa mudança temporária feita por python)
  carrega a cena sem script: nada grava nem chama `quit()`, e a janela do Godot fica preta na tela do usuário. O
  hook não pega: ele roda só no Edit/Write e compila o jogo, e o `shot.gd` não é carregado pelo jogo. Rode toda
  captura com `--quit-after 1500` (~25 s; já está no comando do `CLAUDE.md`, no `visual.sh` e no `hibit_shots.sh`)
  e leia a saída inteira: um `SCRIPT ERROR` ali quer dizer que a imagem não saiu. O `--check-only` não serve para
  conferir o `shot.gd` (sem os autoloads, acusa erro em tudo). Mudança temporária num arquivo do projeto: guarde a
  cópia antes e devolva no mesmo comando, e nunca devolva com `git checkout` (apaga também o que ainda não foi
  para o commit).
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
- **`PackedFloat32Array + PackedFloat32Array` emenda, não soma.** Para juntar dois filtros do mesmo som (`_biquad` de
  cada ressoar) o `+` devolveu o dobro do comprimento, com um depois do outro; somar amostra a amostra é um laço.
- **Sorteio por amostra no volume de um tom vira chiado.** O sabiá com o volume variando 3% a cada amostra ganhou um
  ruído de fundo em todas as frequências (visto no espectro), e o trinado em degraus (`signf`) abria o espectro em
  cada troca. Variação de som anda devagar (por nota ou numa onda lenta); confira o espectro do som novo, já que não
  dá para ouvir daqui.
- **Shader nas camadas grandes do cenário desfaz o lote das chamadas de desenho.** A cidade clareando no amanhecer
  por um shader na `_back` e na `_view` multiplicou as chamadas; a mesma conta no `modulate` delas não custa nada.
  Para clarear, escurecer ou tingir uma camada inteira, `modulate` antes de shader.
- **Captura de um worktree com `--out` absoluto vai parar dentro dele** (`<worktree>/Users/...`): o `shot.gd` trata o
  caminho como do projeto. Use pasta relativa (o `hibit_shots.sh` recusa a absoluta) e traga os arquivos depois.
- **Primitivos alternando triângulo e quadrilátero não entram no mesmo lote.** O `_light_fan` desenhava, por fatia, o
  triângulo do miolo e o quadrilátero da beira: cada um virava uma chamada de desenho, e os 22 fiapos de nuvem do
  amanhecer (2 camadas × 32 fatias × 2) passavam de 5000 chamadas por quadro na vista; as nuvens da lua davam os ~1850
  "intermitentes" ao abrir a lista. Agrupar os de mesmo número de pontos (os triângulos todos, depois os
  quadriláteros) deu os mesmos pixels e ~380 chamadas. Cenário novo entra no `medir.gd`: o amanhecer nunca tinha sido
  medido e o problema passou despercebido por três sub-etapas.
- **Luz por cima de textura, em mistura comum, apaga a textura e suja a cor.** A faixa de sol do amanhecer, laranja
  com alfa alto por cima do asfalto já texturizado, escondia o grão e, misturada ao azul-violeta da sombra e do asfalto,
  saía cáqui ou verde; o usuário achou "opaca". Luz que tinge o chão vai embaixo da textura (desenhada antes dela), a
  textura em escuro/claro translúcido (não na cor do material), e a cor de uma luz numa camada com `modulate` acima de 1
  é dividida por ele (`_sunny`). E "mais vivo" se mede: subir o ganho da luz do dia só lavou as sombras; o que faltava
  era contraste e saturação na gradação do dia.
- **Luz tem de vir de algum lugar e fazer sentido na hora toda.** No amanhecer, a sombra subindo numa fachada de
  costas para o sol, o contorno aceso em volta da igreja e a janela de sol no tampo encolhendo até a parede (às 6h,
  parecia meio-dia) foram todos recusados. Antes de pôr luz ou sombra, conferir de onde ela vem (o sol está atrás das
  fachadas de lá e da igreja: brilho, clarão ou neblina acesa desenhados na frente da igreja parecem atravessá-la) e quanto ela anda no tempo real da cena (meia hora de sol baixo mal mexe na luz). E a textura por
  cima da luz é o grão miúdo: manchas grandes em escuro translúcido no laranja viram blocos de sombra.
- **Queixa visual ambígua: achar o defeito na imagem antes de corrigir.** "Faixa escura no meio da faixa de sol"
  foi lida como as manchas do asfalto, que também escureciam; era a beira da própria luz, num laranja mais escuro que
  o miolo, e o usuário teve de mandar um recorte. Recortar o lugar e listar o que pode ser (a direção da faixa, o
  tamanho) e, na dúvida entre dois, corrigir os dois ou perguntar.
- **Luz e sombra se encontram em tons misturados, não num degrau só.** A faixa de sol do amanhecer ia direto do
  violeta da sombra ao laranja da luz e parecia pintada por cima do asfalto; o usuário lembrou que misturar as cores
  na passagem é técnica básica de pixel art. Na beira de toda luz que bate numa superfície, um ou dois degraus com a
  cor da sombra e a da luz misturadas (por fora, do lado da sombra: mais escuros que a luz no meio dela viraram a
  "faixa escura" recusada antes).
- **O contorno `_occ` dos objetos da mesa é convexo, não a silhueta.** Uma beira de luz posta nele (o sol na caneca
  e no relógio) passava fora da alça e cortava o ar ao lado do relógio. Luz que segue a forma de um objeto vai no
  desenho dele (a imagem da caneca sabe onde está cada lado), não no contorno.
- **A luz e a sombra que ela faz saem do mesmo raio.** A janela de sol no tampo ia reta para a esquerda e a sombra
  dos objetos tinha a direção dela, à parte; e, com o sol à vista na janela, quem olha espera a luz vindo para ele. Um
  raio só (`_sun_ray`) para a mancha de luz, as sombras e o teste de quem está no sol; e o pé de um objeto junto da
  parede fica na sombra do peitoril mesmo com o alto dele no sol: teste pelo alto.
- **Detalhe miúdo no fundo da vista custa a cada redesenho dele** (~11 por segundo no amanhecer e na noite limpa):
  centenas de `_r` com `_o` chamado em cada um puseram ~1,5 ms nele. Numa superfície plana a tela anda por igual
  (calcule o passo uma vez); muitas linhas iguais vão num `draw_multiline` só. E tirar as juntas para economizar
  transformou o tijolo em tábua: o detalhe que dá a forma fica, o que se corta é o custo dele.
- **Luz por cima de textura não pode cobrir a textura.** A faixa de sol na rua, quase opaca, cobria as manchas e os
  remendos desenhados embaixo e ficava chapada, com só as rachaduras riscando (o usuário notou). O que forma a
  superfície volta por cima da luz como escuro ou claro translúcido relativo ao tom de base (o tom vezes a luz), na
  força da luz naquele ponto; na cor, por cima, vira bloco de outro tom. Melhor ainda (pedido 248): luz numa camada
  própria que multiplica ou soma, entre o chão e o que fica em pé nele, como a da sala; aí não há o que repassar.
- **Ângulo de uma linha da sala não se ajusta sozinho: ela passa pelo ponto de fuga.** O usuário pediu o peitoril mais
  reto, saindo do mesmo canto (pedido 252). Numa sala retangular, toda linha da parede da direita vai para o ponto de
  fuga da sala, então mudar a inclinação mantendo um ponto dela só dá mudando o plano: a parede em ângulo, com o ponto
  de fuga dela (`SIDE_VP`). Antes de mexer numa medida da perspectiva, confira o que ela arrasta junto (aqui, a quina
  e as contas em 3D da luz da janela).

- **Pedido com palavra estranha: leia como o erro de digitação mais provável e confira o resto da frase.** "diminua a
  circunferência do sol e aumente sem brilho interno" era "aumente seu brilho interno"; lido ao pé da letra, o sol
  saiu maior e liso, o contrário do pedido. Com "diminua" logo antes, "aumente" não podia ser do disco. Na dúvida,
  diga a leitura escolhida na resposta, em uma linha.
- **Luz de sol baixo na rua: beira esmaecida, não recortada.** A faixa de sol no amanhecer tinha a beira nítida (pedido
  228) e depois dois degraus de tom; o usuário a achou "chapada, sem esmaecimento": num nascer do sol a sombra não faz
  linha reta. A luz de um sol baixo chega espalhada, e a sombra que vem de mais alto é mais larga e mais mole na beira
  (`STRIP_SOFT`, o degradê crescendo com a largura da sombra da parede). Sombra de um sol baixo, faça a beira dela
  macia e na altura do que a faz, não uma régua.
- **Luz no chão da rua precisa de algo que a quebre, senão vira vidro colorido.** A faixa de sol, uma cor só com as
  beiras macias e a textura do asfalto por baixo, ainda pareceu ao usuário "um vidro amarelo por cima da rua". Na
  referência, o que dá textura à luz é a rua úmida espelhando o sol: uma coluna de reflexo embaixo dele, quebrada em
  faixas. Compare com a referência pelo que a luz faz no material (reflexo, umidade), não só pela cor e pela beira.
- **Luz de um lado só não existe: se o chão está aceso, confira as paredes viradas para o sol.** A faixa de sol cobria
  o chão da rua do cruzamento, e as duas paredes dela estavam na sombra (uma sugestão minha, aceita no pedido 258); o
  usuário viu na hora que a parede da esquerda, virada para o sol, tinha de pegar a luz. Antes de sugerir sombra ou
  luz numa superfície, ponha o sol e a normal dela na conta e confira com o que está aceso em volta.
- **Ao sugerir melhorias, olhe primeiro os defeitos à vista na captura, não só o que falta da referência.** O usuário
  pediu sugestões e recebeu ideias novas (o céu, as poças) enquanto o chão atrás do carro estacionado continuava liso
  e as paredes sem luz; os defeitos vêm antes dos acréscimos.
- **O que tem de bater (a parede e o chão acesos) sai da mesma conta, e confere-se em todas as horas, não em duas.**
  A parede da esquerda tinha a conta própria da sombra subindo por ela, sem o limite e a rampa da faixa do chão, e
  das 5h15 às 5h30 ficava escura com o chão aceso; eu só tinha capturado as 5h40 e as 6h. Com o tempo mexendo na luz,
  capture a faixa toda (a cada poucos minutos) antes de dizer que está pronto.
- **Proporção pela cena, não pelo quadro da referência.** A torre da igreja foi alongada até parecer a da referência
  do usuário e ele achou alta demais. Ao copiar uma forma de uma referência, compare a altura dela com o que está em
  volta na nossa cena (os prédios da rua do cruzamento, o vão do céu) antes de dar por pronto.
- **Mancha que não se explica: ache a camada antes de dar nome a ela.** A faixa escura embaixo da igreja foi vista
  numa captura e chamada de "a sombra da igreja" sem conferir; era o asfalto de base do chão pintado por cima do pé
  dela (a ordem de desenho), e escondia a escadaria acabada de pôr. Para saber de onde vem um pixel, pinte a suspeita
  de magenta ou pule a camada numa captura e leia o pixel; só depois diga o que é.
- **A sombra vem de onde o sol aparece.** As sombras da mesa já tinham sido viradas "para os olhos" (pedido 245), mas
  com pouca força: ainda iam mais de lado que para a frente, e o usuário pediu de novo. Com o sol quase de frente na
  janela, compare o ângulo da sombra na tela com o lugar do sol na vista, e tente valores bem diferentes lado a lado
  antes de escolher um.
- **Luz que anda com o tempo anda num sentido só, e toda beira de sombra tem quem a projete.** No sol do amanhecer:
  um `smoothstep` de entrada multiplicado por uma razão que diminui fazia a sombra da rua ir e voltar; a janela de luz
  no tampo, projetada de um x só numa parede em ângulo, parava numa linha que nenhum objeto projetava; e um cache
  copiado só com a camada à vista deixava a luz sem sombras até a sala se redesenhar. Conferir: a beira medida em
  várias horas (só cresce ou só encolhe), cada beira de sombra ligada a uma quina de verdade, e o que a camada usa
  sempre em dia, à vista ou não.
- **Sombras de um sol quase de frente: paralelas na tela, não a perspectiva certa.** Com o ponto de fuga das sombras
  caindo no meio da mesa, cada objeto tinha a sua de um lado (a do relógio torta, a da caneca contra as outras), e o
  usuário leu como erro, duas vezes. Quando a conta física dá um leque perto da câmera, troque por uma direção só na
  tela e confira as sombras de todos os objetos juntas, não uma de cada vez.
- **Luz que muda com a hora não fica parada no fim dela.** O sol das 6h ficou no laranja do nascer (céu, faixa na rua)
  e a sombra da luminária na força da noite com o dia já claro: cada luz foi ajustada no momento que se olhava, e o fim
  do amanhecer herdou o meio dele. Ao mexer numa luz do amanhecer, olhe a mesma cena às 5h30, 5h50 e 6h, e veja o que
  as outras luzes (a luminária, o céu) fazem quando ela cresce.
- **Medir na hora e no lugar que o usuário mostrou, separando as camadas.** Na "sombra dupla" do relógio, comparei
  com e sem a sombra da luminária às 6h04, vi diferença e dei como causa; a imagem dele era das 5h38 e a causa era
  outra (a beira da luz espalhada do sol cortando a sombra). O que achou foi subtrair capturas na hora dele (sem o sol,
  sem as sombras dos objetos) e desenhar os polígonos por cima: cada faixa ficou com dono.
- **Rampa em degraus numa superfície grande e lisa vira um desenho.** Na parede do fundo, os degraus de tinta pela luz
  da luminária (plano hi-bit) deram um arco nítido ao lado do armário, que lia como uma forma sem sentido; e, sendo
  tinta, ficava igual com a sala clareando no amanhecer. Degrau de rampa serve a peças pequenas (metal, papel, um
  objeto num degrau só); em parede, chão ou céu, a luz vai lisa, e a que muda com a hora vai num shader ou numa
  camada com `modulate`, não na tinta.
- **Luz no chão embaixo de algo que anda vai na camada dele, cortada por ele.** O reflexo da porta do hotel ficava no
  chão da vista, que não se redesenha com os carros, e aparecia pela sombra translúcida do táxi parado em cima dele.
  Quem passa na frente de uma luz no chão precisa tapá-la, e isso só dá na camada que se redesenha com ele.
- **Ternário com `[]` não tem tipo.** `var x: Array[Vector3] = f() if c else []` estoura na hora em que cai no `[]`
  ("Trying to assign an array of type Array"), e só no caminho que o teste sem tela não desenha (a vista, com um carro
  na chuva). Declare vazia e atribua no `if`; e meça com tela (`medir.gd`) depois de mexer na vista.
- **Mexeu na geometria da sala, confira as beiras do que é espelhado ou recortado nela.** O arco da luminária
  refletido no vidro terminava seco na luminária; enquanto esse corte ficava fora do vidro ninguém via, e o plano da
  janela (parede mais longe, vidro maior) o trouxe para dentro como uma linha vertical (pedido 278). Luz desenhada
  termina sumindo, nunca numa beira, a não ser que algo de verdade a corte ali.
- **Mudou o tamanho de algo, confira as cópias dele.** O reflexo do letreiro no vidro foi medido para as letras miúdas
  (5 px de deslocamento, longe delas); quando elas passaram para a fonte de 11, ninguém voltou ao reflexo, que caiu em
  cima das letras e fez o letreiro parecer quebrado (pedido 282). Reflexo, sombra, halo ou fantasma de um desenho
  guardam medidas dele: mudou o desenho, refaça a conta deles.
- **Objeto preso numa fachada vai onde ele estaria de verdade.** O letreiro de bandeira ficou no x de antes, em cima
  de uma coluna de janelas, e as tampava (pedido 284): ninguém pendura uma placa na frente da janela. Tire o lugar das
  janelas sorteadas (`_sign_x`), não de uma constante que cai onde calhar.
- **Texto em pixel art fica em pé mesmo numa face em perspectiva.** As letras entortadas pela conta da perspectiva
  (cada coluna descendo) estavam certas e ficaram feias: vistas de baixo, as do alto viraram garranchos (pedido 284).
  As letras, um pixel da fonte por pixel da tela, em pé; e, numa placa vista quase de lado, a caixa também (pedido 286:
  só com as letras em pé, a caixa em perspectiva ainda era uma faixa estreita de beira inclinada): a perspectiva fica
  na posição dela.
- **Texto dentro de uma moldura: centre pela medida, e confira na captura.** As letras do letreiro começavam a um tanto
  fixo do alto e, mais altas que a face, encostavam embaixo (pedido 285). Some a altura do texto, centre no espaço da
  face e meça os vãos de cada lado nos pixels da captura antes de mostrar.
- **Na vista, o tamanho na tela vem da fonte, não da distância.** Com um pixel da letra por pixel da tela, afastar o
  letreiro só o faz maior em metros; na tela ele continua do mesmo tamanho. O de neon tinha medidas de um de verdade
  e ainda assim ficou grande demais (pedido 288). Antes de mostrar, compare a altura em px com a dos andares do
  prédio ao lado.
- **Luz apagada continua da cor dela; o halo segue a forma da luz.** O letreiro de neon apagado tinha os tubos todos
  num vermelho-escuro, e a lua amarela acesa virava vermelha apagada; o halo do bloom era o retângulo dele e saía
  quadrado (pedido 289). Apagado, cada tubo no tom dele, sem a luz; o halo pelas peças (`Bloom.light` com `parts`).
  E a caixa de um letreiro é metal pintado, cinza-escuro: escura e tingida de vermelho, parecia vinho.
- **Antes do sol, o longe não brilha.** O ar da distância e a neblina usavam a cor do horizonte, que de madrugada é o
  clarão amarelo; tudo o que sumia nele (a igreja, os prédios de longe, o fim da rua) parecia aceso antes da hora, e a
  luz do sol começava antes de ele aparecer atrás da igreja (pedido 292). O que está entre nós e o clarão fica na luz
  fria do céu, contra ele; a luz do sol na cidade começa quando o disco sai de trás do que o tapa, medido na captura
  (`_sun_seen`), não na hora em que ele nasce.
- **Tire só o que foi apontado.** "As antenas dos prédios mais distantes" eram os riscos de 1 px nos prédios de longe,
  atrás da igreja; tirei também as de espinha de peixe dos telhados da rua do cruzamento perto dela, e na vista não
  sobrou antena nenhuma (pedido 293). Num pedido para tirar algo de um grupo, ache na captura o que corresponde à
  descrição ("mais distantes", "com poucos detalhes") e tire só isso; se outra coisa parecida também incomoda, diga e
  pergunte, em vez de tirar junto.
- **Prédio que só aparece como bloco não acrescenta.** Os prédios baixos atrás da igreja (pedido 295) só podiam
  aparecer como uma faixa acima do telhado da nave (baixos de verdade, ficavam todos atrás dela e das paredes); na
  captura eram um retângulo de cor chapada com uma grade de janelas, sem silhueta, e saíram (pedido 296). Quando o
  pedido não cabe no espaço da tela como foi imaginado, mostre a captura do que deu e diga o limite antes de forçar uma
  versão que só lembra a ideia.
- **Prédio "alto" atrás de um marco tem que passar dele.** Os prédios atrás da igreja (pedido 298) mal passavam do
  telhado da nave e ficavam abaixo da torre: na tela, pareciam baixos (pedido 299). A altura que conta é a da tela,
  ao lado do que está na frente: confira na captura se a silhueta deles sobe acima do que os encobre, não só os metros.
  E "mais alto" não é "o dobro": de 80 a 160 m, passando da ponta da torre, viraram arranha-céus numa cidade pequena
  (pedido 300). Suba o bastante para resolver a queixa, guardando a escala do lugar, e mostre antes de exagerar.
- **Arredondado de referência se mede na referência.** No visual da mesa (pedido 368), cantos de raio 5 na moldura de
  5 px pareciam quase retos na escala do jogo, e os de dentro ficaram quadrados (pedido 369). Ao copiar uma forma de
  uma imagem, meça o raio dela em pixels do jogo (a imagem reduzida para 960×540) e arredonde também o contorno de
  dentro quando a referência o faz.
- **A cópia segue o que o usuário aprovou por último.** Ao alinhar o painel do operador com a miniatura dele (pedido
  374), voltei a miniatura às cores antigas das teclas em vez de levar ao painel o ciano que o usuário tinha acabado de
  ver e aceitar nela (pedido 375). Quando duas peças precisam bater, pergunte ou parta do visual mais recente aprovado.

## Fio desenhado é imagem montada, não trechos de linha
Fios curvos em `_pixel_line` por trechos ficavam finos e cheios de furos; carimbando quadrados ao longo da curva,
engrossavam nas diagonais e o brilho corria pelo comprimento nos trechos em pé (o usuário: "amassados, não
cilíndricos"). Fio é montado numa imagem guardada pintando cada pixel pela distância dele à linha do meio, de través,
em faixas de cilindro (beira, brilho do lado da luz, miolo, lado de baixo), com pelo menos 4 px (com 3, o brilho some
aos pedaços), sem contorno escuro. Plugue e passa-fio pequenos, de frente numa superfície em perspectiva, pareciam
adesivos: o que fica numa face da sala se desenha no plano dela. "Por trás da máquina" é o fio saindo da traseira,
nunca por baixo dela; e a mesa é afastada da parede (o fio cai no vão, cortado na beira).

## Conferir a captura contra o que foi pedido antes de mandar
Mandei uma captura dizendo que o fio do calculógrafo não passava mais por baixo da máquina dele, e na mesma imagem ele
passava por baixo da quina da unidade de despacho; o usuário viu. Antes de mandar, olhe a captura procurando
justamente o defeito reclamado, em todos os objetos que o mesmo desenho toca, não só no que foi mexido.

## Canto redondo em desenho projetado precisa de raio de verdade
Arredondei a tela da miniatura do despacho tirando um pixel de cada canto do desenho de frente; depois da projeção na
perspectiva (`_project`) o pixel sumia e o usuário viu os cantos quadrados. No objeto da sala, arredonde com raio de
3 px ou mais no desenho (`_round`), recue a face vizinha que encosta no canto (o alto do painel) e confira na captura
ampliada, canto por canto.

## "Print" é captura de tela
O usuário pediu para limpar "os prints desnecessários" e eu tirei `print()` dos testes; ele queria apagar as capturas
de tela acumuladas em `build/`. Na fala do usuário, "print" é captura; `print()` do código é "log" ou "saída".
Na dúvida entre os dois sentidos, olhe primeiro o que está mais à vista (pastas cheias de imagens).

## Beira limpa pode sair com dentes no empate do centro do pixel
Dei a etapa 3 por pronta e o usuário achou dentes (+2, 0) na beira da direita do bloco de fichas. A beira já tinha
inclinação limpa entre pontos inteiros, e por isso a reta passava exatamente pelos centros dos pixels: o `_project`
decidia o empate pelo erro da conta. Ao conferir beira, meça os degraus linha a linha na captura (o fim de cada linha),
não só a olho na ampliação, e desempate sempre do mesmo jeito (`EDGE_EPS`).
Logo depois ele achou o lado esquerdo do mesmo objeto: consertado um lado, meça todas as beiras dele (as duas
do tampo, a espessura e a risca da sombra) antes de mandar.

## Razão quase exata põe o degrau diferente no meio
O `clean_slope` aceitava a razão "quase exata" (n + ½ com o lado curto ímpar) achando que o degrau diferente ia para
a ponta; a placa de vídeo o põe onde a reta pede, no meio (3-4-3-4-4-3 na lateral da mesa, 2-1-2-2-1 na base do
relógio). Deixar o canto livre nos dois eixos também não serve: o ponto mais perto entorta as outras beiras. Prefira
a razão exata andando 1 px no outro eixo (`exact_slope`) ou dobre a beira (`_bent_edge`), e confira imprimindo os
cantos: a medida pela captura erra onde há textura ou veio da mesa por perto.

## Conserto de pixel não muda a forma do desenho
Para limpar o moiré dos fios da caixa na parede, troquei os quatro fios caídos em curva por dois fios retos, a 45°,
e mandei como pronto. O usuário: "tava infinitamente melhor antes [...] os fios retos e sem curvatura, tá muito
feio". O item do plano dizia "inclinação limpa" e eu o segui ao pé da letra, mas reta limpa serve para beira reta:
numa curva, o conserto é desenhar a mesma curva pixel a pixel. Se o conserto pede mudar a forma (menos peças, sem
curva, outro caminho), mostre antes como proposta e pergunte, não entregue como feito.

- **Mudou a ordem do desenho, confira tudo o que era desenhado junto.** Os fios encaixados passaram a sair antes dos
  plugs guardados, e a beira do buraco, desenhada com cada plug, foi junto por cima dos fios ("os cabos ficaram por
  baixo do buraco do slot"). Antes de trocar a ordem, liste o que cada passo desenha (plug, beira, sombra, tampa) e
  capture o fio cruzando cada peça.

- **Ordem de desenho por profundidade: pense em cada fileira.** "Encaixados antes dos guardados" valia para o fio da
  fileira de trás, mas o da fileira da frente, que nasce na frente dos plugs de trás, sumia atrás deles ("os fios estão
  ficando por baixo dos plugs também"). Ao ordenar por profundidade, confira o caso de cada fileira na captura.

- **Beira escura dos dois lados é contorno, mesmo na cor da peça.** O fio tinha a beira na própria cor escurecida 65%
  e ainda lia como linha de desenho ("muito escuras, fogem do visual"). Volume se faz com o lado da luz claro e só o
  da sombra mais escuro, de leve; o recorte contra o fundo fica com a sombra projetada.
  Valeu também para o plug encaixado, montado com discos: a beira de cada disco somava um anel escuro, e os gomos
  escuros da capa, empilhados, uma meia-lua preta. Peça montada por camadas: olhe o que as camadas escuras somam.

- **Redesenho a partir de referência: mantenha a escala do jogo.** Os plugs novos, desenhados "limpos" pela foto,
  saíram com 36 px de altura ("minúsculos"), e a ponta de metal fina demais. Ao refazer uma peça, compare na captura
  com a versão anterior e com o que encaixa nela: a ponta do plug tem a largura do furo da tomada, reta até a cabeça
  (sem degrau) e com o bico arredondado (ponta chata não é pino).

- **Peça que cresce sobre o painel: confira o que ela tapa e o clique de quem está embaixo.** O cotovelo descendo da
  tomada cobria a chave de escuta e roubava o clique dela (o `test_flow` pegou); a caixa de clique de uma peça na
  diagonal pega o vizinho, por isso o clique segue a silhueta.

- **Ao trocar o desenho de uma peça, liste o que a versão anterior tinha de bom e mantenha.** O cotovelo novo perdeu a
  paralaxe do plug encaixado ("perdeu toda aquela lógica realista") e saiu atarracado, com uma bola na cabeça, longe
  da foto (um tubo só, curva e capa comprida, o fio na linha da capa). Antes de mostrar: captura ampliada lado a lado
  com a referência e com a versão anterior.

- **Contorno de pixel art: confira o polígono, não só o desenho.** Linhas vazias no mapa do cotovelo faziam o
  `_art_outline` dar a volta errada; o destaque e o clique viraram um quadradinho, e nenhum teste pegou. Peça com
  contorno novo: um teste de clique nela.

- **Peça que gira com o fio segue o fio, sem limite fixo de lado.** Forçar a capa da entrada para a esquerda (para
  livrar a chave de escuta) fazia o fio dar um "V" no pé dela. Se algo precisa ficar livre, incline só o necessário,
  medido pela geometria, e resolva o resto no clique (a chave ganha da capa).

- **A mesma peça nos dois estados.** O cotovelo ganhou capa flexível, mas o plug em pé (na mão, solto) continuou sem
  ela: ao tirar da tomada, a capa sumia. Peça com mais de um desenho (em pé, encaixado, girado): mudou um, mude os
  outros e confira cada um na captura.

- **A mesma peça em dois desenhos tem as mesmas medidas.** A capa em pé saiu com 11 px e 10 de largura, a encaixada
  com 24 e 8. Ao desenhar uma peça de novo em outro estado, copie as medidas do desenho que já existe (aqui,
  `ELBOW_LEN`, `ELBOW_W`, `ELBOW_RIBS`) e ponha os dois lado a lado na captura antes de mostrar.

- **Tubo dobrado é um eixo curvo, não peças retas emendadas.** Pescoço reto, bola e capa reta davam um "L" com quina
  embaixo. Varra o tubo por um eixo curvo com um raio de curva maior que a meia largura; senão a parte de dentro da
  curva fica com quina.

- **O que pende de um fio vem da física do fio, não de uma regra.** A capa num ângulo calculado (a direção do buraco)
  deitava mais do que o fio puxava. Peça presa a uma corda: ponha-a na simulação (articulação, peso) e leia o ângulo
  dela. E a barriga da corda de Verlet é sobretudo o esticar das regras sob o peso; para um fio esticado por
  contrapeso, tire peso do fio em vez de só tirar folga.

- **Fio reto não pode vir de tirar o peso.** Para tirar a barriga, o fio encaixado passou a pesar 0,15 e pareceu "em
  gravidade zero". Tensão é o contrapeso puxando (recolher mais fio que o vão), com o peso inteiro; e a mudança de
  comprimento vai aos poucos, ou a corda de Verlet chicoteia e se enrosca.

## Burocracia: o que as autoridades sabem, e a tela é o canal do jogador
- **A consequência segue o que o personagem sabe.** Propus que gravar e descartar a fita da ligação marcada contasse
  como "não gravou" na hora; o usuário lembrou que as autoridades não sabem o que a ligação tinha: só dias depois
  descobrem que houve ligação suspeita sem gravação, e aí é descuido do telefonista (B4: `found_after`, duas noites).
  Antes de pôr uma advertência, pergunte quem fica sabendo e quando.
- **Ler as falas é o jogo.** Propus um sinal na mesa para a ligação marcada, além da linha na conversa: "se o jogador
  não estiver olhando para os textos, é um problema dele". Não proponha avisos redundantes ao texto da conversa.
- **Ligação marcada é do roteiro.** Nenhum molde marca ligação como suspeita: só o roteiro (`TransferCall.suspicious`).

## Objeto novo: a medida de verdade e o que ele mostra
- **Escala entre objetos da mesma mesa.** Desenhei a fita cassete em pé, do tamanho de um plug ou menor; o usuário
  lembrou que, pela lógica, ela não é tão pequena perto de um plug de áudio. Antes de pôr um objeto novo, confira a
  medida de verdade contra os vizinhos (o plug tem 72 px, ~1 px/mm) e veja se ele cabe no lugar daquele jeito.
- **O que se vê precisa existir no aparelho.** No gravador de fenda, pus uma janelinha com as bobinas girando, mas a
  fita está dentro da fenda: não haveria o que ver ali. Cada mostrador tem que vir de algo físico do aparelho.
- **Sem lugar, abra espaço; não esprema.** Encolhi o gravador para caber na frente do console e criei uma vista de perto
  para compensar; o usuário não gostou e alargou a mesa comutadora para abrir uma coluna do tamanho dele. Quando um
  objeto não cabe na escala de verdade, proponha mudar a disposição antes de miniaturizar ou esconder em outra tela.
- **Objeto da mesa que não abre ferramenta.** O `_flat` registra tudo o que desenha em `_props` (os objetos de
  clicar); a pilha de fitas entrou ali, e o mouse sobre ela quebrava o `draw_hover` (sem nome em `PROPS`). O que só
  ocupa a mesa sai de `_props` depois de desenhado (fica em `_occ`, para a disposição e as sombras).
- **Texto miúdo no meio de uma tecla.** As letras de `PixelArt.tiny` ficam nas linhas 3 a 7 da textura (em cima, os
  acentos); pus o texto pela altura da textura e as teclas do gravador saíram com as letras fora do meio. Centre pelas
  5 linhas das maiúsculas, na frente da tecla abaixo da quina de luz, e use largura com a mesma paridade do texto.
- **Caixa funda não é retângulo escuro.** O compartimento de fitas era um nicho escuro com as fitas por cima: "chapado,
  parecem adesivos". Profundidade vem do que o olho veria de cima e da direita: a parede de dentro, o fundo na sombra
  da borda, o alto e o lado de cada objeto, a sombra dele no fundo e uma beira na frente tapando o pé.
- **Objeto dentro de um vão não encosta na borda.** Pus as fitas com o alto rente à borda de cima do compartimento e o
  usuário viu as fitas sobrepondo a borda. O que fica dentro de um vão tem que mostrar o fundo em volta, inclusive
  em cima; se não couber, esconda o pé atrás de uma beira em vez de subir o objeto.
- **Obstáculo que aparece embaixo de um fio esticado.** Os pinos (`Cord.pegs`) supunham que o fio chega ao plug pelo
  lado; um plug encaixado bem sob um fio esticado o prendia por dentro, batendo sem parar (o usuário viu). Todo
  obstáculo novo da física tem que ser testado aparecendo *debaixo* do que já está parado, não só no caminho.
- **Obstáculo de fio só apoia por cima.** Os plugs encaixados seguravam o fio de qualquer lado; o de cima, esticado,
  enganchou por baixo do plug de baixo e tremia sem parar (o usuário viu "o fio se mexendo loucamente"). Um plug que
  sai do painel não prende um fio puxado contra ele por baixo: o fio escorrega pela ponta. Obstáculo de corda que
  segura de baixo para cima é laço; confira as capturas com o fio passando por baixo de um plug, não só por cima.
- **Profundidade que não se vê não existe.** A paralaxe dos plugs encaixados estava "estilizada" em 0,014 px por px
  (no máximo ~8 px, quase sempre 1–2) e o usuário não via nada; um colar de metal discreto também não resolveu. Ao
  ajustar um efeito de profundidade, compare as pontas (o mais perto e o mais longe dos olhos) lado a lado na captura:
  se a diferença não salta aos olhos sem explicação, está fraco. E os detalhes do objeto em pé (a faixa na cor do
  cabo) têm que sobreviver na outra pose.
- **Profundidade é volume, não deslocamento.** Aumentar a paralaxe de um objeto chapado só alongou o pescoço do plug
  ("zero profundidade, o cotovelo piorou"). O que vende a profundidade: anéis em elipse (a faixa, os frisos), a luz
  pela normal 3D, o que está mais à frente cobrindo o resto, a parte de metal na boca. E uma projeção de viés aplicada
  a cada ponto da superfície estica as seções redondas (o tubo engrossava longe dos olhos): projete o eixo e desenhe
  a seção com largura fixa. Detalhe do objeto (a faixa colorida) fica na peça certa (a parte dura, não a borracha).
- **Mudar um obstáculo da física mexe em todos os fios.** Ao trocar os discos de esbarrão do plug, revise as capturas
  com fios passando por cima de vários plugs: o pescoço deitado virou prateleira e o fio serpenteou.
- **Um `await` longo num nó prende as variáveis locais depois de o nó sair.** A espera de 60 s do `Main.ring` segurava
  a ligação depois do `restart`: espera longa com um objeto na mão vai por `timer.timeout.connect(f.bind(obj))`, que
  cai com o nó. Ao caçar vazamento num teste, nada de `wait_until` com lambda que guarda o objeto: o lambda fica na
  pilha do teste suspenso e o objeto parece vazado.
- **Algo deitado na prateleira perto da lateral segue a lateral, não os plugs.** A almofada dos broches pegou a
  inclinação dos pares de plugs (`_lean`) e o usuário viu que destoava da prateleira: perto do fim dela, a referência
  é a lateral da mesa (`_receding`, como o tampo dos equipamentos). Meça a inclinação na captura contra a beira ao
  lado antes de entregar. E o que depende dos olhos (`Switchboard._eye`, que muda depois do primeiro quadro) entra no
  estado comparado, ou fica desenhado com os olhos errados.
- **Erro visual num sentido só: procure o arredondamento antes de mexer na pose.** As pernas de quem ia para a
  esquerda pareciam para trás; adiantei o quadril (`HIP_AHEAD`) para todos e quem ia para a direita ficou com as
  pernas na frente. A causa era a perna de 2 px no `_limb`, que crescia sempre para a direita. Capture os dois
  sentidos lado a lado antes e depois de cada ajuste. E carro que para na rua por muito tempo estaciona junto do
  meio-fio: parado no meio da faixa, o usuário estranhou.
- **Figura pequena não é desculpa para pouco detalhe.** O vigia da noite 9 (~9 px por metro) saiu em silhueta de
  peças, com braços de 1 px e chapéu, e o usuário recusou ("parece uma aranha"). Membro de 1 px numa figura de frente
  vira pata. Use o caminho do rig (`_draw_pixels`): pixel a pixel, membros de 2 px, tons (pele, cabelo, roupa, beira
  acesa), colunas simétricas. Releia a seção de qualidade do `PLANO_RUA.md` antes de mostrar uma cena.
- **Símbolo nacional real fica de fora das cenas.** O carro de som saiu com a bandeira do Brasil no cartaz e o usuário
  pediu um brasão genérico. Na rua, insígnia, bandeira e frase de verdade viram emblema neutro (brasão redondo, letras
  inventadas na pichação, caminhão sem estrela).
- **Peça presa num carro segue o eixo dele.** As cornetas do carro de som, apontadas em diagonal, pareciam tortas e
  viradas para o jogador; e crescer o que já estava aprovado em tamanho também foi recusado. Objeto montado em veículo
  fica alinhado ao comprimento dele, no tamanho da primeira versão aprovada, salvo pedido.
- **Antes de entregar um veículo novo, meça a folga entre as rodas na captura ampliada.** As rodas de trás do
  caminhão saíram uma em cima da outra (os arcos têm 2 px a mais que o pneu). E figura dentro de um vão: confira que
  nada a corta (a lona enrolada comia os capacetes) e que linhas finas repetidas (fuzis, postes, cinto) não viram
  grade ou cruz.
- **Elemento novo da fachada não pode cair em cima de outro.** A vitrine do térreo do hotel, quando acesa, aparecia
  atrás da porta, como duas portas. Ao mexer perto da porta, da marquise ou do bar, capture com as vitrines acesas
  (começo do turno) e apagadas.
- **Andar até um lugar: no passo, freando só no fim.** A curva "out" no caminho inteiro fazia o pintor perder
  velocidade desde longe. Use `Beating.walk`. E numa perseguição, quem persegue chega depois de o perseguido sumir,
  senão não é crível que não o viu.
- **Figura da cena da rua na frente dos postes de lá vem depois deles no desenho.** Os postes eram desenhados por
  cima de todos, e os homens da banca, na frente deles, ficavam atrás. E ação com objeto (pôr no porta-malas) precisa
  do objeto mudando (a tampa abrindo) e de quem age à vista, sem nada que o tape.
- **Figura atrás de um carro, mexendo nele, some debaixo dele.** O carro é desenhado depois das figuras e com a
  profundidade encolhida (`CAR_DEPTH`): o que a figura faz por cima dele (pôr algo no porta-malas) precisa ser
  desenhado de novo depois do carro, recortado da altura dele para cima. Confira na captura ampliada se a mão e o
  objeto chegam dentro, não só se a pessoa está perto.
- **Carro parado na rua de lá: encostado no meio-fio.** Com a profundidade encolhida (`CAR_DEPTH`), um carro no meio da
  mão (ou em `PATROL_Z`) parece parado no meio da avenida; quem estaciona encosta (z ~7,45 m, o lado de lá passando do
  meio-fio, que não se vê) e chega a ele freando (`"park"`). E cena de fuga é rápida e à vista: sem coreografia de
  carga, gente atravessando com pressa até a porta do lado da calçada.
- **`Beating.walk` freia no fim.** Emendar vários trechos dele faz a pessoa desacelerar a cada um (e trocar o "out" do
  último por "lin" deixa o trecho de freio na metade da velocidade). Quem anda sem parar por um caminho com curvas: um
  momento "lin" por ponto, o tempo pela distância; a pose (virar, olhar para trás) muda no momento do ponto.
- **Luz na vista é `Bloom`, não tinta.** Um ponto colorido com um clarão misturado ao céu (`_light_fan` em mistura
  normal) parece mancha, não luz: o que acende (poste, letreiro, sinalizador) entra no `Bloom` pela camada `_over`
  (halo somado e o miolo estourando para o branco), com a posição no estado dela. E tom que muda a cada quadro na
  cidade vai no `modulate`, nunca no `_day` (as luzes dela se dividem por ele e a `_back` não se redesenha junto).
- **Ponto de luz forte no céu não é `Bloom`.** O halo em degraus dele, bom em lâmpada pequena, num ponto sozinho no
  céu vira um disco de beira marcada. Luz que precisa parecer luz: miolo estourando no branco, halo liso somado
  (imagem montada pixel a pixel, força no `modulate`), estouro ao acender, cintilação irregular, e o efeito dela na
  sala (a janela projetada, pela camada do sol). Foram três tentativas até o usuário aceitar a direção.
- **Antes de dizer que um efeito não aparece, confira ampliado.** Sugeri que a janela vermelha do sinalizador quase não
  aparecia na sala, olhando a tela inteira; ampliado, com e sem ele, ela estava nítida no tampo e no peitoril. Na
  tela inteira, um efeito vermelho escuro sobre a madeira escura some: compare o mesmo recorte com e sem o efeito.
- **Efeito de impacto precisa de causa física.** No encaixe do plug pus um brilho em estrela na boca da tomada (o
  reflexo do metal); o usuário leu como faísca e tirou: "não faz sentido". Numa interação física, o impacto vem do
  movimento (aceleração, batida, repique), da sombra, do entorno que pula e do som; luz só onde algo acende de verdade.
  E animação de 4 quadros não se vê: dê tempo ao movimento principal (o giro, a chegada) antes da batida.
- **Analise a peça antes de desenhar: o plug encaixado.** No menu, desenhei o FONE de perto como um tubo reto com a
  faixa verde embaixo da cabeça e a capa toda em frisos; corrigido com uma foto, refiz a capa inteira em anéis, e
  errei de novo. O plug tem partes, cada uma no lugar dela: a ponta de metal, o corpo duro com a faixa do cabo junto
  da tomada, o cotovelo (só a dobra, uma mola de borracha de poucos anéis, com o fio à mostra nas frestas) e a capa
  lisa até o fio. Antes de redesenhar uma peça que já existe no jogo, leia como o jogo a monta (`Switchboard._elbow`,
  o comentário dele descreve a anatomia) e reaproveite o modelo (o tubo em 3D pelo eixo), não reinvente em 2D.
  Com uma imagem melhor veio a terceira correção: a cabeça é curta, a dobra inteira é mola (sulcos finos, sem o fio à
  mostra) e acaba num colarinho reto, sem capa comprida. Peça descrita por foto: compare proporção por proporção
  (comprimento de cada parte, largura do fio) antes de mostrar, não só a lista das partes.
- **Relevo pequeno num tubo 3D vem da forma, não da tinta.** Os sulcos da mola pintados como faixas escuras num tubo
  liso pareciam listras, e o tubo feito de esferas pelo eixo não consegue ter sulco (a esfera vizinha tapa). Montado
  em anéis de pontos na superfície (`title_board.gd`, `_fone_art`), com o raio ondulando e a normal inclinada junto, a
  luz faz o anel e a beira sai recortada. Pontos espalhados deixam furos: passo menor que o pixel, descarte da parede
  de dentro e um tapa-furos.
- **Foto de referência mostra a forma; a proporção é a do jogo.** Seguindo a foto do plug, engrossei o cotovelo e o
  fio, e o usuário corrigiu: "não segue o que mostra na gameplay". Na versão de perto de uma peça do jogo, as medidas
  são as dela em escala (`Switchboard.ELBOW_*`, `JACK_RINGS`, a largura do fio); da foto, só o feitio (a mola, o
  colarinho). Compare a captura de perto com uma do jogo lado a lado antes de mostrar.
  O mesmo vale para o texto: no painel de perto deixei as legendas na fonte de 11 enquanto o resto ia a 3×, e a
  chapa do banco com a letra e o aviso num canto; o usuário notou as duas. Ampliou a peça, amplie as letras e mantenha
  a disposição dela (a fonte em dobro com relevo, `PixelArt.big`, é o tamanho das miúdas da mesa em 3×).
  E use as mesmas peças: na chapa do banco troquei a letra estampada (`PLATE_LETTERS`) e o estêncil (`PixelArt.tiny`)
  pela fonte do jogo, e "ainda não condiz". Peça com desenho próprio no jogo vai de perto com aquele desenho ampliado.

## Pergunta ao usuário se lê sozinha
No relato do passo 3 do roteiro, listei as dúvidas que ainda faltavam só pelo número que elas tinham numa análise
antiga ("0 · 1 · 3 · 5 · 7–9 · 13–25"), com um resumo de três palavras; o usuário: "não entendi absolutamente nada
dessa tabela de dúvidas. O que são esses números?". Ele não guarda a numeração de mensagens passadas. Cada pergunta
vai escrita inteira, com o contexto e uma sugestão, e só as que importam para o próximo passo; numeração, só a da
própria mensagem.

## Antes de perguntar, jogue a cena de cabeça
Perguntei se "ignorar as ligações para a delegacia e a Alta Cúpula" (Dia 9) era não atender ou atender e não
transferir; o usuário: "como que o jogador vai descobrir que aquela ligação é da cúpula ou delegacia? Pergunta sem
sentido." O destino só se sabe depois de atender. Antes de mandar uma dúvida de roteiro, siga a ligação na mesa
(toca, atende, ouve o pedido, transfere) e só pergunte o que o jogo de fato deixa em aberto.

## Detalhe pequeno em objeto deitado vai na tela
Pus o lacre da carta no desenho de frente do envelope; a homografia o entortou num losango e o usuário achou
"estranho, não tá esticada". Detalhe de poucos pixels em objeto chato da mesa (lacre, lápis, risco) vai na tela,
deitado (mais largo que alto), no ponto que `_tex_pt` dá, como o `_ink`.

## Nomeie a coisa, não o apelido do plano
Escrevi "a senha do Dia 4 vale das 20:30 às 21h" e o usuário perguntou "a senha só vale por trinta minutos? Como
assim?"; depois: "você não deixou claro que senha seria". Era a regra que ele mesmo tinha dado (a ligação ao hotel
com "A semente brotou"), mas "a senha" soava como o código da B3 do bilhete. Ao citar uma regra do roteiro, diga a
cena inteira: quem liga para onde, o que diz e o que conta.

## Cena da rua nasce na regra de qualidade
Fiz a bandeira da noite 15 como silhueta andando e um retângulo descendo e mostrei as capturas; o usuário: "como eu
já tinha falado e especificado antes, as animações e detalhes dos eventos precisam ser bons". Toda cena nova na vista
(evento do roteiro ou não) segue o `PLANO_RUA.md`, seção 1, desde a primeira versão: rig ou figura com poses
suavizadas, objeto com peso (cai, quica, assenta), detalhe e luz do lugar, chuva e névoa, som. Leia a seção antes de
desenhar.


## Distância antes de desculpa de escala
Disse que o homem na varanda não comportava detalhe por ser pequeno; o usuário: "por que não dá pra colocar detalhes?
Na prática, ele está na mesma distância das pessoas que andam na rua". Antes de alegar limite de escala, compare o `z`
com o de quem já é desenhado com detalhe ali perto; o que apagava o detalhe era a contraluz forte que eu pus.


## O que o usuário já decidiu não volta como pergunta
Deixei o relatório do supervisor no fim da noite 16 e perguntei se estava bom; o usuário: "Não tem relatório, já
falei isso. Após o epílogo seriam os créditos basicamente". Antes de listar dúvidas, procure a resposta no
`HISTORICO.md` e no `PLANO_ROTEIRO.md`; o que já foi dito vira código, não pergunta.

## Figura pequena na vista: conferir a cor final na captura, pixel a pixel
O homem de sobretudo saiu "marrom" duas vezes: a luz do contorno do rig (`_draw_pixels`) acende as beiras de cima e do
lado, e numa figura de 3–4 px quase todo pixel é beira; e a gradação da noite clareia os escuros (um `2c2b2d` vira
`3a3a3d`). Figura pequena que tem de parecer preta: sem contorno (`rim`) e cor bem escura no `Pal`, conferida no
valor do pixel da captura, não só no olho. Desenho próprio com retângulos em metros (o antigo) flutuava e não tinha
rosto: pessoa na rua é sempre o rig de quem passa.

## Quem tem nome tem a voz da pessoa, e lugar tomado fecha
A Morgana saiu com a voz "w" (homem velho) porque a voz do contato foi escrita sem conferir quem é; e as centrais dos
setores continuavam atendendo depois que o setor passou à Maria. Pelo modelo físico: setor entregue é central fechada,
sem ninguém do outro lado. Ao criar contato com nome, confira a voz pelo sexo e pela idade; ao mudar quem atende um
setor, feche o que ficou para trás (`gone_from`).

## Sugestão de design: resolver o problema, não criar sistema
Pedido "sugira desculpas e consequências", propus conferir a desculpa com a noite, mentira descoberta depois, contador
de suspeita em degraus e cobranças em seis noites. O usuário recusou: "vai só adicionar mais coisa no jogo sendo que
podemos simplificar o que de fato é problema". Antes de sugerir mecânica, diga qual problema ela resolve e proponha o
menor ajuste no que já existe; sistema novo só se ele pedir.

## Final que vira variação: procure todo `requires` do final que absorveu
Ao fundir a vitória amarga no sucesso (`custou_gente`), troquei os `requires` do epílogo, mas o fecho da noite 15
("Amanhece", o encontro com Sebastião) pedia só `final_sucesso` e passou a valer também na amarga, que não tem
encontro. Quem ganha um marcador a mais herda tudo o que pedia só aquele marcador: ao fundir dois estados, procure
(`grep`) cada `requires` do que ficou, em todas as noites, não só nos arquivos do que saiu.
