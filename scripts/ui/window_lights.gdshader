shader_type canvas_item;
render_mode blend_add;
// As luzes de fora que entram pela janela (plano hi-bit, etapa 6): o letreiro de neon e os postes da rua, cada um
// tingindo em volta dele o vão, o peitoril, a persiana e a parede perto da janela. Na camada `_window_lights` do
// `Background`, entre a persiana e os objetos da mesa: eles ficam na frente da luz pela ordem das camadas (a caneca e
// o relógio não são pintados). Soma cor; o vidro fica de fora (a vista tem a luz dela). Os parâmetros mudam sem
// redesenhar a sala (`Background._window_light_params`).
#include "res://scripts/ui/glass.gdshaderinc"

uniform int count = 0;            // quantas luzes (até 8)
uniform vec4 lights[8];           // cada uma: onde (px da tela), até onde chega (px) e a força
uniform vec4 colors[8] : source_color;   // e a cor dela

varying vec2 pos;

void vertex() {
	pos = VERTEX;   // px da tela
}

void fragment() {
	vec3 sum = vec3(0.0);
	if (!in_glass(pos)) {
		for (int i = 0; i < count; i++) {
			float f = 1.0 - smoothstep(0.0, 1.0, distance(pos, lights[i].xy) / lights[i].z);
			sum += colors[i].rgb * f * f * lights[i].w;   // liso até a beira
		}
	}
	COLOR = vec4(sum, 1.0);
}
