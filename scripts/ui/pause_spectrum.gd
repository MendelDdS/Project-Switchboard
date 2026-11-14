extends Control
## O fundo da pausa, no lugar da mesa comutadora da tela inicial: a luz da sala na parede (`TitleBoard.wall_art`) e,
## à direita, um espectro de áudio esmaecido, como um medidor da época: barras de segmentos empilhados, no âmbar das
## lâmpadas da mesa, espelhadas em volta do meio, os segmentos de cima mais claros. As barras não andam cada uma por
## si: uns poucos picos (`_peaks`) passeiam pelo espectro, crescendo e minguando ao acaso, e puxam as vizinhas em onda;
## por cima, um tremor pequeno em cada barra. Só anda com a pausa à mostra e só redesenha quando alguma barra ganha
## ou perde um segmento (`_look`).

const BOARD := preload("res://scripts/ui/title_board.gd")
const BARS := 40
const BAR := Vector2(8.0, 4.0)   ## a largura de uma barra e o vão até a próxima
const LEFT := 440.0   ## onde o espectro começa (onde a mesa começa na tela inicial)
const SEG := Vector2i(4, 2)   ## a altura de um segmento e o vão até o próximo
const SEGS := 18   ## segmentos de uma barra cheia, para cada lado do meio
const ALPHA := Vector2(0.13, 0.34)   ## esmaecido: do segmento do meio ao da ponta
const PEAKS := 4
const PEAK_W := 3.5   ## a largura de um pico, em barras
const PEAK_SPEED := 14.0   ## até quantas barras por segundo ele anda
const PEAK_HOLD := Vector2(0.2, 0.6)   ## de quanto em quanto tempo (s, sorteado) o pico troca de força e de rumo
const JITTER := 0.12   ## o tremor de cada barra, da barra cheia
const JITTER_HOLD := Vector2(0.05, 0.18)
const SPEED := 14.0   ## quão depressa a barra vai para a altura nova

var _wall := BOARD.wall_art()
var _bar: ImageTexture   ## uma barra cheia, com os segmentos (cada barra mostra o meio dela, até a altura)
var _h := PackedFloat32Array()
var _jit := PackedFloat32Array()
var _look := PackedInt32Array()   ## os segmentos acesos de cada barra, como estão desenhados
var _wait := PackedFloat32Array()
var _peaks := []   ## cada pico: {at (barra), v (barras/s), amp, to, wait}
var _rng := RandomNumberGenerator.new()   # (o global segue a semente do jogo)


func _ready() -> void:
	for a: PackedFloat32Array in [_h, _jit, _wait]:
		a.resize(BARS)
	for i in PEAKS:
		_peaks.append({"at": _rng.randf() * BARS, "v": 0.0, "amp": 0.0, "to": 0.0, "wait": 0.0})
	var pitch := SEG.x + SEG.y
	var half := SEGS * pitch
	var img := Image.create(int(BAR.x), half * 2, false, Image.FORMAT_RGBA8)
	for k in SEGS:
		var col := Color(Pal.AMBER, lerpf(ALPHA.x, ALPHA.y, k / float(SEGS - 1)))
		img.fill_rect(Rect2i(0, half + 1 + k * pitch, int(BAR.x), SEG.x), col)   # (1 px de cada lado do meio: o vão)
		img.fill_rect(Rect2i(0, half - 1 - k * pitch - SEG.x, int(BAR.x), SEG.x), col)
	_bar = ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	for p: Dictionary in _peaks:
		p["wait"] -= delta
		if p["wait"] <= 0.0:
			p["wait"] = _rng.randf_range(PEAK_HOLD.x, PEAK_HOLD.y)
			p["to"] = _rng.randf_range(0.15, 1.0)
			p["v"] = _rng.randf_range(-PEAK_SPEED, PEAK_SPEED)
		p["amp"] = lerpf(p["amp"], p["to"], 1.0 - exp(-delta * 6.0))
		p["at"] += p["v"] * delta
		if p["at"] < 0.0 or p["at"] > BARS:   # bate na ponta e volta
			p["at"] = clampf(p["at"], 0.0, BARS)
			p["v"] = -p["v"]
	for i in BARS:
		_wait[i] -= delta
		if _wait[i] <= 0.0:
			_wait[i] = _rng.randf_range(JITTER_HOLD.x, JITTER_HOLD.y)
			_jit[i] = _rng.randf_range(-JITTER, JITTER)
		var want := 0.0
		for p: Dictionary in _peaks:
			var d: float = (i + 0.5 - p["at"]) / PEAK_W
			want += p["amp"] * exp(-d * d)
		want = clampf(want * (0.45 + 0.55 * sin(PI * (i + 0.5) / BARS)) + _jit[i], 0.0, 1.0)   # mais alto no meio
		_h[i] = lerpf(_h[i], want, 1.0 - exp(-delta * SPEED))
	var look := PackedInt32Array()
	for i in BARS:
		look.append(maxi(1, roundi(_h[i] * SEGS)))   # em segmentos inteiros, ao menos um
	if look != _look:
		_look = look
		queue_redraw()


func _draw() -> void:
	draw_texture_rect(_wall, Rect2(Vector2.ZERO, size), false)
	var mid := roundf(size.y / 2.0)
	var pitch := SEG.x + SEG.y
	var half := SEGS * pitch
	for i in _look.size():
		var h := _look[i] * pitch
		draw_texture_rect_region(_bar, Rect2(LEFT + i * (BAR.x + BAR.y), mid - h, BAR.x, h * 2.0), Rect2(0, half - h, BAR.x, h * 2.0))
