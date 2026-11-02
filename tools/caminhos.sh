#!/bin/sh
# Joga a história inteira por caminho (`tests/test_shift.gd --path=`): as noites 1 a 15 em sequência, os marcadores
# de uma passando para a seguinte (`--flags`), e confere o final de cada uma (`final_<caminho>`; a amarga é o sucesso
# com `custou_gente`, e o sucesso, sem). Os caminhos correm
# juntos (~3 min); o relato de cada noite fica em build/caminhos/<caminho>.txt.
#   tools/caminhos.sh [caminho...]   (sem nada: sucesso amarga presa fracasso)
cd "$(dirname "$0")/.." || exit 1
G=/Applications/Godot.app/Contents/MacOS/Godot
mkdir -p build/caminhos
run() {
	flags=""
	: > "build/caminhos/$1.txt"
	for n in $(seq 1 15); do
		out=$("$G" --headless --fixed-fps 60 --path . tests/runner.tscn -- --test=shift --seed=1 --night="$n" --path="$1" --flags="$flags" 2>&1)
		flags=$(echo "$out" | sed -n 's/^marcadores: //p')
		echo "noite $n: $(echo "$out" | grep -E '^eficiência|FALHOU' | cut -c1-800)" >> "build/caminhos/$1.txt"
	done
	echo "marcadores: $flags" >> "build/caminhos/$1.txt"
	has() { echo "$flags" | tr ',' '\n' | grep -qx "$1"; }
	case $1 in
		amarga) has final_sucesso && has custou_gente ;;
		sucesso) has final_sucesso && ! has custou_gente ;;
		*) has "final_$1" ;;
	esac
	if [ $? -eq 0 ]; then
		echo "$1: OK"
	else
		echo "$1: FALHOU (final: $(echo "$flags" | tr ',' '\n' | grep -E '^final_|^custou_gente' | tr '\n' ' '))"
		return 1
	fi
}
paths=${*:-"sucesso amarga presa fracasso"}
for p in $paths; do
	run "$p" > "build/caminhos/$p.result" &
done
wait
fail=0
for p in $paths; do
	cat "build/caminhos/$p.result"
	grep -q OK "build/caminhos/$p.result" || fail=1
done
exit $fail
