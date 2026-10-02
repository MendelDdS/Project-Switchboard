class_name Progress
extends RefCounted
## O que fica salvo entre as noites (user://progress.cfg): a próxima noite e o ritmo dela, as advertências graves
## acumuladas e os
## marcadores do roteiro (escolhas que mudam as noites seguintes; veja StoryFlags).

const PATH := "user://progress.cfg"

var night := 1
var pace := 1   ## nível de ritmo da próxima noite (GameContent.paces; veja Pace.next)
var severe := 0
var flags := PackedStringArray()


static func load_saved() -> Progress:
	var p := Progress.new()
	var f := ConfigFile.new()
	if f.load(PATH) == OK:
		p.night = f.get_value("progress", "night", 1)
		p.pace = f.get_value("progress", "pace", p.night)
		p.severe = f.get_value("progress", "severe", 0)
		p.flags = f.get_value("progress", "flags", PackedStringArray())
	return p


func save() -> void:
	var f := ConfigFile.new()
	f.set_value("progress", "night", night)
	f.set_value("progress", "pace", pace)
	f.set_value("progress", "severe", severe)
	f.set_value("progress", "flags", flags)
	f.save(PATH)


## Volta para a primeira noite.
static func clear() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
