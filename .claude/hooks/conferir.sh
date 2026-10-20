#!/bin/bash
# Hooks do Claude Code (.claude/settings.json): o erro volta para o agente na hora, sem ninguém lembrar de rodar.
#   conferir.sh editou   (PostToolUse de Edit/Write) check.sh no arquivo editado e o projeto compilado
#   conferir.sh parou    (Stop) compila de novo só se algo mudou sem passar pelo Edit (sed, script)
# Saída 2 com o texto no stderr: o Claude Code repassa ao agente. Sem --import (o editor pode estar aberto).
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0
G=/Applications/Godot.app/Contents/MacOS/Godot
state="$(git rev-parse --git-dir)/claude-hooks"   # fora do git: o que já foi visto, para não repetir
mkdir -p "$state"
input=$(cat)

tree() {   # o estado do que compila: muda quando um .gd, .tscn ou .tres muda
	{ git diff HEAD -- '*.gd' '*.tscn' '*.tres'; git ls-files --others --exclude-standard -- '*.gd' '*.tscn' '*.tres' | xargs cat 2>/dev/null; } | md5
}

compile() {   # o mesmo do CLAUDE.md (--quit-after 60): erro de compilação em qualquer script carregado pelo jogo
	local out
	out=$("$G" --headless --path . --quit-after 60 2>&1 | grep -E -A1 "SCRIPT ERROR|^ERROR:|Parse Error" | head -8)   # (o primeiro erro é o que importa; o resto é cascata)
	tree >"$state/compiled"
	[ -z "$out" ] && return 0
	printf 'O projeto não compila:\n%s\n' "$out" >&2
	return 1
}

case $1 in
editou)
	f=$(jq -r '.tool_input.file_path // empty' <<<"$input")
	f=${f#"$PWD/"}
	[[ $f == *.gd || $f == *.tscn || $f == *.tres ]] || exit 0
	rc=0
	out=$(sh .claude/skills/revisar-mudancas/check.sh HEAD "$f" | grep -v "^Nada nas")
	key="$state/check_$(md5 -qs "$f")"
	# ponytail: o mesmo apontamento só volta se o texto mudou; aceito uma vez, não insiste a cada edição do arquivo
	if [ -n "$out" ] && [ "$out" != "$(cat "$key" 2>/dev/null)" ]; then
		printf '%s\n(confira: o filtro é grosso, pode ser falso)\n' "$out" >&2
		rc=2
	fi
	printf '%s' "$out" >"$key"
	compile || rc=2
	exit $rc
	;;
parou)
	[ "$(jq -r '.stop_hook_active' <<<"$input")" = true ] && exit 0
	[ "$(tree)" = "$(cat "$state/compiled" 2>/dev/null)" ] && exit 0
	compile || exit 2
	;;
esac
exit 0
