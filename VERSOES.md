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
