# Histórico das decisões de design

O que o usuário pediu, em ordem (antes no `CLAUDE.md`). Acrescente cada pedido novo no fim.

1. Mesa com entradas + destinos; cabos limitados; desmontar conexões encerradas.
2. Teclado de discagem removido; ligações simultâneas; caderno em fila; mais variedade de conversas.
3. Menos simultaneidade (extras espaçadas, pico raro).
4. Conversas conectadas mais longas (45–90 min de jogo).
5. Modelo de cabos refeito: pares com chaves FALAR/TOCAR foram **substituídos** por FONE + saídas + cabos de
   conexão + botão Transferir (o usuário considera o vermelho "o cabo do fone"; depois o FONE passou a branco, depois a verde, e os
   cabos de conexão a vermelho/azul/amarelo).
6. Ligações continuam depois da linha 07; linha 07 em horário aleatório após 02:00; final às 06:00;
   clique devolve o plug à base com animação.
7. Reestruturação para a versão definitiva (branch `refactor/definitive`): testes no projeto, semente fixa,
   conteúdo em Resources, `PhoneCall`/`Exchange` tipados, interface em cenas com Containers e tema, autoload
   `Sfx` com barramentos, Input Map e `tr()`.
8. Anotação "NÃO ATENDER NOVAMENTE" removida (o mistério será roteirizado depois); a ligação desconhecida vem
   de qualquer entrada, não só da 07.
9. Mais roteiros escritos e conversas híbridas: moldes com lacunas (nomes em inglês) para extras e emergência.
10. Consequências + relatório do supervisor no fim do turno, pensado para as próximas noites. Despacho errado: a pessoa
    agradece na hora, o rádio diz que não havia nada e as unidades voltam; ela liga de novo dizendo que piorou e,
    em alguns casos, dá para despachar de novo (a advertência fica).
11. Turno passou a ser 18:00–00:00 (desconhecida entre 22:00 e 23:30; extras 4–6). Número errado com o FONE fora:
    não completa; foi engano, os dois desligam e o solicitante liga de novo pedindo o certo. Clique que mexe
    uns pixels conta como clique.
12. Sons: campainha antiga (martelinho + ressonadores de metal; depois trocada por bipes suaves, jogadores acharam irritante) e "tuuuu" (o filtro de caixa oca foi testado e removido a pedido do usuário), chuva e grilos (chirps + trilos) refeitos. Clima sorteado por
    noite: chuva (só chuva), névoa (grilos), limpo (brisa e grilos). A coruja que havia foi removida a pedido do usuário.
13. Rádio mais largo e alto (3 linhas); abas 24 px mais baixas (mapa se ajusta à altura). Silhueta na janela
    `SHADOW_LEAD` (15 min) antes da ligação desconhecida (`Background.shadow`), sai `SHADOW_LEAVE` (10 min) antes
    (foi ligar); segue o horário sorteado (`myst_plan`), mesmo que a ligação atrase.
14. Ligações demais ao mesmo tempo depois do turno de 6 h: relógio a 0,75 min/s (turno volta a ~8 min reais) e
    retornos esperam a mesa esvaziar (`RETRY_WAIT`). Medido com o robô desastrado (`--clumsy`).
15. Várias noites com roteiro fixo por noite (`Night`), progresso salvo e demissão com 3 graves acumuladas.
16. **Nada fixo além do roteiro**: as 4 "principais" com horário fixo foram removidas; tudo é sorteado com intervalo
    máximo (`call_gap`), o que também acabou com silêncios de ~1 h. O primeiro valor (12–32 min) era rápido demais
    para uma pessoa; passou a 28–42 (noite 2: 26–40), medido com o robô `--human`. Silhueta sai 10 min antes de ligar, preta e
    contra a luz de um poste.
17. Três idiomas (pt_BR, en, es): enum `T.Key` + CSV para a interface, .po para as falas.
18. Menu de pausa (Esc) com Configurações (idioma, volumes, velocidade do texto), também na tela inicial.
19. Fios saem de buracos (dois por cabo de conexão, um por ponta; o do FONE no encaixe); plug solto cai e o fio o
    recolhe para o buraco (substituiu a volta em arco e o cabo enrolado na base). Plug só se move arrastando
    (o modo "clique no plug e depois na tomada" foi removido); clique sem arrastar desconecta.
20. Cursores próprios (botões de cena também: `node_added` ligado em `_enter_tree`) (seta, dedo, mão aberta/fechada, proibido, I-beam), plug sob o mouse com destaque, fio mexido
    por último por cima e fios parados sem simulação. Plug com ponta de metal maior, que entra na tomada; sombras.
21. Caderno: registro com um clique no tipo ("Outro" e os campos editáveis saíram), contador na aba no lugar do
    ponto e da troca automática de aba, livro redesenhado como página pautada com carimbos.
22. Menos burocracia no despacho: mapa e despacho numa aba só (sem "Abrir mapa"/"Usar no despacho"), o tipo marca as
    unidades de costume, conferência sempre à vista com Enviar só quando pronto, limpa depois de enviar, etiqueta com
    a faixa de números ao passar o mouse, som de papel desenrolando ao abrir. Marcar o mapa sozinho pelo endereço
    dito na ligação ficou de fora de propósito (tira o desafio; no máximo, um modo fácil).
23. Turno caótico: noite 1 calma (7–9 ligações, máx. 2 pedindo atenção, sem picos) e ritmo subindo noite a noite.
    O tipo da ocorrência deixou de marcar unidades: a conversa revela os fatos e o protocolo (polícia: crime, briga,
    arma, rua bloqueada; bombeiros: fogo, fumaça, fio/gás, alguém preso; ambulância: ferido, passando mal ou preso) diz
    o que mandar. Cartão do protocolo na aba, respostas decisivas sem ambiguidade, moldes e roteiros com casos sorteados.
24. Barra de agravamento da emergência (abaixo do chat, dentro da caixa): inicial → agravando (média) → agravada
    (grave, jornal com atraso) → perdida (gravíssima, nova gravidade). Para enquanto o operador pergunta e a pessoa
    responde; corre em espera. Cada estágio tem fala própria e pode exigir unidades novas. Depois: a barra só para
    com o socorro completo no lugar certo (chutar e completar não adianta), ficou mais rápida (45/40/35 s no 1º
    estágio) e some fora da linha; aí o rádio inteiro acende (moldura pulsando e aviso na tela) na cor do estágio.
    Cada estágio libera uma pergunta sobre o que mudou; na perdida, só "Tem alguém ferido?" (e o endereço). A unidade
    nova só conta depois de alguém contar (a pessoa ou o rádio). O telefone passou a ocupar o que sobra da tela e o
    chat encolhe quando as opções ganham fileiras (antes, o painel passava até 13 px da tela e cortava os botões).
25. Ritmo separado das noites (`Pace`, níveis 1–5): segunda emergência só a partir do nível 3; nas 3 primeiras noites o
    ritmo só sobe se a noite anterior não foi ruim; depois sobe sempre, até o nível 5 (limite medido com `--human`).
    Última ligação às 23:40 e botão Encerrar turno; à meia-noite ninguém é cortado.
26. Setores: a cidade em três bairros (Vila Serena, Centro, Alto da Serra), entregues nas noites 5 e 9 (15 noites).
    Mesa com bancos A/B/C (faixas 100–199…), tampados por chapa até a entrega; mapa só com os bairros atendidos, ruas
    que continuam com o mesmo nome e a numeração seguindo, nomes sem sobreposição; revelação do bairro novo no mapa,
    dica do banco novo e ritmo que não sobe na noite da entrega. Lista telefônica refeita: uma letra por página dupla, abas de
    índice na borda em vez da barra de letras, ordem sem acento e bairro no endereço.
27. Ligação não atendida entra sozinha no caderno (carimbo "Não atendida", sem escolher tipo). Uma fala por vez em cada
    ligação (`Conversation.say` espera a anterior; o assunto não atropela mais o "Obrigado, Central") e nada de conversa
    fiada com o destino tocando. Fontes trocadas por IBM Plex e, a pedido do usuário, por Departure
    Mono em tudo (nítida em 1280×720; o texto de 11 px borra em janela bem menor).
28. Aba do despacho refeita: mapa na aba inteira e a ficha de despacho por cima, à direita (abre ao marcar o local
    ou com emergência, recolhe depois do envio), com o protocolo junto de cada unidade; viaturas num canto do mapa.
29. Ficha de despacho como cartão perfurado: marcar o local imprime o cartão (digitação e impressora antiga), o
    jogador perfura tipo e unidades em posições fixas e leva o cartão ao transmissor (canto de baixo à esquerda), que o puxa e
    envia, mesmo incompleto (o supervisor pune); a trituradora, embaixo da impressora, descarta o cartão.
30. Plug encaixado em perspectiva (visto de cima e da direita, com paralaxe por encaixe), com as peças do plug em pé,
    sombra pela profundidade, fio saindo no eixo e furos vazios com a mesma paralaxe. Janela maior, ao lado do rádio,
    no alto da direita (abas mais baixas), preparando mais detalhes na janela e na mesa.
31. Telefone como console em cunha (tela embutida na carcaça, fenda da barra de agravamento, teclas de verdade no deck)
    e rádio ao lado do relógio; a janela ocupa todo o alto da direita e as abas (o mapa) ficaram mais altas. O título
    "Central de São Sotero · Operador noturno" saiu da tela (a introdução da noite já mostra).
32. A tela vira uma mesa de trabalho (referência visual do usuário): mesa comutadora à esquerda, de pé sobre a mesa,
    com o FONE e o rádio na frente dela; ferramentas guardadas, que deslizam sobre a janela quando abertas (como um
    papel posto na mesa); painel do operador embaixo, na largura toda, com só as últimas 3 falas, e o registro inteiro
    das conversas numa quarta ferramenta. O cenário segue desenhado em código, mas pode virar PNG por camada depois.
33. Mesa comutadora refeita: móvel de madeira, seções com faixas gravadas, mais espaço entre as fileiras e legenda no
    pé; a base dos cabos virou uma bandeja na mesa, à frente do painel, de onde os fios sobem; relógio mais compacto.
34. Cenário: a janela deixou de ocupar a área das ferramentas inteira (parecia uma aba a mais) e virou um objeto na
    parede, com persiana, peitoril, vaso e a cidade lá fora (igreja com relógio, casas, poste, chão molhado); relógio de
    parede com a hora do jogo, papéis presos, tábuas na mesa, listas e caneca. Cada camada aceita um PNG depois.
35. Objetos da cena abrem as ferramentas: ficam na mesa, ao alcance do operador (na parede só ficaria o que parecesse
    perto dele), desenhados no mesmo detalhe da mesa comutadora. A legenda do rádio ficou de fora: o rádio já tem tela.
36. Mesa de madeira: a dica do manual subiu para o alto da direita (liberou a mesa), objetos maiores e em fileiras,
    tábuas em perspectiva com a borda da frente, luz da luminária e da janela na mesa e sombras saindo da luminária.
37. A mesa parecia o piso: a mesa comutadora passou a ficar de pé no tampo (o fundo dele atrás dela), sem rodapé na
    parede nem juntas de assoalho nas tábuas, com a borda da frente mais grossa. As abas das ferramentas somem quando
    estão guardadas (eram informação duplicada dos objetos da mesa); o selo do caderno foi para o caderno da mesa.
38. Ainda parecia chão (as duas linhas escuras da quina): perspectiva de um ponto, com o ponto de fuga na altura dos
    olhos; luz da luminária dobrando na quina (arco na parede, poça na mesa), sombras projetadas na parede, janela
    embutida com a espessura da parede e objetos da mesa com lado e espessura no rumo do ponto de fuga.
39. Canto da sala: a janela foi para a parede da direita, vista de lado (a vista da cidade fica reta, só recortada
    pelo vidro: entortada com a janela parecia um quadro), e no lugar dela, na parede do fundo, um armário de aço de
    chão atrás da mesa. Uma câmera só para a sala inteira, com os objetos da mesa postos nela em 3D (antes misturavam
    vista de frente e de cima, sem escorço) e o ponto de fuga perto deles.
40. Rádio, encaixe do FONE e bandeja dos cabos como caixas na câmera (tampo, lado e sombra); tábuas e poça de luz
    calculadas pela câmera, e a luz da luminária na mesa e no armário tremendo com ela.
41. Game design na mesa: os objetos mostram o estado do jogo (tiras no caderno, alfinete piscando, folha nova na
    prancheta); o jornal da manhã com as consequências da noite anterior fica na mesa; a sala muda pelos marcadores
    do roteiro (o mistério e as escolhas também moram no cenário).
42. Ferramentas como objetos (o papel sai do objeto na mesa, com a forma dele, e o cenário escurece atrás); um relógio
    só, analógico, na parede acima da mesa comutadora (o painel digital destoava e repetia a hora do relógio de
    parede), com o turno numa plaqueta de latão; o painel do operador virou um console embutido na frente da mesa.
43. Dicas da primeira vez para os sinais da mesa; a lateral da mesa comutadora na câmera; o relógio bate as horas e
    uma campainha avisa quando o turno pode ser encerrado.
44. Desempenho do cenário: ele só se redesenha quando algo que mostra muda; a vista da janela anda sozinha no vidro.
45. A mesa comutadora parecia fora da mesa e desalinhada com as peças de baixo, e a perspectiva estava exagerada para
    quem senta perto da mesa: a mesa comutadora virou um móvel só (painel na prateleira de um console, com a faixa de
    mesa embutida na frente dele) e os olhos subiram (ponto de fuga logo acima da tela), entortando bem menos.
46. O FONE e os cabos foram para a prateleira, na frente do painel e acima do rádio, como numa mesa telefônica de
    verdade: os plugs ficam em pé em buracos no tampo e os fios sobem deles até as tomadas; nomes gravados na madeira.
47. Acabamentos: os objetos da mesa reorganizados a partir da mesa comutadora (sem encostar uns nos outros), o
    interior do armário com profundidade, detalhes no console, relógio mais legível e, a pedido do usuário, a
    luminária saiu da tela: só a luz, vinda de cima e do meio.
48. Uma densidade de pixel só: o cenário passou a ter os detalhes em 1x1, como a interface (a mistura com 2x2
    incomodava; as contas da câmera seguem em unidades de 2 px), e os objetos perderam o contorno preto (serrilhava).
49. O 1x1 ficou "pixels pequenos e definidos demais", e um filtro de 2x2 com média borrou tudo: o cenário inteiro
    passou a 2x2 de verdade (arte na grade de 2 px e filtro que pega um pixel por bloco), ainda em prova (caderno e
    prancheta redesenhados; listas, mapa, jornal e caneca não). Para acabar com os borrões, como no Papers, Please: o
    jogo é ampliado como imagem (`viewport`, "nearest"), a fonte sem suavização, sem linhas de varredura e com vinheta
    e brilho em degraus.
50. O jogo todo ampliado como imagem deixou o texto feio a 1,5× (1080p): híbrido. A interface volta a ser desenhada na
    resolução da tela, com a fonte suavizada; só o cenário vai numa tela de metade da resolução ampliada com "nearest"
    (`SceneView`), que dá pixels quadrados e inteiros nas telas comuns. O filtro de 2x2 saiu.
51. Os objetos da mesa todos na grade de 2 px (listas, mapa, jornal e caneca redesenhados em blocos), o brilho da luz
    só na sala (antes passava em anéis por cima da mesa comutadora e dos textos) e os halos do bloom na mesma grade.
52. O brilho das lâmpadas e dos aros não passa mais por cima do plug encaixado; plug em pé mais comprido, com a ponta
    de metal mais longa; buracos da prateleira maiores, sem contorno preto, com o plug guardado entrando neles (antes
    parecia equilibrado em cima do buraco); os fios também saem de dentro do buraco, e o do FONE não deita mais na
    prateleira. Perto do buraco, fio e plug escurecem (a sombra de dentro dele).
53. Plugs e fios sem contorno preto (a beira na cor da peça, mais escura), como o cenário; o plug encaixado mais fino,
    deixando a aba da tomada à vista (dá para ver que entrou nela).
54. Prova de tudo em 2x2 com a fonte Tiny5 (branch `improve/0000-pixel-2x`, em espera): o texto ficava pior. A pedido
    do usuário, o jogo todo ficou em 1x1: o cenário voltou aos detalhes de 1 px (da história 48), numa tela na
    resolução da janela, o bloom em blocos de 1 px, e da prova vieram as peças redondas da mesa comutadora pixel a pixel
    (lâmpadas com aro, vidro e centro aceso). Os encaixes e o plug encaixado ficaram como estavam (o usuário os preferia).
55. O encaixe redesenhado pela referência do usuário (a mesma da branch 2×2), em 1x1: aro niquelado fino e furo preto
    largo, em pixel art.
56. Em telas maiores que 1280×720 os pixels "quebravam" (1,5× em 1080p): o jogo passou a ser desenhado sempre em
    1280×720 e ampliado com um filtro de pixel art (`GameView`, "sharp bilinear"), que deixa todos os pixels do mesmo
    tamanho em qualquer resolução (perfeitos nas ampliações inteiras).
57. Os plugs em pé na escala das tomadas novas (a ponta de metal da largura do furo, o cabo quase do tamanho do aro),
    os buracos da prateleira em pixel art (elipse com a beira de trás na sombra, a da frente na luz e a parede de
    dentro) e a tela em Configurações (cheia ou janela; ampliação suave ou pixels perfeitos com borda).
58. O relógio de parede analógico virou um relógio de flip na mesa, meio virado para o operador (depois com
    algarismos grandes desenhados à mão, base, rodinha, alarme e um creme menos claro); as outras peças
    redondas (botões do rádio, caneca, alfinete, parafusos) em pixel art como as tomadas; halo das luzes em degraus
    lisos, sem o pontilhado.
59. A perspectiva estava errada (o relógio torto): a câmera passou a sair de um operador sentado (altura dos olhos e
    distância ao tampo dão a distância focal), o relógio gira para os olhos por um cálculo e a frente dele é projetada
    de verdade.
60. Tomadas menores, com o furo da largura da ponta do plug, e o plug encaixado na proporção do em pé, com os mesmos
    detalhes. Mesa comutadora: lâmpadas de vidro leitoso (não pareciam mais tomadas), faixa ligando a coluna de cada
    linha, plaqueta de latão do fabricante no pé do painel, desgaste em volta das tomadas, chapas A/B com a letra
    estampada e o aviso pintado, fios de pano com dobras e trançado e a moldura com veios de verdade (a plaquinha que
    cai quando a linha chama foi testada e saiu: informação demais). O cartão de despacho sobe na mão e cai ao soltar.
61. Painel de baixo enxuto: saíram o bloco da ligação em foco e o do destino e das outras linhas (inúteis: a mesa já
    mostra); ficaram a tela da conversa (com a barra de agravamento e os avisos do visor), as teclas e o rádio,
    reestilizado como uma tela do console. Onde ficava o rádio, na frente da mesa comutadora, uma miniatura desse
    painel: o de baixo é a vista de perto dela. A conversa mostra as últimas falas que couberem, não só 3. O rádio
    guarda as mensagens anteriores na tela, a tela da conversa espera com o cursor piscando e a mesa comutadora só se
    redesenha quando algo muda.
62. A sala viva: a cidade vai apagando as luzes com a noite, a luz da luminária cai no painel da mesa comutadora, as
    teclas do console viraram teclas de verdade (chapa de metal, etiqueta de latão com o atalho, tecla baixa em
    relevo), a dica do manual e o horário do turno são papéis colados com fita (a plaqueta do turno saiu; na parede, a
    placa esmaltada da companhia telefônica) e o rádio ganhou um alto-falante perfurado na altura toda.
63. Clima noir: a sala fria e escura fora da luz da luminária (borda lisa, sem recorte), a luz dela mais forte e
    concentrada na mesa (o relógio ficava no escuro) e um brilho azul fraco vindo da janela (as faixas da persiana saíram).
64. A noite lá fora: carros passando com a luz dos faróis atravessando a sala, relâmpago e trovão na chuva e um
    letreiro de neon de hotel falhando, com o reflexo vermelho na parede.
65. A vista da janela pela referência do usuário: a telefonia no alto do morro, a rua dela com os carros passando e a
    esquina, a calçada, a mureta de tijolos com a escada descendo para a rua da cidade (no lugar do arbusto). Depois,
    profundidade: a cidade em camadas na névoa, a avenida fugindo para o horizonte e a luz e as sombras no chão; a
    esquina foi para a direita e, no lugar da escada, prédios de perto com o poste e o homem na frente; volume e
    escala nas coisas de perto; o homem e o carro na proporção da porta e dos andares dos prédios. Por fim, a vista
    passou a ter uma câmera de verdade (a sala no segundo andar, tudo em metros e na distância), e o carro é visto de cima.
66. A vista virou uma rua de verdade passando ao lado do prédio (referência do usuário). Primeiro com a câmera de lado
    e o ponto de fuga à esquerda (a rua parecia uma rampa vista de cima e os prédios, tortos); depois, a pedido, como
    uma cena 3D pensada antes: câmera na altura de quem está na janela, de frente para a rua, que passa na horizontal e
    continua para os dois lados, prédios verticais apoiados na calçada de lá, o cruzamento indo embora para o único
    ponto de fuga com a igreja no fim, o homem embaixo do poste da esquina, um carro passando e o arbusto plantado na
    nossa calçada. A mureta saiu. Depois, a nossa calçada, o nosso meio-fio e a faixa de pedestres saíram da vista (diziam
    que a nossa parede ia de frente, contra a diagonal da sala) e o arbusto passou para o primeiro plano, com a janela.
67. A janela parecia vista de cima: pela câmera, a parede dela fica a uns 44 cm da cabeça do operador, e o peitoril
    estava 38 cm abaixo dos olhos. O peitoril subiu (menos inclinado, a persiana subiu junto) e o vão ganhou a espessura
    da parede (o lado de dentro do batente, o fundo do vão, o vidro recuado com o caixilho de verdade) e um peitoril de
    dentro com o vaso.
68. Os olhos desceram para dentro da tela (`EYE`), na altura da janela: ela ficou reta, com a travessa no horizonte,
    o peitoril descendo pouco e a parede dela mais longe da cabeça. A vista da janela passou a usar o horizonte da sala
    (uma câmera só para o cenário inteiro). Em janela larga, os objetos da ponta entortam mais. Depois os olhos desceram
    mais (a janela e a vista juntas) e o armário cresceu para ~1,5 m, com prateleiras até a mesa.
69. Acabamentos da câmera nova: o ponto de fuga foi para o meio dos objetos da mesa (entortavam), o armário alto ganhou
    venezianas embaixo, puxador no meio e desgaste, um conduíte com a caixa de passagem leva os fios da mesa comutadora
    para o teto, o reflexo no vidro passou a ser a sala espelhada pela câmera e a vista ficou mais noir (asfalto escuro
    com as poças de luz dos postes, a vitrine do bar atrás do homem, a marquise do hotel, janelas fundas e névoa no
    fundo). O aquecedor embaixo da janela ficou de fora: com o peitoril a 24 cm do tampo, ele ficaria atrás da mesa.
70. A luz da rua na mesa passou a sair da janela de verdade (o vão projetado no tampo); um pedestre passa de vez em
    quando pela calçada de lá; o carro na chuva chia na água e o neon do hotel estala quando falha (abafado, de longe).
    A luz dos faróis varrendo a sala saiu; o peitoril e a guarnição de perto, que pareciam um buraco escuro, ficaram na
    luz de fora; a vitrine do bar ficou com duas divisões, longe da porta.
71. Sons da noite: o sino da igreja bate as horas de longe, a chuva cresce e diminui em ondas com as gotas no vidro e
    a calha pingando, a cidade se cala depois das 22h (menos carros e pedestres, grilos mais presentes), a luminária
    zumbe e estala quando pisca, a janela chocalha no trovão perto e os passos de quem passa soam de longe.
72. Os objetos da mesa girados uns graus, como largados (a pilha de listas desencontrada) em vez de retos e em
    fileira, e o mapa redesenhado como mapa de verdade (lia como papel quadriculado com um gráfico).
73. Os objetos da mesa redesenhados na identidade do jogo: o tampo dos objetos chatos posto pixel a pixel na
    perspectiva (torto por transformação, os pixels esticavam), cores de papel envelhecido em vez de branco, menos
    ruído (letra de mão espaçada, miolo das listas liso), a capa da lista com o título em baixo-relevo; menores, menos
    girados e com mais folga (estavam apertados e se encostando). Os testes voltaram ao tempo de antes (a vista da
    janela não é mais desenhada sem tela).
74. O relógio de flip ficou reto: meio virado para o operador, estava certo na perspectiva, mas parecia inclinado
    numa mesa plana (a única caixa alta girada entre as horizontais da sala).
75. A caneca redesenhada (parecia um balde): esmaltada de época, branco-gelo com a borda azul-marinho, alça em C e
    lascas, e o vapor do café subindo, que some com as horas porque o café esfria.
76. O alfinete do mapa parou de piscar e brilhar com emergência (um alfinete não acende; a dica dele saiu) e as listas
    telefônicas ganharam detalhes: na capa, o título dourado, o fone, a etiqueta do ano, a marca de caneca e a ponta
    dobrada; nas lombadas, a etiqueta do volume; no miolo, as folhas em linhas finas (numa imagem posta pixel a pixel:
    desenhadas tortas na tela, viravam degraus e faixas), as beiras sujas e tiras marcando páginas.
77. O vaso da janela foi refeito (um vaso de barro no tamanho dele na sala, posto pela câmera, com uma
    espada-de-são-jorge) e depois saiu, a pedido, com a planta: o peitoril fica vazio.
78. Os objetos da mesa na identidade da mesa comutadora (referência do usuário): o risco fino (texto, pauta, colunas)
    desenhado na tela em pixel art, não no papel em perspectiva (virava moiré); papel com 1 px de beira; os mais claros
    da tela (caneca, miolo das listas, capa) um tom abaixo; a capa das listas com o grão do papelão e o friso; o
    prendedor da prancheta em mapa de pixels niquelado, de pé (`CLIP_ART`), e a folha nova girada com a ponta dobrada
    (`SHEET_TURN`); a alça da caneca mais grossa; o lápis e as tiras do caderno com luz e sombra; o mapa e o jornal na
    paleta de papel envelhecido. Uma plaqueta de latão gravada no relógio foi testada e saiu (não combinava).
79. A chuva mais realista: o som em estéreo, com corpo grave (era um chiado agudo e parado) e vindo mais da janela, à
    direita; os pingos na janela caindo rápido, em riscos, e em maior quantidade. Gotas soltas (batidas, bolhas de poça,
    gotas no vidro, o pingo da calha) foram testadas e saíram: soavam como "tic".
80. A névoa de verdade: um véu liso que esconde o longe e engrossa rente ao chão, fiapos passando pela rua e as luzes dos
    postes e do neon espalhando nela (eram faixas retangulares no vidro, com a rua tão nítida quanto numa noite limpa).
81. A cidade mais viva: mais gente na calçada, às vezes em dupla, rareando até as 22h, quando ninguém mais passa; o
    homem do mistério chega andando, fica 15 min embaixo do poste e volta andando antes de ligar (antes, aparecia e
    sumia parado, por 5 min). Os passos de quem passa saíram: de dentro do prédio não se ouviriam.
82. As ferramentas abertas no material dos objetos da mesa (as cores em comum no `Pal`): a lista com a capa de papelão
    e as abas em tiras de papel, o caderno em couro (no lugar do pano verde, para se diferenciar das listas coloridas)
    com as tiras dos pendentes, o registro na tábua com o prendedor niquelado e o cabeçalho com o fio vermelho, o jornal
    no papel-jornal com a foto e as colunas (e aberto para ter arte e textos por noite) e a luz da luminária no papel.
    O mapa aberto deixou de parecer um diagrama: ruas de papel, bairros nos tons do mapa da mesa, casas e quintais,
    lugares de telhado de barro, a praça, a sanfona e o selo.
83. O mapa da mesa virou a miniatura fiel do mapa aberto (as mesmas folhas, quarteirões, casas, lugares, praça, zona
    rural e selo; o papel na proporção dos bairros atendidos). Antes, era uma cidade inventada, com rio e trem que o
    mapa aberto não tem.
84. Desempenho (medido com tela e sem vsync): a sala parada engasgava 3 a 4 vezes por segundo (o relógio virando e o
    neon a redesenhavam inteira, ~20 ms cada vez), e a cada quadro com a luminária piscando, no relâmpago e com o papel
    de uma ferramenta deslizando; eram ~2200 chamadas de desenho por quadro, mil delas do escuro da sala. Polígonos
    viraram primitivos, o que muda sozinho saiu da sala (a camada de cima, a textura do relógio, as duas camadas da
    vista), a tela do cenário só se desenha quando muda e os sons são sintetizados nos núcleos todos: na chuva, de 7,6
    para 2,0 ms por quadro, sem nenhum acima de 8 ms, e a abertura 0,6 s mais rápida.
85. A luz da rua na mesa maior e mais suave (era um quadrado pequeno perto da parede) e o relâmpago só no que a janela
    alcança, quase branco e nítido: a parede do fundo com a sombra do armário, a frente do armário, a lateral da mesa
    comutadora e a janela com a cruz do caixilho no tampo (era um véu azul e liso na tela inteira, até na frente da
    mesa comutadora).
86. Ambiente melancólico, noir e aconchegante: a luminária esquenta no começo do turno, a pausa abafa o som, o prédio
    da esquina virou apartamentos com varanda e a TV piscando na janela, janelas acendem de madrugada, a chuva muda de força durante a noite (com as poças crescendo), nuvens passam pela
    lua, o arbusto balança em rajadas, o vidro embaça nos cantos e as
    gotas do vidro fazem manchinhas de sombra na luz da rua na mesa. O semáforo do cruzamento foi testado e saiu. Ficaram de fora a pedido: chaminés (raras no
    Brasil), o vento na fresta, o prédio estalando e o grão de filme; a sirene das viaturas fica para depois.
87. As máquinas do despacho (impressora, triturador e transmissor) não apareciam em lugar nenhum da sala: o mapa
    dobrado deu lugar a uma unidade de despacho na mesa, como um terminal antigo, com as três máquinas na base e o mapa
    de papel aberto sob o vidro no painel (um monitor foi descartado: fora de época e o mapa é de papel). As listas
    ficaram atrás, ao lado dela, e o caderno veio para a frente (as listas na frente o tampavam).
88. O despacho aberto passou a ser a unidade de despacho de perto: o mapa sob o vidro na moldura de metal (sem a
    sanfona) e, embaixo, a base fixa com as três máquinas lado a lado, como na miniatura: transmissor à esquerda,
    impressora no meio (o cartão sobe dela para cima do vidro) e trituradora à direita. Antes o cartão saía da
    impressora logo acima da trituradora e, solto ali, era triturado. A ficha deixou de abrir e fechar (o × e o botão de
    reabrir saíram). As abas das ferramentas saíram, a pedido, para o papel ganhar altura: abrem pelos objetos da mesa
    e pelas teclas 1 a 4. Ficaram de fora: a área de descanso do cartão, a fenda só pela mão, a confirmação no
    triturador e o desfazer do arraste. Depois: o cartão menor (176 px) e as fendas finas, o cartão livre até a borda
    de baixo (por cima das máquinas), a moldura do vidro sem o fio de baixo (riscava a tira da impressora) e, na mesa,
    a unidade e as listas mais para a esquerda (o relógio encostava na pilha, `BOOKS_SPAN`; conferido pelos limites
    na tela, não só pela captura). Por fim: as luzes de emergência e de cartão e a plaqueta numa faixa embaixo das
    máquinas (`CardMachines._draw_strip`, `STRIP`, como na frente da miniatura) e o mapa enquadrado acima da tira da
    impressora (`CityMap.bottom_inset`), com o nome do bairro à vista.
89. Revisão geral: a dica do manual cresce com o texto (cortava em 2 linhas), o jogo fica sempre em 1280×720 (o monitor
    largo esticava a sala) e o jogo ganhou data: começa na segunda-feira, 8 de outubro de 1973, mostrada no
    calendário do armário, na introdução, no jornal e no caderno (os bilhetes que citavam o dia da semana acompanharam).
90. O tutorial virou um treinamento com a Cecília, telefonista veterana do Alto da Serra, numa noite 0 (sexta, 5 de
    outubro), antes da primeira: o FONE já na entrada 1, ela chama com a tecla Atender piscando, se apresenta, liga de
    novo pela entrada 2 e ensina, como colega, a lista, os cabos, o Transferir e a desmontar a ligação; comenta o erro e
    a demora quando está na linha (fora dela, só a dica do manual). Depois dela, um turno calmo; dá para pular o
    treinamento na tela inicial. A transferência guiada da noite 1 saiu. Em partes: caderno, emergência com o cartão
    e o resto ainda faltam.
91. A Cecília falava rápido demais e o texto se acumulava: ela passou a falar mais devagar, em frases curtas (as
    falas longas foram quebradas). Uma pausa de leitura entre as falas foi testada e saiu a pedido.
92. Treinamento, parte 2: na última ligação, a Cecília ensina o caderno (as tiras, registrar as ligações dela como
    comuns, comentando o tipo errado) e a prancheta do registro.
93. Treinamento, parte 3: a Cecília liga pela entrada 3 fingindo uma emergência (fumaça numa casa) e ensina o
    despacho: marcar o local no mapa, triturar o cartão quando ela corrige o endereço, perfurar o tipo e a unidade,
    levar ao transmissor e ouvir o rádio; explica a barra de agravamento só de boca.
94. Treinamento, parte 4: a Cecília pede para o jogador deixá-la em espera (o FONE na entrada 1) e voltar, explica
    que quem espera demais desiste, e conta como termina o turno (23:40, Encerrar turno, registrar tudo, meia-noite).
95. Revisão do treinamento: a noite 0 não demite (`ShiftReport.fired`) e fecha com "Fim do treinamento"; a pausa não
    conta a demora nem a conversa dela; um cartão do endereço errado enviado antes da hora não vale como chegada (e o
    manual avisa quando os bombeiros ainda estão fora); o FONE fora da linha dela dá a dica de voltar; as fichas dela
    dizem "Treinamento" (a da emergência leva o local e o cartão); o caderno do treinamento é de 5 para 6; o botão de
    recomeçar aparece desde a noite 1; ao terminar, o manual lembra de registrar as fichas dela.
96. Vozes: soavam "atrás de uma parede" (passa-baixa em ~1 kHz na sílaba). As de quem liga passam pelo barramento
    Phone, com a banda do telefone dos anos 70 (distorção leve do microfone de carvão, 300–3400 Hz, pico em 2 kHz); a
    desconhecida e o rádio continuam com o filtro próprio. Cada pessoa tem a sua altura, pelo nome (a mesma quando liga
    de novo), e a fala ganhou entonação: a voz cai ao longo da frase, a tônica da palavra sobe e o fim da frase desce
    (ou sobe na pergunta), em vez de um sorteio por sílaba.
97. Entonação de pergunta e exclamação mais marcada: na pergunta a frase fica reta e as três últimas sílabas sobem em
    rampa; na exclamação a frase toda fica mais aguda e mais alta, a tônica com mais ênfase e o fim caindo mais.
98. Sílabas atropeladas: a fala anda no ritmo das letras, e vogais a duas letras uma da outra ("sei o", "com a")
    saíam quase juntas. Uma sílaba só começa depois de 70% da anterior da mesma voz; a que chega cedo não toca (o texto
    segue no mesmo ritmo).
99. Vogais nasais e consoantes: "ã", "õ" e vogal antes de "m"/"n" sem vogal depois ("também", "central") soam nasais
    (F1 mais baixo e fraco, ressoar do nariz); e cada sílaba ganha o ataque da consoante que vem antes no texto (estalo
    em p/t/b/d, chiado em s/f/ch/j e no "r" do começo, zumbido em m/n), em vez de um chiado sorteado.
100. O "a" saía forte demais: 2,5 dB a menos (`Sfx.VOWEL_DB`). O painel de debug ganhou abas (Jogo e Vozes); na de
    Vozes, o alfabeto (cada letra fala o nome dela) e uma caixa de texto para ouvir qualquer fala na voz escolhida.
101. "Alô" falava só o "A": o intervalo mínimo entre sílabas descartava a que chegava cedo. Agora ela espera a vez e
    toca; só é descartada se já houver outra esperando (a fala não acumula atraso).
102. Falas 2 dB mais altas (`Sfx.VOICE_GAIN`), com um limitador no barramento Voices: a tônica de uma exclamação (e a
    voz da desconhecida) já passava de 0 dB e podia estourar.
103. Emoção nas emergências: quem liga se agita com a barra de agravamento (voz mais aguda, trêmula, mais alta e mais
    rápida), cada um do seu jeito: o temperamento é sorteado por ligação (umas pessoas quase não mudam, outras disparam)
    e o retorno da mesma pessoa o mantém.
104. Erro ao perder a emergência com o operador na linha: a barra era desenhada no quadro em que ela passava ao estágio
    3 (perdida), que não tem cor nem nome. O `UrgencyBar._draw` agora confere se ela ainda vale.
105. Emergências simultâneas, no máximo duas: cada uma com a sua barra (o painel mostra a da linha do FONE, o rádio
    acende na pior e avisa da outra); o cartão vai para a emergência do lugar marcado (fora de todas, para a que está
    sendo atendida). A terceira espera; o debug recusa.
106. Viaturas pela quantidade de emergências: com duas em andamento, até duas de cada tipo (a de reserva sai da mesma
    base); com uma, continua uma de cada, e quem errou espera ela voltar.
107. Mais ligações: 13 transferências escritas (os destinos que ainda não tinham, várias com alternativa do mesmo
    ramo), 3 moldes de transferência, 14 emergências escritas (7 no Centro e 7 no Alto da Serra, dez por bairro),
    5 moldes de emergência (queda, fio caído, gás, atropelamento, desabamento) e 10 trotes.
108. Mais 13 assuntos de conversa fiada do cotidiano (novela, futebol, casamento da filha, circo, marido de plantão,
    bolo no forno, carta do irmão, novena, viagem ao médico, rua sem calçamento, crochê, farmácia de plantão, filme no
    cinema), cada um com uma resposta simpática e uma seca que continuam o assunto. Galinha, dente de leite, cachorro
    fugido e rádio novo saíram a pedido: assunto sem motivo para contar à central (curiosidade solta) parece aleatório;
    toda conversa fiada precisa de um gancho: novidade da cidade, o que a pessoa faz enquanto espera ou por que está acordada.
109. Revisão dos assuntos antigos pelo mesmo critério: horta e falta de luz (perto demais do mistério) trocados pela
    festa da vizinha e pelos cem anos do seu Geraldo; relógio adiantado pede a hora certa à central; o crochê é feito
    enquanto espera. Pedir desculpa por ligar tarde não faz sentido (é o horário da central): uma pede desculpa por
    incomodar com a central cheia, a outra por puxar conversa. A carta do irmão diz por que ela conta (precisava contar
    pra alguém).
110. Rádio: cada mensagem leva na frente a hora em que chegou ("[21:04] Central, viatura 2…"), para saber se é nova e
    quanto a viatura demorou; um pouco mais de espaço entre as linhas da tela, que quase se encostavam.
111. Ligações interurbanas pelos troncos, como nas mesas de verdade (a ligação vai à central da outra cidade, onde
    outra telefonista completa). Primeiro passo, só para ver como fica: um banco de seis troncos (CAPITAL, NORTE, SUL,
    LESTE, OESTE, LITORAL, nomes provisórios) no canto de baixo à direita do painel, embaixo do banco C e na largura do
    B (`_draw_trunks`). Os cabos de conexão se juntaram perto do FONE (`PATCH_PITCH`; o resto da prateleira fica para
    os cabos novos que virão com os setores) e a plaqueta do fabricante foi para a plaqueta lisa do console, ao lado
    da miniatura. Depois, o FONE mais para a esquerda (`FONE_HOLE_X`, encaixe de 48 px) e os cabos logo depois dele,
    com 12 px entre um plug e o par seguinte. As tomadas dos troncos ainda não aceitam plug.
112. O nome do FONE numa plaquinha de latão na frente do console, abaixo da beira da prateleira (gravado embaixo do
    buraco saía cortado: a beira da frente do buraco, desenhada por cima do plug, cobria o alto das letras). Uma
    chapa de latão em volta do buraco do FONE, para distingui-lo dos cabos, foi testada (de frente e depois em
    perspectiva, fugindo para o ponto de fuga) e saiu a pedido: ficou feia. Depois a plaquinha foi para o chão da
    prateleira, logo à frente do buraco, na perspectiva dos olhos (a placa inclinada para o ponto de fuga; as letras
    ficam retas, porque inclinadas linha a linha, mesmo com um terço do ângulo, as de 5 px viravam um borrão), e os
    cabos se afastaram do FONE (24 px até o primeiro plug).
113. Teste: as duas pontas de cada cabo uma atrás da outra na prateleira, como nas mesas de verdade (`SHELF_HOLE_Y`
    atrás, `SHELF_FRONT_Y` na frente, uma coluna por cabo, `PATCH_PITCH`). Pela perspectiva, a da frente fica 20 a 32
    px à esquerda da de trás (na reta do ponto de fuga), e os guardados da frente passam na frente dos de trás. Com o
    desencontro variando a cada coluna parecia bagunça: a da frente ficou sempre meio passo à esquerda (`FRONT_SHIFT`),
    como tijolos, e o FONE 10 px mais longe da beira para a plaquinha caber.
114. Os cabos se espalham pela prateleira até o bloco interurbano, sem sobrar espaço (`_step`: do FONE até
    `TRUNK_GAP` antes do bloco, `trunks`, dividido pelos plugs; com mais cabos, o passo encolhe).
115. As duas pontas de cada cabo juntas, como um par (a da frente encostada à esquerda da de trás, `PAIR_SHIFT`), e
    os pares a um passo igual até o interurbano (`_pitch`): fazem parte da mesma ligação, e alternadas uma a uma não
    dava para ver qual ponta era de qual cabo.
116. Correção: a ponta da fileira da frente travava antes de entrar no buraco (o fio repousava na linha da fileira de
    trás e não descia até ele; agora cada fio repousa na fileira do buraco dele). A plaquinha "FONE" inclinada pela
    perspectiva ficou ruim: agora é reta, na fileira da frente, centrada embaixo do buraco do FONE.
117. Volta a 3 cabos; os dois lugares que sobram ficam sob um tampo cada, porque cada setor novo vai liberar um par
    (`SHELF_SLOTS`, `_draw_cover`). O tampo foi primeiro um retângulo reto, depois na perspectiva exata (o usuário
    pediu o ângulo de visão), mais à esquerda (ancorado no meio do fundo), um por par, na inclinação dos pares de
    buracos (na exata ficava inclinado demais ao lado deles), mais largo (fino demais) e com um parafuso em cada canto.
118. Interurbanos funcionando: as tomadas do banco INTERURBANO são destinos (troncos 901–906); quem liga pede a cidade
    e diz o número de lá; o operador liga a saída no tronco, transfere, passa o número à telefonista da outra cidade
    e ela completa. Tronco errado: o número não é de lá.
119. A prateleira ficou mais funda: o painel da mesa comutadora recuou 16 px para a parede (a faixa do bilhete do turno
    e a margem de cima cederam a altura; o fundo do tampo, a sala e o ponto de fuga ficaram onde estavam) e as duas
    fileiras de buracos se afastaram do rodapé do painel, da beira da frente e uma da outra, para os cabos terem
    respiro (`SHELF_HOLE_Y`, `SHELF_FRONT_Y`).
120. Análise de desempenho e as correções dela: a mesa comutadora em camadas (o painel parado, as lâmpadas, as
    tomadas com a luz da sala e os fios, cada uma redesenhada só quando o que mostra muda: a lâmpada piscando não
    redesenha mais a mesa inteira) e o trançado do fio numa chamada de desenho só. O fio que parecia demorar ~10 s
    para dormir era o mouse passando pela janela durante a medição: sem ele, os fios assentam e dormem em 2 a 5 s, e
    a física ficou como estava.
121. Cada setor entregue ao operador traz um par de cabos: o lugar tampado na prateleira abre e o cabo novo está lá
    (branco na noite 5, com o Centro; preto na noite 9, com o Alto da Serra; `patches`, pelos setores atendidos).
122. Bilhete de tarifação dos interurbanos: um calculógrafo na mesa começa a contar sozinho quando a outra ponta
    atende e, quando a conversa acaba, imprime o bilhete; o operador arrasta o carimbo até o bilhete e o bilhete até
    uma caixinha, e guardado sem carimbo dá advertência leve.
123. Sem lugar na mesa para o calculógrafo, ele ficou no lugar da prancheta do registro, que passou a ficar pendurada
    ao lado da mesa comutadora.
124. O painel de debug toca um interurbano na hora (botão Interurbano, num tronco livre).
125. Bilhetes e carimbo do calculógrafo soltos na mesa dele: pegos, levados e soltos em qualquer lugar (antes, o
    arrastar do Godot, que só levava uma imagem até o alvo); o carimbo carimba o bilhete em que é solto.
126. Na miniatura do calculógrafo da sala, o bilhete sobe da fenda enquanto é impresso.
127. A prancheta do registro pendurada na lateral do painel da mesa comutadora, na perspectiva e no ângulo da sala (de
    frente, na parede, destoava).
