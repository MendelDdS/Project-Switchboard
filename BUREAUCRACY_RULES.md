# Como criar uma burocracia

As burocracias são normas que o supervisor e as autoridades impõem à telefonista. O jogador pode descumpri-las: a
regra registra a decisão e penaliza, nunca bloqueia. O núcleo (`scripts/bureaucracy/bureaucracy.gd`, o gerente, nó
`%Bureaucracy` do Main) não conhece regra nenhuma; ele só chama os ganchos de cada uma.

Referência completa: `scripts/bureaucracy/rule_auth_code.gd` (B3) e `data/bureaucracy/b3_codigo.tres`.

## Passo a passo

1. **O script** em `scripts/bureaucracy/rule_<nome>.gd`, com `extends BureaucracyRule`, sem `class_name`.
   - No comentário de topo, diga o que a regra faz e como o roteiro a liga.
   - Os parâmetros são `@export`: o painel de debug cria um editor para cada um sozinho. Ele aceita bool, int (enum
     com `@export_enum("Nome:valor", ...)`), float, String, PackedStringArray e PackedInt32Array.
2. **Os ganchos.** Sobrescreva só os que a regra usa. Todos são síncronos: um `await` num Resource às vezes devolvia
   o estado da corrotina para quem esperava. Os ganchos são:
   - `night_started()`, `night_ended()`: começo do turno e fim, antes do relatório.
   - `call_started(c) -> Array`: as falas logo depois do "alô", em ordem; texto é de quem liga, `{"op": texto}` é do
     operador, `{"sys": texto}` é um aviso na conversa e `{"snaps": "tec tec... tec"}` são estalos de dedo (o sinal
     da B2). O gerente diz as falas.
   - `request_made(c) -> Array`: o mesmo, logo depois de quem liga pedir a transferência (o aviso de bloqueio e o
     código de autorização vêm aqui).
   - `choices(c) -> Array[Dictionary]`: opções do operador enquanto o pedido espera, `{"label", "fn"}`. O texto é
     `T.text(T.Key.CHOICE_*)`, a fala é `T.Key.OP_*`, em `translations/ui.csv`.
   - `before_transfer(c, d) -> Verdict`: a tentativa de transferir para `d`.
     - Devolva `null` (nada a dizer), `Verdict.allowed(motivo)` (só o registro) ou `infraction(motivo)` (advertência
       na gravidade da regra); pedir algo ao operador é um botão de resposta (`choices`), não uma resposta aqui.
     - O gerente registra todas e aplica só a maior, também contra o número errado da mesma tentativa.
   - `transfer_done(c)`, `call_ended(c, reason)`, `listening(n, on)`, `clue_heard(k)`.
   - `caught_listening(c) -> bool`: os dois perceberam a escuta; verdadeiro = a regra cobra do jeito dela, no lugar
     da advertência por escuta (a B4, numa ligação marcada).
   - `debug_info() -> String`, `debug_actions() -> [[texto, Callable]]`: aparecem no painel de debug.
3. **Fora da transferência:**
   - Para decisões, use `desk.log_decision(id, c, escolha, resultado)`.
   - Para advertências, use `desk.penalize(self, c, gravidade, motivo, T.Key.X)`.
   - Quando o operador nega ou aceita algo e a conversa acaba, use `await desk.hang_up_after(c, fala)`: quem liga diz
     a fala (a reação, `TransferCall.refused_line`, ou o agradecimento, `thanks`) e desliga. Para a ligação sem
     reação própria, `desk.refusal(c, reactions)` sorteia uma das `reactions` da regra (como a B2 e a B3).
   - O que a regra guarda numa ligação vai em `c.meta["<id>_..."]`.
4. **Os serviços**, que qualquer regra pode usar e trocar sem mexer nas outras: `desk.codes` (códigos de autorização),
   `desk.messages` (recados), `desk.agreements` (acordos de redirecionamento) e `desk.tapes` (fitas). Serviço novo é
   um `preload` e uma variável no gerente.
5. **Os dados** em `data/bureaucracy/<id>.tres`, com o script da regra.
   - Campos comuns: `id`, `title`, `active` (desligada por padrão), `from_night`/`to_night`, `severity`, `fault_text`
     (o nome de uma chave `T.Key`; o padrão é `FAULT_BUREAUCRACY`) e `tests`.
   - `tests` são as ligações de teste (`TransferCall` com `resource_name`), uma por botão no debug, com falas marcadas
     `[TESTE]`.
   - `equipment` lista os equipamentos que ela traz para a mesa.
   - O gerente carrega todo `.tres` desta pasta sozinho.
6. **Equipamento na mesa** (opcional):
   - Uma cena em `scenes/ui/equipment/<id>.tscn` (um Control com `custom_minimum_size`, pixel art e o próprio clique;
     acha o gerente com `Bureaucracy.of(self)`).
   - O `<id>` vai em `equipment` no `.tres`.
   - A mesa a põe de pé na prateleira embaixo do Interurbano, na primeira vez que a regra vale
     (`equipment_unlocked(id)` avisa uma vez só).
7. **O teste** vai em `tests/test_bureaucracy.gd`: ligue a chave geral, ligue a regra, toque as ligações de `tests` e
   confira as advertências (`ShiftReport.level`) e o registro (`desk.decisions`).

## Como o roteiro liga

```gdscript
main.bureaucracy.enable(true)                    # a chave geral (desligada, o jogo é o de sempre)
main.bureaucracy.activate("b2_bloqueados")       # vale de from_night a to_night; no meio do turno, começa na hora
main.bureaucracy.update_params("b2_bloqueados", {"blocked": PackedStringArray(["355"])})
main.bureaucracy.deactivate("b2_bloqueados")
main.bureaucracy.unlock_equipment("gravador")    # ou lock_equipment, sem regra nenhuma
```

A chave geral, as regras ligadas e os parâmetros de `update_params` vão para o save no fim da noite
(`Progress.bureaucracy`) e voltam na próxima sessão; o que o debug muda direto na regra não.

O exemplo feito só por este guia é `rule_call_length.gd` com `data/bureaucracy/exemplo_duracao.tres` (limite de
duração da ligação, desligado).
