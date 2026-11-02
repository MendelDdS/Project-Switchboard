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
   dá o número no fim do treinamento), que atende até a noite 7 (a Morgana até a 4: na 5 o Centro passa à Maria), larga o setor na 8 (toca e ninguém atende) e some da
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
   com Sebastião num texto na tela preta, `Night.endings`), fracasso e presa. Três finais só: a vitória amarga é uma
   variação do sucesso no epílogo (`custou_gente`, `Rebellion.costly`: venceu com a fita das armas, do grupo C ou dos
   grupos entregue, ou com a paróquia esquecida; muda quem liga, o jornal e o fecho), e a esquecida, se vier, será uma
   variação do fracasso (falhou e desobedeceu alguma vez: a cúpula liga
   à meia-noite, e no lugar do relatório a cena `Arrest`, o homem de sobretudo e a viatura com dois policiais vindo
   para a central). O epílogo, a noite 16 jogável (`GameContent.epilogue`, fora das 15): Sebastião no sucesso, a mãe
   da Cecília com o golpe vencido, a cúpula no fracasso e a carta do supervisor na mesa no fracasso; o fecho na tela
   com "Fim", os créditos e a volta ao menu, sem relatório. A mãe da Cecília liga em todos os finais, com uma
   conversa por final. Presa: o golpe falhou e ela cortou mais pedidos das autoridades do que atendeu. Ligações do
   roteiro depois das 23:40 ainda tocam (`Main._story_late`); as conversas do roteiro são ligação comum no caderno.
   Burocracias até a 15.
10. **Noites 14 e 15 feitas, falta testar.** Na 14: Sebastião às 18:20 conta a versão dele (não pede mais fitas: o
    pedido é só o do Dia 12, que não se repete); a polícia (184) fala do cerco ao aeroporto e à ferrovia e do hotel lacrado e do bar
    fechado amanhã; a Cúpula (296), do ministro levado ao Centro e tirado de avião e do armazém do comandante; bar e hotel marcados para gravar (entregues: `obedeceu_*_14`);
    rádio e TV bloqueadas (`b2_radio_tv.tres`, 14 e 15); o hotel apagado a noite toda (`StreetEvent` "closed"). Na
    15: a carta (as três ordens); cinco pedidos das autoridades para a delegacia e a Cúpula (`authority`: transferida
    e ouvida até o fim, `obedeceu_<rua>_15`; cortada, recusada ou deixada tocando, `desobedeceu_`); bar e hotel
    (`ligou_suspeito_15`) e a denúncia pelo discador na delegacia; rádio e TV transferidas, `desobedeceu_`; das 21h às
    22h, "Começou." à Casa Paroquial (120) e ao Armazém Ferreira (288); das 22h às 22:30, a "Canção da Madrugada" à
    rádio (390); com o golpe vencido, o bar à meia-noite com a mensagem de liberdade. Ordem de Sebastião não cumprida:
    um vacilo (`Rebellion.ORDERS`; as da 15 contam à meia-noite).
11. **Noites 1 a 13 feitas, falta testar.** Ligações do roteiro (`data/calls/story_0*`, `story_1[0-3]_*`), discador e
    jornal por marcador, geradas fiéis ao documento: 1 o homem sério pede o bar e agradece pelo nome; 2 três tentativas
    (`bar_2`; o "se perguntado" é a fala do repetir); 3 a Cecília avisa e, às 21h, manda ligar para o bar, onde ele dá
    a senha (`sabe_senha_3`, que o hotel do Dia 4 exige); 4 a denúncia pelo discador na delegacia (a ligação do roteiro
    atende fora dos setores, `Dialing`) e três ligações da cidade em pânico; 5 a Cecília dá o nome e ele conta dos pais
    (só com `senha_hotel_4` sem denúncia; liga `sebastiao_5`, também se ela não atender: na 8 ele não diz que sumiu), jornal dos atentados e da TV; 6 o acordo B2 (bar com os
    estalos vai para o hotel) e duas ligações com o sinal; 7 avisar o bar pelo discador (`avisou_bar_7`) e as três
    conversas (rádio, armas, grupo C) em duas versões; 8 Sebastião (o hospital, `hospital_8`), a volta dele, o bar, o
    hotel avisado ou não (grupos e comandante; com `fita_armas_entregue` o armazém caiu e o grupo espera na casa do Joaquim Ferreira, 291, também na 14, na 15 e no "Começou." da carta, versões `_armas`); convites: o recado da 4 pede denunciar pelo 184, Sebastião pede avisar o bar e o hotel no acordo da 6 e na 8, a carta da 15 manda ligar para o bar à meia-noite; 9 ignorar delegacia e Cúpula (três pedidos das autoridades desligam
    `cumpriu_9`; as ligações das 22:05 e 22:30 têm a versão da tomada caída, `_caiu`, pelo marcador `tomada_caiu`); 10 a Cecília vai embora e a paróquia (`paroquia_10`); 11 a raiva dele sem a paróquia e o jornal das
    crianças; 12 as duas conversas com a Cúpula para gravar e dar a ele; 13 o bilhete da morte da Cecília; 14 a versão
    dele. Emergências dos ataques nos Dias 4 e 9 (quatro cada, no lugar das sorteadas); a cobrança do supervisor no Dia 12
    (com `cumpriu_9`, sem respostas: advertência média, `StoryFlags.FAULT`). A Morgana fecha na 5 (o setor 1 é da
    Maria). O robô dos caminhos (`test_shift --path=`, `tools/caminhos.sh`) joga as 15 noites em sequência por final (sucesso, amarga, que é o sucesso com `custou_gente`, presa, fracasso: disca, grava e entrega as fitas, corta ou obedece) e confere o final de cada um.
12. Os roteiros secundários (do documento do usuário, 02/11/2026; não mexem no fator sucesso), feitos:
    - **Miguel** (o menino, voz `k`): trotes de verdade na 1 e na 3 (`PrankCall.prank`: o caderno registra como trote);
      na 3 o sobrenome inventado liga `miguel_amigo` (entrar na brincadeira) ou não (exigir o nome); depois, conversas
      na 6, 7, 8, 12 e 14 com versão simpática e seca pelo `miguel_amigo` (desligar na cara desliga, `if_hung_up`); o
      nome dela (`miguel_maria`, na 6), o irmão com os rebeldes (`miguel_irmao`, na 8), o gesso (`miguel_gesso`, na
      12), o irmão preso na 14 com `fita_grupo_c_entregue`; a 9 é a mãe com o filho atropelado (emergência das 21:25,
      no lugar da moça, `story_09_mae_atropelado`, sem dizer o nome); a 10 sem ele; no epílogo, pelo final e pela fita.
    - **Otávio e Generosa**: a música deles é "Luar da Serra" (a da 15 continua a proibida); 2 ele pede a Rádio Serena
      (390); 3 ela deixa o número (384, linha nova, fora da lista; `generosa_3`) e ele pergunta: passar (`otavio_numero`)
      ou mentir (`otavio_mentira`); 5 o conselho do cinema ou a segunda dedicatória; 6 o cinema ou a tristeza; 8 ela
      pede o Otávio (agora 361, Rua da Estação, setor 3; a Funerária Paz Eterna foi para o 253 para a lista seguir com
      12 por setor) e conta do beijo, os ramos se juntam; 10 ela pergunta, o operador disca o São Lucas (213, `D_otavio`,
      a Joana lembra da voz com `hospital_8`, `otavio_achado`) e conta na volta dela (`generosa_soube`); 12 a dedicatória
      dela; epílogo: sucesso, a alta; fracasso, o hospital dá ocupado da primeira vez (`TransferCall.busy_line`).
    - Final com o gesso (`End_gesso`, `End_gesso_amarga`): de manhã Maria assina o gesso no São Lucas e encontra Sebastião.

## Dúvidas em aberto

- (Respondida: a fita mínima conta só a dada às autoridades; uma dada a Sebastião não livra da advertência.)
