import 'package:calcio_regras/calcio_regras.dart';

import '../entities/temporada.dart';
import 'gerar_calendario.dart';

/// Situação do mata-mata de um turno, ou da grande final: a próxima etapa
/// que a Organização pode criar, ou por que ainda não pode.
class SituacaoMataMata {
  /// Etapa que pode ser criada agora. Nula se ainda não dá ou se acabou.
  final Fase? proxima;

  /// Jogos propostos para a [proxima] etapa, com data sugerida.
  final List<Partida> propostos;

  /// Times que jogam pelo empate nos [propostos] (quartas).
  final Map<String, String> vantagem;

  /// Verdadeiro se alguma data proposta não está no calendário oficial e
  /// precisa ser confirmada pela Organização.
  final bool dataProvisoria;

  /// Por que a próxima etapa ainda não pode ser criada.
  final String? aguardando;

  /// Campeão do turno (ou da temporada, na grande final), quando decidido.
  final String? campeao;

  /// Etapa criada por último cujos jogos ainda não têm súmula: pode ser
  /// desfeita.
  final Fase? desfazivel;
  final List<String> idsDesfaziveis;

  const SituacaoMataMata({
    this.proxima,
    this.propostos = const [],
    this.vantagem = const {},
    this.dataProvisoria = false,
    this.aguardando,
    this.campeao,
    this.desfazivel,
    this.idsDesfaziveis = const [],
  });
}

/// Monta as etapas eliminatórias (art. 16) a partir da classificação e dos
/// resultados: quartas (3º x 6º e 4º x 5º), semifinais, final do turno e a
/// grande final entre os campeões dos turnos, se forem diferentes. Nas
/// categorias com 4 classificados não há quartas: semifinal 1º x 4º e
/// 2º x 3º.
class MataMata {
  final String local;
  const MataMata({this.local = 'Arena Gugu'});

  static const _etapas = [Fase.quartas, Fase.semifinal, Fase.finalTurno];

  SituacaoMataMata turno(DadosTemporada d, int turno) {
    final doTurno = d.partidas.where((p) => p.turno == turno).toList();
    final classificatorios = doTurno.where((p) => p.fase == Fase.classificatoria).toList();
    final desfazer = _desfazivel(doTurno);

    if (classificatorios.isEmpty) {
      return const SituacaoMataMata(aguardando: 'Gere o calendário do turno primeiro.');
    }
    final faltam = classificatorios.where((p) => !p.encerrada).length;
    if (faltam > 0) {
      return SituacaoMataMata(
        aguardando: faltam == 1
            ? 'Falta 1 jogo da fase classificatória.'
            : 'Faltam $faltam jogos da fase classificatória.',
      );
    }

    final categoria = d.categoria;
    final tabela = classificacaoDoTurno(
      turno: turno,
      times: [for (final t in d.times) t.id],
      partidas: d.partidas,
      ajustes: d.ajustes,
      ordemSorteio: d.ordemSorteio(turno),
      params: d.parametros,
    );
    // Um empate decidido só por sorteio entre os classificados e o primeiro
    // de fora muda o chaveamento.
    final corte = categoria.classificados + 1;
    if (tabela.take(corte).any((l) => l.aguardaSorteio)) {
      return SituacaoMataMata(
        aguardando: 'Há times empatados em todos os critérios entre os $corte primeiros. Faça o '
            'sorteio do art. 42 e registre o resultado na aba Tabela.',
        desfazivel: desfazer?.$1,
        idsDesfaziveis: desfazer?.$2 ?? const [],
      );
    }
    int posicao(String id) => tabela.firstWhere((l) => l.timeId == id).posicao;

    List<Partida> da(Fase f) => doTurno.where((p) => p.fase == f).toList();
    List<String>? vencedores(List<Partida> jogos) {
      final v = [for (final p in jogos) vencedorMataMata(p)];
      return v.contains(null) ? null : v.cast<String>();
    }

    SituacaoMataMata propor(Fase fase, List<Confronto> confrontos) {
      final (datas, provisoria) = _datas(d, turno, confrontos.length);
      final propostos = [
        for (final (i, c) in confrontos.indexed)
          Partida(
            id: _id(turno, fase, i, confrontos.length),
            turno: turno,
            fase: fase,
            mandanteId: c.mandanteId,
            visitanteId: c.visitanteId,
            inicio: datas[i],
            local: local,
          ),
      ];
      return SituacaoMataMata(
        proxima: fase,
        propostos: propostos,
        vantagem: {
          for (final c in confrontos)
            if (c.vantagemEmpate != null) c.mandanteId: c.vantagemEmpate!,
        },
        dataProvisoria: provisoria,
        desfazivel: desfazer?.$1,
        idsDesfaziveis: desfazer?.$2 ?? const [],
      );
    }

    SituacaoMataMata esperando(String texto) => SituacaoMataMata(
      aguardando: texto,
      desfazivel: desfazer?.$1,
      idsDesfaziveis: desfazer?.$2 ?? const [],
    );

    final semis = da(Fase.semifinal);
    if (categoria.temQuartas) {
      final quartas = da(Fase.quartas);
      if (quartas.isEmpty) return propor(Fase.quartas, chaveamentoQuartas(tabela));
      final vQuartas = vencedores(quartas);
      if (vQuartas == null) return esperando('Aguardando o resultado das quartas de final.');
      if (semis.isEmpty) {
        return propor(Fase.semifinal, chaveamentoSemifinais(tabela, vQuartas));
      }
    } else if (semis.isEmpty) {
      return propor(Fase.semifinal, chaveamentoSemifinaisDiretas(tabela));
    }
    final vSemis = vencedores(semis);
    if (vSemis == null) return esperando('Aguardando o resultado das semifinais.');

    final finais = da(Fase.finalTurno);
    if (finais.isEmpty) {
      // Na final não há vantagem (art. 16.3); manda o mais bem colocado.
      final ordem = [...vSemis]..sort((a, b) => posicao(a).compareTo(posicao(b)));
      return propor(Fase.finalTurno, [Confronto(ordem.first, ordem.last)]);
    }
    final campeao = vencedores(finais)?.single;
    if (campeao == null) return esperando('Aguardando o resultado da final.');
    return SituacaoMataMata(
      campeao: campeao,
      desfazivel: desfazer?.$1,
      idsDesfaziveis: desfazer?.$2 ?? const [],
    );
  }

  /// Grande final (art. 16.4): só existe se os campeões dos turnos forem
  /// diferentes. Se o mesmo time venceu os dois, ele é o campeão.
  SituacaoMataMata grandeFinal(DadosTemporada d) {
    final c1 = turno(d, 1).campeao;
    final c2 = turno(d, 2).campeao;
    if (c1 == null || c2 == null) {
      return const SituacaoMataMata(
        aguardando: 'A grande final é definida depois das finais dos dois turnos.',
      );
    }
    final direto = campeaoSemGrandeFinal(c1, c2);
    if (direto != null) return SituacaoMataMata(campeao: direto);

    final jogo = d.partidas.where((p) => p.fase == Fase.grandeFinal).firstOrNull;
    if (jogo == null) {
      final (datas, provisoria) = _datas(d, 0, 1);
      return SituacaoMataMata(
        proxima: Fase.grandeFinal,
        propostos: [
          Partida(
            id: 'grande-final',
            turno: 0,
            fase: Fase.grandeFinal,
            mandanteId: c1,
            visitanteId: c2,
            inicio: datas.single,
            local: local,
          ),
        ],
        dataProvisoria: provisoria,
      );
    }
    final campeao = vencedorMataMata(jogo);
    return SituacaoMataMata(
      campeao: campeao,
      aguardando: campeao == null ? 'Aguardando o resultado da grande final.' : null,
      desfazivel: jogo.encerrada ? null : Fase.grandeFinal,
      idsDesfaziveis: jogo.encerrada ? const [] : [jogo.id],
    );
  }

  static String _id(int turno, Fase fase, int i, int total) {
    final nome = switch (fase) {
      Fase.quartas => 'quartas',
      Fase.semifinal => 'semi',
      Fase.finalTurno => 'final',
      _ => fase.name,
    };
    return total == 1 ? 't$turno-$nome' : 't$turno-$nome-${i + 1}';
  }

  /// A última etapa eliminatória criada, se nenhum jogo dela tem súmula.
  static (Fase, List<String>)? _desfazivel(List<Partida> doTurno) {
    for (final f in _etapas.reversed) {
      final jogos = doTurno.where((p) => p.fase == f).toList();
      if (jogos.isEmpty) continue;
      if (jogos.any((p) => p.encerrada)) return null;
      return (f, [for (final p in jogos) p.id]);
    }
    return null;
  }

  /// Próximos horários oficiais livres depois do último jogo do turno. Se
  /// faltarem, propõe uma semana depois, às 20:30 e 21:30, e marca as datas
  /// como provisórias.
  static (List<DateTime>, bool) _datas(DadosTemporada d, int turno, int quantos) {
    final ocupados = {for (final p in d.partidas) p.inicio};
    final jogos = turno == 0 ? d.partidas : d.partidas.where((p) => p.turno == turno);
    final ultimo = jogos.map((p) => p.inicio).fold<DateTime?>(
      null,
      (a, b) => a == null || b.isAfter(a) ? b : a,
    );
    final oficiais = [...?horariosDe(d.categoria)[turno]]..sort();
    final livres = [
      for (final h in oficiais)
        if ((ultimo == null || h.isAfter(ultimo)) && !ocupados.contains(h)) h,
    ];
    if (livres.length >= quantos) return (livres.take(quantos).toList(), false);

    final base = ultimo ?? DateTime.now();
    final dia = DateTime(base.year, base.month, base.day).add(const Duration(days: 7));
    return (
      [for (var i = 0; i < quantos; i++) dia.add(Duration(hours: 20 + i, minutes: 30))],
      true,
    );
  }
}
