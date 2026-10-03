extends SceneTree
## Base dos testes. Rodar com `tests/run.sh` (ou `godot --headless --path . -s tests/test_x.gd`).
## `ok()` falha o teste com código de saída 1 em vez de travar como o `assert` faz no modo headless.

var failed := false


func ok(cond: bool, msg: String = "") -> void:
	if cond or failed:
		return
	failed = true
	var st := get_stack()
	var where := "linha %d" % st[1]["line"] if st.size() > 1 else ""
	printerr("FALHOU (%s): %s" % [where, msg])
	quit(1)


func wait_until(cond: Callable, sec: float = 60.0) -> bool:
	var t := 0.0
	while not cond.call():
		await process_frame
		t += 1.0 / 60.0
		if t > sec or failed:
			return false
	return true


func frames(n: int) -> void:
	for i in n:
		await process_frame


## `sectors`: setores atendidos (vazio = os da noite); os cenários usam números da lista inteira.
func load_main(sectors: Array = []) -> Node:
	var m: Node = load("res://scenes/main.tscn").instantiate()
	m.night_no = 1   # não lê nem grava o progresso salvo (`-- --night=N` escolhe outra noite)
	m.force_sectors = sectors
	root.add_child(m)
	current_scene = m
	await process_frame
	return m


func finish(name: String) -> void:
	if not failed:
		print("PASSOU: " + name)
		quit(0)
