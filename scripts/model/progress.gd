class_name Progress
extends RefCounted
## O que fica salvo entre as noites (user://progress.cfg): a próxima noite e o ritmo dela, as noites seguidas abaixo
## do conceito mínimo (`ShiftReport.low_nights`; o `severe` dos saves antigos é ignorado), os marcadores do roteiro (escolhas que mudam as noites seguintes; veja StoryFlags) e o jornal da manhã
## seguinte (as manchetes da noite, `ShiftReport.news`, que ficam na mesa na próxima) e as advertências que só chegam
## nela (`ShiftReport.later`) e as palavras-chave ouvidas na escuta (`Clue`, em dicionário) e quantas vezes cada lugar
## denunciou a telefonista (`Eavesdrop.grudges`) e as noites de chuva (a mancha de umidade da sala, `Background.damp`)
## e o estado das burocracias (`Bureaucracy.state`: o registro de decisões, os recados...) e os broches ganhos e as
## contas deles (`Badges`).
##
## O arquivo leva a versão do formato (`VERSION`). Um save de versão mais nova que o jogo (de um build mais novo) ou
## que não abre (corrompido) não é lido nem perdido: fica guardado ao lado (`aside`) e o jogo começa do zero. A
## gravação vai para um arquivo temporário e só então toma o lugar do save: fechado no meio, o save antigo fica inteiro.

const PATH := "user://progress.cfg"
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
var aside := ""    ## o save que não deu para ler, guardado ao lado com este nome (vazio: nenhum)


static func load_saved(path := PATH) -> Progress:
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
	return p


func save(path := PATH) -> void:
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
	if f.save(path + ".tmp") == OK:
		DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))


## Volta para o começo (o treinamento).
static func clear() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
