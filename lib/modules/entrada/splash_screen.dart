import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/repositories/preferencias_repository.dart';
import '../../shared/layout/tela_larga.dart';
import '../../shared/theme/app_colors.dart';

/// Como cada forma do fundo entra em cena.
enum _Entrada {
  /// Faixa que desliza de baixo para cima, ao longo da própria diagonal.
  sobe,

  /// Faixa que desliza de cima para baixo, na mesma diagonal.
  desce,

  /// Triângulo que cresce no lugar.
  surge,
}

/// Uma forma do fundo, na posição em que está no Figma (quadro de 414 × 896).
class _Forma {
  final String arquivo;
  final double x;
  final double y;
  final double largura;
  final double altura;
  final _Entrada entrada;

  const _Forma(this.arquivo, this.x, this.y, this.largura, this.altura, this.entrada);
}

/// Na ordem das camadas do Figma: a primeira fica por baixo.
const _formas = [
  _Forma('fill50', 195.8, 454, 386, 442, _Entrada.sobe),
  _Forma('fill51', 186.8, 139, 200, 183, _Entrada.desce),
  _Forma('fill54', 281.8, 529, 121, 110, _Entrada.sobe),
  _Forma('fill56', 54.8, 741, 199, 155, _Entrada.desce),
  _Forma('fill57', 243.8, 112, 337, 472, _Entrada.sobe),
  _Forma('fill66', 348.8, 11, 233, 282, _Entrada.desce),
  _Forma('fill67', 253.8, 293, 76, 84, _Entrada.sobe),
  _Forma('fill68', 119.8, 219, 76, 84, _Entrada.desce),
  _Forma('fill69', -60.2, 335, 76, 84, _Entrada.sobe),
  _Forma('fill70', 324.8, 179, 121, 134, _Entrada.desce),
  _Forma('fill71', 251.8, 792, 100, 104, _Entrada.sobe),
  _Forma('fill72', 29.8, 353, 121, 134, _Entrada.desce),
  _Forma('fill73', 364.8, 704, 76, 84, _Entrada.sobe),
  _Forma('fill74', 374, 122, 76, 84, _Entrada.desce),
  _Forma('fill76', 61.8, 109, 89, 92, _Entrada.surge),
  _Forma('fill77', 187.8, 612, 81, 94, _Entrada.surge),
  _Forma('fill78', -14.2, 217, 81, 94, _Entrada.surge),
  _Forma('fill81', 229.8, 77, 29, 33, _Entrada.surge),
  _Forma('fill84', -198, 546, 428, 470, _Entrada.sobe),
  _Forma('fill85', -84.2, 384, 170, 215, _Entrada.desce),
  _Forma('fill100', 95, 546, 136, 168, _Entrada.sobe),
  _Forma('fill79', 37.8, 578, 29, 33, _Entrada.surge),
  _Forma('fill80', -7.2, 246, 29, 33, _Entrada.surge),
  _Forma('fill101', -21.2, 470, 102, 143, _Entrada.desce),
];

/// Direção das faixas (de baixo à esquerda para cima à direita), em pixels
/// do quadro do Figma, com comprimento suficiente para tirar a faixa da tela.
const _percurso = Offset(430, -600);

const _quadro = Size(414, 896);
const _logo = Rect.fromLTWH(82, 257, 250, 372);

/// 01 · Splash. As faixas cruzam a tela, os triângulos surgem e o escudo
/// entra por último; depois de uma pausa curta, segue para a escolha do perfil.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Fração do tempo em que a animação termina; o resto é a pausa final.
  static const fimDaAnimacao = 0.76;

  static const duracao = Duration(milliseconds: 2100);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controle = AnimationController(
    vsync: this,
    duration: SplashScreen.duracao,
  )..addStatusListener(_aoTerminar);

  bool _iniciou = false;

  /// Perfil escolhido em outra abertura: o app vai direto para ele.
  String? _perfilSalvo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciou) return;
    _iniciou = true;
    // Com "reduzir movimento" ligado no aparelho, mostra a tela pronta e só
    // aguarda a pausa final.
    final semMovimento = MediaQuery.disableAnimationsOf(context);
    _controle.forward(from: semMovimento ? SplashScreen.fimDaAnimacao : 0);
    context.read<PreferenciasRepository>().perfil().then((r) => _perfilSalvo = r);
  }

  void _aoTerminar(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) context.go(_perfilSalvo ?? '/entrar');
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  /// Progresso de 0 a 1 de um trecho da animação, já com a curva aplicada.
  double _trecho(double inicio, double fim, Curve curva) =>
      Interval(inicio, fim, curve: curva).transform(_controle.value);

  Widget _forma(int indice, _Forma f) {
    final imagem = SvgPicture.asset(
      'assets/splash/${f.arquivo}.svg',
      width: f.largura,
      height: f.altura,
      fit: BoxFit.fill,
    );
    final Widget animada;
    if (f.entrada == _Entrada.surge) {
      // Os triângulos surgem em sequência, quando as faixas estão chegando.
      final atraso = (indice % 6) * 0.02;
      final t = _trecho(0.30 + atraso, 0.56 + atraso, Curves.easeOutBack);
      animada = Transform.scale(scale: t.clamp(0.0, 1.2), child: imagem);
    } else {
      // Cada faixa começa um pouco depois da anterior.
      final atraso = indice * 0.012;
      final t = _trecho(atraso, 0.36 + atraso, Curves.easeOutCubic);
      final sentido = f.entrada == _Entrada.sobe ? -1.0 : 1.0;
      animada = Transform.translate(offset: _percurso * (sentido * (1 - t)), child: imagem);
    }
    return Positioned(left: f.x, top: f.y, child: animada);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.fundo,
    body: Semantics(
      label: 'Calcio Firenze',
      image: true,
      child: ExcludeSemantics(
        child: ClipRect(
          child: SizedBox.expand(
            // O quadro do Figma cobre a tela inteira, em qualquer proporção.
            // No computador (janela deitada) ele apareceria gigante: fica
            // inteiro, no centro, na altura da janela.
            child: FittedBox(
              fit: TelaLarga.menuLateral(context) ? BoxFit.contain : BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: ClipRect(
                child: SizedBox.fromSize(
                size: _quadro,
                child: AnimatedBuilder(
                  animation: _controle,
                  builder: (context, _) {
                    final entrada = _trecho(0.44, SplashScreen.fimDaAnimacao, Curves.easeOutBack);
                    final opacidade = _trecho(0.44, 0.60, Curves.easeOut);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final (i, f) in _formas.indexed) _forma(i, f),
                        Positioned.fromRect(
                          rect: _logo,
                          child: Opacity(
                            opacity: opacidade,
                            child: Transform.scale(
                              scale: 0.72 + 0.28 * entrada,
                              child: Image.asset('assets/splash/logo.png', fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
