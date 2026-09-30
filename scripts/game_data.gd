class_name GameData
extends RefCounted
## Conteúdo da demonstração: lista telefônica, roteiros das ligações e ruas do mapa.
## Para criar novas variações de ligação, basta acrescentar dicionários às listas T1, T2, EM e TR.

# Horário previsto (minutos após 22:00) de cada ligação. O relógio anda 1 minuto por segundo real;
# se o operador ainda estiver ocupado, a ligação toca alguns minutos depois.
const CALL_AT := [5, 38, 84, 170, 253]

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
]
const WAITING := ["Alô? Central?", "Ainda está aí?", "Alô? Conseguiu?", "Moço? A ligação caiu?"]
const EM_WAITING := ["Alô?! Vocês vão mandar alguém?", "Por favor, rápido!", "Central?!"]

# Vozes: f = mulher, m = homem, k = criança, w = homem mais velho/sussurro.
# Ligação 1 — transferência para estabelecimento.
const T1 := [
	{"voice": "f", "caller": "Dona Lurdes", "open": ["Boa noite.", "Poderia me conectar com a farmácia? A de plantão. Meu neto está com febre."], "repeat": "A farmácia de plantão, moço. A que fica aberta de noite.", "target": "162", "dest": "Farmácia Santa Rita", "thanks": "Obrigada, meu filho. Deus te abençoe."},
	{"voice": "m", "caller": "Sr. Nelson", "open": ["Boa noite, central.", "Me liga com o Hotel Estrela, por favor? Meu irmão chegou hoje da capital e está hospedado lá."], "repeat": "O Hotel Estrela. Na avenida.", "target": "305", "dest": "Hotel Estrela", "thanks": "Muito obrigado."},
	{"voice": "m", "caller": "Rapaz", "open": ["Boa noite.", "Preciso de um táxi. Me conecta com o ponto da rodoviária?"], "repeat": "O ponto de táxi. Da rodoviária.", "target": "176", "dest": "Táxi, Ponto da Rodoviária", "thanks": "Valeu, central."},
	{"voice": "f", "caller": "Dona Zilda", "open": ["Boa noite, querido.", "Quero falar com a Padaria Pão Dourado. É pra encomendar o pão de amanhã cedo."], "repeat": "A Pão Dourado. A padaria.", "target": "142", "dest": "Padaria Pão Dourado", "thanks": "Obrigada, querido."},
]
# Ligação 2 — transferência para pessoa (com nomes parecidos na lista).
const T2 := [
	{"voice": "m", "caller": "Morador", "open": ["Preciso falar com o Dr. Almeida."], "repeat": "O Dr. Almeida. O médico, da clínica.", "target": "214", "dest": "Dr. Augusto Almeida", "thanks": "Obrigado."},
	{"voice": "f", "caller": "Sra. Marta", "open": ["Por favor, a Dona Célia Rocha.", "A da Rua do Sol. Não a outra."], "repeat": "Célia Rocha, a da Rua do Sol.", "target": "367", "dest": "Célia Rocha (Rua do Sol)", "thanks": "Obrigada."},
	{"voice": "w", "caller": "Sr. Ivo", "open": ["Me liga com o Joaquim Ferreira.", "O do armazém. Não o outro."], "repeat": "Joaquim Ferreira, do armazém.", "target": "288", "dest": "Armazém Ferreira", "thanks": "Tá certo, obrigado."},
	{"voice": "f", "caller": "Senhora", "open": ["Boa noite. Preciso falar com o Padre Anselmo.", "É sobre a missa de sétimo dia. Ele deve estar em casa."], "repeat": "O Padre Anselmo. Na casa dele, não na igreja.", "target": "120", "dest": "Casa Paroquial", "thanks": "Obrigada, meu filho."},
]
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
const LINE_LABEL := {"free": "livre", "busy": "ocupada", "ring": "chamando", "talk": "em linha", "hold": "em espera", "conn": "ocupada", "ghost": "DESCONHECIDO"}

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
