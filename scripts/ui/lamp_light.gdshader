shader_type canvas_item;
// A luz da luminária por cima do cenário pronto (`SceneView`, plano hi-bit, etapa 5): a poça quente que soma cor,
// caindo lisa a partir do meio dela (sem degraus), e de fora o vidro da janela (a vista tem a luz dela). Os
// parâmetros vêm do `Background` a cada quadro (`SceneView._process`), sem redesenhar a sala.
#include "res://scripts/ui/glass.gdshaderinc"

uniform vec2 size = vec2(960.0, 540.0);       // o cenário, em px (o `UV` vezes ele: px da tela)
uniform vec2 center = vec2(480.0, 400.0);     // o meio da poça no tampo (px)
uniform vec2 radius = vec2(300.0, 220.0);     // até onde a luz chega para os lados e para cima e para baixo (px)
uniform float level = 1.0;                    // a luminária: 1 acesa, menos piscando ou esquentando
uniform vec3 tint : source_color = vec3(1.0, 0.78, 0.5);   // a cor dela (mais laranja esquentando)
uniform float gain = 0.5;                     // o quanto a cor de cada pixel cresce no meio da poça...
uniform float add = 0.03;                     // ...e a cor pura somada (pouca: muita lavava o escuro)
uniform vec4 daylight = vec4(1.0, 0.95, 0.85, 0.0);   // a luz do dia pela janela (cor, força): a etapa 7; 0 por ora

void fragment() {
	vec4 c = COLOR;   // (no Godot 4, já é a textura vezes a cor do desenho)
	vec2 p = UV * size;
	if (!in_glass(p)) {
		float d = length((p - center) / radius);
		float f = 1.0 - smoothstep(0.0, 1.0, d);   // liso até a beira
		f *= f * level * (1.0 - daylight.a);       // o dia enfraquece a luminária
		c.rgb = c.rgb * (1.0 + tint * f * gain) + tint * f * add;
	}
	COLOR = c;
}
