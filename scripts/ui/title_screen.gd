extends Control
## A tela inicial do jogo, antes da primeira noite da sessão (o `GameView` a põe no lugar do `Main`; a pausa do jogo
## volta para ela por "Voltar ao menu"): à direita, o canto da mesa comutadora de perto com o FONE na entrada 1
## (`title_board.gd`); à esquerda, o nome do jogo, o menu (cada opção com uma lâmpada que acende na escolhida, pelo
## mouse ou pelas setas; Carregar diz em que noite o jogo parou), os Créditos e a versão. Ao fundo, o ambiente da
## sala e, de vez em quando, uma linha chamando. Carregar ou Novo jogo apagam a lâmpada do FONE, escurecem a tela e
## clareiam já no jogo; Novo jogo com um jogo salvo pergunta antes de apagá-lo (num papel, como os créditos).

const MAIN := "res://scenes/main.tscn"
const RING_GAP := Vector2(25.0, 50.0)   ## de quanto em quanto tempo (s, sorteado) uma linha chama...
const RING_SEC := 4.5   ## ...e quanto tempo ela fica chamando (dois toques) antes de desistir
const FADE_SEC := 0.9   ## o escuro ao começar o jogo (e o clarear, já nele)
const CITY := "São Sotero"   ## a parte do nome do jogo que vai em letra maior (`_texts`)
const LOGO_GAP := 8   ## px entre as duas linhas do nome
const RAIN_CHANCE := 0.35   ## a chance de o ambiente ser de chuva

var _leaving := false
var _ring := Timer.new()


func _ready() -> void:
	var saved := FileAccess.file_exists(Progress.PATH)
	%Load.visible = saved
	%Quit.visible = OS.get_name() != "Web"   # (no navegador, sair do jogo não fecha nada)
	var lamp := PixelArt.disc(11, [[2.5, Color.WHITE], [5.5, Color(0.92, 0.92, 0.92), Color(0.78, 0.78, 0.78), Color(0.58, 0.58, 0.58)]], Vector2(0.7071, -0.7071))
	for b: Button in [%Load, %New, %Settings, %Quit]:
		b.icon = lamp   # a lâmpada apagada; na escolhida, acesa (as cores do ícone na variação `TitleButton`)
	for b: Button in [%Load, %New, %Settings, %Quit, %Credits]:
		b.mouse_entered.connect(b.grab_focus)   # o mouse escolhe como as setas: uma lâmpada acesa só
	%Version.texture = PixelArt.tiny(Settings.version_text())
	_texts()
	%Load.pressed.connect(_play)
	%New.pressed.connect(func():
		if saved:
			_paper(true)
		else:
			_play())
	%Settings.pressed.connect(%PauseMenu.open_settings)
	%Quit.pressed.connect(get_tree().quit)
	%Credits.pressed.connect(_paper.bind(false))
	%Erase.pressed.connect(func():
		Progress.clear()
		_play())
	%Close.pressed.connect(func():
		Sfx.play("click")
		_close_paper())
	%PauseMenu.visibility_changed.connect(func(): if not %PauseMenu.visible: _choose())
	Sfx.ring_stop()
	Sfx.muffle(false)
	Sfx.start_ambience("rain" if randf() < RAIN_CHANCE else "clear")
	add_child(_ring)
	_ring.one_shot = true
	_ring.timeout.connect(_toggle_ring)
	_ring.start(randf_range(RING_GAP.x, RING_GAP.y))
	_choose.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if %Shade.visible and e.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close_paper()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_texts()


## O que se monta com o idioma: o nome do jogo em letra grande e a linha embaixo de Carregar.
func _texts() -> void:
	# ponytail: o nome da cidade (`CITY`) em letra de 4× e o resto do nome do jogo em 2×, em cima ou embaixo conforme
	# vem antes ou depois dele no idioma; se um idioma novo não trouxer a cidade no nome, sai tudo em 2×.
	var title := T.text(T.Key.GAME_TITLE)
	var rest := title.replace(CITY, "").strip_edges()
	var ink := {"u": Pal.BOARD_INK.lightened(0.25), "d": Pal.BOARD_INK.darkened(0.3), "+": Pal.BOARD_INK}
	var small := PixelArt.art(PixelArt.big(rest.to_upper(), 1), ink).get_image()
	var imgs: Array = [small]
	if rest != title:
		var big := PixelArt.art(PixelArt.big(CITY.to_upper(), 2), ink).get_image()
		imgs = [small, big] if title.begins_with(rest) else [big, small]
	var h := 0
	var w := 0
	for i: Image in imgs:
		w = maxi(w, i.get_width())
		h += i.get_height() + LOGO_GAP
	var logo := Image.create(w, h - LOGO_GAP, false, Image.FORMAT_RGBA8)
	var y := 0
	for i: Image in imgs:
		i.convert(Image.FORMAT_RGBA8)
		logo.blit_rect(i, Rect2i(Vector2i.ZERO, i.get_size()), Vector2i(0, y))
		y += i.get_height() + LOGO_GAP
	%Logo.texture = ImageTexture.create_from_image(logo)
	%Where.text = _where()
	%Where.get_parent().visible = %Load.visible and %Where.text != ""


## A noite em que o jogo salvo parou, com a data ("Noite 4 · Quinta-feira, 11 de outubro de 1973"). Lido direto do
## arquivo: o `Progress.load_saved` guarda ao lado o save que não dá para ler, e isso fica para o `Main` avisar.
func _where() -> String:
	var f := ConfigFile.new()
	if f.load(Progress.PATH) != OK:
		return ""
	var n: int = f.get_value("progress", "night", 0)
	if n == 0:
		return T.text(T.Key.TITLE_WHERE_TRAINING) % GameData.date_text(0)
	return T.text(T.Key.TITLE_WHERE) % [n, GameData.date_text(n)]


## A primeira opção à mostra fica escolhida (as setas e o Enter andam a partir dela).
func _choose() -> void:
	if _leaving or %Shade.visible:
		return
	for b: Button in [%Load, %New]:
		if b.visible:
			b.grab_focus()
			return


## Uma linha começa a chamar (a lâmpada pulsando e a campainha do lado dela) ou, chamando, desiste.
func _toggle_ring() -> void:
	var board := $Board
	if board.ringing == 0:
		board.ringing = randi_range(2, board.COLS)
		var x: float = board.position.x + board.COL0 + board.PITCH * (board.ringing - 1)
		Sfx.ring_start({board.ringing: x / size.x})
		_ring.start(RING_SEC)
	else:
		board.ringing = 0
		Sfx.ring_stop()
		_ring.start(randf_range(RING_GAP.x, RING_GAP.y))


## O papel por cima do menu: o aviso de que o jogo novo apaga o salvo (`ask`) ou os créditos.
func _paper(ask: bool) -> void:
	Sfx.play("click")
	%Text.text = T.text(T.Key.TITLE_NEW_WARNING if ask else T.Key.CREDITS_TEXT)
	%Erase.visible = ask
	%Shade.visible = true
	(%Erase if ask else %Close).grab_focus()


func _close_paper() -> void:
	%Shade.visible = false
	_choose()


## Troca esta tela pelo jogo (o `Main` lê o jogo salvo, se houver; os recomeços dele, `Main.restart`, não voltam
## aqui): o tec da chave, a lâmpada do FONE apagando, a tela escurecendo e, já com o jogo atrás, clareando.
func _play() -> void:
	if _leaving:
		return
	_leaving = true
	Sfx.play("sw")
	Sfx.ring_stop()
	Sfx.stop_ambience(FADE_SEC)
	_ring.stop()
	$Board.ringing = 0
	$Board.fone_on = false
	%Fade.mouse_filter = Control.MOUSE_FILTER_STOP   # nada mais se clica no menu
	get_viewport().gui_release_focus()
	var dark := create_tween()
	dark.tween_interval(0.25)   # a lâmpada apagando
	dark.tween_property(%Fade, "color:a", 1.0, FADE_SEC)
	await dark.finished
	GameView.playing = true
	add_sibling(load(MAIN).instantiate())
	get_parent().move_child(self, -1)   # o escuro fica por cima do jogo enquanto clareia
	for c in get_children():
		if c is CanvasItem:
			c.visible = false
	var light := create_tween()
	light.tween_property(%Fade, "color:a", 0.0, FADE_SEC)
	await light.finished
	queue_free()
