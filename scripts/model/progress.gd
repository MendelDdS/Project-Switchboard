class_name Progress
extends RefCounted
## O que fica salvo entre as noites (user://progress.cfg): a próxima noite e o ritmo dela, as noites seguidas abaixo
## do conceito mínimo (`ShiftReport.low_nights`; o `severe` dos saves antigos é ignorado), os marcadores do roteiro (escolhas que mudam as noites seguintes; veja StoryFlags) e o jornal da manhã
## seguinte (as manchetes da noite, `ShiftReport.news`, que ficam na mesa na próxima) e as advertências que só chegam
## nela (`ShiftReport.later`) e as palavras-chave ouvidas na escuta (`Clue`, em dicionário) e quantas vezes cada lugar
## denunciou a telefonista (`Eavesdrop.grudges`) e as noites de chuva (a mancha de umidade da sala, `Background.damp`).

const PATH := "user://progress.cfg"

var night := 0   ## 0 = o treinamento (jogo novo)
var pace := 1   ## nível de ritmo da próxima noite (GameContent.paces; veja Pace.next)
var low_nights := 0
var flags := PackedStringArray()
var news: Array = []
var later: Array = []
var clues: Array = []
var grudges := {}   ## número do lugar -> denúncias
var rains := 0   ## noites de chuva que já passaram


static func load_saved() -> Progress:
	var p := Progress.new()
	var f := ConfigFile.new()
	if f.load(PATH) == OK:
		p.night = f.get_value("progress", "night", 0)
		p.pace = f.get_value("progress", "pace", Pace.expected(p.night))
		p.low_nights = f.get_value("progress", "low_nights", 0)
		p.flags = f.get_value("progress", "flags", PackedStringArray())
		p.news = f.get_value("progress", "news", [])
		p.later = f.get_value("progress", "later", [])
		p.clues = f.get_value("progress", "clues", [])
		p.grudges = f.get_value("progress", "grudges", {})
		p.rains = f.get_value("progress", "rains", 0)
	return p


func save() -> void:
	var f := ConfigFile.new()
	f.set_value("progress", "night", night)
	f.set_value("progress", "pace", pace)
	f.set_value("progress", "low_nights", low_nights)
	f.set_value("progress", "flags", flags)
	f.set_value("progress", "news", news)
	f.set_value("progress", "later", later)
	f.set_value("progress", "clues", clues)
	f.set_value("progress", "grudges", grudges)
	f.set_value("progress", "rains", rains)
	f.save(PATH)


## Volta para o começo (o treinamento).
static func clear() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
