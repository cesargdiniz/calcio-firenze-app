import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/format.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/card_jogo.dart';
import '../../../shared/widgets/logo_calcio.dart';
import '../../torcedor/torcedor_controller.dart';
import '../avisos.dart';
import '../participante_controller.dart';
import '../widgets/pendencia_card.dart';

/// Entrega o estado "pronto" às telas do Participante.
class ComParticipante extends StatelessWidget {
  final Widget Function(BuildContext context, ParticipantePronto p) builder;
  const ComParticipante({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => BlocBuilder<ParticipanteController, ParticipanteStatus>(
    builder: (context, s) =>
        s is ParticipantePronto ? builder(context, s) : const SizedBox.shrink(),
  );
}

/// P1 · Participante · Início
class ParticipanteInicioScreen extends StatelessWidget {
  const ParticipanteInicioScreen({super.key});

  @override
  Widget build(BuildContext context) => ComParticipante(
    builder: (context, p) {
      final s = p.pessoal;
      final primeiroNome = s.pessoa.nome.split(' ').first;
      final painel = switch (context.watch<TorcedorController>().state) {
        TorcedorPronto(:final painel) => painel,
        _ => null,
      };
      final rodada = s.proximoJogo?.rodada;
      final avisos = avisosDoParticipante(p).length;

      return ListView(
        padding: AppSpacing.tela,
        children: [
          Row(
            children: [
              const LogoCalcio(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $primeiroNome',
                      style: AppTextStyles.tituloSecao.copyWith(fontSize: 20),
                    ),
                    Text('${p.papel.rotulo} · ${s.time.nome}', style: AppTextStyles.subtitulo),
                  ],
                ),
              ),
              IconButton(
                tooltip: avisos == 0 ? 'Avisos' : 'Avisos ($avisos)',
                onPressed: () => context.go('/participante/avisos'),
                icon: Badge(
                  isLabelVisible: avisos > 0,
                  backgroundColor: AppColors.vermelho,
                  label: Text('$avisos'),
                  child: const Icon(Icons.notifications_none_rounded, color: AppColors.tinta),
                ),
              ),
            ],
          ),
          const TituloSecao('Minha situação'),
          Cartao(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Cartões no turno', style: AppTextStyles.rotulo)),
                    Etiqueta(
                      s.amarelosNoCiclo == 1 ? '1 amarelo' : '${s.amarelosNoCiclo} amarelos',
                      cor: AppColors.amareloEscuro,
                      fundo: AppColors.amareloSuave,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rodada == null ? 'Próximo jogo' : 'Rodada $rodada',
                        style: AppTextStyles.rotulo,
                      ),
                    ),
                    _SituacaoEtiqueta(p),
                  ],
                ),
                ..._alertas(p, rodada),
              ],
            ),
          ),
          const TituloSecao('Pendências'),
          if (s.pendencias.isEmpty)
            const Text('Nenhuma pendência. Tudo em dia.', style: AppTextStyles.corpo)
          else ...[
            for (final x in s.pendencias) PendenciaCard(x),
            const Text(
              'O pagamento é feito à Organização, fora do app. Depois de confirmado, '
              'a pendência aparece como quitada.',
              style: AppTextStyles.pequeno,
            ),
          ],
          if (s.proximoJogo != null && painel != null) ...[
            const TituloSecao('Próximo jogo'),
            CardJogo(
              partida: s.proximoJogo!,
              mandante: painel.time(s.proximoJogo!.mandanteId),
              visitante: painel.time(s.proximoJogo!.visitanteId),
              local: painel.local,
              onTap: () => context.go('/participante/jogos/${s.proximoJogo!.id}'),
            ),
          ],
        ],
      );
    },
  );

  static List<Widget> _alertas(ParticipantePronto p, int? rodada) {
    final s = p.pessoal;
    final ehTecnico = s.pessoa.funcao == Funcao.tecnico;
    final rodadaTxt = rodada == null ? 'o próximo jogo' : 'a Rodada $rodada';
    Widget alerta(String texto, Color fundo) => Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: fundo, borderRadius: AppRadius.botao),
      child: Text(texto, style: AppTextStyles.corpo.copyWith(color: AppColors.tinta)),
    );

    return [
      if (s.suspenso)
        alerta('Suspenso para $rodadaTxt · ${s.motivoSuspensao}.', AppColors.vermelhoSuave),
      if (s.impedido)
        alerta(
          ehTecnico
              ? 'Pendência vencida: você não pode ficar à beira do campo em $rodadaTxt até quitar.'
              : 'Pendência vencida: você não pode jogar $rodadaTxt até quitar.',
          AppColors.vermelhoSuave,
        ),
      if (!s.impedido && s.totalEmAberto > 0 && s.proximoPrazo != null)
        alerta(
          'Pague ${reais(s.totalEmAberto)} até ${dataHoraJogo(s.proximoPrazo!)} '
          'para ${ehTecnico ? 'ficar à beira do campo' : 'jogar'} $rodadaTxt.',
          AppColors.amareloSuave,
        ),
      if (s.pendurado && !s.suspenso)
        alerta('Pendurado: mais um amarelo e você cumpre suspensão.', AppColors.amareloSuave),
    ];
  }
}

class _SituacaoEtiqueta extends StatelessWidget {
  final ParticipantePronto p;
  const _SituacaoEtiqueta(this.p);

  @override
  Widget build(BuildContext context) {
    final s = p.pessoal;
    if (s.suspenso) {
      return const Etiqueta('Suspenso', cor: AppColors.vermelho, fundo: AppColors.vermelhoSuave);
    }
    if (s.impedido) {
      return const Etiqueta('Impedido', cor: AppColors.vermelho, fundo: AppColors.vermelhoSuave);
    }
    if (s.pendurado) {
      return const Etiqueta(
        'Pendurado',
        cor: AppColors.amareloEscuro,
        fundo: AppColors.amareloSuave,
      );
    }
    return const Etiqueta.verde('Liberado');
  }
}
