import 'package:go_router/go_router.dart';

import '../modules/entrada/entrada_screen.dart';
import '../modules/entrada/splash_screen.dart';
import '../modules/torcedor/screens/classificacao_screen.dart';
import '../modules/torcedor/screens/inicio_screen.dart';
import '../modules/torcedor/screens/jogo_detalhe_screen.dart';
import '../modules/torcedor/screens/jogos_screen.dart';
import '../modules/torcedor/screens/suspensos_screen.dart';
import '../modules/torcedor/torcedor_shell.dart';

GoRouter criarRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/entrar', builder: (_, _) => const EntradaScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, navegacao) => TorcedorShell(navegacao: navegacao),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/torcedor', builder: (_, _) => const InicioScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/torcedor/jogos',
              builder: (_, _) => const JogosScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, estado) =>
                      JogoDetalheScreen(partidaId: estado.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/torcedor/tabela', builder: (_, _) => const ClassificacaoScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/torcedor/suspensos', builder: (_, _) => const SuspensosScreen()),
          ],
        ),
      ],
    ),
  ],
);
