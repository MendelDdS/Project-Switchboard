# Plano: o conceito do turno

O pedido: medir a eficiência do operador em cada noite pelas advertências e pelo que ele fez certo; duas noites abaixo
do nível mínimo e ele é demitido, e o jogo termina para ele. O jogador não vê número: o supervisor dá um **conceito**
carimbado no memorando (Ótimo, Bom, Regular, Insuficiente), como na avaliação de funcionário da época.

Branch: `feature/0000-implement-efficiency`, a partir da `develop`.

## 1. Como é hoje

- **Só os erros contam.** `ShiftReport` guarda as advertências do turno (`FAULTS`: id → gravidade) e o desfecho de cada
  emergência (OK, com atraso, ruim). Nada registra o que deu certo.
- **Demissão por graves acumuladas.** `SEVERE_LIMIT` = 3 graves somadas entre as noites (a gravíssima vale
  `CRITICAL_WEIGHT` = 2), salvas no `Progress.severe`. `ShiftReport.fired()` decide; o `Main.start_ending` apaga o
  progresso e a tela final (`Ending`) mostra "Você foi demitido".
- **O parecer** (`ShiftReport.verdict()`: bom, atenção, ruim; três frases em `content.tres`, `verdicts`) vai à mão no
  memorando e decide se o ritmo da noite seguinte sobe nas três primeiras noites (`Pace.next`: o ruim, 2, repete).
- **O memorando** (`ReportView.show_report`) lista as advertências com o carimbo da gravidade (`_stamp`,
  `SEVERITY_COLORS`), a contagem por gravidade e a linha "Advertências graves acumuladas: N de 3".
- O treinamento (noite 0) não gera advertência nem demite.

## 2. A eficiência (interna)

Uma conta de 0 a 1 por noite, que o jogador nunca vê (só o painel de debug mostra, em porcentagem). Ela decide o
conceito.

```
eficiência = positivos ÷ (positivos + negativos)      (1 sem negativos, também numa noite sem positivos)
```

É a parte "certa" de tudo o que o supervisor anotou, em pontos. Ligação não atendida não dá ponto positivo e ainda dá
a advertência dela: ela pesa dos dois lados, de propósito. Erros que crescem com o volume da noite se comparam igual
entre uma noite calma e uma cheia; **um erro isolado e grande pesa mais numa noite calma** (menos acertos para
diluí-lo). Isso fica, de propósito: a calibração (seção 6) confere que uma grave isolada não derruba o atento na
noite 1; se derrubar, entra uma base fixa somada aos positivos (`SHIFT_BASE`), não antes.

### Pontos negativos: as advertências

Um peso por gravidade (`ShiftReport.POINTS`, ao lado das gravidades):

| Gravidade | Pontos | Advertências de hoje |
|---|---|---|
| Leve | 3 | informação errada, registro errado ou faltando, bilhete sem carimbo ou esquecido, unidade a mais, tipo de ocorrência errado |
| Média | 15 | não atendida, desistiu na espera, número errado, ligação cortada, desligou no fim do turno, faltou unidade, unidade à toa, cartão em branco, situação piorou |
| Grave | 30 | escuta denunciada, endereço errado no despacho, emergência sem despacho, situação crítica |
| Gravíssima | 60 | emergência perdida |

### Pontos positivos: os acertos

Só as **decisões** do operador ganham ponto. As tarefas obrigatórias (registrar a ficha, carimbar e guardar o
bilhete) não: elas já têm a advertência quando faltam, e pagar por elas subiria o piso de todo mundo, aproximando o
desastrado do mínimo.

| Acerto (`ShiftReport.CREDITS`, id) | Pontos | Onde acontece no código |
|---|---|---|
| `transfer`: transferência completada (os dois conversando) | 10 | `Main._try_complete` |
| `trunk`: interurbano completado | 12 | `Main._try_complete`, destino tronco (no lugar do `transfer`) |
| `info`: informação certa | 5 | `Conversation`, `info_ok = 1` |
| `emergency_ok`: emergência resolvida no estágio inicial | 20 | `Supervisor.on_arrived`, `Fleet.Result.OK` |
| `emergency_late`: resolvida com a situação piorando | 10 | idem (a advertência média do estágio já desconta) |
| (resolvida no estágio crítico) | 0 | sem crédito: a grave do estágio já diz tudo |
| `occurrence`: tipo de ocorrência perfurado certo | 3 | `Supervisor.on_arrived` |
| `prank`: trote reconhecido (registrado como trote, sem despacho) | 5 | `Supervisor.on_registered` |

Os créditos ficam numa lista como a das advertências (`credits`: id, hora), para o memorando contar por tipo.
Não contam: o treinamento, a ligação desconhecida, a emergência de treino e a ligação que o debug tira (`Main.drop`).
O retorno de quem não foi atendido (`call_again`) pode dar o crédito da transferência: a advertência da perdida fica,
o crédito é o conserto. É de propósito.

### A escuta denunciada

A denúncia chega no relatório da noite seguinte (`ShiftReport.later`) e **conta na eficiência da noite em que chega**:
é quando a companhia fica sabendo, e o memorando mostra a advertência ali. Assim o conceito nunca cai por um motivo que
o jogador não vê no mesmo papel. Na última noite (sem noite seguinte) ela já entra na de hoje, como hoje.

## 3. O conceito

| Conceito (`ShiftReport.Grade`) | Eficiência | Tinta do carimbo | Frase à mão (`content.tres`, `verdicts`) |
|---|---|---|---|
| Ótimo | 0,90 ou mais | azul-escuro | "Turno exemplar. Continue assim." |
| Bom | 0,75 a 0,90 | grafite | "Bom turno. Atenção aos detalhes." |
| Regular | 0,60 a 0,75 | sépia | "Turno regular. Os moradores contam com a central." |
| Insuficiente | abaixo de 0,60 | vermelho | "Insuficiente. Mais uma noite assim e a companhia vai dispensar seus serviços." |

- Os limites (`GRADE_MIN`) saíram da calibração (seção 6).
- **Piso da catástrofe:** uma gravíssima (emergência perdida) dá Insuficiente, seja qual for a eficiência. Sem isso,
  quem deixa morrer uma emergência por noite a partir da noite 9 passaria sempre (128 ÷ (128 + 63) ≈ 0,67).
- **O conceito substitui o parecer**: `verdict()` sai e `grade()` entra; o `Pace.next` passa a ler o conceito (o
  Insuficiente repete o ritmo, como o ruim de hoje). Uma escala só, em vez de duas.
- A frase à mão é uma por conceito; na segunda noite seguida em Insuficiente (a da demissão), não há frase: vem a tela
  final.

## 4. A demissão

- **Conceito mínimo: Regular**, igual em todas as noites.
- **Duas noites seguidas em Insuficiente** demitem (uma Regular ou melhor no meio zera a contagem). A contagem fica no
  `Progress` (`low_nights`) e a demissão sai no fim da segunda (`ShiftReport.fired()`), com o progresso apagado e a
  tela final, como hoje.
- **Treinamento:** não dá conceito nem conta noite abaixo.
- **Última noite:** Insuficiente nela demite como em qualquer outra, se for a segunda seguida. A tela final da demissão
  vem no lugar do fim normal, depois do relatório, que segue sobre o amanhecer como hoje.
- **Save antigo:** o `Progress` lê `low_nights` com padrão 0 e ignora o `severe` gravado (as graves de antes não
  pesam na regra nova).

## 5. O que o jogador vê

- **No memorando** (`ReportView`), no lugar da linha das graves acumuladas:
  - os **acertos contados**, datilografados, sem pontos, uma linha por tipo que aconteceu ("Ligações completadas: 9",
    "Interurbanos completados: 1", "Informações prestadas: 3", "Emergências atendidas: 2", "Trotes identificados: 1"),
    antes da lista das advertências: o jogador vê o que fez de bom e de ruim e entende o conceito;
  - o **carimbo do conceito**, redondo, no pé do memorando entre o botão de assinar e a rubrica: dois aros (o de
    fora com 2 px, o de dentro com 1), "SÃO SOTERO" curvado em cima e "SUPERVISÃO" embaixo (a fonte miúda em 2×,
    desenrolada em volta do círculo; em 1×, curvada, as letras de 3 px se desfaziam, e o nome da companhia inteiro não
    cabia), a faixa reta atravessando o meio com o conceito em 11 negrito, "★ CONCEITO ★" em cima dela e a data da
    noite embaixo, miúda; na tinta do conceito, com a borracha falhando (sempre igual na mesma noite). Os pixels saem
    de uma imagem montada pixel a pixel (`ReportView._stamp_image`) e o conceito é texto por cima. Reto, sem inclinação:
    inclinado, os pixels sairiam do lugar. Os carimbos da gravidade continuam retangulares;
  - "Conceito mínimo exigido: Regular" e, depois de uma noite Insuficiente, "Noites seguidas com conceito insuficiente: 1 de 2"; na noite da demissão, o parecer é outro (`verdict_fired`).
- **O parecer à mão:** a frase do conceito (tabela da seção 3), com a rubrica, como hoje (feito na etapa 3, com as
  traduções).
- **O bilhete da noite seguinte** (o recado do supervisor na abertura) lembra, depois de uma Insuficiente, que esta
  noite decide (`content.tres`, uma frase somada ao bilhete da noite; não muda os `.tres` das noites).
- **A tela final da demissão** diz o motivo: "Duas noites seguidas com conceito insuficiente."
- **O painel de debug** (F1): a eficiência ao vivo em porcentagem, os positivos e os negativos, o conceito que daria
  agora e um botão para marcar uma noite Insuficiente (para testar a demissão).

## 6. Calibração (feita, etapa 2)

- **O robô foi consertado antes:** ele escolhia sempre a primeira resposta na informação (errava 2 em 3) e registrava
  toda ficha como Comum (emergências e trotes viravam `register_wrong`). Agora dá a informação certa e o tipo certo.
- **Cinco sementes** nas noites 1, 5, 9, 12 e 15, atento (`--human`) e desastrado (`--clumsy`, deixa tocar 1 em 3).
- **Com a média em 8**, o desastrado passava quase sempre (62% a 86%): a não atendida liga de novo e o crédito do
  retorno apagava a advertência. A média foi para 15 e, para manter as proporções, a grave para 30 e a gravíssima
  para 60:

| Jogador | Menor | Mediana | Maior |
|---|---|---|---|
| atento | 67% | 88% | 100% |
| desastrado | 47% | 58% | 77% |

- Limites: Regular a partir de 60% (o atento mais fraco, com uma não atendida e duas emergências agravadas, fica
  em 67%), Bom a partir de 75%, Ótimo a partir de 90% (as noites sem erro e com no máximo uma agravada). O
  desastrado fica em Insuficiente em cerca de 2 de cada 3 noites; como a demissão pede duas seguidas, ele costuma
  cair antes da metade do jogo.
- Uma grave isolada na noite 1 do atento dá 63 ÷ (63 + 30) = 68%, Regular: a `SHIFT_BASE` não foi necessária.
- O `test_shift` imprime a eficiência, o conceito, os acertos e as advertências, e falha se o atento ficar abaixo
  de Regular (o desastrado e o descuidado da escuta, denunciado duas vezes, ficam de fora).

## 7. Onde mexer

| Arquivo | O quê |
|---|---|
| `scripts/model/shift_report.gd` | `POINTS`, `CREDITS` (id → pontos, nome), `credits`, `credit(id, time)`, `positives()`, `negatives()`, `efficiency()`, `enum Grade`, `GRADE_MIN`, `grade()` (com o piso da gravíssima), `low_before`; `fired()` pelo conceito; saem `verdict()`, `SEVERE_LIMIT`, `CRITICAL_WEIGHT`, `severe_before` e `severe_total()` |
| `scripts/supervisor.gd` | `credit(id)` ao lado do `fault` (sem nada no treinamento); os créditos do despacho e do trote |
| `scripts/main.gd` | o crédito da transferência e do interurbano; `start_ending` salva `low_nights` e passa `grade()` ao `Pace.next` |
| `scripts/conversation.gd` | o crédito da informação certa |
| `scripts/data/pace.gd` | `next` lê o conceito (Insuficiente repete) |
| `scripts/model/progress.gd` | `low_nights` no lugar de `severe` |
| `scripts/ui/report_view.gd` | os acertos contados, o carimbo redondo do conceito (`_grade_stamp`, `GRADE_COLORS`), as linhas do mínimo e das noites abaixo |
| `scripts/ui/intro.gd` | o lembrete no bilhete depois de uma Insuficiente |
| `scripts/ui/ending.gd` | o texto da demissão por conceito |
| `scripts/ui/debug_panel.gd` | a eficiência ao vivo, o conceito e o botão |
| `tests/test_shift.gd` | o robô acerta as informações; imprime a eficiência e o conceito |
| `data/content.tres` | as quatro frases dos conceitos e o lembrete do bilhete |
| `translations/ui.csv`, `.po` | as chaves novas (conceitos, acertos, linhas do memorando, demissão), em pt_BR, en e es (`tools/update_translations.gd`) |
| `README.md`, `CLAUDE.md`, `HISTORICO.md` | a regra nova, no lugar da das graves |

Nada de arquivo novo: tudo cabe no que já existe (`ShiftReport` já é o dono das contas do turno).

## 8. Testes

- **`test_penalties`:** a eficiência com acertos e advertências conhecidos (a conta exata); 1 sem advertência; cada
  conceito na sua faixa; a gravíssima dá Insuficiente com eficiência alta; a denúncia de ontem conta hoje; a noite
  Insuficiente conta; duas seguidas demitem e uma Regular no meio zera a contagem; as graves acumuladas não demitem
  mais; o memorando mostra os acertos contados e o carimbo. (O save antigo não ganhou teste: os testes não gravam o
  `user://progress.cfg`, e a leitura é um `get_value` com padrão 0.)
- **`test_shift`:** imprime a eficiência e o conceito e falha se o atento ficar em Insuficiente (o `--clumsy` fica
  como medição, sem falhar); na noite 2 o nível do ritmo sobe para o atento.
- **`test_training`:** o treinamento continua sem advertência, sem crédito, sem conceito e sem demitir.
- Bateria inteira (`tests/run.sh`), três idiomas; captura do memorando (`--screen=report`) nos quatro conceitos.

## 9. Etapas

1. ✅ **O modelo:** pesos, créditos, eficiência e conceito no `ShiftReport`, com o teste da conta. Sem interface.
2. ✅ **Os acertos marcados** nos lugares da tabela; o robô acerta as informações e imprime eficiência e conceito;
   calibração (seção 6) e ajuste dos pesos e dos limites.
3. ✅ **A demissão:** `low_nights` no `Progress`, `fired()` e `grade()`, o `Pace.next`, o fim do turno; testes.
4. ✅ **A interface:** memorando (acertos, carimbo, linhas), frases, bilhete da noite seguinte, tela da demissão e
   painel de debug; traduções.
5. ✅ **Documentação e bateria inteira.**

## 10. Decisões do usuário (19/10/2026)

1. **As duas noites são seguidas**: uma noite Regular ou melhor zera a contagem.
2. **A demissão por 3 graves acumuladas sai**: `SEVERE_LIMIT`, `CRITICAL_WEIGHT` (o peso passa para `POINTS`),
   `severe_before`, `severe_total()`, `Progress.severe` e a linha "graves acumuladas" do memorando são removidos;
   o conceito é a única regra de demissão (com o piso da gravíssima).
3. **O mínimo é fixo** em todas as noites: Regular.
4. **O memorando mostra um conceito carimbado** (Ótimo, Bom, Regular, Insuficiente), não a porcentagem; a eficiência
   fica interna (só no debug). O conceito substitui o parecer bom/atenção/ruim.
5. **Só as decisões dão crédito**: registrar a ficha e guardar o bilhete não.
