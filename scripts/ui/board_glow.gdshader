shader_type canvas_item;
render_mode blend_add;
// A luz das lâmpadas acesas da mesa comutadora no painel em volta (plano hi-bit, etapa 6.2): um brilho fraco da cor de
// cada uma, que começa onde o halo do `Bloom` acaba (dentro dele, a luz somaria duas vezes) e some liso. Na camada
// `_glow` da mesa, por cima da luz da sala e por baixo dos fios. Os parâmetros vêm das luzes que a mesa já declara ao
// `Bloom` (`Switchboard._glow_params`), postos quando a camada das lâmpadas se redesenha.

uniform int count = 0;            // quantas luzes (até 16)
uniform vec4 lights[16];          // cada uma: o meio (px da mesa), onde o halo do Bloom acaba (px) e a força (o nível dela)
uniform vec4 colors[16] : source_color;
uniform float reach = 2.6;        // até onde o brilho chega, em vezes o fim do halo
uniform float strength = 0.16;    // a força no mais forte

varying vec2 pos;

void vertex() {
	pos = VERTEX;
}

void fragment() {
	vec3 sum = vec3(0.0);
	for (int i = 0; i < count; i++) {
		float d = distance(pos, lights[i].xy);
		float r = lights[i].z;
		float f = 1.0 - smoothstep(0.0, r * reach, d);
		sum += colors[i].rgb * f * f * smoothstep(0.4 * r, r, d) * lights[i].w;   // entra por baixo do halo, que já some
	}
	COLOR = vec4(sum * strength, 1.0);
}
