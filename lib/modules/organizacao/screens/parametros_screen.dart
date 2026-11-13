import 'package:calcio_regras/calcio_regras.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/format.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/basicos.dart';
import '../organizacao_controller.dart';
import '../organizacao_shell.dart';
import 'pedidos_screen.dart';

/// Um valor ajustável do regulamento.
class _Campo {
  final String chave;
  final String rotulo;
  final bool emReais;
  final int minimo;
  final int Function(Parametros) ler;

  const _Campo(this.chave, this.rotulo, this.ler, {this.emReais = false, this.minimo = 0});

  String texto(Parametros p) => emReais ? valorParaCampo(ler(p)) : '${ler(p)}';

  String exibir(Parametros p) => emReais ? reais(ler(p)) : '${ler(p)}';

  /// Valor digitado, ou nulo se não for um número aceito.
  int? interpretar(String digitado) {
    final limpo = digitado.trim();
    if (limpo.isEmpty) return null;
    final valor = emReais ? centavosDe(limpo) : int.tryParse(limpo);
    return valor == null || valor < minimo ? null : valor;
  }
}

int _vitoria(Parametros p) => p.pontosVitoria;
int _empate(Parametros p) => p.pontosEmpate;
int _derrota(Parametros p) => p.pontosDerrota;
int _amarelo(Parametros p) => p.valorAmarelo;
int _vermelho(Parametros p) => p.valorVermelho;
int _acumulo(Parametros p) => p.amarelosParaSuspensao;
int _expulsao(Parametros p) => p.jogosPorExpulsao;
int _prazo(Parametros p) => p.prazoQuitacao.inHours;
int _golsWo(Parametros p) => p.golsWo;
int _deducaoWo(Parametros p) => p.deducaoWo;
int _rebaixados(Parametros p) => p.rebaixados;

const _secoes = [
  (
    titulo: 'Pontuação · art. 42',
    campos: [
      _Campo('vitoria', 'Pontos por vitória', _vitoria),
      _Campo('empate', 'Pontos por empate', _empate),
      _Campo('derrota', 'Pontos por derrota', _derrota),
    ],
  ),
  (
    titulo: 'Cartões · arts. 66, 67 e 72',
    campos: [
      _Campo('amarelo', 'Cartão amarelo (R\$)', _amarelo, emReais: true),
      _Campo('vermelho', 'Cartão vermelho (R\$)', _vermelho, emReais: true),
    ],
  ),
  (
    titulo: 'Suspensões · arts. 69 e 73',
    campos: [
      _Campo('acumulo', 'Amarelos que geram 1 jogo de suspensão', _acumulo, minimo: 2),
      _Campo('expulsao', 'Jogos de suspensão por expulsão', _expulsao),
    ],
  ),
  (
    titulo: 'Quitação · arts. 68 e 73.7',
    campos: [_Campo('prazo', 'Horas antes do próximo jogo para quitar', _prazo)],
  ),
  (
    titulo: 'W.O. · art. 75',
    campos: [
      _Campo('golsWo', 'Gols para o time presente', _golsWo),
      _Campo('deducaoWo', 'Pontos perdidos pelo time ausente', _deducaoWo),
    ],
  ),
  (
    titulo: 'Rebaixamento · art. 89',
    campos: [_Campo('rebaixados', 'Clubes rebaixados por temporada', _rebaixados)],
  ),
];

/// O11 · Gestão · Regulamento e parâmetros
class ParametrosScreen extends StatelessWidget {
  const ParametrosScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      ComOrg(builder: (context, o) => _Formulario(atuais: o.dados.parametros));
}

class _Formulario extends StatefulWidget {
  final Parametros atuais;
  const _Formulario({required this.atuais});

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  late final Map<String, TextEditingController> _textos = {
    for (final s in _secoes)
      for (final c in s.campos) c.chave: TextEditingController(text: c.texto(widget.atuais)),
  };
  bool _salvando = false;

  @override
  void dispose() {
    for (final t in _textos.values) {
      t.dispose();
    }
    super.dispose();
  }

  int? _valor(String chave) {
    for (final s in _secoes) {
      for (final c in s.campos) {
        if (c.chave == chave) return c.interpretar(_textos[chave]!.text);
      }
    }
    return null;
  }

  bool get _valido => _textos.keys.every((chave) => _valor(chave) != null);

  void _restaurar() => setState(() {
    for (final s in _secoes) {
      for (final c in s.campos) {
        _textos[c.chave]!.text = c.texto(Parametros.master2027);
      }
    }
  });

  void _avisar(String texto) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _salvar() async {
    if (!_valido) return;
    final novos = Parametros(
      pontosVitoria: _valor('vitoria')!,
      pontosEmpate: _valor('empate')!,
      pontosDerrota: _valor('derrota')!,
      valorAmarelo: _valor('amarelo')!,
      valorVermelho: _valor('vermelho')!,
      amarelosParaSuspensao: _valor('acumulo')!,
      jogosPorExpulsao: _valor('expulsao')!,
      prazoQuitacao: Duration(hours: _valor('prazo')!),
      golsWo: _valor('golsWo')!,
      deducaoWo: _valor('deducaoWo')!,
      classificadosMataMata: widget.atuais.classificadosMataMata,
      rebaixados: _valor('rebaixados')!,
    );
    final controller = context.read<OrganizacaoController>();
    setState(() => _salvando = true);
    try {
      await controller.salvarParametros(novos);
      if (mounted) _avisar('Parâmetros salvos.');
    } catch (_) {
      if (mounted) _avisar('Não foi possível salvar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppSpacing.tela,
    children: [
      const VoltarGestao(),
      const CabecalhoTela('Regulamento e parâmetros', subtitulo: 'Master · Temporada 2027'),
      const SizedBox(height: AppSpacing.md),
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.amareloSuave,
          borderRadius: AppRadius.botao,
        ),
        child: Text(
          'Estes valores entram em todos os cálculos: tabela, pendências, suspensões e '
          'rebaixamento. Ao salvar, a temporada inteira é recalculada, inclusive os jogos já '
          'encerrados. O regulamento não permite mudar regra com a edição em andamento.',
          style: AppTextStyles.corpo.copyWith(color: AppColors.tinta),
        ),
      ),
      for (final s in _secoes) ...[
        TituloSecao(s.titulo),
        for (final c in s.campos)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: TextField(
              controller: _textos[c.chave],
              keyboardType: TextInputType.numberWithOptions(decimal: c.emReais),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: c.rotulo,
                helperText: 'Regulamento 2027: ${c.exibir(Parametros.master2027)}',
                errorText: _valor(c.chave) != null
                    ? null
                    : c.minimo > 0
                    ? 'Informe um número a partir de ${c.minimo}.'
                    : 'Informe um número válido.',
                border: const OutlineInputBorder(borderRadius: AppRadius.botao),
              ),
            ),
          ),
      ],
      const Text(
        'O mata-mata segue fixo em 6 classificados (art. 16), porque o chaveamento das '
        'quartas e semifinais depende desse número.',
        style: AppTextStyles.pequeno,
      ),
      const SizedBox(height: AppSpacing.lg),
      FilledButton(
        onPressed: _salvando || !_valido ? null : _salvar,
        child: Text(_salvando ? 'Salvando…' : 'Salvar parâmetros'),
      ),
      TextButton(
        onPressed: _salvando ? null : _restaurar,
        child: const Text('Preencher com os valores do regulamento'),
      ),
    ],
  );
}
