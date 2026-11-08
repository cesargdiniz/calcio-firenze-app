# Arquitetura e modelo de dados

## Camadas

```
packages/calcio_regras   Regras do regulamento, Dart puro, com testes.
lib/domain               Entidades do app, contrato do repositório, casos de uso (Dart puro).
lib/data                 Fontes de dados: hoje a temporada de exemplo; depois o Firestore.
lib/modules              Telas por perfil (torcedor, participante, organizacao) com Cubit.
lib/shared               Tema (cores, fontes, espaços do Figma) e componentes visuais.
```

Convenções: as skills em `.claude/skills` (Clean Architecture, Cubit com status selado, testes). Diferença em relação às skills: injeção de dependência com `RepositoryProvider`/`BlocProvider` do próprio flutter_bloc, sem `flutter_injections`, e sem Dio (o acesso a dados é pelo SDK do Firebase).

## Quem calcula o quê

O Firebase gratuito (plano Spark) não roda Cloud Functions, e as regras estão em Dart. Por isso:

- **As regras rodam no app.** Quando a Organização encerra uma súmula, registra um pagamento ou uma decisão, o próprio app recalcula com `calcio_regras` e publica o resultado.
- **O Torcedor lê um documento pronto** (`publico/painel`): tabela, jogos, suspensos e pendurados. Uma leitura por abertura, sem cálculo e sem dados financeiros.
- **As fontes de verdade** são as súmulas, as decisões e os pagamentos. Pendências, suspensões e tabela são sempre derivados delas e podem ser recalculados a qualquer momento.

## Firestore

```
clubes/{clubeId}                      nome, sigla, cor, escudoUrl, historico[]   (cadastrado uma vez)

temporadas/{temporadaId}              nome, categoria, ano, local, turnoAtual,
                                      parametros{...}, ordemSorteio[]
  times/{clubeId}                     dirigenteId, rebaixadoNoAnoAnterior
  pessoas/{pessoaId}                  nome, timeId, funcao (atleta|tecnico|dirigente),
                                      numero, goleiro, turno, ativo, uid?
  partidas/{partidaId}                turno, fase, rodada, mandanteId, visitanteId, inicio,
                                      arbitros[], etapa (agendada|preparacao|lancamento|encerrada),
                                      sumula{golsMandante, golsVisitante, ausenteWo, penaltis,
                                             gols[], cartoes[], timesSemPontos[], observacoes},
                                      fonte{youtubeUrl?}, pdfUrl?
  pagamentos/{pendenciaId}            pagoEm, registradoPor
  decisoes/{decisaoId}                pessoaId, timeId, partidaOrigemId, jogosSuspensao,
                                      multa, motivo, fundamento, votacao
  ajustes/{ajusteId}                  timeId, turno, pontos, motivo
  movimentacoes/{id}                  tipo (demissao|lesao|trocaGoleiro|desligamento),
                                      pessoaId, timeId, data, laudoPath?
  publico/painel                      gerado pelo app da Organização (leitura aberta)
  privado/disciplina                  pendências calculadas (só Organização)

usuarios/{uid}                        nome, email, perfil (participante|organizacao),
                                      vinculo{temporadaId, pessoaId, status}
  situacao/atual                      pendências e cartões da própria pessoa (gerado)
```

Fotos de súmula e laudos ficam no Storage em `privado/…`, legíveis só pela Organização.

## Decisões a confirmar antes de publicar nas lojas

- **Identificador do app** (permanente nas lojas): proposta `br.com.calciofirenze.app`.
- **Projeto Firebase**: dois projetos, `calcio-firenze-dev` e `calcio-firenze`, na conta de Cesar Guerreiro Diniz.
