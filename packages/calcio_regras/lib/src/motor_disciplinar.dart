import 'entidades.dart';
import 'parametros.dart';

enum StatusPendencia {
  /// Dentro do prazo de quitação.
  aVencer,

  /// Prazo passou sem pagamento: gera multa e impede de jogar ou de ficar à
  /// beira do campo (arts. 68 e 73.7).
  vencida,
  quitada,

  /// O time ainda não tem próximo jogo marcado, então não há prazo.
  semPrazo,
}

/// Valor a pagar à Organização.
class Pendencia {
  final String id;
  final String pessoaId;
  final String timeId;
  final Funcao funcao;

  /// Em centavos.
  final int valor;
  final String descricao;
  final String partidaOrigemId;
  final DateTime origemEm;
  final DateTime? prazo;
  final DateTime? pagoEm;

  /// Multa por atraso (mesmo valor da pendência original).
  final bool multaAtraso;

  const Pendencia({
    required this.id,
    required this.pessoaId,
    required this.timeId,
    required this.funcao,
    required this.valor,
    required this.descricao,
    required this.partidaOrigemId,
    required this.origemEm,
    this.prazo,
    this.pagoEm,
    this.multaAtraso = false,
  });

  StatusPendencia status(DateTime agora) {
    if (pagoEm != null) return StatusPendencia.quitada;
    if (prazo == null) return StatusPendencia.semPrazo;
    return agora.isAfter(prazo!) ? StatusPendencia.vencida : StatusPendencia.aVencer;
  }

  /// Paga até o prazo informado?
  bool pagaAte(DateTime limite) => pagoEm != null && !pagoEm!.isAfter(limite);

  @override
  String toString() => '$id R\$${valor ~/ 100}';
}

enum MotivoSuspensao { expulsao, amarelos, decisao }

class Suspensao {
  final String pessoaId;
  final String timeId;
  final MotivoSuspensao motivo;
  final int jogos;
  final String partidaOrigemId;

  /// Partidas do time em que a suspensão é cumprida, na ordem. Pode ter menos
  /// que [jogos] se o calendário ainda não tem partidas suficientes.
  final List<String> partidasACumprir;

  const Suspensao({
    required this.pessoaId,
    required this.timeId,
    required this.motivo,
    required this.jogos,
    required this.partidaOrigemId,
    required this.partidasACumprir,
  });

  int get semData => jogos - partidasACumprir.length;
}

class Pendurado {
  final String pessoaId;
  final String timeId;
  final int amarelos;
  const Pendurado(this.pessoaId, this.timeId, this.amarelos);
}

/// Ciclo de contagem de amarelos: zera ao fim da fase classificatória
/// (art. 70). O mata-mata de cada turno conta como ciclo próprio.
typedef Ciclo = ({int turno, bool eliminatoria});

Ciclo cicloDe(Partida p) => (turno: p.turno, eliminatoria: p.fase.eliminatoria);

/// Lê as súmulas, decisões e pagamentos e produz pendências, suspensões,
/// pendurados e impedidos. É o "Motor disciplinar" da especificação.
///
/// Decisões de interpretação (registradas no README do pacote):
/// - Os dois amarelos que viram vermelho (art. 67) não são cobrados nem contam
///   para o acúmulo; cobra-se só o vermelho.
/// - Amarelo seguido de vermelho direto (art. 73.1/73.2): cobra os dois e o
///   amarelo continua contando para o acúmulo.
/// - Suspensões da mesma pessoa se somam e são cumpridas em sequência.
class MotorDisciplinar {
  final List<Partida> _partidas;
  final Map<String, DateTime> _pagamentos;
  final Parametros params;
  final DateTime agora;

  final List<Pendencia> pendencias = [];
  final List<Suspensao> suspensoes = [];

  /// Amarelos que contam para o acúmulo, por pessoa e partida.
  final Map<String, List<(Partida, String timeId)>> _amarelosContados = {};

  MotorDisciplinar({
    required Iterable<Partida> partidas,
    Iterable<Pagamento> pagamentos = const [],
    Iterable<DecisaoDisciplinar> decisoes = const [],
    required this.agora,
    this.params = Parametros.master2027,
  }) : _partidas = [...partidas]..sort((a, b) => a.inicio.compareTo(b.inicio)),
       _pagamentos = {for (final p in pagamentos) p.pendenciaId: p.pagoEm} {
    _processarSumulas();
    _processarDecisoes(decisoes);
    _gerarMultasPorAtraso();
    _distribuirSuspensoes();
  }

  Partida _partida(String id) => _partidas.firstWhere((p) => p.id == id);

  List<Partida> _jogosDoTime(String timeId) => _partidas.where((p) => p.envolve(timeId)).toList();

  Partida? _proximoJogo(String timeId, Partida depoisDe) {
    for (final p in _jogosDoTime(timeId)) {
      if (p.inicio.isAfter(depoisDe.inicio)) return p;
    }
    return null;
  }

  DateTime? _prazo(String timeId, Partida origem) =>
      _proximoJogo(timeId, origem)?.inicio.subtract(params.prazoQuitacao);

  // Suspensões ainda sem partidas atribuídas, na ordem em que surgiram.
  final List<(String pessoa, String time, MotivoSuspensao, int jogos, Partida origem)>
  _aDistribuir = [];

  void _processarSumulas() {
    final contagem = <(String, Ciclo), int>{};

    for (final p in _partidas) {
      final s = p.sumula;
      if (s == null) continue;

      final porPessoa = <String, List<CartaoAplicado>>{};
      for (final c in s.cartoes) {
        porPessoa.putIfAbsent(c.pessoaId, () => []).add(c);
      }

      porPessoa.forEach((pessoa, cartoes) {
        final time = cartoes.first.timeId;
        final funcao = cartoes.first.funcao;
        final prazo = _prazo(time, p);
        final segundoAmarelo = cartoes.any((c) => c.tipo == TipoCartao.segundoAmarelo);
        final vermelhoDireto = cartoes.any((c) => c.tipo == TipoCartao.vermelho);

        void cobrar(String sufixo, int valor, String descricao) {
          final id = '${p.id}:$pessoa:$sufixo';
          pendencias.add(
            Pendencia(
              id: id,
              pessoaId: pessoa,
              timeId: time,
              funcao: funcao,
              valor: valor,
              descricao: descricao,
              partidaOrigemId: p.id,
              origemEm: p.inicio,
              prazo: prazo,
              pagoEm: _pagamentos[id],
            ),
          );
        }

        if (segundoAmarelo) {
          // Art. 67: só o vermelho é cobrado.
          cobrar('vermelho2a', params.valorVermelho, 'Dois amarelos (vermelho)');
        } else {
          var i = 0;
          for (final _ in cartoes.where((c) => c.tipo == TipoCartao.amarelo)) {
            cobrar('amarelo${i++}', params.valorAmarelo, 'Cartão amarelo');
            if (funcao == Funcao.atleta) {
              _amarelosContados.putIfAbsent(pessoa, () => []).add((p, time));
              final chave = (pessoa, cicloDe(p));
              final n = (contagem[chave] ?? 0) + 1;
              contagem[chave] = n;
              if (n % params.amarelosParaSuspensao == 0) {
                _aDistribuir.add((pessoa, time, MotivoSuspensao.amarelos, 1, p));
              }
            }
          }
        }
        if (vermelhoDireto) {
          cobrar('vermelho', params.valorVermelho, 'Cartão vermelho');
        }
        if ((segundoAmarelo || vermelhoDireto) && funcao == Funcao.atleta) {
          _aDistribuir.add((pessoa, time, MotivoSuspensao.expulsao, params.jogosPorExpulsao, p));
        }
      });
    }
  }

  void _processarDecisoes(Iterable<DecisaoDisciplinar> decisoes) {
    for (final d in decisoes) {
      final origem = _partida(d.partidaOrigemId);
      if (d.multa > 0) {
        final id = 'decisao:${d.id}';
        pendencias.add(
          Pendencia(
            id: id,
            pessoaId: d.pessoaId,
            timeId: d.timeId,
            funcao: Funcao.atleta,
            valor: d.multa,
            descricao: d.motivo,
            partidaOrigemId: origem.id,
            origemEm: origem.inicio,
            prazo: _prazo(d.timeId, origem),
            pagoEm: _pagamentos[id],
          ),
        );
      }
      if (d.jogosSuspensao > 0) {
        _aDistribuir.add((d.pessoaId, d.timeId, MotivoSuspensao.decisao, d.jogosSuspensao, origem));
      }
    }
  }

  /// Arts. 68 e 73.7: pagamento depois do prazo gera multa do mesmo valor.
  void _gerarMultasPorAtraso() {
    final originais = pendencias.where((p) => !p.multaAtraso).toList();
    for (final p in originais) {
      final prazo = p.prazo;
      if (prazo == null) continue;
      final atrasou = p.pagoEm == null ? agora.isAfter(prazo) : p.pagoEm!.isAfter(prazo);
      if (!atrasou) continue;
      final id = '${p.id}:atraso';
      pendencias.add(
        Pendencia(
          id: id,
          pessoaId: p.pessoaId,
          timeId: p.timeId,
          funcao: p.funcao,
          valor: p.valor,
          descricao: 'Multa por atraso · ${p.descricao}',
          partidaOrigemId: p.partidaOrigemId,
          origemEm: p.origemEm,
          prazo: prazo,
          pagoEm: _pagamentos[id],
          multaAtraso: true,
        ),
      );
    }
  }

  void _distribuirSuspensoes() {
    _aDistribuir.sort((a, b) => a.$5.inicio.compareTo(b.$5.inicio));
    // Próxima partida livre de cada pessoa, para somar suspensões em sequência.
    final ocupadoAte = <String, DateTime>{};

    for (final (pessoa, time, motivo, jogos, origem) in _aDistribuir) {
      final inicio = ocupadoAte[pessoa];
      final candidatos = _jogosDoTime(time).where(
        (p) => p.inicio.isAfter(origem.inicio) && (inicio == null || p.inicio.isAfter(inicio)),
      );
      final cumprir = candidatos.take(jogos).toList();
      if (cumprir.isNotEmpty) ocupadoAte[pessoa] = cumprir.last.inicio;
      suspensoes.add(
        Suspensao(
          pessoaId: pessoa,
          timeId: time,
          motivo: motivo,
          jogos: jogos,
          partidaOrigemId: origem.id,
          partidasACumprir: [for (final p in cumprir) p.id],
        ),
      );
    }
  }

  // ---------------------------------------------------------------- consultas

  /// Atletas suspensos na partida (tela "Suspensos" e súmula em branco).
  List<Suspensao> suspensosPara(String partidaId) =>
      suspensoes.where((s) => s.partidasACumprir.contains(partidaId)).toList();

  /// Atletas com amarelos a um passo da suspensão no ciclo da partida,
  /// contando só os jogos anteriores a ela.
  List<Pendurado> penduradosPara(String partidaId) {
    final p = _partida(partidaId);
    final ciclo = cicloDe(p);
    final resultado = <Pendurado>[];
    _amarelosContados.forEach((pessoa, lista) {
      final anteriores = lista.where(
        (e) => cicloDe(e.$1) == ciclo && e.$1.inicio.isBefore(p.inicio),
      );
      if (anteriores.isEmpty) return;
      final time = anteriores.last.$2;
      if (!p.envolve(time)) return;
      final n = anteriores.length;
      if (n % params.amarelosParaSuspensao == params.amarelosParaSuspensao - 1) {
        resultado.add(Pendurado(pessoa, time, n));
      }
    });
    return resultado;
  }

  /// Pendências que impedem alguém de jogar (ou o técnico de ficar à beira
  /// do campo) na partida: originadas antes dela e não pagas até o prazo
  /// (24 h antes). Antes do prazo ninguém aparece aqui, porque ainda dá
  /// tempo de pagar.
  List<Pendencia> impedimentosPara(String partidaId) {
    final p = _partida(partidaId);
    final limite = p.inicio.subtract(params.prazoQuitacao);
    if (agora.isBefore(limite)) return const [];
    return pendencias
        .where((x) => p.envolve(x.timeId) && x.origemEm.isBefore(p.inicio) && !x.pagaAte(limite))
        .toList();
  }

  /// Pessoas impedidas na partida (uma vez cada).
  Set<String> impedidosPara(String partidaId) => {
    for (final x in impedimentosPara(partidaId)) x.pessoaId,
  };

  List<Pendencia> pendenciasDe(String pessoaId) =>
      pendencias.where((p) => p.pessoaId == pessoaId).toList();

  List<Pendencia> pendenciasEmAberto() => pendencias.where((p) => p.pagoEm == null).toList();

  /// Amarelos que contam para o acúmulo no ciclo atual da pessoa.
  int amarelosNoCiclo(String pessoaId, Ciclo ciclo) =>
      (_amarelosContados[pessoaId] ?? const []).where((e) => cicloDe(e.$1) == ciclo).length;
}
