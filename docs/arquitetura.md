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

temporadas/{temporadaId}              uma por categoria: master-2027, super-master-2027,
                                      livre-2027. parametros{...}, patrocinador? (nome da
                                      competição na súmula: "CF <patrocinador> <ano>")
  times/{clubeId}                     nome, sigla, cor, escudo? (PNG reduzido, até 300 KB)
  pessoas/{pessoaId}                  nome, timeId, funcao (atleta|tecnico), numero,
                                      goleiro, dirigente, saiuEm? (data da saída do elenco)
  partidas/{partidaId}                turno, fase, rodada, mandanteId, visitanteId, inicio,
                                      arbitros[], etapa (agendada|preparacao|lancamento|encerrada),
                                      sumula{golsMandante, golsVisitante, ausenteWo, penaltis,
                                             gols[], cartoes[], timesSemPontos[], observacoes,
                                             melhorDaPartida{pessoaId, timeId}?},
                                      fonte{youtubeUrl?}
  pagamentos/{pendenciaId}            pagoEm, registradoPor
  decisoes/{decisaoId}                pessoaId, timeId, partidaOrigemId, jogosSuspensao,
                                      multa, motivo, fundamento?, votacao?
  ajustes/{ajusteId}                  timeId, turno, pontos, motivo
  movimentacoes/{id}                  tipo (demissao|desligamento|lesao|trocaGoleiro),
                                      pessoaId, timeId, nome, data, laudo, motivoTroca?,
                                      substitutoId?, substitutoNome?, observacoes?
                                      (só a Organização lê)
  publico/painel                      gerado pelo app da Organização (leitura aberta)
  privado/disciplina                  pendências calculadas (só Organização)
  vinculos/{uid}                      nome, email, pessoaId, timeId, papel, status
                                      (pendente|aprovado|recusado). Um por categoria: o
                                      mesmo atleta pode jogar Master e Livre.

usuarios/{uid}                        nome, email, perfil (participante)
  situacao/atual                      pendências e cartões da própria pessoa (gerado)

organizacao/{uid}                     quem organiza; temporadas[]? limita às categorias
                                      (sem o campo, organiza todas). Criado à mão no console.
```

## Categorias

Master (10 times), Super Master (6) e Livre (8) são competições separadas, cada uma em
sua temporada, com times, elencos, calendário, tabela, regras e Organização próprios
(`lib/domain/entities/categoria.dart`). O Torcedor e o Participante escolhem a categoria
na primeira abertura e trocam pela barra do topo; a escolha fica guardada no aparelho. A
Organização vê só as categorias que organiza. Os avisos do Participante juntam todas as
categorias em que ele tem vínculo aprovado. A Copa Master entra quando o formato estiver
definido.

O app não usa o armazenamento de arquivos do Firebase (Storage). O escudo do time é enviado em "Editar time", reduzido para caber em 256 px e guardado no próprio documento do time; sem imagem, vale a cor com a sigla. O laudo de lesão não é enviado: a movimentação só registra que ele foi apresentado.

## Decisões a confirmar antes de publicar nas lojas

- **Identificador do app** (permanente nas lojas): proposta `br.com.calciofirenze.app`.
- **Projeto Firebase**: dois projetos, `calcio-firenze-dev` e `calcio-firenze`, na conta de Cesar Guerreiro Diniz.
