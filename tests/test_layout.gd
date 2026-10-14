extends "res://tests/test_base.gd"
## A disposição dos objetos da mesa: em 16:9 e nas janelas mais largas (o `main.tscn` sozinho), nenhum objeto
## fica por cima de outro na tela (o relógio por cima das listas passou duas vezes conferido só na captura). Mede o
## contorno de cada um como o cenário o desenhou (`Background._occ`, `occ_ids`). A caneca fica na frente do relógio
## de propósito.

const WIDTHS := [960, 1125, 1281]   # o jogo é sempre 960 (`GameView`); as outras, o `main.tscn` sozinho numa janela larga
const TOGETHER := [["relogio", "caneca"]]   # os que se encostam de propósito
const WANT := [Tools.DIRECTORY, Tools.DISPATCH, Tools.LOGBOOK, Tools.CALL_LOG, Tools.NEWS, Tools.TOLL, "relogio", "caneca"]


func _initialize() -> void:
	for w: int in WIDTHS:
		var vp := SubViewport.new()   # o jogo nessa largura, como o `GameView` o põe na janela
		vp.size = Vector2i(w, 540)
		get_tree().root.add_child(vp)
		var m: Node = load("res://scenes/main.tscn").instantiate()
		m.night_no = 1
		vp.add_child(m)
		await frames(2)
		m.set_news([{"outcome": 0, "template": GameData.CONTENT.news_ok[0], "occurrence": "Outro", "address": "Rua do Sol, 10"}])
		await frames(12)   # a tela se arruma e o cenário se redesenha
		var bg: Background = m.background
		for id: String in WANT:
			ok(id in bg.occ_ids, "%d px: o cenário desenhou %s" % [w, id])
		for i in bg.occ_ids.size():
			for j in range(i + 1, bg.occ_ids.size()):
				var a := bg.occ_ids[i]
				var b := bg.occ_ids[j]
				if [a, b] in TOGETHER or [b, a] in TOGETHER:
					continue
				var area := 0.0
				var where := Rect2(Vector2.INF, Vector2.ZERO)   # (o ponto infinito some no primeiro `expand`)
				for q: PackedVector2Array in Geometry2D.intersect_polygons(bg._occ[i], bg._occ[j]):
					area += _area(q)
					where = Rect2(q[0], Vector2.ZERO) if where.position == Vector2.INF else where
					for p in q:
						where = where.expand(p)
				ok(area < 1.0, "%d px: %s e %s se sobrepõem na tela (%.0f px², em %s)" % [w, a, b, area, where])
		print("OK %d px: %d objetos, nenhum por cima de outro" % [w, bg.occ_ids.size()])
		vp.queue_free()
		await frames(2)
	finish("disposição da mesa")


func _area(q: PackedVector2Array) -> float:
	var s := 0.0
	for k in q.size():
		s += q[k].cross(q[(k + 1) % q.size()])
	return absf(s) / 2.0
