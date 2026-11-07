extends SceneTree
## A medida do plano de pixel (HISTORICO 392; as regras em `scripts/ui/CLAUDE.md`): para cada captura de uma pasta (`tools/hibit_shots.sh`), quantas
## cores distintas ela tem e quantos blocos de 8×8 são degradê contínuo (muitas cores, `MIN_COLORS` ou mais, com os
## vizinhos quase iguais, `MAX_STEP`: a luz lisa dos shaders, onde a pixel art pede degraus de paleta). Grava, numa
## pasta ao lado (`<pasta>_mapa`), cada captura escurecida com esses blocos em laranja. Com uma segunda pasta, compara:
##   Godot --headless --path . -s tools/pixel_map.gd -- build/pixel/antes [build/pixel/depois]

const BLOCK := 8
const MIN_COLORS := 28   # cores num bloco a partir das quais ele é degradê (uma textura de pixel art fica bem abaixo)...
const MAX_STEP := 6.0    # ...se a luminância média entre vizinhos (0 a 255) não passa disto (senão é textura miúda)
const MARK := Color(1.0, 0.55, 0.0, 0.35)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("uso: -- <pasta> [pasta para comparar]")
		quit(1)
		return
	var dirs: Array = Array(args).map(func(a: String) -> String: return a.trim_suffix("/"))
	var all := []
	for d: String in dirs:
		all.append(_measure(d))
	var names: Array = all[0].keys()
	names.sort()
	for f: String in names:
		var line := "%-28s" % f.get_basename()
		for m: Dictionary in all:
			line += "  cores %6d  degradê %4d" % m.get(f, [0, 0]) if m.has(f) else "  (sem captura)"
		print(line)
	quit()


## Mede as capturas da pasta `d` e grava os mapas: nome -> [cores, blocos de degradê].
func _measure(d: String) -> Dictionary:
	var out := {}
	var pngs := Array(DirAccess.get_files_at("res://" + d)).filter(func(f: String) -> bool:   # (as `_zoom` são ampliadas)
		return f.ends_with(".png") and not f.ends_with("_zoom.png"))
	if pngs.is_empty():
		print("nenhuma captura em " + d)
		return out
	DirAccess.make_dir_recursive_absolute("res://%s_mapa" % d)
	for f: String in pngs:
		var img := Image.load_from_file("res://%s/%s" % [d, f])
		img.convert(Image.FORMAT_RGBA8)
		var w := img.get_width()
		var h := img.get_height()
		var px := img.get_data()
		var lum := PackedFloat32Array()
		lum.resize(w * h)
		var colors := {}
		for i in w * h:
			var k := px.decode_u32(i * 4)
			colors[k] = true
			lum[i] = (px[i * 4] * 0.299 + px[i * 4 + 1] * 0.587 + px[i * 4 + 2] * 0.114)
		var map := img.duplicate() as Image
		map.adjust_bcs(0.55, 1.0, 1.0)
		var flat := 0
		for by in range(0, h - BLOCK + 1, BLOCK):
			for bx in range(0, w - BLOCK + 1, BLOCK):
				var seen := {}
				var step := 0.0
				for y in range(by, by + BLOCK):
					for x in range(bx, bx + BLOCK):
						seen[px.decode_u32((y * w + x) * 4)] = true
						if x > bx:
							step += absf(lum[y * w + x] - lum[y * w + x - 1])
				if seen.size() >= MIN_COLORS and step / (BLOCK * (BLOCK - 1)) < MAX_STEP:
					flat += 1
					for y in range(by, by + BLOCK):
						for x in range(bx, bx + BLOCK):
							map.set_pixel(x, y, map.get_pixel(x, y).blend(MARK))
		map.save_png("res://%s_mapa/%s" % [d, f])
		out[f] = [colors.size(), flat]
	return out
