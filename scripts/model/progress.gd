class_name Progress
extends RefCounted
## O que fica salvo entre as noites (user://progress.cfg): a próxima noite e o ritmo dela, as advertências graves
## acumuladas, os marcadores do roteiro (escolhas que mudam as noites seguintes; veja StoryFlags) e o jornal da manhã
## seguinte (as manchetes da noite, `ShiftReport.news`, que ficam na mesa na próxima).

const PATH := "user://progress.cfg"

var night := 1
var pace := 1   ## nível de ritmo da próxima noite (GameContent.paces; veja Pace.next)
var severe := 0
var flags := PackedStringArray()
var news: Array = []


static func load_saved() -> Progress:
	var p := Progress.new()
	var f := ConfigFile.new()
	if f.load(PATH) == OK:
		p.night = f.get_value("progress", "night", 1)
		p.pace = f.get_value("progress", "pace", Pace.expected(p.night))
		p.severe = f.get_value("progress", "severe", 0)
		p.flags = f.get_value("progress", "flags", PackedStringArray())
		p.news = f.get_value("progress", "news", [])
	return p


func save() -> void:
	var f := ConfigFile.new()
	f.set_value("progress", "night", night)
	f.set_value("progress", "pace", pace)
	f.set_value("progress", "severe", severe)
	f.set_value("progress", "flags", flags)
	f.set_value("progress", "news", news)
	f.save(PATH)


## Volta para a primeira noite.
static func clear() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
