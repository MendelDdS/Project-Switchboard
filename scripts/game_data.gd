class_name GameData
extends RefCounted
## Conteúdo da demonstração: lista telefônica, roteiros das ligações e ruas do mapa.
## Para criar novas variações de ligação, basta acrescentar dicionários às listas T1, T2, EM e TR.

# Horário previsto (minutos após 22:00) das 4 ligações principais. O relógio anda 1 minuto por segundo real.
# A ligação desconhecida (linha 07) é sorteada depois das 02:00 (MYST_FROM/MYST_TO em main.gd).
const CALL_AT := [5, 38, 84, 170]

# Lista telefônica, já em ordem alfabética.
const DIR := [
	{"n": "Almeida, Dr. Augusto", "s": "Clínica São Lucas", "a": "Rua das Flores, 12", "num": "214"},
	{"n": "Almeida, Otávio", "s": "residência", "a": "Rua da Estação, 9", "num": "251"},
	{"n": "Armazém Ferreira", "s": "Joaquim Ferreira", "a": "Rua do Comércio, 30", "num": "288"},
	{"n": "Bar do Zé", "s": "", "a": "Rua da Estação, 140", "num": "327"},
	{"n": "Barbearia Navalha", "s": "", "a": "Rua do Comércio, 71", "num": "209"},
	{"n": "Bombeiros, Corpo de", "s": "use o despacho", "a": "Avenida Brasil, 210", "num": "193"},
	{"n": "Casa Paroquial", "s": "Pe. Anselmo", "a": "Praça da Matriz, 1", "num": "120"},
	{"n": "Cine Odeon", "s": "", "a": "Avenida Brasil, 95", "num": "344"},
	{"n": "Clínica São Lucas", "s": "recepção", "a": "Rua das Flores, 12", "num": "213"},
	{"n": "Correios e Telégrafos", "s": "", "a": "Praça da Matriz, 8", "num": "155"},
	{"n": "Costa, Marta", "s": "", "a": "Rua do Sol, 54", "num": "223"},
	{"n": "Delegacia de Polícia", "s": "use o despacho", "a": "Avenida Brasil, 120", "num": "190"},
	{"n": "Escola Estadual Rui Barbosa", "s": "", "a": "Rua do Sol, 10", "num": "280"},
	{"n": "Farmácia Central", "s": "fecha às 20h", "a": "Praça da Matriz, 3", "num": "118"},
	{"n": "Farmácia Santa Rita", "s": "plantão 24 horas", "a": "Avenida Brasil, 220", "num": "162"},
	{"n": "Ferreira, Joaquim", "s": "residência", "a": "Rua da Estação, 60", "num": "291"},
	{"n": "Funerária Paz Eterna", "s": "", "a": "Rua das Acácias, 250", "num": "399"},
	{"n": "Hospital Municipal", "s": "use o despacho", "a": "Rua das Flores, 150", "num": "192"},
	{"n": "Hotel Estrela", "s": "", "a": "Avenida Brasil, 30", "num": "305"},
	{"n": "Igreja Matriz", "s": "secretaria, horário comercial", "a": "Praça da Matriz, 1", "num": "124"},
	{"n": "Lima, Rosa", "s": "", "a": "Rua das Acácias, 77", "num": "296"},
	{"n": "Mercearia Silva", "s": "", "a": "Rua das Acácias, 105", "num": "262"},
	{"n": "Nogueira, Paulo", "s": "", "a": "Rua do Moinho, 18", "num": "312"},
	{"n": "Oficina do Tião", "s": "", "a": "Rua do Moinho, 44", "num": "318"},
	{"n": "Padaria Pão Dourado", "s": "", "a": "Rua do Comércio, 5", "num": "142"},
	{"n": "Pereira, Lúcia", "s": "", "a": "Rua das Flores, 90", "num": "336"},
	{"n": "Posto São Cristóvão", "s": "", "a": "Rua da Estação, 200", "num": "347"},
	{"n": "Prefeitura Municipal", "s": "", "a": "Praça da Matriz, 2", "num": "101"},
	{"n": "Rádio Serena AM", "s": "", "a": "Rua do Sol, 199", "num": "390"},
	{"n": "Ramos, Alberto", "s": "", "a": "Avenida Brasil, 180", "num": "352"},
	{"n": "Rocha, Célia", "s": "", "a": "Rua do Sol, 88", "num": "367"},
	{"n": "Rocha, Célia", "s": "", "a": "Avenida Brasil, 240", "num": "373"},
	{"n": "Serraria Moinho Velho", "s": "desativada", "a": "Rua do Moinho, 40", "num": "355"},
	{"n": "Souza, Benedito", "s": "", "a": "Rua do Sol, 230", "num": "271"},
	{"n": "Táxi, Ponto da Rodoviária", "s": "", "a": "Rua da Estação, 110", "num": "176"},
	{"n": "Teixeira, Ivo", "s": "", "a": "Rua das Flores, 33", "num": "379"},
	{"n": "Vieira, Sônia", "s": "", "a": "Rua do Comércio, 120", "num": "384"},
]

const SMALLTALK := [
	"Que chuva, hein? Não parou desde a tarde.",
	"Desculpe ligar tão tarde.",
	"A luz piscou aqui em casa agora há pouco. Aí também?",
	"O senhor passa a noite inteira aí sozinho?",
	"Essa linha está chiando, né?",
	"Minha mulher disse que não era pra incomodar a central a essa hora.",
	"O senhor não tem medo de ficar aí de noite?",
	"Meu marido já dormiu, mas eu não consigo pegar no sono.",
	"Ouvi dizer que o rio vai encher de novo.",
	"Faltou luz lá na Rua do Sol ontem, sabia?",
	"Essa central nunca dorme, né?",
	"Tem um barulho engraçado na linha hoje.",
	"Que frio, meu Deus.",
	"Tinha um carro parado na frente de casa, com o farol aceso. Já foi embora.",
]
const WAITING := ["Alô? Central?", "Ainda está aí?", "Alô? Conseguiu?", "Moço? A ligação caiu?", "Alô? Tô esperando...", "Demora muito?"]
const EM_WAITING := ["Alô?! Vocês vão mandar alguém?", "Por favor, rápido!", "Central?!"]
const HOLD_OK := ["Tá bom, eu espero.", "Obrigado, aguardo.", "Certo.", "Pode ser, eu fico na linha.", "Tá, mas rapidinho, tá?"]
const WRONG_DEST := ["Não, moço, não é aí.", "Hã? Não é com essa pessoa que eu quero falar.", "Esse não é quem eu pedi!", "Opa, acho que o senhor ligou errado."]

# Números sem ninguém à noite: tocam e ninguém atende.
const CLOSED := [101, 118, 124, 155, 209, 280, 355]

# Vozes: f = mulher, m = homem, k = criança, w = homem mais velho/sussurro.
# Ligação 1 — transferência para estabelecimento.
const T1 := [
	{"voice": "f", "caller": "Dona Lurdes", "open": ["Boa noite.", "Poderia me conectar com a farmácia? A de plantão. Meu neto está com febre."], "repeat": "A farmácia de plantão, moço. A que fica aberta de noite.", "target": "162", "dest": "Farmácia Santa Rita", "thanks": "Obrigada, meu filho. Deus te abençoe."},
	{"voice": "m", "caller": "Sr. Nelson", "open": ["Boa noite, central.", "Me liga com o Hotel Estrela, por favor? Meu irmão chegou hoje da capital e está hospedado lá."], "repeat": "O Hotel Estrela. Na avenida.", "target": "305", "dest": "Hotel Estrela", "thanks": "Muito obrigado."},
	{"voice": "m", "caller": "Rapaz", "open": ["Boa noite.", "Preciso de um táxi. Me conecta com o ponto da rodoviária?"], "repeat": "O ponto de táxi. Da rodoviária.", "target": "176", "dest": "Táxi, Ponto da Rodoviária", "thanks": "Valeu, central."},
	{"voice": "f", "caller": "Dona Zilda", "open": ["Boa noite, querido.", "Quero falar com a Padaria Pão Dourado. É pra encomendar o pão de amanhã cedo."], "repeat": "A Pão Dourado. A padaria.", "target": "142", "dest": "Padaria Pão Dourado", "thanks": "Obrigada, querido."},
	{"voice": "m", "caller": "Rapaz apaixonado", "open": ["Boa noite!", "Me liga com a Rádio Serena? Quero pedir uma música pra minha noiva."], "repeat": "A rádio. A Serena AM.", "target": "390", "dest": "Rádio Serena AM", "thanks": "Valeu! Ela vai ouvir, tenho certeza."},
	{"voice": "m", "caller": "Caminhoneiro", "open": ["Central, boa noite.", "Meu caminhão morreu perto do moinho. O Tião da oficina atende de noite, não atende?"], "repeat": "A oficina do Tião. Na Rua do Moinho.", "target": "318", "dest": "Oficina do Tião", "thanks": "Deus lhe pague."},
	{"voice": "m", "caller": "Motorista", "open": ["O posto da Rua da Estação ainda está aberto?", "Me conecta lá, por favor. Tô quase sem gasolina."], "repeat": "O Posto São Cristóvão.", "target": "347", "dest": "Posto São Cristóvão", "thanks": "Obrigado, central."},
	{"voice": "f", "caller": "Dona Cida", "open": ["Boa noite, meu bem.", "Quero saber que filme passa amanhã. Me passa pro cinema?"], "repeat": "O Cine Odeon, na avenida.", "target": "344", "dest": "Cine Odeon", "thanks": "Obrigada, meu bem."},
	{"voice": "w", "caller": "Senhor", "open": ["Boa noite...", "Preciso falar com a funerária. Meu pai faleceu agora há pouco."], "repeat": "A funerária. A Paz Eterna.", "target": "399", "dest": "Funerária Paz Eterna", "thanks": "Obrigado, moço."},
	{"voice": "f", "caller": "Dona Neide", "open": ["Me liga com o Bar do Zé.", "Meu marido disse que ia ficar só uma hora. Já faz três."], "repeat": "O Bar do Zé! Na Rua da Estação.", "target": "327", "dest": "Bar do Zé", "thanks": "Ah, ele vai ver só."},
]
# Ligação 2 — transferência para pessoa (com nomes parecidos na lista).
const T2 := [
	{"voice": "m", "caller": "Morador", "open": ["Preciso falar com o Dr. Almeida."], "repeat": "O Dr. Almeida. O médico, da clínica.", "target": "214", "dest": "Dr. Augusto Almeida", "thanks": "Obrigado."},
	{"voice": "f", "caller": "Sra. Marta", "open": ["Por favor, a Dona Célia Rocha.", "A da Rua do Sol. Não a outra."], "repeat": "Célia Rocha, a da Rua do Sol.", "target": "367", "dest": "Célia Rocha (Rua do Sol)", "thanks": "Obrigada."},
	{"voice": "w", "caller": "Sr. Ivo", "open": ["Me liga com o Joaquim Ferreira.", "O do armazém. Não o outro."], "repeat": "Joaquim Ferreira, do armazém.", "target": "288", "dest": "Armazém Ferreira", "thanks": "Tá certo, obrigado."},
	{"voice": "f", "caller": "Senhora", "open": ["Boa noite. Preciso falar com o Padre Anselmo.", "É sobre a missa de sétimo dia. Ele deve estar em casa."], "repeat": "O Padre Anselmo. Na casa dele, não na igreja.", "target": "120", "dest": "Casa Paroquial", "thanks": "Obrigada, meu filho."},
	{"voice": "m", "caller": "Vizinho", "open": ["Quero falar com o seu Almeida.", "O Otávio, da Rua da Estação. Não é o doutor."], "repeat": "Otávio Almeida. Rua da Estação.", "target": "251", "dest": "Otávio Almeida", "thanks": "Isso, obrigado."},
	{"voice": "f", "caller": "Sobrinha", "open": ["A Dona Célia Rocha, por favor.", "A que mora na avenida. Minha tia."], "repeat": "Célia Rocha. A da avenida.", "target": "373", "dest": "Célia Rocha (Av. Brasil)", "thanks": "Obrigada, moço."},
	{"voice": "m", "caller": "Freguês", "open": ["O seu Joaquim Ferreira, por favor.", "Na casa dele. O armazém já fechou a essa hora."], "repeat": "Na casa do Joaquim Ferreira. Não no armazém.", "target": "291", "dest": "Joaquim Ferreira (residência)", "thanks": "Tá certo."},
	{"voice": "f", "caller": "Dona Rute", "open": ["Me liga com a clínica, na recepção.", "Não é pra falar com o doutor, é pra marcar horário."], "repeat": "A recepção da Clínica São Lucas.", "target": "213", "dest": "Clínica São Lucas", "thanks": "Obrigada."},
]
# Ligações extras — tocam em horários aleatórios. Algumas dão o número direto;
# outras pedem um lugar fechado à noite ("alt" é a sugestão do operador quando ninguém atende).
const FILL := [
	{"voice": "m", "caller": "Homem", "open": ["Boa noite.", "Gostaria de falar com o número 327."], "repeat": "Três, dois, sete.", "target": "327", "dest": "Bar do Zé", "thanks": "Obrigado."},
	{"voice": "f", "caller": "Dona Tereza", "open": ["Me conecta com o 223, por favor?", "É da minha comadre."], "repeat": "Dois, dois, três. A Marta.", "target": "223", "dest": "Marta Costa", "thanks": "Obrigada, querido."},
	{"voice": "f", "caller": "Moça", "open": ["Oi. O número é 336.", "Da Lúcia Pereira."], "repeat": "Três, três, seis.", "target": "336", "dest": "Lúcia Pereira", "thanks": "Obrigada!"},
	{"voice": "w", "caller": "Seu Aníbal", "open": ["Boa noite. Me liga com a Farmácia Central, a da praça?", "Preciso de um remédio pra pressão."], "repeat": "A Farmácia Central. Na Praça da Matriz.", "target": "118", "dest": "Farmácia Central", "thanks": "Obrigado, meu filho.",
	 "alt": "162", "alt_dest": "Farmácia Santa Rita", "alt_ask": "Ninguém atende. Quer que eu tente a Santa Rita, de plantão?", "alt_yes": "Ah, é mesmo, a Central fecha cedo. Pode ser, obrigado."},
	{"voice": "f", "caller": "Dona Aurora", "open": ["Preciso falar com a igreja. A Matriz.", "É pra pedir uma bênção... minha filha viaja amanhã cedo."], "repeat": "A Igreja Matriz.", "target": "124", "dest": "Igreja Matriz", "thanks": "Deus lhe pague.",
	 "alt": "120", "alt_dest": "Casa Paroquial", "alt_ask": "A secretaria da igreja não atende. Quer que eu tente a casa do Padre Anselmo?", "alt_yes": "Isso, na casa do padre. Obrigada."},
	{"voice": "m", "caller": "Seu Benedito", "open": ["Central, é o Benedito.", "Me liga com o Ivo Teixeira? Ele ficou de me devolver a escada."], "repeat": "O Ivo. Ivo Teixeira, da Rua das Flores.", "target": "379", "dest": "Ivo Teixeira", "thanks": "Obrigado. Agora ele não escapa."},
]

# Pedidos de informação: o operador responde consultando a lista ou o relógio.
const INFO_VOICES := [["f", "Moradora"], ["m", "Morador"], ["w", "Senhor"], ["f", "Senhora"]]
const INFO_NUM := [["o Hotel Estrela", "305"], ["a Padaria Pão Dourado", "142"], ["o Cine Odeon", "344"], ["a Mercearia Silva", "262"],
	["o Posto São Cristóvão", "347"], ["a Rádio Serena", "390"], ["a Dona Rosa Lima", "296"], ["o seu Benedito Souza", "271"],
	["a Dona Sônia Vieira", "384"], ["o seu Ivo Teixeira", "379"], ["o Armazém Ferreira", "288"], ["o seu Paulo Nogueira", "312"]]
const ASK_NUM := ["Boa noite. Pode me dar o número %s?", "Central, o senhor sabe o número %s?", "Queria só o número %s, pra anotar aqui.", "Perdi a caderneta. Qual é o número %s?"]
const ASK_TIME := ["Moço, que horas são? O relógio lá de casa parou.", "Desculpe incomodar. O senhor tem as horas certas?", "Central, que horas são agora? Faltou luz e o relógio apagou."]
const INFO_OK := ["Anotado. Obrigada, boa noite.", "Isso, obrigado.", "Ah, tá certo. Obrigado.", "Muito obrigada. Boa noite."]
const INFO_BAD := ["Hum. Tem certeza? Bom... obrigado.", "Isso tudo? Tá bom, obrigado.", "Vou tentar esse então."]
# Ligação 3 — emergência. "street"/"block" é o trecho correto no mapa; "req" as unidades necessárias.
const EM := [
	{"voice": "f", "caller": "Mulher", "open": "Central! Houve um acidente na Rua das Acácias! Precisamos de ajuda!",
	 "q": [["Qual é o endereço exato?", "É perto do número 101! Na frente da mercearia!"], ["O que aconteceu?", "É um acidente de carro! Bateu no poste!"], ["Quantas pessoas estão feridas?", "Duas pessoas. Uma não está se mexendo!"]],
	 "street": "acacias", "block": 1, "addr": "Rua das Acácias, 101", "type": "Acidente de trânsito", "req": ["pol", "amb"], "after": "Estão vindo? Graças a Deus... obrigada."},
	{"voice": "m", "caller": "Homem", "open": "Central, tem fogo! Tem fogo no galpão da Rua do Moinho!",
	 "q": [["Qual é o número?", "Quarenta! O galpão da serraria velha!"], ["O que está queimando?", "O telhado inteiro! A fumaça está preta!"], ["Tem alguém lá dentro?", "Acho que não. Acho que não..."]],
	 "street": "moinho", "block": 0, "addr": "Rua do Moinho, 40", "type": "Incêndio", "req": ["bomb"], "after": "Tá bom. Tá bom. Eu vou tirar o carro daqui."},
	{"voice": "f", "caller": "Moça", "open": "Central, meu pai caiu no banheiro e não acorda!",
	 "q": [["Qual é o endereço?", "Rua do Sol, 230! A casa amarela!"], ["Ele está respirando?", "Está... mas não responde. Bateu a cabeça."], ["Tem mais alguém ferido?", "Não, só ele. Por favor, rápido!"]],
	 "street": "sol", "block": 2, "addr": "Rua do Sol, 230", "type": "Mal súbito", "req": ["amb"], "after": "Obrigada. Eu vou deixar a porta aberta."},
	{"voice": "w", "caller": "Homem (sussurrando)", "open": "Central... tem alguém tentando arrombar a casa do vizinho.",
	 "q": [["Qual é o endereço?", "Avenida Brasil, 150. A casa do lado da minha."], ["O que você está vendo?", "Forçando a janela dos fundos. O vizinho viajou."], ["Quantas pessoas?", "Dois homens. Não vi arma, não."]],
	 "street": "brasil", "block": 1, "addr": "Avenida Brasil, 150", "type": "Invasão / roubo", "req": ["pol"], "after": "Tá. Vou ficar quieto aqui dentro."},
	{"voice": "m", "caller": "Homem nervoso", "open": "Central! Tão brigando aqui no Bar do Zé! Um puxou uma faca!",
	 "q": [["Qual é o endereço?", "Rua da Estação, 140! O bar do Zé!"], ["Alguém está ferido?", "Um tá sangrando no braço! Rápido!"], ["Quantas pessoas estão brigando?", "Dois! Mas o bar tá cheio!"]],
	 "street": "estacao", "block": 1, "addr": "Rua da Estação, 140", "type": "Outro", "req": ["pol", "amb"], "after": "Tão vindo? Tá, eu seguro o pessoal aqui."},
	{"voice": "f", "caller": "Senhora", "open": "Central, caiu um fio do poste aqui na frente e está soltando faísca na chuva!",
	 "q": [["Qual é o endereço?", "Rua do Comércio, 71! Na frente da barbearia!"], ["Alguém encostou no fio?", "Não, não! Tá todo mundo longe."], ["Tem fogo?", "Tá começando a queimar a árvore!"]],
	 "street": "comercio", "block": 0, "addr": "Rua do Comércio, 71", "type": "Outro", "req": ["bomb"], "after": "Tá bom. Vou manter as crianças dentro de casa."},
]
# Ligação 4 — trote. Passos: ["c", fala] solicitante, ["o", [opções]] operador, ["p", segundos] pausa, ["end"].
const TR := [
	{"voice": "k", "caller": "Criança", "fake": "Rua Au-Au, 4", "steps": [
		["c", "Central, preciso de uma ambulância!"], ["o", ["Qual é o endereço?"]], ["p", 1.5], ["c", "Na casa do meu cachorro."],
		["o", ["Qual é o endereço?", "Isso é sério?"]], ["c", "Rua Au-Au, número 4."], ["p", 1.1], ["c", "É urgente. Ele comeu meu sanduíche."],
		["c", "(risadas abafadas)"], ["p", 0.6], ["c", "(ao fundo) Desliga, desliga!"], ["end"]]},
	{"voice": "k", "caller": "Garoto", "fake": "—", "steps": [
		["c", "Central! É urgente! Tem um incêndio!"], ["o", ["Onde é o incêndio?"]], ["p", 0.9], ["c", "No meu coração..."],
		["c", "...pela Marcinha da sétima série!"], ["c", "(risadas de várias crianças)"],
		["o", ["Esta é uma linha de serviço, garoto.", "Onde você está ligando?"]], ["c", "Fala pra ela, tá? Tchau!"], ["end"]]},
	{"voice": "k", "caller": "Menina", "fake": "—", "steps": [
		["c", "Alô? É da central telefônica?"], ["o", ["Sim. Em que posso ajudar?"]], ["c", "Vocês têm o telefone de todo mundo da cidade?"],
		["o", ["Temos a lista, sim."]], ["p", 0.8], ["c", "Então cuida bem deles, tá?"], ["c", "(risadas)"], ["c", "Minha mãe tá vindo! Tchau!"], ["end"]]},
	{"voice": "k", "caller": "Garoto", "fake": "—", "steps": [
		["c", "Alô, é da central? A sua geladeira está funcionando?"], ["o", ["Aqui é a central telefônica.", "Que brincadeira é essa?"]], ["p", 0.8],
		["c", "Então corre atrás dela!"], ["c", "(risadas)"], ["end"]]},
	{"voice": "k", "caller": "Menino", "fake": "—", "steps": [
		["c", "Central? Aqui quem fala é o presidente da república."], ["o", ["Pois não, senhor presidente.", "Esta é uma linha de serviço."]],
		["c", "Eu quero... eu quero pedir uma pizza!"], ["p", 0.6], ["c", "(ao fundo) Pede cachorro-quente!"], ["c", "(risadas abafadas)"], ["end"]]},
]

const STREETS := [
	{"id": "flores", "name": "Rua das Flores", "o": "h", "y": 90.0},
	{"id": "brasil", "name": "Avenida Brasil", "o": "h", "y": 225.0},
	{"id": "acacias", "name": "Rua das Acácias", "o": "h", "y": 360.0},
	{"id": "comercio", "name": "Rua do Comércio", "o": "v", "x": 110.0},
	{"id": "estacao", "name": "Rua da Estação", "o": "v", "x": 250.0},
	{"id": "sol", "name": "Rua do Sol", "o": "v", "x": 390.0},
	{"id": "moinho", "name": "Rua do Moinho", "o": "v", "x": 530.0},
]
const BLK := ["1–99", "100–199", "200–299"]
const OCC := ["Acidente de trânsito", "Incêndio", "Mal súbito", "Invasão / roubo", "Outro"]
const UNAME := {"pol": "Polícia", "bomb": "Bombeiros", "amb": "Ambulância"}
const LINE_LABEL := {"free": "livre", "ring": "chamando", "talk": "em linha", "hold": "em espera", "conn": "conectada", "done": "desligou", "ghost": "DESCONHECIDO"}
const DEST_LABEL := {"free": "livre", "ring": "tocando", "conn": "conectado", "done": "desligou"}

static func street(id: String) -> Dictionary:
	for s in STREETS:
		if s["id"] == id:
			return s
	return {}

static func find_number(num: String) -> Dictionary:
	for d in DIR:
		if d["num"] == num:
			return d
	return {}
