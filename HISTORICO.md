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
- `#emergencia` barra de agravamento e viaturas · `#consequencias` supervisor, advertências, relatório
- `#ritmo` agenda e quantidade de ligações · `#turno` horário, relógio do jogo, fim do turno · `#noites` noites,
  progresso, data · `#setores` · `#treinamento` · `#misterio` a ligação desconhecida e o homem na rua
- `#conteudo` roteiros e moldes · `#conversa` conversa fiada e o andamento das falas · `#voz` vozes · `#som`
- `#idiomas` · `#desempenho` · `#debug` · `#testes` · `#codigo` estrutura do código
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
