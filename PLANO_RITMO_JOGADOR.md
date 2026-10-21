# Plano: o ritmo de quem joga (respostas, mapa e emergências)

Origem: a partida cronometrada do usuário na noite 9, semente 1 (21/10/2026), comparada com o robô do `test_shift --human`
(`HISTORICO.md`, itens 317 e 318). O cronômetro do `DebugPanel` (`_time_calls`) grava os passos de cada ligação no
`user://logs/godot.log`.

## 1. O que a partida mostrou

Emergências (barra de agravamento corrida, em s; limite do estágio inicial 40 s nas duas):

| | mapa marcado | impresso | ocorrência | unidades | fim do relato | enviado |
|---|---|---|---|---|---|---|
| 1ª (20:01) | 11 | 13 | 14 | 16 | 16 | 18 |
| 2ª (22:17) | 31 | 33 | 35 | 37 | 38 | 39 |
| robô `--human` | 29 | 31–34 | 34–39 | 34–39 | 19 | 40 |

- O jogador começa o cartão antes do fim do relato; do mapa ao envio leva 7–8 s (o robô, 11 s).
- O que pesa é **achar a rua**: 31 s na 2ª emergência (a Rua Tiradentes), a 1 s do limite. Com o limite de 35 s (15
  das 40 emergências) ela teria piorado.
- Um clique na rua vertical marcou a horizontal: um cartão triturado.
- Transferências: do pedido ao Transferir, 11–17 s, igual ao robô; o grosso é procurar o número (pedido → cabo na saída).
- Informação: 14–16 s nas primeiras, 2–6 s depois (aprendizado).
- Os botões de resposta longos atrasam a leitura e, com a oferta da alternativa, **quebram a tela** (imagem do usuário:
  a tela inteira empurrada para a esquerda).

## 2. Diagnóstico

- **A tela quebrando**: o botão de resposta não quebra linha (`PhonePanel._render_choices`) e exige a largura do texto
  inteiro. As falas do operador têm até 42 caracteres e as perguntas da emergência até 39, mas as ofertas da
  alternativa (`TransferCall.alt_ask`, 8 ligações) têm 58 a 79: o botão passa da largura do painel e empurra a tela.
- **O clique na rua errada**: `CityMap._find_seg` escolhe a rua mais perto medindo o trecho inteiro; no cruzamento as
  duas empatam e vence a primeira da lista. E o clique é recalculado ao soltar o botão, não usa a rua destacada.
- **Achar a rua**: com os três bairros, a escala do mapa fica abaixo de `NAMES_K` e só os nomes dos bairros aparecem;
  nenhuma rua tem nome à vista. Achar uma rua é passar o mouse por cada uma ou aproximar com a roda (que nada anuncia).
  Marcar o mapa sozinho pelo endereço já foi descartado (`HISTORICO.md`, item 22: tira o desafio).

## 3. Plano

### A. A tela não quebra (feito)
Nenhum botão de resposta alarga o painel: o que não couber quebra em duas linhas. O `test_layout` confere que a
resposta mais longa do jogo cabe.

### B. Botões curtos (feito: o quadro abaixo é a proposta; ficou "[Oferecer outro lugar]" para a alternativa)
O botão mostra a intenção; o operador continua dizendo a frase inteira na conversa.

| Hoje | Botão |
|---|---|
| Pode repetir, por favor? | Repetir |
| Um momento, vou conectar. | Conectar |
| A Casa Paroquial não atende. Quer que eu tente a secretaria da Igreja Matriz? | Tentar Igreja Matriz (secretaria) |
| Fique na linha, vou enviar ajuda. | Enviar ajuda |
| E aí, como vai a noite? | Puxar conversa |

O rótulo da alternativa sai do nome da lista telefônica (o roteiro não muda). As perguntas da emergência e as
respostas da conversa fiada são do roteiro e já curtas (mediana 20 caracteres): ficam.

### C. O clique certo no mapa (feito)
Os cruzamentos continuam clicáveis (tirar o clique deles foi recusado). No cruzamento, a rua que o mouse vinha seguindo continua destacada até ele sair
dela (as duas empatam ali); e o clique marca a rua destacada, não a recalculada ao soltar. Corrigir sem triturar: F3.

### D. Achar a rua (feito)
1. **Grade e índice de ruas**: testado e descartado (o índice cobria ruas e só repetia os nomes).
2. **Nomes das ruas à vista onde couberem** (feito: as 14 com nome desde o mapa afastado).
3. Aproximar sem a roda: F4.

### F. O mapa, depois dos nomes à vista
1. **Lugares de referência no mapa afastado (feito).** 40% das emergências de molde dão a rua e um lugar
   ("Rua do Sol, perto do posto"; `LANDMARK_CHANCE`), e na noite 9 nenhum nome de lugar cabe no telhado. Passando o
   mouse num prédio de referência, a etiqueta diz o nome dele, como nas ruas.
2. **Onde fica o número (feito).** A numeração dos trechos só aparecia bem aproximado, e os trechos não
   coincidem com os cruzamentos. Passando o mouse numa rua, ela inteira fica destacada (mais fraco) e aparece a
   numeração de cada trecho. Junto: o realce amarelo do trecho sumia embaixo do nome da rua.
3. **Corrigir o local sem triturar (feito).** O primeiro clique só datilografa o local na tira da impressora e marca
   o trecho vazado; outra rua troca o local; o segundo clique no mesmo trecho imprime. O aviso "clique de novo para
   imprimir" pisca na impressora e aparece na etiqueta do trecho.
4. **Aproximar sem a roda (feito).** Um anel de aproximar na moldura da direita, como o de uma leitora de microfilme:
   arrastar para cima aproxima, a roda também gira, e o + e o − em cima e embaixo dele dão um degrau por clique.

### E. Medir de novo
Outra partida cronometrada da noite 9; só então decidir se os limites do estágio inicial (35/40/45 s, `stage_sec`)
sobem. Se o robô `--human` ficar para trás do jogador, ele passa a começar o cartão quando ouve o endereço.
