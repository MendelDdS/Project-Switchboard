extends Node
## Roda um teste como cena, com os autoloads (`Sfx`, `Settings`...) já de pé (com `-s` eles ainda não existem quando o
## Godot compila o teste): assim os testes podem ter tipo (`Main`, `Switchboard`...).
## `Godot --headless --fixed-fps 60 --path . tests/runner.tscn -- --test=flow` (mais os argumentos do jogo, como
## `--seed=1`). O teste é `tests/test_<nome>.gd` e entra como filho deste nó.


func _ready() -> void:
	var test := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--test="):
			test = a.trim_prefix("--test=")
	var script: Script = load("res://tests/test_%s.gd" % test) if test != "" else null
	if script == null or not script.can_instantiate():   # não existe ou não compila
		printerr("FALHOU: teste não encontrado ou não compila (use -- --test=nome)")
		get_tree().quit(1)
		return
	add_child(script.new())
