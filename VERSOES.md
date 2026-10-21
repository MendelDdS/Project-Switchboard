# Versões das builds

Cada build nova (os executáveis em `build/`) ganha a versão seguinte e entra no fim deste arquivo, com a data, o
commit de onde saiu (marcado no git com a tag da versão), os sistemas e o que mudou desde a anterior.

**Formato: `0.MENOR.CORREÇÃO-fase`.**
- **MENOR** sobe quando a build traz coisa nova (mecânica, conteúdo, visual, som); a CORREÇÃO volta a 0.
- **CORREÇÃO** sobe quando ela só conserta problemas.
- **Fase**: `alpha` enquanto entram mecânicas e conteúdo (hoje: as noites 3 a 15 sem roteiro e o mistério sem
  fim); `beta` quando tudo estiver no jogo e só restar ajuste e correção; `rc` antes do lançamento; a 1.0 sai sem fase.
- O número fica em `application/config/version` e a fase em `application/config/stage` (`project.godot`); a
  exportação do macOS e a tela inicial e a pausa (`Settings.version_text`) leem dali.

## v0.4.0-alpha — 08/10/2026

Commit `4e515f9` · macOS e Windows

### Novidades
- Cachorros latindo bem longe, das 21h em diante.
- Ambiente melancólico e noir: a luminária esquenta no começo do turno, a pausa abafa o som, o prédio da esquina
  virou apartamentos com varanda e a TV piscando na janela, janelas acendem de madrugada, a chuva muda de força
  durante a noite, nuvens passam pela lua, o arbusto balança em rajadas, o vidro embaça nos cantos e as gotas do
  vidro fazem manchinhas de sombra na mesa.
- Unidade de despacho na mesa no lugar do mapa dobrado: o mapa de papel sob o vidro e as três máquinas na base
  (transmissor, impressora e triturador), com as luzes de emergência e de cartão.
- O despacho aberto é a unidade de perto: a base fixa com as máquinas lado a lado, o cartão menor e livre até a borda
  de baixo, e a ficha não abre nem fecha mais.
- As abas das ferramentas saíram: elas abrem pelos objetos da mesa ou pelas teclas 1 a 4.

### Correções
- O cartão impresso, solto logo abaixo da impressora, caía na trituradora.
- O relógio da mesa ficava por cima da pilha de listas.

## v0.5.0-alpha — 10/10/2026

Commit `8732b9a` · macOS, Windows e Linux

### Novidades
- Interurbanos: o banco INTERURBANO com seis cidades; quem liga pede a cidade e o número de lá, o operador liga no
  tronco, passa o número à telefonista da outra cidade e ela completa. Tronco errado conta como número errado.
- Noite de treinamento: a Cecília, telefonista veterana, ensina transferir, registrar, despachar, a espera e o fim do
  turno. A tela inicial tem Pular o treinamento.
- Até duas emergências ao mesmo tempo, cada uma com a sua barra; o rádio avisa da que está fora da linha, e as
  viaturas de reserva saem só com duas em andamento.
- Mais ligações: 13 transferências e 14 emergências escritas, 3 moldes de transferência, 5 de emergência, 10 trotes
  e 13 assuntos novos de conversa fiada.
- Vozes de telefone: a banda do telefone, a altura de cada pessoa, a entonação da frase, vogais nasais e consoantes.
- Mensagens do rádio com a hora em que chegaram ([21:04]).
- A prateleira em duas fileiras, mais funda, com os pares de cabos juntos, tampas nos buracos dos cabos que cada setor
  vai trazer e a plaqueta de latão do FONE.
- Carros variados: sete modelos de 1973, faróis acesos, táxis e lataria molhada na chuva; o pneu molhado refeito.
- A lua nasce atrás da igreja, na fase real de 1973.
- O jogo começa em 8 de outubro de 1973 e é sempre 1280×720, ampliado para a tela sem quebrar os pixels (Configurações:
  tela cheia ou janela, e ampliação só inteira).
- As ligações do roteiro tocam sozinhas, e a mesa parada demais ganha um pedido de informação.

### Correções
- O fio pendurado na beira da prateleira e o plug encaixado na paralaxe.

## v0.6.0-alpha — 21/10/2026

Sem build: só a tag no código (o commit dela) · os executáveis saem quando alguém pedir

### Novidades
- O supervisor dá um conceito a cada noite (Ótimo, Bom, Regular, Insuficiente), carimbado no relatório; duas noites
  seguidas abaixo de Regular demitem o operador.
- O relatório virou um memorando datilografado no papel timbrado, com o carimbo da gravidade em cada advertência e o
  parecer escrito à mão; as telas fora do turno são papéis.
- A última noite vai até as 6h e termina no amanhecer: o céu em degradê, o sol nascendo atrás da igreja e a luz do dia
  entrando na sala.
- Visual mais rico: cores por rampas de material, a luz da luminária, o clima noir e o brilho das lâmpadas do painel em
  shaders, e uma gradação de cor por clima.
- A vista mais viva: pedestres com roupas variadas, alguém fumando na varanda, gato, bicicletas, a rua do cruzamento
  com lojas, a igreja com vitrais e o letreiro de neon refletido no vidro.
- A mesa mostra uso: os objetos se erguem sob o mouse, a persiana abre e fecha, o lápis e o jornal mudam de lugar, as
  tomadas e os plugs foram redesenhados e os fios pendem menos.
- Vozes sintetizadas mais ricas.
- Despacho: os nomes das ruas à vista com o mapa afastado; a rua sob o mouse destacada, com a numeração de cada trecho;
  o nome dos lugares de referência sob o mouse; dois cliques para imprimir (o primeiro datilografa o endereço, e
  outra rua o troca sem triturar o cartão); e o anel de aproximar, como numa leitora de microfilme, com tiques e um
  mostrador de tambores.
- Botões de resposta curtos, com a frase inteira na conversa.

### Correções
- Os botões de resposta longos empurravam a tela para o lado.
- O clique num cruzamento do mapa marcava a rua errada.
- Aberto pelo objeto da mesa, o despacho só via o mouse depois de outro clique.
- Recomeçar pelo clique tirava a cena do meio do evento.
- O título e o texto das telas finais pulavam quando o botão aparecia.
- Letras encostando na moldura da placa do fabricante e nomes encostando no mapa.
