---
name: revisar-mudancas
description: Revisão rápida de boas práticas e desempenho APENAS no código alterado do jogo (o git diff ainda não commitado, ou desde um commit dado). Use quando o usuário pedir commit das mudanças (sempre antes de commitar) ou pedir explicitamente para revisar ou validar as mudanças. Não use depois de cada mudança.
---

# Revisar as mudanças

**Quando:** só quando o usuário pede commit (a revisão vem antes dele) ou pede uma revisão. Não rode por conta própria
depois de cada mudança.

Uma passada curta, só no que mudou: nada de auditar o resto do projeto. O código em volta serve apenas para entender
a mudança; apontamento fora das linhas alteradas não entra.

## 1. O que mudou

```sh
git status --short
git diff HEAD --stat
```

Com o usuário pedindo desde um commit (ex.: "nesta branch"), use esse commit como base. Arquivos `.gd` novos, ainda
fora do git, também contam. Sem nada alterado, diga isso e pare.

## 2. Verificações mecânicas

```sh
sh .claude/skills/revisar-mudancas/check.sh [base]
```

Só olha as linhas acrescentadas e aponta o que as convenções já proíbem, inclusive o desempenho:

- `draw_polygon` em vez de `draw_primitive`;
- `queue_redraw` ou procura na árvore no `_process`;
- imagem montada a cada quadro ou desenho;
- SubViewport em `UPDATE_ALWAYS`;
- tarefa em thread em prioridade baixa;
- cor escrita direto (`Color("…")`) fora do `Pal`;
- `PointLight2D` (ou outra luz do Godot) no lugar dos shaders da luz.

É um filtro grosso: confira cada apontamento no código antes de repassar (um `draw_polygon` com textura, ou um
`queue_redraw` depois de comparar o estado, são legítimos).

Depois, os testes rápidos (~30 s), sempre, antes de qualquer commit:

```sh
tests/run.sh content training flow
```

Falhou: não commite; conserte (ou relate, se não for da mudança). Um teste quebrado já entrou num commit por faltar
este passo. Mudança em agenda, ritmo, fim de ligação, mesa ou cabos: rode a suíte inteira (`tests/run.sh`, ~2 min).

## 3. Leitura do diff

Leia `git diff HEAD` (ou desde a base) e, só nas linhas alteradas, confira o que pede julgamento. As regras vêm do
`CLAUDE.md` (o da raiz e o `scripts/ui/CLAUDE.md`; o detalhe em `docs/mapa-*.md`, por `grep`) e do `LESSONS.md`; na dúvida, eles valem mais que esta lista.

**Desempenho** (a análise de 10/2026 achou engasgos de ~20 ms 3 a 4 vezes por segundo; ver o item 84 do
`HISTORICO.md`):

- **Redesenho.** Quem desenha só redesenha quando o que mostra muda: o estado comparado no `_process`
  (`Background._state`, o da camada `_over`, o `_back_state` da vista, o `_look` da mesa). O que muda sozinho (tempo,
  piscar, animação) não pode morar num desenho grande. Use uma camada própria, a textura atualizada no lugar
  (`ImageTexture.update`, como a frente do relógio) ou o `modulate`. Coisa nova que muda tem que entrar no estado
  certo; posta no lugar errado, redesenha demais.
- **Chamadas de desenho.** Área cheia em `draw_primitive` (no cenário, `_fill`/`_poly`): cada `draw_polygon` é uma
  chamada e cria um polígono a cada redesenho. Grade de cores: calcule cada vértice uma vez, não por célula.
- **Por quadro.** Nada pesado em `_process` ou no `_draw` de algo que redesenha sempre: alocar imagens ou arrays
  grandes, procurar na árvore, laços longos. Imagem montada pixel a pixel fica guardada por tamanho e estado.
- **Caches.** Todo `static var` de cache tem limite (ou chave que não cresce sem fim).
- **SubViewport** em `UPDATE_ONCE` quando o conteúdo não muda sempre (como o `Background._show`).
- **Threads.** `WorkerThreadPool` em alta prioridade se alguém espera; em baixa, ela usa só ~30% dos núcleos. O
  `randf` global não é seguro entre threads: cada uma com o seu `RandomNumberGenerator`.
- **Sem tela.** O que roda a cada quadro também pesa nos testes (o turno do robô leva ~9–10 s).

**Desenho:**

- Cor que muda a cada quadro vai no `modulate`, nunca nas cores de um `PixelArt.disc`/`art` (o cache não esvazia).
- Cores e materiais no `Pal`. Fonte só em múltiplos de 11.
- Interface em cena, com Containers, e variação de tema em vez de override por nó.

**Tipos e GDScript:**

- Valor sem tipo (`Dictionary`, ternário com Variant) declarado com tipo explícito, não `:=`.
- Dicionário usado como chave não pode ser mudado depois.
- Ao percorrer `live` podendo encerrar ligações, percorra `live.duplicate()`.

**Jogo:**

- Todo `create_timer` com `false`; quem precisa rodar na pausa tem `process_mode` próprio.
- Volume só por `Sfx.fade`/`_tween`.
- Toda espera da agenda tem limite.

**Textos:**

- Interface por `T.text(T.Key.X)`; falas e conteúdo nos Resources (`data/`), nada de fala no código.
- Texto novo pede `tools/update_translations.gd`.
- Nomes na ordem natural.

**Estilo e documentação:**

- Comentários e documentação (`##`) em português, na densidade do arquivo.
- Código enxuto, sem código morto, `print` de depuração ou testes temporários (`tests/test_zz_*`) esquecidos.
- Atalho deliberado com comentário `ponytail:`.
- Mudança de comportamento ou de convenção registrada no `CLAUDE.md` (e no `HISTORICO.md`, quando foi pedido do usuário).

## 4. Medir (só quando a mudança mexe em desenho ou em algo que roda a cada quadro)

Mudou um `_draw`, um `_process`, o estado de redesenho, a vista da janela, a mesa comutadora, o `Bloom` ou um
SubViewport? Meça uma vez, com tela (fecha sozinho em ~40 s; os últimos cenários são o amanhecer da última noite):

```sh
cp .claude/skills/revisar-mudancas/medir.gd tests/test_zz_medir.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . tests/runner.tscn -- --test=zz_medir --seed=1
rm -f tests/test_zz_medir.gd tests/test_zz_medir.gd.uid
```

Referência neste Mac (10/2026, depois do plano hi-bit; os números variam de uma medição para outra, ±1 ms):

(26/10/2026: o mesmo commit mede ~7 ms de média, também na versão 0.6.0, e as chamadas do último quadro saem ~235 numa
execução e ~740 na outra, sem mudar ao esconder o jogo inteiro: compare sempre com a versão anterior medida na mesma
hora, e as chamadas só entre execuções que deram o mesmo patamar.)

- **Quadro:** 2–4 ms em média; o pior 1% até ~10 ms e uns poucos quadros acima de 8 ms, nenhum acima de 16 ms
  (o sol a 8× pode dar um).
- **Chamadas de desenho:** ~380 quando o cenário não se redesenha; ~400–450 abrindo uma ferramenta; no amanhecer
  ~380–1000 (o céu em degradê, os fiapos de nuvem e os raios).
- **Parado:**
  - a sala 0 vezes por segundo;
  - a camada de cima 0–1;
  - a vista ~30;
  - o fundo da vista ~3 (~11 na noite limpa, pelas estrelas).
- **Relâmpago ou papel deslizando:** a camada de cima ~40–55 por segundo, sem a sala.
- **Amanhecer:** a camada do sol (`sol`) ~2 por segundo parada e ~11 com o sol a 8×; a sala não se redesenha.

Chamadas na casa dos milhares: procure primitivos seguidos com número de pontos diferente (o lote só junta os
iguais) ou uma troca de transformação dentro de um laço; esconda uma camada por vez para achar qual.

Bem pior que isso: aponte com os números. Na dúvida se a piora é da mudança, meça a versão anterior (`git stash`,
medir, `git stash pop`).

## 5. Relato e commit

Em português e curto, para o usuário:

- Cada apontamento numa linha: `arquivo:linha`, o problema e o porquê, do mais grave para o menos.
- Erro claro da própria mudança (um `create_timer` sem `false`, um `print` esquecido): corrija e diga que corrigiu.
- O que for escolha de design ou mexer em comportamento: só aponte e pergunte antes de commitar.
- Sem nada a apontar (ou depois das correções claras) e com os testes passando: siga com o commit pedido, no padrão do `CLAUDE.md`.
  Diga "Revisão das mudanças: nada a apontar" e quantos arquivos foram vistos.
