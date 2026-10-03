extends Node
## Base dos testes. Rodar com `tests/run.sh` (um só: `Godot --headless --fixed-fps 60 --path . tests/runner.tscn --
## --test=x`; veja `runner.gd`). O teste começa em `_initialize`.
## `ok()` falha o teste com código de saída 1 em vez de travar como o `assert` faz no modo headless.

var failed := false


func _ready() -> void:
	_initialize.call_deferred()   # a raiz ainda está montando os filhos: o teste põe o Main nela


func _initialize() -> void:
	pass


func ok(cond: bool, msg: String = "") -> void:
	if cond or failed:
		return
	failed = true
	var st := get_stack()
	var where := "linha %d" % st[1]["line"] if st.size() > 1 else ""
	printerr("FALHOU (%s): %s" % [where, msg])
	get_tree().quit(1)


func wait_until(cond: Callable, sec: float = 60.0) -> bool:
	var t := 0.0
	while not cond.call():
		await get_tree().process_frame
		t += 1.0 / 60.0
		if t > sec or failed:
			return false
	return true


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## `sectors`: setores atendidos (vazio = os da noite); os cenários usam números da lista inteira.
func load_main(sectors: Array = []) -> Node:
	var m: Node = load("res://scenes/main.tscn").instantiate()
	m.night_no = 1   # não lê nem grava o progresso salvo (`-- --night=N` escolhe outra noite)
	m.force_sectors = sectors
	get_tree().root.add_child(m)
	get_tree().current_scene = m
	await get_tree().process_frame
	return m


func finish(name: String) -> void:
	if not failed:
		print("PASSOU: " + name)
		get_tree().quit(0)
