extends SceneTree
## Os degraus de uma beira numa captura, para conferir se ela é limpa (`scripts/ui/CLAUDE.md`, Beiras):
##   Godot --headless --path . -s tools/edge_steps.gd -- build/x.png 756,271,781,286 [mais beiras...]
## Cada beira é uma reta aproximada (px da captura, até ~3 px fora): ao longo do eixo longo, a beira de verdade é o
## maior salto de cor perto dela; com o lado do fundo no fim (`,l`, `,r`, `,u`, `,d`), o primeiro px que foge da cor
## do fundo, vindo dele (o maior salto se enganava com as listras de dentro do objeto). Imprime os degraus (quantos px
## seguidos no eixo longo antes de andar 1 no curto) e marca a beira irregular: degraus que não são iguais nem
## alternados um a um (n, n + 1, n...: o que o `clean_slope` dá), um passo de 2 ou um passo para trás (um dente).
## As beiras já consertadas, com os degraus aprovados, ficam em `tools/beiras.txt`; o `tools/visual.sh` as confere:
##   Godot --headless --path . -s tools/edge_steps.gd -- --check=tools/beiras.txt build/visual/disco
## Beira que mudou sai na lista com os degraus de antes e os de agora (e sai com 1): confira na captura e, se ficou
## boa, troque os degraus guardados (`--accept` regrava o arquivo com os de agora).

const NEAR := 3   ## quantos px para cada lado da reta dada a beira pode estar
const FROM := 5   ## de quantos px fora da reta, no lado do fundo, a medida vindo dele começa
const BACK := 45   ## quanto de cor (soma de R, G e B, de 0 a 765) separa o objeto do fundo
const SIDES := {"l": Vector2i(1, 0), "r": Vector2i(-1, 0), "u": Vector2i(0, 1), "d": Vector2i(0, -1)}   ## de onde vem o fundo -> para onde andar


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0].begins_with("--check="):
		quit(_check(args[0].get_slice("=", 1), args[1], false))
		return
	if args.size() == 3 and args[0].begins_with("--check=") and args[2] == "--accept":
		quit(_check(args[0].get_slice("=", 1), args[1], true))
		return
	if args.size() < 2:
		print("uso: -- <captura> x0,y0,x1,y1[,l|r|u|d] [...] · -- --check=tools/beiras.txt <pasta das capturas> [--accept]")
		quit(1)
		return
	var img := _load(args[0])
	for e in args.slice(1):
		print("%s: %s" % [e, " ".join(_measure(img, e))])
	quit()


## Confere as beiras do arquivo `list` (linhas `captura | nome | x0,y0,x1,y1,lado | degraus`) nas capturas de `dir`;
## com `accept`, regrava os degraus de agora. Devolve 1 se alguma mudou.
func _check(list: String, dir: String, accept: bool) -> int:
	var lines := FileAccess.get_file_as_string(list).split("\n")
	var shots := {}
	var changed := 0
	for i in lines.size():
		var f := lines[i].split("|")
		if lines[i].begins_with("#") or f.size() != 4:
			continue
		var shot := f[0].strip_edges()
		if not shots.has(shot):
			shots[shot] = _load(dir.path_join(shot + ".png"))
		var got := _measure(shots[shot], f[2].strip_edges())
		if got[0] != f[3].strip_edges():
			changed += 1
			print("%s (%s): antes %s, agora %s  %s" % [f[1].strip_edges(), shot, f[3].strip_edges(), got[0], got[1]])
			lines[i] = " | ".join([f[0].strip_edges(), f[1].strip_edges(), f[2].strip_edges(), got[0]])
	if accept:
		FileAccess.open(list, FileAccess.WRITE).store_string("\n".join(lines))
	print("Beiras: %s" % ("nenhuma mudou" if changed == 0 else "%d %s%s" % [changed, "mudou" if changed == 1 else "mudaram", " (regravados os degraus)" if accept else ""]))
	return 0 if changed == 0 or accept else 1


func _load(path: String) -> Image:
	return Image.load_from_file(path if path.is_absolute_path() else ProjectSettings.globalize_path("res://" + path))


## Os degraus da beira `spec` (`x0,y0,x1,y1` e, se tiver, o lado do fundo) e o veredito: [degraus, "limpa"/"IRREGULAR (...)"].
func _measure(img: Image, spec: String) -> Array:
	var v := spec.split(",")
	var a := Vector2(v[0].to_float(), v[1].to_float())
	var b := Vector2(v[2].to_float(), v[3].to_float())
	return _steps(img, a, b, SIDES.get(v[4] if v.size() > 4 else "", Vector2i.ZERO))


func _steps(img: Image, a: Vector2, b: Vector2, walk: Vector2i) -> Array:
	var flat := absf(b.x - a.x) >= absf(b.y - a.y)
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	var pos := []   # a beira no eixo curto, a cada px do longo
	if walk != Vector2i.ZERO and (walk.y != 0) != flat:
		return ["-", "lado errado: numa beira deitada o fundo fica em cima ou embaixo (u, d); numa em pé, dos lados (l, r)"]
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		if walk != Vector2i.ZERO:
			pos.append(_from_back(img, Vector2i(p.round()), walk, flat))
			continue
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
	return ["-".join(runs.map(func(r): return str(r))), "IRREGULAR (" + bad + ")" if bad != "" else "limpa"]


## Onde começa o objeto na linha (ou coluna) de `p`: vindo do fundo, `FROM` px fora, o primeiro px que foge da cor dele.
func _from_back(img: Image, p: Vector2i, walk: Vector2i, flat: bool) -> int:
	var q := p - walk * FROM
	var back := img.get_pixelv(q)
	for k in FROM + NEAR + 1:
		var c := img.get_pixelv(q)
		if (absf(c.r - back.r) + absf(c.g - back.g) + absf(c.b - back.b)) * 255.0 >= BACK:
			break
		q += walk
	return q.y if flat else q.x
