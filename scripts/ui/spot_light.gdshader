shader_type canvas_item;
// O holofote do toque de recolher (a camada `_spot_add` do `Background`, desenhada por `_draw_sweep_light`): em vez de
// pintar uma cor por cima, clareia o que já está desenhado embaixo dela (a fachada, a calçada, as janelas) na força da
// luz em cada ponto, que vem na cor dos vértices (a forma do facho; `a` = força). O tijolo e as juntas continuam
// aparecendo, cada material fica na sua cor, mais clara, e o que já brilha (a porta acesa, a vitrine) quase não muda:
// o ganho cai com o claro do que está embaixo.

uniform sampler2D screen : hint_screen_texture, filter_nearest;
uniform float gain = 4.0;   // quanto a luz no meio multiplica o que está embaixo, no escuro (`CURFEW_GAIN`)...
uniform float lift = 0.1;   // ...e o pouco que ela soma, para o preto não ficar preto

void fragment() {
	vec3 base = texture(screen, SCREEN_UV).rgb;
	float l = COLOR.a;
	float dark = 1.0 - dot(base, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(base * (1.0 + gain * l * dark * dark * COLOR.rgb) + COLOR.rgb * lift * l, 1.0);
}
