class_name Progress
extends RefCounted
## O que fica salvo entre as noites (user://progress.cfg): a próxima noite e as advertências graves acumuladas.

const PATH := "user://progress.cfg"

var night := 1
var severe := 0


static func load_saved() -> Progress:
	var p := Progress.new()
	var f := ConfigFile.new()
	if f.load(PATH) == OK:
		p.night = f.get_value("progress", "night", 1)
		p.severe = f.get_value("progress", "severe", 0)
	return p


func save() -> void:
	var f := ConfigFile.new()
	f.set_value("progress", "night", night)
	f.set_value("progress", "severe", severe)
	f.save(PATH)


## Volta para a primeira noite.
static func clear() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
