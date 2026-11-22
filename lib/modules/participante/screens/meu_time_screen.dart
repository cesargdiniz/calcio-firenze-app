import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/usecases/montar_situacao.dart';
import '../../../shared/format.dart';
import '../../../domain/entities/usuario.dart';
import '../../../shared/seletor_imagem.dart';
import '../participante_controller.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../widgets/pendencia_card.dart';
import 'participante_inicio_screen.dart';
import '../../../shared/layout/tela_larga.dart';

/// P2 · Participante · Meu time
class MeuTimeScreen extends StatelessWidget {
  const MeuTimeScreen({super.key});

  @override
  Widget build(BuildContext context) => ComParticipante(
    builder: (context, p) {
      final t = p.time;
      final proximo = t.proximoJogo;
      final nomes = {for (final l in t.elenco) l.pessoa.id: l.pessoa.nome};

      return ListView(
        padding: TelaLarga.margens(context),
        children: [
          Row(
            children: [
              Escudo(t.time, tamanho: 56),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.time.nome, style: AppTextStyles.tituloTela.copyWith(fontSize: 24)),
                    Text(
                      proximo == null
                          ? 'Sem jogo marcado'
                          : 'Próximo: ${proximo.rodada != null ? 'Rodada ${proximo.rodada} · ' : ''}'
                                '${dataHoraJogo(proximo.inicio)}',
                      style: AppTextStyles.subtitulo,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (p.papel == Papel.dirigente) const _TrocarEscudo(),
          const TituloSecao('Antes da rodada'),
          Cartao(
            child: Column(
              children: [
                _Contagem('Suspensos', t.contar(SituacaoAtleta.suspenso), AppColors.vermelho),
                _Contagem(
                  'Impedidos por pendência',
                  t.contar(SituacaoAtleta.impedido),
                  AppColors.vermelho,
                ),
                _Contagem(
                  'Pendurados',
                  t.contar(SituacaoAtleta.pendurado),
                  AppColors.amareloEscuro,
                ),
                if (p.papel.veTime)
                  _Contagem(
                    'Com pendência a pagar',
                    t.contar(SituacaoAtleta.pendencia),
                    AppColors.amareloEscuro,
                  ),
              ],
            ),
          ),
          if (p.papel.veTime && t.pendenciasDoTime.isNotEmpty) ...[
            const TituloSecao('Pendências do time'),
            for (final x in t.pendenciasDoTime)
              PendenciaCard(x, nome: nomes[x.pessoaId] ?? x.pessoaId),
          ],
          const TituloSecao('Elenco'),
          Cartao(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(children: [for (final l in t.elenco) _LinhaAtleta(l)]),
          ),
        ],
      );
    },
  );
}

class _Contagem extends StatelessWidget {
  final String rotulo;
  final int n;
  final Color cor;
  const _Contagem(this.rotulo, this.n, this.cor);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(rotulo, style: AppTextStyles.corpo)),
        Text('$n', style: AppTextStyles.nome.copyWith(color: n == 0 ? AppColors.dica : cor)),
      ],
    ),
  );
}

/// Componente "Lista/Atleta do time" do Figma.
class _LinhaAtleta extends StatelessWidget {
  final LinhaElenco l;
  const _LinhaAtleta(this.l);

  @override
  Widget build(BuildContext context) {
    final (rotulo, cor, fundo) = switch (l.situacao) {
      SituacaoAtleta.liberado => ('Liberado', AppColors.verde, AppColors.verdeSuave),
      SituacaoAtleta.pendurado => ('Pendurado', AppColors.amareloEscuro, AppColors.amareloSuave),
      SituacaoAtleta.pendencia => ('Pendência', AppColors.amareloEscuro, AppColors.amareloSuave),
      SituacaoAtleta.impedido => ('Impedido', AppColors.vermelho, AppColors.vermelhoSuave),
      SituacaoAtleta.suspenso => ('Suspenso', AppColors.vermelho, AppColors.vermelhoSuave),
    };
    final x = l.pessoa;
    final papel = [
      if (x.funcao == Funcao.tecnico) 'Técnico',
      if (x.goleiro) 'Goleiro',
      if (x.dirigente) 'Dirigente',
      if (l.detalhe != null && l.situacao != SituacaoAtleta.liberado) l.detalhe!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(x.numero == null ? '' : '${x.numero}', style: AppTextStyles.rotulo),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(x.nome.toUpperCase(), style: AppTextStyles.nome.copyWith(fontSize: 12)),
                if (papel.isNotEmpty) Text(papel, style: AppTextStyles.pequeno),
              ],
            ),
          ),
          Etiqueta(rotulo, cor: cor, fundo: fundo),
        ],
      ),
    );
  }
}

/// O dirigente troca o escudo do time pelo do celular (galeria ou arquivos).
class _TrocarEscudo extends StatefulWidget {
  const _TrocarEscudo();

  @override
  State<_TrocarEscudo> createState() => _TrocarEscudoState();
}

class _TrocarEscudoState extends State<_TrocarEscudo> {
  bool _gravando = false;

  Future<void> _trocar() async {
    final seletor = context.read<SeletorImagem>();
    final controller = context.read<ParticipanteController>();
    final avisos = ScaffoldMessenger.of(context);
    setState(() => _gravando = true);
    try {
      final imagem = await seletor.escolherEscudo();
      if (imagem == null) return;
      await controller.trocarEscudo(imagem);
      avisos.showSnackBar(const SnackBar(content: Text('Escudo do time atualizado.')));
    } on ImagemGrandeDemais {
      avisos.showSnackBar(
        const SnackBar(content: Text('A imagem ficou pesada demais. Tente um escudo mais simples.')),
      );
    } catch (_) {
      avisos.showSnackBar(const SnackBar(content: Text('Não foi possível trocar o escudo.')));
    } finally {
      if (mounted) setState(() => _gravando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: _gravando ? null : _trocar,
      icon: const Icon(Icons.image_outlined, color: AppColors.verde),
      label: Text(_gravando ? 'Enviando…' : 'Trocar escudo do time'),
    ),
  );
}
