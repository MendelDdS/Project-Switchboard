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
6. **Feito.** Fitas: na pilha da mesa, Dar a Sebastião (pacote branco de carta, `StoryCall.if_sebastiao`), Dar às
   autoridades (pacote amarelo com risco azul; vale pontos e liga `if_delivered`) ou Descartar; sem volta (`Tapes.give`).
   A fita da conversa das próprias autoridades entregue a elas: advertência gravíssima (`FAULT_TAPE_AUTHORITY`).
   O turno não encerra com fita sem destino (o Encerrar abre a pilha e avisa); acabado à força, a sem destino fica
   esquecida. Noite com ligação para o bar (327) sem nenhuma gravação às autoridades (vale uma sem nada; a de Sebastião
   não livra): advertência leve (`rule_tapes.gd`, `bar_*`). O bilhete da noite 7 explica (o gravador, o bar liberado,
   a fita mínima e atender às autoridades sem advertência). As duas ligações sem informação para o bar nas noites 7 e
   8 ficam para o conteúdo (passo 10).
7. **Feito.** Obedecer às autoridades é transferir e deixar a conversa acabar: o desfecho da conectada
   (`if_connected`/`if_elsewhere`) espera o fim dela; cortada pelo operador antes, vale `if_dropped`
   (`Main._story_talk_over`). Saiu a ligação desconhecida (falas, agenda, ligar de volta, a noite calada, os detalhes
   da sala que dependiam dela). Dar a Sebastião só na noite em que ele pediu (`Tapes.ASKED` + a noite, que a ligação
   dele liga). A senha do Dia 4: ligar pelo discador para o Hotel Serena (305) das 20:30 às 21h e dizer "A semente
   brotou" liga `senha_hotel_4` (`Night.dial`, `DialCall`); fora disso, o hotel de sempre.
8. **Feito, falta a aprovação.** Na rua: o homem de sobretudo nas noites 13 e 14, das 22h às 22h50, embaixo do poste da
   esquina do prédio de tijolos, fumando (`StreetEvent` "stranger"); a bandeira na varanda do apartamento vazio à
   meia-noite da noite 15, só com `golpe_venceu` (`Banner`; o veredito da meia-noite agora vem antes das cenas da rua).
9. **Feito, falta a aprovação.** Os finais (`Rebellion.final`, à meia-noite da 15, `final_*`): sucesso (o encontro
   com Sebastião num texto na tela preta, `Night.endings`), vitória amarga (venceu com a fita das armas, do grupo C ou
   dos grupos entregue, ou com a paróquia esquecida), fracasso e presa (falhou e desobedeceu alguma vez: a cúpula liga
   à meia-noite, e no lugar do relatório a cena `Arrest`, o homem de sobretudo e a viatura com dois policiais vindo
   para a central). O epílogo, a noite 16 jogável (`GameContent.epilogue`, fora das 15): Sebastião no sucesso, a mãe
   da Cecília com o golpe vencido, a cúpula no fracasso e a carta do supervisor na mesa no fracasso; o fecho na tela
   com "Fim", os créditos e a volta ao menu, sem relatório. A mãe da Cecília liga em todos os finais, com uma
   conversa por final. Presa: o golpe falhou e ela cortou mais pedidos das autoridades do que atendeu. Ligações do
   roteiro depois das 23:40 ainda tocam (`Main._story_late`); as conversas do roteiro são ligação comum no caderno.
   Burocracias até a 15.
10. Conteúdo: as falas de todas as noites (Claude escreve, fiel ao documento), revisadas para a Maria (só alguns do
    setor 3, que a conhecem, a chamam pelo nome); o hotel da história é o Hotel Serena (o do neon) nos textos;
    "avisar o bar" é o do Dia 7 (no Dia 6, Sebastião pede que toda ligação do bar vá para o hotel); traduções.

## Dúvidas em aberto

- Miguel e Generosa (epílogo): o usuário ainda escreve o roteiro deles; não mexem no roteiro principal. O Otávio
  (alta em breve) é o Otávio Almeida (251) da lista.
- (Respondida: a fita mínima conta só a dada às autoridades; uma dada a Sebastião não livra da advertência.)
