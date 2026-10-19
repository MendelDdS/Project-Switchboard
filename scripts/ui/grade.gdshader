shader_type canvas_item;
// A gradação de cor do jogo inteiro (`GameView.grade_material`, no `Box`): cada pixel do jogo passa por uma conta de
// cor na hora de ir para a tela, as sombras puxando para o azul da noite, os tons médios na luz (a madeira, as
// lâmpadas) para o quente e um pouco mais de contraste; os tons claros (o papel, o texto claro) ficam como são, para o
// papel não amarelar nem acinzentar. Ponto a ponto, no pixel já ampliado em bloco ("nearest"): o pixel perfect
// continua.

uniform float strength : hint_range(0.0, 1.0) = 1.0;   // 0 é o jogo sem gradação (a chave do painel de debug)
uniform vec3 shadow_lift = vec3(-0.012, 0.002, 0.035);  // o que as sombras ganham: o azul da noite, sem clarear
uniform vec3 light_tint = vec3(1.06, 1.0, 0.9);         // as luzes, mais quentes...
uniform vec2 warm = vec2(0.18, 0.42);                   // ...a partir desse brilho (de um ao outro, aos poucos)
uniform float contrast = 1.1;                           // em volta de `pivot`: abaixo dele escurece, acima clareia
uniform float pivot = 0.2;
uniform float saturation = 1.0;                       // 1 as cores como são; acima, mais vivas (o amanhecer)
uniform vec2 spare = vec2(0.48, 0.7);                   // daí para cima a gradação some aos poucos: o papel

void fragment() {
	vec3 c = COLOR.rgb;
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	vec3 g = c + shadow_lift * (1.0 - smoothstep(0.0, 0.35, l));
	g *= mix(vec3(1.0), light_tint, smoothstep(warm.x, warm.y, l));
	g = (g - pivot) * contrast + pivot;
	g = mix(vec3(dot(g, vec3(0.2126, 0.7152, 0.0722))), g, saturation);
	g = mix(g, c, smoothstep(spare.x, spare.y, l));
	COLOR.rgb = mix(c, clamp(g, 0.0, 1.0), strength);
}
