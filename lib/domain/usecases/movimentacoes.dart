import 'package:calcio_regras/calcio_regras.dart';

import '../entities/temporada.dart';

/// O substituto da troca de goleiro já aparece em súmula ou decisão, então a
/// movimentação não pode mais ser desfeita.
class MovimentacaoEmUso implements Exception {
  const MovimentacaoEmUso();
}

/// Por que a pessoa não pode ter esta movimentação registrada; nulo se pode.
String? impedimentoMovimentacao(TipoMovimentacao tipo, Pessoa pessoa) {
  if (!pessoa.ativo) return 'Já está fora do elenco.';
  if (pessoa.funcao != Funcao.atleta) return 'Só atletas têm movimentação registrada.';
  return switch (tipo) {
    TipoMovimentacao.demissao when pessoa.dirigente =>
      'Quem é ou foi dirigente não pode pedir demissão (art. 82).',
    TipoMovimentacao.trocaGoleiro when !pessoa.goleiro =>
      'A troca só vale para o goleiro inscrito do time (art. 83).',
    _ => null,
  };
}

/// O que o regulamento prevê para cada tipo de saída.
String consequenciaMovimentacao(TipoMovimentacao tipo) => switch (tipo) {
  TipoMovimentacao.demissao =>
    'Art. 82: no 1º turno, o atleta vai para o Draft 2 e só volta por sorteio, nunca ao '
        'ex-clube. No 2º turno, fica fora do campeonato. Só é permitido um pedido por ano.',
  TipoMovimentacao.desligamento =>
    'Art. 83.2: quem pede desligamento do Calcio não retorna no 2º turno, e o time não '
        'tem direito a substituição.',
  TipoMovimentacao.lesao =>
    'Art. 83.2: o atleta não volta ao time, mesmo que se recupere. O time escolhe um '
        'atleta a mais no Draft 2; depois do Draft 2, segue com um a menos.',
  TipoMovimentacao.trocaGoleiro =>
    'Arts. 83 e 83.1: só por lesão incapacitante com laudo ou por mudança de município. '
        'O substituto precisa já ter participado de alguma categoria; goleiro externo é '
        'vedado.',
};

/// A pessoa aparece em alguma súmula (gol ou cartão) ou decisão?
bool citadoNaTemporada(DadosTemporada d, String pessoaId) =>
    d.decisoes.any((x) => x.pessoaId == pessoaId) ||
    d.partidas.any((p) {
      final s = p.sumula;
      return s != null &&
          (s.cartoes.any((c) => c.pessoaId == pessoaId) || s.gols.any((g) => g.autorId == pessoaId));
    });
