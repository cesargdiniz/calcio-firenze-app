import 'dart:typed_data';

import 'package:calcio_regras/calcio_regras.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/temporada.dart';
import '../../../shared/seletor_imagem.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../../../shared/widgets/escudo.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';
import 'pedidos_screen.dart';
import '../../../shared/layout/tela_larga.dart';

/// O7 · Gestão · Times da temporada
class TimesScreen extends StatelessWidget {
  const TimesScreen({super.key});

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) {
      final times = [...o.dados.times]..sort((a, b) => a.nome.compareTo(b.nome));
      return ListView(
        padding: TelaLarga.margens(context),
        children: [
          const VoltarGestao(),
          CabecalhoTela(
            'Times da temporada',
            subtitulo: '${times.length} de ${o.categoria.times} clubes · ${o.dados.nome}',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (times.length < o.categoria.times) ...[
            Text(
              'A categoria ${o.categoria.nome} tem ${o.categoria.times} times. Cadastre os que '
              'faltam antes de importar os elencos e sortear o calendário.',
              style: AppTextStyles.corpo,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.go('/organizacao/gestao/times/novo'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar time'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (times.isNotEmpty)
            Cartao(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final t in times)
                  ListTile(
                    leading: Escudo(t),
                    title: Text(t.nome, style: AppTextStyles.nome),
                    subtitle: Text(_resumo(o, t), style: AppTextStyles.pequeno),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.dica),
                    onTap: () => context.go('/organizacao/gestao/times/${t.id}'),
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );

  static String _resumo(OrgPronta o, Time t) {
    if (o.dados.demonstracao) return '${t.sigla} · elenco ainda não importado';
    final atletas = o.dados.pessoas
        .where((p) => p.timeId == t.id && p.funcao == Funcao.atleta && p.ativo)
        .length;
    final dirigente = o.dados.pessoas.where((p) => p.timeId == t.id && p.dirigente).firstOrNull;
    return [
      t.sigla,
      '$atletas atletas',
      if (dirigente != null) 'Dirigente: ${dirigente.nome}',
    ].join(' · ');
  }
}

/// Paleta para a cor do time (cores dos clubes do Figma + neutras).
const _paleta = [
  0xFF0A3D91, 0xFF1B5CC1, 0xFF12A0D7, 0xFF5B2A86, 0xFF8E1F2F, 0xFFC8102E, //
  0xFFD7263D, 0xFF00A752, 0xFF008E44, 0xFFF4B43A, 0xFF2B2B2B, 0xFF6E6E6E,
];

/// O8 · Gestão · Editar time
class EditarTimeScreen extends StatelessWidget {
  final String timeId;
  const EditarTimeScreen({super.key, required this.timeId});

  @override
  Widget build(BuildContext context) => ComOrg(
    builder: (context, o) {
      if (timeId == 'novo') {
        return _EditarTime(
          key: ValueKey('novo-${o.dados.id}'),
          time: Time(id: '', nome: '', sigla: '', cor: _paleta.first),
          siglasEmUso: {for (final t in o.dados.times) t.id},
        );
      }
      final t = o.time(timeId);
      if (t == null) return const Center(child: Text('Time não encontrado.'));
      return _EditarTime(time: t, key: ValueKey(t.id));
    },
  );
}

class _EditarTime extends StatefulWidget {
  final Time time;

  /// Preenchido só ao cadastrar um time novo: siglas que já existem.
  final Set<String>? siglasEmUso;
  const _EditarTime({super.key, required this.time, this.siglasEmUso});

  bool get novo => siglasEmUso != null;

  @override
  State<_EditarTime> createState() => _EditarTimeState();
}

class _EditarTimeState extends State<_EditarTime> {
  late final _nome = TextEditingController(text: widget.time.nome);
  late final _sigla = TextEditingController(text: widget.time.sigla);
  late int _cor = widget.time.cor;
  late Uint8List? _escudo = widget.time.escudo;
  bool _salvando = false;
  bool _lendoEscudo = false;

  @override
  void dispose() {
    _nome.dispose();
    _sigla.dispose();
    super.dispose();
  }

  String get _siglaDigitada => _sigla.text.trim().toUpperCase();

  /// Problema na sigla de um time novo, ou nulo.
  String? get _erroSigla {
    if (!widget.novo) return null;
    final s = _siglaDigitada;
    if (s.length < 2 || s.length > 4 || !RegExp(r'^[A-Z0-9]+$').hasMatch(s)) {
      return 'De 2 a 4 letras ou números, sem espaço.';
    }
    if (widget.siglasEmUso!.contains(s)) return 'Já existe um time com esta sigla.';
    return null;
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty || _erroSigla != null) return;
    final sigla = widget.novo ? _siglaDigitada : widget.time.sigla;
    setState(() => _salvando = true);
    try {
      await context.read<OrganizacaoController>().salvarTime(
        Time(
          id: widget.novo ? sigla : widget.time.id,
          nome: nome,
          sigla: sigla,
          cor: _cor,
          escudoUrl: widget.time.escudoUrl,
          escudo: _escudo,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Time salvo.')));
        context.go('/organizacao/gestao/times');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Não foi possível salvar.')));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  /// Escolhe a imagem no aparelho. Só vale depois de "Salvar".
  Future<void> _enviarEscudo() async {
    final seletor = context.read<SeletorImagem>();
    setState(() => _lendoEscudo = true);
    try {
      final imagem = await seletor.escolherEscudo();
      if (imagem != null && mounted) setState(() => _escudo = imagem);
    } on ImagemGrandeDemais {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A imagem ficou pesada demais. Tente um escudo mais simples.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível ler a imagem. Envie um PNG ou JPG.')),
        );
      }
    } finally {
      if (mounted) setState(() => _lendoEscudo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previa = Time(
      id: widget.time.id,
      nome: _nome.text,
      sigla: widget.novo ? _siglaDigitada : widget.time.sigla,
      cor: _cor,
      escudo: _escudo,
    );
    return ListView(
      padding: TelaLarga.margens(context),
      children: [
        const VoltarGestao(rotulo: 'Times da temporada', rota: '/organizacao/gestao/times'),
        Row(
          children: [
            Escudo(previa, tamanho: 72),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    onPressed: _lendoEscudo || _salvando ? null : _enviarEscudo,
                    child: Text(
                      _lendoEscudo
                          ? 'Lendo a imagem…'
                          : _escudo == null
                          ? 'Enviar escudo'
                          : 'Trocar escudo',
                    ),
                  ),
                  if (_escudo != null)
                    TextButton(
                      onPressed: _salvando ? null : () => setState(() => _escudo = null),
                      child: const Text('Remover escudo'),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _escudo == null
              ? 'Sem imagem, o app mostra a cor com a sigla. Envie um PNG, de preferência '
                    'quadrado e com fundo transparente.'
              : 'O app reduz a imagem para caber em 256 px. A troca vale depois de salvar.',
          style: AppTextStyles.pequeno,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _nome,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Nome do clube',
            border: OutlineInputBorder(borderRadius: AppRadius.botao),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.novo)
          TextField(
            controller: _sigla,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.characters,
            maxLength: 4,
            decoration: InputDecoration(
              labelText: 'Sigla (não muda depois)',
              errorText: _sigla.text.isEmpty ? null : _erroSigla,
              border: const OutlineInputBorder(borderRadius: AppRadius.botao),
            ),
          )
        else
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Sigla',
              border: OutlineInputBorder(borderRadius: AppRadius.botao),
            ),
            child: Text(widget.time.sigla, style: AppTextStyles.nome),
          ),
        const TituloSecao('Cor do time'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in _paleta)
              Semantics(
                button: true,
                selected: c == _cor,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _cor = c),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c == _cor ? AppColors.tinta : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: _salvando || _nome.text.trim().isEmpty || _erroSigla != null ? null : _salvar,
          child: Text(_salvando ? 'Salvando…' : (widget.novo ? 'Adicionar time' : 'Salvar')),
        ),
      ],
    );
  }
}
