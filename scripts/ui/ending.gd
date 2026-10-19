class_name Ending
extends ColorRect
## Fim do turno: escurece a mesa, mostra o relatório do supervisor e depois segue para a próxima noite,
## ou, na última noite (ou com advertências graves demais), mostra o final e recomeça do início.

const REPORT_DIM := 0.84   ## o quanto a sala escurece atrás do relatório (depois dele, o preto inteiro)

@onready var _title: Label = %Title
@onready var _question: Label = %Question
@onready var _restart: Button = %Restart
@onready var _report: ReportView = %ReportView


func _ready() -> void:
	color.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for n in [_title, _question, _restart]:
		n.modulate.a = 0.0
	_restart.visible = false
	_restart.pressed.connect(Main.restart)


## `more`: ainda há uma próxima noite (o progresso já foi salvo pelo Main).
func play(report: ShiftReport, more: bool) -> void:
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
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	_restart.visible = true
	create_tween().tween_property(_restart, "modulate:a", 1.0, 1.5)
