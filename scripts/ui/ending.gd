class_name Ending
extends ColorRect
## Fim do turno: escurece a mesa, mostra o relatório do supervisor e depois segue para a próxima noite,
## ou, no fim do jogo (o epílogo, a presa ou a demissão), mostra o final e volta ao menu (ou ao treinamento). O texto
## da tela preta pode vir da noite (`Night.ending_for`): o encontro com Sebastião, o fecho de cada final; no fim do
## jogo, sem relatório, e depois do fecho os créditos.

const StoryText := preload("res://scripts/data/story_text.gd")
const REPORT_DIM := 0.84   ## o quanto a sala escurece atrás do relatório (depois dele, o preto inteiro)

@onready var _title: Label = %Title
@onready var _question: Label = %Question
@onready var _restart: Button = %Restart
@onready var _report: ReportView = %ReportView

var _to_menu := false


func _ready() -> void:
	color.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for n in [_title, _question, _restart]:
		n.modulate.a = 0.0
	_restart.disabled = true   # no lugar desde o começo, transparente: escondido, entrar depois subia o texto
	_restart.pressed.connect(func() -> void:
		if _to_menu:
			GameView.playing = false
		Main.restart())


## `more`: ainda há uma próxima noite (o progresso já foi salvo pelo Main). `text`: o texto da noite para a tela
## preta (null: o de sempre). `memo` falso: sem o relatório (o fim do jogo), a mesa escurece de vez.
func play(report: ShiftReport, more: bool, text: StoryText = null, memo := true) -> void:
	if report.fired():
		_title.text = T.text(T.Key.END_FIRED_TITLE)
		_question.text = T.text(T.Key.END_FIRED_TEXT)
		_restart.text = T.text(T.Key.RESTART_FIRST_NIGHT)
	elif more and report.night == 0:
		_title.text = T.text(T.Key.END_TRAINING_TITLE)
		_question.text = T.text(T.Key.END_TRAINING_TEXT)
		_restart.text = T.text(T.Key.NEXT_NIGHT)
	elif more:
		_title.text = T.text(T.Key.END_NIGHT_TITLE) % report.night
		_question.text = T.text(T.Key.END_NIGHT_TEXT)
		_restart.text = T.text(T.Key.NEXT_NIGHT)
	elif text != null:   # o fim do jogo: o final
		_title.text = T.text(T.Key.END_GAME_TITLE)
		_restart.text = T.text(T.Key.PAUSE_TO_MENU)
		_to_menu = true
	if text != null and not report.fired():
		if text.title != "":
			_title.text = tr(text.title)
		_question.text = tr(text.text)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not memo:
		await create_tween().tween_property(self, "color:a", 1.0, 2.5).finished
	else:
		create_tween().tween_property(self, "color:a", REPORT_DIM, 3.0)   # o memorando chega na mesa escura, ainda à vista
		await get_tree().create_timer(3.4, false).timeout
		_report.show_report(report)
		_report.modulate.a = 0.0
		_report.visible = true
		create_tween().tween_property(_report, "modulate:a", 1.0, 1.2)
		await _report.closed
		create_tween().tween_property(self, "color:a", 1.0, 0.8)
		await create_tween().tween_property(_report, "modulate:a", 0.0, 0.8).finished
		_report.visible = false
	create_tween().tween_property(_title, "modulate:a", 1.0, 2.0)
	await get_tree().create_timer(2.6, false).timeout
	create_tween().tween_property(_question, "modulate:a", 1.0, 2.5)
	await get_tree().create_timer(2.4, false).timeout
	if _to_menu:   # o fim do jogo: o fecho fica o tempo de ler, e vêm os créditos
		await get_tree().create_timer(maxf(6.0, _question.text.length() * 0.06), false).timeout
		create_tween().tween_property(_title, "modulate:a", 0.0, 1.5)
		await create_tween().tween_property(_question, "modulate:a", 0.0, 1.5).finished
		_title.text = T.text(T.Key.TITLE_CREDITS)
		_question.text = T.text(T.Key.CREDITS_TEXT)
		create_tween().tween_property(_title, "modulate:a", 1.0, 2.0)
		await get_tree().create_timer(1.5, false).timeout
		create_tween().tween_property(_question, "modulate:a", 1.0, 2.5)
		await get_tree().create_timer(2.4, false).timeout
	_restart.disabled = false
	create_tween().tween_property(_restart, "modulate:a", 1.0, 1.5)
