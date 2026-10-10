class_name Lift
extends RefCounted
## O que se pega da mesa e se leva com o mouse (o cartão do despacho, o bilhete de tarifação e o carimbo): na mão,
## sobe (fica maior em volta de onde foi pego, `pivot_offset`, e a sombra se afasta); solto, cai de volta, acelerando.
## Quem usa liga `held`, chama `step` a cada quadro enquanto ele devolver verdadeiro e desenha com `shadow()`.

const SHADOW := Color(0, 0, 0, 0.35)
const SHADOW_REST := Vector2(3, 4)    ## a sombra na mesa...
const SHADOW_HELD := Vector2(9, 12)   ## ...e erguido, na mão (como o plug da mesa)
const HELD_SCALE := 1.06              ## na mão, chega perto dos olhos (maior)...
const LIFT_SEC := 0.1                 ## ...nesse tempo; solto, cai na mesa nesse outro, acelerando
const DROP_SEC := 0.2

var held := false
var height := 0.0   ## a altura que se vê: sobe liso e cai acelerando
var _t := 0.0       ## 0 na mesa, 1 na mão (o tempo da subida ou da queda)


## Avança `delta` e devolve se ainda está subindo ou caindo.
func step(delta: float) -> bool:
	var up := 1.0 if held else 0.0
	_t = move_toward(_t, up, delta / (LIFT_SEC if held else DROP_SEC))
	height = smoothstep(0.0, 1.0, _t) if held else _t * _t
	return _t != up


## A escala de quem é levado: parado na mesa, 1 exato (as letras ficam nítidas).
func scale() -> Vector2:
	return Vector2.ONE * lerpf(1.0, HELD_SCALE, height)


func shadow() -> Vector2:
	return SHADOW_REST.lerp(SHADOW_HELD, height)
