class_name ReportView
extends CenterContainer
## Relatório do supervisor no fim do turno: advertências do turno, o jornal da manhã e o parecer.

signal closed

const SEVERITY_COLORS := ["5a4d3a", "8a5a14", "8a1a14"]

var C: GameContent = GameData.CONTENT

@onready var _night: Label = %Night
@onready var _body: RichTextLabel = %Body
@onready var _verdict: Label = %Verdict


func _ready() -> void:
	%Sign.pressed.connect(func():
		Sfx.play("pencil")
		closed.emit())


func show_report(r: ShiftReport) -> void:
	_night.text = tr("Noite %d · turno das %s às %s") % [r.night, Main.fmt(0.0), Main.fmt(Main.SHIFT_END)]
	var s := "[b]%s[/b]\n" % tr("ADVERTÊNCIAS")
	if r.faults.is_empty():
		s += tr("Nenhuma.") + "\n"
	for f in r.faults:
		var sev := ShiftReport.severity(f["id"])
		var detail: String = " — " + String(f["detail"]) if f["detail"] != "" else ""
		s += "%s  %s%s  [color=#%s](%s)[/color]\n" % [f["time"], tr(ShiftReport.FAULTS[f["id"]][1]), detail.replace("[", "("),
			SEVERITY_COLORS[sev], tr(ShiftReport.SEVERITY_NAMES[sev])]
	s += "\n%s: %d   ·   %s: %d   ·   %s: %d\n" % [tr("Graves"), r.count(ShiftReport.Severity.SEVERE),
		tr("Médias"), r.count(ShiftReport.Severity.MEDIUM), tr("Leves"), r.count(ShiftReport.Severity.LIGHT)]
	s += tr("Advertências graves acumuladas: %d de %d") % [r.severe_total(), ShiftReport.SEVERE_LIMIT] + "\n"
	s += "\n[b]%s[/b]\n" % tr("JORNAL DA MANHÃ")
	var news := r.outcomes()
	if news.is_empty():
		s += tr("Noite tranquila em São Sotero.") + "\n"
	for e: EmergencyCall in news:
		var pool: PackedStringArray = [C.news_ok, C.news_late, C.news_bad][news[e]]
		s += "• %s\n" % GameData.fill(GameData.pick(pool), {"occurrence": _occurrence(e.occurrence), "address": e.address})
	_body.text = s
	_verdict.text = tr(C.verdicts[r.verdict()]) if r.verdict() < C.verdicts.size() else ""


## "Invasão / roubo" -> "Invasão"; "Outro" -> "Ocorrência".
func _occurrence(o: String) -> String:
	return tr("Ocorrência") if o == "Outro" else tr(o).get_slice(" /", 0)
