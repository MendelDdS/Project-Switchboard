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
- **Ajuste de ritmo tem efeito colateral.** Conversas mais longas prendem cabos por mais tempo e causam falta de
  cabo livre. Meça o efeito (robô) e relate o trade-off junto com a mudança.
- **Quando mudar algo que o usuário não pediu** (ex.: mover o final para 06:00, manter o botão Atender),
  diga explicitamente na resposta.

## Lógica

- **Toda espera na agenda precisa de limite.** A linha 07 só tocava com a mesa em silêncio e as ligações principais
  nunca desistiam: se o jogador deixasse uma tocando, o turno nunca terminava. Solução: `latest` (máx. 30 min de
  espera) e `GIVE_UP_SEC` para as principais. Achado pelo robô, não pelo teste dirigido.
- **Robô que joga o turno inteiro acha bugs que cenários não acham.** Rode alguns turnos completos depois de
  mexer na agenda, no fim de ligação ou nos cabos.
- **Ligações são `Dictionary`: compare com `is_same()`.** `==` compara conteúdo, e `Array.erase` usa `==`;
  remova de `live` por índice com `is_same`.
- **Ao iterar `live` e poder encerrar ligações no meio**, itere sobre `live.duplicate()` (`end_call` remove da lista).
- **Texto que depende do relógio muda enquanto o jogador lê.** A resposta certa de "que horas são" é calculada
  quando as opções são geradas; testes devem tolerar alguns minutos de diferença.

## GDScript / Godot 4.6

- **`:=` falha com valor sem tipo** ("Cannot infer the type of variable"): acesso a `Dictionary`, ternário com
  Variant, retorno de método de objeto sem tipo. Declare o tipo: `var live: bool = ...`, `var cc: int = ...`.
- **Lambda multilinha dentro de literal de dicionário/argumento** é frágil no parser. Atribua a uma variável
  (`var fn := func(): ...`) e depois use.
- **Um `Control` só recebe clique dentro do próprio retângulo.** Para o encaixe do FONE (fora da mesa),
  sobrescreva `_has_point`.
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
  `append_array`. Pelo mesmo motivo, nos testes use `m.sched.clear()` em vez de `m.sched = []`.
- **`ResourceSaver.save` com sub-resources sem caminho embute tudo no arquivo pai.** Para o pai referenciar
  arquivos próprios, salve o filho e use a instância recarregada (`load(caminho)`), que tem `resource_path`.
- **Autoloads não existem quando o Godot compila um script `-s`.** Um teste que declara tipos (`var m: Main`) cujos
  scripts usam o autoload `Sfx` falha com "Identifier not found: Sfx" e o Godot fica parado até o limite de tempo.
  Nos testes, deixe sem tipo o que depende de autoload.
- **Um StyleBox com margem interna muda o tamanho mínimo do container.** O painel de papel com `content_margin` 6
  fez a coluna direita pedir 12 px a mais; o nó raiz (anchors com grow nos dois lados) cresceu e deslocou tudo 6 px.
  Ao migrar para containers, confira `get_combined_minimum_size()` dos nós principais.
- **Containers com `mouse_filter` PASS bloqueiam cliques em irmãos atrás deles.** O encaixe do FONE fica dentro do
  telefone, mas quem trata o clique é a mesa: o telefone e os containers acima do encaixe precisam de IGNORE.
  O mesmo vale para overlays de tela cheia (`Ending`) que ficam visíveis com alfa 0.

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
- **Um assert errado no teste parece bug do jogo.** Antes de mexer no código, confira se a expectativa do teste
  está certa (ex.: contar linhas da transcrição depois de a linha "(Em espera.)" já ter entrado).
