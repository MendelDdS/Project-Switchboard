extends SceneTree
## Os degraus de uma beira numa captura, para conferir se ela é limpa (`PLANO_PIXEL.md`):
##   Godot --headless --path . -s tools/edge_steps.gd -- build/x.png 756,271,781,286 [mais beiras...]
## Cada beira é uma reta aproximada (px da captura, até ~3 px fora): ao longo do eixo longo, a beira de verdade é o
## maior salto de cor perto dela. Imprime os degraus (quantos px seguidos no eixo longo antes de andar 1 no curto) e
## marca a beira irregular: degraus que não são iguais nem alternados um a um (n, n + 1, n...: o que o `clean_slope`
## dá), um passo de 2 ou um passo para trás (um dente).

const NEAR := 3   ## quantos px para cada lado da reta dada a beira pode estar


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("uso: -- <captura> x0,y0,x1,y1 [...]")
		quit(1)
		return
	var img := Image.load_from_file(args[0] if args[0].is_absolute_path() else ProjectSettings.globalize_path("res://" + args[0]))
	for e in args.slice(1):
		var v := (e as String).split_floats(",")
		print("%s: %s" % [e, _steps(img, Vector2(v[0], v[1]), Vector2(v[2], v[3]))])
	quit()


func _steps(img: Image, a: Vector2, b: Vector2) -> String:
	var flat := absf(b.x - a.x) >= absf(b.y - a.y)
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	var pos := []   # a beira no eixo curto, a cada px do longo
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		var best := -1.0
		var at := 0
		for o in range(-NEAR, NEAR):
			var q := Vector2i(p.round()) + (Vector2i(0, o) if flat else Vector2i(o, 0))
			var r := q + (Vector2i(0, 1) if flat else Vector2i(1, 0))
			if q.x < 0 or q.y < 0 or r.x >= img.get_width() or r.y >= img.get_height():
				continue
			var c := img.get_pixelv(q)
			var d := img.get_pixelv(r)
			var jump := absf(c.r - d.r) + absf(c.g - d.g) + absf(c.b - d.b)
			if jump > best:
				best = jump
				at = q.y if flat else q.x
		pos.append(at)
	var dir := signi(pos[-1] - pos[0])
	var runs := []
	var run := 1
	var bad := ""
	for i in range(1, pos.size()):
		var s: int = pos[i] - pos[i - 1]
		if s == 0:
			run += 1
			continue
		if absi(s) > 1:
			bad = "passo de %d" % s
		elif signi(s) != dir:
			bad = "dente"
		runs.append(run)
		run = 1
	runs.append(run)
	var inner: Array = runs.slice(1, -1) if runs.size() > 2 else runs   # (as pontas são cortadas pela reta dada)
	if bad == "" and inner.size() > 1:
		var even := inner.all(func(r: int) -> bool: return r == inner[0])
		var swing := true   # alternados um a um, n e n + 1
		for i in range(1, inner.size()):
			swing = swing and absi(inner[i] - inner[i - 1]) == 1 and (i < 2 or inner[i] == inner[i - 2])
		if not even and not swing:
			bad = "degraus desencontrados"
	return "%s  %s" % ["-".join(runs.map(func(r): return str(r))), "IRREGULAR (" + bad + ")" if bad != "" else "limpa"]
