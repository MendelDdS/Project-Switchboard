#!/bin/sh
# Roda todos os testes em modo headless e falha se algum falhar, travar ou gerar SCRIPT ERROR.
# Uso: tests/run.sh            (Godot em /Applications; ou defina GODOT=/caminho/do/godot)
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
LIMIT=240   # segundos por teste
cd "$(dirname "$0")/.." || exit 1
log=$(mktemp)
fails=0

run() {   # run <script> [argumentos do jogo]
	script=$1; shift
	printf '%s %s ... ' "$script" "$*"
	perl -e 'alarm shift; exec @ARGV' "$LIMIT" "$GODOT" --headless --path . -s "$script" -- "$@" >"$log" 2>&1
	code=$?
	if [ $code -eq 0 ] && ! grep -q "SCRIPT ERROR" "$log"; then
		grep -E "^(PASSOU|fim|OK)" "$log" | tail -1
	else
		echo "FALHOU (código $code)"
		grep -E "FALHOU|SCRIPT ERROR|at: " "$log" | grep -v "cleanup" | head -8
		fails=$((fails + 1))
	fi
}

run tests/test_flow.gd
for s in 1 2 3; do
	run tests/test_shift.gd --seed=$s
done

rm -f "$log"
[ $fails -eq 0 ] && echo "Todos os testes passaram." || echo "$fails teste(s) falharam."
exit $fails
