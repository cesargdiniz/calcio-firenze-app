import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/categoria.dart';
import '../../../domain/entities/temporada.dart';
import '../../../domain/entities/usuario.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../../categoria/categoria_controller.dart';
import '../participante_controller.dart';

/// 04 · Vincular ao elenco. O pedido vai para a Organização aprovar.
class VincularScreen extends StatefulWidget {
  final DadosTemporada dados;
  final bool recusado;

  /// Outras categorias em que a conta já tem vínculo (atalho para trocar).
  final List<Categoria> comVinculo;

  const VincularScreen({
    super.key,
    required this.dados,
    this.recusado = false,
    this.comVinculo = const [],
  });

  @override
  State<VincularScreen> createState() => _VincularScreenState();
}

class _VincularScreenState extends State<VincularScreen> {
  Papel _papel = Papel.atleta;
  String? _timeId;
  String? _pessoaId;
  bool _enviando = false;
  String? _erro;

  List<Pessoa> get _candidatos {
    if (_timeId == null) return const [];
    final doTime = widget.dados.pessoas.where((p) => p.timeId == _timeId && p.ativo);
    final Iterable<Pessoa> filtrados = switch (_papel) {
      Papel.atleta => doTime.where((p) => p.funcao == Funcao.atleta),
      Papel.dirigente => doTime.where((p) => p.dirigente),
      Papel.tecnico => doTime.where((p) => p.funcao == Funcao.tecnico),
    };
    return filtrados.toList()..sort((a, b) => a.nome.compareTo(b.nome));
  }

  Future<void> _enviar() async {
    final pessoa = widget.dados.pessoas.firstWhere((p) => p.id == _pessoaId);
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await context.read<ParticipanteController>().pedirVinculo(_papel, pessoa);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível enviar o pedido. Tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final times = [...widget.dados.times]..sort((a, b) => a.nome.compareTo(b.nome));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.tela,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  await context.read<ParticipanteController>().sair();
                  if (context.mounted) context.go('/entrar');
                },
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.oliva),
                label: Text('Sair', style: AppTextStyles.subtitulo.copyWith(fontSize: 14)),
              ),
            ),
            CabecalhoTela('Vincular ao elenco', subtitulo: widget.dados.nome),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Diga quem você é na categoria ${widget.dados.categoria.nome}. A Organização '
              'confere e aprova o pedido. Se você joga em mais de uma categoria, peça o '
              'vínculo em cada uma.',
              style: AppTextStyles.corpo,
            ),
            for (final c in widget.comVinculo)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.read<CategoriaController>().escolher(c),
                  icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.verde),
                  label: Text('Ver ${c.nome}, onde você já tem vínculo'),
                ),
              ),
            if (widget.dados.demonstracao)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.amareloSuave,
                  borderRadius: AppRadius.botao,
                ),
                child: const Text(
                  'Os elencos desta categoria ainda não foram cadastrados pela Organização. O '
                  'pedido de vínculo abre assim que eles estiverem no app.',
                  style: AppTextStyles.corpo,
                ),
              )
            else if (widget.dados.times.isEmpty || widget.dados.pessoas.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.amareloSuave,
                  borderRadius: AppRadius.botao,
                ),
                child: const Text(
                  'Os elencos desta categoria ainda não foram cadastrados pela Organização.',
                  style: AppTextStyles.corpo,
                ),
              ),
            if (widget.recusado)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.vermelhoSuave,
                  borderRadius: AppRadius.botao,
                ),
                child: const Text(
                  'Seu pedido anterior não foi aprovado. Confira os dados ou fale com a Organização.',
                  style: AppTextStyles.corpo,
                ),
              ),
            if (!widget.dados.demonstracao) ...[
            const TituloSecao('Função'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final p in Papel.values)
                  ChipFiltro(
                    p.rotulo,
                    ativo: p == _papel,
                    onTap: () => setState(() {
                      _papel = p;
                      _pessoaId = null;
                    }),
                  ),
              ],
            ),
            const TituloSecao('Seu time'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final t in times)
                  _ChipTime(
                    time: t,
                    ativo: t.id == _timeId,
                    onTap: () => setState(() {
                      _timeId = t.id;
                      _pessoaId = null;
                    }),
                  ),
              ],
            ),
            if (_timeId != null) ...[
              TituloSecao(_papel == Papel.atleta ? 'Seu nome no elenco' : 'Seu nome'),
              if (_candidatos.isEmpty)
                const Text('Ninguém com essa função neste time.', style: AppTextStyles.pequeno)
              else
                Cartao(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      for (final p in _candidatos)
                        ListTile(
                          dense: true,
                          selected: p.id == _pessoaId,
                          selectedColor: AppColors.verde,
                          leading: SizedBox(
                            width: 28,
                            child: Text(
                              p.numero == null ? '' : '#${p.numero}',
                              style: AppTextStyles.rotulo,
                            ),
                          ),
                          title: Text(p.nome.toUpperCase(), style: AppTextStyles.nome),
                          subtitle: p.goleiro
                              ? const Text('Goleiro', style: AppTextStyles.pequeno)
                              : null,
                          trailing: p.id == _pessoaId
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.verde)
                              : null,
                          onTap: () => setState(() => _pessoaId = p.id),
                        ),
                    ],
                  ),
                ),
            ],
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(_erro!, style: AppTextStyles.corpo.copyWith(color: AppColors.vermelho)),
              ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _pessoaId == null || _enviando ? null : _enviar,
              child: Text(_enviando ? 'Enviando…' : 'Enviar para aprovação'),
            ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipTime extends StatelessWidget {
  final Time time;
  final bool ativo;
  final VoidCallback onTap;

  const _ChipTime({required this.time, required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    selected: ativo,
    button: true,
    child: Material(
      color: ativo ? AppColors.verdeSuave : AppColors.cartao,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.chip,
        side: BorderSide(color: ativo ? AppColors.verde : AppColors.linha),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Escudo(time, tamanho: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(time.nome, style: AppTextStyles.rotulo),
            ],
          ),
        ),
      ),
    ),
  );
}
