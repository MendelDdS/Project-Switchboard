#!/bin/sh
# Verificações mecânicas só nas linhas acrescentadas (git diff sem contexto, mais os .gd novos ainda fora do git):
# o que as convenções do projeto (CLAUDE.md, LESSONS.md) já proíbem. Não substitui a revisão: só acha o óbvio rápido.
# Uso: check.sh [base]   (base: o commit para comparar; padrão HEAD, ou seja, o que ainda não foi commitado)
cd "$(git rev-parse --show-toplevel)" || exit 1
base="${1:-HEAD}"
{
	git diff -U0 "$base" -- '*.gd' '*.tscn' '*.tres'
	git ls-files --others --exclude-standard -- '*.gd' | while read -r f; do git diff -U0 --no-index /dev/null "$f"; done
} | awk '
function warn(msg) { printf "%s:%d: %s\n    %s\n", file, line, msg, text; n++ }
/^\+\+\+ / { file = substr($0, 7); next }
/^@@/ {
	match($0, /\+[0-9]+/); line = substr($0, RSTART + 1, RLENGTH - 1) - 1
	fn = $0; sub(/^@@[^@]*@@ ?/, "", fn)   # a função em volta (o git põe no cabeçalho do trecho)
	next
}
/^\+/ {
	line++
	text = substr($0, 2)
	code = text
	sub(/#.*/, "", code)   # (o comentário não conta; um # dentro de texto corta a linha, mas só para menos)
	if (file ~ /test_zz_/) warn("teste temporário esquecido (tests/test_zz_*): apague antes de terminar")
	if (file ~ /\.tscn$/) {
		if (code ~ /theme_override_/) warn("override de tema no nó: prefira uma variação de tema em themes/main_theme.tres")
		if (code ~ /render_target_update_mode = 4/) warn("SubViewport desenhado a todo quadro (UPDATE_ALWAYS): dá para ser só quando muda (UPDATE_ONCE)?")
		next
	}
	if (file !~ /\.gd$/) next
	if (code ~ /^(static )?func /) fn = code
	frame = fn ~ /func _(physics_)?process\(/
	drawing = fn ~ /func _draw/
	if (frame && code ~ /queue_redraw\(\)/) warn("queue_redraw no _process: só quando o que ele mostra mudou (estado comparado)?")
	if ((frame || drawing) && code ~ /get_nodes_in_group\(|find_child(ren)?\(/) warn("procura na árvore a cada quadro (ou a cada desenho): guarde a referência")
	if ((frame || drawing) && code ~ /Image\.create|create_from_image\(|set_pixel\(/) warn("imagem montada a cada quadro ou desenho: guarde (cache por tamanho e estado) e, se muda, atualize a mesma textura (update)")
	if (code ~ /UPDATE_ALWAYS/) warn("SubViewport desenhado a todo quadro: dá para ser só quando muda (UPDATE_ONCE)?")
	if (code ~ /WorkerThreadPool\.add_(group_)?task\(/ && code !~ /true/) warn("tarefa em prioridade baixa usa só ~30% dos núcleos: high_priority = true se alguém espera por ela")
	if (code ~ /(^|[^_a-zA-Z.])tr\("/) warn("texto literal em tr(): use T.text(T.Key.X) (chave em translations/ui.csv)")
	if (code ~ /create_timer\([^,()]*\)/) warn("create_timer sem false no 2º argumento: continua contando na pausa")
	if (code ~ /draw_(colored_)?polygon\(/ && code !~ /get_texture|uv/) warn("área cheia com draw_polygon: cada um é uma chamada de desenho; use draw_primitive (no cenário, _fill/_poly)")
	if (code ~ /draw_circle\(/) warn("peça redonda com draw_circle: use PixelArt.disc (pixel a pixel)")
	if (code ~ /volume_db[ \t]*=/ && file !~ /sfx\.gd$/) warn("volume mudado direto: só por Sfx.fade/Sfx._tween")
	if (code ~ /randomize\(\)/) warn("randomize() anula a semente dos testes (-- --seed=N)")
	if (code ~ /^class_name /) warn("class_name novo: só existe depois de reimportar (com o editor aberto, dê foco a ele)")
	if (file ~ /^tests\// && code ~ /(^|[^a-z_.])assert\(/) warn("assert trava o headless: use ok()")
	if (file ~ /^tests\// && code ~ /Time\.get_ticks_(msec|usec)/) warn("tempo de teste em relógio real: com --fixed-fps, meça em quadros")
	if (file !~ /^(tests|tools)\// && code ~ /(^|[^a-z_.])print(s|err|_debug)?\(/) warn("print no jogo (depuração esquecida?)")
}
END { if (!n) print "Nada nas verificações mecânicas."; else printf "%d apontamento(s) nas verificações mecânicas.\n", n }
'
