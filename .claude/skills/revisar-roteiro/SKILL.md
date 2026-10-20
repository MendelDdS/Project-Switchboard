---
name: revisar-roteiro
description: Revisão de continuidade do roteiro que o usuário escreveu (noites, ligações do roteiro, a desconhecida, conversas, marcadores) - aponta incoerências, nunca escreve falas. Use SÓ quando o usuário pedir para revisar o roteiro, a continuidade ou uma noite; não use depois de mexer em data/ por conta própria.
---

# Revisar o roteiro

O roteiro é do usuário: esta revisão **só aponta**. Não escreve fala, não sugere fala pronta, não edita `data/`. Se
uma correção pedir texto novo, diga o que está incoerente e deixe a escrita com ele.

## 1. O que revisar

O que o usuário pedir (uma noite, um trecho, "tudo até a noite N"). Sem dizer, pergunte qual. Para cada noite,
leia `data/nights/night_NN.tres` inteiro e o que ela referencia (`ExtResource`: as ligações do roteiro em
`data/calls/story_*`, a desconhecida em `mystery`, `smalltalk`), e as noites **anteriores** só no que a noite
pedida usa (marcadores, fatos, pessoas). Os contatos citados: `data/directory/` (nome, endereço, `note`, motivos).

O mecânico já tem teste: rode `tests/run.sh content` antes (lacunas, traduções, marcador que ninguém liga) e não
repita o que ele já pega.

Os marcadores, de uma vez:

    grep -rn "requires\|sets\|overheard_flags" data | grep -v '= PackedStringArray()$'

e os que o código liga sozinho: `grep -rn 'flags.apply("' scripts` (`escutou_N`, `ligou_de_volta_N`,
`desligou_desconhecida_N`, `denunciado_N`: N é a noite).

## 2. O que procurar

- **Fatos entre noites**: nome, parentesco, endereço, número, profissão ou o que uma pessoa sabe mudando de uma
  noite para outra sem motivo; alguém citando o que ainda não aconteceu ou o que só o jogador ouviu escutando.
- **Ramos do roteiro**: um `requires` que nunca pode valer naquela noite (o marcador só é ligado depois, ou dois
  pedidos que se excluem); uma escolha que liga um marcador que nada usa (pode ser de propósito: pergunte); a fala de
  um ramo que contradiz a do outro quando os dois podem acontecer na mesma noite.
- **A desconhecida**: o que ela diz bate com o que o jogador fez nas noites anteriores (`desligou_desconhecida_N`,
  `ligou_de_volta_N`)? Uma fala que pressupõe uma resposta que o jogador pode não ter dado.
- **Época e lugar**: São Sotero em 1973 (`GameData.START`). Nada de coisa fora da época (objeto, gíria, serviço);
  lugares e ruas que existem na lista (`data/directory/`) e no mapa.
- **As regras de escrita** do `CLAUDE.md` (nomes na ordem natural, a `note` só quando o nome não diz quem atende) e
  do `README.md` (as conversas escutadas não dizem o tipo do lugar com alternativa).
- **Voz das pessoas**: alguém falando de um jeito muito diferente do que falou antes (tratamento, "o senhor"/"você"),
  quando não há motivo na história.

## 3. Como entregar

Uma lista curta, por noite, do mais grave ao menos grave. Cada item: o arquivo e o campo (ou a linha), a fala
citada, com o que ela conflita (a outra fala citada, com o arquivo) e por quê, numa frase. O que for dúvida (pode
ser intencional) vai separado, como pergunta. Sem nada a apontar, diga isso.
