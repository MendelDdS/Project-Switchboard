class_name Progress
extends RefCounted
## O que fica salvo entre as noites (um arquivo por jogo salvo, `file`: o jogador tem `SLOTS`, escolhidos na tela
## inicial, `slot`): a próxima noite e o ritmo dela, as noites seguidas abaixo
## do conceito mínimo (`ShiftReport.low_nights`; o `severe` dos saves antigos é ignorado), os marcadores do roteiro (escolhas que mudam as noites seguintes; veja StoryFlags) e o jornal da manhã
## seguinte (as manchetes da noite, `ShiftReport.news`, que ficam na mesa na próxima) e as advertências que só chegam
## nela (`ShiftReport.later`) e as palavras-chave ouvidas na escuta (`Clue`, em dicionário) e quantas vezes cada lugar
## denunciou a telefonista (`Eavesdrop.grudges`) e as noites de chuva (a mancha de umidade da sala, `Background.damp`)
## e o estado das burocracias (`Bureaucracy.state`: o registro de decisões, os recados...) e os broches ganhos e as
## contas deles (`Badges`) e as páginas do diário de Maria das noites que passaram (`Diary.page`).
##
## O arquivo leva a versão do formato (`VERSION`). Um save de versão mais nova que o jogo (de um build mais novo) ou
## que não abre (corrompido) não é lido nem perdido: fica guardado ao lado (`aside`) e o jogo começa do zero. A
## gravação vai para um arquivo temporário e só então toma o lugar do save: fechado no meio, o save antigo fica inteiro.

const SLOTS := 3   ## quantos jogos salvos o jogador pode ter
static var slot := 1   ## o que está em uso (1 a `SLOTS`), escolhido na tela inicial
## A noite que está sendo rejogada (0: nenhuma), escolhida na tela inicial: o jogo lê a cópia do começo dela
## (`night_file`) e não grava nada; o jogo salvo continua de onde parou.
static var replay := 0
## A versão do formato do save. Mudou o tipo ou o sentido de um campo (não basta acrescentar um: a leitura dá o valor
## padrão ao que falta): suba e converta o save antigo no `load_saved`, de versão em versão, antes de ler. Os saves
## sem versão são da 1.
const VERSION := 2

var night := 0   ## 0 = o treinamento (jogo novo)
var pace := 1   ## nível de ritmo da próxima noite (GameContent.paces; veja Pace.next)
var low_nights := 0
var flags := PackedStringArray()
var news: Array = []
var later: Array = []
var clues: Array = []
var grudges := {}   ## número do lugar -> denúncias
var rains := 0   ## noites de chuva que já passaram
var bureaucracy := {}
var badges := {}   ## id do broche -> a noite em que veio (`Badges.award`)
var tally := {}    ## as contas dos broches de várias noites
var diary := {}    ## noite -> a página do diário de Maria como ficou no fim dela (`Diary.page`)
var aside := ""    ## o save que não deu para ler, guardado ao lado com este nome (vazio: nenhum)


## O arquivo do jogo salvo `n`; rejogando uma noite (`replay`), a cópia do começo dela.
static func file(n := slot) -> String:
	return night_file(replay, n) if replay > 0 else "user://progress_%d.cfg" % n


## A cópia do jogo salvo `n` como estava no começo da noite `night` (`keep`), para rejogá-la.
static func night_file(night: int, n := slot) -> String:
	return "user://progress_%d_noite_%d.cfg" % [n, night]


## As noites do jogo salvo `n` que dá para rejogar (as que têm cópia), em ordem.
static func nights(n := slot) -> Array[int]:
	var out: Array[int] = []
	for i in range(1, GameData.CONTENT.nights.size() + 1):
		if FileAccess.file_exists(night_file(i, n)):
			out.append(i)
	return out


## Grava o jogo e guarda a cópia do começo da noite em que ele está (do treinamento não: não se rejoga).
func keep() -> void:
	save()
	if night > 0:
		save(night_file(night))


static func load_saved(path := file()) -> Progress:
	var p := Progress.new()
	var f := ConfigFile.new()
	if not FileAccess.file_exists(path):
		return p
	var err := f.load(path)
	var v: int = f.get_value("progress", "version", 1) if err == OK else 0
	if err != OK or v > VERSION:
		p.aside = "%s.%s-%d.cfg" % [path.get_basename(), "v%d" % v if err == OK else "corrompido", Time.get_unix_time_from_system()]
		DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(p.aside))
		push_warning("save %s guardado em %s" % [path, p.aside])
	else:
		p.night = f.get_value("progress", "night", 0)
		p.pace = f.get_value("progress", "pace", Pace.expected(p.night))
		p.low_nights = f.get_value("progress", "low_nights", 0)
		p.flags = f.get_value("progress", "flags", PackedStringArray())
		p.news = f.get_value("progress", "news", [])
		p.later = f.get_value("progress", "later", [])
		p.clues = f.get_value("progress", "clues", [])
		p.grudges = f.get_value("progress", "grudges", {})
		p.rains = f.get_value("progress", "rains", 0)
		p.bureaucracy = f.get_value("progress", "bureaucracy", {})
		if v < 2:   # (até a 1, as regras só ligavam pelo debug: as ligadas e a chave geral salvas não valem mais)
			for k in ["enabled", "active", "params"]:
				p.bureaucracy.erase(k)
		p.badges = f.get_value("progress", "badges", {})
		p.tally = f.get_value("progress", "tally", {})
		p.diary = f.get_value("progress", "diary", {})
	return p


func save(path := file()) -> void:
	var f := ConfigFile.new()
	f.set_value("progress", "version", VERSION)
	f.set_value("progress", "night", night)
	f.set_value("progress", "pace", pace)
	f.set_value("progress", "low_nights", low_nights)
	f.set_value("progress", "flags", flags)
	f.set_value("progress", "news", news)
	f.set_value("progress", "later", later)
	f.set_value("progress", "clues", clues)
	f.set_value("progress", "grudges", grudges)
	f.set_value("progress", "rains", rains)
	f.set_value("progress", "bureaucracy", bureaucracy)
	f.set_value("progress", "badges", badges)
	f.set_value("progress", "tally", tally)
	f.set_value("progress", "diary", diary)
	if f.save(path + ".tmp") == OK:
		DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))


## Apaga o jogo salvo `n`: volta para o começo (o treinamento). `all` falso (o fim do jogo, a demissão): as noites
## já jogadas ficam para rejogar.
static func clear(n := slot, all := true) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file(n)))
	for i in nights(n) if all else []:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(night_file(i, n)))
