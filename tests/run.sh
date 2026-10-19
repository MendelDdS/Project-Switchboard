#!/bin/sh
# Roda todos os testes em modo headless e falha se algum falhar, travar ou gerar SCRIPT ERROR.
# Uso: tests/run.sh [teste...]  (Godot em /Applications; ou defina GODOT=/caminho/do/godot)
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
LIMIT=${LIMIT:-120}   # segundos por teste (um turno do robô leva ~9 s)
cd "$(dirname "$0")/.." || exit 1
log=$(mktemp)
fails=0

run() {   # run <teste> [argumentos do jogo]: roda tests/test_<teste>.gd pela cena tests/runner.tscn (com os autoloads)
	test=$1; shift
	printf 'tests/test_%s.gd %s ... ' "$test" "$*"
	# --fixed-fps: cada quadro avança 1/60 s de jogo e o motor roda o mais rápido que a CPU deixa (sem esperar o
	# relógio real). Simulação determinística e muito mais rápida; o tempo real só aparece em efeitos visuais.
	"$GODOT" --headless --fixed-fps 60 --path . tests/runner.tscn -- --test="$test" "$@" >"$log" 2>&1 &
	pid=$!
	# SCRIPT ERROR não encerra o Godot (o jogo segue com o erro): sem isto, um teste quebrado só morria no LIMIT
	ticks=0
	while kill -0 $pid 2>/dev/null; do
		if grep -q "SCRIPT ERROR" "$log"; then
			kill $pid 2>/dev/null
			break
		fi
		if [ $ticks -ge $((LIMIT * 5)) ]; then
			kill $pid 2>/dev/null
			echo "FALHOU: passou de ${LIMIT} s" >>"$log"
			break
		fi
		sleep 0.2
		ticks=$((ticks + 1))
	done
	wait $pid 2>/dev/null
	code=$?
	if [ $code -eq 0 ] && ! grep -q "SCRIPT ERROR" "$log"; then
		grep -E "^(PASSOU|fim|OK)" "$log" | tail -1
	else
		echo "FALHOU (código $code)"
		grep -E "FALHOU|SCRIPT ERROR|at: " "$log" | grep -v "cleanup" | head -8
		fails=$((fails + 1))
	fi
}

# Reimporta: registra `class_name` novos (sem isso, scripts que usam a classe nova não compilam). Com o editor aberto,
# não: ele reimporta sozinho, e dois Godot gravando .godot/uid_cache.bin ao mesmo tempo o corrompem (o jogo deixa de
# achar recursos por UID, como o layout dos barramentos de áudio).
if pgrep -f -- "--path $PWD (-e|--editor)( |$)" >/dev/null; then
	echo "Editor aberto: sem --import (dê foco a ele para registrar classes novas)."
else
	"$GODOT" --headless --path . --import >"$log" 2>&1
fi
if grep -q "SCRIPT ERROR" "$log"; then
	grep -E "SCRIPT ERROR|at: " "$log" | head -8
	echo "O projeto não compila."
	exit 1
fi

if [ $# -gt 0 ]; then   # tests/run.sh flow penalties: só esses (sem argumentos do jogo)
	for t in "$@"; do
		run "$t"
	done
	rm -f "$log"
	[ $fails -eq 0 ] && echo "Todos os testes passaram." || echo "$fails teste(s) falharam."
	exit $fails
fi
run flow
run training
run penalties
run keys --night=1   # (a noite também para a cena recarregada pelo Recomeçar, que não lê o progresso salvo)
run layout
for s in 1 2 3; do
	run shift --seed=$s
done
run shift --seed=3 --clumsy
run shift --seed=2 --night=2
run shift --seed=1 --night=5
run shift --seed=2 --night=9
run shift --seed=1 --night=15   # a última noite vai até as 6h (`Night.shift_end`)
run shift --seed=1 --human
run shift --seed=2 --human --nosy
run shift --seed=2 --human --nosy --careless
run shift --seed=2 --lang=en
run shift --seed=3 --lang=es

rm -f "$log"
[ $fails -eq 0 ] && echo "Todos os testes passaram." || echo "$fails teste(s) falharam."
exit $fails
