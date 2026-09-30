extends Control
## Central de Vila Serena — cena principal.
## Monta a mesa do operador e conduz o turno: 5 ligações em sequência e o final.
##
## Loop: ATENDER → ENTENDER → CONSULTAR → CONECTAR/DESPACHAR → REGISTRAR → CONTINUAR

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
var others_lbl: Label
var transcript: RichTextLabel
var choices_box: HFlowContainer
var warn_lbl: Label
var answer_btn: Button
var hang_btn: Button
var transfer_btn: Button
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
const FILLER_GAP := 25.0        # minutos de jogo entre uma ligação extra e qualquer outra
const PEAK_CHANCE := 0.35       # chance de um pico (duas ou três linhas tocando juntas) no turno
const MYST_FROM := 240.0        # a ligação desconhecida toca em algum momento entre 02:00...
const MYST_TO := 450.0          # ...e 05:30 (minutos após 22:00)
const TALK_LEN := Vector2(45.0, 90.0)   # duração (min de jogo) de uma conversa transferida
const GIVE_UP_SEC := 60.0      # ligações extras desistem se ninguém atende (as principais aguentam 1,5x)
var line_until: Array = []
var myst_time := "02:13"
var sched: Array = []           # ligações ainda por tocar, em ordem de horário
var live: Array = []            # ligações tocando ou em andamento (podem ser várias ao mesmo tempo)
var shown: Dictionary = {}      # ligação exibida no painel do telefone
var tut: Dictionary = {}        # primeira ligação: guia passo a passo
var em_call: Dictionary = {}
var lines: Array = []
var dests := {}                 # número de destino (int) -> "free" / "ring" / "conn" / "done"
var _dgen := {}
var _taught_done := false
var _taught_multi := false
var _taught_info := false
var _myst_lead := false
var _calling_back := false
var disp_until := 0
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
var pending_q: Array = []
var after := false
var note_shown := false
var note_wanted := false
var ending := false
var flick := false
var _note_gen := 0
var _closing := false
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
	for d in GameData.DIR:
		if d["s"] != "use o despacho":
			dests[int(d["num"])] = "free"
	var mains := [
		_mk(GameData.T1.pick_random(), "transfer", 0),
		_mk(GameData.T2.pick_random(), "transfer", 1),
		_mk(GameData.EM.pick_random(), "emergency", 2),
		_mk(GameData.TR.pick_random(), "prank", 3),
		_mk({}, "mystery", -1),
	]
	var myst: Dictionary = mains[4]
	myst["at"] = randf_range(MYST_FROM, MYST_TO)
	myst["latest"] = float(myst["at"]) + 30.0   # não espera a mesa silenciar para sempre
	tut = mains[0]
	sched = mains + _fillers(mains)
	sched.sort_custom(func(a, b): return a["at"] < b["at"])
	sfx = Sfx.new()
	add_child(sfx)
	_build()


func _mk(src: Dictionary, kind: String, i: int) -> Dictionary:
	var c: Dictionary = src.duplicate(true)
	c["kind"] = kind
	c["t_lines"] = []
	c["opts"] = []
	if i >= 0:
		c["main"] = i
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
	board.dests = dests
	board.sfx = sfx
	add_child(board)
	board.end_changed.connect(_on_end_changed)
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
	var ph := _bevel(Vector2(24, 446), Vector2(588, 262))
	var dbg := ColorRect.new()
	dbg.color = Color("120d07")
	dbg.position = Vector2(100, 12)   # à esquerda fica o encaixe do FONE, desenhado pela mesa
	dbg.size = Vector2(180, 36)
	ph.add_child(dbg)
	disp_lbl = _label(dbg, "", Vector2(6, 0), 22, Pal.AMBER, Pal.mono, 168)
	disp_lbl.size = Vector2(168, 36)
	disp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	disp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disp_lbl.clip_text = true
	call_line_lbl = _label(ph, "Nenhuma chamada", Vector2(292, 12), 13, Pal.DIM)
	call_state_lbl = _label(ph, "", Vector2(292, 12), 13, Pal.DIM, null, 280)
	call_state_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	others_lbl = _label(ph, "", Vector2(292, 32), 12, Pal.AMBER, null, 280)
	var tp := PanelContainer.new()
	tp.position = Vector2(16, 58)
	tp.size = Vector2(556, 110)
	tp.add_theme_stylebox_override("panel", _sb(Color("0f0d09"), Color.BLACK, 2, 8))
	ph.add_child(tp)
	transcript = RichTextLabel.new()
	transcript.bbcode_enabled = true
	transcript.scroll_following = true
	transcript.custom_minimum_size = Vector2(538, 100)
	transcript.add_theme_color_override("default_color", Pal.TEXT)
	transcript.add_theme_font_size_override("normal_font_size", 14)
	transcript.add_theme_constant_override("line_separation", 2)
	tp.add_child(transcript)
	choices_box = HFlowContainer.new()
	choices_box.position = Vector2(16, 174)
	choices_box.size = Vector2(556, 44)
	choices_box.add_theme_constant_override("h_separation", 6)
	choices_box.add_theme_constant_override("v_separation", 6)
	ph.add_child(choices_box)
	warn_lbl = _label(ph, "", Vector2(16, 222), 12, Pal.AMBER, null, 176)
	warn_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warn_lbl.size = Vector2(176, 36)
	answer_btn = _button(ph, "Atender", Vector2(200, 222), Vector2(118, 32), Pal.GREEN, Color("1c150c"), Color("5b7e44"))
	answer_btn.add_theme_font_size_override("font_size", 16)
	answer_btn.pressed.connect(answer)
	answer_btn.disabled = true
	transfer_btn = _button(ph, "Transferir", Vector2(324, 222), Vector2(118, 32), Pal.AMBER, Color("1c150c"), Color("a86b1d"))
	transfer_btn.add_theme_font_size_override("font_size", 16)
	transfer_btn.pressed.connect(transfer)
	transfer_btn.disabled = true
	hang_btn = _button(ph, "Desligar", Vector2(448, 222), Vector2(124, 32), Pal.RED, Color("1c150c"), Color("8e3526"))
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
	var info := _label(card, "Tudo acontece na sua mesa. Use o mouse para levar os plugues até as tomadas e para consultar a lista, o mapa e o caderno. Mais de uma linha pode tocar ao mesmo tempo. Use fones de ouvido.", Vector2(40, 238), 14, Pal.DIM, null, 480)
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
	radio("Central, viatura 2 em ronda. Tudo tranquilo.")
	hint("Aguarde as chamadas. A lista, o mapa, o despacho e o caderno ficam nas abas acima.")


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
		_run_schedule()
		_update_line_timers()
		# o turno só fecha depois da linha 07 ter tocado e caído
		if minutes >= SHIFT_END and after and not _closing:
			_closing = true
			_close_shift()
		clock_lbl.text = fmt(minutes)
		# quem está na linha com o operador reclama da demora
		var f := _focus()
		if not f.is_empty() and f.get("active", false) and not f.get("talking", false):
			var quiet: int = now - int(f.get("last_talk", now))
			if f["kind"] == "transfer" and f.get("phase", "") == "await" and quiet > 22000:
				f["last_talk"] = now
				say(f, GameData.WAITING.pick_random())
			elif f["kind"] == "emergency" and not f.get("dispatched", false) and quiet > 26000:
				f["last_talk"] = now
				say(f, GameData.EM_WAITING.pick_random())
	if disp_until > 0 and now > disp_until:
		disp_until = 0
		_render_disp()
	bg.flick = flick
	glow.modulate.a = bg.lamp_level
	_frame += 1


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE and board.held != -1:
		board.go_home(board.held)


func hint(t: String) -> void:
	hint_lbl.text = "" if t == "" else "[bgcolor=#b8924e][color=#1a150d] MANUAL [/color][/bgcolor]  " + t


func warn(t: String) -> void:
	warn_lbl.text = t
	_warn_gen += 1
	var g := _warn_gen
	await get_tree().create_timer(4.0).timeout
	if g == _warn_gen:
		warn_lbl.text = ""


func _render_disp() -> void:
	if Time.get_ticks_msec() < disp_until:
		return
	disp_lbl.text = ""


func flash_disp(t: String, ms: int = 2600) -> void:
	disp_lbl.text = t
	disp_until = Time.get_ticks_msec() + ms


# ================================================================ mesa comutadora

## Destino ligado à SAÍDA da linha n pelo cabo de conexão (-1 se não houver).
func _dest_of_line(n: int) -> int:
	var e := board.cord_at(n + 10)
	if e == -1:
		return -1
	var j: int = board.ends[board.mate(e)]
	return j if j > 20 else -1


## A ligação em que o operador está: a da entrada onde o FONE está.
func _focus() -> Dictionary:
	return _call_on_line(board.fone_line())


func _call_on_line(j: int) -> Dictionary:
	for c in live:
		if int(c["line"]) == j:
			return c
	return {}


func _on_end_changed(e: int, j: int, prev: int) -> void:
	if prev != -1:
		_vacated(prev, e)
	if j != -1:
		_filled(j, e)
	_tutorial_step()
	_refresh_panel()


## FONE numa entrada: a ligação dessa linha passa a ser a do operador.
func _filled(j: int, e: int) -> void:
	if e != 0:
		return
	if j == 7 and after:
		_callback_07()
	var c := _call_on_line(j)
	if c.get("active", false) and lines[j - 1] == "hold":
		lines[j - 1] = "talk"


## Um plug saiu da tomada j.
func _vacated(j: int, e: int) -> void:
	if e == 0:
		# FONE saiu: se o destino já atendeu, a ligação segue pelo cabo de conexão; senão fica em espera.
		var c := _call_on_line(j)
		if c.get("active", false):
			if not _try_complete(c):
				lines[j - 1] = "hold"
				_sys(c, "(Em espera.)")
		elif c.is_empty():
			_maybe_free(j)
		return
	var other: int = board.ends[board.mate(e)]
	if j <= 20:
		# saiu da SAÍDA da linha n
		var n := j - 10
		var c := _call_on_line(n)
		if c.get("active", false):
			if other > 20:
				_cut_dest(c, other)
		else:
			if lines[n - 1] == "conn":
				lines[n - 1] = "done"   # a conversa foi cortada
				line_until[n - 1] = -1.0
				if other > 20 and dests[other] == "conn":
					dests[other] = "done"
			_maybe_free(n)
		return
	# saiu do destino j
	var st: String = dests[j]
	dests[j] = "free"
	_dgen[j] = int(_dgen.get(j, 0)) + 1
	if st == "free":
		return
	sfx.play("sw")
	if other >= 11 and other <= 20:
		var n := other - 10
		var c := _call_on_line(n)
		if c.get("active", false):
			_sys(c, "(Chamada para %d cancelada.)" % j if st == "ring" else "(%d desconectado.)" % j)
			disp_until = 0
			_render_disp()
		elif lines[n - 1] == "conn":
			lines[n - 1] = "done"
			line_until[n - 1] = -1.0


## Cabo tirado da SAÍDA no meio de uma transferência: o destino para de tocar ou cai.
func _cut_dest(c: Dictionary, d: int) -> void:
	if dests[d] == "ring":
		dests[d] = "free"
		_dgen[d] = int(_dgen.get(d, 0)) + 1
		_sys(c, "(Chamada para %d cancelada.)" % d)
	elif dests[d] == "conn":
		dests[d] = "done"
		_sys(c, "(%d desconectado.)" % d)


## Linha sem ligação e sem plugs volta a ficar livre.
func _maybe_free(n: int) -> void:
	if lines[n - 1] in ["conn", "done"] and board.cord_at(n) == -1 and board.cord_at(n + 10) == -1 and _call_on_line(n).is_empty():
		lines[n - 1] = "free"
		line_until[n - 1] = -1.0
		sfx.play("sw")


## Botão Transferir: chama o destino ligado à SAÍDA da linha em que o FONE está.
func transfer() -> void:
	var c := _focus()
	if c.is_empty() or not c.get("active", false):
		warn("Leve o FONE até a entrada da ligação que você quer transferir.")
		return
	if c["kind"] != "transfer":
		warn("Esse solicitante não pediu transferência.")
		return
	if c.get("phase", "") != "await":
		warn("Ouça o pedido do solicitante antes de transferir.")
		return
	var n := int(c["line"])
	var d := _dest_of_line(n)
	if d == -1:
		warn("Ligue um cabo de conexão da SAÍDA %02d até o número de destino." % n)
		return
	if dests[d] != "free":
		warn("O %d já está tocando ou em conversa." % d)
		return
	sfx.play("key")
	_ring_dest(c, d)


## O destino toca; se o cabo sair da tomada ou a chamada cair, para de tocar.
func _ring_dest(c: Dictionary, d: int) -> void:
	_dgen[d] = int(_dgen.get(d, 0)) + 1
	var g: int = _dgen[d]
	var right: bool = str(d) == String(c["target"])
	var closed: bool = d in GameData.CLOSED
	dests[d] = "ring"
	flash_disp("%d TOCANDO" % d, 60000)
	_tutorial_step()
	_update_call_ui()
	for i in (4 if closed else (2 if right else 3)):
		if is_same(_focus(), c):
			sfx.play("ringback")
		if not await wait(c, 2.0) or _dgen[d] != g:
			return
	if closed:
		dests[d] = "free"
		flash_disp("%d SEM RESPOSTA" % d, 3000)
		_sys(c, "(Ninguém atende no %d.)" % d)
		if right:
			c["no_answer"] = true
			_transfer_choices(c)
		_update_call_ui()
		return
	dests[d] = "conn"
	sfx.play("sw")
	flash_disp("%d CONECTADO" % d, 3000)
	var who: String = GameData.find_number(str(d))["n"]
	_tutorial_step()
	_update_call_ui()
	if _try_complete(c):
		return
	if right:
		_sys(c, "(%s atendeu.)" % who)
		await say(c, c["thanks"], 0.4)
	else:
		_sys(c, "(Atendeu: %s. Não é quem o solicitante pediu.)" % who)
		if await say(c, GameData.WRONG_DEST.pick_random()) and c.get("main", -1) in [0, 1]:
			hint("Tire a ponta do cabo desse destino. Confira o nome e o endereço na lista: há nomes parecidos.")


## Destino atendeu e o FONE saiu da entrada: os dois lados seguem conectados pelo cabo de conexão.
func _try_complete(c: Dictionary) -> bool:
	var ln := int(c["line"])
	if c.get("ended", false) or c["kind"] != "transfer" or not c.get("active", false) or board.fone_line() == ln:
		return false
	var d := _dest_of_line(ln)
	if d == -1 or dests[d] != "conn":
		return false
	lines[ln - 1] = "conn"
	line_until[ln - 1] = minutes + randf_range(TALK_LEN.x, TALK_LEN.y)
	c["connected"] = true
	c["dest_num"] = d
	_sys(c, "(Você tirou o fone. %02d e %d seguem conectados.)" % [ln, d])
	flash_disp("%02d - %d" % [ln, d], 2600)
	end_call(c, "connected")
	return true


## Depois da linha 07: FONE na entrada 07 tenta ligar de volta.
func _callback_07() -> void:
	if _calling_back:
		return
	_calling_back = true
	flash_disp("LINHA 07…", 60000)
	sfx.play("ringback")
	await get_tree().create_timer(2.2).timeout
	sfx.static_burst(2.0)
	sfx.play("sit")
	flash_disp("NÚMERO NÃO EXISTE", 3200)
	_calling_back = false
	if not note_shown:
		_note_gen += 1
		var g := _note_gen
		await get_tree().create_timer(6.0).timeout
		if g == _note_gen:
			_trigger_note()


func _show_line_info(n: int) -> void:
	if n > 10 and n <= 20:
		var d := _dest_of_line(n - 10)
		board.show_info(PackedStringArray(["SAÍDA %02d" % (n - 10), "LIVRE" if board.cord_at(n) == -1 else ("PARA %d" % d if d != -1 else "CABO SEM DESTINO")]), false, n)
		sfx.play("click")
		return
	if n > 20:
		board.show_info(PackedStringArray(["NÚMERO %d" % n, String(GameData.DEST_LABEL[dests[n]]).to_upper()]), false, n)
		sfx.play("click")
		return
	var st: String = lines[n - 1]
	if n == 7 and after and st == "free":
		# A linha está livre, mas guarda o registro da última chamada.
		board.show_info(PackedStringArray(["LINHA 07", "LIVRE", "ÚLTIMA ORIGEM: ???", "NÚMERO: ???", "DURAÇÃO: " + myst_time]), true, n)
		sfx.static_burst()
	else:
		var a := PackedStringArray(["LINHA %02d" % n, String(GameData.LINE_LABEL[st]).to_upper()])
		if board.fone_line() == n:
			a.append("FONE CONECTADO")
		board.show_info(a, false, n)
		sfx.play("click")


# ================================================================ painel da chamada
# O painel mostra a ligação do par com FALAR. As outras continuam tocando ou em espera.

func _refresh_panel() -> void:
	var f := _focus()
	if not f.is_empty() and not is_same(f, shown):
		shown = f
		_render_transcript()
	_render_choices()
	if not f.is_empty() and f.get("active", false):
		sfx.fade(sfx.hiss, -26.0 if f["kind"] == "mystery" else -36.0, 0.3)
	else:
		sfx.fade(sfx.hiss, -80.0, 0.2)
	_update_call_ui()


func _add_line(c: Dictionary, who: String, text: String, cls: String) -> int:
	c["t_lines"].append({"who": who, "text": text, "cls": cls})
	if is_same(c, shown):
		_render_transcript()
	return c["t_lines"].size() - 1


func _sys(c: Dictionary, t: String) -> void:
	_add_line(c, "", t, "sys")


func _render_transcript() -> void:
	var s := ""
	for l in shown.get("t_lines", []):
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


## Espera o operador estar na linha dessa ligação. Falso se ela terminar antes.
func _until_focused(c: Dictionary) -> bool:
	while not (c.get("active", false) and is_same(_focus(), c)):
		if c.get("ended", false):
			return false
		await get_tree().process_frame
	return true


func say(c: Dictionary, text: String, pause: float = 0.55) -> bool:
	if not await _until_focused(c):
		return false
	var gv: bool = c["kind"] == "mystery"
	var li := _add_line(c, String(c.get("caller", "Solicitante")), "", "ghost" if gv else "")
	c["talking"] = true
	_update_call_ui()
	var paren := text.begins_with("(")
	var voice := "k" if paren else ("g" if gv else String(c["voice"]))
	var prev_vowel := false
	for i in text.length():
		# em espera, a pessoa para de falar até o operador voltar
		if not is_same(_focus(), c) and not await _until_focused(c):
			c["talking"] = false
			_update_call_ui()
			return false
		var ch := text[i]
		c["t_lines"][li]["text"] += ch
		if is_same(c, shown):
			_render_transcript()
		prev_vowel = _voice_char(voice, text, i, prev_vowel, paren)
		var d := 0.062 if gv else (0.09 if ch in [",", "."] else 0.028)
		await get_tree().create_timer(d).timeout
	c["last_talk"] = Time.get_ticks_msec()
	await get_tree().create_timer(pause).timeout
	c["talking"] = false
	_update_call_ui()
	return not c.get("ended", false)


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


func op(c: Dictionary, text: String) -> bool:
	if not await _until_focused(c):
		return false
	_add_line(c, "Você", text, "op")
	sfx.play("click")
	c["last_talk"] = Time.get_ticks_msec()
	await get_tree().create_timer(0.75).timeout
	return not c.get("ended", false)


func wait(c: Dictionary, sec: float) -> bool:
	await get_tree().create_timer(sec).timeout
	return not c.get("ended", false)


func _set_opts(c: Dictionary, list: Array) -> void:
	c["opts"] = list
	if is_same(c, shown):
		_render_choices()


func _render_choices() -> void:
	for ch in choices_box.get_children():
		ch.queue_free()
	if shown.is_empty() or not is_same(_focus(), shown):
		return
	for o in shown.get("opts", []):
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
		b.disabled = shown.get("talking", false)
		b.pressed.connect(o["fn"])
		choices_box.add_child(b)


func choose(c: Dictionary, opts: Array) -> int:
	c["pick"] = -1
	var list := []
	for i in opts.size():
		var k := i
		var fn := func():
			c["pick"] = k
			_set_opts(c, [])
		list.append({"label": opts[i], "fn": fn})
	_set_opts(c, list)
	while int(c["pick"]) == -1:
		if c.get("ended", false):
			return -1
		await get_tree().process_frame
	return int(c["pick"])


func _update_call_ui() -> void:
	var f := _focus()
	answer_btn.disabled = f.is_empty() or not f.get("ringing", false)
	hang_btn.disabled = f.is_empty() or not f.get("active", false)
	transfer_btn.disabled = f.is_empty() or not f.get("active", false) or f["kind"] != "transfer" or f.get("phase", "") != "await"
	for b in choices_box.get_children():
		if b is Button and not b.is_queued_for_deletion():
			b.disabled = shown.get("talking", false)
	var line := "Nenhuma chamada"
	var st := ""
	if not shown.is_empty():
		line = "Linha %02d" % int(shown["line"])
		if shown.get("ended", false):
			st = "encerrada"
		elif not is_same(f, shown):
			st = "tocando" if shown.get("ringing", false) else "em espera"
		elif shown.get("ringing", false):
			st = "tocando"
		else:
			st = "em linha"
			var d := _dest_of_line(int(shown["line"]))
			if shown["kind"] == "transfer" and d != -1 and dests[d] in ["ring", "conn"]:
				st = "chamando %d" % d if dests[d] == "ring" else "%d atendeu" % d
	call_line_lbl.text = line
	call_state_lbl.text = st
	var o := PackedStringArray()
	for c in live:
		if not is_same(c, shown):
			o.append("%02d %s" % [int(c["line"]), "tocando" if c.get("ringing", false) else "em espera"])
	others_lbl.text = "" if o.is_empty() else "Outras linhas: " + ", ".join(o)


# ================================================================ agenda das ligações

## Ligações extras em horários aleatórios, espaçadas das outras (FILLER_GAP) para a mesa
## respirar. De vez em quando vem um pico: uma extra logo depois de uma principal (duas linhas
## juntas) e, mais raro, outra em seguida (três).
func _fillers(mains: Array) -> Array:
	var pool := []
	for t in GameData.T1 + GameData.T2 + GameData.FILL:
		if not mains.any(func(m): return m.get("caller", "") == t["caller"]):
			pool.append(t)
	pool.shuffle()
	var taken := []
	for m in mains:
		taken.append(float(m["at"]))
	var ats := []
	for i in randi_range(5, 7):   # espalhadas pelo turno todo, antes e depois da linha 07
		for _try in 40:
			var at := randf_range(12.0, SHIFT_END - 10.0)
			if taken.all(func(x): return absf(at - x) >= FILLER_GAP):
				ats.append(at)
				taken.append(at)
				break
	if randf() < PEAK_CHANCE:
		var base: float = [38.0, 84.0, 170.0].pick_random()
		ats.append(base + randf_range(2.0, 5.0))
		if randf() < 0.4:
			ats.append(base + randf_range(5.0, 9.0))
	var out := []
	for at in ats:
		var c: Dictionary
		if randf() < 0.65 and not pool.is_empty():
			c = _mk(pool.pop_back(), "transfer", -1)
		else:
			c = _mk(_info_call(), "info", -1)
		c["at"] = at
		c["filler"] = true
		out.append(c)
	return out


func _info_call() -> Dictionary:
	var v: Array = GameData.INFO_VOICES.pick_random()
	if randf() < 0.7:
		var t: Array = GameData.INFO_NUM.pick_random()
		return {"voice": v[0], "caller": v[1], "what": "num", "about": t[0], "answer": t[1],
			"ask": String(GameData.ASK_NUM.pick_random()) % ("d" + String(t[0]))}
	return {"voice": v[0], "caller": v[1], "what": "time", "ask": GameData.ASK_TIME.pick_random()}


func _free_line() -> int:
	var free := []
	for n in range(1, 11):
		if n != 7 and lines[n - 1] == "free" and board.cord_at(n) == -1 and board.cord_at(n + 10) == -1:
			free.append(n)
	return -1 if free.is_empty() else free.pick_random()


func _run_schedule() -> void:
	if sched.is_empty():
		return
	for m in sched:
		if m["kind"] == "mystery" and not _myst_lead and minutes >= float(m["at"]) - 20.0:
			_myst_lead = true
			sfx.fade(sfx.rain, -30.0, 20.0)
			sfx.fade(sfx.hum, -34.0, 20.0)
	var c: Dictionary = sched[0]
	if minutes < float(c["at"]):
		return
	# A ligação desconhecida só toca com a mesa em silêncio; as outras esperam uma entrada livre.
	var hush: bool = c["kind"] == "mystery" and not live.is_empty() and minutes < float(c["latest"])
	if hush or (c["kind"] != "mystery" and _free_line() == -1):
		c["at"] = minutes + 3.0
		sched.sort_custom(func(a, b): return a["at"] < b["at"])
		return
	sched.pop_front()
	ring(c)


# Conexões completadas duram um tempo; depois alguém desliga e a mesa mostra "desligou".
func _update_line_timers() -> void:
	for n in 10:
		if lines[n] == "conn" and float(line_until[n]) >= 0.0 and minutes >= float(line_until[n]):
			lines[n] = "done"
			line_until[n] = -1.0
			var d := _dest_of_line(n + 1)
			if d != -1 and dests[d] == "conn":
				dests[d] = "done"
			sfx.play("sw", -8.0)
			if not _taught_done and live.is_empty():
				_taught_done = true
				hint("Lâmpadas vermelhas: a conversa terminou. Tire as duas pontas do cabo de conexão para liberar a linha e o cabo.")


func _update_bell() -> void:
	if live.any(func(c): return c.get("ringing", false)):
		sfx.ring_start()
	else:
		sfx.ring_stop()


func ring(c: Dictionary) -> void:
	var busy := not live.is_empty()
	c["line"] = 7 if c["kind"] == "mystery" else _free_line()
	var ln := int(c["line"])
	line_until[ln - 1] = -1.0
	lines[ln - 1] = "ring"
	c["ringing"] = true
	c["time"] = fmt(minutes)
	live.append(c)
	if c["kind"] == "mystery":
		myst_time = c["time"]
		scrawl.set_lines(PackedStringArray([myst_time, "Linha 07", "NÃO ATENDER NOVAMENTE."]))
	if c["kind"] == "emergency":
		em_call = c
		incident = {"street": c["street"], "block": c["block"], "req": c["req"], "sent": [], "resolved": false, "addr": c["addr"]}
	_update_bell()
	_refresh_panel()
	if is_same(c, tut):
		hint("A lâmpada da entrada %02d está piscando. Arraste o [b]FONE[/b] (cabo vermelho, no telefone) até a tomada dessa entrada." % ln)
	elif busy and not _taught_multi:
		_taught_multi = true
		hint("Outra entrada chamando! Leve o [b]FONE[/b] até ela: a ligação atual fica em espera. Para voltar, leve o FONE de volta à entrada dela.")
	elif c.get("main", -1) == 1:
		hint("Lembre: FONE na entrada que pisca, depois Atender.")
	if c["kind"] == "mystery":
		await get_tree().create_timer(9.0).timeout
		if c.get("ringing", false) and not ending:
			warn("O telefone está tocando.")
	elif not is_same(c, tut):
		await get_tree().create_timer(GIVE_UP_SEC * (1.0 if c.get("filler", false) else 1.5)).timeout
		if c.get("ringing", false):
			end_call(c, "missed")


func _tutorial_step() -> void:
	var c := tut
	if not c.has("line") or c.get("ended", false):
		return
	var n := int(c["line"])
	if c.get("ringing", false):
		if board.fone_line() == n:
			hint("Agora clique em [b]Atender[/b] para falar com quem ligou.")
		return
	if c.get("phase", "") != "await" or board.fone_line() != n:
		return
	var dest := String(c["dest"]).split(" (")[0]
	var d := _dest_of_line(n)
	if board.cord_at(n + 10) == -1:
		hint("Procure [b]%s[/b] na lista. Pegue um [b]cabo de conexão[/b] na base e ligue uma ponta na [b]SAÍDA %02d[/b], logo abaixo da entrada." % [dest, n])
	elif d == -1:
		hint("Leve a outra ponta desse cabo até o número de [b]%s[/b], na fileira de destinos." % dest)
	elif dests[d] == "free":
		hint("Clique em [b]Transferir[/b] para chamar o destino.")
	elif dests[d] == "ring":
		hint("O destino está tocando. Aguarde atender.")
	else:
		hint("O destino atendeu. Tire o [b]FONE[/b] da entrada (devolva ao telefone): a ligação continua pelo cabo de conexão.")


func answer() -> void:
	var c := _focus()
	if c.is_empty() or not c.get("ringing", false):
		warn("Leve o FONE até a entrada que está piscando.")
		sfx.play("click")
		return
	c["ringing"] = false
	c["active"] = true
	c["last_talk"] = Time.get_ticks_msec()
	_update_bell()
	sfx.play("sw")
	lines[int(c["line"]) - 1] = "talk"
	_refresh_panel()
	match c["kind"]:
		"transfer":
			run_transfer(c)
		"emergency":
			run_emergency(c)
		"prank":
			run_prank(c)
		"info":
			run_info(c)
		"mystery":
			run_mystery(c)


func hangup() -> void:
	var c := _focus()
	if c.is_empty() or not c.get("active", false):
		return
	sfx.play("sw")
	_add_line(c, "Você", "(desliga)", "op")
	end_call(c, "op")


# ---------------------------------------------------------------- transferência

const GREETINGS := ["Central, boa noite.", "Central telefônica, pois não?", "Central, boa noite. Em que posso ajudar?", "Central, pois não?", "Central."]


## Toda ligação começa igual: o operador não sabe o que vem do outro lado.
func _greet(c: Dictionary) -> bool:
	if not await wait(c, 0.3):
		return false
	return await op(c, GREETINGS.pick_random())


func run_transfer(c: Dictionary) -> void:
	if not await _greet(c):
		return
	if not await wait(c, 0.5):
		return
	for l in c["open"]:
		if not await say(c, l):
			return
	if randf() < 0.55:
		if not await say(c, GameData.SMALLTALK.pick_random(), 0.45):
			return
	c["phase"] = "await"
	_update_call_ui()
	_tutorial_step()
	if board.free_patches() == 0 and board.cord_at(int(c["line"]) + 10) == -1:
		hint("Não há cabos de conexão livres. Desmonte uma conexão encerrada (lâmpadas vermelhas).")
	elif c.get("main", -1) == 1:
		hint("Consulte a lista. Confira o nome e o endereço.")
	_transfer_choices(c)


func _transfer_choices(c: Dictionary) -> void:
	var list := []
	if not c.get("said_wait", false):
		list.append({"label": "Um momento, vou conectar.", "fn": func(): _transfer_wait(c)})
	list.append({"label": "Pode repetir, por favor?", "fn": func(): _transfer_repeat(c)})
	if c.get("no_answer", false) and c.has("alt") and not c.get("alt_done", false):
		list.append({"label": c["alt_ask"], "fn": func(): _transfer_alt(c)})
	_set_opts(c, list)


func _transfer_wait(c: Dictionary) -> void:
	if c.get("talking", false):
		return
	c["said_wait"] = true
	_transfer_choices(c)
	if not await op(c, "Um momento, vou conectar."):
		return
	await say(c, GameData.HOLD_OK.pick_random())


func _transfer_repeat(c: Dictionary) -> void:
	if c.get("talking", false):
		return
	if not await op(c, "Pode repetir, por favor?"):
		return
	await say(c, c["repeat"])


## O lugar pedido não atende à noite: o operador sugere outro.
func _transfer_alt(c: Dictionary) -> void:
	if c.get("talking", false):
		return
	c["alt_done"] = true
	c["target"] = c["alt"]
	c["dest"] = c["alt_dest"]
	c["repeat"] = String(c["alt_dest"]) + "."
	_transfer_choices(c)
	if not await op(c, c["alt_ask"]):
		return
	await say(c, c["alt_yes"])


# ---------------------------------------------------------------- informação

func run_info(c: Dictionary) -> void:
	if not await _greet(c):
		return
	if not await wait(c, 0.4):
		return
	if not await say(c, c["ask"]):
		return
	var right := ""
	var opts := []
	if c["what"] == "num":
		right = "É o %s." % c["answer"]
		opts = [right]
		while opts.size() < 3:
			var o := "É o %s." % String(GameData.DIR.pick_random()["num"])
			if not o in opts:
				opts.append(o)
	else:
		right = "São %s." % fmt(minutes)
		opts = [right, "São %s." % fmt(minutes + 60.0), "São %s." % fmt(minutes - 45.0)]
	opts.shuffle()
	c["phase"] = "info"
	if not _taught_info:
		_taught_info = true
		hint("Pedido de informação: confira a lista telefônica (ou o relógio) antes de responder.")
	var i := await choose(c, opts)
	if i < 0 or not await op(c, opts[i]):
		return
	c["info_ok"] = opts[i] == right
	if not await say(c, GameData.INFO_OK.pick_random() if c["info_ok"] else GameData.INFO_BAD.pick_random(), 0.5):
		return
	_sys(c, "(O solicitante desligou.)")
	end_call(c, "caller")


# ---------------------------------------------------------------- emergência

func run_emergency(c: Dictionary) -> void:
	if not await _greet(c):
		return
	if not await wait(c, 0.3):
		return
	if not await say(c, c["open"], 0.3):
		return
	c["phase"] = "emerg"
	hint("Pergunte o que precisa. Marque o local no mapa e envie as unidades pelo despacho.")
	c["asked"] = []
	_emergency_choices(c)


func _emergency_choices(c: Dictionary) -> void:
	var list := []
	var qs: Array = c["q"]
	for i in qs.size():
		if i in c["asked"]:
			continue
		var k := i
		list.append({"label": qs[i][0], "fn": func(): _em_ask(c, k)})
	if not c.get("dispatched", false):
		list.append({"label": "Fique na linha, vou enviar ajuda.", "fn": func(): _em_hold(c)})
	_set_opts(c, list)


func _em_ask(c: Dictionary, k: int) -> void:
	if c.get("talking", false) or c.get("ended", false):
		return
	c["asked"].append(k)
	_emergency_choices(c)
	if not await op(c, c["q"][k][0]):
		return
	await say(c, c["q"][k][1])


func _em_hold(c: Dictionary) -> void:
	if c.get("talking", false):
		return
	if not await op(c, "Fique na linha, vou enviar ajuda."):
		return
	await say(c, ["Rápido, por favor!", "Tá bom... tá bom."].pick_random())


func _emergency_dispatched() -> void:
	var c := em_call
	if c.is_empty() or not c.get("active", false) or c.get("dispatched", false):
		return
	c["dispatched"] = true
	_emergency_choices(c)
	while c.get("talking", false):
		if not await wait(c, 0.2):
			return
	if not await op(c, "As unidades estão a caminho."):
		return
	if not await say(c, c["after"], 0.9):
		return
	_sys(c, "(O solicitante desligou.)")
	end_call(c, "caller")


# ---------------------------------------------------------------- trote

func run_prank(c: Dictionary) -> void:
	if not await _greet(c):
		return
	if not await wait(c, 0.6):
		return
	for st in c["steps"]:
		match st[0]:
			"c":
				if not await say(c, st[1], 0.45):
					return
			"p":
				if not await wait(c, float(st[1])):
					return
			"o":
				var i := await choose(c, st[1])
				if i < 0:
					return
				if not await op(c, st[1][i]):
					return
			"end":
				sfx.play("cut")
				_sys(c, "(A ligação foi encerrada do outro lado.)")
				if not await wait(c, 0.5):
					return
				end_call(c, "caller")


# ---------------------------------------------------------------- a ligação misteriosa

func _op_line(c: Dictionary, l: String) -> bool:
	var i := await choose(c, [l])
	if i < 0:
		return false
	return await op(c, l)


func run_mystery(c: Dictionary) -> void:
	c["caller"] = "—"
	if not await _greet(c): return
	if not await wait(c, 2.6): return
	if not await say(c, "...alô?", 0.7): return
	if not await _op_line(c, "Central telefônica. Qual número você está tentando chamar?"): return
	if not await wait(c, 2.2): return
	if not await say(c, "Eu não sei."): return
	if not await _op_line(c, "Qual é o seu nome?"): return
	if not await wait(c, 1.5): return
	if not await say(c, "Eu estou tentando descobrir."): return
	sfx.static_burst(2.0)
	if not await _op_line(c, "Onde você está?"): return
	if not await wait(c, 1.2): return
	if not await say(c, "Eu não sei."): return
	if not await _op_line(c, "Você consegue me dizer alguma rua?"): return
	if not await wait(c, 3.4): return
	if not await say(c, "Tem uma luz.", 0.6): return
	if not await _op_line(c, "Que luz?"): return
	if not await wait(c, 1.3): return
	flick = true
	if not await say(c, "A luz da sua mesa.", 2.6): return
	sfx.static_burst()
	if not await say(c, "Ela sempre fica acesa?", 0.5): return
	end_call(c, "mystery")


# ---------------------------------------------------------------- fim de chamada

func end_call(c: Dictionary, reason: String) -> void:
	if c.get("ended", false):
		return
	c["ended"] = true
	c["active"] = false
	c["ringing"] = false
	c["talking"] = false
	c["opts"] = []
	for i in live.size():
		if is_same(live[i], c):
			live.remove_at(i)
			break
	_update_bell()
	if c["kind"] == "mystery":
		_mystery_aftermath(c)
	if reason != "connected":
		# Os cabos ficam na mesa: a linha mostra "desligou" até o operador desmontar.
		var ln := int(c["line"])
		var d := _dest_of_line(ln)
		if d != -1 and dests[d] == "ring":
			dests[d] = "free"
			_dgen[d] = int(_dgen.get(d, 0)) + 1
		elif d != -1 and dests[d] == "conn":
			dests[d] = "done"
		if lines[ln - 1] in ["talk", "hold", "ring"]:
			var plugged := board.cord_at(ln) != -1 or board.cord_at(ln + 10) != -1
			lines[ln - 1] = "done" if plugged and c["kind"] != "mystery" else "free"
	if reason == "op":
		_sys(c, "(Você encerrou a ligação.)")
	elif reason == "missed":
		_sys(c, "(Ninguém atendeu. A pessoa desistiu.)")
	_refresh_panel()
	var where := "—"
	var unit := "—"
	var obs := ""
	match c["kind"]:
		"transfer":
			if c.get("connected", false):
				var right: bool = str(c["dest_num"]) == String(c["target"])
				where = String(c["dest"]) if right else String(GameData.find_number(str(c["dest_num"]))["n"])
				if not right:
					obs = "Conectada ao número errado."
		"info":
			if c.has("info_ok"):
				obs = ("Pediu o número d%s." % c["about"]) if c["what"] == "num" else "Perguntou as horas."
				if not c["info_ok"]:
					obs += " Informação errada."
		"emergency":
			var same: bool = not sent.is_empty() and is_same(sent["call"], c)
			where = String(sent["loc"]) if same else String(c["addr"])
			unit = String(sent["units"]) if same else "—"
		"prank":
			where = c["fake"]
	if reason == "op":
		obs = "Encerrada pelo operador."
	elif reason == "missed":
		obs = "Não atendida."
	elif c["kind"] == "transfer" and not c.get("connected", false):
		obs = "Não conectada."
	elif c["kind"] == "mystery":
		obs = "A ligação caiu."
	var who := "Desconhecido" if c["kind"] == "mystery" or reason == "missed" else String(c["caller"])
	var rec := {"time": c["time"], "who": "%s (linha %02d)" % [who, int(c["line"])], "where": where, "unit": unit, "obs": obs, "kind": c["kind"]}
	c["rec"] = rec
	_add_pending(rec)
	await get_tree().create_timer(1.5).timeout
	if ending:
		return
	if live.is_empty():
		set_tab("caderno")
		hint("Registre a ocorrência no caderno.")
	else:
		hint("Há ocorrências para registrar no caderno quando der tempo.")


func _mystery_aftermath(c: Dictionary) -> void:
	sfx.play("cut")
	sfx.hum.volume_db = -80.0
	flick = false
	_sys(c, "(A ligação caiu.)")
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
	if tab != "caderno":
		tab_dots["caderno"].visible = true


## 06:00: o turno acaba. Se a anotação ainda não apareceu, ela aparece agora; depois, o final.
func _close_shift() -> void:
	if not note_shown:
		_show_note()
	await get_tree().create_timer(12.0).timeout
	_start_ending()


func _start_ending() -> void:
	if ending:
		return
	ending = true
	running = false
	sfx.ring_stop()
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
	sent = {"call": em_call, "loc": target["label"], "units": ", ".join(names)}
	if em_call.has("rec"):
		em_call["rec"]["where"] = sent["loc"]
		em_call["rec"]["unit"] = sent["units"]
		if is_same(pending, em_call["rec"]):
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
	# a anotação da linha 07 sobe para a tabela enquanto houver formulário aberto
	scrawl.position = Vector2(30, 220) if pending.is_empty() else Vector2(250, 40)
	if pending.is_empty():
		pending_box.visible = false
		tab_dots["caderno"].visible = false
		return
	pending_box.visible = true
	p_time.text = "Nova ocorrência · " + String(pending["time"]) + ("   (+%d na fila)" % pending_q.size() if not pending_q.is_empty() else "")
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
	pending = pending_q.pop_front() if not pending_q.is_empty() else {}
	sfx.play("pencil")
	_render_ledger()
	_fill_pending()
	hint("")


## Ocorrências encerradas entram numa fila: o caderno não segura o turno.
func _add_pending(rec: Dictionary) -> void:
	if pending.is_empty():
		pending = rec
		_fill_pending()
		return
	pending_q.append(rec)   # não apaga o que o jogador está preenchendo
	p_time.text = "Nova ocorrência · %s   (+%d na fila)" % [pending["time"], pending_q.size()]
	tab_dots["caderno"].visible = true


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
	if prev == "caderno" and note_wanted:
		await get_tree().create_timer(1.2).timeout
		_show_note()
