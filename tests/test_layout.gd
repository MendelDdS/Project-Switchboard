extends "res://tests/test_base.gd"
## A disposição dos objetos da mesa: em 16:9 e nas janelas mais largas (o `main.tscn` sozinho), nenhum objeto
## fica por cima de outro na tela (o relógio por cima das listas passou duas vezes conferido só na captura). Mede o
## contorno de cada um como o cenário o desenhou (`Background._occ`, `occ_ids`). A caneca fica na frente do relógio
## de propósito. E a resposta mais longa do jogo, num botão do painel, não alarga a tela (a oferta da alternativa
## empurrava tudo para a esquerda).

const WIDTHS := [960, 1125, 1281]   # o jogo é sempre 960 (`GameView`); as outras, o `main.tscn` sozinho numa janela larga
const TOGETHER := [["relogio", "caneca"]]   # os que se encostam de propósito
const WANT := [Tools.DIRECTORY, Tools.DISPATCH, Tools.LOGBOOK, Tools.CALL_LOG, Tools.NEWS, Tools.TOLL, "relogio", "caneca"]


func _initialize() -> void:
	# a vista no amanhecer desenha ~17 mil itens por quadro: acima do buffer do renderizador, ele às vezes trava
	# (`project.godot`; o editor aberto pode regravá-lo sem a linha)
	ok(int(ProjectSettings.get_setting("rendering/gl_compatibility/item_buffer_size")) >= 32768, "item_buffer_size abaixo de 32768")
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
		if w == 960:
			await _longest_choice(m)
		vp.queue_free()
		await frames(2)
	finish("disposição da mesa")


## A resposta mais longa (a oferta da alternativa) com outras duas no painel: tudo dentro dos 960 px.
func _longest_choice(m: Main) -> void:
	var longest := ""
	for t: TransferCall in GameData.CONTENT.transfers + GameData.CONTENT.transfer_templates:
		if tr(t.alt_ask).length() > longest.length():
			longest = tr(t.alt_ask)
	var c := PhoneCall.new()
	c.on_line = true
	m.phone.show_call(c)
	c.set_options([{"label": T.text(T.Key.CHOICE_REPEAT), "fn": func(): pass}, {"label": longest, "fn": func(): pass},
		{"label": T.text(T.Key.CHOICE_SMALLTALK), "fn": func(): pass}])
	await frames(4)
	var r := m.phone.get_global_rect()
	ok(r.position.x >= 0.0 and r.end.x <= 960.0 and m.size.x <= 960.0,
		"a resposta mais longa (%d letras) cabe no painel: painel em %s, tela com %.0f px" % [longest.length(), r, m.size.x])
	m.phone.show_call(null)


func _area(q: PackedVector2Array) -> float:
	var s := 0.0
	for k in q.size():
		s += q[k].cross(q[(k + 1) % q.size()])
	return absf(s) / 2.0
