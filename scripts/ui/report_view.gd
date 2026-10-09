class_name ReportView
extends CenterContainer
## Relatório do supervisor no fim do turno: advertências do turno, o jornal da manhã e o parecer.

signal closed

const SEVERITY_COLORS := ["5a4d3a", "8a5a14", "8a1a14", "5a0a40"]

var C: GameContent = GameData.CONTENT

@onready var _night: Label = %Night
@onready var _body: RichTextLabel = %Body
@onready var _verdict: Label = %Verdict


func _ready() -> void:
	%Sign.pressed.connect(func():
		Sfx.play("pencil")
		closed.emit())


func show_report(r: ShiftReport) -> void:
	if r.night == 0:
		_night.text = T.text(T.Key.REPORT_TRAINING) % [Main.fmt(0.0), Main.fmt(Main.SHIFT_END)]
	else:
		_night.text = T.text(T.Key.REPORT_NIGHT) % [r.night, Main.fmt(0.0), Main.fmt(Main.SHIFT_END)]
	var s := "[b]%s[/b]\n" % T.text(T.Key.REPORT_WARNINGS)
	if r.faults.is_empty():
		s += T.text(T.Key.REPORT_NONE) + "\n"
	for f in r.faults:
		var sev := ShiftReport.severity(f["id"])
		var detail: String = " — " + String(f["detail"]) if f["detail"] != "" else ""
		s += "%s  %s%s  [color=#%s](%s)[/color]\n" % [f["time"], T.text(ShiftReport.FAULTS[f["id"]][1]), detail.replace("[", "("),
			SEVERITY_COLORS[sev], T.text(ShiftReport.SEVERITY_NAMES[sev])]
	s += "\n%s: %d   ·   %s: %d   ·   %s: %d   ·   %s: %d\n" % [T.text(T.Key.REPORT_CRITICAL), r.count(ShiftReport.Severity.CRITICAL),
		T.text(T.Key.REPORT_SEVERE), r.count(ShiftReport.Severity.SEVERE),
		T.text(T.Key.REPORT_MEDIUM), r.count(ShiftReport.Severity.MEDIUM), T.text(T.Key.REPORT_LIGHT), r.count(ShiftReport.Severity.LIGHT)]
	s += T.text(T.Key.REPORT_ACCUMULATED) % [r.severe_total(), ShiftReport.SEVERE_LIMIT] + "\n"
	s += "\n[b]%s[/b]\n" % T.text(T.Key.REPORT_NEWS)
	var news := r.news()
	if news.is_empty():
		s += T.text(T.Key.REPORT_QUIET) + "\n"
	for d in news:
		s += "• %s\n" % ShiftReport.headline(d)
	_body.text = s
	_verdict.text = tr(C.verdicts[r.verdict()]) if r.verdict() < C.verdicts.size() else ""
