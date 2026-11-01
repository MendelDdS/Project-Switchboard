# Plano: o roteiro de Maria

O roteiro (documento "Roteiro — Planejamento dia a dia (Maria, a telefonista)", 29/10/2026) põe a história nas 16
noites: Maria decide, ligação a ligação, se ajuda a rebelião de Sebastião ou obedece às autoridades. Primeiro o
motor (o que o roteiro precisa e o jogo ainda não faz), depois o conteúdo, com as falas escritas pelo usuário.

## Passos do motor

1. **Feito.** Desfecho das ligações do roteiro: `StoryCall.if_connected` / `if_elsewhere` / `if_dropped` /
   `if_missed` ligam marcadores (`{dest}` vira o número conectado); `again` desligado tira o retorno automático (as
   tentativas ficam no roteiro, como as três do Dia 2). `Main._story_outcome`.
2. **Feito.** Regras ligadas pelas noites do `.tres`: B1 (nome e sobrenome) da 3, B2 (o Bar do Zé, 327, bloqueado)
   na 5 e na 6, B4 (gravador) da 7; nas noites 14 e 15 continuam, e na 15 nenhuma advertência conta. Pedido das
   autoridades (`StoryCall.authority`) sem advertência das regras. O acordo do Dia 6 usa os estalos (B2); só as
   ligações do roteiro vêm marcadas para gravar; fita não entregue: advertência média duas noites depois. A
   demissão continua. Calibrado: igual ao commit anterior fora da noite 15.
   B1: 40% das ligações comuns sem fala do nome só dizem quando pedido (`ask_share`). B3 da noite 10 na delegacia
   (184, plantão, no lugar do Ivo Teixeira), no Hospital São Lucas (213, era a Clínica) e na Alta Cúpula (296, no lugar
   da Rosa Lima); o código da noite vai no bilhete do supervisor. As reações de quem não tem o código ainda são de
   teste (`b3_codigo.tres`, `reactions`).
3. **Feito.** O fator sucesso (`scripts/model/rebellion.gd`, testado caminho a caminho em `tests/test_story.gd`):

   | Fato (marcador) | Pontos |
   |---|---|
   | TV: `senha_hotel_4` sem `denunciou_bar_4` (Dias 2 e 3 perdidos = sem a senha) | +2 |
   | Rádio: `cumpriu_9`, sem a fita da rádio nem a dos grupos, nem armas + grupo C com o hospital esquecido ou o hotel avisado | +2 |
   | Fitas das armas, do grupo C, do comandante; a denúncia; hospital (8) e paróquia (10) esquecidos | −2 cada |
   | Hotel avisado (8); fita do Dia 12 que não chegou a Sebastião | −1 cada |
   | Fita entregue a Sebastião (12) | +1 |
   | Cada pedido das autoridades atendido nas noites 14 e 15 (`obedeceu_<id>`) | −1 cada |

   Nível: alto com 4 ou mais, médio com 2–3, baixo abaixo. Carta do Dia 11 amiga só com alto; pedra (14, 23h) com
   médio ou baixo; o golpe vence (meia-noite da 15) com médio ou alto. Conclusões como marcadores (`tv_conquistada`,
   `radio_conquistada`, `fita_hotel_entregue`, `chance_*`, `golpe_venceu`/`golpe_falhou`). Cenas da rua com
   `requires` (a batida da 13 com `fita_hotel_entregue`); bilhete e jornal com versões (`Night.notes`, `news_if`);
   fita entregue liga marcadores (`StoryCall.if_delivered`); no fracasso, o turno acaba à meia-noite.
4. **Feito.** Cartas na mesa, desde o começo do turno: envelope lacrado em cima do jornal (o lacre vermelho e a dica
   do começo avisam), aberto quando o jogador quiser (`Night.letters`, `letter_for`, `Tools.LETTER`); a de Sebastião
   no Dia 11 em duas versões (amiga com `chance_alta`; ameaça, com o nome de Cristóvão, nas outras).
5. **Feito.** Telefones: as telefonistas das centrais pelo discador (`GameContent.operators`, fora da lista e da mesa;
   os números no rodapé da lista): 001 a Morgana, do Centro (séria, comportada); 002 a Cecília, do Alto da Serra (ela
   dá o número no fim do treinamento), que atende até a noite 7, larga o setor na 8 (toca e ninguém atende) e some da
   9 em diante (o setor passa à Maria; `answers_until`, `gone_from`); 003 é a própria central (ocupado). A TV Orbital
   no 155, no lugar do Geraldo Martins (a ligação do afilhado saiu). No Dia 10 a Cecília liga de outro lugar.
6. Fitas: a gravada vai para a mesa com duas saídas, dar para Sebastião (pacote branco de carta) ou para as
   autoridades (pacote amarelo com um risco azul vertical), resolvidas antes de encerrar o turno; nas noites com
   ligação para o bar, pelo menos uma às autoridades (pode ser de conversa sem informação), senão advertência leve; o
   supervisor explica no dia do gravador. Substitui o "deixar na mesa = entregar".
7. Regras das ligações do roteiro: obedecer às autoridades é transferir (transferir e desligar antes do fim da
   conversa é desobedecer); a senha do Dia 4 vale das 20:30 às 21h; sai a ligação desconhecida.
8. Na rua: o homem de sobretudo nas noites 13 e 14 (22h–23h, em frente ao prédio de tijolos; o homem do mistério
   reaproveitado) e a bandeira na varanda à meia-noite da noite 15.
9. Os finais: sucesso (o encontro com Sebastião num texto na tela preta), fracasso, vitória amarga e presa; o epílogo,
   uma noite 16 jogável, com a carta do supervisor na mesa no fracasso.
10. Conteúdo: as falas de todas as noites (Claude escreve, fiel ao documento), revisadas para a Maria (só alguns do
    setor 3, que a conhecem, a chamam pelo nome); o hotel da história é o Hotel Serena (o do neon) nos textos;
    "avisar o bar" é o do Dia 7 (no Dia 6, Sebastião pede que toda ligação do bar vá para o hotel); traduções.

## Dúvidas em aberto

- Miguel e Generosa (epílogo): o usuário ainda escreve o roteiro deles; não mexem no roteiro principal.
- O Otávio do epílogo é o Otávio Almeida (251) da lista?
- (Respondida: a fita mínima conta só a dada às autoridades; uma dada a Sebastião não livra da advertência.)
