import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/logo_calcio.dart';
import 'saida_imagem.dart';

/// Botão do cabeçalho que abre o compartilhamento da tela.
class BotaoCompartilhar extends StatelessWidget {
  final VoidCallback onPressed;
  const BotaoCompartilhar({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('compartilhar'),
    tooltip: 'Compartilhar como imagem',
    onPressed: onPressed,
    icon: const Icon(Icons.ios_share_rounded, color: AppColors.verde),
  );
}

/// Mostra a prévia de [conteudo] num cartão com o nome da competição e
/// compartilha como imagem (WhatsApp, salvar na galeria, e-mail).
///
/// [conteudo] é montado com a largura de um celular e tudo o que tiver de
/// altura: a imagem sai inteira, mesmo o que na tela precisa de rolagem.
Future<void> compartilharComoImagem(
  BuildContext context, {
  required String titulo,
  required String subtitulo,
  required Widget conteudo,
  required String nomeArquivo,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _Previa(
    titulo: titulo,
    subtitulo: subtitulo,
    conteudo: conteudo,
    nomeArquivo: nomeArquivo,
  ),
);

class _Previa extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final Widget conteudo;
  final String nomeArquivo;
  const _Previa({
    required this.titulo,
    required this.subtitulo,
    required this.conteudo,
    required this.nomeArquivo,
  });

  @override
  State<_Previa> createState() => _PreviaState();
}

class _PreviaState extends State<_Previa> {
  final _chave = GlobalKey();
  bool _gerando = false;

  Future<void> _compartilhar() async {
    final saida = context.read<SaidaImagem>();
    final avisos = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    setState(() => _gerando = true);
    try {
      final limite = _chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagem = await limite.toImage(pixelRatio: 3);
      final dados = await imagem.toByteData(format: ui.ImageByteFormat.png);
      imagem.dispose();
      await saida.compartilhar(
        dados!.buffer.asUint8List(),
        nomeArquivo: widget.nomeArquivo,
        legenda: '${widget.titulo} · ${widget.subtitulo}',
      );
      navegador.pop();
    } catch (_) {
      avisos.showSnackBar(const SnackBar(content: Text('Não foi possível gerar a imagem.')));
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              // A imagem tem largura fixa; em tela estreita a prévia encolhe.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border.all(color: AppColors.linha)),
                  child: RepaintBoundary(
                    key: _chave,
                    child: _CartaoDaImagem(
                      titulo: widget.titulo,
                      subtitulo: widget.subtitulo,
                      conteudo: widget.conteudo,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: FilledButton.icon(
              onPressed: _gerando ? null : _compartilhar,
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(_gerando ? 'Gerando…' : 'Compartilhar imagem'),
            ),
          ),
        ],
      ),
    ),
  );
}

/// O que vai na imagem: logo, título, conteúdo e rodapé com a data.
class _CartaoDaImagem extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget conteudo;
  const _CartaoDaImagem({required this.titulo, required this.subtitulo, required this.conteudo});

  @override
  Widget build(BuildContext context) => Container(
    width: 380,
    color: AppColors.fundo,
    padding: const EdgeInsets.all(AppSpacing.lg),
    // Sem rolagem nem toques: só a figura.
    child: IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const LogoCalcio(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: AppTextStyles.tituloSecao),
                    Text(subtitulo, style: AppTextStyles.subtitulo),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          conteudo,
          const SizedBox(height: AppSpacing.md),
          Text(
            'Calcio Firenze · ${dataCurta(DateTime.now())}',
            style: AppTextStyles.pequeno.copyWith(color: AppColors.dica),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
