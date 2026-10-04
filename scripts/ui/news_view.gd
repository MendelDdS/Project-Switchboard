class_name NewsView
extends VBoxContainer
## O jornal da manhã, aberto pelo jornal dobrado na mesa (da segunda noite em diante): o nome do jornal, a edição e
## uma manchete por emergência da noite anterior (`ShiftReport.news`, as mesmas do relatório), a primeira em destaque;
## noite sem emergência, "noite tranquila". As consequências das escolhas ficam na sala, não só na tela final.

var _news: Array = []
var _weekday := ""


func show_news(news: Array, weekday: String) -> void:
	_news = news
	_weekday = weekday
	_render()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_render()


func _render() -> void:
	$Edition.text = T.text(T.Key.NEWS_EDITION) % tr(_weekday)
	var s := "[font_size=22]%s[/font_size]" % T.text(T.Key.REPORT_QUIET) if _news.is_empty() else ""
	for i in _news.size():
		var h := ShiftReport.headline(_news[i]).replace("[", "(")
		s += ("[font_size=22]%s[/font_size]\n\n" if i == 0 else "• %s\n\n") % h
	$Headlines.text = s
