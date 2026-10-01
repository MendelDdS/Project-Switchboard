extends Node
## Configurações do jogador (autoload `Settings`). Por enquanto só o idioma: começa sempre em português; o menu de
## configurações (ainda não existe) vai chamar `set_locale`. `-- --lang=en` força um idioma para testar.
## Textos: interface/código em translations/ui.csv (enum T.Key), falas dos roteiros em translations/content.*.po.

const DEFAULT_LOCALE := "pt_BR"
const LOCALES := ["pt_BR", "en", "es"]


func _ready() -> void:
	var lang := DEFAULT_LOCALE
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang=") and a.get_slice("=", 1) in LOCALES:
			lang = a.get_slice("=", 1)
	set_locale(lang)


func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
