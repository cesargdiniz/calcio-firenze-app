import 'package:calcio_firenze/domain/entities/temporada.dart';
import 'package:calcio_firenze/domain/usecases/movimentacoes.dart';
import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_test/flutter_test.dart';

const _linha = Pessoa(id: 'sam-7', nome: 'Bruno Lima', timeId: 'SAM', numero: 7);
const _goleiro = Pessoa(id: 'sam-1', nome: 'Caio Reis', timeId: 'SAM', numero: 1, goleiro: true);
const _dirigente = Pessoa(id: 'sam-9', nome: 'Davi Luz', timeId: 'SAM', numero: 9, dirigente: true);
const _tecnico = Pessoa(id: 'sam-t', nome: 'Hélio Ramos', timeId: 'SAM', funcao: Funcao.tecnico);

void main() {
  test('dirigente não pode pedir demissão, mas pode sair por lesão (art. 82)', () {
    expect(impedimentoMovimentacao(TipoMovimentacao.demissao, _dirigente), contains('art. 82'));
    expect(impedimentoMovimentacao(TipoMovimentacao.lesao, _dirigente), isNull);
    expect(impedimentoMovimentacao(TipoMovimentacao.demissao, _linha), isNull);
  });

  test('troca de goleiro só vale para o goleiro inscrito (art. 83)', () {
    expect(impedimentoMovimentacao(TipoMovimentacao.trocaGoleiro, _linha), contains('art. 83'));
    expect(impedimentoMovimentacao(TipoMovimentacao.trocaGoleiro, _goleiro), isNull);
  });

  test('técnico e quem já saiu não têm movimentação', () {
    expect(impedimentoMovimentacao(TipoMovimentacao.desligamento, _tecnico), isNotNull);
    final fora = _linha.comSaida(DateTime(2027, 3, 1));
    expect(impedimentoMovimentacao(TipoMovimentacao.desligamento, fora), isNotNull);
  });

  test('quem saiu continua no elenco dos jogos anteriores à saída', () {
    final fora = _linha.comSaida(DateTime(2027, 3, 1));
    expect(fora.ativo, isFalse);
    expect(fora.noElencoEm(DateTime(2027, 2, 26, 20, 30)), isTrue);
    expect(fora.noElencoEm(DateTime(2027, 3, 1, 20, 30)), isFalse);
    expect(fora.comSaida(null).ativo, isTrue);
  });

  test('citadoNaTemporada encontra gol, cartão e decisão', () {
    DadosTemporada dados({Sumula? sumula, List<DecisaoDisciplinar> decisoes = const []}) =>
        DadosTemporada(
          id: 't',
          nome: 'T',
          local: 'L',
          times: const [],
          pessoas: const [_linha],
          partidas: [
            Partida(
              id: 'j1',
              turno: 1,
              fase: Fase.classificatoria,
              mandanteId: 'SAM',
              visitanteId: 'COM',
              inicio: DateTime(2027, 2, 1),
              sumula: sumula,
            ),
          ],
          decisoes: decisoes,
        );

    expect(citadoNaTemporada(dados(sumula: const Sumula()), 'sam-7'), isFalse);
    expect(
      citadoNaTemporada(
        dados(sumula: const Sumula(gols: [Gol(timeId: 'SAM', autorId: 'sam-7')])),
        'sam-7',
      ),
      isTrue,
    );
    expect(
      citadoNaTemporada(
        dados(
          sumula: const Sumula(
            cartoes: [CartaoAplicado(pessoaId: 'sam-7', timeId: 'SAM', tipo: TipoCartao.amarelo)],
          ),
        ),
        'sam-7',
      ),
      isTrue,
    );
    expect(
      citadoNaTemporada(
        dados(
          decisoes: const [
            DecisaoDisciplinar(
              id: 'd',
              pessoaId: 'sam-7',
              timeId: 'SAM',
              partidaOrigemId: 'j1',
              motivo: 'm',
              multa: 100,
            ),
          ],
        ),
        'sam-7',
      ),
      isTrue,
    );
  });
}
