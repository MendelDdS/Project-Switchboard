extends Control
## Central de Vila Serena — cena principal.
## Monta a mesa do operador e conduz o turno: 5 ligações em sequência e o final.
##
## Loop: ATENDER → ENTENDER → CONSULTAR → CONECTAR/DESPACHAR → REGISTRAR → CONTINUAR

signal choice_made(i: int)

# ---------------------------------------------------------------- nós
var sfx: Sfx
var bg: Background
var board: Switchboard
var book: PhoneBook
var city: CityMap
var scrawl: Scrawl
var clock_lbl: Label
var radio_lbl: Label
var radio_led: ColorRect
var disp_lbl: Label
var call_line_lbl: Label
var call_state_lbl: Label
var transcript: RichTextLabel
var choices_box: HFlowContainer
var warn_lbl: Label
var answer_btn: Button
var hang_btn: Button
var hint_lbl: RichTextLabel
var tab_btns := {}
var tab_dots := {}
var views := {}
var map_sel_lbl: Label
var dispatch_box: VBoxContainer
var ledger: RichTextLabel
var pending_box: PanelContainer
var p_time: Label
var p_who: LineEdit
var p_where: LineEdit
var p_type: OptionButton
var p_unit: LineEdit
var p_obs: LineEdit
var reg_msg: Label
var glow: TextureRect
var intro: ColorRect
var fade_rect: ColorRect
var fade_l1: Label
var fade_l2: Label
var fade_btn: Button

# ---------------------------------------------------------------- estado
var minutes := 0.0
var running := false
const GAME_MIN_PER_SEC := 1.0   # 480 minutos de turno ≈ 8 minutos reais
const SHIFT_END := 480.0
var next_at := -1.0
var line_until: Array = []
var myst_time := "02:13"
var idx := -1
var calls: Array = []
var lines: Array = []
var dial := ""
var last_dialed := ""
var disp_until := 0
var cur: Dictionary = {}
var token := 0
var phase := "idle"
var last_talk := 0
var talking := false
var tab := "lista"
var map_sel: Dictionary = {}
var units := {"pol": "DISPONÍVEL", "bomb": "DISPONÍVEL", "amb": "DISPONÍVEL"}
var unit_sel: Array = []
var occ := ""
var sent: Dictionary = {}
var incident: Dictionary = {}
var dispatch_report := ""
var dispatch_msg := ""
var entries: Array = []
var pending: Dictionary = {}
var after := false
var note_shown := false
var note_wanted := false
var ending := false
var flick := false
var _note_gen := 0
var _seen_started := false
var _t_lines: Array = []
var _radio_q: Array = []
var _radio_busy := false
var _tick_acc := 0.0
var _frame := 0
var _warn_gen := 0


# ================================================================ montagem

func _ready() -> void:
	Pal.init_fonts()
	randomize()
	theme = _make_theme()
	for i in 10:
		lines.append("free")
		line_until.append(-1.0)
	calls = [
		_mk(GameData.T1.pick_random(), "transfer", 0),
		_mk(GameData.T2.pick_random(), "transfer", 1),
		_mk(GameData.EM.pick_random(), "emergency", 2),
		_mk(GameData.TR.pick_random(), "prank", 3),
		_mk({}, "mystery", 4),
	]
	sfx = Sfx.new()
	add_child(sfx)
	_build()


func _mk(src: Dictionary, kind: String, i: int) -> Dictionary:
	var c: Dictionary = src.duplicate(true)
	c["kind"] = kind
	c["at"] = float(GameData.CALL_AT[i])
	return c


func _sb(bg_c: Color, border: Color = Color.BLACK, bw: int = 2, pad: float = 6.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg_c
	s.border_color = border
	s.set_border_width_all(bw)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.5
	s.content_margin_bottom = pad * 0.5
	return s


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = Pal.ui
	t.default_font_size = 14
	t.set_stylebox("normal", "Button", _sb(Color("3a3325")))
	t.set_stylebox("hover", "Button", _sb(Color("4a4130")))
	t.set_stylebox("pressed", "Button", _sb(Color("2a241a")))
	t.set_stylebox("disabled", "Button", _sb(Color("25211a"), Color("111111")))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Pal.GLOW
	focus.set_border_width_all(2)
	t.set_stylebox("focus", "Button", focus)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(k, "Button", Pal.PAPER)
	t.set_color("font_disabled_color", "Button", Color(Pal.PAPER, 0.35))
	t.set_color("font_color", "Label", Pal.TEXT)
	var le := _sb(Color("f3ead0"), Pal.INK_SOFT, 2, 6)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", _sb(Color("fbf3dc"), Pal.INK, 2, 6))
	t.set_color("font_color", "LineEdit", Pal.INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(Pal.INK_SOFT, 0.7))
	t.set_color("caret_color", "LineEdit", Pal.INK)
	t.set_font("font", "LineEdit", Pal.mono)
	t.set_font_size("font_size", "LineEdit", 20)
	for s in ["normal", "hover", "pressed", "focus"]:
		t.set_stylebox(s, "OptionButton", _sb(Color("f3ead0"), Pal.INK_SOFT, 2, 6))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(k, "OptionButton", Pal.INK)
	t.set_font("font", "OptionButton", Pal.mono)
	t.set_font_size("font_size", "OptionButton", 20)
	return t


func _label(parent: Node, txt: String, pos: Vector2, sz: int, col: Color, font: Font = null, w: float = 0.0) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	if w > 0:
		l.size = Vector2(w, 0)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	if font != null:
		l.add_theme_font_override("font", font)
	parent.add_child(l)
	return l


func _button(parent: Node, txt: String, pos: Vector2, sz: Vector2, bg_c: Color, fg: Color, hi: Color = Color(0, 0, 0, 0)) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.size = sz
	var n := _sb(bg_c)
	if hi.a > 0:
		n.border_width_bottom = 4
		n.border_width_right = 4
		n.border_color = hi
	var h := n.duplicate()
	h.bg_color = bg_c.lightened(0.08)
	var p := n.duplicate()
	p.bg_color = bg_c.darkened(0.12)
	p.border_width_bottom = 2
	p.border_width_right = 2
	var d := n.duplicate()
	d.bg_color = bg_c.darkened(0.55)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("disabled", d)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.4))
	parent.add_child(b)
	return b


func _bevel(pos: Vector2, sz: Vector2) -> Bevel:
	var b := Bevel.new()
	b.position = pos
	b.size = sz
	add_child(b)
	return b


func _build() -> void:
	bg = Background.new()
	bg.size = Vector2(1280, 720)
	add_child(bg)

	# relógio
	var ck := _bevel(Vector2(24, 16), Vector2(262, 74))
	var ckbg := ColorRect.new()
	ckbg.color = Color("120d07")
	ckbg.position = Vector2(12, 11)
	ckbg.size = Vector2(132, 52)
	ck.add_child(ckbg)
	clock_lbl = _label(ck, "22:00", Vector2(12, 4), 60, Pal.AMBER, Pal.mono, 132)
	clock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(ck, "Turno\n22:00–06:00", Vector2(156, 17), 13, Pal.DIM)
	# título
	_label(self, "Central de Vila Serena", Vector2(304, 18), 17, Pal.TEXT)
	_label(self, "Operador noturno · mesa 1", Vector2(304, 42), 13, Pal.DIM)
	# rádio
	var rd := _bevel(Vector2(956, 16), Vector2(300, 74))
	var gr := ColorRect.new()
	gr.color = Color("0d0c09")
	gr.position = Vector2(12, 12)
	gr.size = Vector2(54, 50)
	rd.add_child(gr)
	for k in 8:
		var s := ColorRect.new()
		s.color = Color("3c3527")
		s.position = Vector2(2, 3 + k * 6)
		s.size = Vector2(50, 3)
		gr.add_child(s)
	radio_led = ColorRect.new()
	radio_led.color = Color("3a1a12")
	radio_led.position = Vector2(60, 8)
	radio_led.size = Vector2(8, 8)
	rd.add_child(radio_led)
	_label(rd, "Rádio de despacho", Vector2(78, 6), 11, Pal.DIM)
	var rbg := ColorRect.new()
	rbg.color = Color("0c110c")
	rbg.position = Vector2(78, 24)
	rbg.size = Vector2(208, 42)
	rd.add_child(rbg)
	radio_lbl = _label(rbg, "…", Vector2(6, 0), 18, Color("b7c9a8"), Pal.mono, 198)
	radio_lbl.size = Vector2(198, 42)
	radio_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	radio_lbl.clip_text = true
	radio_lbl.add_theme_constant_override("line_spacing", -4)

	# telefone (antes da mesa comutadora para os cabos ficarem por cima)
	_build_phone()
	board = Switchboard.new()
	board.position = Vector2(24, 104)
	board.lines = lines
	board.sfx = sfx
	add_child(board)
	board.plug_changed.connect(_on_plug_changed)
	board.info_requested.connect(_show_line_info)
	board.warned.connect(warn)

	_build_tools()

	hint_lbl = RichTextLabel.new()
	hint_lbl.bbcode_enabled = true
	hint_lbl.position = Vector2(636, 674)
	hint_lbl.size = Vector2(620, 40)
	hint_lbl.scroll_active = false
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_lbl.add_theme_color_override("default_color", Color("d9cfae"))
	hint_lbl.add_theme_font_size_override("normal_font_size", 14)
	add_child(hint_lbl)

	_build_overlays()


func _build_phone() -> void:
	var ph := _bevel(Vector2(24, 388), Vector2(588, 316))
	var dbg := ColorRect.new()
	dbg.color = Color("120d07")
	dbg.position = Vector2(16, 14)
	dbg.size = Vector2(200, 40)
	ph.add_child(dbg)
	disp_lbl = _label(dbg, "", Vector2(6, 0), 32, Pal.AMBER, Pal.mono, 188)
	disp_lbl.size = Vector2(188, 40)
	disp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	disp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	disp_lbl.clip_text = true
	var keys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "R"]
	for i in keys.size():
		var k: String = keys[i]
		var txt := "Cancelar" if k == "C" else ("Rediscar" if k == "R" else k)
		var b := _button(ph, txt, Vector2(16 + (i % 3) * 69, 64 + int(i / 3) * 46), Vector2(61, 38), Color("d4c7a2"), Color("221c13"), Color("9e906a"))
		b.focus_mode = Control.FOCUS_NONE
		if k == "C" or k == "R":
			b.add_theme_font_size_override("font_size", 12)
		else:
			b.add_theme_font_override("font", Pal.mono)
			b.add_theme_font_size_override("font_size", 28)
		b.pressed.connect(_on_key.bind(k))
	var dial_btn := _button(ph, "Discar", Vector2(16, 254), Vector2(200, 42), Pal.AMBER, Color("1c150c"), Color("a86b1d"))
	dial_btn.focus_mode = Control.FOCUS_NONE
	dial_btn.add_theme_font_size_override("font_size", 16)
	dial_btn.pressed.connect(func(): do_dial(false))

	call_line_lbl = _label(ph, "Nenhuma chamada", Vector2(236, 12), 13, Pal.DIM)
	call_state_lbl = _label(ph, "", Vector2(236, 12), 13, Pal.DIM, null, 336)
	call_state_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var tp := PanelContainer.new()
	tp.position = Vector2(236, 34)
	tp.size = Vector2(336, 150)
	tp.add_theme_stylebox_override("panel", _sb(Color("0f0d09"), Color.BLACK, 2, 8))
	ph.add_child(tp)
	transcript = RichTextLabel.new()
	transcript.bbcode_enabled = true
	transcript.scroll_following = true
	transcript.custom_minimum_size = Vector2(318, 140)
	transcript.add_theme_color_override("default_color", Pal.TEXT)
	transcript.add_theme_font_size_override("normal_font_size", 14)
	transcript.add_theme_constant_override("line_separation", 2)
	tp.add_child(transcript)
	choices_box = HFlowContainer.new()
	choices_box.position = Vector2(236, 192)
	choices_box.size = Vector2(336, 60)
	choices_box.add_theme_constant_override("h_separation", 6)
	choices_box.add_theme_constant_override("v_separation", 6)
	ph.add_child(choices_box)
	warn_lbl = _label(ph, "", Vector2(236, 250), 12, Pal.AMBER, null, 336)
	answer_btn = _button(ph, "Atender", Vector2(236, 268), Vector2(162, 36), Pal.GREEN, Color("1c150c"), Color("5b7e44"))
	answer_btn.add_theme_font_size_override("font_size", 16)
	answer_btn.pressed.connect(answer)
	answer_btn.disabled = true
	hang_btn = _button(ph, "Desligar", Vector2(410, 268), Vector2(162, 36), Pal.RED, Color("1c150c"), Color("8e3526"))
	hang_btn.add_theme_font_size_override("font_size", 16)
	hang_btn.pressed.connect(hangup)
	hang_btn.disabled = true


func _build_tools() -> void:
	var names := [["lista", "Lista telefônica", 150], ["mapa", "Mapa", 70], ["despacho", "Despacho", 104], ["caderno", "Caderno", 96]]
	var x := 636.0
	for n in names:
		var b := Button.new()
		b.text = n[1]
		b.position = Vector2(x, 108)
		b.size = Vector2(n[2], 34)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 15)
		var id: String = n[0]
		b.pressed.connect(func(): set_tab(id))
		add_child(b)
		tab_btns[id] = b
		var dot := ColorRect.new()
		dot.color = Pal.AMBER
		dot.size = Vector2(10, 10)
		dot.position = Vector2(b.size.x - 6, -5)
		dot.visible = false
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(dot)
		tab_dots[id] = dot
		x += float(n[2]) + 8.0
	var tool := Panel.new()
	tool.position = Vector2(636, 142)
	tool.size = Vector2(620, 522)
	var ps := _sb(Pal.PAPER)
	ps.shadow_color = Color(0, 0, 0, 0.35)
	ps.shadow_size = 0
	ps.shadow_offset = Vector2(6, 6)
	tool.add_theme_stylebox_override("panel", ps)
	add_child(tool)

	# lista
	book = PhoneBook.new()
	book.sfx = sfx
	_add_view("lista", tool, book)

	# mapa
	var mv := Control.new()
	_add_view("mapa", tool, mv)
	city = CityMap.new()
	city.sfx = sfx
	city.size = Vector2(576, 422)
	mv.add_child(city)
	city.segment_selected.connect(_on_segment)
	_label(mv, "Local marcado:", Vector2(0, 440), 15, Pal.INK)
	map_sel_lbl = _label(mv, "nenhum", Vector2(112, 432), 24, Pal.INK, Pal.mono)
	var ub := _button(mv, "Usar no despacho", Vector2(410, 434), Vector2(166, 34), Color("3a3325"), Pal.PAPER)
	ub.pressed.connect(func(): set_tab("despacho"))

	# despacho
	var dv := Control.new()
	_add_view("despacho", tool, dv)
	dispatch_box = VBoxContainer.new()
	dispatch_box.size = Vector2(576, 486)
	dispatch_box.add_theme_constant_override("separation", 6)
	dv.add_child(dispatch_box)

	# caderno
	var nv := Control.new()
	_add_view("caderno", tool, nv)
	for k in 18:
		var rl := ColorRect.new()
		rl.color = Color(0.35, 0.43, 0.55, 0.22)
		rl.position = Vector2(0, 30 + k * 26)
		rl.size = Vector2(576, 1)
		rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nv.add_child(rl)
	_label(nv, "Caderno de ocorrências", Vector2(0, 0), 18, Pal.INK)
	var nd := _label(nv, "Noite de 14 para 15", Vector2(0, 4), 13, Pal.INK_SOFT, null, 576)
	nd.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ledger = RichTextLabel.new()
	ledger.bbcode_enabled = true
	ledger.position = Vector2(0, 32)
	ledger.size = Vector2(576, 176)
	ledger.scroll_following = true
	ledger.add_theme_color_override("default_color", Pal.INK)
	ledger.add_theme_font_override("normal_font", Pal.mono)
	ledger.add_theme_font_size_override("normal_font_size", 16)
	nv.add_child(ledger)
	_render_ledger()

	pending_box = PanelContainer.new()
	pending_box.position = Vector2(0, 214)
	pending_box.size = Vector2(576, 250)
	pending_box.add_theme_stylebox_override("panel", _sb(Color(1, 0.97, 0.88, 0.55), Pal.INK, 2, 14))
	pending_box.visible = false
	nv.add_child(pending_box)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 8)
	pending_box.add_child(pv)
	p_time = Label.new()
	p_time.add_theme_color_override("font_color", Pal.INK)
	p_time.add_theme_font_size_override("font_size", 15)
	pv.add_child(p_time)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 6)
	pv.add_child(grid)
	p_who = _field(grid, "Solicitante")
	p_where = _field(grid, "Local / destino")
	var tv := VBoxContainer.new()
	tv.custom_minimum_size = Vector2(265, 0)
	tv.add_theme_constant_override("separation", 2)
	var tl := Label.new()
	tl.text = "Tipo"
	tl.add_theme_color_override("font_color", Pal.INK_SOFT)
	tl.add_theme_font_size_override("font_size", 12)
	tv.add_child(tl)
	p_type = OptionButton.new()
	for o in ["Escolha…", "Ligação comum", "Emergência", "Trote", "Outro"]:
		p_type.add_item(o)
	tv.add_child(p_type)
	grid.add_child(tv)
	p_unit = _field(grid, "Unidade enviada")
	p_obs = _field(pv, "Observações")
	p_obs.placeholder_text = "ex.: solicitante realizou chamada falsa"
	p_obs.get_parent().custom_minimum_size = Vector2(546, 0)
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 12)
	pv.add_child(rh)
	var rb := _button(rh, "Registrar ocorrência", Vector2.ZERO, Vector2.ZERO, Pal.INK, Pal.PAPER)
	rb.custom_minimum_size = Vector2(190, 34)
	rb.pressed.connect(_register)
	reg_msg = Label.new()
	reg_msg.add_theme_color_override("font_color", Pal.INK_RED)
	reg_msg.add_theme_font_size_override("font_size", 12)
	reg_msg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rh.add_child(reg_msg)

	scrawl = Scrawl.new()
	scrawl.position = Vector2(30, 220)
	scrawl.size = Vector2(500, 110)
	scrawl.visible = false
	nv.add_child(scrawl)

	_render_dispatch()
	_style_tabs()


func _field(parent: Node, lbl: String) -> LineEdit:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(265, 0)
	v.add_theme_constant_override("separation", 2)
	var l := Label.new()
	l.text = lbl
	l.add_theme_color_override("font_color", Pal.INK_SOFT)
	l.add_theme_font_size_override("font_size", 12)
	v.add_child(l)
	var e := LineEdit.new()
	v.add_child(e)
	parent.add_child(v)
	return e


func _add_view(id: String, tool: Control, v: Control) -> void:
	v.position = Vector2(22, 18)
	v.size = Vector2(576, 486)
	v.visible = id == tab
	tool.add_child(v)
	views[id] = v


func _style_tabs() -> void:
	for id in tab_btns:
		var b: Button = tab_btns[id]
		var on: bool = id == tab
		var s := _sb(Pal.PAPER if on else Color("3a3325"))
		s.border_width_bottom = 0
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, s)
		for k in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(k, Pal.INK if on else Color("cdbf98"))
		b.position.y = 104.0 if on else 108.0
		b.size.y = 40.0 if on else 34.0


func _build_overlays() -> void:
	# luz quente da luminária
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(1, 0.77, 0.43, 0.22), Color(1, 0.67, 0.31, 0.06), Color(1, 0.6, 0.3, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 640
	gt.height = 360
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.78, 0.04)
	gt.fill_to = Vector2(1.37, 0.04)
	glow = TextureRect.new()
	glow.texture = gt
	glow.size = Vector2(1280, 720)
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	add_child(glow)
	# vinheta
	var vg := Gradient.new()
	vg.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	vg.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.6)])
	var vt := GradientTexture2D.new()
	vt.gradient = vg
	vt.width = 640
	vt.height = 360
	vt.fill = GradientTexture2D.FILL_RADIAL
	vt.fill_from = Vector2(0.55, 0.45)
	vt.fill_to = Vector2(1.3, 0.45)
	var vig := TextureRect.new()
	vig.texture = vt
	vig.size = Vector2(1280, 720)
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)
	# linhas de varredura
	var scan := Control.new()
	scan.size = Vector2(1280, 720)
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan.draw.connect(func():
		for y in range(0, 720, 3):
			scan.draw_rect(Rect2(0, y, 1280, 1), Color(0, 0, 0, 0.08)))
	add_child(scan)

	# tela inicial
	intro = ColorRect.new()
	intro.color = Color(0.02, 0.024, 0.027, 0.92)
	intro.size = Vector2(1280, 720)
	add_child(intro)
	var card := Bevel.new()
	card.position = Vector2(360, 150)
	card.size = Vector2(560, 420)
	intro.add_child(card)
	_label(card, "Central de Vila Serena", Vector2(40, 30), 30, Pal.TEXT)
	_label(card, "Terça-feira · 22:00", Vector2(40, 72), 24, Pal.AMBER, Pal.mono)
	var q := PanelContainer.new()
	q.position = Vector2(40, 110)
	q.size = Vector2(480, 0)
	q.add_theme_stylebox_override("panel", _sb(Pal.PAPER, Color.BLACK, 2, 16))
	card.add_child(q)
	var ql := Label.new()
	ql.text = "Seu turno termina às 06:00. Atenda as chamadas, conecte-as corretamente e registre todas as ocorrências."
	ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ql.custom_minimum_size = Vector2(448, 0)
	ql.add_theme_font_override("font", Pal.mono)
	ql.add_theme_font_size_override("font_size", 24)
	ql.add_theme_color_override("font_color", Pal.INK)
	q.add_child(ql)
	var info := _label(card, "Tudo acontece na sua mesa. Use o mouse para levar os plugues até as tomadas e para consultar a lista, o mapa e o caderno. Os números também podem ser digitados pelo teclado. Use fones de ouvido.", Vector2(40, 238), 14, Pal.DIM, null, 480)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(480, 0)
	info.size = Vector2(480, 80)
	var sb := _button(card, "Começar turno", Vector2(40, 344), Vector2(180, 44), Pal.AMBER, Color("1c150c"), Color("a86b1d"))
	sb.add_theme_font_size_override("font_size", 17)
	sb.pressed.connect(_start_shift)

	# tela final
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.size = Vector2(1280, 720)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)
	fade_l1 = _label(fade_rect, "Fim da demonstração", Vector2(0, 300), 30, Pal.TEXT, null, 1280)
	fade_l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fade_l2 = _label(fade_rect, "Você atenderia novamente?", Vector2(0, 356), 36, Pal.AMBER, Pal.mono, 1280)
	fade_l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fade_btn = _button(fade_rect, "Recomeçar turno", Vector2(560, 440), Vector2(160, 36), Color(0, 0, 0), Pal.DIM)
	fade_btn.pressed.connect(func(): get_tree().reload_current_scene())
	for n in [fade_l1, fade_l2, fade_btn]:
		n.modulate.a = 0.0
	fade_btn.visible = false


# ================================================================ laço principal

func _start_shift() -> void:
	intro.visible = false
	sfx.start_ambience()
	running = true
	last_talk = Time.get_ticks_msec()
	radio("Central, viatura 2 em ronda. Tudo tranquilo.")
	hint("Aguarde as chamadas. A lista, o mapa, o despacho e o caderno ficam nas abas acima.")
	await get_tree().create_timer(2.2).timeout
	idx = -1
	schedule_next()


func fmt(m: float) -> String:
	var t := (22 * 60 + int(floor(m))) % 1440
	return "%02d:%02d" % [t / 60, t % 60]


func _process(delta: float) -> void:
	var dt := delta * 1000.0
	var now := Time.get_ticks_msec()
	if running:
		minutes = minf(SHIFT_END, minutes + delta * GAME_MIN_PER_SEC)
		_tick_acc += dt
		if _tick_acc > 1000.0:
			_tick_acc = 0.0
			sfx.play("tick", -3.0)
		if next_at >= 0.0 and minutes >= next_at:
			ring(idx + 1)
		_update_line_timers()
		clock_lbl.text = fmt(minutes)
		if not cur.is_empty() and cur.get("active", false) and not talking:
			if cur["kind"] == "transfer" and phase == "await" and board.plugs["fone"] == cur["line"] and now - last_talk > 22000:
				last_talk = now
				say(cur, GameData.WAITING.pick_random(), token)
			elif cur["kind"] == "emergency" and not cur.get("dispatched", false) and now - last_talk > 26000:
				last_talk = now
				say(cur, GameData.EM_WAITING.pick_random(), token)
	if disp_until > 0 and now > disp_until:
		disp_until = 0
		_render_disp()
	bg.flick = flick
	glow.modulate.a = bg.lamp_level
	_frame += 1


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed or e.echo:
		return
	var k: InputEventKey = e
	if k.keycode == KEY_ESCAPE and board.held != "":
		board.go_home(board.held)
		return
	var ch := k.unicode
	if ch >= 48 and ch <= 57:
		_on_key(char(ch))
	elif k.keycode == KEY_BACKSPACE:
		dial = dial.substr(0, max(0, dial.length() - 1))
		sfx.play("key")
		_render_disp()
	elif k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
		do_dial(false)


func hint(t: String) -> void:
	hint_lbl.text = "" if t == "" else "[bgcolor=#b8924e][color=#1a150d] MANUAL [/color][/bgcolor]  " + t


func warn(t: String) -> void:
	warn_lbl.text = t
	_warn_gen += 1
	var g := _warn_gen
	await get_tree().create_timer(4.0).timeout
	if g == _warn_gen:
		warn_lbl.text = ""


# ================================================================ mesa comutadora

func _on_plug_changed(p: String, n: int, prev: int) -> void:
	if p == "fone" and not cur.is_empty() and not cur.get("ended", false) and int(cur.get("line", 0)) > 0:
		var ln: int = cur["line"]
		if prev == ln and lines[ln - 1] == "talk":
			lines[ln - 1] = "hold"
			if cur["kind"] == "transfer" and phase == "await":
				_sys("(Linha do solicitante em espera.)")
		if n == ln and lines[ln - 1] == "hold":
			lines[ln - 1] = "talk"
	if p == "sw" and n == 7 and after:
		sfx.static_burst(2.0)
	_tutorial_step()
	_update_call_ui()


func _show_line_info(n: int) -> void:
	var st: String = lines[n - 1]
	if n == 7 and after and st == "free":
		# A linha está livre, mas guarda o registro da última chamada.
		board.show_info(PackedStringArray(["LINHA 07", "LIVRE", "ÚLTIMA ORIGEM: ???", "NÚMERO: ???", "DURAÇÃO: " + myst_time]), true, n)
		sfx.static_burst()
	else:
		var a := PackedStringArray(["LINHA %02d" % n, String(GameData.LINE_LABEL[st]).to_upper()])
		var p := board.plug_at(n)
		if p != "":
			a.append("PLUG: " + ("FONE" if p == "fone" else "SWITCH"))
		board.show_info(a, false, n)
		sfx.play("click")


# ================================================================ teclado numérico

func _on_key(k: String) -> void:
	if k == "C":
		dial = ""
		sfx.play("key")
		_render_disp()
	elif k == "R":
		sfx.play("key")
		do_dial(true)
	else:
		if phase == "dialing":
			return
		if dial.length() < 6:
			dial += k
		sfx.play("key")
		_render_disp()


func _render_disp() -> void:
	if Time.get_ticks_msec() < disp_until:
		return
	disp_lbl.add_theme_font_size_override("font_size", 32)
	disp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	disp_lbl.text = dial


func flash_disp(t: String, ms: int = 2600) -> void:
	disp_lbl.add_theme_font_size_override("font_size", 24)
	disp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disp_lbl.text = t
	disp_until = Time.get_ticks_msec() + ms


func do_dial(redial: bool) -> void:
	if phase == "dialing" or ending:
		return
	if after:
		await _callback_attempt(redial)
		return
	var num := last_dialed if redial else dial
	if cur.is_empty() or cur.get("ended", false) or cur["kind"] != "transfer":
		flash_disp("SEM CHAMADA", 1800)
		warn("Não há chamada aguardando conexão.")
		return
	if not cur.get("active", false):
		warn("Atenda a chamada primeiro.")
		return
	if phase != "await":
		warn("Ouça o pedido do solicitante antes de discar.")
		return
	if board.plugs["fone"] == cur["line"]:
		warn("Retire o plug do FONE da linha do solicitante antes de discar.")
		return
	if board.plugs["sw"] == -1:
		warn("Conecte o plug do SWITCH em uma linha livre.")
		return
	var out: int = board.plugs["sw"]
	if lines[out - 1] != "free":
		warn("A linha %02d não está livre. Use uma tomada com a lâmpada apagada." % out)
		return
	if num == "":
		warn("Digite o número no teclado.")
		return
	last_dialed = num
	phase = "dialing"
	_update_call_ui()
	var tok := token
	flash_disp("DISCANDO " + num, 60000)
	if not await wait(sfx.dial(num) + 0.25, tok):
		return
	var entry := GameData.find_number(num)
	if entry.is_empty():
		sfx.play("sit")
		flash_disp("NÃO ATRIBUÍDO")
		_sys("(O número %s não existe.)" % num)
		phase = "await"
		dial = ""
		_update_call_ui()
		return
	flash_disp("CHAMANDO…", 60000)
	if not await wait(sfx.ringback(1 if num == cur["target"] else 2) + 0.2, tok):
		return
	if num != cur["target"]:
		flash_disp("NÚMERO ERRADO")
		_sys("(Atendeu: %s. Não é quem o solicitante pediu. A conexão foi desfeita.)" % entry["n"])
		phase = "await"
		dial = ""
		_update_call_ui()
		if idx <= 1:
			hint("Confira o nome e o endereço na lista antes de discar. Há nomes parecidos.")
		return
	var talk_len := randf_range(14.0, 40.0)
	for ln in [out, int(cur["line"])]:
		lines[ln - 1] = "conn"
		line_until[ln - 1] = minutes + talk_len
	flash_disp("CONECTADO", 2400)
	dial = ""
	_sys("(Conexão estabelecida com %s.)" % entry["n"])
	cur["connected"] = true
	if not await wait(1.1, tok):
		return
	await say(cur, cur["thanks"], tok, 0.4)
	end_call("connected")


func _callback_attempt(redial: bool) -> void:
	phase = "dialing"
	if redial:
		flash_disp("REDISCANDO…", 60000)
		await get_tree().create_timer(sfx.dial("7") + 0.3).timeout
		sfx.play("sit")
		flash_disp("NÚMERO INVÁLIDO", 3200)
	else:
		var num := dial
		var into07: bool = board.plugs["sw"] == 7
		flash_disp("DISCANDO…", 60000)
		await get_tree().create_timer(sfx.dial(num if num != "" else "0") + 0.3).timeout
		var known := GameData.find_number(num)
		if into07 or known.is_empty():
			sfx.play("sit")
			flash_disp("NÚMERO NÃO EXISTE" if (into07 or num.contains("7")) else "NÚMERO INVÁLIDO", 3200)
		else:
			sfx.ringback(3)
			flash_disp("NINGUÉM ATENDE", 3200)
	dial = ""
	phase = "idle"
	if not note_shown:
		_note_gen += 1
		var g := _note_gen
		await get_tree().create_timer(6.0).timeout
		if g == _note_gen:
			_trigger_note()


# ================================================================ painel da chamada

func _add_line(who: String, text: String, cls: String) -> int:
	_t_lines.append({"who": who, "text": text, "cls": cls})
	_render_transcript()
	return _t_lines.size() - 1


func _sys(t: String) -> void:
	_add_line("", t, "sys")


func _render_transcript() -> void:
	var s := ""
	for l in _t_lines:
		match l["cls"]:
			"sys":
				s += "[color=#9a917a][font_size=13]%s[/font_size][/color]\n" % l["text"]
			"op":
				s += "[color=#8dbb6c]Você[/color]  %s\n" % l["text"]
			"ghost":
				s += "[color=#f3a83c]—[/color]  [color=#c6d3c4]%s[/color]\n" % l["text"]
			_:
				s += "[color=#f3a83c]%s[/color]  %s\n" % [l["who"], l["text"]]
	transcript.text = s


func say(c: Dictionary, text: String, tok: int, pause: float = 0.55) -> bool:
	var gv: bool = c["kind"] == "mystery"
	var li := _add_line(String(c.get("caller", "Solicitante")), "", "ghost" if gv else "")
	talking = true
	_update_call_ui()
	var paren := text.begins_with("(")
	var voice := "k" if paren else ("g" if gv else String(c["voice"]))
	var prev_vowel := false
	for i in text.length():
		if tok != token:
			talking = false
			_update_call_ui()
			return false
		var ch := text[i]
		_t_lines[li]["text"] += ch
		_render_transcript()
		prev_vowel = _voice_char(voice, text, i, prev_vowel, paren)
		var d := 0.062 if gv else (0.09 if ch in [",", "."] else 0.028)
		await get_tree().create_timer(d).timeout
	last_talk = Time.get_ticks_msec()
	await get_tree().create_timer(pause).timeout
	talking = false
	_update_call_ui()
	return tok == token


const VMAP := {"a": "a", "á": "a", "à": "a", "â": "a", "ã": "a", "e": "e", "é": "e", "ê": "e", "i": "i", "í": "i", "o": "o", "ó": "o", "ô": "o", "õ": "o", "u": "u", "ú": "u"}


## Dispara uma sílaba abafada a cada grupo de vogais (ritmo de fala, estilo Papers, Please).
func _voice_char(voice: String, text: String, i: int, prev_vowel: bool, laugh: bool) -> bool:
	var lc := text[i].to_lower()
	if not VMAP.has(lc):
		return false
	if not prev_vowel:
		var rise := laugh or (text.strip_edges().ends_with("?") and i > text.length() - 9)
		sfx.syllable(voice, VMAP[lc], rise)
	return true


func op(text: String, tok: int) -> bool:
	_add_line("Você", text, "op")
	sfx.play("click")
	last_talk = Time.get_ticks_msec()
	await get_tree().create_timer(0.75).timeout
	return tok == token


func wait(sec: float, tok: int) -> bool:
	await get_tree().create_timer(sec).timeout
	return tok == token


func _clear_choices() -> void:
	for ch in choices_box.get_children():
		ch.queue_free()


func _render_choices(list: Array) -> void:
	_clear_choices()
	for o in list:
		var b := Button.new()
		b.text = o["label"]
		b.add_theme_font_size_override("font_size", 13)
		var n := _sb(Color("1f2a1c"), Color.BLACK, 2, 8)
		var h := n.duplicate()
		h.bg_color = Color("2a3a25")
		var d := n.duplicate()
		d.bg_color = Color("161c14")
		b.add_theme_stylebox_override("normal", n)
		b.add_theme_stylebox_override("hover", h)
		b.add_theme_stylebox_override("pressed", h)
		b.add_theme_stylebox_override("disabled", d)
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(k, Color("cfe3bf"))
		b.add_theme_color_override("font_disabled_color", Color(0.81, 0.89, 0.75, 0.35))
		b.pressed.connect(o["fn"])
		choices_box.add_child(b)
	_update_call_ui()


func choose(opts: Array, tok: int) -> int:
	var list := []
	for i in opts.size():
		var k := i
		var fn := func():
			_clear_choices()
			choice_made.emit(k)
		list.append({"label": opts[i], "fn": fn})
	_render_choices(list)
	var r: int = await choice_made
	if tok != token:
		return -1
	return r


func _update_call_ui() -> void:
	var c := cur
	answer_btn.disabled = not (not c.is_empty() and c.get("ringing", false))
	hang_btn.disabled = not (not c.is_empty() and c.get("active", false))
	for b in choices_box.get_children():
		if b is Button and not b.is_queued_for_deletion():
			b.disabled = talking
	var line := "Nenhuma chamada"
	var st := ""
	if not c.is_empty() and not c.get("ended", false):
		line = "Linha %02d" % int(c["line"])
		if c.get("ringing", false):
			st = "tocando"
		elif phase == "dialing":
			st = "discando"
		elif phase == "await":
			st = "em linha" if board.plugs["fone"] == c["line"] else "aguardando conexão"
		else:
			st = "em linha"
	call_line_lbl.text = line
	call_state_lbl.text = st


# ================================================================ fluxo das ligações

func schedule_next() -> void:
	var i := idx + 1
	if i >= calls.size():
		return
	# O relógio nunca para: a ligação toca no horário previsto,
	# ou alguns minutos depois se o operador ainda estiver ocupado.
	next_at = maxf(float(calls[i]["at"]), minutes + randf_range(4.0, 8.0))
	if i == 4:
		var lead := clampf((next_at - minutes) / GAME_MIN_PER_SEC, 6.0, 25.0)
		sfx.fade(sfx.rain, -30.0, lead)
		sfx.fade(sfx.hum, -34.0, lead)


# Linhas conectadas ficam ocupadas enquanto a conversa dura.
func _update_line_timers() -> void:
	for n in 10:
		if lines[n] == "conn" and float(line_until[n]) >= 0.0 and minutes >= float(line_until[n]):
			lines[n] = "free"
			line_until[n] = -1.0
			sfx.play("sw", -8.0)


func ring(i: int) -> void:
	idx = i
	next_at = -1.0
	cur = calls[i]
	token += 1
	_t_lines.clear()
	_render_transcript()
	_clear_choices()
	for n in 10:
		if lines[n] in ["ring", "talk", "hold"]:
			lines[n] = "free"
	if cur["kind"] != "mystery":
		var free := []
		for n in range(1, 11):
			if lines[n - 1] == "free" and n != 7:
				free.append(n)
		if free.is_empty():
			free = [1, 2, 3, 4, 5, 6, 8, 9, 10]
		cur["line"] = free.pick_random()
		lines[int(cur["line"]) - 1] = "ring"
	else:
		# A ligação desconhecida chega pela linha 07, como qualquer outra.
		cur["line"] = 7
		line_until[6] = -1.0
		lines[6] = "ring"
	cur["ringing"] = true
	cur["time"] = fmt(minutes)
	if cur["kind"] == "mystery":
		myst_time = cur["time"]
		scrawl.set_lines(PackedStringArray([myst_time, "Linha 07", "NÃO ATENDER NOVAMENTE."]))
	sfx.ring_start()
	_update_call_ui()
	if cur["kind"] == "emergency":
		incident = {"street": cur["street"], "block": cur["block"], "req": cur["req"], "sent": [], "resolved": false, "addr": cur["addr"]}
	match i:
		0:
			hint("A lâmpada da linha %02d está piscando. Clique no plug [b]FONE[/b] e depois na tomada dessa linha." % int(cur["line"]))
		1:
			hint("Lembre: FONE na linha que pisca, depois Atender.")
		4:
			hint("")
			var tok := token
			await get_tree().create_timer(9.0).timeout
			if tok == token and cur.get("ringing", false) and not ending:
				warn("O telefone está tocando.")
		_:
			hint("")


func _tutorial_step() -> void:
	if cur.is_empty() or cur.get("ended", false) or idx != 0:
		return
	if cur.get("ringing", false) and board.plugs["fone"] == cur["line"]:
		hint("Agora clique em [b]Atender[/b].")
	elif phase == "await":
		if board.plugs["fone"] == cur["line"]:
			hint("Tire o plug do FONE da linha do solicitante (clique nele). A linha fica em espera.")
		elif board.plugs["sw"] == -1:
			hint("Leve o plug do [b]SWITCH[/b] até uma tomada livre (lâmpada apagada).")
		else:
			hint("Procure [b]%s[/b] na lista telefônica, digite o número e clique em [b]Discar[/b]." % String(cur["dest"]).split(" (")[0])


func answer() -> void:
	if cur.is_empty() or not cur.get("ringing", false):
		return
	if board.plugs["fone"] != cur["line"]:
		warn("Conecte o plug do FONE na tomada da linha que está piscando.")
		sfx.play("click")
		return
	cur["ringing"] = false
	cur["active"] = true
	sfx.ring_stop()
	sfx.play("sw")
	if int(cur["line"]) > 0:
		lines[int(cur["line"]) - 1] = "talk"
	sfx.fade(sfx.hiss, -26.0 if cur["kind"] == "mystery" else -36.0, 0.3)
	_update_call_ui()
	var tok := token
	match cur["kind"]:
		"transfer":
			run_transfer(cur, tok)
		"emergency":
			run_emergency(cur, tok)
		"prank":
			run_prank(cur, tok)
		"mystery":
			run_mystery(cur, tok)


func hangup() -> void:
	if cur.is_empty() or not cur.get("active", false):
		return
	sfx.play("sw")
	_add_line("Você", "(desliga)", "op")
	end_call("op")


# ---------------------------------------------------------------- transferência

const GREETINGS := ["Central, boa noite.", "Central telefônica, pois não?", "Central, boa noite. Em que posso ajudar?", "Central, pois não?", "Central."]


## Toda ligação começa igual: o operador não sabe o que vem do outro lado.
func _greet(tok: int) -> bool:
	if not await wait(0.3, tok):
		return false
	return await op(GREETINGS.pick_random(), tok)


func run_transfer(c: Dictionary, tok: int) -> void:
	if not await _greet(tok):
		return
	if not await wait(0.5, tok):
		return
	for l in c["open"]:
		if not await say(c, l, tok):
			return
	if randf() < 0.55:
		if not await say(c, GameData.SMALLTALK.pick_random(), tok, 0.45):
			return
	phase = "await"
	_update_call_ui()
	_tutorial_step()
	if idx == 1:
		hint("Consulte a lista. Confira o nome e o endereço.")
	_transfer_choices(c, tok)


func _transfer_choices(c: Dictionary, tok: int) -> void:
	var list := []
	if not c.get("said_wait", false):
		list.append({"label": "Um momento, vou conectar.", "fn": func(): _transfer_wait(c, tok)})
	list.append({"label": "Pode repetir, por favor?", "fn": func(): _transfer_repeat(c, tok)})
	_render_choices(list)


func _transfer_wait(c: Dictionary, tok: int) -> void:
	if talking:
		return
	c["said_wait"] = true
	_transfer_choices(c, tok)
	if not await op("Um momento, vou conectar.", tok):
		return
	await say(c, ["Tá bom, eu espero.", "Obrigado, aguardo.", "Certo."].pick_random(), tok)


func _transfer_repeat(c: Dictionary, tok: int) -> void:
	if talking:
		return
	if not await op("Pode repetir, por favor?", tok):
		return
	await say(c, c["repeat"], tok)


# ---------------------------------------------------------------- emergência

func run_emergency(c: Dictionary, tok: int) -> void:
	if not await _greet(tok):
		return
	if not await wait(0.3, tok):
		return
	if not await say(c, c["open"], tok, 0.3):
		return
	phase = "emerg"
	hint("Pergunte o que precisa. Marque o local no mapa e envie as unidades pelo despacho.")
	c["asked"] = []
	_emergency_choices(c, tok)


func _emergency_choices(c: Dictionary, tok: int) -> void:
	var list := []
	var qs: Array = c["q"]
	for i in qs.size():
		if i in c["asked"]:
			continue
		var k := i
		list.append({"label": qs[i][0], "fn": func(): _em_ask(c, tok, k)})
	if not c.get("dispatched", false):
		list.append({"label": "Fique na linha, vou enviar ajuda.", "fn": func(): _em_hold(c, tok)})
	_render_choices(list)


func _em_ask(c: Dictionary, tok: int, k: int) -> void:
	if talking or tok != token:
		return
	c["asked"].append(k)
	_emergency_choices(c, tok)
	if not await op(c["q"][k][0], tok):
		return
	await say(c, c["q"][k][1], tok)


func _em_hold(c: Dictionary, tok: int) -> void:
	if talking:
		return
	if not await op("Fique na linha, vou enviar ajuda.", tok):
		return
	await say(c, ["Rápido, por favor!", "Tá bom... tá bom."].pick_random(), tok)


func _emergency_dispatched() -> void:
	if cur.is_empty() or cur["kind"] != "emergency" or not cur.get("active", false) or cur.get("dispatched", false):
		return
	var c := cur
	var tok := token
	c["dispatched"] = true
	_emergency_choices(c, tok)
	while talking:
		if not await wait(0.2, tok):
			return
	if not await op("As unidades estão a caminho.", tok):
		return
	if not await say(c, c["after"], tok, 0.9):
		return
	_sys("(O solicitante desligou.)")
	end_call("caller")


# ---------------------------------------------------------------- trote

func run_prank(c: Dictionary, tok: int) -> void:
	if not await _greet(tok):
		return
	if not await wait(0.6, tok):
		return
	for st in c["steps"]:
		match st[0]:
			"c":
				if not await say(c, st[1], tok, 0.45):
					return
			"p":
				if not await wait(float(st[1]), tok):
					return
			"o":
				var i := await choose(st[1], tok)
				if i < 0:
					return
				if not await op(st[1][i], tok):
					return
			"end":
				sfx.play("cut")
				_sys("(A ligação foi encerrada do outro lado.)")
				if not await wait(0.5, tok):
					return
				end_call("caller")


# ---------------------------------------------------------------- a ligação misteriosa

func _op_line(l: String, tok: int) -> bool:
	var i := await choose([l], tok)
	if i < 0:
		return false
	return await op(l, tok)


func run_mystery(c: Dictionary, tok: int) -> void:
	c["caller"] = "—"
	if not await _greet(tok): return
	if not await wait(2.6, tok): return
	if not await say(c, "...alô?", tok, 0.7): return
	if not await _op_line("Central telefônica. Qual número você está tentando chamar?", tok): return
	if not await wait(2.2, tok): return
	if not await say(c, "Eu não sei.", tok): return
	if not await _op_line("Qual é o seu nome?", tok): return
	if not await wait(1.5, tok): return
	if not await say(c, "Eu estou tentando descobrir.", tok): return
	sfx.static_burst(2.0)
	if not await _op_line("Onde você está?", tok): return
	if not await wait(1.2, tok): return
	if not await say(c, "Eu não sei.", tok): return
	if not await _op_line("Você consegue me dizer alguma rua?", tok): return
	if not await wait(3.4, tok): return
	if not await say(c, "Tem uma luz.", tok, 0.6): return
	if not await _op_line("Que luz?", tok): return
	if not await wait(1.3, tok): return
	flick = true
	if not await say(c, "A luz da sua mesa.", tok, 2.6): return
	sfx.static_burst()
	if not await say(c, "Ela sempre fica acesa?", tok, 0.5): return
	end_call("mystery")


# ---------------------------------------------------------------- fim de chamada

func end_call(reason: String) -> void:
	if cur.is_empty() or cur.get("ended", false):
		return
	var c := cur
	token += 1
	choice_made.emit(-1)
	sfx.ring_stop()
	sfx.fade(sfx.hiss, -80.0, 0.2)
	_clear_choices()
	c["ended"] = true
	c["active"] = false
	c["ringing"] = false
	phase = "idle"
	talking = false
	if c["kind"] == "mystery":
		_mystery_aftermath()
	var my_idx := idx
	if reason == "connected":
		_release_later(2.0, my_idx, false)
	else:
		var ln := int(c["line"])
		if ln > 0 and lines[ln - 1] in ["talk", "hold", "ring"]:
			lines[ln - 1] = "free"
		_release_later(0.9, my_idx, false)
	if reason == "op":
		_sys("(Você encerrou a ligação.)")
	_update_call_ui()
	var where := "—"
	var unit := "—"
	var obs := ""
	match c["kind"]:
		"transfer":
			where = String(c["dest"]) if c.get("connected", false) else "—"
		"emergency":
			var same: bool = not sent.is_empty() and sent["call_idx"] == idx
			where = String(sent["loc"]) if same else String(c["addr"])
			unit = String(sent["units"]) if same else "—"
		"prank":
			where = c["fake"]
	if reason == "op":
		obs = "Encerrada pelo operador."
	elif c["kind"] == "transfer" and not c.get("connected", false):
		obs = "Não conectada."
	elif c["kind"] == "mystery":
		obs = "A ligação caiu."
	var who := "Desconhecido" if c["kind"] == "mystery" else String(c["caller"])
	pending = {"time": c["time"], "who": "%s (linha %02d)" % [who, int(c["line"])], "where": where, "unit": unit, "obs": obs, "kind": c["kind"]}
	_fill_pending()
	await get_tree().create_timer(1.5).timeout
	if not ending:
		set_tab("caderno")
		hint("Registre a ocorrência no caderno para continuar o turno.")


func _release_later(sec: float, my_idx: int, conn: bool) -> void:
	await get_tree().create_timer(sec).timeout
	if idx != my_idx:
		return
	if conn:
		pass
	board.return_all()
	_update_call_ui()


func _mystery_aftermath() -> void:
	sfx.play("cut")
	sfx.hum.volume_db = -80.0
	flick = false
	_sys("(A ligação caiu.)")
	after = true
	get_tree().create_timer(1.8).timeout.connect(func(): sfx.fade(sfx.hum, -32.0, 3.0))
	_note_gen += 1
	var g := _note_gen
	await get_tree().create_timer(45.0).timeout
	if g == _note_gen:
		_trigger_note()


func _trigger_note() -> void:
	if note_shown or ending:
		return
	while not pending.is_empty():
		await get_tree().create_timer(1.0).timeout
		if note_shown or ending:
			return
	if tab == "caderno":
		note_wanted = true
		await get_tree().create_timer(20.0).timeout
		if not note_shown:
			_show_note()
		return
	_show_note()


func _show_note() -> void:
	if note_shown:
		return
	note_shown = true
	note_wanted = false
	scrawl.visible = true
	if tab == "caderno":
		_note_seen()
	else:
		tab_dots["caderno"].visible = true
	await get_tree().create_timer(30.0).timeout
	_start_ending()


func _note_seen() -> void:
	if _seen_started:
		return
	_seen_started = true
	await get_tree().create_timer(7.5).timeout
	_start_ending()


func _start_ending() -> void:
	if ending:
		return
	ending = true
	sfx.fade(sfx.rain, -80.0, 5.0)
	sfx.fade(sfx.hum, -80.0, 5.0)
	sfx.fade(sfx.hiss, -80.0, 1.0)
	await get_tree().create_timer(5.0).timeout
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 3.0)
	await get_tree().create_timer(3.4).timeout
	create_tween().tween_property(fade_l1, "modulate:a", 1.0, 2.0)
	await get_tree().create_timer(2.6).timeout
	create_tween().tween_property(fade_l2, "modulate:a", 1.0, 2.5)
	await get_tree().create_timer(2.4).timeout
	fade_btn.visible = true
	create_tween().tween_property(fade_btn, "modulate:a", 1.0, 1.5)


# ================================================================ mapa e despacho

func _on_segment(street: String, block: int, label: String) -> void:
	map_sel = {"street": street, "block": block, "label": label}
	map_sel_lbl.text = label
	tab_dots["despacho"].visible = true
	_render_dispatch()


func _paper_label(txt: String, sz: int, col: Color = Pal.INK) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", Pal.mono)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l


func _paper_btn(txt: String, on: bool, sz: int = 20) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", Pal.mono)
	b.add_theme_font_size_override("font_size", sz)
	var n := _sb(Pal.INK if on else Color(0, 0, 0, 0), Pal.INK, 2, 10)
	var h := n.duplicate()
	h.bg_color = Pal.INK if on else Color(0, 0, 0, 0.08)
	var d := n.duplicate()
	d.bg_color = Color(0, 0, 0, 0)
	d.border_color = Color(Pal.INK, 0.35)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("disabled", d)
	var fg := Pal.PAPER if on else Pal.INK
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, fg)
	b.add_theme_color_override("font_disabled_color", Color(Pal.INK, 0.35))
	return b


func _render_dispatch() -> void:
	for ch in dispatch_box.get_children():
		ch.queue_free()
	var D := dispatch_box
	D.add_child(_paper_label("DESPACHO", 32))
	D.add_child(_paper_label("LOCAL:", 19, Pal.INK_SOFT))
	var lr := HBoxContainer.new()
	lr.add_theme_constant_override("separation", 14)
	lr.add_child(_paper_label(map_sel["label"] if not map_sel.is_empty() else "Marque o local no mapa", 24, Pal.INK if not map_sel.is_empty() else Pal.INK_SOFT))
	var om := _paper_btn("Abrir mapa", false, 17)
	om.pressed.connect(func(): set_tab("mapa"))
	lr.add_child(om)
	D.add_child(lr)
	D.add_child(_spacer(4))
	D.add_child(_paper_label("OCORRÊNCIA:", 19, Pal.INK_SOFT))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	for o in GameData.OCC:
		var b := _paper_btn(o, occ == o, 19)
		var oo: String = o
		b.pressed.connect(func():
			occ = oo
			sfx.play("click")
			_render_dispatch())
		chips.add_child(b)
	D.add_child(chips)
	D.add_child(_spacer(4))
	D.add_child(_paper_label("UNIDADES:", 19, Pal.INK_SOFT))
	for u in ["pol", "bomb", "amb"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var avail: bool = units[u] == "DISPONÍVEL"
		var b := _paper_btn("[ %s ]" % String(GameData.UNAME[u]).to_upper(), u in unit_sel, 21)
		b.custom_minimum_size = Vector2(200, 0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not avail
		var uu: String = u
		b.pressed.connect(func():
			if uu in unit_sel:
				unit_sel.erase(uu)
			else:
				unit_sel.append(uu)
			sfx.play("sw")
			_render_dispatch())
		row.add_child(b)
		row.add_child(_paper_label(units[u], 21, Pal.INK if avail else Color("8a3a14")))
		D.add_child(row)
	D.add_child(_spacer(4))
	var sr := HBoxContainer.new()
	sr.add_theme_constant_override("separation", 14)
	var send_b := _paper_btn("[ ENVIAR ]", true, 24)
	send_b.pressed.connect(_send)
	sr.add_child(send_b)
	var m := Label.new()
	m.text = dispatch_msg
	m.add_theme_color_override("font_color", Pal.INK_RED)
	m.add_theme_font_size_override("font_size", 13)
	m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sr.add_child(m)
	D.add_child(sr)
	if dispatch_report != "":
		D.add_child(_spacer(6))
		var rep := _paper_label(dispatch_report, 21)
		D.add_child(rep)


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _units_report(title: String) -> String:
	var s := title
	for u in ["pol", "bomb", "amb"]:
		if units[u] != "DISPONÍVEL":
			s += "\n%-12s %s" % [GameData.UNAME[u], units[u]]
	return s


func _send() -> void:
	if map_sel.is_empty():
		dispatch_msg = "Marque o local no mapa antes de enviar."
		_render_dispatch()
		return
	if unit_sel.is_empty():
		dispatch_msg = "Selecione ao menos uma unidade."
		_render_dispatch()
		return
	dispatch_msg = ""
	var target := map_sel.duplicate()
	var us := unit_sel.duplicate()
	sfx.play("sw")
	sfx.static_burst()
	var names := PackedStringArray()
	for u in us:
		units[u] = "EM DESLOCAMENTO"
		city.trip(u, target)
		names.append(GameData.UNAME[u])
	sent = {"call_idx": idx, "loc": target["label"], "units": ", ".join(names)}
	if pending.get("kind", "") == "emergency":
		pending["where"] = sent["loc"]
		pending["unit"] = sent["units"]
		_fill_pending()
	unit_sel.clear()
	dispatch_report = _units_report("UNIDADES ENVIADAS")
	_render_dispatch()
	_emergency_dispatched()
	await get_tree().create_timer(1.8).timeout
	radio(["Central, unidade a caminho.", "Central, recebido. Deslocando."].pick_random())
	await get_tree().create_timer(5.6).timeout
	_arrive(us, target)


func _arrive(us: Array, target: Dictionary) -> void:
	for u in us:
		units[u] = "NO LOCAL"
	dispatch_report = _units_report("SITUAÇÃO DAS UNIDADES")
	_refresh_dispatch()
	var msg := ""
	if incident.is_empty() or incident["resolved"]:
		msg = "Central, estamos no local. Nada a relatar. Retornando."
	elif incident["street"] != target["street"] or incident["block"] != target["block"]:
		msg = "Central, estamos na %s e não há nada aqui. Confirme o endereço." % String(target["label"]).split(",")[0]
	else:
		for u in us:
			if not u in incident["sent"]:
				incident["sent"].append(u)
		var miss := []
		for r in incident["req"]:
			if not r in incident["sent"]:
				miss.append(String(GameData.UNAME[r]).to_lower())
		if not miss.is_empty():
			msg = "Central, precisamos de %s aqui na %s." % [" e ".join(PackedStringArray(miss)), incident["addr"]]
		else:
			msg = "Central, equipe no local. Vítimas atendidas, situação sob controle."
			incident["resolved"] = true
	radio(msg)
	await get_tree().create_timer(12.0).timeout
	for u in us:
		if units[u] == "NO LOCAL":
			units[u] = "RETORNANDO"
	dispatch_report = _units_report("SITUAÇÃO DAS UNIDADES")
	_refresh_dispatch()
	await get_tree().create_timer(7.0).timeout
	for u in us:
		if units[u] == "RETORNANDO":
			units[u] = "DISPONÍVEL"
	city.remove_units(us)
	dispatch_report = _units_report("SITUAÇÃO DAS UNIDADES")
	if dispatch_report == "SITUAÇÃO DAS UNIDADES":
		dispatch_report = ""
	_refresh_dispatch()


func _refresh_dispatch() -> void:
	if tab == "despacho":
		_render_dispatch()


# ================================================================ rádio

func radio(t: String) -> void:
	_radio_q.append(t)
	if not _radio_busy:
		_radio_next()


func _radio_next() -> void:
	if _radio_q.is_empty():
		_radio_busy = false
		radio_led.color = Color("3a1a12")
		return
	_radio_busy = true
	var t: String = _radio_q.pop_front()
	radio_led.color = Pal.RED
	sfx.static_burst()
	await get_tree().create_timer(0.45).timeout
	radio_lbl.text = ""
	var rv := false
	for i in t.length():
		radio_lbl.text += t[i]
		rv = _voice_char("r", t, i, rv, false)
		await get_tree().create_timer(0.032).timeout
	sfx.static_burst(-2.0)
	await get_tree().create_timer(1.6).timeout
	radio_led.color = Color("3a1a12")
	await get_tree().create_timer(0.4).timeout
	_radio_next()


# ================================================================ caderno

func _render_ledger() -> void:
	var s := "[table=6]"
	for h in ["Horário", "Solicitante", "Local / destino", "Tipo", "Unidade", "Obs."]:
		s += "[cell padding=2,0,8,4][font=res://fonts/PixelifySans.ttf][font_size=12][color=#5a4d3a]%s[/color][/font_size][/font][/cell]" % h
	if entries.is_empty():
		s += "[/table]\n[font=res://fonts/PixelifySans.ttf][font_size=13][color=#5a4d3a]Nenhuma ocorrência registrada neste turno.[/color][/font_size][/font]"
	else:
		for r in entries:
			for k in ["time", "who", "where", "type", "unit", "obs"]:
				s += "[cell padding=2,2,8,2]%s[/cell]" % String(r[k]).replace("[", "(")
		s += "[/table]"
	ledger.text = s


func _fill_pending() -> void:
	if pending.is_empty():
		pending_box.visible = false
		tab_dots["caderno"].visible = false
		return
	pending_box.visible = true
	p_time.text = "Nova ocorrência · " + String(pending["time"])
	p_who.text = pending["who"]
	p_where.text = pending["where"]
	p_unit.text = pending["unit"]
	p_obs.text = pending["obs"]
	p_type.select(0)
	reg_msg.text = ""
	tab_dots["caderno"].visible = true


func _register() -> void:
	if pending.is_empty():
		return
	if p_type.selected <= 0:
		reg_msg.text = "Escolha o tipo da ocorrência."
		return
	entries.append({
		"time": pending["time"], "who": p_who.text, "where": p_where.text,
		"type": p_type.get_item_text(p_type.selected),
		"unit": p_unit.text if p_unit.text != "" else "—", "obs": p_obs.text if p_obs.text != "" else "—",
	})
	pending = {}
	sfx.play("pencil")
	_render_ledger()
	_fill_pending()
	hint("")
	await get_tree().create_timer(1.8).timeout
	schedule_next()


# ================================================================ abas

func set_tab(t: String) -> void:
	if tab == t:
		return
	var prev := tab
	tab = t
	for id in views:
		views[id].visible = id == t
	_style_tabs()
	sfx.play("page")
	if t == "despacho":
		_render_dispatch()
		tab_dots["despacho"].visible = false
	if t == "caderno":
		if pending.is_empty():
			tab_dots["caderno"].visible = false
		if note_shown:
			_note_seen()
	if prev == "caderno" and note_wanted:
		await get_tree().create_timer(1.2).timeout
		_show_note()
