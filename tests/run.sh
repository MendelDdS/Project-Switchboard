#!/bin/sh
# Roda todos os testes em modo headless e falha se algum falhar, travar ou gerar SCRIPT ERROR.
# Uso: tests/run.sh            (Godot em /Applications; ou defina GODOT=/caminho/do/godot)
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
LIMIT=120   # segundos por teste
cd "$(dirname "$0")/.." || exit 1
log=$(mktemp)
fails=0

run() {   # run <script> [argumentos do jogo]
	script=$1; shift
	printf '%s %s ... ' "$script" "$*"
	# --fixed-fps: cada quadro avança 1/60 s de jogo e o motor roda o mais rápido que a CPU deixa (sem esperar o
	# relógio real). Simulação determinística e muito mais rápida; o tempo real só aparece em efeitos visuais.
	perl -e 'alarm shift; exec @ARGV' "$LIMIT" "$GODOT" --headless --fixed-fps 60 --path . -s "$script" -- "$@" >"$log" 2>&1
	code=$?
	if [ $code -eq 0 ] && ! grep -q "SCRIPT ERROR" "$log"; then
		grep -E "^(PASSOU|fim|OK)" "$log" | tail -1
	else
		echo "FALHOU (código $code)"
		grep -E "FALHOU|SCRIPT ERROR|at: " "$log" | grep -v "cleanup" | head -8
		fails=$((fails + 1))
	fi
}

# Reimporta: registra `class_name` novos (sem isso, scripts que usam a classe nova não compilam).
"$GODOT" --headless --path . --import >"$log" 2>&1
if grep -q "SCRIPT ERROR" "$log"; then
	grep -E "SCRIPT ERROR|at: " "$log" | head -8
	echo "O projeto não compila."
	exit 1
fi

run tests/test_flow.gd
run tests/test_penalties.gd
for s in 1 2 3; do
	run tests/test_shift.gd --seed=$s
done
run tests/test_shift.gd --seed=3 --clumsy
run tests/test_shift.gd --seed=2 --night=2
run tests/test_shift.gd --seed=1 --human
run tests/test_shift.gd --seed=2 --lang=en
run tests/test_shift.gd --seed=3 --lang=es

rm -f "$log"
[ $fails -eq 0 ] && echo "Todos os testes passaram." || echo "$fails teste(s) falharam."
exit $fails
