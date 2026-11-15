# calcio_regras

As regras do Calcio Firenze (Master 2027) em Dart puro, sem Flutter nem Firebase. O app e as Cloud Functions usam o mesmo código, então a tabela e a lista de suspensos saem iguais em qualquer lugar.

| Arquivo | O que calcula | Regulamento |
|---|---|---|
| `classificacao.dart` | Tabela do turno e geral, W.O., perda de pontos, 7 desempates + sorteio, rebaixados | arts. 4, 42, 43.1, 68, 75, 89 |
| `motor_disciplinar.dart` | Pendências (R$), prazo de 24 h, multa por atraso, suspensões, pendurados, impedidos | arts. 66–73.7, 86–88 |
| `artilharia.dart` | Goleadores do turno ou da temporada, sem os gols de W.O. | art. 75 |
| `mata_mata.dart` | Quartas, semifinais, quem avança, grande final | art. 16 |
| `parametros.dart` | Valores ajustáveis (pontos, R$, prazos) | — |

## Rodar os testes

```bash
cd packages/calcio_regras
dart pub get
dart test
```

## Interpretações adotadas

Pontos em que o regulamento deixa margem. Cada um tem teste próprio; se a Organização decidir diferente, o ajuste é localizado.

1. **Dois amarelos na mesma partida (art. 67):** cobra só o vermelho (R$ 50) e os dois amarelos não contam para o acúmulo de 3.
2. **Amarelo + vermelho direto (art. 73.1/73.2):** cobra R$ 80 e o amarelo continua contando para o acúmulo.
3. **Vermelho e 3º amarelo no mesmo jogo:** 2 jogos de suspensão, cumpridos em sequência.
4. **Acúmulo no mata-mata:** os amarelos zeram ao fim da classificatória (art. 70); no mata-mata de cada turno a contagem recomeça do zero.
5. **Prazo de quitação:** 24 h antes do próximo jogo **do time** de quem recebeu o cartão. Pagamento depois disso gera multa do mesmo valor, cobrada uma única vez, e a pessoa fica impedida naquele jogo.
6. **Time que perde os pontos (arts. 4, 43.1, 68):** placar, gols e V/E/D continuam valendo para estatística e desempate; só os pontos da partida viram zero.
7. **Cartões no desempate (critérios 6 e 7):** conta todos os cartões do time, inclusive do técnico; o 2º amarelo conta como vermelho.
8. **Confronto direto (critério 5):** mini-tabela de pontos só entre os empatados naquele ponto do desempate. Se um critério seguinte separa parte do grupo, o confronto direto não é reaplicado ao que sobrou.
9. **Classificação geral (art. 89):** soma só as fases classificatórias dos dois turnos.
10. **Artilharia:** só contam gols com autor lançado na súmula. Os gols do W.O. (art. 75) valem para a classificação, mas não são de nenhum jogador; gols contra e a disputa de pênaltis também ficam de fora. Empatados dividem a posição.
