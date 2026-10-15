shader_type canvas_item;
// A gradação de cor do jogo inteiro (`GameView.grade_material`, no `Box`): cada pixel do jogo passa por uma conta de
// cor na hora de ir para a tela, as sombras puxando para o azul da noite, as luzes para o quente e um pouco mais de
// contraste. Ponto a ponto, no pixel já ampliado em bloco ("nearest"): o pixel perfect continua.

uniform float strength : hint_range(0.0, 1.0) = 1.0;   // 0 é o jogo sem gradação (a chave do painel de debug)
uniform vec3 shadow_lift = vec3(-0.004, 0.003, 0.02);   // o que as sombras ganham: o azul da noite
uniform vec3 light_tint = vec3(1.05, 1.0, 0.91);        // as luzes, mais quentes
uniform float contrast = 1.05;                          // em volta de `pivot`: abaixo dele escurece, acima clareia
uniform float pivot = 0.2;

void fragment() {
	vec3 c = COLOR.rgb;
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	vec3 g = c + shadow_lift * (1.0 - smoothstep(0.0, 0.35, l));
	g *= mix(vec3(1.0), light_tint, smoothstep(0.3, 0.85, l));
	g = (g - pivot) * contrast + pivot;
	COLOR.rgb = mix(c, clamp(g, 0.0, 1.0), strength);
}
