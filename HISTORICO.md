# Histórico das decisões de design

O que o usuário pediu, em ordem (antes no `CLAUDE.md`). Acrescente cada pedido novo no fim, com as chaves do assunto
na primeira linha do item (as da lista abaixo; assunto novo ganha chave nova, posta na lista).

**Não leia tudo**: busque só os itens com as chaves do pedido (qualquer uma delas; o item sai inteiro), e acrescente
`saiu` para ver o que já foi testado e descartado:

    awk -v t='camera|janela|saiu' '/^[0-9]+\. /{p = $0 ~ "#(" t ")( |$)"} p' HISTORICO.md

Chaves:
- `#cabos` plugs, fios, FONE, prateleira e buracos · `#mesa-comutadora` painel, tomadas, lâmpadas, bancos
- `#camera` perspectiva, ponto de fuga, olhos · `#disposicao` onde fica cada coisa na tela e na mesa
- `#sala` parede, armário, conduíte, tampo · `#janela` o vão, peitoril, persiana · `#vista` a cidade lá fora
- `#luz` luminária, bloom, noir, luz da rua · `#clima` chuva, névoa, lua · `#pixel` densidade, contorno, pixel art
- `#tela` resolução e ampliação · `#fonte` · `#objetos` os objetos da mesa da sala · `#relogio` o relógio da sala
- `#calculografo` tarifação e bilhetes · `#carimbo` o carimbo dele e a marca · `#interurbano` troncos
- `#despacho` cartão, máquinas, viaturas · `#mapa` o desenho do mapa · `#lista` lista telefônica · `#jornal`
- `#caderno` caderno, hoje bloco de fichas · `#prancheta` o registro das conversas · `#ferramentas` os papéis abertos
- `#painel` o painel de baixo, console e teclas · `#radio` · `#interface` menus, pausa, configurações, cursores, dicas
- `#discador` as ligações que o operador faz (o discador da prateleira e o de perto)
- `#emergencia` barra de agravamento e viaturas · `#consequencias` supervisor, advertências, relatório
- `#ritmo` agenda e quantidade de ligações · `#turno` horário, relógio do jogo, fim do turno · `#noites` noites,
  progresso, data · `#setores` · `#treinamento` · `#misterio` a ligação desconhecida e o homem na rua
- `#conteudo` roteiros e moldes · `#conversa` conversa fiada e o andamento das falas · `#voz` vozes · `#som`
- `#idiomas` · `#desempenho` · `#debug` · `#testes` · `#codigo` estrutura do código
- `#burocracias` as normas do supervisor e das autoridades (identificação, bloqueios, códigos, fitas)
- `#recompensas` os broches ganhos pelas noites
- `#saiu` algo testado ou feito que saiu a pedido: confira antes de propor de novo

1. #mesa-comutadora #cabos
   Mesa com entradas + destinos; cabos limitados; desmontar conexões encerradas.
2. #mesa-comutadora #ritmo #caderno #conteudo #saiu
   Teclado de discagem removido; ligações simultâneas; caderno em fila; mais variedade de conversas.
3. #ritmo
   Menos simultaneidade (extras espaçadas, pico raro).
4. #ritmo
   Conversas conectadas mais longas (45–90 min de jogo).
5. #cabos #mesa-comutadora #saiu
   Modelo de cabos refeito: pares com chaves FALAR/TOCAR foram **substituídos** por FONE + saídas + cabos de
   conexão + botão Transferir (o usuário considera o vermelho "o cabo do fone"; depois o FONE passou a branco, depois a verde, e os
   cabos de conexão a vermelho/azul/amarelo).
6. #misterio #turno #cabos
   Ligações continuam depois da linha 07; linha 07 em horário aleatório após 02:00; final às 06:00;
   clique devolve o plug à base com animação.
7. #codigo #testes
   Reestruturação para a versão definitiva (branch `refactor/definitive`): testes no projeto, semente fixa,
   conteúdo em Resources, `PhoneCall`/`Exchange` tipados, interface em cenas com Containers e tema, autoload
   `Sfx` com barramentos, Input Map e `tr()`.
8. #misterio #saiu
   Anotação "NÃO ATENDER NOVAMENTE" removida (o mistério será roteirizado depois); a ligação desconhecida vem
   de qualquer entrada, não só da 07.
9. #conteudo
   Mais roteiros escritos e conversas híbridas: moldes com lacunas (nomes em inglês) para extras e emergência.
10. #consequencias #despacho #emergencia
    Consequências + relatório do supervisor no fim do turno, pensado para as próximas noites. Despacho errado: a pessoa
    agradece na hora, o rádio diz que não havia nada e as unidades voltam; ela liga de novo dizendo que piorou e,
    em alguns casos, dá para despachar de novo (a advertência fica).
11. #turno #misterio #consequencias #cabos
    Turno passou a ser 18:00–00:00 (desconhecida entre 22:00 e 23:30; extras 4–6). Número errado com o FONE fora:
    não completa; foi engano, os dois desligam e o solicitante liga de novo pedindo o certo. Clique que mexe
    uns pixels conta como clique.
12. #som #clima #saiu
    Sons: campainha antiga (martelinho + ressonadores de metal; depois trocada por bipes suaves, jogadores acharam irritante) e "tuuuu" (o filtro de caixa oca foi testado e removido a pedido do usuário), chuva e grilos (chirps + trilos) refeitos. Clima sorteado por
    noite: chuva (só chuva), névoa (grilos), limpo (brisa e grilos). A coruja que havia foi removida a pedido do usuário.
13. #radio #interface #misterio #vista
    Rádio mais largo e alto (3 linhas); abas 24 px mais baixas (mapa se ajusta à altura). Silhueta na janela
    `SHADOW_LEAD` (15 min) antes da ligação desconhecida (`Background.shadow`), sai `SHADOW_LEAVE` (10 min) antes
    (foi ligar); segue o horário sorteado (`myst_plan`), mesmo que a ligação atrase.
14. #ritmo #turno #testes
    Ligações demais ao mesmo tempo depois do turno de 6 h: relógio a 0,75 min/s (turno volta a ~8 min reais) e
    retornos esperam a mesa esvaziar (`RETRY_WAIT`). Medido com o robô desastrado (`--clumsy`).
15. #noites #consequencias
    Várias noites com roteiro fixo por noite (`Night`), progresso salvo e demissão com 3 graves acumuladas.
16. #ritmo #noites #misterio #testes #saiu
    **Nada fixo além do roteiro**: as 4 "principais" com horário fixo foram removidas; tudo é sorteado com intervalo
    máximo (`call_gap`), o que também acabou com silêncios de ~1 h. O primeiro valor (12–32 min) era rápido demais
    para uma pessoa; passou a 28–42 (noite 2: 26–40), medido com o robô `--human`. Silhueta sai 10 min antes de ligar, preta e
    contra a luz de um poste.
17. #idiomas
    Três idiomas (pt_BR, en, es): enum `T.Key` + CSV para a interface, .po para as falas.
18. #interface
    Menu de pausa (Esc) com Configurações (idioma, volumes, velocidade do texto), também na tela inicial.
19. #cabos #saiu
    Fios saem de buracos (dois por cabo de conexão, um por ponta; o do FONE no encaixe); plug solto cai e o fio o
    recolhe para o buraco (substituiu a volta em arco e o cabo enrolado na base). Plug só se move arrastando
    (o modo "clique no plug e depois na tomada" foi removido); clique sem arrastar desconecta.
20. #interface #cabos
    Cursores próprios (botões de cena também: `node_added` ligado em `_enter_tree`) (seta, dedo, mão aberta/fechada, proibido, I-beam), plug sob o mouse com destaque, fio mexido
    por último por cima e fios parados sem simulação. Plug com ponta de metal maior, que entra na tomada; sombras.
21. #caderno #saiu
    Caderno: registro com um clique no tipo ("Outro" e os campos editáveis saíram), contador na aba no lugar do
    ponto e da troca automática de aba, livro redesenhado como página pautada com carimbos.
22. #despacho #mapa #som #saiu
    Menos burocracia no despacho: mapa e despacho numa aba só (sem "Abrir mapa"/"Usar no despacho"), o tipo marca as
    unidades de costume, conferência sempre à vista com Enviar só quando pronto, limpa depois de enviar, etiqueta com
    a faixa de números ao passar o mouse, som de papel desenrolando ao abrir. Marcar o mapa sozinho pelo endereço
    dito na ligação ficou de fora de propósito (tira o desafio; no máximo, um modo fácil).
23. #ritmo #emergencia #despacho #conteudo
    Turno caótico: noite 1 calma (7–9 ligações, máx. 2 pedindo atenção, sem picos) e ritmo subindo noite a noite.
    O tipo da ocorrência deixou de marcar unidades: a conversa revela os fatos e o protocolo (polícia: crime, briga,
    arma, rua bloqueada; bombeiros: fogo, fumaça, fio/gás, alguém preso; ambulância: ferido, passando mal ou preso) diz
    o que mandar. Cartão do protocolo na aba, respostas decisivas sem ambiguidade, moldes e roteiros com casos sorteados.
24. #emergencia #interface #radio
    Barra de agravamento da emergência (abaixo do chat, dentro da caixa): inicial → agravando (média) → agravada
    (grave, jornal com atraso) → perdida (gravíssima, nova gravidade). Para enquanto o operador pergunta e a pessoa
    responde; corre em espera. Cada estágio tem fala própria e pode exigir unidades novas. Depois: a barra só para
    com o socorro completo no lugar certo (chutar e completar não adianta), ficou mais rápida (45/40/35 s no 1º
    estágio) e some fora da linha; aí o rádio inteiro acende (moldura pulsando e aviso na tela) na cor do estágio.
    Cada estágio libera uma pergunta sobre o que mudou; na perdida, só "Tem alguém ferido?" (e o endereço). A unidade
    nova só conta depois de alguém contar (a pessoa ou o rádio). O telefone passou a ocupar o que sobra da tela e o
    chat encolhe quando as opções ganham fileiras (antes, o painel passava até 13 px da tela e cortava os botões).
25. #ritmo #turno
    Ritmo separado das noites (`Pace`, níveis 1–5): segunda emergência só a partir do nível 3; nas 3 primeiras noites o
    ritmo só sobe se a noite anterior não foi ruim; depois sobe sempre, até o nível 5 (limite medido com `--human`).
    Última ligação às 23:40 e botão Encerrar turno; à meia-noite ninguém é cortado.
26. #setores #mesa-comutadora #mapa #lista #ritmo
    Setores: a cidade em três bairros (Vila Serena, Centro, Alto da Serra), entregues nas noites 5 e 9 (15 noites).
    Mesa com bancos A/B/C (faixas 100–199…), tampados por chapa até a entrega; mapa só com os bairros atendidos, ruas
    que continuam com o mesmo nome e a numeração seguindo, nomes sem sobreposição; revelação do bairro novo no mapa,
    dica do banco novo e ritmo que não sobe na noite da entrega. Lista telefônica refeita: uma letra por página dupla, abas de
    índice na borda em vez da barra de letras, ordem sem acento e bairro no endereço.
27. #caderno #conversa #fonte
    Ligação não atendida entra sozinha no caderno (carimbo "Não atendida", sem escolher tipo). Uma fala por vez em cada
    ligação (`Conversation.say` espera a anterior; o assunto não atropela mais o "Obrigado, Central") e nada de conversa
    fiada com o destino tocando. Fontes trocadas por IBM Plex e, a pedido do usuário, por Departure
    Mono em tudo (nítida em 1280×720; o texto de 11 px borra em janela bem menor).
28. #despacho #mapa
    Aba do despacho refeita: mapa na aba inteira e a ficha de despacho por cima, à direita (abre ao marcar o local
    ou com emergência, recolhe depois do envio), com o protocolo junto de cada unidade; viaturas num canto do mapa.
29. #despacho
    Ficha de despacho como cartão perfurado: marcar o local imprime o cartão (digitação e impressora antiga), o
    jogador perfura tipo e unidades em posições fixas e leva o cartão ao transmissor (canto de baixo à esquerda), que o puxa e
    envia, mesmo incompleto (o supervisor pune); a trituradora, embaixo da impressora, descarta o cartão.
30. #cabos #disposicao
    Plug encaixado em perspectiva (visto de cima e da direita, com paralaxe por encaixe), com as peças do plug em pé,
    sombra pela profundidade, fio saindo no eixo e furos vazios com a mesma paralaxe. Janela maior, ao lado do rádio,
    no alto da direita (abas mais baixas), preparando mais detalhes na janela e na mesa.
31. #painel #radio #disposicao #saiu
    Telefone como console em cunha (tela embutida na carcaça, fenda da barra de agravamento, teclas de verdade no deck)
    e rádio ao lado do relógio; a janela ocupa todo o alto da direita e as abas (o mapa) ficaram mais altas. O título
    "Central de São Sotero · Operador noturno" saiu da tela (a introdução da noite já mostra).
32. #disposicao #painel #ferramentas #sala #prancheta
    A tela vira uma mesa de trabalho (referência visual do usuário): mesa comutadora à esquerda, de pé sobre a mesa,
    com o FONE e o rádio na frente dela; ferramentas guardadas, que deslizam sobre a janela quando abertas (como um
    papel posto na mesa); painel do operador embaixo, na largura toda, com só as últimas 3 falas, e o registro inteiro
    das conversas numa quarta ferramenta. O cenário segue desenhado em código, mas pode virar PNG por camada depois.
33. #mesa-comutadora #cabos
    Mesa comutadora refeita: móvel de madeira, seções com faixas gravadas, mais espaço entre as fileiras e legenda no
    pé; a base dos cabos virou uma bandeja na mesa, à frente do painel, de onde os fios sobem; relógio mais compacto.
34. #sala #janela #vista #objetos
    Cenário: a janela deixou de ocupar a área das ferramentas inteira (parecia uma aba a mais) e virou um objeto na
    parede, com persiana, peitoril, vaso e a cidade lá fora (igreja com relógio, casas, poste, chão molhado); relógio de
    parede com a hora do jogo, papéis presos, tábuas na mesa, listas e caneca. Cada camada aceita um PNG depois.
35. #objetos #ferramentas #radio
    Objetos da cena abrem as ferramentas: ficam na mesa, ao alcance do operador (na parede só ficaria o que parecesse
    perto dele), desenhados no mesmo detalhe da mesa comutadora. A legenda do rádio ficou de fora: o rádio já tem tela.
36. #sala #objetos #luz #disposicao #interface
    Mesa de madeira: a dica do manual subiu para o alto da direita (liberou a mesa), objetos maiores e em fileiras,
    tábuas em perspectiva com a borda da frente, luz da luminária e da janela na mesa e sombras saindo da luminária.
37. #sala #camera #ferramentas #saiu
    A mesa parecia o piso: a mesa comutadora passou a ficar de pé no tampo (o fundo dele atrás dela), sem rodapé na
    parede nem juntas de assoalho nas tábuas, com a borda da frente mais grossa. As abas das ferramentas somem quando
    estão guardadas (eram informação duplicada dos objetos da mesa); o selo do caderno foi para o caderno da mesa.
38. #camera #sala #luz #janela #objetos
    Ainda parecia chão (as duas linhas escuras da quina): perspectiva de um ponto, com o ponto de fuga na altura dos
    olhos; luz da luminária dobrando na quina (arco na parede, poça na mesa), sombras projetadas na parede, janela
    embutida com a espessura da parede e objetos da mesa com lado e espessura no rumo do ponto de fuga.
39. #camera #janela #sala #objetos
    Canto da sala: a janela foi para a parede da direita, vista de lado (a vista da cidade fica reta, só recortada
    pelo vidro: entortada com a janela parecia um quadro), e no lugar dela, na parede do fundo, um armário de aço de
    chão atrás da mesa. Uma câmera só para a sala inteira, com os objetos da mesa postos nela em 3D (antes misturavam
    vista de frente e de cima, sem escorço) e o ponto de fuga perto deles.
40. #camera #cabos #luz
    Rádio, encaixe do FONE e bandeja dos cabos como caixas na câmera (tampo, lado e sombra); tábuas e poça de luz
    calculadas pela câmera, e a luz da luminária na mesa e no armário tremendo com ela.
41. #objetos #jornal #noites #sala
    Game design na mesa: os objetos mostram o estado do jogo (tiras no caderno, alfinete piscando, folha nova na
    prancheta); o jornal da manhã com as consequências da noite anterior fica na mesa; a sala muda pelos marcadores
    do roteiro (o mistério e as escolhas também moram no cenário).
42. #ferramentas #relogio #painel #turno
    Ferramentas como objetos (o papel sai do objeto na mesa, com a forma dele, e o cenário escurece atrás); um relógio
    só, analógico, na parede acima da mesa comutadora (o painel digital destoava e repetia a hora do relógio de
    parede), com o turno numa plaqueta de latão; o painel do operador virou um console embutido na frente da mesa.
43. #interface #camera #mesa-comutadora #som #turno
    Dicas da primeira vez para os sinais da mesa; a lateral da mesa comutadora na câmera; o relógio bate as horas e
    uma campainha avisa quando o turno pode ser encerrado.
44. #desempenho #sala #vista
    Desempenho do cenário: ele só se redesenha quando algo que mostra muda; a vista da janela anda sozinha no vidro.
45. #mesa-comutadora #camera
    A mesa comutadora parecia fora da mesa e desalinhada com as peças de baixo, e a perspectiva estava exagerada para
    quem senta perto da mesa: a mesa comutadora virou um móvel só (painel na prateleira de um console, com a faixa de
    mesa embutida na frente dele) e os olhos subiram (ponto de fuga logo acima da tela), entortando bem menos.
46. #cabos
    O FONE e os cabos foram para a prateleira, na frente do painel e acima do rádio, como numa mesa telefônica de
    verdade: os plugs ficam em pé em buracos no tampo e os fios sobem deles até as tomadas; nomes gravados na madeira.
47. #objetos #sala #painel #relogio #luz #saiu
    Acabamentos: os objetos da mesa reorganizados a partir da mesa comutadora (sem encostar uns nos outros), o
    interior do armário com profundidade, detalhes no console, relógio mais legível e, a pedido do usuário, a
    luminária saiu da tela: só a luz, vinda de cima e do meio.
48. #pixel #sala
    Uma densidade de pixel só: o cenário passou a ter os detalhes em 1x1, como a interface (a mistura com 2x2
    incomodava; as contas da câmera seguem em unidades de 2 px), e os objetos perderam o contorno preto (serrilhava).
49. #pixel #tela #fonte #saiu
    O 1x1 ficou "pixels pequenos e definidos demais", e um filtro de 2x2 com média borrou tudo: o cenário inteiro
    passou a 2x2 de verdade (arte na grade de 2 px e filtro que pega um pixel por bloco), ainda em prova (caderno e
    prancheta redesenhados; listas, mapa, jornal e caneca não). Para acabar com os borrões, como no Papers, Please: o
    jogo é ampliado como imagem (`viewport`, "nearest"), a fonte sem suavização, sem linhas de varredura e com vinheta
    e brilho em degraus.
50. #pixel #tela #fonte #saiu
    O jogo todo ampliado como imagem deixou o texto feio a 1,5× (1080p): híbrido. A interface volta a ser desenhada na
    resolução da tela, com a fonte suavizada; só o cenário vai numa tela de metade da resolução ampliada com "nearest"
    (`SceneView`), que dá pixels quadrados e inteiros nas telas comuns. O filtro de 2x2 saiu.
51. #pixel #objetos #luz
    Os objetos da mesa todos na grade de 2 px (listas, mapa, jornal e caneca redesenhados em blocos), o brilho da luz
    só na sala (antes passava em anéis por cima da mesa comutadora e dos textos) e os halos do bloom na mesma grade.
52. #cabos #luz
    O brilho das lâmpadas e dos aros não passa mais por cima do plug encaixado; plug em pé mais comprido, com a ponta
    de metal mais longa; buracos da prateleira maiores, sem contorno preto, com o plug guardado entrando neles (antes
    parecia equilibrado em cima do buraco); os fios também saem de dentro do buraco, e o do FONE não deita mais na
    prateleira. Perto do buraco, fio e plug escurecem (a sombra de dentro dele).
53. #cabos #pixel
    Plugs e fios sem contorno preto (a beira na cor da peça, mais escura), como o cenário; o plug encaixado mais fino,
    deixando a aba da tomada à vista (dá para ver que entrou nela).
54. #pixel #fonte #mesa-comutadora #saiu
    Prova de tudo em 2x2 com a fonte Tiny5 (branch `improve/0000-pixel-2x`, em espera): o texto ficava pior. A pedido
    do usuário, o jogo todo ficou em 1x1: o cenário voltou aos detalhes de 1 px (da história 48), numa tela na
    resolução da janela, o bloom em blocos de 1 px, e da prova vieram as peças redondas da mesa comutadora pixel a pixel
    (lâmpadas com aro, vidro e centro aceso). Os encaixes e o plug encaixado ficaram como estavam (o usuário os preferia).
55. #mesa-comutadora #pixel
    O encaixe redesenhado pela referência do usuário (a mesma da branch 2×2), em 1x1: aro niquelado fino e furo preto
    largo, em pixel art.
56. #tela #pixel
    Em telas maiores que 1280×720 os pixels "quebravam" (1,5× em 1080p): o jogo passou a ser desenhado sempre em
    1280×720 e ampliado com um filtro de pixel art (`GameView`, "sharp bilinear"), que deixa todos os pixels do mesmo
    tamanho em qualquer resolução (perfeitos nas ampliações inteiras).
57. #cabos #tela #interface
    Os plugs em pé na escala das tomadas novas (a ponta de metal da largura do furo, o cabo quase do tamanho do aro),
    os buracos da prateleira em pixel art (elipse com a beira de trás na sombra, a da frente na luz e a parede de
    dentro) e a tela em Configurações (cheia ou janela; ampliação suave ou pixels perfeitos com borda).
58. #relogio #objetos #pixel #luz #saiu
    O relógio de parede analógico virou um relógio de flip na mesa, meio virado para o operador (depois com
    algarismos grandes desenhados à mão, base, rodinha, alarme e um creme menos claro); as outras peças
    redondas (botões do rádio, caneca, alfinete, parafusos) em pixel art como as tomadas; halo das luzes em degraus
    lisos, sem o pontilhado.
59. #camera #relogio
    A perspectiva estava errada (o relógio torto): a câmera passou a sair de um operador sentado (altura dos olhos e
    distância ao tampo dão a distância focal), o relógio gira para os olhos por um cálculo e a frente dele é projetada
    de verdade.
60. #mesa-comutadora #cabos #despacho #saiu
    Tomadas menores, com o furo da largura da ponta do plug, e o plug encaixado na proporção do em pé, com os mesmos
    detalhes. Mesa comutadora: lâmpadas de vidro leitoso (não pareciam mais tomadas), faixa ligando a coluna de cada
    linha, plaqueta de latão do fabricante no pé do painel, desgaste em volta das tomadas, chapas A/B com a letra
    estampada e o aviso pintado, fios de pano com dobras e trançado e a moldura com veios de verdade (a plaquinha que
    cai quando a linha chama foi testada e saiu: informação demais). O cartão de despacho sobe na mão e cai ao soltar.
61. #painel #radio #desempenho #saiu
    Painel de baixo enxuto: saíram o bloco da ligação em foco e o do destino e das outras linhas (inúteis: a mesa já
    mostra); ficaram a tela da conversa (com a barra de agravamento e os avisos do visor), as teclas e o rádio,
    reestilizado como uma tela do console. Onde ficava o rádio, na frente da mesa comutadora, uma miniatura desse
    painel: o de baixo é a vista de perto dela. A conversa mostra as últimas falas que couberem, não só 3. O rádio
    guarda as mensagens anteriores na tela, a tela da conversa espera com o cursor piscando e a mesa comutadora só se
    redesenha quando algo muda.
62. #vista #luz #painel #interface #radio #turno #saiu
    A sala viva: a cidade vai apagando as luzes com a noite, a luz da luminária cai no painel da mesa comutadora, as
    teclas do console viraram teclas de verdade (chapa de metal, etiqueta de latão com o atalho, tecla baixa em
    relevo), a dica do manual e o horário do turno são papéis colados com fita (a plaqueta do turno saiu; na parede, a
    placa esmaltada da companhia telefônica) e o rádio ganhou um alto-falante perfurado na altura toda.
63. #luz #sala #saiu
    Clima noir: a sala fria e escura fora da luz da luminária (borda lisa, sem recorte), a luz dela mais forte e
    concentrada na mesa (o relógio ficava no escuro) e um brilho azul fraco vindo da janela (as faixas da persiana saíram).
64. #vista #clima #luz #som
    A noite lá fora: carros passando com a luz dos faróis atravessando a sala, relâmpago e trovão na chuva e um
    letreiro de neon de hotel falhando, com o reflexo vermelho na parede.
65. #vista
    A vista da janela pela referência do usuário: a telefonia no alto do morro, a rua dela com os carros passando e a
    esquina, a calçada, a mureta de tijolos com a escada descendo para a rua da cidade (no lugar do arbusto). Depois,
    profundidade: a cidade em camadas na névoa, a avenida fugindo para o horizonte e a luz e as sombras no chão; a
    esquina foi para a direita e, no lugar da escada, prédios de perto com o poste e o homem na frente; volume e
    escala nas coisas de perto; o homem e o carro na proporção da porta e dos andares dos prédios. Por fim, a vista
    passou a ter uma câmera de verdade (a sala no segundo andar, tudo em metros e na distância), e o carro é visto de cima.
66. #vista #camera #saiu
    A vista virou uma rua de verdade passando ao lado do prédio (referência do usuário). Primeiro com a câmera de lado
    e o ponto de fuga à esquerda (a rua parecia uma rampa vista de cima e os prédios, tortos); depois, a pedido, como
    uma cena 3D pensada antes: câmera na altura de quem está na janela, de frente para a rua, que passa na horizontal e
    continua para os dois lados, prédios verticais apoiados na calçada de lá, o cruzamento indo embora para o único
    ponto de fuga com a igreja no fim, o homem embaixo do poste da esquina, um carro passando e o arbusto plantado na
    nossa calçada. A mureta saiu. Depois, a nossa calçada, o nosso meio-fio e a faixa de pedestres saíram da vista (diziam
    que a nossa parede ia de frente, contra a diagonal da sala) e o arbusto passou para o primeiro plano, com a janela.
67. #janela #camera
    A janela parecia vista de cima: pela câmera, a parede dela fica a uns 44 cm da cabeça do operador, e o peitoril
    estava 38 cm abaixo dos olhos. O peitoril subiu (menos inclinado, a persiana subiu junto) e o vão ganhou a espessura
    da parede (o lado de dentro do batente, o fundo do vão, o vidro recuado com o caixilho de verdade) e um peitoril de
    dentro com o vaso.
68. #camera #janela #vista #sala
    Os olhos desceram para dentro da tela (`EYE`), na altura da janela: ela ficou reta, com a travessa no horizonte,
    o peitoril descendo pouco e a parede dela mais longe da cabeça. A vista da janela passou a usar o horizonte da sala
    (uma câmera só para o cenário inteiro). Em janela larga, os objetos da ponta entortam mais. Depois os olhos desceram
    mais (a janela e a vista juntas) e o armário cresceu para ~1,5 m, com prateleiras até a mesa.
69. #camera #sala #janela #vista #saiu
    Acabamentos da câmera nova: o ponto de fuga foi para o meio dos objetos da mesa (entortavam), o armário alto ganhou
    venezianas embaixo, puxador no meio e desgaste, um conduíte com a caixa de passagem leva os fios da mesa comutadora
    para o teto, o reflexo no vidro passou a ser a sala espelhada pela câmera e a vista ficou mais noir (asfalto escuro
    com as poças de luz dos postes, a vitrine do bar atrás do homem, a marquise do hotel, janelas fundas e névoa no
    fundo). O aquecedor embaixo da janela ficou de fora: com o peitoril a 24 cm do tampo, ele ficaria atrás da mesa.
70. #luz #vista #som #janela #saiu
    A luz da rua na mesa passou a sair da janela de verdade (o vão projetado no tampo); um pedestre passa de vez em
    quando pela calçada de lá; o carro na chuva chia na água e o neon do hotel estala quando falha (abafado, de longe).
    A luz dos faróis varrendo a sala saiu; o peitoril e a guarnição de perto, que pareciam um buraco escuro, ficaram na
    luz de fora; a vitrine do bar ficou com duas divisões, longe da porta.
71. #som #clima
    Sons da noite: o sino da igreja bate as horas de longe, a chuva cresce e diminui em ondas com as gotas no vidro e
    a calha pingando, a cidade se cala depois das 22h (menos carros e pedestres, grilos mais presentes), a luminária
    zumbe e estala quando pisca, a janela chocalha no trovão perto e os passos de quem passa soam de longe.
72. #objetos #mapa
    Os objetos da mesa girados uns graus, como largados (a pilha de listas desencontrada) em vez de retos e em
    fileira, e o mapa redesenhado como mapa de verdade (lia como papel quadriculado com um gráfico).
73. #objetos #pixel #testes
    Os objetos da mesa redesenhados na identidade do jogo: o tampo dos objetos chatos posto pixel a pixel na
    perspectiva (torto por transformação, os pixels esticavam), cores de papel envelhecido em vez de branco, menos
    ruído (letra de mão espaçada, miolo das listas liso), a capa da lista com o título em baixo-relevo; menores, menos
    girados e com mais folga (estavam apertados e se encostando). Os testes voltaram ao tempo de antes (a vista da
    janela não é mais desenhada sem tela).
74. #relogio #camera
    O relógio de flip ficou reto: meio virado para o operador, estava certo na perspectiva, mas parecia inclinado
    numa mesa plana (a única caixa alta girada entre as horizontais da sala).
75. #objetos
    A caneca redesenhada (parecia um balde): esmaltada de época, branco-gelo com a borda azul-marinho, alça em C e
    lascas, e o vapor do café subindo, que some com as horas porque o café esfria.
76. #objetos #mapa #lista #saiu
    O alfinete do mapa parou de piscar e brilhar com emergência (um alfinete não acende; a dica dele saiu) e as listas
    telefônicas ganharam detalhes: na capa, o título dourado, o fone, a etiqueta do ano, a marca de caneca e a ponta
    dobrada; nas lombadas, a etiqueta do volume; no miolo, as folhas em linhas finas (numa imagem posta pixel a pixel:
    desenhadas tortas na tela, viravam degraus e faixas), as beiras sujas e tiras marcando páginas.
77. #janela #saiu
    O vaso da janela foi refeito (um vaso de barro no tamanho dele na sala, posto pela câmera, com uma
    espada-de-são-jorge) e depois saiu, a pedido, com a planta: o peitoril fica vazio.
78. #objetos #pixel #prancheta #lista #caderno #mapa #jornal #saiu
    Os objetos da mesa na identidade da mesa comutadora (referência do usuário): o risco fino (texto, pauta, colunas)
    desenhado na tela em pixel art, não no papel em perspectiva (virava moiré); papel com 1 px de beira; os mais claros
    da tela (caneca, miolo das listas, capa) um tom abaixo; a capa das listas com o grão do papelão e o friso; o
    prendedor da prancheta em mapa de pixels niquelado, de pé (`CLIP_ART`), e a folha nova girada com a ponta dobrada
    (`SHEET_TURN`); a alça da caneca mais grossa; o lápis e as tiras do caderno com luz e sombra; o mapa e o jornal na
    paleta de papel envelhecido. Uma plaqueta de latão gravada no relógio foi testada e saiu (não combinava).
79. #clima #som #vista #saiu
    A chuva mais realista: o som em estéreo, com corpo grave (era um chiado agudo e parado) e vindo mais da janela, à
    direita; os pingos na janela caindo rápido, em riscos, e em maior quantidade. Gotas soltas (batidas, bolhas de poça,
    gotas no vidro, o pingo da calha) foram testadas e saíram: soavam como "tic".
80. #clima #vista
    A névoa de verdade: um véu liso que esconde o longe e engrossa rente ao chão, fiapos passando pela rua e as luzes dos
    postes e do neon espalhando nela (eram faixas retangulares no vidro, com a rua tão nítida quanto numa noite limpa).
81. #vista #misterio #som #saiu
    A cidade mais viva: mais gente na calçada, às vezes em dupla, rareando até as 22h, quando ninguém mais passa; o
    homem do mistério chega andando, fica 15 min embaixo do poste e volta andando antes de ligar (antes, aparecia e
    sumia parado, por 5 min). Os passos de quem passa saíram: de dentro do prédio não se ouviriam.
82. #ferramentas #lista #caderno #prancheta #jornal #mapa #luz
    As ferramentas abertas no material dos objetos da mesa (as cores em comum no `Pal`): a lista com a capa de papelão
    e as abas em tiras de papel, o caderno em couro (no lugar do pano verde, para se diferenciar das listas coloridas)
    com as tiras dos pendentes, o registro na tábua com o prendedor niquelado e o cabeçalho com o fio vermelho, o jornal
    no papel-jornal com a foto e as colunas (e aberto para ter arte e textos por noite) e a luz da luminária no papel.
    O mapa aberto deixou de parecer um diagrama: ruas de papel, bairros nos tons do mapa da mesa, casas e quintais,
    lugares de telhado de barro, a praça, a sanfona e o selo.
83. #mapa #objetos
    O mapa da mesa virou a miniatura fiel do mapa aberto (as mesmas folhas, quarteirões, casas, lugares, praça, zona
    rural e selo; o papel na proporção dos bairros atendidos). Antes, era uma cidade inventada, com rio e trem que o
    mapa aberto não tem.
84. #desempenho #som
    Desempenho (medido com tela e sem vsync): a sala parada engasgava 3 a 4 vezes por segundo (o relógio virando e o
    neon a redesenhavam inteira, ~20 ms cada vez), e a cada quadro com a luminária piscando, no relâmpago e com o papel
    de uma ferramenta deslizando; eram ~2200 chamadas de desenho por quadro, mil delas do escuro da sala. Polígonos
    viraram primitivos, o que muda sozinho saiu da sala (a camada de cima, a textura do relógio, as duas camadas da
    vista), a tela do cenário só se desenha quando muda e os sons são sintetizados nos núcleos todos: na chuva, de 7,6
    para 2,0 ms por quadro, sem nenhum acima de 8 ms, e a abertura 0,6 s mais rápida.
85. #luz #clima #saiu
    A luz da rua na mesa maior e mais suave (era um quadrado pequeno perto da parede) e o relâmpago só no que a janela
    alcança, quase branco e nítido: a parede do fundo com a sombra do armário, a frente do armário, a lateral da mesa
    comutadora e a janela com a cruz do caixilho no tampo (era um véu azul e liso na tela inteira, até na frente da
    mesa comutadora).
86. #luz #vista #clima #som #saiu
    Ambiente melancólico, noir e aconchegante: a luminária esquenta no começo do turno, a pausa abafa o som, o prédio
    da esquina virou apartamentos com varanda e a TV piscando na janela, janelas acendem de madrugada, a chuva muda de força durante a noite (com as poças crescendo), nuvens passam pela
    lua, o arbusto balança em rajadas, o vidro embaça nos cantos e as
    gotas do vidro fazem manchinhas de sombra na luz da rua na mesa. O semáforo do cruzamento foi testado e saiu. Ficaram de fora a pedido: chaminés (raras no
    Brasil), o vento na fresta, o prédio estalando e o grão de filme; a sirene das viaturas fica para depois.
87. #despacho #objetos #mapa #caderno #lista #saiu
    As máquinas do despacho (impressora, triturador e transmissor) não apareciam em lugar nenhum da sala: o mapa
    dobrado deu lugar a uma unidade de despacho na mesa, como um terminal antigo, com as três máquinas na base e o mapa
    de papel aberto sob o vidro no painel (um monitor foi descartado: fora de época e o mapa é de papel). As listas
    ficaram atrás, ao lado dela, e o caderno veio para a frente (as listas na frente o tampavam).
88. #despacho #mapa #ferramentas #interface #saiu
    O despacho aberto passou a ser a unidade de despacho de perto: o mapa sob o vidro na moldura de metal (sem a
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
89. #interface #tela #noites #jornal #caderno
    Revisão geral: a dica do manual cresce com o texto (cortava em 2 linhas), o jogo fica sempre em 1280×720 (o monitor
    largo esticava a sala) e o jogo ganhou data: começa na segunda-feira, 8 de outubro de 1973, mostrada no
    calendário do armário, na introdução, no jornal e no caderno (os bilhetes que citavam o dia da semana acompanharam).
90. #treinamento
    O tutorial virou um treinamento com a Cecília, telefonista veterana do Alto da Serra, numa noite 0 (sexta, 5 de
    outubro), antes da primeira: o FONE já na entrada 1, ela chama com a tecla Atender piscando, se apresenta, liga de
    novo pela entrada 2 e ensina, como colega, a lista, os cabos, o Transferir e a desmontar a ligação; comenta o erro e
    a demora quando está na linha (fora dela, só a dica do manual). Depois dela, um turno calmo; dá para pular o
    treinamento na tela inicial. A transferência guiada da noite 1 saiu. Em partes: caderno, emergência com o cartão
    e o resto ainda faltam.
91. #treinamento #conversa #saiu
    A Cecília falava rápido demais e o texto se acumulava: ela passou a falar mais devagar, em frases curtas (as
    falas longas foram quebradas). Uma pausa de leitura entre as falas foi testada e saiu a pedido.
92. #treinamento #caderno #prancheta
    Treinamento, parte 2: na última ligação, a Cecília ensina o caderno (as tiras, registrar as ligações dela como
    comuns, comentando o tipo errado) e a prancheta do registro.
93. #treinamento #despacho #emergencia
    Treinamento, parte 3: a Cecília liga pela entrada 3 fingindo uma emergência (fumaça numa casa) e ensina o
    despacho: marcar o local no mapa, triturar o cartão quando ela corrige o endereço, perfurar o tipo e a unidade,
    levar ao transmissor e ouvir o rádio; explica a barra de agravamento só de boca.
94. #treinamento #turno
    Treinamento, parte 4: a Cecília pede para o jogador deixá-la em espera (o FONE na entrada 1) e voltar, explica
    que quem espera demais desiste, e conta como termina o turno (23:40, Encerrar turno, registrar tudo, meia-noite).
95. #treinamento #consequencias
    Revisão do treinamento: a noite 0 não demite (`ShiftReport.fired`) e fecha com "Fim do treinamento"; a pausa não
    conta a demora nem a conversa dela; um cartão do endereço errado enviado antes da hora não vale como chegada (e o
    manual avisa quando os bombeiros ainda estão fora); o FONE fora da linha dela dá a dica de voltar; as fichas dela
    dizem "Treinamento" (a da emergência leva o local e o cartão); o caderno do treinamento é de 5 para 6; o botão de
    recomeçar aparece desde a noite 1; ao terminar, o manual lembra de registrar as fichas dela.
96. #voz #som
    Vozes: soavam "atrás de uma parede" (passa-baixa em ~1 kHz na sílaba). As de quem liga passam pelo barramento
    Phone, com a banda do telefone dos anos 70 (distorção leve do microfone de carvão, 300–3400 Hz, pico em 2 kHz); a
    desconhecida e o rádio continuam com o filtro próprio. Cada pessoa tem a sua altura, pelo nome (a mesma quando liga
    de novo), e a fala ganhou entonação: a voz cai ao longo da frase, a tônica da palavra sobe e o fim da frase desce
    (ou sobe na pergunta), em vez de um sorteio por sílaba.
97. #voz
    Entonação de pergunta e exclamação mais marcada: na pergunta a frase fica reta e as três últimas sílabas sobem em
    rampa; na exclamação a frase toda fica mais aguda e mais alta, a tônica com mais ênfase e o fim caindo mais.
98. #voz
    Sílabas atropeladas: a fala anda no ritmo das letras, e vogais a duas letras uma da outra ("sei o", "com a")
    saíam quase juntas. Uma sílaba só começa depois de 70% da anterior da mesma voz; a que chega cedo não toca (o texto
    segue no mesmo ritmo).
99. #voz
    Vogais nasais e consoantes: "ã", "õ" e vogal antes de "m"/"n" sem vogal depois ("também", "central") soam nasais
    (F1 mais baixo e fraco, ressoar do nariz); e cada sílaba ganha o ataque da consoante que vem antes no texto (estalo
    em p/t/b/d, chiado em s/f/ch/j e no "r" do começo, zumbido em m/n), em vez de um chiado sorteado.
100. #voz #debug
    O "a" saía forte demais: 2,5 dB a menos (`Sfx.VOWEL_DB`). O painel de debug ganhou abas (Jogo e Vozes); na de
    Vozes, o alfabeto (cada letra fala o nome dela) e uma caixa de texto para ouvir qualquer fala na voz escolhida.
101. #voz
    "Alô" falava só o "A": o intervalo mínimo entre sílabas descartava a que chegava cedo. Agora ela espera a vez e
    toca; só é descartada se já houver outra esperando (a fala não acumula atraso).
102. #voz #som
    Falas 2 dB mais altas (`Sfx.VOICE_GAIN`), com um limitador no barramento Voices: a tônica de uma exclamação (e a
    voz da desconhecida) já passava de 0 dB e podia estourar.
103. #voz #emergencia
    Emoção nas emergências: quem liga se agita com a barra de agravamento (voz mais aguda, trêmula, mais alta e mais
    rápida), cada um do seu jeito: o temperamento é sorteado por ligação (umas pessoas quase não mudam, outras disparam)
    e o retorno da mesma pessoa o mantém.
104. #emergencia #interface
    Erro ao perder a emergência com o operador na linha: a barra era desenhada no quadro em que ela passava ao estágio
    3 (perdida), que não tem cor nem nome. O `UrgencyBar._draw` agora confere se ela ainda vale.
105. #emergencia #despacho #radio #debug
    Emergências simultâneas, no máximo duas: cada uma com a sua barra (o painel mostra a da linha do FONE, o rádio
    acende na pior e avisa da outra); o cartão vai para a emergência do lugar marcado (fora de todas, para a que está
    sendo atendida). A terceira espera; o debug recusa.
106. #emergencia #despacho
    Viaturas pela quantidade de emergências: com duas em andamento, até duas de cada tipo (a de reserva sai da mesma
    base); com uma, continua uma de cada, e quem errou espera ela voltar.
107. #conteudo #emergencia
    Mais ligações: 13 transferências escritas (os destinos que ainda não tinham, várias com alternativa do mesmo
    ramo), 3 moldes de transferência, 14 emergências escritas (7 no Centro e 7 no Alto da Serra, dez por bairro),
    5 moldes de emergência (queda, fio caído, gás, atropelamento, desabamento) e 10 trotes.
108. #conversa #saiu
    Mais 13 assuntos de conversa fiada do cotidiano (novela, futebol, casamento da filha, circo, marido de plantão,
    bolo no forno, carta do irmão, novena, viagem ao médico, rua sem calçamento, crochê, farmácia de plantão, filme no
    cinema), cada um com uma resposta simpática e uma seca que continuam o assunto. Galinha, dente de leite, cachorro
    fugido e rádio novo saíram a pedido: assunto sem motivo para contar à central (curiosidade solta) parece aleatório;
    toda conversa fiada precisa de um gancho: novidade da cidade, o que a pessoa faz enquanto espera ou por que está acordada.
109. #conversa #misterio
    Revisão dos assuntos antigos pelo mesmo critério: horta e falta de luz (perto demais do mistério) trocados pela
    festa da vizinha e pelos cem anos do seu Geraldo; relógio adiantado pede a hora certa à central; o crochê é feito
    enquanto espera. Pedir desculpa por ligar tarde não faz sentido (é o horário da central): uma pede desculpa por
    incomodar com a central cheia, a outra por puxar conversa. A carta do irmão diz por que ela conta (precisava contar
    pra alguém).
110. #radio
    Rádio: cada mensagem leva na frente a hora em que chegou ("[21:04] Central, viatura 2…"), para saber se é nova e
    quanto a viatura demorou; um pouco mais de espaço entre as linhas da tela, que quase se encostavam.
111. #interurbano #mesa-comutadora #cabos
    Ligações interurbanas pelos troncos, como nas mesas de verdade (a ligação vai à central da outra cidade, onde
    outra telefonista completa). Primeiro passo, só para ver como fica: um banco de seis troncos (CAPITAL, NORTE, SUL,
    LESTE, OESTE, LITORAL, nomes provisórios) no canto de baixo à direita do painel, embaixo do banco C e na largura do
    B (`_draw_trunks`). Os cabos de conexão se juntaram perto do FONE (`PATCH_PITCH`; o resto da prateleira fica para
    os cabos novos que virão com os setores) e a plaqueta do fabricante foi para a plaqueta lisa do console, ao lado
    da miniatura. Depois, o FONE mais para a esquerda (`FONE_HOLE_X`, encaixe de 48 px) e os cabos logo depois dele,
    com 12 px entre um plug e o par seguinte. As tomadas dos troncos ainda não aceitam plug.
112. #cabos #camera #saiu
    O nome do FONE numa plaquinha de latão na frente do console, abaixo da beira da prateleira (gravado embaixo do
    buraco saía cortado: a beira da frente do buraco, desenhada por cima do plug, cobria o alto das letras). Uma
    chapa de latão em volta do buraco do FONE, para distingui-lo dos cabos, foi testada (de frente e depois em
    perspectiva, fugindo para o ponto de fuga) e saiu a pedido: ficou feia. Depois a plaquinha foi para o chão da
    prateleira, logo à frente do buraco, na perspectiva dos olhos (a placa inclinada para o ponto de fuga; as letras
    ficam retas, porque inclinadas linha a linha, mesmo com um terço do ângulo, as de 5 px viravam um borrão), e os
    cabos se afastaram do FONE (24 px até o primeiro plug).
113. #cabos #camera
    Teste: as duas pontas de cada cabo uma atrás da outra na prateleira, como nas mesas de verdade (`SHELF_HOLE_Y`
    atrás, `SHELF_FRONT_Y` na frente, uma coluna por cabo, `PATCH_PITCH`). Pela perspectiva, a da frente fica 20 a 32
    px à esquerda da de trás (na reta do ponto de fuga), e os guardados da frente passam na frente dos de trás. Com o
    desencontro variando a cada coluna parecia bagunça: a da frente ficou sempre meio passo à esquerda (`FRONT_SHIFT`),
    como tijolos, e o FONE 10 px mais longe da beira para a plaquinha caber.
114. #cabos
    Os cabos se espalham pela prateleira até o bloco interurbano, sem sobrar espaço (`_step`: do FONE até
    `TRUNK_GAP` antes do bloco, `trunks`, dividido pelos plugs; com mais cabos, o passo encolhe).
115. #cabos
    As duas pontas de cada cabo juntas, como um par (a da frente encostada à esquerda da de trás, `PAIR_SHIFT`), e
    os pares a um passo igual até o interurbano (`_pitch`): fazem parte da mesma ligação, e alternadas uma a uma não
    dava para ver qual ponta era de qual cabo.
116. #cabos #camera #saiu
    Correção: a ponta da fileira da frente travava antes de entrar no buraco (o fio repousava na linha da fileira de
    trás e não descia até ele; agora cada fio repousa na fileira do buraco dele). A plaquinha "FONE" inclinada pela
    perspectiva ficou ruim: agora é reta, na fileira da frente, centrada embaixo do buraco do FONE.
117. #cabos #setores #camera
    Volta a 3 cabos; os dois lugares que sobram ficam sob um tampo cada, porque cada setor novo vai liberar um par
    (`SHELF_SLOTS`, `_draw_cover`). O tampo foi primeiro um retângulo reto, depois na perspectiva exata (o usuário
    pediu o ângulo de visão), mais à esquerda (ancorado no meio do fundo), um por par, na inclinação dos pares de
    buracos (na exata ficava inclinado demais ao lado deles), mais largo (fino demais) e com um parafuso em cada canto.
118. #interurbano
    Interurbanos funcionando: as tomadas do banco INTERURBANO são destinos (troncos 901–906); quem liga pede a cidade
    e diz o número de lá; o operador liga a saída no tronco, transfere, passa o número à telefonista da outra cidade
    e ela completa. Tronco errado: o número não é de lá.
119. #cabos #mesa-comutadora #disposicao
    A prateleira ficou mais funda: o painel da mesa comutadora recuou 16 px para a parede (a faixa do bilhete do turno
    e a margem de cima cederam a altura; o fundo do tampo, a sala e o ponto de fuga ficaram onde estavam) e as duas
    fileiras de buracos se afastaram do rodapé do painel, da beira da frente e uma da outra, para os cabos terem
    respiro (`SHELF_HOLE_Y`, `SHELF_FRONT_Y`).
120. #desempenho #mesa-comutadora #cabos
    Análise de desempenho e as correções dela: a mesa comutadora em camadas (o painel parado, as lâmpadas, as
    tomadas com a luz da sala e os fios, cada uma redesenhada só quando o que mostra muda: a lâmpada piscando não
    redesenha mais a mesa inteira) e o trançado do fio numa chamada de desenho só. O fio que parecia demorar ~10 s
    para dormir era o mouse passando pela janela durante a medição: sem ele, os fios assentam e dormem em 2 a 5 s, e
    a física ficou como estava.
121. #setores #cabos
    Cada setor entregue ao operador traz um par de cabos: o lugar tampado na prateleira abre e o cabo novo está lá
    (branco na noite 5, com o Centro; preto na noite 9, com o Alto da Serra; `patches`, pelos setores atendidos).
122. #interurbano #calculografo #carimbo #consequencias
    Bilhete de tarifação dos interurbanos: um calculógrafo na mesa começa a contar sozinho quando a outra ponta
    atende e, quando a conversa acaba, imprime o bilhete; o operador arrasta o carimbo até o bilhete e o bilhete até
    uma caixinha, e guardado sem carimbo dá advertência leve.
123. #calculografo #prancheta #disposicao
    Sem lugar na mesa para o calculógrafo, ele ficou no lugar da prancheta do registro, que passou a ficar pendurada
    ao lado da mesa comutadora.
124. #debug #interurbano
    O painel de debug toca um interurbano na hora (botão Interurbano, num tronco livre).
125. #calculografo #carimbo
    Bilhetes e carimbo do calculógrafo soltos na mesa dele: pegos, levados e soltos em qualquer lugar (antes, o
    arrastar do Godot, que só levava uma imagem até o alvo); o carimbo carimba o bilhete em que é solto.
126. #calculografo #objetos
    Na miniatura do calculógrafo da sala, o bilhete sobe da fenda enquanto é impresso.
127. #prancheta #camera #mesa-comutadora
    A prancheta do registro pendurada na lateral do painel da mesa comutadora, na perspectiva e no ângulo da sala (de
    frente, na parede, destoava).
128. #calculografo #carimbo #testes #consequencias #treinamento #caderno
    Melhorias do calculógrafo, sugeridas e aprovadas: o robô do turno carimba e guarda os bilhetes (medido: 1 a 2 por
    noite, sem efeito no ritmo); bilhete esquecido na mesa é advertência leve e a meia-noite espera guardá-lo; bilhete e
    carimbo sobem na mão e caem soltos como o cartão do despacho (`Lift`); o número do bilhete vai para o caderno; a
    Cecília explica o calculógrafo no treinamento; guardar a ferramenta com uma peça na mão a deixa na mesa.
129. #carimbo #prancheta #calculografo
    O carimbo do calculógrafo em 3/4, como na referência do usuário (tampo chanfrado, frente com "TARIFADO" gravado e
    cabo cilíndrico em cima; antes, visto de cima, era um bloco chato); o nome da prancheta, ao passar o mouse, saía
    escondido embaixo da mesa comutadora e agora vai todo para fora dela; o bilhete guardado desce para dentro da
    caixinha e some atrás da frente dela.
130. #calculografo #carimbo #som
    Três sugestões aceitas para o calculógrafo: com ele aberto, o bilhete sai da fenda da máquina no tempo da
    impressora e cai na mesa; o carimbo bate quando chega na mesa (o som na batida, não ao soltar, e o bloco se
    achata um pouco); e a borracha seca a cada batida (a segunda marca mais fraca, a terceira só um vulto que não vale)
    até ser passada na almofada, que ganhou função. A dica do primeiro bilhete fala da almofada.
131. #carimbo #saiu
    O carimbo do calculógrafo no modelo de uma nova referência do usuário (caixa preta com visor na frente, haste e
    bola vermelha em cima), no ângulo do jogo, de frente como da cadeira (a primeira versão seguiu o ângulo da imagem,
    girado, e saiu a pedido). Levar e soltar não carimba mais: o jogador põe o carimbo em cima do bilhete e clica nele
    para apertar; a almofada também se carimba com um clique.
132. #carimbo
    O carimbo de caixa preta com visor destoava da arte do jogo (preto e cinza neutros, vermelho saturado, plástico
    de outra época, volume chapado, sem a plaqueta das máquinas, maior que o bilhete): redesenhado, a pedido, na mesma
    forma (caixa, haste e bola) com os materiais da mesa: metal pintado das máquinas com a plaqueta de latão
    "TARIFADO", saia de níquel, a borracha aparecendo embaixo na cor da tinta, haste de níquel e bola de baquelite no
    vermelho dos cabos; mais baixo (98 px).
133. #calculografo #carimbo
    Melhorias gráficas do calculógrafo aberto, sugeridas e aprovadas: o visor de letras âmbar (cara de monitor, fora
    de 1973) virou contadores de tambor, um por entrada, que rolam a cada minuto; o tampo ganhou o veio e a borda da
    frente da mesa da sala; a máquina, os pés e a sombra na mesa; o bilhete, fibras, a beira serrilhada e o campo do
    carimbo (a marca caía em cima dos dados); a almofada, a tampa aberta e o brilho da tinta, que some ao carimbá-la;
    e a caixinha mostra a faixa azul dos bilhetes guardados e a ponta da marca nos carimbados.
134. #carimbo
    Mais acabamento no carimbo, sugerido e aprovado: a bola numa haste fina parecia joystick e virou um cabo torneado
    de baquelite (bola achatada, pescoço grosso, virola e ressalto de níquel), sombreado como esfera (as três fatias
    do `PixelArt.disc` davam cara de bola de praia); corpo de quinas chanfradas, mais estreito que a saia (o degrau),
    plaqueta presa por rebites em vez dos parafusos nos cantos (parecia caixa de ferramentas); tampo mais raso; mais
    luz na quina do tampo e na da esquerda; e a linha de contato embaixo da borracha. Ficou com 87 px de altura.
135. #carimbo
    O cabo do carimbo ainda estava estranho: contorno preto (o plug, a outra baquelite torneada do jogo, não tem),
    sombreado calculado com faixas serrilhadas, pixels soltos e o brilho como uma mancha grudada na beira, o pescoço
    mais claro que a parte de baixo da bola e entrando seco nela (cogumelo com palito). Refeito em texto no
    acabamento do plug (`HANDLE_ART`: faixas de pé no vermelho dos cabos, a bola em pera, um tom mais clara em cima e
    mais escura embaixo, o pescoço afinando e alargando até o anel, a virola e o ressalto de níquel), com 28 px de
    largura.
136. #carimbo
    O carimbo ainda não parecia um carimbo e o cabo estava achatado: o usuário mandou a foto de um numerador automático
    de escritório (Nykon) para servir de base. Redesenhado nele: o cabo de baquelite preta em cogumelo, alto, torneado
    linha a linha (`Toll._knob`), sobre a haste cromada e o anel; o corpo de níquel com o painel rebaixado e a etiqueta;
    embaixo, entre as pernas com parafusos, as rodas de algarismos e a língua de latão; e a sapata com a borracha na
    janela. Apertado, o corpo e o cabo descem pelas pernas.
137. #carimbo
    O carimbo precisava ser mais fino e visto de cima para baixo, como na referência em pixel art que o usuário mandou
    (o mesmo numerador): 88 px de largura em vez de 128, o tampo oval do cabo, o tampo do corpo e a sapata vistos de
    cima, as pernas mais altas e a sapata com a janela, por onde se vê o bilhete embaixo e a marca depois de carimbar.
    A marca do bilhete encolheu para caber na janela (64×20: o fio duplo e "TARIFADO"; o nome da central saiu dela).
138. #carimbo
    Dois ajustes no carimbo: apertado, ele desce até as rodas de latão encostarem no papel, na janela da sapata, e só
    então a marca aparece (`Toll._touch`, no meio do aperto, `PRESS` 39 px); e as pernas descem até o fundo da sapata,
    com a janela entre elas (antes, a sapata com os dentes parecia solta embaixo das pernas).
139. #calculografo #carimbo
    O bilhete não saía pelo buraco da impressora: impresso com o calculógrafo fechado (o caso comum), ao abrir ele já
    estava deitado na mesa. Agora espera na fenda (na sala, a ponta de pé) e sai dela quando a ferramenta abre. E a
    marca do carimbo ganhou três linhas: a data da noite pequena em cima, "TARIFADO" médio e "SÃO SOTERO" bem pequeno
    embaixo (64×32; a janela da sapata, o aperto e o bilhete, 140 px, cresceram junto).
140. #carimbo
    Mais detalhes no carimbo: as molas de retorno sob as pontas do eixo, que encolhem no aperto; o seletor de latão
    com as marcas gravadas e a alavanca serrilhada (no lugar da língua lisa); no cabo, o medalhão de latão de um
    fabricante inventado e o reflexo quente da luminária; e a sombra da armação em duas camadas (curta e escura
    encostada na mesa, longa e fraca), sem a faixa mais escura onde a sombra do corpo caía em cima da das pernas no
    aperto. A marca vermelha, que estava simples demais: moldura grossa de cantos redondos com um fio fino por dentro,
    traços dos lados da data, "TARIFADO" em negrito, estrelinhas dos lados de "SÃO SOTERO" e a tinta falhando e
    carregando como a de uma borracha de verdade (64×34; a janela e a sapata cresceram junto).
141. #carimbo #som #saiu
    Ajustes do carimbo: as molas de retorno saíram (não gostou; voltaram os parafusos de latão das pernas); o seletor
    perdeu o "0 1 2 D", que não dava para entender (o modo de repetição dos numeradores de verdade), e ficou com riscos
    gravados; o aperto parecia não encostar (as rodas paravam no meio da janela, com o papel à vista embaixo delas):
    agora desce até as rodas tamparem a janela toda, e a sombra encurta perto do papel; e a batida ganhou impacto:
    desce acelerando, para seco no papel um instante e volta freando, a mesa sacode (o que está nela pula e assenta) e o
    som soma o estalo do metal ao baque.
142. #debug #calculografo
    Debug só para imprimir bilhetes: "Imprimir bilhete" no painel (F1) solta um bilhete de tarifação sem ligação,
    como se um interurbano tivesse acabado agora, para testar o carimbo e a caixinha sem esperar uma conversa.
143. #carimbo
    Carimbado um pouco fora do bilhete, a marca saía em outro lugar (era empurrada para dentro do papel). Agora sai
    onde a janela do carimbo estava, cortada na beira do papel; com menos da metade dentro é borrão e não vale (dá
    para carimbar de novo, e o borrão continua no papel). Das sugestões (marca cortada, tinta na mesa, ímã no campo,
    não deixar carimbar na beira), o usuário escolheu a marca cortada com a regra do borrão.
144. #calculografo #objetos
    A miniatura do calculógrafo na sala não batia com a ferramenta aberta (a fenda no tampo, um visor com três pontos,
    sem o relógio, sem a mesa dele). Das sugestões, o usuário quis as duas: a máquina refeita pela aberta (mostrador
    com os ponteiros, os dez contadores acendendo pela entrada, a plaqueta com a luz, a fenda embaixo, de onde o
    bilhete sai para a mesa) e a mesinha dela na sala, com a almofada, os bilhetes soltos, a caixinha e o carimbo onde
    o jogador os deixou (de longe se vê um bilhete esquecido).
145. #cabos #calculografo #carimbo #objetos #jornal #despacho
    As proporções da sala não faziam sentido: os plugs (18 × 93 px, uns 12 cm em pé) ficavam maiores que o carimbo,
    as listas e o relógio. O usuário quis as duas sugestões, uma depois da outra: os plugs de volta a uns 2/3 e mais
    finos (14 × 66 px, uns 2 × 9 cm; buraco da prateleira, fio e plug encaixado afinaram junto; as tomadas ficaram) e o
    calculógrafo da sala maior (de 14 para uns 22 cm, com um carimbo novo em pé, de pixel art, como o da ferramenta).
    O dobro não cabia na fileira da frente em 1280: o jornal ficou dobrado mais estreito e a unidade de despacho foi
    recuada, para a máquina não tampar a base dela.
146. #mesa-comutadora #saiu
    A mesa comutadora menor, para as coisas não ficarem tão espaçadas nem tomarem tanto da mesa da sala (588 × 362
    para 492 × 304: colunas das linhas a 44 px, destinos a 24, a sobra de altura vira parede acima dela), e as
    tomadas na proporção dos plugs: o furo escuro de 6 px, a largura da luva. Vendo a primeira versão (aro de 12), o
    usuário pediu o aro maior com o mesmo furo (14 px, 3 de níquel) e menos protuberância. Chato, num tom só, perdeu
    os detalhes; ficou o desenho detalhado com os tons do níquel mais perto uns dos outros e a sombra curta. As
    lâmpadas acompanharam (14 px).
147. #disposicao #objetos #caderno #jornal #mesa-comutadora
    A mesa comutadora 40 px mais para a direita (`Gutter` antes da coluna da esquerda) e os objetos da mesa também,
    com respiro entre eles e entre a mesa comutadora e o primeiro (a mesma folga antes do primeiro, `_row` com um 0 na
    frente). Na fileira da frente não cabia, com o jornal: o usuário propôs trocar o caderno aberto por um **bloco de
    fichas de ocorrência** (a ficha da noite é entregue ao supervisor no fim do turno), com o jornal ao lado. Na mesa,
    a folha de cima com a fita de pano da colagem, o impresso, a pauta e o lápis (`_art_pad`, 26 de largura, era 46);
    aberto, o papel com a fita no alto e a beira das folhas e o papelão em volta (`PaperDeco`); nos textos, "caderno"
    virou "ficha"/"bloco de fichas" (título "Ficha de ocorrências"), nos três idiomas.
148. #calculografo #relogio #objetos #saiu
    Três pedidos do calculógrafo: (1) sem o relógio redondo na máquina, aberta e na sala, porque repetia o de flip
    ao lado (o visor dos contadores ocupa o lugar, cada contador no meio da célula); (2) a miniatura da sala estava
    larga demais perto da aberta (22 × 2,6 cm, uma tira; a aberta é 632 × 104): ficou com uns 18 cm, a máquina na
    proporção da aberta, e a mesinha na proporção da mesa aberta de agora (`Toll.NOMINAL` 632 × 354); (3) "torto na
    mesa": a almofada e a caixinha encostadas nos cantos passavam dos lados da máquina na sala (perto, a mesinha abre
    mais que ela) e o carimbo ficava na beira da mesa. Agora as duas ficam afastadas dos lados e de baixo na mesma
    medida (`Toll.INSET`), na mesma linha, e o calculógrafo da sala fica na linha do bloco de fichas.
149. #calculografo #disposicao #objetos
    O calculógrafo da sala mais para a esquerda, alinhado com a unidade de despacho atrás dele (o meio de um no meio
    da outra); o bloco de fichas e o jornal se distribuem no que sobra da fileira da frente, até a parede.
150. #camera #mesa-comutadora
    A lateral da mesa comutadora angulada demais para a esquerda: o ponto de fuga mais perto dela (`VP_AT` 0,32 →
    0,24; na tela, de x 700 para 664): a lateral fica a 10° da linha de visão, não 14°, e sai mais estreita e menos
    inclinada; a sala inteira acompanha.
151. #camera #objetos #janela #saiu
    Pedido de uma visão menos grande angular (objetos perto muito inclinados): com o tampo preso ao layout da tela,
    a distância focal quase não muda nada na tela; a inclinação só cai movendo o ponto de fuga. Testados e mantida a
    câmera, a pedido: olhos mais altos (`EYE` 170: a janela subia e a vista perdia o céu, como antes do item 68, e os
    objetos da frente encolhiam), o ponto de fuga à direita (`VP_AT` 0,35: a lateral da mesa comutadora alargava,
    contra o item 150) e metade de cada (`EYE` 150, `VP_AT` 0,30).
152. #mesa-comutadora #consequencias #conversa
    Escutar ligação: uma chave de escuta por linha entre a entrada e a saída (alavanca como nas mesas de verdade, pela
    foto do usuário), que sobe ao transferir e desce sozinha quando o destino atende; com o FONE na linha, Tab ou o
    clique na alavanca a sobe para ouvir os dois (murmúrio sem texto; as falas escritas, só quando o roteiro trouxer).
    O nome "SAÍDAS · CABO DE CONEXÃO" foi para baixo das saídas, miúdo. Escutar levanta a suspeita deles, que o
    jogador só percebe pela conversa (silêncio, "tem alguém na linha?"); cheia, denunciam a telefonista: advertência
    grave. Será usada na história (pessoas autoritárias pedindo para escutar).
153. #mesa-comutadora #consequencias #conversa
    Escuta afinada: tecla própria no console, Escutar (Z), que vira Soltar com a chave levantada (antes era o Tab, no
    Transferir); o FONE encaixando com a chave em cima também estala (tirar e pôr o FONE não burlava mais); a suspeita
    baixa devagar sem ninguém ouvindo (escutar aos pedaços vale a pena); a conversa anda ouvindo ou não (o que não ouviu,
    perdeu); ouvir todas as falas escritas liga os marcadores da ligação (`overheard_sets`); a denúncia só chega no
    relatório da noite seguinte.
154. #consequencias #conversa
    Escuta: desconfiança por ligação (`TransferCall.wary`, para quem mandar escutar alguém desconfiado ou distraído),
    as ligações do treinamento não se escutam e o robô curioso (`--nosy`) mede quanto dá para ouvir sem ser
    denunciado (~1/3 de cada conversa, soltando no silêncio) e que a escuta não atrapalha o ritmo.
155. #conversa #consequencias
    Escuta, preparando as conversas que o jogador vai precisar ouvir: com falas escritas, a ligação não acaba antes da
    última; toda conversa começa por um cumprimento de verdade, sorteado (texto, não murmúrio), para dar tempo de
    levantar a chave; e cada fala escrita ouvida pode ligar um marcador próprio (`overheard_flags`).
156. #conversa #conteudo
    Conversas de verdade na escuta, pelo motivo do pedido (quem pede remédio fala de remédio com a farmácia, quem pede
    quarto reserva noites no hotel), em dados fáceis de crescer: cada motivo da lista virou um `Motive` com a frase do
    pedido e a conversa juntas; o lugar atende com o próprio nome (`hello`) e a pessoa com um "alô". Escritas as 21 da
    Vila Serena (noite 1).
157. #conversa #conteudo
    Melhorias das conversas escutadas: quem atende tem voz própria (`voice` do contato, ou tirada do nome, sempre a
    mesma); depois da última fala escrita os dois se despedem e desligam (a linha fica livre antes); o teste confere as regras de escrita (sem o tipo do lugar, lacunas que existem, falas
    curtas nos três idiomas); lacunas sorteadas por conversa ({hour}, {wait}, {nights}, {street}...), para o que se
    ouve não ser sempre igual; e duas conversas por motivo, sorteadas.
158. #conversa #consequencias
    Escuta preparada para as conversas do roteiro: o jogador administra o tempo de escuta para pegar o máximo de
    palavras-chave (nomes de pessoas e ruas, telefones, horários), que vão para um documento a ser repassado a um
    interessado (documento e interessado ficam para depois). Palavras marcadas `[tipo:texto]` nas falas escritas;
    ouvida com todas as letras, a palavra fica guardada (`Eavesdrop.clues`).
159. #conversa
    As palavras-chave ouvidas ficam salvas para as noites seguintes (no progresso, com a noite, a hora, quem ligou e
    para onde).
160. #conversa #conteudo
    Mais conversas para escutar: duas por motivo do Centro e do Alto da Serra (como as da Vila Serena, com lacunas) e
    uma em cada transferência escrita das 50, de todos os setores, todas do cotidiano e sem palavras-chave (essas são
    para as conversas de roteiro). O teste passou a conferir todos os setores e as transferências escritas.
161. #conversa #conteudo #traducao
    Melhorias da escuta e do conteúdo: os contatos da lista saíram do `content.tres`, um arquivo cada em
    `data/directory/`, com os seus motivos e conversas; as traduções podem ser revisadas numa planilha (`--review` e
    `--apply`); a fala da escuta não cria mais um timer por letra; a palavra-chave pega faz o lápis riscar e fica
    sublinhada na tela; e as pegas vão para a página de anotações da lista telefônica, onde o jogador marca as que vai
    repassar (o repasse ao interessado vem depois).
162. #conversa #conteudo
    Duas regras para a escuta não virar receita: a palavra-chave aparece em lugares diferentes da conversa (no
    cumprimento, no meio, na despedida), para o jogador escolher a hora de entrar; e cada contato da lista tem a sua
    desconfiança (`DirectoryEntry.wary`: a pensão cismada percebe logo, o bar barulhento quase não nota), que vale
    também nas ligações de molde, para cada lugar pedir uma tática.
163. #conversa
    As anotações das palavras-chave: a mesma palavra ouvida de novo fica numa linha só ("×2") e herda a marca; o
    clique passa de normal a marcada para repassar, a riscada (vai para o fim) e de volta; o que não cabe segue nas
    páginas seguintes; só as palavras-chave do roteiro são guardadas, não a conversa. O teste confere a desconfiança
    por lugar, e o robô curioso mede quanto se ouve por entrada em cada uma.
164. #conversa
    A desconfiança na conversa escutada em estágios, não só o silêncio: conversa normal (sem desconfiança), silêncio
    (perceberam algo; a melhor hora de baixar a chave), a pergunta de um ao outro (desconfiaram) e, ouvindo até o fim,
    a resposta do outro (agora sabem que estão sendo ouvidos), antes da reclamação. Perguntas e respostas em pares
    convincentes (estalo da extensão, respiração, a voz ficando fraca; nada de chiado "da telefonia", específico demais). Lugar muito
    desconfiado pula o silêncio e vai direto à pergunta. E o jeito de atender de cada lugar dá a pista da desconfiança
    dele (a pensão seca, o bar solto). Revisadas a pedido: quem pergunta é quem estava calado (a respiração
    só se nota calado; quem falava responde "Achei que era você..."), eco virou voz fraca e o "a essa hora" da rádio saiu
    (o turno começa às 18h).
165. #conversa
    Escutando o hotel, tudo passou rápido demais: não dava para ler e já tinham descoberto. A conversa escutada anda
    mais devagar que a fala com o operador (1,6×, e 1 s entre uma fala e outra) e a suspeita sobe em 40 s em vez de 25,
    para o silêncio cair no mesmo ponto da conversa.
166. #conversa
    Um intervalo entre as reações da desconfiança: depois do silêncio e da resposta, a conversa segue um pouco (6 s)
    antes da próxima, e o outro hesita 2 s antes de responder à pergunta (soltando a chave aí, eles desconversam). Nos
    lugares desconfiados as reações vinham coladas, sem tempo de ler e soltar a chave.
167. #conversa
    O silêncio parecia não fazer efeito: depois dele a conversa escrita voltava ao normal e eles se despediam antes de
    chegar à pergunta (a conversa andava enquanto eles desconfiavam). Agora, desconfiados e com o operador ouvindo, a
    conversa normal não anda: terminada a fala, ficam calados até a pergunta (ou até ele soltar a chave, e aí ela segue);
    depois da resposta, calados até a reclamação. A pergunta vem depois de uma pausa de 2 s, e a resposta 1 s depois da
    pergunta (a hesitação de 2 s do item 166 saiu).
168. #conversa
    6 a 20 s calados numa ligação não fazem sentido: cada estágio esperava a suspeita subir até o seguinte. Agora a
    suspeita só decide quando eles percebem algo; dali em diante, com o operador ouvindo, anda no tempo: ~3 s calados,
    a pergunta, a resposta 1 s depois e, sabendo, ~3 s calados e a reclamação (~12 s em qualquer lugar). Soltando a
    chave no silêncio, a conversa segue; no fim da pergunta, desconversam; depois da resposta, continuam sabendo e
    reclamam da próxima vez que se calarem. Saíram os níveis da pergunta e da certeza e a folga do item 166.
169. #conversa #interface #som #debug #testes
    Melhorias da escuta escolhidas pelo usuário: no silêncio dos desconfiados, o chiado da linha aberta sobe (dá
    para notar de ouvido); o lugar que denunciou fica mais desconfiado nas noites seguintes (+0,3 por denúncia,
    salvo no progresso); o painel de debug mostra a suspeita de cada conversa e força o silêncio; e um teste confere
    que, depois de uma pergunta sem resposta, cada fala escrita continua com quem a diz. A velocidade do texto saiu
    das configurações, a pedido: não faz sentido no jogo (o ritmo das falas é parte dele, como o da escuta).
170. #conversa
    Correção: quando o lugar pedido não atende, a conversa fiada começava no mesmo instante em que surgia a opção de
    oferecer a alternativa e atrasava o jogador. O tempo do destino chamando ("tuuu tuuu") contava como silêncio;
    agora, sem resposta, o silêncio recomeça dali, e nada de conversa fiada durante a conexão.
171. #conversa #testes #codigo
    Melhorias da escuta escolhidas pelo usuário: fechou-se a brecha de soltar a chave depois de eles saberem e nunca
    mais voltar (a denúncia agora é certa na hora da resposta; a reclamação ao vivo é só o que ele ouve se estiver na
    linha); o silêncio mostra um ponto por segundo na tela, para ver que é uma janela de tempo; o estado de cada
    conversa ficou num objeto só (`Eavesdrop.Talk`) em vez de quatro dicionários; e um robô descuidado no `run.sh`
    (`--careless`) confere que a punição funciona num turno inteiro.
172. #pixel #tela #relogio #jornal #mesa-comutadora #interface
    "Pixels duplos" (pedido do usuário, a começar pelo relógio): o que tinha pixel de 2 px ou mais ao lado dos de 1 px
    da sala ganhou detalhe de 1 px. Os algarismos do relógio com barras de 1 px (eram de traço de 2 px); as letras das
    chapas A/B desenhadas à mão em relevo (eram a fonte em 33); o nome do jornal na fonte ampliada pelo Scale2x em
    letra vazada (`PixelArt.big`; em 44) e a manchete em 11 em negrito (em 22); a folhinha do calendário mais larga (os
    números de dois algarismos se encostavam). E as resoluções: o cursor passou a ter a ampliação do jogo, com o mesmo
    filtro (era sempre 2×: em 1080p, a 1,5×, saía mais grosso que tudo), e a captura ganhou `--scale` para ver o jogo
    como ele aparece em cada tela. (O Scale3x, para as chapas, inventava bicos nas letras e saiu.)
173. #pixel #tela #interface #mesa-comutadora #saiu
    Base 960×540 (pedido do usuário, numa branch à parte, `improve/0000-base-960`): em 1280×720, a 1080p ficava em
    1,5×, macia pelo filtro; em 960×540 a 1080p é 2× exata (e 4K, 4×). Só ampliação inteira: o que não for múltiplo
    exato fica com borda escura (720p e 1600×900 em 1×, 1440p em 2×). Saíram o filtro "sharp bilinear" e a escolha
    "suave/pixel perfeito" das Configurações. Tudo foi reduzido a 75% (cenas, mesa comutadora com plugs, tomadas,
    lâmpadas, alavancas, chapas e carimbo da sala redesenhados, câmera e objetos da sala, física dos fios), menos o
    texto, que continua em 11: os números dos destinos passaram à fonte gravada, as teclas do telefone ficaram mais
    largas para "Transferir" caber, o nome do jornal em 2× (4× não cabia) e o painel do telefone um pouco mais alto
    (as opções da emergência não cabiam).
    O despacho não cabia (as três fendas da largura do cartão de 176 px passavam da unidade): a pedido, o cartão e
    as máquinas foram reduzidos na mesma proporção (cartão de 132 px), e o texto do cartão, da tira da impressora e
    dos avisos das máquinas passou à fonte miúda da mesa (em 11 o local não cabia); a fonte miúda ganhou a vírgula.
    Ajustes depois da base: as tomadas com 12×12 px, o furo redondo de 4 px (achatado em 10×10); a luva dos plugs
    centrada (tinha 5 px e pendia meio pixel para a direita) e o pino dourado 1 px mais alto (o plug com 51 px); a
    vista da janela mais longe (`OUT_F` a 75%: estava ampliada em relação à janela e perdia os detalhes); a janela
    mais baixa (`WIN_TOP`, `WIN_SILL`), com a persiana à vista abaixo do bilhete do manual, e a vista centrada no vidro
    abaixo dela (`OUT_DROP`: o horizonte lá fora desce com a janela).
    Acabamento em 960: o bilhete do MANUAL de espera encurtado nos três idiomas (sobrava "4)." sozinho na terceira
    linha), a coluna do caderno "Horário" virou "Hora" (passava da margem vermelha) e o texto do registro alinhado ao
    título e ao fio do cabeçalho (`CallLog.SIDE`).
    A vinheta da sala acabava 18 px dentro do console (uma faixa escura translúcida por cima das teclas e do rádio):
    agora acaba na beira de cima dele (`offset_bottom` -142). Os botões de volume da frente do console a 75% e a
    espaços iguais entre a miniatura do painel e a beira do móvel (passavam dela).
    Os números das plaquinhas das entradas (01–10) na fonte miúda do painel, no meio da chapa: na de 11 enchiam a
    chapa de alto a baixo, pareciam grossos e ficavam baixos.
    Pedido seguinte, o que ele queria: os nomes das seções do painel ("ENTRADAS · FONE", "SAÍDAS · CABO DE CONEXÃO")
    na fonte miúda gravada, como a legenda, e a faixa das entradas no meio entre a moldura e as plaquinhas (o nome em
    11 enchia a faixa e encostava nelas). O "·" entrou na fonte miúda. Os números das plaquinhas ficaram miúdos.
    Espaçamentos, segunda rodada (a pedido, com as pendências): a plaqueta do fabricante no meio entre os parafusos e a
    miniatura do painel; as teclas do telefone mais largas (92 px, a chapa com 3 px de cada lado: "Transferir" encostava);
    `DarkButton` com o relevo do âmbar num tom escuro (na pausa e no início eram blocos pretos sumindo no fundo) e, no
    início, os botões secundários da altura do "Começar turno"; o relatório na altura do texto (rola acima de
    `ReportView.MAX_LINES`), com um respiro antes do parecer; no calculógrafo, o bilhete cai à direita da almofada, não
    em cima do carimbo.
    O plug encaixado com mais detalhe: a beira dourada da luva de latão entre a tomada e o corpo. Um reflexo da
    luminária no corpo foi testado e saiu (caía no contorno aceso pela lâmpada, que já é o ponto claro dele), e uma
    bota de borracha em volta da saída do fio também (mais larga que o fio, ele parecia colado num caroço).
    Correções: o fio saía da ponteira 5 px no eixo do plug, que visto quase de frente tem ~3 px na tela, e passava
    deitado por cima dele; agora sai entre o eixo e a vertical, já caindo (`Cord.stub`). A caixinha dos bilhetes do
    calculógrafo mais larga que o bilhete (`Toll.BOX`, 204: na redução ficou com 176 e o bilhete com 190). O MANUAL
    num lugar fixo de duas linhas (`HintSlot`): com mais linhas, desce por cima das ferramentas em vez de empurrá-las.
    O estado escrito de cada linha em cima das lâmpadas ("LIVRE", "CHAMANDO") saiu: redundante com a lâmpada e a
    legenda das cores. (O texto ainda aparece no balão de informação da linha, `Main`.)
    Melhorias da base 960 (a pedido): as teclas do telefone numa grade de 2 × 2, liberando largura para a tela da
    conversa (numa emergência, a fala, as respostas e a barra não cabiam, o painel crescia e a sala pulava ~20 px
    para cima); o buraco do FONE perto da beira da prateleira (`FONE_HOLE_X` 14), para o nome gravado caber antes da
    ponta do primeiro cabo nos três idiomas (até "FONE" passava por baixo dela; os cabos contam de `CORDS_X`); no modo
    janela, a janela no maior múltiplo inteiro que cabe na tela (abria em 960 × 540 em qualquer monitor); lâmpadas,
    tomadas e chaves 6 px mais para cima, fechando o vão do estado escrito que saiu, e o título das saídas no meio
    entre elas e os bancos.
    O painel ainda crescia numa emergência (aviso, três fileiras de respostas e a barra passavam da altura da tela da
    conversa). A fonte não pode ser menor (11 é o mínimo da Departure Mono): o aviso virou a última linha das falas, em
    âmbar, em vez de uma linha à parte, e a barra de agravamento ficou numa linha só, o estágio à esquerda e a barra à
    direita.
    Pixels mais definidos (a pedido, das sugestões): a tela do jogo prende o desenho
    aos pixels (`snap_2d_*` na `View` do `GameView`). A fonte sem suavização foi medida e não muda nada (saiu da lista).
    A altura do painel de baixo travada: as falas encolhem até a mais nova, para caberem quatro fileiras de respostas
    com o aviso e a barra, e o teste de fluxo confere o pior caso estágio por estágio.
    O cartão, o bilhete e o carimbo voltaram a crescer na mão: sem crescer (só a sombra se afastando, para os pixels
    não dobrarem), o usuário testou e não gostou. #saiu
    O título das saídas ganhou a mesma faixa gravada do das entradas, de ponta a ponta do painel, separando a seção
    das saídas da dos bancos.
    A mesa comutadora recuou e ficou funda: o console um pouco atrás da borda do tampo (aparece um friso de tampo na
    frente dele) e o móvel indo quase até o fundo do tampo, com um vão pequeno atrás (o tampo vazio atrás dela sobrava).
    A vista da janela mais longe e sem nada importante escondido pela madeira: a câmera de fora recuou (a rua inteira
    cabe no vidro), o ponto de fuga dela foi para o vidro de perto, ao lado do montante (a rua do cruzamento e a igreja
    ficavam atrás dele), e a travessa do caixilho subiu para o alto, como uma bandeira (no horizonte, cobria o fim da
    rua e o pé da igreja). #janela #vista
    Os carros pareciam largos: o facho dos faróis era uma laje cinza de 8 m colada na frente deles; agora some aos
    poucos, em 5 m. A vista desceu um pouco (a rua parecia alta, perto do peitoril). A rua do cruzamento estava pobre e
    com janelas soltas ao acaso: agora as paredes têm andares, com a laje de cada um e as janelas em colunas, e as de
    longe não se amontoam num borrão; a cruz e o relógio da igreja ficaram do tamanho da torre (o relógio, com o
    brilho de antes, parecia um poste aceso). A cruz da igreja saía meio pixel fora do eixo da torre: a torre, a ponta e a cruz agora são
    simétricas num eixo de pixel. A frente dos carros vindo na nossa direção acendia lanternas vermelhas em vez de
    faróis (a caminhonete do outro lado parecia quebrada). #vista
    No painel de debug (seção Clima), fazer um carro passar lá fora, na mão de lá ou na de cá, sorteado ou do modelo
    escolhido. #vista
    A perua estava larga e baixa: mais curta (4,0 m) e mais alta (1,6 m), e o vidro de todos os carros reflete um pouco
    do céu (quase preto, sumia no asfalto atrás e o carro parecia só a lataria). #vista
    A picape do outro lado, passada a placa do hotel, saía com o teto quebrado: de viés, a parede de trás da cabine
    fica maior que o teto, e teto e vidros tinham quase o mesmo tom. O teto dos carros ficou mais claro que os
    vidros, a parede de trás da cabine tem a largura do teto e o vidro dela some quando fica estreito demais. #vista
    O fusca, quase passando, ficava com um borrão preto no alto e um buraco em cima: o para-brisa era desenhado
    também visto por trás (agora vidros e chapas inclinadas só saem virados para os olhos), a traseira do teto tinha o
    tom escuro do capô e havia degraus sem chapa entre a traseira, a tampa do motor e a frente. #vista
    Os carros ainda pareciam largos demais longe do meio da janela: a vista é grande-angular e a largura do carro se
    inclinava para o ponto de fuga; agora só 40% dela entra nesse recuo (`CAR_DEPTH`). As formas não se encontravam
    (capô, teto e vidros 10 cm para dentro da lateral deixavam frestas): agora vão de um lado ao outro. O baú do
    caminhão ganhou a parede da frente, acima da cabine, e a caçamba da picape a beira do lado de cá. #vista
    O estalo do letreiro de neon ao falhar saiu, a pedido (som `neon`). O reflexo dele na rua molhada saía embaixo
    da beira esquerda da caixa, e não das letras. #vista #saiu
174. #objetos #interface #som #desempenho #saiu
    No lugar do contorno amarelo e da caixa preta com o nome, sob o mouse: o objeto se ergue 2 px (no tempo do `Lift`,
    a sombra fica na mesa e se afasta) e, quando o mouse sai, assenta com uma batidinha bem baixa do material (papel
    nas listas, no bloco de fichas, no jornal e na prancheta; metal na unidade de despacho e no calculógrafo); o nome
    numa etiqueta de fita crepe (`TapedLabel`) acima dele. A pedido, o objeto vai para uma camada só dele: a sala
    continua se redesenhando só ao entrar e sair, e o hover medido ficou igual ao de antes. A etiqueta torta, com a
    letra subindo e descendo à mão, saiu a pedido (reta); a prancheta pendurada, em vez de subir, sai 2 px da lateral
    para a frente.
175. #janela #vista #sala #saiu
    Quem passava na calçada de lá tinha 8 px, um palito: a janela ficou maior (começa quase na quina, vai até perto da
    borda da tela e o peitoril desceu 3 cm) e o outro lado da rua veio para perto (calçada de lá a 7,6–9,4 m, era a
    11,2–14; `OUT_F` 38, era 32): quem passa tem ~15 px, com cabeça, chapéu e casaco. Os lugares ao longo da rua (o
    cruzamento, o hotel, o homem, o poste, a varanda) encolheram junto, para a vista continuar com os mesmos. A 3,6 m,
    o carro da mão de cá virava uma laje (o teto, de cima, cortado pelo peitoril): a nossa calçada ficou mais larga e
    os olhos lá fora desceram de 4,5 para 3,8 m. A travessa do caixilho saiu (fica só o montante), o peitoril de dentro
    ficou mais estreito (`SILL_D` 5, era 9) e a folhinha saiu da porta do armário para a parede, entre ele e a quina.
176. #sala #objetos #vista #janela #interface #som #saiu
    As sugestões do cenário: quem passa embaixo de um poste ganha a luz dele na beira (cima e o lado virado para ele;
    no guarda-chuva, que é fino, só o lado: aceso no alto, virava um bloco bege), na chuva quem passa se espelha na
    calçada molhada, a porta do bar ao lado da vitrine abre de vez em quando, com a luz do salão saindo pela calçada,
    e alguém sai por ela; e o guarda-chuva do operador pendurado pelo cabo no puxador do armário, molhado e escorrendo
    nas noites de chuva. O casaco da sugestão ficou de fora: na escala da sala ele tem a largura do armário e cobriria
    a folhinha, a janela ou o próprio armário. Ajustes: o armário e o conduíte mais para a direita (longe da mesa
    comutadora), o jornal mais para a esquerda e inteiro na tela (a fileira da frente para na beira dela), a janela
    mais alta (o peitoril desceu mais 3 cm) e a rua vazia embaixo do arbusto coberta por uma cerca viva até o batente.
    Extra: um clique na persiana a fecha, descendo lâmina a lâmina até o peitoril, e outro a abre; fechada, ela tampa
    a rua, a luz dela na sala e o brilho das luzes de lá.
177. #vista
    Quem passava aparecia e sumia de uma vez na beira esquerda do vidro: com a rua mais perto, o vidro mostra uns 11,5 m
    para cada lado, e eles andavam só de -11 a 11 m. Voltaram a andar de -16 a 16 m (`WALK_SPAN`), entrando e saindo
    por trás dos batentes; o homem do mistério também vem de mais longe (`MAN_FROM` 14).
178. #sala
    O gancho do guarda-chuva ficava por cima do puxador do armário: agora passa por trás dele (o guarda-chuva é
    desenhado antes do puxador).
179. #vista #sala #objetos #som #interface
    Das sugestões, o usuário quis: alguém fumando na varanda do apartamento de vez em quando (a brasa acende a cada
    tragada, na frente da janela da TV); um gato em metade das noites, na marquise do hotel ou no gradil da varanda
    (uns pixels maior que o de verdade: com 3 px não se via que era gato); bicicletas passando junto do meio-fio de lá,
    às vezes com a campainha, e o ônibus da linha nos horários dele (19h05, 20h35, 22h05, 23h20; sorteado, raro como
    foi pensado, quase nunca apareceria num turno de 8 minutos); a mancha de umidade na quina, que cresce com as
    noites de chuva (salvas no progresso) e fica molhada nas noites de chuva (no escuro da quina, só as marcas claras
    da água aparecem: o corpo escuro sumia); a caneca clicável, um gole por clique até a borra, com o vapor sumindo;
    o armário clicável, abrindo e fechando a porta (o guarda-chuva vai com ela); e quem atende os telefones da vista:
    transferida a ligação para o Hotel Estrela ou o Bar do Zé, alguém vai até o telefone e fica nele enquanto a
    conversa dura (a ligação não sabe o número de quem liga: só o lado de quem atende aparece).
180. #objetos #luz #despacho #calculografo #setores #pixel #saiu
    Correção do usuário: a entrega dos setores vai ser consequência da história, então nada na mesa anuncia ou data a
    abertura de um banco (um aviso colado com a data foi sugerido e recusado). Das sugestões revistas: o lápis do bloco
    de fichas muda de lugar a cada ficha registrada; o jornal, depois de aberto, volta à mesa dobrado mais uma vez, com
    os classificados para cima e girado para o outro lado; e a fileira da frente da mesa ganhou luz (da poça para a
    frente, a luz da luminária vai mais longe, no escuro da sala e no de cada objeto). O cartão do despacho na mão
    entorta os pixels (ampliado 6% por escala, repete uma coluna a cada 16), e as correções foram testadas e saíram:
    só a sombra se afastando, sem crescer (estranho: puxado para cima, um cartão chega perto); redesenhado 6% maior com
    as letras do mesmo tamanho; e redesenhado 25% maior com a fonte miúda um pixel maior (4×6). A pedido, ficou a
    escala de antes, com os pixels tortos na mão.
181. #interface #consequencias #luz #sala #vista #som
    Das sugestões de visual, o usuário quis: o relatório do supervisor como um memorando de verdade (papel timbrado com o
    fone e o nome da companhia, o fio duplo, as dobras em três e as fibras; o texto datilografado, com a tinta da fita
    variando de letra em letra; cada advertência com o carimbo da gravidade na cor dela, como os do caderno, a borracha
    falhando; o parecer escrito à mão na caneta azul, com a linha subindo e descendo, e a rubrica do supervisor; a sala
    escura à vista atrás dele, não mais o preto); a abertura da noite como o recado do supervisor num bilhete com fita
    preso no painel da mesa comutadora, a sala escurecida atrás e clareando quando o turno começa (como se joga, num
    papel de MANUAL como o da parede: em cima do painel, o texto solto não se lia); a pausa e as configurações num papel
    com fita; o miolo da poça de luz da luminária mais quente (só o meio clareia); na parede do fundo, manchas leves no
    reboco, a marca de um quadro tirado com o prego e uma tomada de baquelite com o fio (embaixo dela, ficava atrás das
    listas); um táxi parando no hotel duas vezes por noite, com o passageiro descendo com a mala e entrando, e a porta do
    carro batendo (parado na frente da porta, metade dele ficava atrás do montante: para um pouco antes); um vira-lata
    caramelo trotando pela calçada de lá (escuro, sumia nela; ele e o passageiro do táxi só até as 22h, quando a rua
    esvazia para o homem do mistério); e mariposas em volta dos postes nas noites limpas.
182. #consequencias #jornal #saiu
    O jornal da manhã saiu do relatório do supervisor: o jornal já vem na mesa na noite seguinte, com as mesmas
    manchetes, e repeti-las no memorando era redundante.
183. #vista
    Quem passava na calçada de lá era sempre a mesma silhueta preta, só com ou sem chapéu: cada um ganhou a sua roupa
    (`_walker`), em cores apagadas pela noite como o pelo do vira-lata (`WALK_COATS`, `WALK_DRESSES`, `WALK_LEGS`,
    `WALK_SKIN`, `WALK_UMBRELLAS`), que esquentam um pouco embaixo dos postes: de vestido ou de calça, de casaco curto
    ou comprido, de chapéu, de boina com pala, de lenço na cabeça ou sem nada, às vezes com bolsa no ombro ou pasta na
    mão, e o guarda-chuva de cada um na sua cor. O homem do mistério continua preto.
184. #pixel #mesa-comutadora #cabos #despacho #calculografo #sala
    Sem contorno preto nos objetos (pedido do usuário, antes do plano hi-bit: "seguindo uma linha mais realista, linhas
    pretas tiram essa sensação"). A beira quase preta (`EDGE_DARK`, `Pal.EDGE`) em volta das peças virou o tom da
    própria peça, na luz em cima e à esquerda e na sombra embaixo e à direita (`Switchboard.rim`): o aro das tomadas e
    das lâmpadas e a porca das chaves na quina do níquel (`NICKEL_EDGE`), a alavanca com a beira do metal e da
    baquelite, as plaquinhas dos números, as chapas A/B e as tampas da prateleira, a plaquinha do FONE, a plaqueta do
    fabricante, a placa da companhia, a moldura de madeira do móvel e a fresta dela com o painel, a miniatura do
    console, a legenda das lâmpadas, as caixas das máquinas do despacho e do calculógrafo (sem a borda), os visores e
    as luzes delas (rebaixados: a sombra em cima, a luz embaixo) e a miniatura do despacho na mesa. O que fica escuro
    é buraco ou rebaixo (o furo das tomadas, as fendas, o rebaixo do vidro do mapa, as telas apagadas, os frisos
    gravados do painel) ou material preto (a baquelite, os pés de borracha). A interface (painel de baixo, bilhete
    do manual, quadro do turno) ainda não foi decidida.
185. #pixel #mesa-comutadora #cabos #luz
    As peças da mesa comutadora na luz da luminária, que fica à direita dela e no alto (antes a luz das peças redondas
    vinha do alto à esquerda, ao contrário da luz da sala no painel): tomadas, lâmpadas, porcas e alavancas das chaves,
    plugs em pé e encaixados, com as sombras dos plugs, dos fios e das tomadas caindo embaixo à esquerda
    (`Switchboard.LIGHT`, `_disc`). As peças da mesa da sala continuam com a luz delas. Um pixel de brilho do níquel em
    cada tomada, por cima da luz da sala. Sem o contorno preto, a tomada voltou a parecer uma cúpula saltando do painel
    (o usuário notou): a face do aro ficou chata, em três tons quase iguais, e só a quina de 1 px marca a luz e a sombra.
    A tomada virou um disco (`_jack_tex`) no lugar do mapa de pixels.
186. #mesa-comutadora #cabos #pixel #luz
    As tomadas pela referência do usuário (o visual do item 55 de volta: aro fino e furo preto largo): um aro de metal quente e abaulado em volta de
    um furo preto largo (6 px; era 4, e o aro de níquel cinza parecia chato e estranho), cada pixel do aro no tom da
    luz numa rampa de cinco, a luz vindo da luminária, à direita (a referência tem a luz à esquerda), e a descida até o
    painel mais escura no lugar da beira preta da referência (nesse tamanho, o aro ficava fino demais). No plug
    encaixado saiu a beira dourada entre a tomada e o corpo (a luva de latão, que o usuário não reconheceu), e a luz da
    lâmpada ou do aro aceso no plug desce da beira em degraus, em vez de só a beira acesa tomar o plug de uma vez.
    `--patch` no `shot` (um cabo encaixado no destino com o aro aceso).
187. #cabos #mesa-comutadora #saiu
    Um contrapeso em cada fio, como nas mesas de verdade (numa roldana embaixo da prateleira), puxando o fio para o
    buraco dele: encaixado ou na mão, a folga volta para dentro e o fio fica esticado, entrando no buraco na própria
    linha, só com a barriga do peso dele (maior quanto mais longe a tomada) e as dobras do pano quase alisadas (antes,
    com uma folga fixa, até 52 px no FONE, o fio ficava mole, deitava na prateleira e passava por cima dos plugs
    guardados); solto, o plug volta na hora, o fio acelerando (antes ele caía 0,35 s sem nada puxar e o fio recolhia
    sempre na mesma marcha; de longe, volta em 1,5 s, era 1,8). A primeira versão forçava o fio a sair do buraco para
    cima e com folga ainda grande: o usuário viu "um fio mole com uma parte dura perto do slot, deixando um bucho", e
    saiu. O brilho do trançado do fio passou para o lado virado para a luz da mesa, à direita (ficou do outro lado
    quando a luz das peças mudou, no item 185).
188. #cabos
    O contrapeso mais forte: o fio ainda ficava solto, encaixado e na mão. A folga caiu para poucos px (~1 a 4, pelo
    vão; era ~10 a 18: a barriga de uma corda presa nas duas pontas cresce com a raiz da folga vezes o vão) e a folga
    volta para o buraco mais depressa; o fio fica quase reto do buraco ao plug.
189. #objetos #luz #pixel
    Plano hi-bit (`PLANO_HIBIT.md`), dividido em sub-etapas para o usuário ver cada mudança antes da etapa inteira; a
    etapa 0 gravou as capturas e as medições de referência. Sub-etapa 1.1: as rampas de material no `Pal` (do escuro
    ao claro, a sombra fria e a luz quente; `Pal.ramp` escolhe o tom pela luz) e a caneca nelas: o esmalte branco-gelo
    em oito tons e a borda azul-marinho em cinco, cada pixel pela luz do cilindro vezes a do lugar (longe da poça, mais
    escura e mais fria, no lugar da imagem escurecida por cima). A primeira rampa, fria até o meio, deixava a caneca
    com cara de aço: só o fim escuro ficou frio. O usuário perguntou se a caneca estava transparente (já era assim; os
    tons novos deixaram à mostra): o que vem da janela era desenhado por cima dos objetos da mesa. Primeiro saiu a luz
    da rua no tampo (passou a ser desenhada antes dos objetos; um recorte em volta de cada um custava 2,2 ms a cada
    redesenho da sala) e a persiana descida (atrás dos objetos); o usuário mostrou que ainda sobrava o principal, a luz
    no peitoril, uma faixa clara atravessando a borda da caneca e o canto do relógio. Recortada pelo contorno (convexo)
    dos objetos, ficou pior: a luz aparecia recortada no formato da caneca, com o vão da alça escuro. A pedido ("a
    camada do copo não poderia ficar na frente da camada da luz?"), as camadas: os objetos da mesa foram para uma camada
    só deles, por cima da sala e da persiana e por baixo do escuro, e a luz do peitoril foi para a sala, antes deles,
    mais forte na medida do escuro que cai por cima; nada é recortado (só o relâmpago, que é somado por cima de tudo).
190. #sala #luz #pixel
    Plano hi-bit, sub-etapa 1.2 (começada em outra sessão, que deixou as rampas no `Pal`): a madeira do tampo escolhe o
    tom pela luz de cada lugar (`Pal.desk`, oito tons do quase preto frio ao castanho quente; `Pal.desk_edge` para a
    borda da frente), em faixas em volta da poça, com os veios e a beira de cada tábua um tom acima e a emenda dois
    abaixo, no lugar de um tom só com a poça e o escuro da sala por cima; a mesinha do calculógrafo aberto fica no tom
    de embaixo da luminária. As faixas em curva lisa deixavam a borda delas à vista, como uma luz em degraus (que já
    tinha saído a pedido): a troca de tom anda um pouco em cada linha, como um veio pegando a luz.
191. #mesa-comutadora #luz #pixel
    Plano hi-bit, sub-etapa 1.3, o móvel da mesa comutadora pela luz que a mesa já tem (a da luminária do teto, mais
    forte no alto à direita): a moldura de madeira, que não recebia luz nenhuma, escolhe o tom de cada pixel numa rampa
    (`Pal.cabinet`, com os três tons de sempre no meio), escura e fria no canto de baixo à esquerda e quente perto da
    luminária; no painel, o relevo (os filetes gravados, a beira rebaixada, as faixas de cada linha) pega o tom na
    rampa do metal (`Pal.panel_metal`) trecho a trecho. O campo do painel continua liso, com a luz da sala por cima:
    em faixas, pareceria luz em degraus ou metal escovado, os dois já recusados.
192. #luz #tela #pixel
    Plano hi-bit, sub-etapa 2.1: a gradação de cor do jogo inteiro, um shader na tela que mostra o jogo (o `Box` do
    `GameView`), suave: as sombras puxando para o azul da noite, as luzes para o quente e um pouco mais de contraste,
    ponto a ponto no pixel já ampliado (o pixel perfect continua). Uma conta com parâmetros no shader, em vez da tabela
    numa textura do plano: dá o mesmo e troca por clima e pela hora do mesmo jeito. A captura passa por ela
    (`--grade=0` sem) e o painel de debug a liga e desliga na hora, para comparar no jogo.
193. #luz #tela #pixel
    Plano hi-bit, sub-etapa 2.2: o usuário não notou a gradação da 2.1, então ela ficou forte o bastante para se ver
    (as sombras visivelmente azuis, sem clarear, a madeira e as lâmpadas mais quentes, mais contraste). Forte por
    igual, o papel da lista e do relatório amarelava e a beira mais escura do papel ficava laranja: o calor ficou nos
    tons médios e os tons claros (o papel, o texto claro) ficam como são. Conferidos com e sem: as ferramentas abertas,
    o painel de baixo numa emergência, o bilhete da noite e o relatório. A pedido, o amarelado um pouco mais fraco.
194. #luz #clima #tela
    Plano hi-bit, sub-etapa 2.3: uma gradação de cor por clima, trocada aos poucos (2 s) quando o clima muda: a noite
    limpa fica com a aprovada na 2.2 (mais contraste, luzes mais quentes), a chuva mais fria (as sombras mais azuis, a
    madeira menos alaranjada) e a névoa mais lavada, com menos contraste.
195. #pixel #objetos
    Plano hi-bit reordenado a pedido, pela recomendação e pelo que cada etapa precisa das outras: depois das feitas, as
    cores para o `Pal` e as rampas no resto do jogo (a etapa que mais muda a imagem e da qual as outras dependem), o
    movimento secundário, a luz da luminária num shader (menor depois das rampas, decidida pela lista da primeira
    sub-etapa), as outras luzes, o amanhecer e o fechamento. Sub-etapa 3.1a: as cores dos papéis (a lista, o bloco de
    fichas com o lápis, a prancheta, o jornal, os bilhetes e o carimbo do calculógrafo), no objeto da mesa e no papel
    aberto, saíram do código para o `Pal`, sem mudar nenhum tom: as capturas saem idênticas pixel a pixel
    (`tools/diff_shots.gd`, com as capturas em `--still`, sem a poeira do feixe, que muda a cada uma).
196. #objetos #luz #pixel
    Plano hi-bit, sub-etapa 3.1b: os papéis da mesa (as listas, o bloco de fichas com o lápis, o jornal, a prancheta
    pendurada e os bilhetes na mesinha do calculógrafo) trocam de tom pela luz parada no lugar de cada pixel, nas
    rampas dos papéis (`Pal.lit`: três degraus de sombra mais frios e um de luz mais quente), no lugar do preto
    translúcido por cima; a troca de degrau anda de uma linha do papel para outra, como no tampo. O papel aberto das
    ferramentas fica no tom de sempre, e o piscar da luminária continua escurecendo por cima, na mesma medida.
197. #despacho #mapa #objetos #pixel
    Plano hi-bit, sub-etapa 3.2a: as cores do mapa (o local marcado, a etiqueta do trecho), do cartão perfurado (o
    papel, a beira, a pauta, o furo, a unidade ocupada; o formulário é a tinta do carimbo de emergência do caderno) e
    das faixas de perigo da trituradora saíram do código para o `Pal`, com as capturas idênticas pixel a pixel. 3.2b:
    a unidade de despacho da mesa (o metal, o mapa sob o vidro, a base e o cartão saindo) no tom da luz parada, na
    rampa do metal e na do cartão, no lugar do preto translúcido por cima, num degrau só para o objeto inteiro (a
    troca de degrau andando de linha em linha, como nos papéis, listrava o metal como escovado); nas máquinas abertas
    do despacho e do calculógrafo, a beira das chapas em dois tons da rampa do metal de cada lado. O cartão, o mapa e
    os papéis abertos ficam no tom de sempre.
198. #mesa-comutadora #cabos #carimbo #painel #pixel
    Plano hi-bit, sub-etapa 3.3a: as cores dos metais e da baquelite da mesa comutadora saíram do código para o `Pal`,
    com as capturas idênticas pixel a pixel: o latão em duas rampas (o das plaquetas, dos aros da prateleira, do friso
    e das etiquetas das teclas; o dos plugs), a baquelite dos botões do console, os isolantes dos plugs, os parafusos,
    o níquel, os cabos, o aro das tomadas, a chapa do banco, o vidro da lâmpada, os números gravados e pintados, o
    estêncil, o balão, o poço das teclas, o carimbo do calculógrafo e a boca da caixinha.
199. #mesa-comutadora #calculografo #carimbo #luz #pixel
    Plano hi-bit, sub-etapa 3.3b: as peças de metal paradas do painel da mesa comutadora (as plaquinhas de níquel, o
    aro das lâmpadas, as porcas e as alavancas das chaves, as chapas dos bancos) num degrau da luz da sala no meio de
    cada uma, como o relevo: mais claras e quentes perto da luminária, mais escuras e frias longe dela. A máquina do
    calculógrafo da mesa, a mesinha, o carimbo em pé e a caixinha num degrau só da luz parada, no lugar do preto
    translúcido, como a unidade de despacho. Os plugs e os fios, que andam, continuam na luz multiplicada.
200. #sala #janela #objetos #relogio #pixel
    Plano hi-bit, sub-etapa 3.4a: as cores da sala (a parede e a da direita, o vão da janela, a persiana, a placa da
    companhia, o prego e a tomada, a folhinha, o conduíte com os cabos, o armário de aço com o cromado, as pastas, a
    etiqueta e o bilhete, o guarda-chuva e o cartaz) e as que sobravam nos objetos da mesa (o relógio de flip, o café e
    as lascas da caneca, o escuro embaixo do tampo) saíram do código para o `Pal`, com as capturas idênticas pixel a
    pixel (na noite limpa com a persiana fechada: a lua passando nas nuvens muda o brilho da janela na sala a cada
    captura). As duas luzes da vista que brilham no vidro ficam para a vista.
201. #sala #luz #pixel
    Plano hi-bit, sub-etapa 3.4b: a parede do fundo, o conduíte e o armário escolhem o tom pela luz da luminária na
    parede, em faixas em volta da boca do cone dela: mais frios longe, mais quentes e um degrau mais claros perto. Como a
    sala já escurece por cima com o escuro dela, a rampa só muda a cor e quase não muda o brilho (escolher o tom pela
    luz e ainda escurecer por cima dobraria o escuro). O armário fica num degrau só, com as sombras e as luzes do aço
    numa rampa fria e quente no lugar dele escurecido e clareado; o conduíte troca de tom onde a faixa o atravessa; a
    sombra entre as lâminas da persiana ficou fria. A pedido, as manchas do reboco ficaram mais fracas (`STAIN` de 0,75
    para 0,35). O peitoril e o vão da janela ficaram como estavam: já vão da luz fria da rua à madeira com a beira quente.
202. #vista #pixel
    Hi-bit 3.5a: as cores da vista (o céu de cada clima, o relâmpago, as estrelas, a lua e as nuvens, a cidade de
    longe e as janelas acesas, as fachadas e o prédio de tijolos, o asfalto, a calçada, o meio-fio e os postes, o bar,
    a porta e a marquise do hotel, a varanda, o relógio da igreja, o arbusto e as gotas no vidro) saíram do código
    para o `Pal`, sem mudar nenhum tom: os 54 tons tirados estão todos lá, e as capturas antes e depois ficam dentro
    do que a vista já muda sozinha (estrelas, nuvens, chuva). Carros, gente e o letreiro ficam para a 3.6.
203. #vista #luz #pixel
    Hi-bit 3.5b: as fachadas de lá, o prédio de tijolos com a varanda e as paredes da rua do cruzamento ganharam uma
    rampa por tinta: a quina, a divisa, o vão das janelas, a verga e as fiadas de tijolo descem para o azul da noite,
    e a cornija, as lajes e o peitoril sobem para o quente dos postes (antes, escurecidos para o preto e clareados
    para o branco). Na rua, as manchas, os remendos e o grão do asfalto e as juntas da calçada viraram tons das
    rampas deles, no lugar do preto e do branco translúcidos por cima, e a quina do meio-fio fica acesa e quente
    embaixo de cada poste (a face, de costas para ele, não). O céu, liso, e as janelas acesas, que são luz, ficaram.
204. #vista #pixel
    Hi-bit 3.6a: as cores dos carros (a lataria, o baú do caminhão, o céu refletido, os vidros, o cromado, a calota, o
    pneu, os faróis, as lanternas e a placa do táxi), de quem passa (as roupas, a pele, os guarda-chuvas, a pasta, as
    silhuetas e o recepcionista do hotel), do gato, do vira-lata e do letreiro do hotel saíram do código para o `Pal`,
    sem mudar nenhum tom: os 57 tons tirados estão todos lá, e as capturas ficam dentro do que a vista e a luminária já
    mudam sozinhas. Os tons escritos por números (a beira acesa de quem passa, a brasa, os olhos do gato, as mariposas,
    a luz da TV, a névoa) são luz e ficaram.
205. #vista #pixel
    Hi-bit 3.6b: a lataria dos carros e o baú do caminhão em rampas (`Pal.CAR_TONES`, `TRUCK_BOX`, o tom dela em
    `CAR_MID`): o arco da roda, o fundo e a parede da caçamba, a frente e a traseira, a parede do baú e o teto na sombra
    fria dela, a beira do para-lama do Fusca na luz quente, no lugar de escurecer e clarear por igual; as roupas de
    quem passa e o pelo do vira-lata escurecem pela sombra fria do `Pal.lit`; a caixa do letreiro do hotel ganha a
    beira tingida pelo neon quando ele está aceso. Sutil, como pedia o plano.
206. #vista #carros
    Os faróis e as lanternas dos carros: com a frente ou a traseira virada para nós, o farol (ou a lanterna) do lado de
    cá saía junto com o par daquela ponta, e a traseira do Fusca tinha três lanternas. A do lado só aparece na ponta
    que não está virada para nós (`_draw_car`).
207. #luz #sala #pixel
    Hi-bit 4.1 e 4.2: das cinco propostas de movimento (o feixe da luminária, a fumaça do cigarro na luz do poste, o
    reflexo da luminária no café, o neon do hotel no vidro, a ponta solta do cartaz com o vento), o usuário quis
    todas, uma por vez. O feixe da luminária no ar: uma faixa lisa e somada descendo da boca dela, mais densa no meio,
    sumindo para os lados e até o tampo, atrás da mesa comutadora, para a poeira ter onde aparecer; pisca e esquenta
    com ela. Com a força de 0,07 somava 1 ou 2 níveis por canal e não se via; ficou em 0,16.
208. #vista #pixel
    Hi-bit 4.3: a fumaça de quem fuma na varanda, que eram três pixels soltos na frente da janela acesa da TV (não se
    viam), virou o fio da brasa com o cigarro na mão e o sopro da tragada: uma nuvenzinha de grãos que sai da boca,
    sobe até a parede escura acima da janela, abre e vai com o vento, como o arbusto, mais quente perto do poste da
    esquina. Os grãos espalhados por uma conta só saíam numa linha reta; cada um ganhou o seu sorteio fixo.
209. #mesa #luz #pixel
    Hi-bit 4.4: a luz da luminária refletida no café da caneca, que era um risco parado na imagem dela, treme: dois
    pontos claros correm devagar ao longo do risco, acendendo e apagando fora de tempo, na camada da poeira (sem
    redesenhar a sala), seguindo a luminária; acabado o café, somem.
210. #vista #janela #luz
    Hi-bit 4.5: o letreiro do hotel refletido no vidro da janela da sala, como o fantasma dele (as letras de novo,
    fracas e deslocadas, a outra face do vidro), apagando com o neon e com o T falhando junto; na chuva, as gotas no
    vidro perto dele pegam o vermelho. Uma mancha vermelha lisa no vidro foi tentada antes e sumia debaixo do halo do
    letreiro.
211. #sala #som #pixel
    Hi-bit 4.6: a ponta de baixo da folhinha, do lado da janela, dobra em orelha (o canto vira a parede na sombra e a
    aba, o verso do papel) nas rajadas da brisa da noite limpa, no tempo exato do som: a força da rajada é a mesma
    onda gravada na brisa, lida pela posição em que ela toca (`Sfx.gust`). Levantando a ponta para a frente, só a
    sombra mudava, e ela caía na parede já escura; com a conta ao quadrado a orelha quase nunca passava de 1 px.
212. #luz
    Hi-bit 5.2: a luz da luminária começa a ir para um shader no `TextureRect` do `SceneView`
    (`lamp_light.gdshader`): por enquanto só a poça quente que soma cor, lisa, por cima do desenho de hoje
    (`Background.light`, `LAMP_LIGHT`, `Pal.LAMP_POOL`), com o vidro da janela de fora e o parâmetro da luz do dia
    (0 até a etapa 7). Uma chave no painel de debug ("Luz da luminária (shader)") e `--lamp=0` na captura comparam
    com e sem.
213. #luz
    Hi-bit 5.3: o escuro da sala (noir) saiu do desenho (`_draw_gloom`, uma grade de 40 × 24 na camada de cima) para um
    shader numa camada própria logo abaixo dela (`_noir`, `room_noir.gdshader`, `_noir_params`), com a mesma conta,
    agora ponto a ponto, e o vidro da janela de fora; a luminária piscando ou esquentando muda só um parâmetro. Não foi
    para o shader do `SceneView`, que vale por cima de tudo: o reflexo da janela, o embaçado do vidro e o relâmpago,
    desenhados depois do escuro, escureceriam junto. A sala saiu igual ao pixel nas três horas e nos três climas.
214. #luz
    Hi-bit 5.4: a luminária piscando ou esquentando saiu do desenho da sala: os objetos não escurecem mais por conta
    própria (`_flick`, `_flicker`), a poça, o arco na parede e a luz no armário ficam sempre no nível cheio, e o
    `lamp_level` saiu do `_state`; quem escurece é o shader do escuro da sala, com o escuro a mais do piscar maior
    (`FLICK_DARK` 0,45, a soma dos dois de antes). Os postes de lá, que apagam no piscar, foram para a camada de cima
    (`_posts`). Piscando, a sala parou de se redesenhar (eram 6 vezes por segundo). Acesa, a sala saiu igual ao
    pixel; numa piscada, o brilho médio é o mesmo, a parede um pouco mais escura e os objetos um pouco menos.
    `--dim=N` na captura prende a luminária num nível.
215. #luz #mesa-comutadora
    Hi-bit 5.5: a mesa comutadora passou a piscar e esquentar com a luminária, como a sala (antes, só a sala
    escurecia), no `modulate` dela (`Switchboard.dim`, `Background.lamp_dark`): tudo o que ela desenha escurece, os
    plugs na prateleira e o fio arrastado também, e nada se redesenha. O véu da luz pela distância
    (`_draw_room_light`), o `_lit_by` dos fios e o degrau dos metais ficam no desenho: são parados. Uma camada por cima
    com o shader do escuro da sala só cobria o retângulo dela (os plugs guardados ficavam claros) e, estendida até a
    prateleira, escurecia duas vezes a madeira, que é do cenário.
216. #luz #janela
    Hi-bit 6.1: as luzes de fora entram pela janela num shader (`window_lights.gdshader`, a camada `_window_lights`
    do `Background`, até 8 luzes por parâmetro): o vermelho do letreiro aceso e o amarelo dos postes de lá tingem o vão,
    o peitoril e a persiana, sem passar pelo vidro; o relógio e a caneca ficam na frente, porque a camada fica embaixo
    dos objetos da mesa. No lugar do reflexo vermelho fraco desenhado (`SIGN_GLOW`). Ligar e desligar uma luz (o
    letreiro falhando, os postes apagando com a luminária) só muda os parâmetros: a sala não se redesenha. Fica
    embaixo do escuro da sala, que deixa ~1/5 dela perto da janela, por isso a força alta (`SIGN_LIGHT`, `POST_LIGHT`).
217. #luz #mesa-comutadora
    Hi-bit 6.2: as lâmpadas acesas da mesa comutadora deixam um brilho fraco da cor delas no painel em volta (nas
    plaquinhas e nos aros das tomadas), num shader da mesa (`board_glow.gdshader`, a camada `_glow`, entre a luz da
    sala e os fios), começando onde o halo do `Bloom` acaba, para a luz não somar duas vezes. As luzes vêm da lista
    que a mesa já declara ao `Bloom` (`Bloom.lights_of`): nada se redesenha por elas. `--lines=1:ring,4:conn` na
    captura acende lâmpadas sem ligação.
218. #luz #mesa
    Hi-bit 6.3: as lâmpadas acesas dos objetos da mesa (ocorrência e cartão na unidade de despacho, a do calculógrafo
    contando) iluminam o tampo em volta, na cor delas, pela mesma camada das luzes de fora (`window_lights.gdshader`,
    embaixo dos objetos: eles ficam na frente). Quem declara a luz ao brilho (`_light`) diz até onde ela cai no tampo
    (`spill`). A tela do rádio não entrou: ele fica no painel de baixo, fora da sala.
219. #turno #relogio #clima #noites
    Hi-bit 7.1: a última noite (a 15) vai das 18h às 6h, sem parar à meia-noite, para o dia nascer no fim da história.
    O fim do turno virou campo da noite (`Night.shift_end`), não um caso especial; a última ligação, o botão Encerrar
    turno, a plaqueta do turno ("18:00–06:00") e o relatório seguem ele. Decidido com o usuário: o Esc continua
    pausando, a janela olha para o leste (o sol entra na sala), o relógio anda no ritmo de sempre (12 h ≈ 16 min) e o
    clima é sorteado, mas a chuva ou a névoa param aos poucos perto da meia-noite (`Night.clears_at`), para o
    amanhecer ser de céu aberto. Por ora a névoa some de uma vez; o véu dela indo embora aos poucos fica com o céu (7.2).
220. #janela #clima #luz #noites
    Hi-bit 7.2: o amanhecer na vista da janela, na última noite. O céu clareia às 4h05, passa pelo rosa-alaranjado no
    horizonte e às 6h é dia; as estrelas somem às 4h30 e a lua empalidece. A janela olha para o leste, onde a lua
    nasce atrás da igreja, então o sol nasce às 5h25 no fundo da rua do cruzamento, perto dela: a cidade fica contra a
    luz, e não a "primeira luz no alto da igreja" do plano. Postes e neon apagam às 5h15, janelas acendem com gente
    acordando e a rua volta a ter gente e carros. A névoa que abre à meia-noite some aos poucos nos 40 min antes.
221. #debug #noites
    Um botão no painel de debug para ir direto às 4h da última noite, o começo do amanhecer ("Amanhecer (última
    noite, 4h)"), sem jogar o turno até lá.
222. #janela #luz #clima
    O amanhecer, como fim do jogo, mais bonito: o crepúsculo num degradê forte de faixas enquanto o sol nasce (azul-
    esverdeado no alto, rosa, laranja e amarelo no horizonte, como a referência em pixel art que o usuário mandou); o
    sol aparecendo mais, com luz forte e reflexos de lente, nascendo atrás da igreja, com raios crepusculares em que a
    torre e a cruz deixam a sombra; depois do crepúsculo, o céu azul em cima e claro embaixo, também em degradê.
223. #janela #luz
    Ajustes do amanhecer: os raios do sol lisos (as muitas linhas finas ficavam estranhas), o miolo do sol branco (não
    parecia um sol), a sombra da igreja nos raios puxando para o preto em vez do vermelho e o céu de dia mais azul em
    cima (o halo grande do sol cobria quase todo o céu à vista e o deixava clarinho).
224. #janela #luz
    A sombra da igreja nos raios cortada por manchas (as nuvens, desenhadas por cima dos raios) e o céu atrás da igreja
    cinza às 6h (o clarão laranja do horizonte e o halo laranja do sol por cima do azul): os raios passam por cima das
    nuvens, o clarão some de dia e o halo fica branco.
225. #janela #luz
    Com o sol subindo atrás da igreja, num trecho (5h45) o braço da cruz perdia a cor: o risco da lente, somado por
    cima da cidade, passava na altura dele. O risco foi para o céu, embaixo da cidade.
226. #janela #luz #rua
    Pedido de melhorias do sol e do amanhecer (sugeridas por mim, escolhidas pelo usuário; a sala fica para a 7.3): a beira
    da igreja acesa contra o sol, a franja de 1 px (`_draw_church_rim`); luz de lado, quente no alto da parede da
    esquerda da rua do cruzamento e na quina da esquina dela, e as fachadas de lá, de costas para o sol, na luz fria do
    céu, com a cornija acesa (`_sunlit`, `Pal.DAWN_SHADE`; a 25% o tijolo ficava lilás); a faixa de sol que entra pela
    rua do cruzamento e atravessa a nossa, com as sombras compridas de quem passa, dos carros e dos postes de lá dentro
    dela (`_sun_shadow`, `_shadow_k`); a neblina baixa no fundo da rua, dourada do lado do sol, sumindo até as 6h
    (`_draw_dawn_mist`); as nuvens acesas por baixo (`Pal.DAWN_CLOUD_TOP`); e passarinhos: dois bandos em V e os pombos
    saindo da torre logo depois de o sol nascer (`FLOCKS`, `_draw_birds`).
227. #janela #luz #rua
    Melhorias de luz do amanhecer seguindo uma imagem de referência do usuário (a sala, a luz entrando pela janela,
    fica para a 7.3): as duas paredes da rua do cruzamento douradas no fundo; os prédios à direita dela laranja, com
    peitoris e faixas acesos, e os da esquerda frios (`Pal.SUN_LOW`; com o laranja claro do sol, o tijolo saía bege:
    a luz do dia azulada por cima desbota); o resto da rua na sombra dos prédios de lá e a faixa de sol mais estreita,
    com o miolo dourado (pontos claros ou escuros no grão pareciam sujeira e saíram; num laranja claro ela saía cinza); as
    sombras de quem passa mais escuras; o teto e os vidros dos carros e a copa do arbusto pegando o sol; a luz das
    vitrines na calçada com os postes apagados; e fiapos de nuvem rosa e dourados pelo céu (`_draw_cirrus`).
228. #janela #luz #rua
    Duas das sugestões seguintes: nas fachadas de lá viradas para o sol, a sombra dos prédios do outro lado embaixo,
    com a linha dela descendo do alto até o térreo entre o nascer e as 6h (`FACADE_SHADE`), os peitoris acesos só
    acima dela; e a faixa de sol no chão reta e de beira nítida, um pouco mais estreita que a rua do cruzamento
    (`STRIP_EDGE`): com as beiras sumindo até as paredes, ela se abria em cunhas perto da janela, como um leque.
229. #vista #janela #luz #saiu
    Plano da etapa 9 (`PLANO_HIBIT.md`): a vista da janela segundo uma imagem de referência (sol laranja com sombra fria,
    céu em camadas, vários prédios no fundo, fachadas com cortina e luz por dentro, rua com sombras, gente e carro,
    arbusto denso, borda de luz na moldura). Aceitos: detalhes em todas as noites e vários prédios altos atrás da
    igreja. Recusados: faixa de pedestres no cruzamento e fios de poste atravessando a rua.
229. #luz #janela #mesa-comutadora
    Seguindo o plano hi-bit, a 7.3: a sala no amanhecer da última noite, só por parâmetros, sem redesenhar a sala. A
    luz do dia entra pela janela (fria, do céu, e quente depois que o sol nasce), o escuro da sala recua a partir dela,
    a luminária perde força (continua acesa), o sol baixo acende o vão e o peitoril (a sugestão 8 da referência do
    usuário), a mesa comutadora clareia de leve, o brilho da luminária e o halo das lâmpadas enfraquecem e a gradação
    de cor vai da noite ao dia.
230. #luz #janela #mesa
    O sol entrando pela sala estava "muito ruim": uma mancha redonda laranja no pé do vidro, que acendia a mesa em volta
    da caneca e do relógio sem eles terem sombra (parecia uma lâmpada atrás deles). Trocada pela janela desenhada no
    tampo, nítida e com o montante, o fundo do vão e o tampo do peitoril acesos (a frente dele na sombra), a sombra
    comprida da caneca e do relógio dentro dela e uma cor mais clara, dourada, também na luz do dia da sala.
231. #luz #janela #mesa
    O sol na mesa deixou de ser parado: anda com o sol subindo, comprido logo depois de nascer e encolhendo para junto
    da parede até as 6h, com as sombras da caneca e do relógio encurtando junto (como as da rua). A pedido, com o sol
    baixo a luz é fraca e de beira espalhada, e fica mais forte e nítida à medida que ele sobe.
232. #som #vista
    Hi-bit 7.4, o som do amanhecer da última noite: os grilos param aos poucos das 4h30 às 5h30 (e a brisa volta ao
    normal), o sabiá-laranjeira canta ainda no escuro a partir das 4h30 (frases de flauta sintetizadas, quatro
    versões, notas entrando e saindo devagar, sem estalo), um galo canta longe, na zona rural, a partir das 4h40, o
    primeiro caminhão da manhã passa na mão de cá às 5h08 e o sino da igreja bate as 6h fechando o turno (as
    badaladas seguem por baixo do relatório).
233. #som #saiu
    O galo cantando longe no amanhecer saiu, a pedido (o "barulho do galo"): ficam os grilos parando, o sabiá, o
    primeiro caminhão e o sino das 6h.
234. #luz #testes
    Hi-bit 8.1, o fechamento da documentação: o quadro de todas as luzes num lugar só do `CLAUDE.md` ("A luz": onde
    cada uma mora e como acrescentar uma nova, sem `PointLight2D`), os horários que ainda diziam meia-noite onde vale o
    fim do turno, as lições do caminho e duas verificações novas no `check.sh` (cor escrita direto fora do `Pal` e luz
    do Godot no lugar dos shaders); o `hibit_shots.sh` ficou, com o amanhecer da noite 15.
235. #desempenho #testes
    Hi-bit 8.2: o `medir.gd` passou a medir o amanhecer da última noite (5:15, 5:40 e o sol andando a 8×) e mostrou
    ~5200 chamadas de desenho na vista: os fiapos de nuvem (`_light_fan`) alternavam triângulo e quadrilátero, e o lote
    do Godot só junta primitivos com o mesmo número de pontos. Agrupados, os pixels são os mesmos e ficam ~380–1000
    chamadas (e sumiram as ~1850 que apareciam às vezes ao abrir a lista, das nuvens da lua). Referências novas na skill.

236. #janela #amanhecer #luz #cores #cidade
    Hi-bit 9.1–9.3, a vista do amanhecer da noite 15 pela imagem de referência do usuário. 9.1: o céu mais quente até
    as 6h (`Pal.DAWN_SKY`, os tons quentes mais para cima, `DAWN_STOPS`), o sol pequeno e nítido (o halo mais curto),
    a sombra da rua em azul-violeta (`Pal.DAWN_SHADOW`; preta, apagava a rua), o clarão no fim da rua quente e mais
    fraco, e a luz quente do sol na moldura, no peitoril e no arbusto (`SUN_LIGHT` em `_window_light_list`). No meio,
    o usuário achou as cores do amanhecer "muito opacas" e a faixa de sol "pouco transparente", sem deixar ver a
    textura da rua: a faixa passou a ser desenhada antes do grão, das manchas, das juntas e dos postes
    (`_draw_sun_strip`), com as manchas e o grão como escuro ou claro translúcido sobre ela (na cor do asfalto, ficavam
    blocos azuis na luz), e a sombra só fora dela; as luzes do sol na cidade saem da luz do dia (`_sunny`: o laranja
    vezes o `modulate` ~2 virava amarelo-cáqui e, misturado ao asfalto azul, verde); a luz do dia na cidade ficou mais
    baixa e menos azul (`DAY_GAIN` 1,5, `DAY_WARM`), e a gradação do dia ganhou contraste e saturação
    (`GameView.DAY_GRADE`, o `saturation` novo do `grade.gdshader`; com o contraste de 1,04, o amanhecer saía chapado).
    9.2: um terceiro plano de prédios altos atrás da igreja (`FAR_ROWS`, sorteio à parte para as outras casas ficarem
    as mesmas), cada plano mais apagado no ar dourado. 9.3: as janelas cada uma de um jeito (cortina de um lado, das
    duas, persiana descida, um móvel contra a luz; apagadas com a cortina ou o caixilho), as lojas com balcão, mesa,
    cadeiras e prateleira, a porta de vidro do hotel com o caixilho e o balcão do saguão, a sombra e a franja da
    marquise, e o varal com roupa na varanda (`Pal.LAUNDRY`), em todas as noites.

237. #janela #amanhecer #luz #cidade #saiu
    Ajustes da vista do amanhecer pedidos pelo usuário: (1) blocos escuros no meio da faixa de sol, "sem sentido":
    eram as manchas do asfalto em preto translúcido por cima da luz; voltaram a ser opacas, embaixo dela, e só o grão
    fica por cima; (2) a igreja sumia na frente dos prédios altos novos: ela fica escura contra o sol e eles mais
    apagados no ar; (3) a luz em volta da igreja com o sol nascendo saiu (`_draw_church_rim`); (4) a fachada da
    direita tinha uma sombra que subia e descia com o sol, e o prédio está de costas para ele: as fachadas de lá ficam
    todas na luz fria do céu, sem a luz quente nem a sombra andando (`FACADE_SHADE` saiu); (5) a luz do sol no tampo
    encolhia depressa até a parede e às 6h parecia meio-dia: ela mal sai do lugar até as 6h, por igual
    (`SUN_STEEP` 1,1–1,25, sem a curva do `_sun_up`).
    Depois, o usuário mostrou que a faixa escura continuava: era a beira da própria faixa de sol, num laranja mais
    escuro que o miolo claro (`STRIP_CORE`); a faixa ficou numa cor só (`Pal.SUN_RIM`, `STRIP_A` 0,65) e o
    `Pal.SUN_LOW` saiu.

238. #janela #amanhecer #luz #saiu
    A igreja um pouco menos escura contra o sol (o ar dourado em 12% dela, não 0%), e "se a igreja está na frente do
    sol, por que a luz fica atravessando?": o clarão da boca da rua do cruzamento, a neblina baixa dourada e o brilho
    do sol na camada somada eram desenhados na frente dela; com o sol nascido, saem (a neblina some com ele nascendo, e
    o brilho somado saiu do `_draw_rays`). O ar dourado fica atrás dela, no céu e nos prédios do fundo.

239. #janela #amanhecer #saiu
    A igreja com menos contraste ainda (o ar dourado em 30% dela com o sol; os prédios altos atrás seguem mais
    apagados, a 50%) e os passarinhos do amanhecer saíram, a pedido (os bandos em V e os pombos saindo da torre,
    `FLOCKS`, `WINGS`, `_draw_birds`).

240. #janela #amanhecer #rua
    Hi-bit 9.4, a rua (em todas as noites): remendos de asfalto de beira reta, com a junta de lá pegando a luz; a
    tampa de ferro do bueiro na faixa de sol (`MANHOLE`); rachaduras finas em zigue-zague na mão de cá; a sarjeta
    translúcida e as bocas de lobo no meio-fio de lá (`DRAINS`); os traços da faixa do meio gastos, cada um do seu
    jeito; de manhã, as poças com o céu claro. Sem faixa de pedestres, fios, semáforo nem chaminé (já saíram).

241. #janela #amanhecer #luz
    "As cores não estão se misturando. Quando a luz do sol bate nas superfícies, as cores deveriam se misturar": a faixa
    de sol passava direto do violeta da sombra ao laranja. Entre as duas, dois degraus com os tons misturados
    (`STRIP_BLEND`, nas beiras de fora, não no meio da luz).

242. #janela #amanhecer #vista
    Hi-bit 9.5, a vida na rua de manhã: carros com o bagageiro e a carga embaixo da lona no teto (`RACK_KINDS`, mais
    comuns perto das 6h, `RACK`), faróis e lanternas espelhados de leve no asfalto úmido do sereno (`DAMP`); o menino
    do jornal de bicicleta, de boné e com a sacola cheia na garupa (`PAPERBOY`), e a sombra comprida do ciclista; às
    5h30 o dono abre o bar e fica no vão da porta, em silhueta contra o salão aceso (`BAR_OPENS`).

243. #janela #amanhecer #sala
    Hi-bit 9.6: o arbusto em tufos (`CLUMPS`, `CLUMP_LEAVES`), cada um mais claro no alto e mais escuro embaixo, o de
    cima cobrindo a beira do outro; com o sol, só a beira de cima de cada tufo acende, mais nos do alto. E a poeira
    dourada no feixe do sol, da janela à mesa, bem de leve (`SUN_DUST`, `_sunbeam`, na camada da poeira).

244. #janela #amanhecer #vista #sala #textura
    "Sinto que não há textura, as cores estão opacas e massenta nas superfícies" (a referência tinha muita textura e
    detalhes simples); depois, "implemente todas as melhorias ... em sequência" com o usuário dormindo (etapa 10 do
    plano hi-bit). A beira do sol no tampo em degraus de 1 px, também na beira das sombras (`_draw_sun`); as fachadas
    de lá com o uso de anos (`_draw_facade_wear`: tijolo a tijolo com as juntas, frisos, pilastras, molduras e
    remendos no reboco, rodapé de pedra, encardido, cano de descida, escorridos embaixo dos peitoris; de manhã o alto
    na luz do céu, `SKY_TOP`, e o rebatido quente da faixa de sol junto da boca do cruzamento, `BOUNCE`); as paredes da
    rua do cruzamento com fiadas e remendos e os peitoris acesos de raspão (`CANYON_GRAIN`); a faixa de sol mais
    vermelha para cá (`STRIP_NEAR`, `Pal.SUN_DEEP`); o batente do vão com remendos e uma rachadura (`REVEAL_GRAIN`); o
    armário com a tinta gasta junto do puxador. Sem grão de pontos soltos (já tinha saído). Testados e tirados na
    mesma sessão: lascas e ferrugem no armário e a beira acesa pelo sol na caneca e no relógio.
245. #janela #amanhecer #sala #luz
    A luz do sol nos objetos da mesa (o item 10.7, refeito) e a direção das sombras deles: o sol entrava pela janela e
    a sombra ia para outro lado (reta para a esquerda, enquanto o sol aparece na janela, vindo para os olhos). Agora o
    raio anda para a esquerda e para os olhos (`SUN_TOWARD`): a janela no tampo e as sombras da caneca e do relógio
    descem para a frente, juntas. A beira virada para o sol acende, quente, tirada do desenho de cada um (a coluna da
    direita da caneca, a volta de fora da alça e o aro de trás; o tampo, a beira de trás e a quina da direita do
    relógio), só quando eles estão no sol (`_draw_sun_edge`). Depois: um quadrado escuro embaixo da caneca, no sol; era a
    sombra de contato dela, num retângulo, e virou a elipse do pé.
246. #janela #amanhecer #sala #luz #textura
    "Commit e implemente 10.6, 10.5 e 10.1 logo em seguida" (o que faltava da etapa 10 do plano hi-bit). A parede do
    fundo com uma rachadura fina descendo do friso e o encardido rente ao tampo e em volta da tomada (`WALL_CRACK`,
    `WALL_GRIME`; o amassado do armário já existia); a faixa de sol mais clara e dourada na boca do cruzamento, mais
    cheia ali para não ficar cáqui (`STRIP_MOUTH`); e o sol no peitoril e no fundo do vão com a sombra do montante e a
    do batente de longe, na direção do raio, a beira em degraus de 1 px (`_draw_sun_sill`).
247. #janela #amanhecer #rua #luz #textura
    "A luz que o sol faz na rua ainda não se mistura com as cores da rua, tem linhas escuras, a textura da rua não tem
    mais forma, a luz do sol está chapada nela." A faixa cobria as manchas e os remendos (desenhados embaixo dela, na
    cor) e sobravam só o grão e as rachaduras, riscando. Eles voltam por cima dela, só dentro, como escuro ou claro
    translúcido na força dela (`_draw_strip_marks`): o tom deles vezes a luz.
248. #janela #amanhecer #rua #luz #textura
    "A atual implementação é a melhor forma e melhor prática?" e "pode fazer". A luz do sol no chão da vista deixou de
    ser tinta por cima: a vista de trás em três camadas (o chão, a luz, o que fica em pé), a sombra dos prédios
    multiplicando e a faixa somada, com as cores da pintura que já estava ajustada passadas a luz (`_lit`: no asfalto, a
    mesma cor). A textura da rua continua embaixo da luz sem remendo; saiu o `_draw_strip_marks` do pedido 247.
249. #janela #vista #sala #interface
    O plano da janela maior (`PLANO_JANELA.md`): o bilhete do MANUAL escondido (o código fica), a parede do armário
    mais longe e a quina para a esquerda, a janela mais alta e mais larga e sem o montante, a vista mais perto (mais
    detalhe em quem passa e nos prédios; o carro da mão de cá pode ficar cortado), a rua do cruzamento mais larga, a
    árvore mais perto, o prédio da direita com duas colunas de janelas e a impressão de segundo andar mantida. O
    plano hi-bit e as capturas dele foram apagados.
250. #janela #sala #camera
    Etapas 1 e 2 do plano da janela: o bilhete do MANUAL escondido (o `HintSlot` invisível; as dicas do treinamento e
    da primeira vez não aparecem por ora) e a parede do fundo mais longe (`WALL_K` 1,4): o armário encolhe, a quina anda
    para a esquerda (~765 → ~679 px) e a parede da direita ganha a largura que a janela vai usar; a mesa e os objetos não
    mudam. O armário mais perto do conduíte (`CAB_AT` 0,25) para a folhinha caber até a quina.
251. #janela #sala #saiu
    Etapa 3 do plano da janela: a janela maior, do alto da tela (`WIN_TOP` −40) a um peitoril mais baixo (`WIN_SILL`
    46), começando logo depois da quina nova (`SIDE_T` 1,03/`WALL_K`), e sem o montante (saiu do vidro e das luzes no
    tampo e no peitoril: o sol e o relâmpago entram por um vão só). O ponto de fuga de fora no meio do vidro inteiro
    (`OUT_AT` 0,5); a vista ainda não mudou.
252. #janela #sala #camera #vista
    Etapa 4 do plano da janela: a vista mais perto (`OUT_F` 38 → 64; quem passa na calçada de lá com ~22 px), o
    horizonte 10 cm abaixo dos olhos (`OUT_DROP`; nos olhos, os prédios saíam por cima do vidro), o que é desenhado em
    px fixos crescendo junto (`OUT_K`: igreja, sol, lua, mariposas; o letreiro do hotel numa caixa maior, com as letras
    na fonte de 11, `SIGN`) e quem passa andando só um pouco além das beiras do vidro (`WALK_SPAN` 10, `MAN_FROM` 10).
    No meio, a pedido, com uma linha vermelha na captura: o peitoril mais reto, saindo do mesmo canto de longe; a parede
    da direita ganhou um ponto de fuga próprio, mais à esquerda (`SIDE_VP`), e fica em ângulo, abrindo para a frente.
    Depois, a pedido: o zoom grande demais; `OUT_F` 54 (quem passa com ~20 px) e o caminho dele até 11 m.
253. #janela #vista
    Etapa 5 do plano da janela, sem a imagem de referência: a rua do cruzamento com 8 m (era 4,9), a esquina do hotel no
    lugar e o lado da direita andando junto (o prédio de tijolos agora mostra duas colunas de janelas no vidro); no
    térreo das paredes dela, portas de madeira e lojas, acesas ou com a porta de enrolar; os postes dela à vista (as
    paredes os cobriam); um carro estacionado de traseira; e quem vira a esquina, entrando ou saindo por ela. Com a rua
    larga, a nave da igreja aparece inteira embaixo da torre.
254. #janela #vista #camera
    A pedido, a vista um pouco mais longe (`OUT_F` 54 → 48; quem passa com ~18 px) e a rua do cruzamento mais larga
    (8 → 10 m, de −4,2 a 5,8): o hotel 0,5 m para a esquerda, o lado da direita mais 1,5 m, e o carro estacionado
    junto do meio-fio novo. Quem passa anda até 12 m para cada lado.
255. #janela #vista
    Etapa 6 do plano da janela: o prédio de tijolos com mais vida. Mais janelas acesas até depois das 22h (`BRICK_LIT`),
    vasos no peitoril e uma gaiola numa janela acesa, alguém passando atrás de uma janela acesa de vez em quando
    (`_draw_behind`) e o brilho fraco das janelas acesas dele no `Bloom`. As duas colunas já cabiam depois da etapa 5.
256. #janela #vista #amanhecer
    Etapa 7 do plano da janela: o arbusto vira uma árvore nova da nossa calçada, mais perto, com a copa larga e baixa
    em tufos maiores e os galhos entre eles; a pedido, sem subir a ponto de esconder o outro lado da rua. Pedido
    extra: o sol menor (`SUN_DISC`) e com o brilho de dentro mais forte, o miolo branco mais largo. (Lido antes como
    "sem brilho interno": o disco saiu maior e liso, e foi desfeito.) Depois, a pedido, menor ainda (`SUN_DISC` 0,55)
    e com mais brilho: quase todo branco, sem a beira laranja, e um brilho saindo dele por cima da beira e
    esmaecendo (`SUN_GLOW`). Depois, o halo sem o laranja, o miolo e o brilho mais fortes e sem o risco
    horizontal da lente cortando o sol.
257. #janela #vista
    Etapa 8 do plano da janela: o detalhe na escala nova. Quem passa ganhou os braços balançando com o passo, a mão,
    os sapatos, a barra e a gola do casaco e o cabelo (1 px cada, sem virar sprite); o térreo das lojas de lá, o
    batente, a placa com as letras em traços, o toldo com a franja e a grade nas fechadas (`_draw_shop_trim`).
258. #janela #amanhecer #vista #luz
    Com a imagem de referência do amanhecer (`private/referencia_janela.png`), o usuário escolheu três diferenças
    para aproximar: (1) a igreja alta e fina em silhueta e o sol ainda baixo às 6h, ao lado da torre e meio atrás dela
    (`SUN_LOW`, `CHURCH_TOWER`; os prédios altos do fundo abrem um vão onde ele nasce; antes ele passava da cruz); (3)
    as paredes da rua do cruzamento na sombra, só com a cornija acesa (a da esquerda pegava a luz de raspão); (7) a
    copa da árvore acesa de verde-amarelo pelo sol (`Pal.LEAF_SUN`).
259. #janela #amanhecer #vista
    O céu do amanhecer mais perto da referência (o item 1 das sugestões depois do plano da janela): bancos de nuvem
    em faixas largas de gomos achatados, de beira nítida em degraus, o corpo na sombra e a beira de baixo acesa rosa
    antes do sol e laranja com ele, descendo até o vão da rua do cruzamento; de dia, brancos e fracos (`_draw_banks`,
    `BANKS`).
260. #janela #amanhecer #rua #luz
    O usuário perguntou se a faixa de sol na avenida estava certa. Com o sol posto ao lado da torre (pedido 258),
    ele fica à direita do eixo da rua do cruzamento, e a parede da direita deveria jogar sombra na faixa: ela agora
    perde o lado direito na sombra dessa parede (`_wall_shade`, a altura dela vezes o desvio do sol pela altura dele),
    quase toda logo depois de o sol nascer e menos com ele subindo, sem pulo. Ficaram de fora, como licença: o sol
    alto na tela para a hora, e a cor da faixa mudando ao longo dela.
261. #janela #amanhecer #rua #luz
    A faixa de sol "muito chapada, sem textura, sem esmaecimento": num nascer do sol a luz não faz a sombra reta, ela
    esmaece. As beiras agora passam da sombra à luz num degradê liso, a da sombra da parede mais larga quanto mais
    comprida ela é (`STRIP_SOFT`; desfaz a beira nítida do pedido 228 e os degraus de `STRIP_BLEND`), e a sombra da
    parede da direita segue a altura de cada prédio da rua do cruzamento, então a beira muda de um para outro.
262. #janela #amanhecer #rua #luz
    "Não tem textura, basicamente parece um vidro amarelo por cima da rua que simula a luz", diferente da referência
    (lá a rua está úmida e o sol se espelha nela). A faixa ficou mais fraca (`STRIP_A` 0,5) e ganhou o sol espelhado
    no asfalto úmido: uma coluna de reflexo dourada embaixo do sol na tela, forte no fundo e mais fraca perto, quebrada
    em faixas pela rua e esmaecendo de lado, só onde a faixa está acesa (`_draw_glints`). Testados e trocados no
    caminho: brilhos curtos sorteados, que saíam como confete branco.
263. #janela #amanhecer #rua #luz
    O reflexo em manchas ovais não agradou ("a parte escura se mantém com aquela textura chapada"); pedidas sugestões,
    o usuário aceitou as três primeiras: marcas de pneu nas duas mãos, mais escuras e lisas, ao longo da nossa rua e
    indo embora pela do cruzamento, em todas as noites (`TRACKS_NEAR`, `TRACKS_FAR`); o sol espelhado nelas, em fios
    quebrados onde o asfalto secou, no lugar das ovais (`_draw_glints`); e a sombra variando: mais escura perto e mais
    clara no longe, quente junto da faixa de sol e mais escura junto dos meios-fios (`SHADE_DEPTH`, `BOUNCE_SHADE`,
    `SHADE_CORNER`). Ficaram para depois o céu espelhado na sombra úmida e as poças maiores.
264. #janela #amanhecer #rua #luz #cidade
    O usuário apontou dois problemas que as sugestões ignoravam: (1) "as paredes do prédio não recebem luz, o chão
    inteiro recebe mas as paredes não": com o sol à direita do eixo da rua do cruzamento, a parede da esquerda, virada
    para ele, pega a luz de raspão (`_canyon_lit`, `WALL_LIT`), menos embaixo quando a sombra da parede da frente
    atravessa a rua; a da direita continua na sombra (desfaz em parte o item 3 do pedido 258, sugestão minha); (2) o
    trecho atrás do carro estacionado "continua sem textura nenhuma": o chão da rua do cruzamento ganhou manchas,
    remendos, tampa de bueiro, rachaduras, a mancha de óleo do carro, sarjeta, a face dos meios-fios e as juntas das
    calçadas (`_draw_crossing_ground`).
265. #janela #amanhecer #rua #luz
    O usuário perguntou se fazia sentido a luz pegar daquele lado: sim (o sol ~6° à direita do eixo da rua do
    cruzamento acende a face virada para a direita, a parede da esquerda), mas forte demais, quase no eixo a luz chega
    deitada (~1/4 da do chão): `WALL_LIT` de 0,45 para 0,2. E pediu a luz do sol na rua e nos prédios mais alaranjada,
    não amarela: `Pal.SUN_STREET` na faixa, na parede de raspão, na face do meio-fio, nas cornijas, no rebatido e no
    teto do carro estacionado; a boca do cruzamento clareia para `SUN_RIM`, não para o dourado. O sol, o céu, as nuvens
    e a luz na sala ficam como estavam.
266. #janela #amanhecer #luz #cidade
    O usuário perguntou se a parede da esquerda da rua do cruzamento pegava o sol em todas as horas em que devia. Não:
    das 5h15 até perto das 5h30 o chão já estava aceso e ela escura (antes do sol sair de trás da igreja, a conta dava
    o sol no eixo da rua; logo depois, a sombra da parede da frente subia por ela sem o limite que a faixa do chão
    tem). Ela passou a pegar a luz inteira sempre que o chão pega; a sombra subindo por ela (`_canyon_lit`) saiu.

267. #janela #amanhecer #rua #luz #cidade
    O usuário pediu uma análise do nascer do sol com correções e melhorias e depois "siga o que você sugeriu"; no meio,
    "diminua a altura da igreja também, está muito alta". Correções: às 6h o céu ficava de dia, branco e azul, e o sol
    sumia no horizonte claro (o céu passou a ficar quente até o fim, `DAY_SKY`, `_day_sky`); o sol é desenhado por
    cima dos bancos de nuvem (um deles o apagava) e os reflexos da lente somem perto dele (pareciam um segundo sol); a
    igreja contra o sol, arroxeada (`Pal.CHURCH_DAWN`; no ar dourado, cáqui); as manchas do asfalto de beira torta
    (`_blot`, em quadriláteros, `_convex`; retas, a faixa de sol virava uma colcha); a sombra dos postes até
    `POST_UMBRA` m e só na faixa de sol (`_strip_end`, `_wall_shade`; inteiras, viravam uma listra); a face do meio-fio
    da esquerda com 1 px no longe (saía serrilhada); os brilhos de longe mais fracos (confete). Melhorias: a vitrine
    do bar, a porta do hotel e as vitrines do térreo espelhadas na rua úmida (`_mirror`; de manhã, o sereno, e na
    chuva) e as poças do amanhecer espelhando o céu (`_draw_puddles`); de manhã, mais gente virando a esquina, vindo
    de mais longe (`WALK_CORNER_DAWN`, `TURN_FAR`), em silhueta contra o sol na rua do cruzamento (`Pal.BACKLIT`), com
    a beira acesa só na faixa de sol e de perto, e o porteiro na porta do hotel; o campanário vazado, com o céu atrás
    e o sino, e o relógio mais baixo; a escadaria da igreja (dois degraus); o salão do bar à vista pela vitrine (a
    prateleira com as garrafas e o balcão), e a vitrine e a porta do hotel na cor delas de dia (estouravam no amarelo).
    A torre ficou mais baixa (`CHURCH_TOWER` 46/62/34, era 60/78/38) e o sol, às 6h, mais baixo junto dela (`SUN_LOW`).
268. #janela #cidade #amanhecer
    "Embaixo da igreja há um espaço preto, o que seria?": era o asfalto de base do chão, posto do horizonte para baixo
    depois da igreja, cobrindo o pé dela e a escadaria (uma faixa de 3 px entre o fim da rua do cruzamento e o
    horizonte, em todas as horas). O asfalto de base agora vem antes da cidade de longe e da igreja (`_draw_city`), e os
    degraus aparecem (a igreja depois da rua inteira quebrava o lote: de 380 para 860 chamadas por quadro).
269. #janela #cidade #saiu
    "Remova essa 'porta' e essa luz da igreja": a porta acesa no alto da escadaria (apagava às 22h, `CHURCH_DARK`) e
    o relógio da torre aceso, com o brilho dele no `Bloom`, saíram. O relógio fica, apagado (o mostrador um tom mais
    claro que a torre e os ponteiros, `Pal.CHURCH_CLOCK`).
270. #janela #amanhecer #sala #luz
    "Essas sombras dos itens na mesa estão erradas, deveria estar vindo mais em direção à câmera": o raio do sol na
    sala anda mais para os olhos (`SUN_TOWARD` 1,2, era 0,6): as sombras da caneca e do relógio descem na diagonal para
    a frente, e a janela de luz no tampo vem junto. Com 2, quase retas para baixo, a luz no tampo virava uma faixa
    estreita.
271. #janela #amanhecer #sala #luz #cidade
    Três problemas no sol do amanhecer: (1) "a sombra se desencontra com a janela": a janela de luz no tampo saía de um
    x só, o do meio do vão, mas a parede da direita fica em ângulo; à direita da caneca, a luz parava numa linha reta
    que ninguém projetava. Agora cada ponto do vão sai da parede onde ele está (`_wall_x`), e o tampo pega o sol até
    a parede. (2) "As sombras dos itens estão aparecendo instantaneamente": os contornos dos objetos (`_sun_occ`) só
    eram copiados com a camada do sol já à vista, e a sala, parada no amanhecer, não se redesenhava: a luz entrava sem
    sombras e elas apareciam de uma vez na próxima vez que a sala se redesenhasse. Agora ficam sempre em dia. (3) "A
    sombra na rua está indo e voltando, como se o sol estivesse dando curva": a sombra da parede da direita na faixa
    de sol crescia de nenhuma até quase toda nos primeiros minutos (`rise`) e depois encolhia. Agora começa quase toda,
    rente ao horizonte, e só encolhe, com o lado do sol fixo no das 6h (`_wall_ratio`); a sombra de quem passa vai
    junto.
272. #janela #amanhecer #sala #luz
    "Gostaria que a iluminação do sol seguisse essa linha vermelha, e lembre-se de projetar as sombras. Outra coisa, a
    sombra do relógio está torta e a da caneca está em desacordo com a do relógio e da lista telefônica": a linha ia da
    quina de baixo da janela, passando pela lista, até a frente da mesa, perto da caixinha. O raio do sol na sala
    deixou a perspectiva e virou um passo só na tela (`SUN_SHIFT`, por px de altura): a beira de longe da luz no tampo
    sai da quina do batente no vidro e segue a linha, a parede depois da janela faz a sombra da beira de perto, e as
    sombras da lista, do relógio e da caneca ficam paralelas a ela (em perspectiva, com o sol quase de frente, elas
    saíam em leque do ponto de fuga dele, entre o relógio e a caneca: a do relógio torta, a da caneca para o outro
    lado). Mais curtas (`SUN_CAST` 0,8).
273. #janela #amanhecer #vista #cidade #sala #luz #objetos
    "Quando bate 6h, o céu deveria estar tão laranja ainda? A luz do sol às 6h está muito laranja na rua, deveria estar
    apenas clareando o dia e essa luz deveria ir sumindo também. O relógio está com duas sombras, o que é?" O quadro
    das 6h do céu ficou com o azul do dia no alto e só o horizonte num dourado claro (o sol continua à vista: sem o
    branco embaixo do pedido 267). A luz do sol lá fora (faixa, paredes, cornijas, rebatido, brilhos) clareia do laranja
    para a do dia com o sol subindo (`Pal.SUN_HIGH`, `_sun_tint`, `SUN_PALE`) e a faixa e a sombra da rua se apagam até
    as 6h (`SUN_FADE`). A sombra da luminária, que continua acesa e deixava a dela para a direita ao lado da do sol, foi
    para uma camada embaixo do sol (`_shade_layer`) que o dia apaga (`LAMP_SHADE`); a sombra dupla mesmo era outra coisa
    (pedido 274).
274. #janela #amanhecer #sala #luz #objetos
    "A sombra dupla continua!" (5h38). Não era a luminária: era a luz espalhada do sol baixo (a parte que vai por
    igual na janela toda, por cima das sombras, `SUN_SOFT`), que tinha os cantos presos ao fundo da mesa só pela
    profundidade; o de trás escorregava para o lado e a beira dela cortava a sombra do relógio em diagonal, um lado sem
    ela e o outro com ela. Agora ela é cortada no fundo da mesa reto na tela, como a janela nítida (`_below`).
275. #sala #luz #amanhecer #saiu
    O arco ao lado do armário: "está feio e sem sentido também, pois se a sala clareou com o amanhecer, essa luz
    chapada não deveria estar aí". Era a beira das faixas de tinta da parede do fundo pela luz da luminária (pedido
    201, plano hi-bit 3.4b: mais quente perto da boca do cone, mais fria longe), que davam um degrau de cor do
    verde-acinzentado ao azul numa linha só, pintado na parede e por isso igual de noite e de dia. A parede voltou a um
    tom só (`Pal.WALL_PAINT`); a luz da luminária nela fica a lisa, a do shader, que perde força com o dia, e o leque
    de `_draw_wall_light`. O conduíte e o armário continuam escolhendo o tom pelo degrau da luz (`_wall_step`).
276. #vista #amanhecer #carros #luz
    "Quando o carro para, está ficando uma listra de luz em cima da sombra do carro." Era o reflexo da porta do hotel
    (e, no bar, da vitrine) no asfalto úmido, desenhado no chão, embaixo da camada dos carros: o táxi para bem na frente
    da porta e o reflexo aparecia pela sombra de contato dele, que é translúcida. Os dois reflexos foram para a frente
    da vista, antes dos carros, e cada carro os corta da beira de lá do chão dele para cá (`_car_ground`, `_mirror`),
    também na chuva.
277. #vista #cidade #luz #carros #testes
    "Faça isso. Também queria adicionar detalhes na lateral dos prédios, adicionar toldo, portas, vitrines." Feito o
    que eu tinha sugerido: a bateria inteira (18 de 18) e os reflexos dos postes, do letreiro e das vitrines de lá no
    asfalto molhado levados para a frente da vista, tapados pelos carros como o da porta do hotel (as das vitrines,
    no chão, ficavam cortadas onde o carro estava quando o chão se redesenhou). Nas paredes da rua do cruzamento
    (`_draw_canyon_wall`): toldo de lona em cada loja, listrado perto, com a franja e a aba; a placa em cima e, numa em
    quatro, a placa de bandeira de frente para cá; a vitrine com a mureta, a mercadoria e o caixilho da porta; a caixa
    da porta de enrolar; as portas com as almofadas, o degrau de pedra e, numa em duas, a laje de concreto; o cano de
    descida; e a lateral do prédio da esquina na tinta da fachada dele (a do prédio de tijolos ficou de tijolos).
278. #janela #luz
    "Ficou uma linha vertical no canto direito da janela." Era o reflexo da sala no vidro (`_draw_reflection`): o arco
    da luz da luminária na parede do fundo, espelhado, acabava seco na própria luminária; com a parede mais longe e a
    janela maior (plano da janela), esse corte, antes fora do vidro, caiu dentro dele. O arco agora segue do outro lado
    da luminária, sumindo.
279. #sala #luz #amanhecer #vista #janela #cidade #testes
    "Faça 1, 2 e 3. Aí tem mais uma coisa para fazer: Adicionar algum reflexo brilhante nas janelas laterais dos
    prédios que recebem a luz do sol". 1: o commit do 277 e do 278. 2: o leque da luz da luminária na parede do fundo
    ficava aceso às 6h, desenhado na sala; a parede e ele foram para camadas embaixo dela (`_wall_layer`, `_wall_glow`)
    e ele some com o dia como as sombras da luminária (`LAMP_SHADE`), e o feixe dela no ar também. 3: o conduíte, em
    trechos, um por faixa de luz da parede (`_wall_step`), tinha um degrau no cano; ficou num degrau só, como o
    armário. O reflexo: os vidros da parede da esquerda da rua do cruzamento espelham o céu (mais de raspão) e o sol,
    de onde ele volta para cá e nas folhas abertas, cada uma na sua hora, com um halo nas de perto (`_sun_glass`). Com
    ele, a captura das 5h45 travava: a vista no amanhecer já passava do buffer de itens do renderizador (16384), e o
    `item_buffer_size` foi para 32768.
280. #vista #cidade #janela
    "Coloque mais detalhes na parede lateral do prédio da direita, como outra varanda por exemplo". Na lateral do
    prédio de tijolos (a parede da direita da rua do cruzamento, perto): uma varanda no 2º andar, na 2ª coluna, no
    lugar da janela (porta acesa até as 23h, laje, vasos e gradil, como a da frente; no 1º andar, na altura dos olhos,
    lia pior), venezianas verdes de madeira em todas as janelas dela (abertas nas acesas e em parte das apagadas,
    fechadas nas outras) e vasos em alguns peitoris; o gradil de ferro fica preto de manhã (puxado para o frio da
    sombra, clareava e parecia azul).
281. #vista #cidade #janela #amanhecer
    "Pronto, pode começar pelo 1 e 3, o 4 é interessante e pode ficar no prédio da direita, na lateral" (das sugestões
    para a vista). 1: nos telhados de lá, caixas d'água (na casa da escada, a caixa um pouco mais larga em cima; ou de
    cimento-amianto num cavalete) e antenas de TV de espinha de peixe, deitadas, com os elementos em traços (de pé, com
    as barras empilhadas, pareciam um poste de luz); vistas de baixo, o parapeito tapa o que fica recuado, então
    aparecem as de perto da beira, mais na rua do cruzamento. 3: gente, carros e o vaivém do bar pelo dia da semana
    (mais na sexta e no sábado, menos no domingo) e, no balcão do bar, de pé contra o salão aceso, de um a quatro
    fregueses, saindo das 22h à meia-noite (sentados, viravam blocos). 4: a banca de jornal verde encostada na lateral
    do prédio de tijolos, na ponta de cá da rua do cruzamento, no lugar das primeiras lojas; aberta até as 19h e de
    novo a partir das 5h10 (revistas penduradas, jornais no balcão), fechada no resto; quem vira a esquina por ali passa
    por fora dela.
282. #vista #luz #janela
    "Conserte a placa do Hotel, aproveite e adiciona o nome, que é Hotel Serena". O reflexo do letreiro no vidro da
    sala (o fantasma dele, pedido 210) ficava 5 px deslocado, medida das letras miúdas de antes; com as da fonte de 11
    (pedido 252), caía em cima das de verdade e o letreiro parecia escrito duas vezes, passando da caixa embaixo. Ficou
    1 px, como a outra face do vidro. As letras também saíam 1 px fora do meio (a caixa em meio pixel e as letras
    arredondadas para baixo). O letreiro agora diz SERENA, de cima para baixo, e HOTEL deitado numa coroa em cima,
    na fonte miúda da mesa; a letra que falha sozinha é o R.
283. #vista #luz
    "Vamos melhorar essa placa, ela pode ficar virada para o prédio da direita ao invés de virada para o prédio da
    telefonia?" O letreiro do hotel virou de bandeira: preso de lado na fachada por dois suportes (o braço saiu), com a
    face acesa virada para a direita, para a rua do cruzamento, vista de lado em perspectiva, com a ponta de frente para
    cá e o fundo visto de baixo; dentro da calçada, e a coroa com HOTEL saindo um pouco mais. As letras continuam em
    pixels inteiros, cada coluna descendo com a perspectiva (vistas de baixo, as do alto entortam mais).
284. #vista #saiu
    "Não ficou com uma perspectiva muito legal e o letreiro poderia ficar mais pro lado direito para não tampar as
    janelas, pela lógica não deveria ser assim". O letreiro foi para a parede sem janela entre a última coluna de
    janelas do hotel e a esquina (tirado das janelas, para nenhuma ficar tampada) e começa na altura dos olhos, longe da
    marquise. Saíram as letras entortadas pela perspectiva (vistas de baixo, as do alto viravam garranchos, e HOTEL,
    miúdo, ficava ilegível) e a coroa com HOTEL deitado, que saía mais da fachada e virava uma diagonal comprida: as
    letras ficam em pé, de cima para baixo, HOTEL miúdo em cima e SERENA embaixo, na caixa ainda em perspectiva.
285. #vista
    "A placa não ficou como eu havia pedido. O texto do neon não tá centralizado". As letras começavam a um tanto fixo
    do alto e passavam da face (o A encostava embaixo, com o vão grande em cima); agora ficam centradas na coluna do
    meio da face, na largura e na altura, e a caixa subiu até 12,4 m para caberem com folga. O halo vermelho, que era
    um retângulo em volta da caixa toda (mais larga e com a beira de cima inclinada), agora sai das letras.
286. #vista #saiu
    "Nao gostei, o que você sugere ?" e, das três sugestões, "Vamos testar o 1": o letreiro deixou a perspectiva (a
    faixa estreita com a beira de cima inclinada, passando do telhado) e virou um retângulo em pé, um pouco mais largo,
    abaixo do telhado, com a grossura à esquerda, os suportes até a fachada e um friso de neon em volta das letras; a
    perspectiva fica só na posição, no meio da parede sem janela. As outras duas, não testadas: só SERENA na placa e
    HOTEL na marquise, ou "HOTEL SERENA" de frente, acima da marquise.
287. #vista #saiu
    "Poderia fazer um leiteiro nesse estilo? Em que o letreiro ficará suspenso na lateral do prédio, virado para frente
    (em direção a telefonia)", com a imagem de um letreiro de neon antigo (HOTEL deitado numa caixa em cima, o nome de
    cima para baixo na bandeira, um enfeite no alto, letras brancas com o brilho vermelho e a beira acesa). O letreiro
    saiu da fachada e foi para a lateral do hotel, na rua do cruzamento, pendurado por suportes e de frente para a
    central: a bandeira vermelho-escura com SERENA, a caixa de cima com HOTEL, a lua crescente no alto (o enfeite),
    letras com o tubo quase branco e o brilho vermelho, e o friso de neon na beira. Saiu a placa reta do pedido 286.
288. #vista
    "O que melhoraria? O letreiro está proporcional?" e "É porque eu achei o letreiro grande demais". Na conta, ele
    tinha o tamanho de um letreiro de verdade (1,4 × 8,5 m), mas na tela ocupava três andares. Como cada pixel da
    letra é um pixel da tela, o tamanho vem da fonte, não da distância: SERENA passou de 5 × 8 para 5 × 6 e a folga
    da bandeira, de 2 px para 1 (a bandeira de 13 × 61 para 11 × 47 px, o letreiro todo de 81 para 66 px de altura).
    A caixa do HOTEL ficou com a folga de 1 px: sem ela, o brilho das letras encostava no friso e virava um bloco
    vermelho.
289. #vista #luz
    "O fundo desse letreiro é preto (melhor um cinza escuro para ficar mais realista), não vinho com esta agora. Se a
    lua acesa é amarela, então desliga seria amarela também. O glow do letreiro aceso está quadrado, seria melhor
    fazer a forma do letreiro. A luz do leiteiro também projeta a luz na parede." A caixa ficou de metal cinza-escuro;
    apagados, os tubos ficam no tom deles, sem a luz (a lua num amarelo apagado e, pela mesma lógica, as letras num
    branco apagado); o brilho vermelho em volta das letras, mais escuro, para a caixa cinza aparecer. O halo do bloom,
    que era o retângulo do letreiro, segue a forma dele: as duas caixas em T, num halo só (em luzes separadas, os
    halos somavam no cruzamento), e a lua num halo amarelo. E a lateral do hotel, onde ele está pendurado, fica
    vermelha em volta dele, sumindo para as beiras.
290. #vista #saiu
    "Remova essa borda vermelha do letreiro tbm, vamos ganhar mais espaço". Saiu o friso de neon na beira das caixas;
    as letras ficam a um pixel da beira, e o letreiro diminuiu (a bandeira de 11 × 47 para 9 × 45 px, a caixa do HOTEL
    de 25 × 11 para 23 × 9).
291. #vista #cidade #luz
    "queria que você subisse mais o telhado da igreja e desenhasse uns vitrais e duas janelinhas na Torres. As luzes
    da janelinha se acendem todos os dias e se apagam sempre às 21h, os vitrais só se acendem às quartas, sextas e
    domingos". O telhado da nave subiu (a parede de 18 para 20 e o alto de 26 para 32, `CHURCH_NAVE`), e a torre ficou
    na frente da fachada, com a sombra dela dos dois lados até sair do telhado. Na torre, duas janelinhas lado a lado,
    acesas todo dia até as 21h; no frontão, um vitral de cada lado dela, em quatro cores, aceso a noite toda nos dias
    de missa e apagando com os postes (no amanhecer da noite 15, uma segunda, a igreja fica sem luz contra o sol, como
    no pedido 269). Na fachada, embaixo, os prédios do fim da rua do cruzamento tapavam os vitrais.
292. #vista #cidade #amanhecer #luz
    "melhore os detalhes no fundo do cenário próximo da igreja. Além disso, veja se a iluminação do amanhecer está
    correta nesse pequeno espaço, a impressão que dá é que há muita luz sendo recebida nesse espaço mesmo quando a luz
    ainda não está pegando". Três coisas acendiam o fundo antes do sol: o ar da distância era a cor do horizonte, o
    clarão amarelo (a igreja cáqui, os prédios de longe e o fim das paredes e do chão da rua do cruzamento claros); a
    neblina baixa era um véu claro, lavanda e depois amarelo antes de ele nascer; e a luz do sol na cidade e na sala
    começava às 5h15, dez minutos antes de ele nascer e quinze antes de sair de trás do telhado da nave. O ar fica na
    luz fria do céu até o sol sair (`_air`, `AIR_SHADE`), a neblina na cor dele, mais fraca (`MIST_A` 0,3) e quente só
    com o sol fora, e a luz do sol vai das 5h30 às 5h50 (`SUN_OUT`). No fundo, os prédios de longe em volta da igreja
    ganharam as janelas apagadas (`FAR_DETAIL`) e, em cima, o andar recuado, a casa de máquinas ou a caixa d'água e a
    antena (`_far_roof`): eram blocos lisos.
293. #vista #cidade #saiu
    "Remova as antenas dos prédios mais distantes, está meio bagunçado": saiu o risco de 1 px das antenas nos
    prédios de longe, atrás da igreja (`_far_roof`). Tirei também as antenas de TV dos telhados da rua do cruzamento a
    mais de 15 m, e o usuário corrigiu: "Mas aí você tirou todas as antenas! Era só remover as antenas dos mais
    distantes que tinham poucos detalhes!!". As da rua do cruzamento voltaram, todas.
294. #vista #cidade #amanhecer #luz
    "Conserte as bagunças sugeridas" (as que apontei no fim da rua do cruzamento): (1) às 5h45, os vidros do fundo da
    parede da esquerda, mais finos que um pixel, brilhavam todos com o sol, uma coluna de riscos brancos: só os de mais
    de um pixel espelham o sol, e os finos aparecem só acesos; (2) a sombra da igreja nos raios crepusculares, uma
    faixa escura e larga subindo pelo céu como fumaça, ficou fraca (`CHURCH_SHADOW` 0,3, era 0,6), sem sair (pedidos
    222 e 223); (3) o halo redondo da lua do letreiro cobria metade da torre: o da lua a 0,2 e o das caixas a 0,35 (eram
    0,5); (4) as janelas acesas da rua do cruzamento tinham o mesmo amarelo forte até o fundo, muitos riscos em volta
    da igreja: somem no ar da distância como a parede.
295. #vista #cidade #amanhecer #luz #igreja
    "Pode fazer isso. Inclusive, adicione prédios baixos atrás da igreja, com uma névoa causada pela distância" (as
    melhorias que sugeri): as lâmpadas dos postes da rua do cruzamento de 1 ou 2 px por 1, mais apagadas no ar (de 3 por
    2 px, perto da igreja pareciam placas soltas); de noite, o clarão da cidade no céu atrás da igreja, que a recorta
    (`CITY_GLOW`; luz atrás dela, não na frente, pedido 269), somindo no amanhecer; o ar da distância de madrugada
    arroxeado (`Pal.DAWN_AIR`): às 5h35, o amarelo do horizonte misturado à luz azul dava um cinza-cáqui; nos prédios
    de longe perto da igreja, uma ou outra janela apagada espelhando o céu frio de cá, de manhã. Os prédios baixos
    (`FAR_ROWS` 3): baixos de verdade ficavam todos atrás da nave e das paredes da rua do cruzamento (sobram 3 px de cada
    lado), então são uma fileira mais baixa que a dos altos, na frente deles e só perto da igreja, com o alto logo acima
    do telhado da nave, no céu atrás deles (no clarão dourado do horizonte saíam cáqui) e com a névoa do chão clareando
    o pé (`LOW_MIST`), poucas janelas acesas de noite. Conferidos chuva e névoa de noite.
296. #vista #cidade #igreja #saiu
    "Nao gostei desse prédio. Remova-o": a fileira de prédios mais baixos atrás da igreja (`FAR_ROWS` 3, `LOW_MIST`,
    pedido 295), o bloco de cor com a grade de janelas à esquerda da torre, logo acima do telhado da nave, saiu
    inteira. O resto do pedido 295 ficou (as lâmpadas dos postes, o clarão da cidade, `DAWN_AIR`, os vidros espelhando).
297. #vista #amanhecer #luz #cidade
    "Faça os 3 pontos" (as melhorias que sugeri): (1) a beira vermelha da marquise do hotel virava um vermelho de neon
    de manhã (o vermelho escuro da noite multiplicado pela luz do dia): desbota para `Pal.MARQUEE_DAY`; (2) as poças do
    amanhecer eram tiras rosa de uma cor só, como tábuas no asfalto: escuras de cá, com o alto do céu, e o céu baixo,
    menos saturado, na beira de lá (`PUDDLE`); (3) o sol às vezes sumia às 5h55: as nuvens que passam com o vento,
    desenhadas com a lua, iam por cima dele (e os reflexos da lente ficavam); o sol agora vai por cima delas, como já ia
    por cima dos bancos de nuvem.
298. #vista #cidade #igreja #saiu
    Experimento na branch `improve/0000-igreja-fundo`: "remova os prédios imperceptíveis no fundo do cenário; os
    espaços que sobrarem nas laterais servirão para adicionar prédios no fundo, numa camada atrás da igreja; traga a
    igreja um pouco para frente, mas sem esconder tanto as laterais dela". As três fileiras de longe (`FAR_ROWS`, a
    250, 320 e 400 m) ficavam quase inteiras atrás das paredes da rua do cruzamento: saíram (o sorteio das duas que
    dividiam o das fachadas fica, para elas continuarem as mesmas), e no lugar uma camada só, a 180 m, com prédios de
    45 a 100 m que passam do telhado da nave ao lado da torre (`CITY_BACK`), na cor da igreja e mais apagados no ar
    (contra o sol, arroxeados como ela: no ar dourado, ficavam bege, como acesos); no vão do sol, só os baixos, até a
    parede da nave. A igreja veio de 120 para 96 m (`CHURCH_Z`, a escala pela distância, `CHURCH_K`), 25% maior. Quem
    escondia os lados dela eram as paredes da rua do cruzamento entre 25 e 50 m (pelo ângulo, a qualquer distância):
    a rua agora acaba na praça dela, aos 80 m, e depois das esquinas são sobrados de 6,5 a 9,5 m (`SQUARE`). Efeito:
    com as paredes mais baixas, a sombra da da direita na faixa de sol da nossa rua encurta.
299. #vista #cidade #igreja
    "Os prédios mais afastados ficaram com altura baixa, pode aumentar, mesmo que precise afastar um pouco mais a
    igreja": os da camada atrás da igreja (`CITY_BACK`) passaram de 45–100 para 80–160 m, até acima da torre, e a
    igreja foi de 96 para 104 m (`CHURCH_Z`, 8% menor). No vão do sol continuam só os baixos. De noite, a lua nasce
    atrás deles e da torre e aparece inteira por volta das 20h.
300. #vista #cidade #igreja
    "Gostei da largura dos prédios, mas não deveria ser arranha céu, diminua a altura": os da camada atrás da igreja
    (`CITY_BACK`) foram de 80–160 para 60–105 m, com a mesma largura: acima do telhado da nave e abaixo da ponta da
    torre. Com eles mais baixos, a lua das 19h30 volta a aparecer inteira, cortada só pela torre.
301. #vista #cidade #igreja
    "Aumente um pixel de largura no prédio da esquerda" e "diminua mais 4px de altura": o prédio da camada de trás
    logo à esquerda da torre (o 11 do sorteio de `_build_city`) ficou 1 px mais largo, crescendo para a esquerda para
    o vão até o vizinho continuar, e 4 px mais baixo que o sorteado.

302. #mesa-comutadora #mapa #despacho #pixel #fonte
    "Análise o visual do jogo e sugira melhorias" e "corrija os três primeiros" (os defeitos de pixel):
    - Na plaqueta do fabricante, na frente do console, o til de "SÃO" encostava na linha de cima e o acento do Ô caía
      no friso. Ela passou de 26 para 32 px de altura, com 1 px livre entre as duas linhas (`draw_maker_plate`).
    - O nome de cada lugar do mapa do despacho era medido pelo quarteirão, e Bilhar e Funerária vazavam do prédio. Agora
      é medido pelo telhado, com 1 px livre de cada lado (`_place_name`); o que não cabe só aparece aproximando o mapa.
      A faixa do nome da praça foi recuada 4 de cada lado para continuar como estava.
    - O selo do canto cobria os nomes, porque não entrava na conta das sobreposições. Agora entra (`_boxes`).

303. #vista #igreja #luz
    "Parte do sol está passando pelo espaço vazio do sino da igreja, mas não está aparecendo": o vão do campanário era
    pintado com a cor lisa do céu naquela altura (`_sky_at`), por cima da torre, e o sol passava atrás dele sem
    aparecer. Agora o vão é aberto na torre (ela é desenhada em faixas em volta dele, `_belfry`), e por ele se vê a
    camada do céu: o sol e o halo dele, as nuvens e, de noite, o clarão da cidade (antes o vão ficava num azul um
    pouco diferente do céu ao lado). Os prédios do fundo atrás da torre ficam abaixo do vão, sem nada do telhado
    entrando nele (o 13 do sorteio aparecia na metade de baixo; fora da torre, ele baixou 1 px).
304. #interface #turno #codigo #testes
    Erros logo depois de terminar o turno do amanhecer, no Recomeçar (`is_input_handled: !is_inside_tree()`,
    `Eavesdrop._wait: data.tree is null`). O `reload_current_scene()` tirava a cena da árvore no meio do clique (a
    `SubViewport` do `GameView` seguia entregando o evento a ela) e só a liberava no fim do quadro: as esperas por
    quadro pendentes acordavam sem árvore. Agora os quatro recomeços (pausa, fim, tela inicial e pular o treinamento)
    passam por `Main.restart()`, que espera o clique acabar, libera a cena velha (as esperas somem junto) e carrega a
    nova; o `test_keys` aperta o Recomeçar da pausa com uma espera pendente. E "notei que você está abrindo várias
    instancias pra tirar print do jogo": as capturas, uma de cada vez e com a janela pequena no canto.
305. #voz #som "Você consegue criar um código em python que gere sons baseados em palavras digitadas como está hoje no
    jogo? Irei usar esse código para gerar falas e adicionar efeitos sonoros por fora": `tools/voz.py`, só com a
    biblioteca padrão, porta das sílabas do `SfxSynth` e da entonação do `Sfx.speak_char` (tônica, pergunta, exclamação,
    nasal, ataque da consoante, altura pelo nome com o hash do Godot, agitação) no ritmo do `Conversation.say`; grava
    um .wav com a banda do telefone (`--seco` sem). Mudou a voz no jogo, mude lá também.
    Depois ele o levou para fora do projeto (`~/Documents/voz.py`). "As palavras estão saindo uma atrás da outra, sem
    pausa": as sílabas andam mais devagar que as letras e o espaço sumia no atraso; agora, no espaço e na pontuação,
    a próxima espera a última acabar de soar e mais a pausa (`PAUSE`: 0,08 s entre palavras, 0,25 na vírgula, 0,45
    no ponto; `--pausa` multiplica, 0 = como no jogo).
    "As palavras podem ser ditas um pouco mais rápido, porém deve haver pausas entre elas": as sílabas dentro da
    palavra 1,3 vez mais rápidas (`WORD_RATE`, `--rapidez`: o tempo da letra e a espera entre sílabas), as pausas iguais.
    "No jogo parece melhor": o balbucio emendado do jogo é o que soa como fala; o padrão voltou ao ritmo dele
    (`--pausa` e `--rapidez` só como opção), com `--chiado` (o da linha, -36 dB, -26 na desconhecida) e a banda do
    telefone em dois estágios por filtro, como o "12 dB" do Godot.
    "Melhorar a voz gerada, dar mais clareza": a voz do script ficou refinada além da do jogo (`--jogo` volta à dele,
    para comparar): cada sílaba sintetizada na altura dela, sem acelerar o som (no jogo, o `pitch_scale` sobe junto
    as ressonâncias: 30% mais aguda levava o F2 do "e" de 1780 a 2320 Hz; refinada fica em ~1870), com a altura
    deslizando até a próxima sílaba e as ressonâncias pelo tamanho da boca de cada voz (`TRACT`); três formantes
    por vogal em cadeia de Klatt (`FORMANTS`, `BANDWIDTHS`, F4); a tônica 1,3 e a última da frase 1,4 vez mais
    longas; o pulso glotal de Rosenberg com variação por ciclo (`GLOTTIS`, jitter e shimmer). Se ficar melhor, dá
    para levar ao `SfxSynth` (menos a altura sem acelerar, que pediria sintetizar durante o jogo).
306. #voz #som "No caso, esses pontos melhoraria o áudio do jogo? então eu aceito": os refinamentos do `voz.py` no
    `SfxSynth`. Cada sílaba é o pulso glotal de Rosenberg, com variação por ciclo e o sopro mais forte com a glote
    aberta (`GLOTTIS`, `CYCLE_JITTER`, `CYCLE_SHIMMER`; o ruído no próprio laço, sem chamar o sorteio a cada amostra),
    passando por três formantes por vogal em cadeia e um quarto comum (`VOWEL` em `Vector3`, `BANDWIDTHS`, `F4`,
    `_formant`, sobre o `_resonator` que já existia; antes eram F1 e F2 em paralelo e um 2600 Hz fixo), no tamanho
    da boca de cada voz (`tract` no `VOICE`: mulher 1,15, criança 1,25; antes todas com os formantes do homem). A
    tônica e a última da frase tocam a versão longa da sílaba (`LONG` 1,35, ids com "l"; `Sfx._long`), e a próxima
    espera pela duração dela (`_spoke` guarda o começo e quando a próxima pode vir). A altura sem acelerar o som (o
    item 1 do script) não entrou: pediria sintetizar durante o jogo. Medido: de 268 sons e 7,1 MB para 448 e 9,2 MB
    (vozes de 1,8 para 3,9 MB), montagem de 424 para ~490 ms (cada voz em dois pedaços, curtas e longas); o volume
    de cada vogal mudou até ±2,4 dB. O `voz.py` acompanhou: `--jogo` agora são essas sílabas aceleradas.
307. #voz #radio "A voz do rádio está mais estridente": a cadeia de formantes do item 306 entregava a sílaba 100 a
    250 vezes mais forte ao filtro da voz, e a saturação do rádio (vezes 40 e corte) virava uma onda quadrada: a
    energia acima de 2,5 kHz dobrou (3–4% para 6–8%). A vogal entra no filtro no pico de antes (`SfxSynth.LEVEL`, 0,4),
    e o rádio voltou ao brilho antigo (centroide ~1000–1100 Hz); as outras vozes não mudam (os filtros delas são
    lineares). O `voz.py` tinha o mesmo problema e levou a mesma correção.
308. #codigo "Antes de criar arquivo: procurar componente que já existe (`graphify query "<componente>"`). Reaproveitar >
    criar": regra nas convenções do `CLAUDE.md`. O `graphify update .` (só código) foi testado e desfeito: sem leitor de
    GDScript, não muda nenhum `.gd` e apaga as ligações semânticas do grafo (1574 para 1474); o grafo voltou à cópia
    de 09/10, e atualizá-lo de verdade é pelo `/graphify . --update`, com leitura semântica. Rodado depois: a detecção
    do graphify também ignora os `.gd`, e os 75 que mudaram entraram à mão nos subagentes (~1,05 milhão de tokens);
    o grafo foi de 907 nós e 1574 ligações para 2867 e 6292.
309. #codigo "Eu instalei o graphify-godot para conseguir mapear .gd": o grafo se atualiza com `python -m graphify update
    <projeto>` (no `CLAUDE.md`, na regra de reaproveitar), no lugar do `graphify update .`, que não lia GDScript.
310. #consequencias #interface #testes "Medir a eficiência do operador ... duas noites abaixo do nível médio e ele é
    demitido": a demissão por 3 graves acumuladas saiu; o supervisor dá um **conceito** carimbado (Ótimo, Bom, Regular,
    Insuficiente; a porcentagem, pedida no começo, ficou interna, a pedido: "a porcentagem seria a melhor forma?"), e
    duas noites seguidas em Insuficiente demitem. Só decisões dão crédito; emergência perdida é Insuficiente. O carimbo
    é redondo, "com detalhes", a pedido. Na calibração, o robô errava a informação (escolhia a primeira) e registrava
    tudo como Comum, e a média em 8 deixava o desastrado passar: foi para 15 (grave 30, gravíssima 60). Plano e
    números em `PLANO_EFICIENCIA.md`.
311. #consequencias #interface "Deixar o carimbo mais aleatório no papel, concentrado na parte vazia de baixo,
    rotacionando um pouco de vez em quando (nem de lado nem de cabeça para baixo)": o carimbo do conceito cai num
    lugar sorteado do vão entre o botão e a rubrica, um pouco acima ou abaixo, e em 2 de cada 3 memorandos torto até
    ~17° (`STAMP_TILT`); girado pixel a pixel pelo RotSprite dos plugs, e por isso o conceito virou pixel da imagem.
312. #codigo "O HISTORICO.md está ficando grande, isso impacta o consumo de tokens?": o que pesava eram os dois
    `CLAUDE.md` (105 KB e 93 KB, ~57 mil tokens, enviados em toda mensagem e reenviados inteiros quando editados no
    meio da sessão). Viraram mapa e regras (~17 KB e ~10 KB); as versões longas ficaram em `docs/mapa-detalhado.md` e
    `docs/mapa-ui-detalhado.md`, consultadas por `grep`. O `HISTORICO.md` não entra sozinho no contexto (só filtrado
    pelo `awk`, ou anexado com `@`). Regra nova: atualizar os `CLAUDE.md` no fim da tarefa, de uma vez.
313. #codigo #testes "Pensando em AI Engineer / Agent Engineer, que sugestões você dá...?" e "Vamos começar pelo 1, os
    hooks": hooks do Claude Code no `.claude/settings.json`. Depois de cada Edit/Write num `.gd`, `.tscn` ou `.tres`,
    `.claude/hooks/conferir.sh` roda o `check.sh` só nesse arquivo (o mesmo apontamento não volta a cada edição) e
    compila o projeto (`--quit-after 60`, ~2 s); no Stop, recompila só se o código mudou sem passar pelo Edit. O erro
    volta para o agente na hora. O `check.sh` passou a aceitar arquivos (`check.sh [base] [arquivo...]`). As outras
    sugestões, ainda não feitas: referência visual e tabela de equilíbrio gravadas, validador de conteúdo, esteira de
    roteiros com agentes (noites 3–15), CI no GitHub Actions.
314. #testes #codigo #conteudo "Faça os pontos 1 e 2, mas sobre o ponto 2, lembre-se que o roteiro é escrito por mim" e
    "No caso do ponto 3, eu que vou escrever o roteiro, não é?": sim; a esteira de roteiros com agentes saiu da lista
    (as ferramentas só conferem o que ele escreve). Feito: `tests/test_content.gd`, as conferências de conteúdo que
    estavam no `test_flow` (sem a cena, ~2 s) mais duas novas, marcador pedido em `requires` que ninguém liga e fala
    fora do `.po`; `tools/visual.sh`, 12 capturas do commit (cópia em `build/visual/base`) contra o disco, sem a vista
    da janela e a chuva (animadas pelo relógio real, saem diferentes a cada captura); `tools/calibrar.sh`, a
    calibração da seção 6 do `PLANO_EFICIENCIA.md` em tabela (50 turnos, ~4 min). O `diff_shots` agora falha com a
    pasta vazia (antes dizia "iguais").
315. #testes #codigo #conteudo "Implemente 1, 2 e 4": (1) o relógio das animações do desenho virou `PixelArt.ms()`, parado
    nas capturas com `--still`; e duas causas do `--seed` não repetir a noite: a semente era aplicada no `_ready` do
    Main, depois do `_ready` do cenário, que já tinha sorteado pingos, estrelas e nuvens (agora no `_enter_tree`), e o
    som sorteava no global no ritmo do relógio real (as sílabas das vozes caíam num quadro ou no seguinte e desandavam
    o resto: quem passa na rua, a agenda); agora no `Sfx._rng`. O `visual.sh` compara a tela inteira (só a chuva
    fica fora: ainda varia sem vir do sorteio nem do relógio). Efeito: a mesma semente dá outra agenda que antes; na
    calibração, o atento teve duas noites 5 Insuficiente (emergência perdida; sementes 1 e 5). (2) CI no GitHub
    Actions (`.github/workflows/testes.yml`): import, `tests/run.sh` e o `check.sh` só apontando. (4) Skill
    `revisar-roteiro`: revisão de continuidade só quando pedida, apontando sem escrever falas. O ponto 3 (todo número
    serve para alguma coisa) espera a definição do usuário.
316. #testes #conteudo #lista "Para o ponto 3, prefiro a (a)": "todo número serve para alguma coisa" quer dizer ser
    destino de transferência. O `test_content` (`_check_destinations`) acusa o número da lista que nenhuma ligação
    escrita (avulsa, do roteiro, do treinamento, também como alternativa) nem molde transfere para ele, contando o do
    mesmo ramo oferecido quando o pedido não atende; os só do despacho ficam de fora. Hoje todos servem.
317. #testes #consequencias "Nem todo jogador vai esperar a ligação finalizar depois que entender que isso não impacta em
    nada": o robô do `test_shift` esperava o destino atender e o agradecimento (e a despedida da informação e da
    emergência) antes de atender outra. `--eager` mede o apressado: com a ligação resolvida (`closing`) ou o destino
    chamando ou na linha, tira o FONE e atende a próxima; sem ninguém tocando, volta à que ficou em espera precisando
    dele. Largar não custa nada (a transferência se completa sozinha); na noite 9, semente 1, a mais cheia, com
    `--human` o apressado largou 3 e tirou Bom contra Regular do atento (duas perdidas a menos). Nas outras sementes, igual.
318. #testes #debug #emergencia "Meça" / "Faça" (o cronômetro): o caminho do cartão no `test_shift --human` leva 40 s
    de barra (relato e perguntas 24, protocolo 5, mapa e impressão 5, perfuração 5, envio 1; a linha "despachos" mostra a
    trilha); o limite do estágio inicial é 35, 40 ou 45 s. Para comparar com uma partida do usuário, o `DebugPanel`
    (`_time_calls`, só em debug) imprime em cada ligação quando cada passo aconteceu (s desde que tocou; na emergência,
    a barra), no `user://logs/godot.log`.
319. #interface #painel #mapa #despacho #testes "Vamos elaborar um plano" (depois da partida cronometrada; o plano em
    `PLANO_RITMO_JOGADOR.md`): (A) a oferta da alternativa (`alt_ask`, até 79 letras) num botão de resposta exigia o
    texto inteiro e empurrava a tela toda para a esquerda; agora a resposta que não cabe quebra em duas linhas
    (`PhonePanel._render_choices`), e o `test_layout` confere a mais longa. (C) No mapa, o clique na rua vertical
    marcava a horizontal: no cruzamento as duas empatavam e vencia a primeira da lista. Tirar o clique dos cruzamentos
    foi recusado ("não faz sentido tirar ação dos cruzamentos"); ficou a rua que o mouse vinha seguindo, até ele sair
    dela (`CityMap._find_seg`), e o clique marca a destacada (`test_flow`).
320. #interface #painel #conversa "Vamos implementar a B" (`PLANO_RITMO_JOGADOR.md`): os botões de resposta longos
    atrasavam a leitura. O botão mostra uma fala curta do operador (`CHOICE_*` no `ui.csv`: "Um momento.", "Pode
    repetir?", "Como vai a noite?", "Fique na linha.") e, clicado, ele diz a frase inteira (`OP_*`) na conversa. Um
    verbo solto ("Conectar") foi recusado: parece ação, não fala. O que é ação do jogador vai entre colchetes:
    "[Oferecer outro lugar]" no lugar da oferta da alternativa (`alt_ask`, que continua sendo a fala). As perguntas da
    emergência e as respostas da conversa fiada (do roteiro, já curtas) ficaram. "Lugar" e não "número": o
    operador oferece outro lugar do mesmo ramo, e "número" confundia com a resposta da informação ("É o 312.").
321. #mapa #despacho "Vamos implementar o 1, Nomes à vista" (`PLANO_RITMO_JOGADOR.md`, D): com os três bairros o mapa
    abria abaixo de `NAMES_K` e só mostrava os bairros; achar a Rua Tiradentes levou 31 s. Os nomes das ruas aparecem
    desde o mapa afastado (`NAMES_K` saiu): sem lugar no meio de um trecho, o abreviado ("R. do Sol") ou só o nome
    ("Estação", "Tiradentes") desliza ao longo da rua, sem sair da folha; cada rua primeiro no bairro onde começa, as
    horizontais antes, alternando os lados (a do meio à direita) para deixar colunas para as verticais. Com os três
    bairros, as 14 ruas têm nome; Flores, Brasil e Acácias, já nomeadas em Vila Serena, só repetem no Centro se couber.
    Redesenhar os nomes custa ~1,4 ms (só quando muda a rua destacada).
322. #mapa #despacho #saiu "Testar a sugestão 2, Grade e índice de ruas" (`PLANO_RITMO_JOGADOR.md`, D): grade fixa na
    cidade (colunas A–F, linhas 1–4) e um índice das ruas à vista ("Tiradentes … E1–E2") num papel acima do selo.
    Saiu: "o índice basicamente atrapalha o jogador", porque cobre ruas (nas primeiras noites, um canto de Vila
    Serena; na noite 9, um terço do Centro); com os nomes à vista ele só repetia a informação com um passo a mais, e a
    grade carregava o mapa.
323. #mapa #despacho "Comece pelos pontos 1 e 2" (`PLANO_RITMO_JOGADOR.md`, F): (1) 40% das emergências de molde dão
    a rua e um lugar ("perto do posto"), e na noite 9 nenhum nome de lugar cabe no telhado: com o mouse no prédio de
    referência, a etiqueta diz o nome (`CityMap._spot`). (2) A numeração dos trechos só aparecia bem aproximado, e os
    trechos não coincidem com os cruzamentos: com o mouse numa rua, ela inteira fica de leve, o trecho mais forte e
    aparece o número onde começa cada trecho (`_draw_hover`). O realce amarelo era desenhado antes dos nomes e sumia
    embaixo da faixa de papel do nome ("a barra amarela de seleção não aparece"); agora vem depois. Na rua vertical a
    etiqueta fica ao lado (em cima tapava o trecho e o "100"). Captura: `tools/shot.gd` `--street=sol,1` e `--spot=Posto`.
324. #mapa #despacho "Dê mais ênfase nesses amarelos" e "adicione o intervalo ... (100-199)": o realce da rua sob o
    mouse ficou mais forte (`LIT`: a rua inteira 0,4, o trecho 0,8) e voltou para baixo dos nomes, com a faixa de
    papel do nome dessa rua no mesmo âmbar (`_road_of`, `_road_at`: por cima, o âmbar forte apagava o nome). Cada trecho
    mostra o intervalo ("200–299") na beira da rua, dentro do papel, no ponto mais perto do meio que não encoste em nome;
    sem lugar, por cima (só aparece com o mouse na rua). Em cima da rua, os intervalos tapavam os nomes, e o meio dos
    trechos das verticais cai quase nos cruzamentos.
325. #despacho #mapa #interface #testes "Na primeira vez que abro a máquina de despacho e passo o cursor por cima das
    ruas, não mostra o seletor, só mostra se eu clicar em outra parte": o objeto da mesa abria a ferramenta ao apertar
    o botão, e o papel surgia sob o mouse com o botão apertado; pelo `GameView`, a soltura se perdia e a cena ficava
    com o mouse até o próximo clique (o mapa não recebia os movimentos). Valia para toda ferramenta aberta pelo objeto
    (pelas teclas 1–4, não). O clique na cena (`Background.pointer`) passou a agir ao soltar; o `test_keys` clica no
    objeto pela janela e confere que o mapa já vê o mouse.
326. #despacho #mapa "Clica uma vez na rua e clica novamente para confirmar a impressão", "deixar isso evidente para o
    jogador": o primeiro clique no mapa só datilografa o local na tira da impressora (`CardMachines.draft`,
    `type_draft`) e marca o trecho vazado (`CityMap.pend`); outra rua troca o local, sem cartão a triturar; o segundo
    no mesmo trecho imprime (`Dispatch._pick`), já sem datilografar. O aviso "clique de novo para imprimir" pisca na
    impressora e vai em vermelho na etiqueta do trecho. O quadradinho da marca passou para cima dos nomes (o nome no
    meio do trecho o tapava). Com um cartão na mesa, o primeiro clique já é recusado.
327. #despacho #mapa "simular uma máquina leitora de microfilme ... girar um controle de zoom", "não vamos remover a
    rolagem do mouse", "+ e −" acima e abaixo: o anel de aproximar na moldura da direita, mais larga (`KNOB_W`,
    `_draw_knob`, `_knob_input`): arrastar para cima aproxima, a roda sobre ele também, e o + e o − dão um degrau
    (apagados no limite); os sulcos andam com a aproximação (`CityMap.zoom_level`, `zoom_by`).
328. #despacho #mapa #objetos #som #testes "Pode fazer todos, exceto o ponto 5" (imprimir clicando na impressora ficou
    de fora): a marca do local (o quadradinho) em tamanho de tela, por cima dos nomes, e o tracejado com ao menos 3 px
    (afastado, sumiam); a miniatura da unidade na mesa com o anel na moldura da direita (`_art_glass`); o anel clareia
    sob o mouse e tem embaixo o mostrador do aumento ("1.4X", `CityMap.magnification`); um tique de catraca por sulco
    que passa (`knob_tick`, no máximo uns 25 por segundo); o robô `--human` dá o segundo clique na rua 0,4 s depois do
    primeiro (`CONFIRM_SEC`).
329. #despacho #mapa "ele está 'liso' ao girar ... ter o tic e pular pro próximo zoom" e "o display ... poderia ser
    analógico ... números 'girando'", "uma pequena escurecida na parte de cima": o aumento do mapa anda em degraus de
    0,1 (`CityMap.ZOOM_STEP`, `zoom_step`; a roda no mapa e o + e o − também caem num degrau, o máximo no degrau abaixo
    de `MAX_K`); o anel avança um degrau a cada `DETENT_PX` arrastados, com um tique, e os sulcos pulam um terço de
    sulco por degrau (`DETENT_TURN`), sem giro contínuo. O mostrador é um contador de tambores (`_drum`, `_roll`): o
    número rola até o novo e o das unidades só vira quando o dos décimos passa do 9; a beira de cima da janela escurece
    (a janela é funda).
330. #testes #ferramentas "Adicione isso às lições aprendidas ... a tela da godot fica preta e paralizada e você espera
    muito tempo antes de fechá-la": captura com o `shot.gd` quebrado ficava parada até o limite de 2 min. As capturas
    passaram a rodar com `--quit-after 1500` (`CLAUDE.md`, `visual.sh`, `hibit_shots.sh`) e a lição foi para o
    `LESSONS.md` (Ferramentas e testes).
331. #despacho "acho que tá pra fazer mais algum ajuste para dar mais profundidade" (das sugestões, 1 a 3; o brilho do
    vidro ficou para depois): o mostrador do aumento com um tambor por algarismo, cada um no seu rasgo rebaixado da
    chapa (a beira de cima e a da esquerda escuras, a de baixo e a da direita na luz), o papel escurecendo no alto e
    embaixo como um cilindro, e o ponto e o X gravados no metal, em latão (`CardMachines._drum`).
332. #despacho "Aumente só mais um pouco de pixels para dar mais respiro" e "um pequeno vão entre o anel de zoom": a
    moldura da direita foi de 24 para 28 px (`KNOB_W`; o mapa na cena acompanha, e na noite 9 ele não encolhe, pois
    cabe pela altura), com folga em volta do mostrador; o anel num rasgo com 2 px de vão em volta, a beira de baixo e a
    da direita na luz. Os tambores chegaram a crescer para 7×11 e voltaram ("Eu queria que aumentasse a borda da
    máquina para dar respiro", não o mostrador).
333. #burocracias #debug #mesa-comutadora "Temos um novo plano de implementação" (`PLANO_BUROCRACIAS.md`): a
    infraestrutura das burocracias, só pelo debug e com a chave geral desligada (o jogo é o de sempre). Cada regra é um
    `.tres` em `data/bureaucracy/` com o script dela (`BureaucracyRule`); o gerente (`Bureaucracy`) não conhece nenhuma,
    aplica só a maior advertência de cada tentativa (também contra o número errado) e registra todas as decisões
    (salvas no `Progress`). B1 identificação e recados, B2 bloqueados (horário, código, urgente, acordo com sinal), B3
    código de autorização (gerador provisório K-07, M-14...; a gravíssima deixa a noite Insuficiente, mantida a pedido),
    B4 fitas. O porta-fitas e o gravador ficam "na prateleira, na parte embaixo de onde fica a sessão Interurbano. Mas
    isso pode mudar mais pra frente": o lugar fica tampado até a primeira burocracia trazer um equipamento. Guia:
    `BUREAUCRACY_RULES.md`; a regra de exemplo (limite de duração) foi feita só por ele.
334. #burocracias #debug "Não entendi nada desse debug": na B1, quem recusava o nome recusava sem ninguém pedir (agora o
    operador pede nome e sobrenome depois do "alô"; no "só se insistir", a opção é "[Insistir no nome]"), e a B4 ligada
    com o turno andando, ou antes da chave geral, chegava sem fitas (a regra que passa a valer começa na hora, `sync`).
    O botão de uma ligação de teste liga sozinho a chave geral e a regra dela (antes, tocava como uma comum), e a aba
    abre com "como usar".
335. #burocracias "O jogador terá uma nova opção de botão (Solicitar identificação) e não perguntar automaticamente pois
    aí tira a iteratividade da burocracia": na B1 ninguém pede o nome sozinho; quem não se identifica mostra
    [Solicitar identificação] (quem diz o nome sem pedir não mostra). Recusado, [Insistir no nome]; quem recusa de novo
    (`refuse_again_line`) só deixa desligar ou transferir com advertência. Recado recusado: quem ligou reclama
    (`message_refused_line`) e desliga; anotado, agradece e desliga. "Destinatário liga" só oferece o recado depois que
    a pessoa diz quem é. Novo jeito: diz quando pedem (`WHEN_ASKED`).
336. #burocracias #saiu "Esse Destinatário recebe não faz sentido nenhum": dar o recado do bar a quem liga para o bar
    saiu (vinha do plano, "ou receber ligação"). O recado só vai para quem é o destinatário, quando ele mesmo liga e diz
    quem é.
337. #burocracias "nem todo recado é anônimo": o recado leva o nome de quem se identificou antes de o operador anotar
    (ligação de teste "Recado com nome"), e na entrega o operador diz de quem é ("Fulano deixou um recado"); a
    advertência configurável continua só para o anônimo.
338. #burocracias Na B2: avisado o bloqueio, quem ligou ficava calado (agora reage, `refused_line`, e desliga); o código
    de autorização vinha antes do pedido (agora depois: gancho novo `request_made`); sem código, nada dizia que o número
    estava bloqueado (agora um aviso na conversa depois do pedido: bloqueado, só com o código, liberado até as 21h; na
    B3, "exige o código"); aceito ou recusado o acordo, quem propôs ficava esperando (agora agradece ou reclama e
    desliga). A reação ao "não" virou um campo só, `refused_line` (era `message_refused_line`, da B1).
339. #burocracias "Verifique se há mais inconsistências com relação ao B2": com o sinal de um acordo, o aviso e o botão
    de bloqueio olhavam o destino do acordo, não o número pedido (o operador não podia recusar o acordo naquela
    ligação); desligar na cara de uma ligação urgente para um bloqueado não ia para o registro (agora é decisão moral);
    faltava a ligação de teste com o código errado.
340. #burocracias Pontos menores da B2: avisado do bloqueio, quem liga sem `refused_line` (as ligações comuns do jogo)
    diz uma das `reactions` da regra, sorteada (passiva, reclama do governo, indiferente; as falas são do usuário, no
    `.tres` só marcadores `[TESTE]`). O bar: bateu 21h, transferir dá advertência mesmo atendida às 20:55 (já era
    assim). Com o sinal de um acordo, o pedido continua sendo X: transferir para X é a conversa normal com a advertência
    do bloqueio (antes tocava como número errado, com a reclamação de quem foi acordado); Y vira o destino só ao
    transferir para ele.
341. #burocracias "Não existiria uma opção mais barata?": o [Avisar o bloqueio] do bar aparece quando bate 21h com a
    ligação esperando, por um temporizador só, armado no pedido até a hora da janela (nada de conferir a cada quadro).
342. #burocracias "Verifique se há inconsistências no B2": com o sinal, tentar Y (sem atender, ou desfeita) deixava Y
    como o destino certo, e voltar para X virava número errado; agora o certo é o tentado na hora (X ou Y, com o nome
    original de X guardado).
343. #burocracias "Tem que ajustar isso" / "uma coisa exclui a outra": número bloqueado (na lista da B2) nunca fica
    "ninguém atende" (`PhoneCall.away` desligado no começo da ligação); com isso a Borracharia do acordo também atende.
344. #burocracias B3: quem não diz o código no pedido ganha o [Pedir a autorização]; quem tem lembra e diz
    (`TransferCall.code_when_asked`), quem não tem reage (a dele ou uma das `reactions` da regra, sorteada, como na B2)
    e desliga. Código não dito conta como sem código (`Bureaucracy.code_of`).
345. #burocracias "No caso da funerária, vai depender apenas do roteiro": bloqueado que passa a valer só com
    autorização é a burocracia trocada (sai da lista da B2, entra nos `numbers` da B3, por `update_params`), e vice
    versa; a B2 não ganha o "lembrar o código".
346. #burocracias "Repasse novamente o B1, B2 e B3": sem erro de fluxo; apontados (sem mexer) o código da noite que o
    jogador ainda não tem como saber fora do debug, o recado entregue sem resposta de quem recebe, o registro de
    "desligou" só na B1 (na B2, só a urgente; na B3, nada) e o `code_frees` da B2 repetindo a B3.
347. #burocracias Sobre a revisão (346): o código da noite fica em aberto (depende do roteiro). O recado entregue ganha
    a resposta de quem recebe, escrita junto com o recado (`TransferCall.message_reply`, guardada na fila; nada
    sorteado, "precisam fazer sentido"). Desligar sem transferir agora vai para o registro nas três: B1 sem
    identificação, B2 sem avisar o bloqueio (permitido; a urgente, decisão moral), B3 sem o código certo.
348. #burocracias #saiu "Pode apagar o jeito B": saiu a liberação por código da B2 (`code_frees`, o aviso
    `SYS_BLOCKED_CODE` e as três ligações de teste da Funerária). Precisa de autorização = B3 (o código e o botão
    [Pedir a autorização], gravíssima sem ele); o roteiro troca a burocracia do número. Contraria o plano (B2 com código,
    grave), a pedido.
349. #burocracias "Têm mais inconsistências? Melhorias que recomenda?": apontados a B1 valendo só para ligações com
    `caller_name` (o plano: todo emissor, com ela ativa) e o roteiro sem como ligar as burocracias por dados; recomendados
    a lista de burocracias por noite no `Night`, o robô do turno com elas ligadas e os avisos com o nome do lugar.
350. #burocracias Sobre a revisão (349), "todo mundo possui nome mas só vai mostrar o nome no chat depois que a pessoa
    falar o nome": a B1 vale para toda transferência (saiu a exceção de quem não tinha `caller_name`); o chat mostra
    `caller` até a fala do nome e o nome dali em diante (`PhoneCall.named`; a voz continua a mesma).
351. #burocracias "Vamos preencher com nomes. Mas não usar apelidos, tratamentos ou coisa do tipo": `caller_name` em
    todo roteiro de transferência (`data/calls/`) e, para os moldes, `GameContent.caller_names` ("descrição:Nome
    Sobrenome", sorteado por descrição de `callers`; `GameData.caller_name`). Mesma pessoa, mesmo nome: Rute Fonseca
    (dito na conversa), Marta Costa e Benedito Souza (os da lista), Seu Ernesto nas duas ligações, e os de `callers`
    iguais aos roteiros (Jair, Cida, Valdir, Olga). Apelido vira o nome (Glorinha: Glória; Zefa: Josefa; Cida:
    Aparecida). Nenhum nome repete gente das falas. O `test_content` cobra nome e sobrenome sem tratamento.
352. #burocracias "o Seu Ernesto fala com voz w em story_02 e com voz m em transfer_31": a mesma pessoa, a voz de idoso
    (`w`) nas duas, a da ligação do roteiro.
353. #mesa-comutadora #cabos #camera "Essa angulação da placa na mesa comutadora está muito errada": o tampo largo do
    lugar dos equipamentos (embaixo do interurbano) usava a inclinação estilizada dos pares de buracos e, ao lado da
    lateral da prateleira, ficava torto; agora as laterais dele fogem para os olhos (`_draw_cover(..., exact)`,
    `_eye`), como a lateral. Os tampos pequenos dos pares continuam na inclinação dos buracos.
354. #mesa-comutadora #cabos "Há espaço para centralizar as placas na prateleira": os tampos (os dos pares vagos e o
    dos equipamentos) ficavam encostados na beira da frente (9 px de madeira atrás, 1 na frente); agora ficam no meio
    da prateleira, do pé do painel à beira de latão (6 e 5 px).
355. #burocracias "É a mesma pessoa": o Seu Benedito da `transfer_24` é o Benedito Souza da lista; a voz dele passou
    de `m` para `w`, a mesma da lista.
356. #mesa-comutadora #cabos "As placas dos cabos estão erradas... muito coladas e quase encostando nos plugs à
    esquerda", depois "ficaram finas demais e ainda estão com uma angulação estranha em relação à placa maior": os
    tampos dos pares vagos tinham a largura do passo entre os pares (26 px, `COVER_W`) e a inclinação estilizada deles;
    no passo menos um vão ficaram finos. Agora dividem por igual o vão do último par (os dois buracos) ao tampo dos
    equipamentos, com 6 px entre eles (`COVER_GAP`), e as laterais fogem para os olhos como as do tampo maior
    (`_receding`; saiu o `exact`).
357. #mesa-comutadora #cabos "Quando o setor é liberado a outra placa aumenta, não faz sentido. Vamos afastar só um
    pouquinho todos os plugs para a esquerda... para caber as duas placas sem redimensionar": cada tampo tem tamanho
    fixo (`COVER_W` 24) e lugar fixo, contado do tampo dos equipamentos para a esquerda; o FONE e os cabos foram 4 px
    para a esquerda (`FONE_HOLE_X` 10, `CORDS_X` 26, `TRUNK_GAP` 10; o passo continua o mesmo). Centrados nos lugares
    dos pares não cabiam: o passo (~26 px) mal passa da largura do tampo.
358. #mesa-comutadora #cabos "Ajuste as placas, parece que elas estão flutuando na prateleira. Deixe mais orgânico e
    realista": saíram o contorno escuro e a sombra afastada 2 px; a chapa ficou mais rasa que a prateleira
    (`COVER_DEPTH` 20, madeira à mostra na frente e atrás), com a sombra colada só na frente e à esquerda, cada pixel
    no metal do painel pela luz da sala (`Pal.panel_metal`), quinas no tom da peça, um brilho de través, riscos de uso
    (`_cover_step`) e parafusos embutidos com a fenda virada a esmo.
359. #mesa-comutadora #cabos "Ficou mais feia. Continua parecendo que está flutuando e estão desalinhadas. Tente simular
    essa textura" (uma chapa escura com chanfro e quatro parafusos): os tampos ficaram retos, de frente, como a
    plaquinha do FONE (saiu o ponto de fuga e a textura da 358), no metal das chapas dos setores (`PLATE`): a beira
    de fora escura de cantos quebrados, o chanfro, um sulco, o campo mais escuro com grão fino e um parafuso escuro em
    cada canto; a sombra, uma linha rente embaixo e à direita.
360. #mesa-comutadora #cabos "A textura está ótima, mas faltou a angulação das placas em cima da prateleira, né? Não
    pode errar isso adicione no LESSONS.md": a textura da 359 entrou na perspectiva da prateleira, esticada linha a
    linha com as beiras fugindo para os olhos (`_cover_px`, `_receding`); os parafusos por cima, redondos, no lugar
    projetado deles. A lição dos tampos foi reescrita (a da 359 dizia "fica reta", errado).
361. #mesa-comutadora #cabos "Preciso que as placas sigam a mesma angulação dos plugs" (com riscos vermelhos na reta
    do par amarelo e nas beiras das placas): as beiras e a textura pendem como os pares (`_lean`, de `PAIR_SHIFT`);
    saiu o ponto de fuga da sala (`_receding`) nos tampos, o largo dos equipamentos também.
362. #mesa-comutadora #cabos "Você errou a parte direita da placa novamente... Tem que ficar na mesma angulação da mesa
    comutadora": a beira direita do tampo largo dos equipamentos fica paralela à lateral da mesa (`_draw_cover(..., side)`,
    a inclinação de `_receding` na beira da prateleira, ~0,33 px por linha); a esquerda e os tampos pequenos seguem os
    plugs (`_lean`).
363. #mesa-comutadora #cabos "As placas estão desalinhadas com relação aos plugs. Centralize os plugs e veja se
    resolve": as fileiras de buracos subiram 4 px (`SHELF_HOLE_Y` 4, `SHELF_FRONT_Y` 18), centradas na madeira à mostra
    (6 px atrás e na frente; eram 10 e 2), como os tampos: a fileira de trás bate com o fundo deles e a da frente com a
    frente. O equipamento da prateleira, assentado pela fileira da frente, subiu junto.
364. #burocracias Sobre o que faltava do plano: o sinal secreto da B2 virou três estalos de dedo ("estalos" em
    `secret_signal`/`deal_signal`), no ritmo da noite ("tec tec... tec", "tec tec tec", "tec... tec tec"...;
    `rule_blocked.rhythms`, `rhythm(noite)`: sempre o mesmo na noite, nunca o da anterior), com o som sintetizado
    ("snap", pelo barramento Phone) e o ritmo na conversa (`Conversation.snaps`). "Deixe isso pronto, mesmo que não
    usaremos agora": a chave geral, as regras ligadas e os parâmetros de `update_params` vão para o save
    (`Bureaucracy.state`/`_restore`).
365. #burocracias "Pode apagar": saiu a terceira resposta das regras, "pede ação" (`Verdict.action`, o `RequerAcao`
    do plano). Nenhuma regra a usava: o que a burocracia pede ao operador vem antes, por botão de resposta, e no
    Transferir só cabe "pode" ou "infração" (o plano proíbe bloquear).
366. #burocracias #fitas Correções da B4: pego escutando uma ligação marcada pelas autoridades, a advertência é da
    B4 ("Perceberam a escuta pedida pelas autoridades", média, trabalho malfeito para elas), não a da escuta sem ordem
    (`caught_listening`); entregar fita sem nada continua valendo zero, sem infração; as fitas entregues entram nos
    serviços prestados do relatório; três fitas por noite, sem acumular (já era). "Não quero mais a arte provisória,
    algo legal, com efeitos juicy, satisfatório": porta-fitas de madeira com as fitas em pé, gravador com teclas de
    piano (REC desce sozinha ao gravar), porta com a fita atrás do vidro e a etiqueta escrita à mão (o primeiro nome e
    um risquinho por palavra-chave), bobinas girando e passando a fita, VU com o ponteiro pulando com a voz, contador
    que rola e a caixa das autoridades com lacre; por cliques animados (escolhidos entre cliques e arrastar): a fita
    sai da fenda, vira no ar e cai na porta, que abre de mola e bate; entregue, pula e cai em pé na caixa; descartada,
    cai pela beira da prateleira; sons novos (`tape_*`).
367. #burocracias #fitas #cabos "As fitas e o equipamento ficaram pequenos?": pôr o gravador no tampo não cabe (as
    duas fileiras já vão de ponta a ponta, e o lugar à direita do bloco é o do jornal) e a caixa das autoridades no
    tampo tem o mesmo problema; "e se a prateleira diminuir um pouco a altura?": o painel ficou 10 px mais alto (238;
    a prateleira desce, numa branch separada, `feature/0000-lower-shelf`) e a frente do console 10 px mais baixa (54;
    a miniatura do painel ficou 16 px mais estreita para caber com folga). Com isso, os equipamentos têm 46 px de
    altura: a fita na escala de verdade (44 × 26) com o nome e a hora da gravação na etiqueta, o gravador com 42 de
    frente, as fitas do porta-fitas em estojo (a lombada de papel com a faixa da marca; a fenda fica vazia quando ela
    sai) e, embaixo do interurbano, uma régua de latão onde os equipamentos encostam (sem eles, marca o lugar).
368. #mesa-comutadora #painel #disposicao #saiu Integrar o despacho, o calculógrafo e o gravador na mesa comutadora
    (alargando-a, com o armário no canto e a prancheta solta na prateleira): avaliado como grande (as ferramentas
    abertas perderiam a largura mínima, e o canto direito é a janela); o usuário escolheu testar o meio-termo (só o
    calculógrafo, o gravador e uma gaveta de fitas no lugar dos botões de volume), ainda por fazer. Antes, só o visual
    da mesa comutadora, retrofuturista como na série Ruptura (imagem de referência do usuário), numa branch própria
    (`feature/0000-retro-switchboard`): a moldura de madeira saiu (esmalte cinza-sálvia de cantos redondos), painel
    cinza-esverdeado, faixa escura no alto com o nome das entradas e a legenda, aba escura no nome das saídas,
    trilhos finos nas colunas no lugar das faixas largas, plaquinhas creme com o número escuro, bancos e interurbano
    rebaixados e escuros, letras em creme, níquel no lugar do latão (buracos, plaquinha do FONE, plaqueta do
    fabricante, régua dos equipamentos); no console, a prateleira em esmalte claro, a frente escura e a lateral em
    esmalte (a sala, o painel de baixo e os aros das tomadas não mudaram).
369. #mesa-comutadora #painel #pixel Cantos do móvel bem mais redondos, como na referência: raio 12 por fora (era 5)
    e os cantos do painel, por dentro, também redondos (raio 7), com a fresta rebaixada acompanhando o arco
    (`_shell_frame`, `SHELL_R`, `_round_dist`). A moldura continua com 5 px (mais grossa, apertaria os bancos).
    Depois: a quina da lateral (e a do tampo, com os olhos acima dele) segue o arredondamento, varrendo o arco do
    canto para o fundo (`Background._round_edge`; a lateral reta deixava uma ponta acima do arco); os cantos de baixo
    voltaram a ser retos por fora, como na referência (o móvel entra no console; o arco mostrava a parede atrás).
370. #mesa-comutadora #painel #pixel Mais perto da série Ruptura (fotos dos terminais da Lumon do usuário): móvel
    de plástico branco-creme (era esmalte cinza-sálvia; o tom sobe no canto longe da luminária para o branco não
    sumir), painel verde-oliva (o usuário trocou o azul-marinho sugerido por oliva) e as chaves de escuta viraram
    teclas quadradas de plástico ciano num rebaixo escuro: soltas saem do painel, presas afundam e escurecem, com um
    pontinho aceso (a alavanca de bastão saiu).
371. #mesa-comutadora #painel #pixel #saiu Tecla de escuta presa acesa (primeiro um pontinho branco; a pedido, a
    tecla inteira acesa de uma cor só, fosca, com luz opaca sem miolo: `Pal.KEY_GLOW`) e os
    outros itens sugeridos para lembrar a série Ruptura: cantos redondos nos bancos, no interurbano, nas abas, na faixa
    do alto, nas plaquinhas e nas tampas A/B (`round_rect`); emblema oval ciano com a sigla CTSS no vão à esquerda do
    interurbano (na faixa do alto não cabia: a legenda começa logo depois do nome das entradas); o desgaste saiu (o
    painel clareado e os riscos em volta das tomadas, `_draw_wear`, e os parafusos e riscos das tampas A/B); a frente
    do console virou a bandeja do teclado dos terminais: plástico branco com uma placa oliva rebaixada de cantos
    redondos, os botões oliva com aro creme e sem os parafusos.
372. #mesa-comutadora #painel #pixel #b4 Mais itens no visual da série Ruptura: lâmpadas de plástico fosco num aro
    creme, acendendo de uma cor só, sem miolo branco nem brilho de vidro (como a tecla; o aro da legenda também
    creme); as tampas de metal parafusadas da prateleira viraram plástico creme liso encaixado; a plaqueta niquelada
    do fabricante virou etiqueta creme impressa em oliva, colada na placa do console; o gravador da B4 ficou em
    plástico branco com a frente oliva e as teclas ciano (a caixa das autoridades continua de aço).
373. #mesa-comutadora #painel #pixel Os aros das tomadas passaram de latão a cromado frio (`Pal.JACK_METAL`, o
    brilho também frio; eu tinha sugerido manter o dourado, o usuário quis o cromado) e a miniatura do painel no
    console seguiu a mesa: telas no oliva escuro, o operador em ciano, as teclas ciano (acesas se ativas) numa chapa
    oliva com etiqueta creme (antes copiavam as cores das teclas do painel de baixo).
374. #painel #telefone #pixel O painel do operador (embaixo) seguiu a mesa da série Ruptura: o corpo de madeira com
    parafusos de latão virou plástico creme liso; as telas da conversa e do rádio, oliva escuro (`HudPanel`); as teclas
    numa chapa oliva de cantos quebrados, sem parafusos, com a etiqueta creme e a tecla fosca, mantendo as cores
    (Atender verde, Desligar vermelho ajudam a jogar); o alto-falante em oliva. A miniatura do console volta a copiar
    as cores das teclas e das falas (o ciano do pedido 373 saiu), agora na chapa oliva com etiqueta creme.
375. #painel #telefone As teclas do painel não batiam com a miniatura que o usuário tinha visto (ciano, pedido 373):
    Atender, Transferir e Escutar ficaram ciano (`Pal.KEY_CAP[3]`, nas `KeyCap_*` do tema), Desligar continua vermelho
    para não ser apertado por engano; a miniatura copia as cores do tema.
376. #painel #captura Conferir as teclas ativas: opção `--keys` no `tools/shot.gd` (todas as teclas do painel ativas,
    sem ligação). Ativas ciano claro e vermelho; apagadas, escuras; a miniatura acompanha, mais escura pela luz da sala.
377. #despacho #calculografo #pixel A máquina de despacho e o calculógrafo seguiram a mesa (série Ruptura), itens 1 e 2
    da sugestão: as caixas das máquinas (`CardMachines.box`, que o calculógrafo também usa) em plástico creme de cantos
    arredondados, sem parafusos, com uma frente oliva rebaixada para a luz e o aviso (âmbar e vermelho não se liam no
    creme); as plaquetas de latão viraram etiquetas creme impressas em oliva (o nome das máquinas, a do fabricante, as
    plaquinhas das entradas do calculógrafo); o visor dos contadores em oliva escuro. Na sala, a base da unidade de
    despacho e o calculógrafo também creme, três tons abaixo do aberto (sob a luminária ficavam brancos); `Pal.SHELL`
    entrou nas rampas do `Pal.lit`. A moldura do mapa, as lâmpadas e a caixinha dos bilhetes ficam para depois.
378. #despacho #calculografo #pixel Itens 3 e 4: as lâmpadas das máquinas (`CardMachines.led`, também no calculógrafo)
    viraram cúpulas de plástico fosco num aro creme, de uma cor só, como as da mesa (na sala, o aro creme nas luzes da
    unidade); a moldura do mapa do despacho, oliva como o painel da mesa (`bevel` em `Pal.BOARD_METAL`), sem parafusos,
    com o + e o − e o mostrador impressos em creme (a borracha do anel continua escura; na sala, o painel do mapa
    oliva); a caixinha dos bilhetes do calculógrafo virou bandeja de plástico oliva com a etiqueta creme (aberta e na sala).
379. #despacho #calculografo #sala #cabos Os papéis viraram papelaria da companhia: o bilhete de tarifação impresso em
    azul-petróleo (`Pal.TICKET_FORM`, o ciano escuro das teclas; o azul-marinho destoava) e o selo oval CTSS da mesa
    impresso na ficha de despacho (vazado na faixa vermelha, que fica: diz "emergência") e no bilhete (ao lado do
    campo do carimbo); o selo virou `Switchboard.badge`, estático. Na sala, fios cinza-escuros saem de baixo da unidade
    de despacho e do calculógrafo, deitam no tampo numa curva frouxa e entram num passa-fio na lateral do console da
    mesa comutadora (`_draw_cable`).
380. #cabos #sala #despacho #calculografo #objetos Os fios das máquinas estavam finos (menos que os cabos de conexão) e
    cheios de furos, e não pareciam plugados: viraram borracha escura de 5 px, montados numa imagem guardada
    (`_cable_image`), com um plugue de corpo creme e capa de borracha encaixado na lateral de cada máquina
    (`_draw_cable_plug`, desenhado depois dela) e o passa-fio menor na lateral do console. Depois, os outros objetos da
    mesa na paleta da mesa: o relógio de flip no plástico creme das máquinas com a base oliva, a borda da caneca e a
    lista do meio em azul-petróleo e a fita do bloco de fichas em oliva (a lista mostarda, a vermelha, o lápis e a
    almofada vermelha ficam: cor de objeto de verdade).
381. #cabos #sala A arte dos fios e plugues estava ruim: saíram o plugue na lateral (parecia adesivo) e o passa-fio
    (um quadrado de frente na lateral em perspectiva). Os fios saem de trás das máquinas e somem atrás da lateral do
    console, como esses aparelhos são ligados; sem contorno escuro (brilho em cima, sombra embaixo e no tampo), curva
    com folga sem cantos em L e a grossura pela distância (`CABLE_D`).
382. #cabos #sala "Por trás da máquina" saiu "por baixo" (o fio nascia no pé da frente) e os fios sumiam embaixo da
    mesa comutadora: agora saem da traseira (a ponta escondida atrás dela, o fio caindo de trás ao lado dela), correm no
    tampo por trás, sobem pela lateral do console e entram num plugue de borracha encaixado nela, desenhado no plano da
    lateral, entre 20% e 65% da fundura dela (`_draw_cable`, `CABLE_PLUG`, `CABLE_PLATE`); cinza-escuros (marrons, sumiam
    no tampo). `_side_faces` desceu para `background_props`.
    No mesmo pedido, depois: os fios vão todos para o fundo da mesa, junto da parede ao lado da mesa comutadora
    (primeiro para o lado, rentes ao console, e então para o fundo), sem plugues (saíram a pedido).
383. #cabos #sala O fio do calculógrafo parecia passar por baixo da máquina (saía rente à traseira, indo para o lado, e
    na perspectiva aparecia no meio da lateral): agora sai rente atrás dela, sem cair do alto, e já recua ao sair, em
    diagonal para o fundo (`CABLE_SAG`), até a parede ao lado da mesa comutadora.
    Depois: em diagonal, o fio do calculógrafo passava por baixo da quina da unidade de despacho (o usuário viu na
    captura): vai primeiro para o lado, recuando só um pouco (`CABLE_SAG` 0,12), e, rente ao console, para o fundo.
384. #cabos #sala Acabamento dos fios: a ponta passa da beira de trás do tampo e cai no vão entre a mesa e a parede (a
    mesa é afastada dela: `DESK_T`), cortada na beira, sem pintar nada na parede além da grossura do fio deitado ali
    (parecia encostado na parede); o da unidade de despacho também sai rente ao tampo (caindo do alto, fazia um gancho
    solto); a curva em 10 retas entre pixels inteiros, de degraus iguais (em 32 trechos, os degraus saíam irregulares).
385. #cabos #sala Os fios pareciam amassados, não cilíndricos (quadrados carimbados ao longo da curva engrossavam nas
    diagonais e o brilho corria pelo comprimento nos trechos em pé): cada pixel pela distância à linha do meio, em
    faixas de cilindro com o brilho do lado da luminária (`CABLE_LIGHT`) e a sombra do outro (`CABLE_SHADE`), de 4 a 6
    px (`CABLE_D` 2,0).
386. #despacho #mesa A unidade de despacho no visual da mesa comutadora e do terminal da série Ruptura: a carcaça do
    mapa em plástico creme de cantos redondos com o rebaixo escuro da tela em volta do vidro (`SCREEN_RIM`), o anel de
    aproximar em ciano (`Pal.KEY_CAP`), + e − e o mostrador impressos em oliva escuro, e a base como a bandeja do
    teclado (creme em volta da placa oliva rebaixada onde ficam as máquinas, `_draw_tray`); a miniatura na mesa
    (`_art_glass`) igual.
387. #despacho #mesa Mais Ruptura no despacho: o fundo da tela em volta das folhas do mapa em azul-petróleo escuro
    (`Pal.MAP_BACK`, também na miniatura); as máquinas sem etiqueta nem saída de ar, com o nome impresso em creme na
    frente oliva (`CardMachines._name`) e os avisos em creme; a faixa de perigo da trituradora em creme e petróleo
    (`Pal.HAZARD`); o selo CTSS na faixa da base; na miniatura, os cantos da tela redondos, o alto e o lado em creme,
    as marcas do transmissor em ciano e sem a saída de ar. Os contadores do calculógrafo seguem em âmbar (são luzes de
    estado, como no aberto).
388. #despacho Os cantos da tela do mapa redondos, como a tela do terminal da série Ruptura: o vidro no rebaixo
    (`SCREEN_R`, `CardMachines._corner`) e, em cima, o rebaixo no plástico; na miniatura, um pixel em cada canto.
389. #despacho #sala Na miniatura, os cantos não ficavam redondos (um pixel por canto sumia na perspectiva): a tela e o
    rebaixo com raio de 3 a 6 px (`_round`), os cantos de cima da carcaça vazados e o alto do painel recuado nas pontas.
390. #despacho O despacho aberto seguindo a miniatura: os cantos de fora da carcaça e da base mais redondos
    (`CardMachines.CASE_ROUND`; as laterais descem por trás da base, sem vão nos cantos de cima dela).
391. #despacho A miniatura estava mais redonda que o despacho aberto, em proporção: no aberto, a tela com raio 18
    (`SCREEN_R`, cantos em textura guardada, `_corner`) e a carcaça e a base com raio 9 (`CASE_R`, `_rounded`, `_arc`).
392. #pixel #luz Melhorar o dithering e eliminar os degraus irregulares (jaggies): diagnóstico com capturas, mapa
    automático dos degradês contínuos (a sala tinha ~33 mil cores, pela luz contínua dos shaders) e os degraus
    marcados à mão (J1–J11); plano em `PLANO_PIXEL.md` (vértices no pixel, inclinações limpas, linhas desenhadas
    na tela e não na textura projetada, luz em degraus com pontilhado só nas transições grandes, cabos de conexão
    como cilindro). O pontilhado dos halos tinha saído a pedido (58): a etapa da luz pede aprovação.
393. #pixel #luz O plano em checklist para ir fazendo aos poucos (`PLANO_PIXEL.md`). Decisões: o pontilhado e o
    número de degraus de luz são testados e mostrados antes de aprovar (preferência pela versão mais suave, 6–8
    degraus); o desgaste do carimbo fica.
394. #pixel Etapa 0 do `PLANO_PIXEL.md`: a medida em `tools/pixel_map.gd` (cores distintas e blocos de degradê por
    captura, com o mapa em laranja) e os números de partida no plano; o `tools/hibit_shots.sh` esperava pouco e só 4
    capturas saíam (agora 3500 quadros, e diz quantas saíram).
395. #pixel #mesa-comutadora #sala Etapa 1 do `PLANO_PIXEL.md`: na mesa comutadora e nos objetos do tampo, os pontos
    dos polígonos no pixel inteiro (`Background._snap`, ligado no `_draw_switchboard` e no `_draw_desk_props`; as faces
    e os tampos com textura projetada também, para a textura pisar onde a face pisa); as quinas que pegam a luz (lateral
    da mesa, relógio) como a coluna rente à beira (`_pixel_line`), não um traço recalculado; nas tampas do console, a
    fresta e a quina contadas da beira já arredondada de cada linha (as diagonais dobradas sumiram). O
    `tools/visual.sh` também não tirava capturas (3500 quadros, e a lista de classes da cópia do commit renovada).
396. #pixel #mesa-comutadora #janela #vista Etapa 2 do `PLANO_PIXEL.md`: as beiras longas em inclinação limpa
    (`Background.clean_slope`: degraus iguais ou alternados por igual, movendo a ponta de longe só nos eixos permitidos)
    na lateral da mesa, nas beiras do bloco de fichas e do jornal e na cornija das paredes da rua; no peitoril, só os
    pontos inteiros e a luz pixel a pixel (limpo, ele descolava do batente no amanhecer).
397. #testes "Limpe todos os prints desnecessários": saíram os `print("OK <seção>")` dos testes (o `# ---- N.` de cada
    seção já diz o mesmo, o `run.sh` mostra só o `PASSOU` e o `ok()` aponta a linha da falha), o do `test_layout` no
    laço e o aviso do mapa sem desenho no `test_flow`. Ficam o cronômetro do `DebugPanel` (`PLANO_RITMO_JOGADOR.md`),
    as métricas do `test_shift` (o `calibrar.sh` as lê), os avisos do `test_content` e a saída das ferramentas.
398. #testes "Na pasta build está cheio de imagens": os "prints" do item 397 eram as capturas. Saíram de `build/` as
    soltas e as das pastas `plano/`, `eff/`, das etapas antigas do `PLANO_PIXEL.md` e do cache velho do `visual.sh`
    (109 → 31 MB); ficam `pixel/ref` (a partida), `pixel/mapa` (o diagnóstico), `pixel/etapa2`, o cache da HEAD do
    `visual.sh` e a `calibracao/`.
399. #pixel #janela #objetos "Vamos seguir com o plano": etapa 3 do `PLANO_PIXEL.md`. O `_pixel_line` leva as pontas ao
    pixel inteiro e distribui os degraus por igual (os filetes da lombada das listas, as pautas e a margem do bloco, o
    lápis e as quinas usam ele); a persiana com lâminas de 3 (eram 2) e a beira de cada lâmina numa reta de pixel na
    tela: em faixas de 1 px na perspectiva, as beiras convergindo viravam moiré (o J8 do plano, chamado de verga).
400. #pixel #objetos "Ainda acho que há pixels sem conserto" (a beira da direita do bloco de fichas com dentes): o
    `_project` desempata sempre do mesmo jeito o pixel cujo centro cai na beira (`EDGE_EPS`); numa inclinação limpa
    entre pontos inteiros, a reta passa pelos centros e o erro da conta punha um pixel a mais ou a menos.
401. #pixel #objetos "No lado esquerdo do caderno também pode ser melhorado?": o lado esquerdo do bloco de fichas
    em degraus 2-2-1 (razão 1,73, fora dos 12% do `clean_slope`) passou a 1-2-1-2 (`FLAT_TOL`, 16%, nas beiras do lado
    dos objetos chatos); a risca escura do contato com a mesa, que alternava 1 e 2 px, é o pé arredondado deslocado 1 px
    para cada lado (`_desk_shadow`, em todos os objetos), não mais o `offset_polygon` fracionário.
402. #pixel #objetos "Conserte, por favor" (a auditoria das beiras pelas capturas): os cantos das caixas do relógio,
    do calculógrafo e da caixinha dos bilhetes saem de `_clock_corners`, com as beiras do lado em razão exata
    (`exact_slope`: o canto de trás anda de lado e, se a razão só fica quase exata, 1 px na altura); o tampo do relógio
    ficou em 2:1 (era 2-2-2-1 e 2-2-3-2) e a base em 1,5 (tinha um dente), com a sombra de contato no pé da base; os
    livros têm a mesma conta (`BOOK_TOL`, 25%: o volume de cima, 1,25 e 1,29, não mudava com 16%) e a capa projetada
    sem o tom liso por baixo; a beira da lateral da mesa comutadora no tampo, 3-4 com um 4-4 no meio, foi dobrada para o
    degrau diferente ir para a ponta (`_bent_edge`). Medidas pelo `tools/edge_steps.gd`.
403. #pixel #luz #saiu "Comece a implementação" (etapa 4 do `PLANO_PIXEL.md`): a poça da luminária foi testada em
    degraus com pontilhado ordenado 4×4 (8, 6 e 4 degraus) e em degraus secos, quantizada antes da força para não
    cintilar. "Prefiro não aplicar essa etapa, os pontilhados deixam muito ruído e a poça em camadas fica sem
    profundidade": saiu inteira, o código desfeito; a luz continua lisa (só a poça baixava as cores de 33,7 mil para
    ~31 mil). Não refazer pontilhado nem luz em degraus sem pedido.
404. #pixel #cabos "Certo, pode seguir" (etapa 5 do `PLANO_PIXEL.md`): o fio de conexão parado (`Cord.asleep`) sai de
    uma imagem montada pixel a pixel pela distância à linha do meio (`Switchboard._rope_image`, guardada em
    `_rope_arts`): a mesma grossura em toda a curva, a beira escura sem engrossar nas diagonais, o trançado do lado
    da luz e a sombra do buraco nas mesmas cores; mexendo, o desenho traçado de antes (`_draw_rope_line`). Montar
    custa 2 a 10 ms, uma vez, quando ele dorme; o `medir.gd` deu igual com e sem.
405. #pixel #sala #saiu "Show, pode continuar" (etapa 6 do `PLANO_PIXEL.md`): os cabos do painel até a caixa de
    passagem viraram dois fios retos, em pé ao lado do cano e a 45° até o painel. "Mas tava infinitamente melhor
    antes, agora está bem ruim, os fios retos e sem curvatura, tá muito feio": voltaram os quatro, caídos em curva
    (o moiré entre eles fica). Não endireitar os fios. "Faça isso": as mesmas curvas montadas pixel a pixel
    (`_cable_at`, o desenho dos fios das máquinas), de 2 px, a saída na caixa um pouco mais aberta. "Os fios estão
    'flutuando' na frente da caixa e não saindo dela": nascem dentro dela, que é desenhada por cima.
406. #pixel #ferramentas "Faça isso. Em seguida, faça o restante" (as sugestões depois do plano de pixel): as beiras
    consertadas (bloco, livros, lateral da mesa comutadora, peitoril) ficam em `tools/beiras.txt` com os degraus
    aprovados, e o `tools/visual.sh` as confere (`tools/edge_steps.gd --check`; medidas vindo do fundo, `,l`/`,r`/`,u`/`,d`).
    Às 21:00, no amanhecer e na chuva as beiras saem iguais (a luz não mexe nelas); a tela larga não conta (o jogo é
    sempre 960×540, `GameView.BASE`). O cabo de conexão parando muda só uns pixels do trançado (deixado assim). Os
    fios da caixa sem se cruzarem: só proposta (abrem o leque por cima da placa). `PixelArt.bounds` no lugar das três
    cópias de `_bounds`.
407. #sala #interface #painel "Pode seguir na sequência" (o que melhorar depois da reformulação dos objetos): o
    armário de aço com a cornija de cantos redondos, as venezianas num recuo escuro (como as teclas da mesa), a
    etiqueta com o selo da companhia impresso em azul-petróleo (`Switchboard.badge`) e o guarda-chuva com volume (luz
    à esquerda, sombra à direita; chapado, parecia uma faixa preta). As respostas do painel de baixo (`ChoiceButton`)
    viraram plaquinhas creme com letra escura, como as etiquetas das teclas (eram caixas pretas de contorno fino). As
    teclas apagadas com a letra na cor da tecla, escurecida (a tinta escura a meia força sumia no tampo apagado).
    Depois, "se eles acendem não faz sentido ficar com texto preto": as teclas acesas com a letra creme clara (a cor do
    texto da conversa), como letra iluminada; as plaquinhas de resposta seguem com a letra escura (são papel).
408. #painel #interface "As plaquinhas que indicam as teclas do teclado não estão com os textos centralizados": os
    rótulos do atalho (Espaço, Tab, Z, X) estavam 2 px acima do meio da plaquinha creme (3 px em cima, 5 embaixo);
    descidos 2 px no `phone_panel.tscn`, a folga ficou igual em cima e embaixo (dos lados já estava, ±1 px).
409. #cabos #mesa-comutadora "Melhorar a física dos cabos dos plugs, atualmente os cabos atravessam os plugs
    conectados e também os desconectados": os plugs encaixados viraram pinos para os fios encaixados das outras pontas
    (`Cord.pegs`, `Cord.clear`: o fio contorna ou se apoia neles; esticado, dobra neles) e os fios encaixados passam
    atrás dos plugs guardados em pé (ordem do desenho: encaixados, guardados, da mão e soltos). Na mão e solto, o fio
    vem para a frente e não bate (prender o fio nos plugs enquanto arrasta não foi pedido). Tratar os guardados como
    obstáculos (o fio por cima das pontas deles) foi descartado na proposta: o fio subiria quase reto ao sair do buraco.
    `--plugs=3:296,4:162` no `tools/shot.gd`.
    Depois, "os cabos ficaram por baixo do buraco do slot": a beira da frente dos buracos era desenhada junto de cada
    plug guardado e depois de cada fio, e cobria os fios que passavam por ela; agora sai de todos os buracos antes de
    fios e plugs (o plug guardado, cortado nela, continua entrando no buraco).
410. #cabos #mesa-comutadora "Faça a conferência e depois os itens 1 e 2" (das melhorias sugeridas para os fios): dois
    plugs encaixados lado a lado, com o fio passando entre eles por 16 caminhos, assentam sem tremer, sem prender e
    sem esticar; um plug encaixando em cima de um fio parado o fazia saltar 8 px num passo (o obstáculo agora cresce
    com o empurrão do encaixe, 0,6 px por passo) e o fio voltava a dormir dentro dele (o `calm` zera). (1) O pano agarra
    no plug em que se apoia (`Cord.PEG_GRIP`). (2) A sombra do trecho apoiado cai tão longe quanto a do plug. A
    investigação do desempenho: o quadro em ~7 ms é o deste Mac hoje (a versão 0.6.0 mede igual), e as chamadas de
    desenho do `medir.gd` oscilam entre ~235 e ~740 de uma execução para outra no mesmo commit, sem mudar ao esconder
    o jogo inteiro: não é regressão, é a leitura do monitor.
411. #cabos #som #mesa-comutadora "Pode fazer nessa sequência. Deixe 5 por último depois de eu aprovar os outros" (as
    melhorias seguintes dos fios). (3) O fio caindo num plug encaixado dá um "toc" abafado (`cord_knock`) e, tirado o
    plug que segurava um fio, o fio cai com o "tap" de sempre. (4) O plug em que o fio cai afunda um instante, como
    na assentada. (6) Onde dois fios se cruzam, o de cima faz uma sombra fina no de baixo. A 5 (o fio na mão
    enroscando nos plugs rente ao painel) espera a aprovação destas.

412. #cabos #mesa-comutadora "Faça a 5 agora". O fio na mão esbarra nos plugs encaixados só na metade do lado do
    buraco (`Cord.HELD_LIE`), a que ainda passa rente ao painel; a do lado da mão, erguida, passa por cima. Arrastado
    contra um plug, o trecho que já encostava não dá outro "toc" (dava um a cada ~0,1 s). Para testar no jogo: se
    atrapalhar, sai.
413. #cabos #mesa-comutadora "Os fios estão ficando por baixo dos plugs também, veja o plug azul". O fio encaixado
    que sai da fileira da frente da prateleira sumia atrás dos plugs guardados na de trás; agora o desenho vai fileira
    por fileira, de trás para a frente (os encaixados que saem dela, depois os guardados nela): ele passa na frente
    dos de trás e atrás dos da frente.
414. #cabos #pixel "Melhorar as cores das linhas dos fios: muito escuras, fogem do visual de remover as linhas que
    deixam com cara de desenho". A beira do fio era a cor dele escurecida 65% dos dois lados (`EDGE`, a mesma do
    plug): um contorno quase preto. Agora só o lado da sombra tem beira, escurecida 30% (`ROPE_EDGE`); o lado da luz
    fica na cor do fio, e a sombra do buraco cobre o fio inteiro.
415. #cabos #pixel "O plug encaixado está com o mesmo estilo de desenho; veja o que pode melhorar". Na vista de
    frente (`_draw_plug_face`), a beira de cada disco era o tom `6` (a cor escurecida 65%) em volta toda: agora é
    sombreada pela luz, no tom do meio do lado dela e escura só do lado da sombra (`ROPE_EDGE`). Os gomos escuros da
    capa, empilhados, faziam uma meia-lua preta no meio do plug: de frente, a capa fica um tom mais clara
    (`_face_row`). O plug em pé (na mão, guardado) segue com a beira `EDGE`.
416. #cabos #pixel "Mudar o visual dos plugs, deixar mais clean" (com a foto de uma mesa dos anos 60: plugs cinza de
    cotovelo com capa de frisos, guardados com a ponta de metal fina sobre o corpo cinza). O plug em pé virou um
    cilindro de plástico cinza liso, sem contorno escuro, com a ponta prateada (`Pal.PLUG_TIP`; antes, P10 de latão
    com corpo na cor do cabo, serrilhado e capa em gomos) e o trançado do fio mais discreto (`BRAID_MIX`). A cor do par
    fica no fio e numa faixa de 2 px no corpo (guardado, o fio some no buraco e não se sabia de que par era). Correções
    pedidas no caminho: "minúsculos" (voltou ao tamanho antigo, 12 × 59); "a parte metálica não está pequena?";
    "o plug está com uma escada" (a ponta reta até a cabeça); "troque a cor para prateado"; "de acordo com a largura
    da tomada" (a ponta com os 6 px do furo); "o pino está reto na ponta" (bico arredondado).
417. #cabos #pixel #mesa-comutadora "Siga com o cotovelo do plug encaixado". Encaixado, o plug é um cotovelo visto de
    frente (`_elbow`, montado pixel a pixel): a cabeça redonda na tomada e a capa de frisos com a faixa do cabo, o fio
    saindo do pé dela (`PLUG_DROP`, `Cord.stub`); os fios esbarram na cabeça e na capa (`ELBOW_PEGS`). Saiu a vista
    de frente em discos com paralaxe (`_draw_plug_face`, `_tilt`). Descendo reta, como na foto, a capa tapava a chave
    de escuta embaixo da entrada (e pegava o clique dela) e o número da tomada de baixo nos bancos; o usuário escolheu
    a capa em diagonal, a 45° para a esquerda, e o clique segue a silhueta.
418. #cabos #pixel #mesa-comutadora "Essa mudança piorou um monte de coisa, perdeu toda aquela lógica realista de
    paralaxe dos plugs na tomada, os cotovelos estão pequenos e grossos" (e a foto de novo: "o completamento do cabo e
    do cotovelo, além do formato do cotovelo"). O cotovelo virou um tubo só, da largura da capa: o pescoço sai da
    tomada com a paralaxe de antes (`_tilt`), a curva arredondada e a capa comprida (24 px, ~3 × a largura) com
    frisos no alto, e o fio continua da capa na mesma linha. A capa gira na tomada para o lado do fio (`_elbow_ang`);
    na entrada, sempre para a esquerda da chave de escuta. A sombra segue o plug desenhado. Corrigido junto: o contorno
    do cotovelo (destaque e clique) saía errado com linhas vazias no mapa (`_art_outline`); o `test_flow` confere.
419. #cabos #pixel #mesa-comutadora "O cabo amarelo e verde da esquerda ficaram em desacordo, o cotovelo deveria seguir
    a direção de onde o fio tá sendo puxado". A capa segue a linha esticada até o buraco do fio (sem somar o peso, que
    a deixava mais em pé que o fio). Na entrada, para a esquerda, inclina só o que livra a chave de escuta (antes, 40°
    no mínimo). Para a direita, segue o fio e tapa a chave (escolha do usuário: "Seguir o fio"), e o clique ali
    continua sendo da chave (`_plug_under`; o `test_flow` confere).
420. #cabos #pixel #mesa-comutadora "O cotovelo não aparece quando eu puxo o plug para fora do slot, para isso, deixe a
    parte plástica do mesmo tamanho da parte metálica e o cotovelo (parte flexível) afunilando até se encontrar com o
    fio"; "o cotovelo deveria afunilar mais na ponta". O plug em pé: corpo de plástico de 24 px (o da ponta), e a capa
    flexível, com frisos, afunilando de 10 a 6 px até o fio (o comprimento total não mudou, `PLUG_LEN`). Encaixado, a
    capa afunila da largura do tubo até a do fio por toda a parte lisa (`ELBOW_W.y` 2,5; antes 3,5 nos últimos 6 px).
421. #cabos #pixel #mesa-comutadora "O tamanho do cotovelo do plug em pé não condiz com ele encaixado". A capa do plug
    em pé passou a ser a mesma do cotovelo: 24 px, 8 de largura, frisos nos mesmos lugares, afunilando até o fio
    (`PLUG_ART` 12 × 72, `PLUG_H` 72, `PLUG_LEN` 48). Guardado, afunda mais no buraco (`PLUG_SINK` 24, a capa some
    nele e a parte à mostra fica como antes); a mão pega no meio do corpo (`PLUG_BASE` 36).
422. #cabos #pixel #mesa-comutadora "Teria como fazer uma dobradura do cotovelo de forma mais suave? Veja que na
    imagem real tem uma suavização na dobradura do cotovelo, não faz 90 graus" (com duas fotos). A curva virou um arco
    (Bézier da tomada, saindo para a câmera, até `ELBOW_BEND` 11 px da capa), varrido com discos a cada meio px, e os
    frisos seguem o eixo pela curva. Antes: o pescoço reto até uma bola, e a capa saindo dela num "L" com quina.
423. #cabos #pixel #mesa-comutadora "O grau que o cotovelo está fazendo aqui está errado, o fio nem está puxando o
    suficiente para ele ficar dessa forma; seria interessante fazer o cotovelo girar e acompanhar o balançado do fio;
    também deixar o fio mais rígido, como se tivesse sendo puxado de volta para o slot". A capa virou parte da física
    do fio: gira na curva do plug (`Cord.pivot`), o pé dela é a ponta da corda e pesa (`BOOT_WEIGHT`), o contrapeso conta
    da curva e puxa para o buraco (`HINGE_SLACK`), e o fio encaixado pesa menos (`TAUT_WEIGHT`): esticado, quase reto, e
    a capa entre a vertical e o buraco, na linha dele, balançando com ele. Saiu o `Cord.stub` (o fio saía da capa
    parada) e a regra que inclinava a capa da entrada para livrar a chave de escuta (agora ela a tapa quando pende
    reta; o clique é da chave).
424. #cabos #mesa-comutadora "O fio está fazendo pouca força puxando para o slot, preciso de mais, da forma como está
    agora parece que está em gravidade zero". O fio encaixado voltou ao peso inteiro; o contrapeso recolhe 6% a mais
    que o vão (`HINGE_PULL`), aos poucos (`HINGE_TAKE`), e o fio tem 24 iterações das regras (`Cord.HINGE_ITER`): tenso,
    quase reto, e a capa mais para o lado do buraco. Recolhendo de uma vez, o fio chicoteava e se enroscava por cima
    dos plugs.
425. #mesa-comutadora #painel #pixel #calculografo "Vamos fazer 1, 2 e 3" (das sugestões de objetos que ficaram para trás
    dos plugs novos): a tecla de escuta montada pixel a pixel (`_key_cap`): o tampo, menor que a base, acima dela, com
    as laterais à mostra pela paralaxe dos olhos (`KEY_DEPTH`) e a sombra, presa rente e acesa como antes; a cúpula da
    lâmpada abaulada (clara do lado da luz) e o alto dela andando com os olhos; o carimbo da mesinha do calculógrafo
    redesenhado como o da ferramenta (cabo em cogumelo com as faixas de luz de cilindro e o medalhão, haste, corpo com a
    plaqueta escrita numa linha, rodas de latão com os tipos sujos de tinta): parecia um robozinho. Os itens 4, 5 e 6
    (tampas da prateleira, frente do console, caixinha dos bilhetes) depois da aprovação.
426. #mesa-comutadora #cabos #console #calculografo "Aprovado" (o 1–3), seguindo para o 4, 5 e 6: os tampos dos lugares
    vagos na prateleira encaixados rente, no tom dela (a fresta em volta e a beira dela por dentro, a de cima e a da
    esquerda na sombra), sem a sombra de peça saltada (pareciam recortes soltos em cima dela); forma, inclinação e lugar
    não mudaram. A tela da conversa na miniatura do console esperando como a de verdade: o aviso em traço apagado e o
    cursor depois (só o cursor, parecia tela desligada sem função). A caixinha dos bilhetes com a parede de trás por
    dentro à mostra (toda escura, parecia um buraco), a etiqueta impressa ("BILHETES", `T.Key.TOLL_BOX`, na fonte
    gravada) e os bilhetes guardados em degraus de tom, cada um com a marca do carimbo na beira.
427. #burocracias #fitas Revisão da B4 (os pontos que sugeri, com os ajustes do usuário): só as ligações do roteiro vêm
    marcadas (nenhum mecanismo de marcar as comuns); a fita calibrada (5 pontos por palavra-chave, no máximo 20 por
    fita, `max_tape_points`: com 10 por palavra, uma fita valia mais que uma advertência grave); a ligação marcada sem a
    fita dela entregue (não gravada, descartada ou esquecida) não pesa na hora, porque as autoridades não sabem o que
    ela tinha: duas noites depois (`found_after`) descobrem, e vem a advertência de descuido ("Ligação pedida pelas
    autoridades não foi gravada", média; `Supervisor.fault_later` ganhou `nights`, e o relatório diz "há 2 noites"),
    com o marcador `authorities_questioning_pending`; a fita deixada no gravador no fim da noite conta como não entregue
    (`Tapes.left_behind`); a gravação de conversa não marcada entregue vai para o registro como "gravação não pedida".
    Sinal na mesa para a ligação marcada: recusado ("se o jogador não estiver olhando para os textos, é um problema
    dele"). O lugar do gravador: pediu mais sugestões.
428. #burocracias #fitas #console #ferramentas #saiu O lugar do gravador (sugestão A): o gravador e a gaveta das fitas
    embutidos na frente do console, nos lugares da plaqueta do fabricante e dos dois botões (`metadata/console` 0 e 1
    na cena, `Background.console_bay`/`console_used`, `Switchboard.console`); a prateleira embaixo do interurbano fica
    tampada (`shelf_used`). Os lados trocaram: o lugar dos botões tem ~60 px, pouco para o gravador. Clicar em
    qualquer dos dois abre o gravador de perto (`Tools.TAPES`, `tape_deck.gd`), como as outras ferramentas; o de
    console só mostra. Fitas por cliques (a de cima da gaveta voa para o gravador; Entregar e Descartar levam para a
    caixa das autoridades ou para o cesto); a caixa só na vista de perto, e no console uma luzinha por fita entregue.
    A fita em pé atrás de uma porta de vidro saiu: "pela lógica, a fita não é tão pequena assim em comparação a um plug
    de áudio". Agora ela fica deitada, na escala dos plugs (100×11 no console, 150×18 de perto), num gravador de fenda,
    com a etiqueta na lombada; a gaveta e a caixa também com as fitas deitadas, empilhadas. A janelinha das bobinas em
    cima da fenda também saiu: "não faz sentido, pois a fita está encaixada no slot". O VU ficou no lugar dela, e o
    gravador encolheu (110×40 no console, 240 de largura de perto).
429. #burocracias #fitas #mesa-comutadora #disposicao #saiu "Não gostei" do gravador no console: o painel das tomadas foi
    para a esquerda (saiu a folga de 12 px antes dele) e a mesa comutadora alargou 72 px (441), com a prateleira e o
    console acompanhando; à direita das tomadas, depois de um friso, uma coluna nova (`SIDE_W`, `side_rect`) com o
    gravador vertical no alto e o compartimento de fitas embaixo, tudo na cena (pedido: "Tudo na cena"; "Fenda
    vertical"; "Em pé, lado a lado"). Saíram a vista de perto do gravador (`Tools.TAPES`, `tape_deck.gd`), os lugares
    da frente do console (a plaqueta e os botões voltaram), a lixeira e a caixa das autoridades, a porta do gravador e
    o som dela. A fita em pé de lado, 12×100 (a lombada com o nome e a hora escritos de lado, de baixo para cima), na
    fenda; o compartimento com três em pé, o clique tira a da direita. Descartar: "ela cai da tela e pronto". Entregar:
    "ela é mostrada ao lado do caderno de registro, se tiver mais de uma fita, só empilhar" — voa encolhendo até a
    pilha, deitada de comprido para o fundo entre a mesinha do calculógrafo e o bloco de fichas (de frente, com 10 cm,
    encostava no bloco e no jornal).
430. #burocracias #fitas #mesa-comutadora Melhorias na coluna do gravador (as que sugeri, escolhidas pelo usuário): até
    chegar o primeiro equipamento dela, a coluna fica sob uma tampa lisa, como as chapas dos bancos (sem letra nem
    aviso); a fita entregue tomba de lado no meio do voo (girada 90°, exata) e chega à mesa com a cara da da pilha
    (escura, a etiqueta nos 60% da esquerda; antes, um bloco creme encolhendo). Conferido: as teclas Entregar e
    Descartar cabem em espanhol (os mesmos textos) e em inglês (mais curtos). A sugestão de ajustar a miniatura do
    console estava errada: ela é o painel do operador, não a mesa comutadora.
431. #burocracias #fitas "Coloque uma tampinha no slot das fitas, como aquelas de toca fitas de carros": sem fita, a fenda
    do gravador fica fechada por uma tampinha de plástico escuro presa pela beira da esquerda; a fita entrando a empurra
    para dentro (de frente, ela estreita até sumir), e, quando a fita sai, ela volta de mola e bate (`_flap`, o som
    `tape_door`, que tinha saído com a porta antiga, de volta). Captura: `--tapes=empty`.
432. #burocracias #fitas #mesa-comutadora "As letras dos botões não estão centralizadas; troque por um botão REC
    vermelho. Para entregar, o jogador deixa a fita na mesa até o fim do turno; para descartar, clica na fita e aparece
    o botão Descartar. O compartimento está chapado, parecem adesivos: mais profundidade." A gravação deixou de ser
    automática: a tecla REC vermelha trava (`Tapes.rec`) e, presa e com a escuta na conversa, em qualquer ordem, grava;
    sem fita, desce e volta com o aviso. Clicada a fita na fenda, ela vai para a pilha da mesa (a REC volta); as da
    mesa são entregues no fim do turno (`Tapes.hand_over`, os pontos só então); a esquecida no gravador continua não
    entregue. Clicada a pilha (que se ergue, "Fitas gravadas"), abre de perto acima dela com as fitas deitadas e o
    Descartar de cada uma (`tape_pile.gd`). O compartimento virou uma caixa funda de plástico branco, como o gravador: o
    fundo escurecendo para cima, a parede da esquerda por dentro, o alto e o lado de cada fita com a sombra no fundo e
    a beira da frente tapando o pé delas, de onde a fita tirada sobe antes de voar.
433. #burocracias #fitas "As fitas parecem estar sobrepondo o compartimento": o alto das fitas subia até a borda de
    cima. Baixei as fitas (`FLOOR` 106): o alto delas fica dentro do vão, com o fundo escuro à vista por cima, e o pé
    fica escondido atrás da beira da frente e da borda de baixo, redesenhadas por cima delas.
434. #burocracias #fitas "Sugira melhorias" e, das sugeridas, "Pode fazer todos, menos o som da queda. Também seria
    interessante poder selecionar qualquer fita no compartimento (hoje só a primeira sai); se há fita no gravador, ela
    está vazia e o jogador clica nela, ela volta para o compartimento, pois está limpa." A REC solta sozinha quando a
    conversa gravada acaba (`rule_tapes.call_ended`, com o estalo dela) e é apertada também pela tecla R (`rec_tape`);
    sob o mouse, a fita na fenda mostra numa etiqueta o que o clique faz ("Tirar a fita" / "Devolver a fita"); a tirada
    sobe só dentro do vão e vem para a frente por cima da beira antes de voar (não passa mais pela borda de cima); a
    pilha inteira responde ao mouse; aberta, é um papel com botões de tinta e a descartada cai para fora da tela, sem
    som. Cada fita do compartimento tem o lugar dela: a apontada sobe 1 px e é a que sai. A virgem clicada no gravador
    volta voando ao primeiro lugar vazio e afunda nele (`Tapes.put_back`), sem ir para a mesa.
435. #fios #mesa-comutadora "Quando o cabo está por cima de uma tomada e eu coloco outro plug na tomada tampada, ele
    fica torto assim e fazendo barulho. Vamos sempre evitar isso." O plug novo crescia embaixo do fio esticado, que não
    tinha como contorná-lo: ficava preso dentro dele, entortado e batendo a cada quadro. Agora o plug levanta o fio que
    tapava a tomada: o fio corre por cima dele, sem esbarrar, e é desenhado depois dele (`Switchboard._draped`, até um
    dos dois sair). Teste: `test_flow`, seção 18.
436. #burocracias #fitas "Você acha que a B4 está boa?" e, das melhorias apontadas, "Faça 1 e 3": (1) os lugares das
    fitas passaram para o modelo (`Tapes.slots`; `insert(i)`, `put_back` devolve a virgem ao lugar dela) e cada fita
    virou uma `Tape` (`scripts/bureaucracy/tape.gd`, com o destino num enum, `Tape.Fate`), no lugar de dicionários com
    chaves em texto; o compartimento só desenha o que o modelo diz (antes guardava os lugares e os reconciliava a cada
    quadro); com uma fita voltando, ele espera ela chegar. (3) A etiqueta da fita no gravador saiu de cima da borda do
    painel e da placa: fica à esquerda da coluna, na frente do painel, fora da moldura.
437. #burocracias #fitas "Pensando como um game designer, a jogabilidade da B4 está boa?" e, das mudanças sugeridas:
    (1) a fita pedida só conta como entregue com alguma palavra-chave (`Tapes.delivered`); a vazia, de um segundo de
    escuta, leva a mesma advertência adiada de não entregar. (2) Nada no relatório da noite: o bilhete do supervisor da
    noite seguinte diz o que houve com as fitas (usadas, entregues, as pedidas que não chegaram, se repôs;
    `Tapes.summary`/`note`, salvo em `Bureaucracy.state`); o que acontece por isso fica com o roteiro, pelos marcadores
    `b4_nao_entregou_<ligação>` e `b4_descartou_<ligação>`. (3) As virgens passam de uma noite para outra: o
    compartimento só é reposto quando esvazia ou depois de três noites seguidas incompleto (`Tapes.restock`,
    `restock_after`). (4) Descartar a fita pedida é não colaborar de propósito: a mesma advertência adiada e o marcador;
    descartar gravação não pedida não tem efeito. (5) Gravando conversa não pedida, a faixa da etiqueta sai riscada
    (`Cassette.standing`/`lying`, `wrong`). (6) Com a fita cheia (o máximo de pontos), a lâmpada da REC pisca devagar.
438. #plugs #mesa-comutadora "Tira print de todos os cabos conectados em posições diferentes, de forma que eu veja o
    paralaxe", "Há melhorias a serem feitas nos plugs nas tomadas?" e "Faça 1 e 3": (1) o plug encaixado ganhou o
    colar de metal rente ao painel (`COLLAR`, nos tons da ponta do plug em pé): fica na tomada enquanto o pescoço sai
    para longe dos olhos, e o que ele deixa à mostra mostra a profundidade (no tom mais claro, contornava a cabeça como
    um halo). (3) Os frisos viraram traços retos de lado a lado do tubo (`_ribs`); antes eram os pixels a menos de 1 px
    de uma distância do eixo, e a capa deitada ficava com frisos em degraus desiguais, falhados ou grossos.
439. #plugs #mesa-comutadora "O paralaxe tá pequeno ainda, não dá pra ver nada do plug. Os plugs têm uma linha
    colorida que sequer dá pra ver encaixados nas tomadas". `PLUG_DEPTH` de 0,014 para 0,03: longe dos olhos, o pescoço
    do plug sai bem para o lado (até ~18 px), perto deles quase nada. A capa do plug encaixado ganhou a faixa na cor do
    cabo, logo abaixo dos frisos (`ELBOW_BAND`), como no plug em pé. Os fios esbarram no pescoço em discos da largura
    do tubo ao longo dele (`_elbow_pegs`; um disco só, crescendo com o deslocamento, passava muito do tubo).
440. #plugs #mesa-comutadora "Reveja os cabos conectados e veja se está correto", e depois: "Os plugs estão com zero
    profundidade, o cotovelo piorou depois das mudanças; a linha dos plugs NÃO fica no cotovelo, mas sim na parte dura
    do plug; precisa de mais detalhes para que a profundidade funcione de verdade" e "O cotovelo do cabo verde está
    muito grosso: quanto mais para a esquerda, mais grosso; a circunferência do cabo é uniforme". O plug encaixado
    virou um tubo em 3D montado pelo eixo (`_elbow`): a ponta de metal na boca da tomada (`ELBOW_SLEEVE`), o corpo
    duro saindo para a câmera com a faixa na cor do cabo em anel (`ELBOW_BODY`, `ELBOW_BAND`), a curva de borracha
    num quarto de círculo (`ELBOW_ARC`) e a capa com os frisos no alto (`ELBOW_RIBS` do fim da curva ao alto da capa;
    no meio da curva viravam pedaços de arco soltos); a luz pela normal 3D e o mais à frente cobre o resto (buffer de
    profundidade). Em volta de cada ponto do eixo, um círculo do raio do tubo: projetar cada ponto da superfície pelo
    deslocamento esticava o tubo para o lado (√(1+s²)). Saíram o colar e os frisos em traço reto (438) e a faixa na
    capa (439). Os fios só esbarram na curva e na capa, à frente do painel: o pescoço deitado os segurava como uma
    prateleira e o fio serpenteava pelas cabeças dos plugs do interurbano.
441. #plugs #mesa-comutadora "A linha do plug encaixado não está grossa demais em comparação ao plug no slot?" Estava:
    3 px de profundidade, e a projeção dava até 1,5 px na tela por px de profundidade (~4,5 px à esquerda). A faixa
    voltou a 2 px, como no plug em pé, e o corpo duro ficou mais fundo (`ELBOW_BODY` 15): o mesmo deslocamento da
    curva nunca passa de 1 px na tela por px de profundidade (o que aponta para a câmera só encurta).
442. #ritmo #testes #treinamento "Pode fazer o 1 e o 3" (do relatório da simulação, `docs/relatorio-simulacao-2026-10-27.md`):
    o bilhete da abertura quebrava na noite 0 (`Tapes.note` com o resumo vazio: o -1 do padrão batia com `n - 1`) e
    o `Main._ready` parava antes de plugar o FONE do treinamento. E a dificuldade parava de subir na noite 6 (nível 5
    até a 15): escolhido "picos nas noites finais" (contraria em parte o "pico raro" do item 3, só no fim do jogo).
    Níveis 6–9 (noites 7–15) com tantas ligações quanto o 5 (`Pace.mean_gap`), só que mais juntas (picos de 12% a 30%,
    `Pace.PEAK_GAP`) e a mesa mais calma entre eles. Medido no robô `--human` (6 sementes por nível): 2+ juntas de 10%
    (nível 5) a 23–24% (8–9), 3+ de 0 a 7–8%, no máximo 1 perdida por noite (uma semente do 7 perdeu 3). O cabo ainda
    não falta (5 cabos com todos os setores): fazer pesar pede menos cabos ou conversas mais longas, a decidir.
443. #ritmo #emergencia #despacho #cabos "Ao invés de diminuir os cabos, podemos alongar as conversas" e, na emergência,
    "pausar o tempo enquanto imprime, enquanto tritura e enquanto transmite; se ainda assim estiver ruim, aumentar o
    tempo da barra". A duração da conversa transferida saiu do `Main.TALK_LEN` para o nível (`Pace.talk_len`): 34–68
    min do 1 ao 5, subindo de 45–85 (6) a 95–165 (9). Mas o cabo ainda não falta: só transferências e interurbanos
    usam cabo (~6 por noite), e o robô `--human` chegou a 2 de 5 cabos em uso (o `test_shift` passou a mostrar
    `cabos N/M`). A barra para com uma máquina do despacho trabalhando (`CardMachines.working`); não bastou (a de 35 s
    piorava sempre e, na noite 3, perdia), e o estágio inicial de todas subiu 10 s (45/50/55). Medido: em 20 turnos do
    robô humano nas noites 1–12, nenhuma emergência piorou; ele envia aos ~38 s.
444. #ritmo #conteudo "Vamos ajustar a proporção de ligações pedindo informações": muitas e poucas transferências, uma
    noite com 4 seguidas. Medido antes no robô `--human` (18 turnos): 2,9 por noite, até 7 de 10 na noite 1, 5
    seguidas. Três fontes: `TRANSFER_SHARE` (65% → 85%); o pedido de informação também ocupava um número da noite
    (sem chamar ninguém), e na noite 1 (10 números) as transferências se esgotavam e viravam informação (agora não
    ocupa); e a ligação a mais da mesa vazia (`Main._fill_quiet`) era sempre informação (agora `Schedule.filler`: uma
    transferência de molde para um número livre; só sem número livre, informação). Depois: 1,5 por noite, no máximo 2
    seguidas. O `test_shift` mostra `info=N, M seguidas`.
445. #ritmo #testes #processo #despacho "Se todos os fios estiverem conectados deve aparecer um botão [Todas as linhas
    ocupadas]... 'Vou aguardar' ou 'Ligarei outra hora'": anotado no relatório (Jogabilidade 5), ainda não feito. "Pode
    aumentar o movimento um pouco, precisamos acompanhar se um jogador novato não vai sofrer": o nível 1 de ritmo
    passou de 45–60 para 40–52 min entre ligações (noite 1: 8–9 ligações); o robô humano descuidado e o apressado
    seguem com Ótimo nas 6 sementes. E os outros itens do relatório: o cenário sorteia no gerador dele
    (`Background._rng`, e o tremor da trituradora no `CardMachines._shake_rng`), fora do global do `--seed`; saiu o
    código morto (`Sfx.later`, `dial`, `ringback`, o som `pulse`, `_pr`, `_sheets_of`); a `revisar-mudancas` roda
    `tests/run.sh content training flow` antes do commit; o CI roda em todo push.
446. #cabos #transferencia #conversa #processo "Pode fazer [Todas as linhas ocupadas]": sem cabo de conexão livre
    (`Main.no_cords`), a transferência ganha o botão (`CHOICE_ALL_BUSY`; aparece e some com os cabos a cada quadro,
    `Main._busy_choices`, porque o cabo solto volta à base sem avisar). O operador diz "Neste momento todas as linhas
    estão ocupadas. Deseja aguardar?" e quem liga decide (`Conversation._all_busy`, `busy_wait_chance` 0,6): espera
    (40 s a mais de silêncio, `BUSY_PATIENCE`, e o dobro em espera, `Supervisor.BUSY_HOLD`) ou "Ligarei outra hora"
    (desliga sem advertência, `OBS_ALL_BUSY` no caderno, e liga de novo, `Retry.BUSY` com `retry_busy`). "Qual o
    problema de ficha em cima do mapa? Depois de imprimir não há mais ação no mapa": o item saiu do relatório. "A
    branch principal é a develop": `CLAUDE.md` corrigido; apagadas as 14 branches locais já mescladas nela.
447. #consequencias #debug #codigo #desempenho #burocracias #testes "Vamos criar um fator de rigorosidade que
    aumentará ao longo dos dias, daí resolve o problema dos primeiros dias serem tão rigorosos com os erros (vamos
    precisar analisar bem o crescimento desse fator)": as advertências pesam na eficiência pelo rigor da noite
    (`ShiftReport.RIGOR`, `rigor(n)`): 0,6 na noite 1, 1 na 9, 1,3 na 15, em linha reta. Escolhida entre cinco curvas
    simuladas sobre 90 turnos do robô (relatório da simulação, Balanceamento 5): o desastrado fica em Regular até a 11
    e cai para Insuficiente da 12 em diante; a emergência perdida segue Insuficiente em qualquer noite. Do mesmo
    pedido: burocracias ficam no F1 até o roteiro ficar pronto; o rascunho do mapa fica ("não faz sentido tirar isso
    para algumas noites"); o cabo, "vamos acompanhar"; vazamentos ao recomeçar corrigidos (a espera de desistir do
    `Main.ring` virou temporizador ligado a `_give_up`, e o Main solta as opções das ligações vivas ao sair); o
    cronômetro do F1 com duas emergências segue o `Fleet.target_of`; desempenho medido, nada a corrigir.
448. #recompensas #mesa-comutadora #consequencias "Vamos criar algumas recompensas diferentes que vão sendo
    destravadas. Como por exemplo 'Noites primorosas' quando o jogador consegue completar 3 noites perfeitas. [...]
    broches com desenhos diferentes que ficariam em algum lugar da mesa, ao passar o mouse nelas, mostraria o título
    de cada recompensa, ao clicar mostraria um quadrado com a descrição": oito broches (`scripts/model/badges.gd`,
    tabela no README), escolhidos pelo usuário entre os sugeridos. O lugar, a pedido: "na parte de cima da
    prateleira da mesa comutadora já que não há mais nada ali", numa almofada de feltro vinho deitada na inclinação
    da prateleira entre o tampo dos equipamentos e o fim dela (`scripts/ui/badges.gd`, nó `%Badges` filho do
    `Board`), cada broche no seu lugar (o que falta deixa o feltro à mostra), etiqueta de fita crepe sob o mouse e
    papel (`TapedNote`) no clique. "Sempre que reiniciar o jogo [...] ficará atrelado aos dados de progresso": no
    `Progress` (`badges`, `tally`), somem com ele. Por isso o Veterano é a noite 10, não o fim da 15 (o save é
    apagado logo depois dela). Os bancos vazios do setor não atendido ficam como estão ("não vi problema").
449. #recompensas #mesa-comutadora "Conserte a angulação do 'pano' vermelho, está diferente da angulação da
    prateleira da mesa": a almofada dos broches seguia a inclinação dos pares de plugs (`_lean`, −0,86 px por linha),
    bem mais que o fim da prateleira ali (−0,3). Agora fica paralela à lateral da mesa, como a beira direita do tampo
    dos equipamentos (`badges.gd`, `_slant` pelo `_receding`), com os olhos (`_eye`) no estado comparado (desenhada
    no primeiro quadro, com outros olhos, pendia para o lado contrário e não se refazia), e centrada entre o tampo e
    o fim da prateleira à vista (16 px de cada lado).
450. #codigo "Podemos implementar versão no save então [...] versionar é a forma mais recomendada e segue as boas
    práticas de desenvolvimento de jogos?": sim, com o resto que costuma vir junto. O save leva a versão do formato
    (`Progress.VERSION`, a 1; os de antes, sem versão, são da 1; a conversão de versão em versão entra no
    `load_saved` quando o formato mudar), grava num temporário que só então toma o lugar do save (fechado no meio, o
    antigo fica inteiro) e o que não dá para ler (de versão mais nova ou corrompido) fica guardado ao lado
    (`Progress.aside`) com um aviso no papel da tela inicial, e o jogo começa do zero. A cópia antes de converter
    fica para a primeira conversão de verdade. Teste em `test_penalties` (9d).
451. #vista "Você consegue melhorar as formas e animações dos pedestres?" Quem passa na calçada de lá deixou os
    blocos de duas poses: as pernas de coxa e canela numa passada de 8 quadros por ciclo (`STRIDE`, `LEG`: contato,
    descida, passagem, subida), com o corpo descendo e subindo pela perna de apoio, os braços de braço e antebraço
    balançando ao contrário das pernas (`ARM`, `SHOULDER`), a perna e o braço de lá mais escuros, os sapatos para a
    frente, os ombros redondos (`_round_top`), o vestido abrindo para a barra, a cabeça um pouco à frente, a pasta
    balançando na mão e, na chuva, o guarda-chuva na mão de cá (antes ficava solto em cima). Quem desce ou sobe a rua
    do cruzamento vem de frente (pernas e braços abertos para os lados). O homem do mistério anda na mesma passada
    (`_gait`) e, parado embaixo do poste, segue de frente. Captura: `--stride`, `--walk_dir`, `--outfit`, `--man`.
    Depois, a pedido ("Da pra desenhar o que voce disse que ta com desenho antigo como modelo novo?"): as silhuetas
    (`_body`, `_figure`, agora em px) também: quem está no balcão do bar, quem atende os telefones do hotel e do bar,
    quem fuma na varanda, o passageiro do táxi com a mala, o dono do bar e o porteiro do hotel. Parados ficam de frente,
    com os braços na beira do casaco (por fora, a silhueta ficava larga) e o braço do fone, do copo ou do cigarro
    dobrado no cotovelo até a orelha; andando, na passada.
452. #vista #noites "Na terceira noite haverá um momento da noite em que um policial abordará um homem e começará a
    espanca-lo no meio da avenida, depois irá levantar ele e o arrastará para fora dos limites da visão da janela. A
    animação precisa ser fluida. O sangue deve respingar no chão e ficar lá pelo resto da noite. Os pedestres se
    afastarão e ficarão observando distante até que a cena acabe. A noite continua normal logo em seguida." Cena da
    rua por noite (`Night.street_scene`, `street_scene_at`; a 3 às 20h40, com gente ainda na calçada): o roteiro em
    `scripts/ui/beating.gd` (`Beating`: momentos-chave de cada um, com curvas de aceleração, interpolados a cada quadro;
    ~28 s). O homem vem pela calçada de lá, o policial desce a rua do cruzamento, aponta, agarra a gola e o empurra
    para o asfalto da boca do cruzamento (o meio da avenida fica embaixo do peitoril, fora da vista), bate com o
    cassetete e chuta (`HITS`, com pausas; o homem encolhe a cada pancada), guarda o cassetete, o levanta pela gola e
    o arrasta para a direita, embaixo do poste, até sair do vidro. Desenhados como esqueleto de coxa, canela, braço,
    antebraço, tronco e cabeça montado pixel a pixel (`_draw_rig`, `_rig_pixels`, `_stamp`), com a beira acesa pelo
    poste. Sangue a partir da terceira pancada (gotas em arco que caem e ficam, `drops`), a poça crescendo embaixo da
    cabeça (`pool`) e o rastro do arrasto; fica até o fim da noite. Sem carros nem gente nova da hora da cena até o
    fim; quem está na calçada para, se afasta até ~4,5 m e fica olhando (`_watch`; mais três chegam para assistir,
    `ONLOOKERS`) e depois segue. Captura `--beating=t` (ou `t0,passo,n`), botão "Policial batendo no pedestre" no F1. Sem som, por ora.
453. #vista #noites "No dia 7 vamos adicionar um carro da polícia parando em frente ao hotel, daí dois policiais irão
    descer e entrar no hotel, ficarão lá por um tempo e depois irão embora." `Night.street_scene` "police" (a 7 às
    21h30): a viatura é a próxima da mão de lá (`_police_next`) e para no hotel como o táxi (`_taxi_x`), mas fica
    `PATROL_WAIT` s (~77 s, ~58 min do relógio). Sedã preto de portas brancas, com a sirene vermelha girando no teto
    (`PATROL_SPIN`, o halo pulsando). Os dois policiais, desenhados como o da noite 3 (`_draw_rig`, agora com recorte
    pela porta), descem do lado da calçada, andam até a porta do hotel e somem nela; ~70 s depois saem, voltam, as
    portas batem (`slams`) e ela vai embora. Captura `--taxi=s --police`, botão "Viatura no hotel" no F1.
454. #debug "Pode adicionar o policial batendo no pedestre no debug?" O botão existia como "Cena da rua (noite 3)";
    virou "Policial batendo no pedestre (noite 3)".
455. #vista #pedestres #noites "As pernas dos pedestres estão um pouco para trás do corpo, parece que eles estão andando
    e caindo para frente; [...] estacionar o carro da polícia [...] ele já pode chegar na posição de estacionado [...]
    a giroflex não está legal, precisa ser mais detalhado, assim como o próprio carro." O quadril de perfil foi
    0,1 m à frente do tronco (`HIP_AHEAD`, que saiu no 457). A viatura vem junto do meio-fio (`PATROL_Z`, a faixa por carro em
    `_lane`) e para com o meio na porta do hotel (`_patrol_mid`), sem manobra. `_draw_patrol_car`: "POLÍCIA" na porta
    branca, holofote na coluna, antena atrás e a sirene com base cromada, cúpula de vidro vermelho e a lâmpada
    passando de um lado ao outro: clarão quando vira para nós, facho varrendo a rua, vermelho na fachada de costas.
    `--still=N` na captura para a sirene em outro ponto do giro.
456. #pedestres "Os pedestres que caminha da esquerda pra direita ainda estão com problema de pernas para frente."
    A perna de 2 px crescia sempre para a direita (`_limb` só centrava as de largura ímpar): quem ia para a direita
    ficava com as pernas 1 px adiante e quem ia para a esquerda, 1 px atrás. Centrada (`wide / 2`).
457. #pedestres "Está a mesma coisa, e pessoas caminhando da direita pra esquerda continua com as pernas para frente."
    Com a perna centrada (456), o quadril adiantado (`HIP_AHEAD`, do 455) passou a pôr as pernas na frente nos dois
    sentidos: saiu, e o quadril volta ao meio do tronco.
458. #vista #noites "Da primeira lista implemente 1 (dias 9 à 14), 3 (no caso, o homem de macacão pinta 3 dias
    depois), 6 (nesse caso, um carro passa jogando os panfletos), 8 e 10. Da segunda lista implemente 5, 8, 9 (no dia
    9, de hora em hora o homem aparece no terraço do Hotel e observa a rua [...]). Não precisa implementar tudo de uma
    vez. Crie um .md para implementar esses eventos por vez" e "Deixe claro no documento que precisa ter detalhes e
    boas animações". `PLANO_RUA.md`: o passo 0 (várias cenas por noite, `StreetEvent`) e as oito cenas, uma por vez,
    com a seção de qualidade (animação fluida, movimento orgânico, detalhe, som, marca que fica, conferência visual).
459. #vista #noites "Pode começar" (o `PLANO_RUA.md`). Passo 0: `StreetEvent` (`kind`, `at`, `every`) e
    `Night.street_events` no lugar de `street_scene`; o Main desdobra as repetições e chama `Background.schedule`.
    Cena H, o vigia da noite 9 (`LOOKOUT_*`, `_draw_lookout`): às 19h, 20h, 21h, 22h e 23h, em silhueta contra o céu,
    vem de trás até a platibanda do hotel, vira a cabeça de um lado ao outro, debruça-se com as mãos nela, ergue o
    binóculo (os cotovelos abertos) e varre a rua, e volta (26 s). Encostado nela: mais atrás, a platibanda o
    escondia quase inteiro. Os braços espelhados pela coluna do corpo (como a perna no 456).
460. #vista #noites "O boneco não está detalhado como eu pedi! Ele tá com os braços super finos, parece uma aranha do
    que um homem, tire o chapéu também". O vigia (`_draw_lookout`) deixou a silhueta de peças (`_body`, braços de 1 px)
    e é montado pixel a pixel, de frente, em colunas simétricas: a capa escura com a beira mais escura, as mangas de
    2 px e as mãos, a cabeça sem chapéu (cabelo em cima e, virada, na nuca, com o nariz para o lado), o binóculo no
    rosto; a beira de cima acesa pelo céu (`_draw_pixels`, separado do `_draw_rig`). Num degrau junto da platibanda,
    subindo aos poucos: aparece do peito para cima.
461. #vista #noites "Está sem braços, a cabeça não precisa ficar tão baixa". Caídas, as mangas ficavam por cima da
    capa e sumiam nela: saem por fora do tronco, mais claras, com os cotovelos um pouco abertos (um vão de céu até o
    corpo) e a costura da capa mais escura. A cabeça sobe uma fileira, sobre o pescoço na sombra do queixo.
462. #vista #noites "Pode fazer" (o toque de recolher do `PLANO_RUA.md`, noites 9 a 14 às 21h). A viatura da noite 7
    passa devagar pela mão de lá (`CURFEW_SEC`), a sirene girando e o holofote da coluna aceso, o facho correndo pela
    calçada e pelas fachadas de lá e acendendo a beira de quem pega (`_sweep_at`, `_sweeps`); o ronco grave toca
    quando ela passa no meio. Quem está na calçada nota quando ela chega perto (`CURFEW_SEE`), cada um no seu tempo,
    para de perfil olhando para ela, dá meia-volta se ia para o lado dela e sai apressado, em passos mais curtos e
    rápidos (`_hurry`, `_take_cover`, `steps`), para a rua do cruzamento ou para dentro do hotel, recortado pela porta
    (`in`). Ninguém mais passa depois (`crowd` zero desde a hora). Na noite 9 coincide com o vigia das 21h.
463. #vista #noites "O que melhoraria nessa luz do holofote?" e "Faça de 1 a 4". O holofote do toque de recolher:
    (1) a luz somada numa camada própria por baixo da frente da vista (`_spot_add`, ADD), clareando o tijolo e a
    calçada sem acinzentar, tapada pela viatura e por quem passa; (2) o círculo com o meio mais forte e a beira
    definida, mais alto que largo na fachada e dobrando para a calçada abaixo do pé dela (cada ponto segue o raio da
    lâmpada até o chão: uma elipse deitada); na boca da rua do cruzamento cai no chão dela, rua acima, e se parte na
    quina (`_draw_sweep_light`); (3) quem ele pega clareia de frente, no tom da roupa (`_beam_at`), e a sombra dele
    aparece na fachada, projetada da lâmpada, maior, cortada no pé da parede e no círculo (`_draw_beam_shadows`); (4) o
    policial procura aos trancos (vira rápido e chega devagar, para um instante) e acompanha um tempo o peito de quem
    pega (`_aim`, `CURFEW_PAUSE`, `CURFEW_TURN`, `CURFEW_FOLLOW`). A primeira versão do círculo, somada a 0,55 com a cor
    do farol, virou tinta bege chapada; e o círculo atravessando a quina virava um risco: partido nela.
464. #vista #noites "Existe outra forma de fazer essa projeção de luz? Algo que deixe mais parecido com o ambiente ao
    invés de um círculo opaco?" e "Troque para testar. Mas antes commit o código atual". O holofote deixou de somar uma
    cor: a camada `_spot_add` usa `spot_light.gdshader`, que lê o que já está desenhado embaixo e o multiplica pela
    força da luz (a forma que `_draw_sweep_light` desenha, na cor dos vértices): o tijolo, as juntas e a calçada
    continuam aparecendo, cada um na sua cor, e o ganho cai no que já é claro (a porta acesa quase não muda,
    `CURFEW_GAIN`). A forma virou a de um holofote antigo (`CURFEW_RINGS`: miolo, faixa, anel do refletor, beira e um
    halo largo), um pouco torta. O commit anterior (fe54ebe) guarda a versão somada, para voltar se esta ficar pior.
465. #vista #noites "A luz no cruzamento fica cortada" e "enquanto a polícia passa em frente aos dois prédios, poderia
    levantar mais a luz". O círculo do holofote deixou de pular os pedaços que atravessavam a quina (o buraco e a beira
    em degraus): cada triângulo é cortado na linha da quina (`_split`) e cai inteiro na parede ou no chão; no chão da
    rua do cruzamento o facho não para mais numa linha (o raio ia até 1,5× e se juntava ali) e vai sumindo com a
    distância; a mira no cruzamento fica baixa (até 0,4 m). Nos prédios ela sobe até as janelas de cima
    (`CURFEW_HIGH`, 4,5 m).
466. #vista #noites "Pode seguir, assim que finalizar parta para os próximos e no final mostre o que você conseguiu
    fazer e o que melhoraria" (as cenas F, G, C, B, E e D do `PLANO_RUA.md`, sem esperar aprovação de cada uma). Noite
    5: o carro de som, uma Kombi devagar com cartaz, brasão e duas cornetas no bagageiro, a voz saturada com eco na rua
    (`SPEAKER_*`, `_build_speaker`), quem está na calçada para e olha (`_listen`). Noite 8: a corrida (`Chase`): um
    rapaz atravessa correndo, olha para trás e entra no hotel; dois homens de terno e chapéu perdem o rastro na esquina
    e vão embora. Noite 6: panfletos jogados de uma Brasília, voando e planando até o chão (`Flyers`), recolhidos um a
    um por um policial um minuto depois. Noite 4: a pichação de madrugada (três letras inventadas e um risco, pixel a
    pixel, escorrendo; `Graffiti`); noite 7: um pintor cobre de cinza em faixas de rolo; ficam nas noites seguintes
    (`left_behind`). Noite 12: um sedã escuro para na esquina, dois homens esvaziam a banca, baixam as portas e a
    lacram (`Newsstand`); ela fica fechada até o fim do jogo. Noite 10: o caminhão do exército com a lona enrolada e os
    soldados de capacete e fuzil (`_draw_army_truck`), o diesel grave (`_build_army`) e o vidro da janela tremendo
    (`_tremor`). Captura `--scene=<tipo>` e as determinísticas `--chase`, `--flyers`, `--graffiti`, `--paint`,
    `--newsstand`; botões no F1.
467. #vista #saiu "Tire a bandeira do Brasil do carro, deixe um círculo como fosse um brasão apenas". O cartaz do carro
    de som ficou com um brasão redondo, sem bandeira.
468. #vista #saiu "As cornetas ficaram estranhas, estão tortas quase viradas para o jogador" e "Deixe elas menores
    também, como na primeira versão". As cornetas ficaram retas, deitadas ao longo do carro, e pequenas.
469. #vista #saiu "Vamos tirar a tremulação na hora do desfile", "o caminhão do desfile está com as duas rodas
    traseiras se sobrepondo. Os soldados estão cortados na carroceria, complete eles, dê mais detalhes ao caminhão",
    "algum problema esquisito na porta do hotel, é como se tivessem duas portas uma em cima da outra", "o carro que passa
    jogando os panfletos poderia jogar aos poucos ao longo da rua e aí ao invés de aparecer somente uma pessoa limpando,
    apareciam umas três varrendo e limpando", "quando o rapaz da tinta está chegando na pichação, a velocidade dele cai
    drasticamente até parar" e, na corrida, "os dois outros homens aparecem muito rápido e não fica crível que eles não
    viram o homem entrar no hotel... seguir pelo mesmo caminho da esquerda". O vidro não treme mais (saiu o `_tremor`).
    O caminhão: os eixos de trás afastados (1,25 m), a lona enrolada mais alta e os soldados no banco do meio, costas com
    costas, cinco de cada lado (`ARMY_SEATS`, `ARMY_GAP`): os de cá inteiros, de frente (capacete, rosto, farda, braços
    nos joelhos, pernas até as botas, o fuzil em pé até o peito); os de lá, só capacete e ombros, mais escuros; os postes
    da lona só nas pontas (no meio, com os fuzis, virava grade); e para-choque, venezianas do capô, retrovisor, estribo,
    tanque, caixa de ferramentas, para-barros e o número na porta. A porta do hotel: uma vitrine do térreo caía atrás
    dela e acendia junto; o trecho da porta não tem mais vitrine (`HOTEL_DOOR_GAP`). Os panfletos: a Brasília mais
    devagar joga quatro maços ao longo da rua (`THROWS`); três varredores de uniforme, vassoura e saco (um da direita, um
    descendo a rua do cruzamento, um da esquerda) varrem e pegam papel por papel da calçada à vista (`SWEEPERS`,
    `Flyers.figures`, som "sweep"). Quem anda até um lugar vai no passo e só freia no fim (`Beating.walk`, `WALK_EASE`),
    no pintor, no pichador, nos homens da banca e nos varredores. A corrida: os homens chegam depois de o rapaz sumir
    na porta (`MEN_START`) e seguem para a esquerda, passando pelo hotel sem saber.
470. #vista #saiu "No evento da banca fechada, os policiais não estão abrindo o porta-malas para colocar as coisas
    dentro, eles também estão ficando atrás do poste", "tire o som das pessoas varrendo as ruas" e "não entendi porque
    os soldados estão pulando dentro do caminhão, pode deixar eles parados". A banca: o primeiro a chegar ao carro abre
    a tampa (`Newsstand.lid`, desenhada no `_draw_car` com `"lid"`), os dois carregam pela traseira, na rua (`TRUNK`,
    passando pela `CORNER`), e o último bate a tampa (som de porta); quem está na cena e mais perto que os postes de lá
    é desenhado depois deles (antes, todos ficavam atrás). Saiu o som "sweep" e o balanço dos soldados (`ARMY_BOB`).
471. #vista "Quando os homens vão colocar os papeis no porta-malas, um deles está colocando os papeis fora do carro,
    fica por trás do porta-malas". O de lá (z 7) ficava atrás da tampa aberta e punha a pilha no vazio: os dois agora
    ficam na metade de cá da traseira, colados nela (`Newsstand.TRUNK`), e se debruçam sobre o porta-malas (`reach`).
    Não bastou ("o homem ainda está por trás do porta-malas e colocando os papeis fora"): o carro, desenhado depois de
    quem está atrás dele, cobria com o tampo e o fundo do porta-malas o tronco e a pilha. Agora os dois são desenhados
    de novo por cima do carro, da altura do tampo para cima e da tampa para a direita (`_draw_loaders`, `_trunk_clip`).
472. #vista "Faça o 14" (a cena proposta da mudança às pressas). Às 20h (antes do toque de recolher das 21h; a
    proposta dizia de madrugada, mas o turno acaba à meia-noite), uma Kombi com bagageiro para na boca da rua do
    cruzamento; o motorista desce do lado da rua, olha a varanda e os dois lados; na varanda do apartamento, alguém
    recolhe a roupa do varal peça por peça e entra, e a luz e a TV apagam; a família desce a rua do cruzamento (o pai
    com o colchão enrolado no ombro, a mãe com a mala, o filho do lado), o colchão sobe para o bagageiro e é amarrado,
    todos entram e a Kombi vai embora. O apartamento fica vazio nas noites seguintes (`Moving`, `left_behind`).
473. #vista "A kombi está parando no meio da avenida, poderia parar um pouco pra frente do hotel, daí as pessoas com um
    passo apressado atravessariam a rua e entraria na kombi, não precisaria do motorista descer e nem colocar as malas
    em cima. Basicamente isso seria uma fuga da família do local." e "A kombi precisa estar bem mais encostada no meio
    fio, como se estivesse estacionando". Saíram o motorista descendo e o colchão no bagageiro; a Kombi para na frente
    do hotel (mais para lá, a borda da vista cortava a frente dela) e encosta no meio-fio enquanto freia (`"park"`: o z
    vai da mão até 7,45 m e volta ao sair); a família desce às pressas (1,7 m/s), o pai olhando para trás, atravessa
    a boca da rua do cruzamento e some pela porta do lado da calçada (`Moving`).
474. #vista "Em alguns momentos, uma das pessoas desacelera o passo" (a família da noite 14). Cada trecho do caminho
    (descida, esquina, travessia, o olhar para trás do pai) era um `Beating.walk`, que freia no fim; agora o caminho
    inteiro vai em momentos "lin" no mesmo passo (1,7 m/s) até a porta da Kombi, onde eles entram andando (`Moving._keys`).
475. #vista #luz #noites "Vamos fazer um evento para o dia 15 às 21:00. Nesse horário, um sinalizador de luz vermelha
    será atirado para o céu e ele cairá lentamente." O sinalizador (`StreetEvent` "flare", `Flare`): sai de longe,
    atrás da cidade e à direita da igreja, sobe riscando em 2,6 s, acende vermelho no alto e desce no paraquedas
    (2,4 m/s, levado pelo vento e balançando) por 48 s, deixando a fumaça do caminho, acesa perto dele; numa camada
    entre o céu e a cidade (`_flare`), some atrás dos telhados. O clarão no céu é liso (`FLARE_GLOW`), a cidade puxa
    para o vermelho pelo `modulate` (`FLARE_TINT`, fora do `_day`: as luzes da cidade se dividem por ele, `_sunny`, e
    a `_back` não se redesenha a cada quadro; com ele dentro, as janelas acesas ficavam verdes) e a luz entra na sala
    pela janela (`FLARE_LIGHT`); o "pof" do tiro longe (som "flare"). Captura `--flare=t`, botão no F1.
476. #vista #luz "A luz do sinalizador quando acende está fraca, não parece uma luz". Era só um clarão vermelho
    escuro misturado ao céu e um ponto de 2×2 px: entrou no `Bloom` como os postes e o letreiro (`_flare_glow`, na
    camada `_over`, que se redesenha quando ele anda um pixel): o halo somado e o miolo estourando para o branco.
    `FLARE_HALO` 0,9 (a 1,4, um disco vermelho de beira marcada).
477. #vista #luz "Continua ruim. Sugira melhorias pra essa luz", e "Faça sua recomendação" (sem chegar mais perto:
    "a distância está correta"). O `Bloom` saiu do sinalizador (o halo em degraus era um disco, uma bola vermelha): o
    halo é uma imagem lisa montada pixel a pixel, somada numa camada logo acima dele na vista (`_flare_add`,
    `_flare_halo`: forte e quase branco colado no miolo, largo e fraco vermelho até zero na beira), a força no
    `modulate`; o miolo de 3×3 estourando no branco com a cruz rosada e raios em cruz crescendo com a força; acende
    com estouro (`BURST`) e cintila aos trancos, com falhas, mais apagando (`Flare.glow`, sorteado pelo tempo); e entra
    na sala como o sol do amanhecer, pela mesma camada (`_sun_layer`, de noite livre, `_flare_steep`): a janela
    vermelha no tampo e no peitoril com as sombras dos objetos, curtas (ele está alto, `FLARE_STEEP`) e crescendo
    enquanto ele desce, e a poeira no feixe, vermelha. Ficaram para depois a luz de um lado só nos telhados e na
    igreja, a fumaça mais grossa e as nuvens acesas por baixo.
478. #vista #luz #noites #pedestres "O que você melhoraria no evento do sinalizador?" e "Faça 1 à 5": (1) a fumaça
    deixou de ser um risco reto de 1 px (parecia uma antena): bolotas pixel a pixel (`Flare.puff`), a da subida fina e
    a da queda grossa, abrindo com o tempo, ondulando (`CURL`), entortada pelo vento mais forte no alto (`SHEAR`),
    partindo-se com a idade e à vista por 30 s (eram 14), rosada por baixo perto dele (`FLARE_SMOKE_LIT`). (2) A luz de
    um lado: a beira da igreja e do alto dos prédios de longe virada para ele, somada logo acima da `_back`
    (`_flare_rim`; as paredes da rua do cruzamento tapam o que fica atrás delas), o lado dele bem mais aceso; as
    cornijas das fachadas de lá e das paredes e a parede da esquerda da rua do cruzamento, de raspão, na camada do
    holofote (`_draw_flare_light`); anda com ele. (3) A janela vermelha na sala estava certa (conferida ampliada; na
    tela inteira eu não tinha visto). (4) Quem está na calçada para, cada um no seu tempo, vira para ele com a cabeça
    para trás e o primeiro aponta (`_skyward`, `FLARE_REACT`; captura `--sky`). (5) Na chuva e na névoa o halo é
    maior e mais forte (`FLARE_WET`), e as gotas e os pingos perto dele ficam vermelhos (`FLARE_BEADS`). Medido:
    +0,5 ms por quadro aceso. Ficou do `PLANO_RUA.md` a barriga vermelha das nuvens perto dele.
479. #vista #luz #noites #clima "Faça" (a barriga vermelha das nuvens perto do sinalizador, que faltava do
    `PLANO_RUA.md`) e "a rua central do cruzamento não fica iluminada, principalmente na chuva fica sem reflexo". As
    nuvens da noite limpa e as do céu da chuva ganham o lado virado para ele aceso de vermelho, mais quanto mais perto,
    somado com o halo, por baixo da cidade (`_cloud_shapes`, `_cloud_blob`, `_overcast_at`, `FLARE_CLOUD`). O chão da
    rua do cruzamento acende com ele (na camada do holofote), menos a faixa na sombra da parede do lado dele, e mais
    na chuva; e na chuva o reflexo dele no asfalto molhado: um risco vermelho quebrado e tremendo embaixo dele,
    descendo até a rua de cá, na camada `_flare_rim`, por baixo das paredes, das fachadas e dos carros, que o tapam
    (`FLARE_GROUND`). Medido aceso: +0,5 ms (limpo) a +1,2 ms (chuva) por quadro.
480. #vista #luz #noites "A rua horizontal está sem luz, a luz cortou na passagem do cruzamento" (com a captura). O
    chão aceso pelo sinalizador parava na calçada de lá. Pelo vão do cruzamento a luz segue pela calçada de lá e pela
    rua até a nossa calçada, andando para o lado de lá dele no caminho (a direção de onde ela vem), com as beiras
    macias (`_draw_flare_light`); o resto da rua fica na sombra dos prédios de lá (ele está atrás e acima deles).
481. #vista #pedestres #noites "Essas pessoas pararam na frente do prédio para ver a luz, porém como elas conseguiriam
    ver? [...] as pessoas só irão parar quando estiverem passando pelo cruzamento". O sinalizador está atrás e acima
    dos prédios de lá: da calçada na frente deles, a fachada o tapa. Só quem passa pela boca da rua do cruzamento
    (`CROSSING`) nota (`FLARE_REACT`, mais curto), e, se ainda estiver nela, para olhando um tempo (`FLARE_GAZE`, 5 a
    12 s, ou até ele apagar) e segue; o primeiro a parar aponta (`_skyward`).
482. #vista #luz #noites #pedestres #conteudo #desempenho #testes "Pode fazer tudo. No caso do 6, vai ser um sinal do
    roteiro, pode deixar o marcador" e "não implemente os latidos" (o latido logo depois do tiro saiu da lista). Quem
    vê o sinalizador é quem está na luz dele (`_flare_reach`, a mesma conta do chão aceso, `_flare_gap`): na boca do
    cruzamento e na rua do cruzamento, indo para o lado da igreja (quem desce, de costas para ele, não). Quem está na
    luz ganha a beira vermelha do lado dele (só do lado: no alto de cada peça virava contorno de arame) e os carros
    passando por ela, o brilho vermelho no capô, no teto e no porta-malas (`_sheen`, `FLARE_FIG`, `FLARE_CAR`). Ao
    acender, o `Background` avisa (`flare_lit`) e o Main liga o marcador `sinalizador_N` (README). A barriga das nuvens
    desenhada em lote (`_light_fans`): ~200 chamadas de desenho a menos, +0,55 ms aceso em todo clima (na chuva era
    +1,2). Teste em `test_flow` (16b): quem passa pela boca para nela, na frente do hotel ninguém vê, e o marcador.
483. #vista #noites #luz "Vamos adicionar outro evento de roteiro: no dia 13 um camburão irá parar em frente ao hotel, e
    um carro da polícia logo atrás, a polícia irá entrar no hotel e um tempo depois sairá escoltando 5 pessoas
    algemadas e entraram no camburão" e "se atente aos detalhes, como portas abrindo, pessoas saindo em fila, subindo
    no camburão, luz do giroflex iluminando local". A batida (`StreetEvent` "raid", `scripts/ui/raid.gd`), na noite 13
    às 22h, com a rua vazia pelo toque de recolher. O camburão (`CAR_KINDS` "camburao": a cabine preta e o cofre de
    chapa branca com "POLÍCIA", a janelinha gradeada, o degrau e a sirene, `_draw_camburao`) para com a frente logo
    depois da porta do hotel: mais para lá, de onde estamos, ele a tapava. A viatura para atrás dele. As portas das
    cabines do lado de cá abrem e fecham, batendo (`_draw_cab_door`; quem desce ou entra aparece só no vão); o
    motorista do camburão fica de guarda e os outros três entram no hotel; os andares acendem um a um e ficam
    (`Raid.floors`). A fila sai: um policial, os cinco presos algemados (as mãos nas costas, o brilho do aço, a cabeça
    baixa; roupas e peles diferentes, `Pal.RAID_*`), um policial no meio e outro no fim, pela rua na frente do
    camburão até a traseira; as portas do cofre abrem (a de cá dobra rente ao lado, a de lá fica para trás), cada preso
    sobe o degrau, abaixa a cabeça e some para lá da beira do cofre, com o da guarda ajudando; ele fecha as duas,
    batendo pesado, e cada um volta ao seu carro. As sirenes paradas (a dela e a da viatura, cada uma no seu giro)
    iluminam a rua: uma mancha vermelha no chão e na fachada onde o facho bate (`_draw_beacon_light`, pelo shader do
    holofote), quem o facho pega (`_beacon_at`), o asfalto molhado e a sala quando viram para nós. Isso vale também
    para a viatura da noite 7 e a do toque de recolher; o vermelho pintado na fachada do hotel (um leque por cima)
    saiu, no lugar dele a luz de verdade. Nenhum carro novo enquanto ela dura. Medido: +0,35 ms por quadro.
484. #vista #noites "Estacione o camburão mais para frente": a frente dele para 1,5 m mais para lá (`Raid.VAN_FRONT`
    -5,7), na frente do hotel; o capô, baixo, passa da porta, que fica à vista por cima dele, e quem vai da porta para
    a rua contorna a frente dele (`Raid.ROUND`). A viatura acompanha. Com a traseira à esquerda do meio, a face de trás
    do cofre aparece, estreita: aberta, mostra o vão escuro. As portas das cabines abrem até 50° (a 65°, a branca da
    viatura saltava para cá como uma tábua).
485. #vista #noites "Mais pra frente, quase chegando nos limites da janela. Também ajuste o nome 'Polícia' do camburão,
    está mais que o carro". A frente do camburão para quase na beira da janela (`Raid.VAN_FRONT` -7,2); a porta do
    hotel fica atrás da cabine (só o alto dela aparece), e por isso a fila e os policiais vão pela calçada, atrás
    dele, e descem para a rua no vão entre ele e a viatura (`Raid.DOWN`; contornar a frente ficaria fora da vista).
    O "POLÍCIA" do cofre foi para o meio da lateral, embaixo da janelinha (ao lado dela, passava da traseira).
486. #vista #noites "O camburão está sem a parte traseira da cabine", "no final um dos policiais ficou travado, a porta
    da viatura se abriu sozinha e o policial simplesmente sumiu e fechou a porta" e "os carros parecem deslizar ao
    estacionar [...] já deixe os veículos na posição que irão parar". A cabine do camburão ganhou a chapa de trás,
    depois do vidro, encostada no cofre (ele ficou 30 cm mais comprido, 5,3 m, para o cofre não encurtar). Quem desce e
    sobe na cabine faz o movimento inteiro (`Raid._out_of_cab`, `_into_cab`): vai até a beira solta da porta, puxa com
    a mão, recua enquanto ela gira, passa para o vão e senta, sumindo nele (sentado, do peitoril para cima; pondo o pé
    na rua, até o chão, `_raid_clip` "van"/"van_in"); descendo, sai do banco, fica de pé e empurra a porta. Os dois
    carros já vêm pela linha do meio-fio e só freiam (sem o `park`, que os encostava de lado no caminho).
487. #vista #noites "A viatura pode ficar com a luz nova": a viatura da noite 7 fica com a luz do giroflex da batida
    (`_draw_beacon_light`, a fachada, o chão, as pessoas e a sala), sem o leque antigo na fachada.
488. #vista "Esse porteiro está bem ruim", "no prédio de tijolos também tem pessoas dentro que estão feias": quem está
    lá dentro contra a luz (o recepcionista no telefone do hotel, o porteiro na porta de manhã, quem está no balcão e
    no telefone do bar, o dono na porta e quem passa atrás da janela acesa) deixou de ser silhueta preta de palito e
    usa o corpo de quem passa na rua (`_draw_backlit`: `_rig_pixels`, com roupa, pele, cabelo e chapéu, escurecido
    pela contraluz, `BACKLIT`; com a beira acesa, sumia no fundo claro). O recepcionista fala de frente, com o fone na
    orelha (`PHONE_FRONT`); um freguês bebe de lado (`HOLD_UP`); o dono fica de frente com a mão no batente; o porteiro
    de quepe e farda (`Pal.CLERK_COAT`). Quem passa atrás da janela fica meio metro acima do piso, para a cabeça e os
    ombros caírem no meio do vidro (a conta certa deixava só o alto da cabeça no peitoril).
489. #discador #mesa-comutadora #conteudo #roteiro "Vamos implementar uma nova funcionalidade que é a de realizar
    ligações" (a referência: o disco na ponta direita da bandeja de uma mesa Ericsson): um discador digital como o
    console, com os algarismos, Discar e Encerrar; ligando para um lugar, uma conversa curta que faz sentido para ele
    (a fala de atendimento, até duas perguntas e [Encerrar ligação]; respondida uma, só resta encerrar); por ora só o
    setor de Vila Serena (os 3xx, os 12 números com atendimento escrito, rascunho para o usuário revisar); ligações do
    roteiro preparadas (`DialCall`, em `Night.dial` ou `GameContent.dial`, no formato dos trotes; o marcador
    `ligou_<número>_<noite>` a cada atendida). Decisões do usuário: o discador fica onde estavam os broches, que foram
    para a esquerda; não precisa do FONE (o fone do operador é ligado direto na mesa); só o clique, e ele abre de
    perto como as outras ferramentas (`Tools.DIALER`). Plano em `PLANO_DISCADOR.md`. O teclado de discagem do item 2
    (para transferir) não volta: este só faz as ligações do operador.
490. #discador #mesa-comutadora "Diminua essa barra branca a esquerda das recompensas, ela não está servindo para nada
    nesse momento": o tampo do lugar dos equipamentos na prateleira ficou curto (`BAY_W`, 60 px de tampo, depois 44, para o teclado maior; a beira
    esquerda é a mesma, os tampos dos cabos não mudam); depois, a pedido ("não ajustou a posição do discador e das
    recompensas"), a almofada vem logo depois dele (`Switchboard.pad_x`); o discador fica no fim da prateleira, à
    direita ("o teclado tem que ficar na direita", `dialer_x`), no meio do vão entre a almofada e o fim dela ("De
    espaços": encostado no fim, parecia sair da mesa).
491. #mesa-comutadora #camera #saiu "A prateleira está com essa curva no final", "dá a entender que a mesa comutadora
    não tem lateral" (na perspectiva, a lateral do console é uma cunha que afina até a quina da frente). Testados e
    desfeitos: escurecer a lateral e marcar a quina com um fio; a ponta reta, a prateleira e o console alinhados com a
    beira do painel ("ficou horrível"); a bochecha em pé na ponta da prateleira, como as da mesa Ericsson. Ficou como
    era, a pedido ("vamos focar na implementação do discador").
492. #discador "O que você melhoraria" → "pode seguir com tudo": quem estava com o FONE fica em espera de verdade
    enquanto o operador liga (a linha em HOLD: quem espera demais desiste, `Supervisor.check_hold`; volta a falar quando
    a feita acaba); um cabo solto na tomada da linha chamada não a solta mais (`Dialing.seized`); as respostas do
    discador aceitam palavras-chave (`[tipo:texto]`), anotadas na lista como na escuta (`Eavesdrop.note`); horário de
    funcionamento (`DirectoryEntry.closes`: a pensão às 22h, a Célia da Rua do Sol às 23h, a oficina e o cinema às
    23h30, a rádio à meia-noite); rediscar (Discar com o visor vazio, ou com o último número nele); a tecla apertada
    afunda na miniatura da prateleira (`Dialer._sunk`), mesmo apertada no de perto; o estado no visor de perto em
    negrito. Revisar as falas e as que a cidade lembra (`requires` nos atendimentos) ficam com o usuário.

493. #mesa-comutadora #discador "No canto da mesa comutadora tem triângulo escuro que parece uma sombra de algo
    dobrado" e "crescer mais um pouco a altura do teclado numérico" (com a linha vermelha no rodapé do painel). O
    triângulo era a sombra de contato do painel na prateleira, que abria 2 px para a direita e passava da ponta dela,
    caindo na lateral do móvel: agora para na ponta da prateleira (`_draw_switchboard`, `lip`). O discador ficou mais
    fundo (`Dialer.DEPTH` 29, a frente no mesmo lugar, `FRONT`, `_back`): a beira de trás encosta no rodapé do painel;
    as teclas, o visor e a lâmpada acompanham.
494. #mesa-comutadora #discador #luz "Faça 1 e 2" (das melhorias do discador) e "o 3 não faz sentido pq a ideia é
    que esse discador é embutido na mesa comutadora" (o fio até o painel saiu). (2) A sombra do discador na prateleira
    ganhou o lado direito, 2 px (a de fora mais fraca), como a dos broches, além da linha embaixo da frente. (1) Os tons
    pela luz da sala (`Pal.cabinet(_room_lit)`, como as tampas) foram testados e desfeitos: saíam 2 degraus mais
    escuros que a prateleira em volta, que já recebe a luz da sala pelo shader, como ele. Depois, "Desça aí um
    pouquinho o discador": 2 px (`FRONT` 13), a beira de trás já não encosta no rodapé.
495. #mesa-comutadora #discador "Com relação ao visual, mudaria alguma coisa?" → "Faça os 3": a lâmpada de linha,
    um aro de 5 × 5 deitado linha a linha na inclinação (parecia um "§"), ficou redonda (`PixelArt.disc`, sem deitar),
    embaixo de "LINHA" gravado em creme (`PixelArt.tiny`, `Pal.BOARD_INK`), os dois embaixo do visor, na altura da
    terceira e da última fileira de teclas (`LABEL_AT`, `LAMP_AT`, `_at`); cada tecla ganhou a sombra de 1 px na placa,
    embaixo (a apertada, rente, não). Depois, "Não gostei do texto linha": o "LINHA" saiu; a lâmpada ficou no lugar.
496. #discador #mesa-comutadora "Ao clicar no discador, abrir um pop up em cima dele mostrando a versão expandida porém
    menor" ou manter a ferramenta à direita → "vamos testar como fica o pop up" (o argumento: com a ferramenta à
    direita, a lista não fica aberta enquanto se disca). Em teste: o de perto (`DialView`) saiu das ferramentas
    (`Tools.DIALER` saiu) e virou um pop-up filho do discador da prateleira, logo acima dele, por cima do painel, sem
    tapar as chaves de escuta; compacto, como a miniatura: o visor e a lâmpada à esquerda (o estado embaixo dos
    algarismos), o teclado à direita, nas teclas do console sem etiqueta (`KeyCapStyle.tag`; as letras dos algarismos
    saíram; Discar e Encerrar só com o fone, `EndKey` para não mexer no Desligar). Abre e fecha pelo clique na
    miniatura e fecha com Esc e no fim do turno.
497. #cabos #mesa-comutadora #saiu "Melhorar a animação do plug entrando na tomada. Queria algo fluido, satisfatório e
    visualmente bonito". Antes: em 0,08 s o plug em pé girava e encolhia até o cotovelo, esticado pela transformação
    do desenho (contra a regra dos pixels), com 1 px de afundada. Primeira versão: o cotovelo aparecia 6 px para fora
    e entrava em 0,07 s, com um brilho em estrela na boca da tomada; "não mudou muita coisa" (curto demais para se
    ver) e o brilho saiu ("não faz sentido": lia como faísca). Depois, a pedido ("uma animação do plug virando para
    entrar na tomada", "uma batida mais marcada", a sombra): o plug vira da mão para a tomada em 0,13 s, o mesmo tubo
    3D do encaixado (`_elbow` com `turn`): a cabeça vai de em pé, deitada no painel, para de frente, a ponta de metal
    (`PIN`) entrando na tomada, a capa e o fio pendurados, do tamanho da mão para o do encaixado (`TURN_LEN`,
    `TURN_W`); para 8 px à frente do painel e entra acelerando em 0,06 s (`_turning`, `OUT_PX`, `IN_SEC`), a sombra
    indo de longe, como na mão, até colar; bate no fundo, afunda 2 px (com 3, o buraco da tomada aparecia ao lado do
    pescoço), segura e repica para fora e para dentro até parar em 0,4 s, a sombra colando e descolando junto
    (`_push`); na batida (`_impact`), o estalo com o tique do metal (`plug_in`) e os plugs encaixados ao lado pulam
    (`NEIGHBOR`, `_knocked`); o fio segue o pé da capa enquanto ele vira. Captura quadro a quadro:
    `shot --plugin=4,20`. Depois, "diminua essa sensação de mola ao encaixar": o repique saiu; afundado, ele volta ao
    lugar freando em 0,15 s (`SETTLE_SEC`).
498. #cabos #mesa-comutadora "Vamos consertar esse comportamento dos fios. Não vamos permitir que eles se enrosquem
    dessa forma, pois está causando bugs visuais com o fio se mexendo loucamente ou enganchando no plug de baixo" (o
    fio da entrada 10 preso por baixo do plug da saída 20): um plug encaixado só apoia o fio por cima. Encostado abaixo
    do meio dele (`Cord.HOOK`, `Cord.hook`), o fio esticado está enganchado: escorrega pela frente do plug e passa a
    correr por cima dele, desenhado depois, como o fio que tapava a tomada (`_draped`). Preso, ele tremia sem dormir
    (16 px em 2 s); agora endireita e dorme. Teste no `test_flow`, depois da seção 18.
499. #interface #mesa-comutadora "Vamos implementar o menu inicial do jogo?" Sugeri um cartão de ponto num relógio de
    ponto na parede; o usuário preferiu a ideia dele: à direita, o canto esquerdo da mesa comutadora de perto, com mais
    detalhe, as primeiras tomadas e o FONE encaixado na entrada 1; à esquerda, o menu (Carregar jogo, só com jogo
    salvo; Novo jogo; Configurações; Sair), embaixo, pequeno, Créditos e, menor ainda, a versão. Feito em
    `scenes/title_screen.tscn` (`title_screen.gd`; o painel em `title_board.gd`, as peças da mesa em 3× refeitas pixel
    a pixel, não ampliadas): cada opção com uma lâmpada que acende âmbar sob o mouse (variação `TitleButton`), a versão
    na fonte gravada do painel (`PixelArt.tiny`), Novo jogo com jogo salvo pergunta num papel antes de apagar, os
    créditos no mesmo papel, Configurações no papel da pausa. O `GameView` põe a tela inicial na primeira vez e o jogo
    depois dela (`GameView.playing`): os recomeços (`Main.restart`) não voltam ao menu.
    Correção do usuário (com uma foto): o cotovelo do plug é uma mola de borracha, e entre os anéis se vê o fio. Fiz a
    capa inteira em anéis; corrigido de novo ("o cotovelo é justamente a dobradura, não tem tantos vincos e a linha
    verde do plug não fica aí"), o FONE do menu passou a ser montado como o plug encaixado do jogo (`_elbow`), um tubo
    em 3D pelo eixo: a ponta de metal, o corpo duro saindo da tomada com a faixa verde junto do painel, o cotovelo
    numa mola de cinco anéis (nas frestas, o fio e o avesso escuro dos anéis) e a capa lisa descendo até o fio.
    Depois, "mais uns 4 vincos para baixo", como na foto: a mola segue quatro anéis capa abaixo (`COILS_DOWN`).
    Depois, com uma imagem melhor do plug encaixado: a cabeça lisa é curta (`PLUG_BODY`), a dobra inteira é mola, com
    sulcos finos e escuros (sem o fio à mostra), e a mola acaba num colarinho liso e reto (`COLLAR`) de onde sai o fio
    grosso (`CORD_R`); saiu a capa comprida afunilando. Depois, "o cabo grosso e o cotovelo não ficaram legais ainda":
    das melhorias que sugeri, fiz três. O plug passou a ser montado em anéis de pontos na superfície (antes, esferas pelo
    eixo, que tapavam qualquer sulco): o raio da mola ondula (`_coil_r`, `COIL_DEPTH`) e a normal acompanha, então cada
    anel tem luz e sombra próprias e a beira sai recortada. O plug é visto mais de lado (`TILT`), com a cabeça à mostra
    e os anéis abrindo em leque na dobra. O fio virou um tubo também (`_fone_cord`): tom redondo pela luz, trançado
    fino em V que some na sombra, sombra do colarinho no começo e queda em curva; mais fino (`CORD_R` 7) e na mesma
    cor (a pedido). Ficou de fora o colarinho mais largo com a beirinha clara.
    Depois, "a ponta do cotovelo pode ir afunilando": o colarinho afunila da largura da mola até pouco mais que o fio
    (`TIP_R`, `COLLAR` 14), com a luz seguindo a inclinação. Depois, "esse cotovelo e cabo estão grossos demais, isso
    não segue o que mostra na gameplay": as medidas voltaram às do jogo em 3×. O tubo ficou mais fino que o aro da
    tomada (`PLUG_R` 10), a ponta afunila comprida (`COLLAR` 28, `TIP_R` 6), o fio tem uns 3 px do jogo (`CORD_R` 4,5)
    e a ponta de metal tem o raio do furo (`SLEEVE_R`).
    Depois, "o fio ficou fino demais agora": `CORD_R` 5,5 (entre os dois), e a boca da ponta acompanha (`TIP_R` 7).
    Depois, a perspectiva ("se a mesa comutadora está no lado esquerdo, a perspectiva do cabo não deveria ser essa"):
    no menu o painel fica à direita da tela e quem olha está na frente dela, à esquerda dele; o plug é visto pelo lado
    esquerdo e o cotovelo pende para a direita (`TILT` positivo; na mesa do jogo o olho fica à direita, e ele pende
    para a esquerda). O fio cai quase reto, e a letra da chapa do banco foi para a direita dele.
    Depois, comparando com a mesa do jogo ("o tamanho das fontes no menu são bem menores; a placa do setor não
    atendido não tem os textos ali"): as legendas do painel de perto passaram à altura das letras miúdas da mesa em
    3× (`_text`, a fonte em dobro com relevo, `PixelArt.big`), com as lâmpadas da legenda e as abas maiores; as
    plaquinhas dos números, 78×38 (as da mesa em 3×); as chapas dos bancos A e B como na mesa, a letra grande no meio
    e o aviso centrado embaixo (`_draw_bank_plate`, `BANK_W`), com o painel 20 px mais alto para caber. O fio pende
    em curva (`CORD_SWING`) pelo vão entre "SAÍDAS" e o ponto e sai à esquerda do aviso, sem tapar letra.
    Depois, "a placa de setor não atendido ainda não condiz": a letra é a estampada da mesa (`PLATE_LETTERS`, em
    relevo, cada pixel em 3×3, `_tripled`) e o aviso, o estêncil nas letras miúdas da mesa (`PixelArt.tiny` em 3×),
    em vez da fonte do jogo; a folga entre as chapas, a da mesa (`BANK_GAP` 13).
    Depois, "deixe o cabo reto e a luz da entrada piscando, assim como acontece na noite 0": o fio cai reto da boca do
    plug (saiu a curva `CORD_SWING`; ele passa na frente do "D" de "SAÍDAS" e do começo do aviso da chapa) e a lâmpada
    da entrada 1 pulsa como uma linha chamando (`fone_on`, o mesmo toque de `Switchboard._lamp`), sem campainha.
500. #interface #som "Implemente 2, 3, 4, 5, 6, 7 e 8" (das melhorias que sugeri para o menu; ficou de fora ligar
    cada opção a uma linha do painel). Começar o jogo: o tec da chave, a lâmpada do FONE apagando, a tela escurecendo
    e clareando já no jogo (`TitleScreen._play`, `%Fade` numa CanvasLayer). Vida na tela parada: o ambiente da sala
    (às vezes de chuva, `RAIN_CHANCE`) e, a cada 25–50 s, uma linha chamando por dois toques, a lâmpada pulsando como
    na mesa (`TitleBoard.ringing`, `_lit`, `LAMP_ON_SEC`/`LAMP_OFF_SEC`). O nome do jogo em letra grande acima do
    menu (`%Logo`, `PixelArt.big`). Carregar diz onde o jogo parou (`%Where`: "Noite 4 · Quinta-feira, ..."; lido do
    arquivo sem o `Progress.load_saved`, que mexeria no save ilegível). No pé do painel, a chapa do banco A com o
    aviso de setor não atendido (`_draw_bank_plate`). Teclado: a primeira opção já escolhida, as setas e o Enter
    andam pelo menu e o mouse escolhe do mesmo jeito (uma lâmpada acesa só). Saiu o "Recomeçar do treinamento" do
    bilhete do supervisor (o Novo jogo do menu faz o mesmo) e a pausa ganhou "Voltar ao menu" (`%ToMenu`).
501. #mesa-comutadora "Na gameplay, a luz para de piscar quando encaixa o cabo, mas deveria piscar até atender a
    ligação." A lâmpada de uma linha chamando ficava acesa fixa com o FONE na entrada; agora pisca até o Atender
    (`Switchboard._lamp` sem o `steady`; a linha só passa a TALK no `Main.answer`).
502. #vista #janela "Crie um novo evento para o dia 14. Por volta das 23h, uma pedra atingirá a janela e causará um
    trincado na parte esquerda." Cena "stone" da noite 14 às 23h (`StreetEvent`, `Stone`), com a rua já vazia do
    toque de recolher: quem atira não aparece; a pedra sobe da rua embaixo da janela crescendo (vindo na nossa
    direção) em 0,45 s, clara da luz da sala chegando no vidro, e bate na parte esquerda dele: a batida seca, o
    trincado correndo em estalinhos e o vidro vibrando (`glass_hit`), a janela chocalhando. O trincado (o miolo moído,
    nove riscos em zigue-zague com galhos e arcos entre eles, claros com a sombra 1 px abaixo, mais estreito que alto
    pelo vidro visto de lado) fica numa camada por cima da vista (`_crack`), redesenhada só quando muda, e segue na
    noite 15 (`LASTING`), também de dia. No F1 e no `shot --scene=stone`.
    Depois: "Aumente o tamanho do trincado; aumente o barulho da batida da pedra; quando a pedra bater, ela deve quicar e
    cair": o trincado ~1,5× maior (11 riscos, 4 arcos, o miolo maior, `ART`, `RAY_LEN`, `RINGS`), a batida mais forte
    (`glass_hit` a 0 dB, com mais grave; o chocalho também) e, depois da batida, a pedra quica um pouco para cima, se
    afasta (encolhe) e cai até sumir no pé do vidro em 0,7 s (`BOUNCE`, `FALL`, `DROP`, `Stone.END`), atrás do trincado.
