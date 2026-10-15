extends SceneTree
## Compara duas pastas de capturas (`tools/shot.tscn`, `tools/hibit_shots.sh`), imagem por imagem, pelo nome: quantos
## pixels mudaram e onde (o retângulo que os contém). Para trocar cores por constantes do `Pal` sem mudar nenhum tom
## (plano hi-bit), conferindo que as capturas saem idênticas, e não só olhando. Grave com `--still` (sem a poeira do
## feixe); o que ainda muda sozinho de uma captura para outra (a vista da janela; a fala na miniatura do painel) fica
## em retângulos ignorados, x,y,w,h:
##   Godot --headless --path . -s tools/diff_shots.gd -- build/hibit/antes build/hibit/depois 760,60,200,220


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("uso: -- <pasta de antes> <pasta de depois>")
		quit(1)
		return
	var a: String = args[0].trim_suffix("/")
	var b: String = args[1].trim_suffix("/")
	var skip: Array[Rect2i] = []
	for i in range(2, args.size()):
		var r := args[i].split(",")
		skip.append(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])))
	var changed := 0
	for f in DirAccess.get_files_at("res://" + a):
		if not f.ends_with(".png"):
			continue
		var ia := Image.load_from_file("res://%s/%s" % [a, f])
		var path := "res://%s/%s" % [b, f]
		if not FileAccess.file_exists(path):
			print("%s: falta em %s" % [f, b])
			changed += 1
			continue
		var ib := Image.load_from_file(path)
		if ia.get_size() != ib.get_size():
			print("%s: tamanhos diferentes" % f)
			changed += 1
			continue
		ia.convert(Image.FORMAT_RGBA8)
		ib.convert(Image.FORMAT_RGBA8)
		if ia.get_data() == ib.get_data():
			continue
		var n := 0
		var box := Rect2i()
		for y in ia.get_height():
			for x in ia.get_width():
				if ia.get_pixel(x, y) != ib.get_pixel(x, y) and not skip.any(func(r: Rect2i) -> bool: return r.has_point(Vector2i(x, y))):
					box = Rect2i(x, y, 1, 1) if n == 0 else box.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
					n += 1
		if n > 0:
			print("%s: %d pixels diferentes, em %s" % [f, n, box])
			changed += 1
	print("iguais" if changed == 0 else "%d imagens diferentes" % changed)
	quit(0 if changed == 0 else 1)
