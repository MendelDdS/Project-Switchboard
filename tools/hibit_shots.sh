#!/bin/bash
# As capturas de referência da sala (as do plano hi-bit), numa pasta relativa ao projeto:
#   tools/hibit_shots.sh build/hibit/1.2
# Em bash, com os argumentos numa lista: no zsh, "$B" sem aspas não se separa em palavras e a captura perdia a semente.
# A pasta tem que ser relativa: com um caminho absoluto, o --out do shot.gd criava a pasta dentro do projeto.
cd "$(dirname "$0")/.." || exit 1
O=${1:?uso: tools/hibit_shots.sh build/hibit/<sub-etapa>}
[[ $O == /* ]] && { echo "a pasta tem que ser relativa ao projeto"; exit 1; }
G=/Applications/Godot.app/Contents/MacOS/Godot
B=(--night=2 --seed=1 --wait=5)
mkdir -p "$O"
shot() { "$G" --path . tools/shot.tscn -- "${B[@]}" "$@" >/dev/null 2>&1; }
for h in 18:30 21:00 23:30; do for w in rain fog clear; do shot --hour=$h --weather=$w --out=$O/sala_${h/:/}_$w.png; done; done
shot --hour=21:00 --weather=clear --hover=caneca --zoom=840,260,110,100 --out=$O/hover_caneca.png
shot --hour=21:00 --weather=clear --zoom=840,260,110,100 --out=$O/caneca.png
shot --hour=23:30 --weather=rain --zoom=840,260,110,100 --out=$O/caneca_2330_rain.png
shot --hour=21:00 --weather=clear --blind=1 --zoom=840,260,110,100 --out=$O/caneca_persiana.png
shot --hour=21:00 --weather=clear --hover=lista --out=$O/hover_lista.png
shot --hour=21:00 --weather=clear --tool=despacho --card --out=$O/despacho.png
shot --hour=21:00 --weather=clear --toll --tool=calculografo --out=$O/calculografo.png
shot --hour=21:00 --weather=clear --listen --patch=312 --zoom=40,60,380,280 --out=$O/mesa_comutadora.png
shot --hour=21:00 --weather=clear --zoom=420,290,320,110 --out=$O/tampo.png
for h in 04:30 05:30 06:00; do "$G" --path . tools/shot.tscn -- --night=15 --seed=1 --wait=5 --hour=$h --weather=clear --out=$O/amanhecer_${h/:/}.png >/dev/null 2>&1; done
