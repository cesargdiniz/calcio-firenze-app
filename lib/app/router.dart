import 'package:go_router/go_router.dart';

import '../modules/entrada/entrada_screen.dart';
import '../modules/entrada/splash_screen.dart';
import '../modules/participante/participante_shell.dart';
import '../modules/participante/screens/meu_time_screen.dart';
import '../modules/participante/screens/participante_inicio_screen.dart';
import '../modules/participante/screens/perfil_screen.dart';
import '../modules/torcedor/screens/classificacao_screen.dart';
import '../modules/torcedor/screens/inicio_screen.dart';
import '../modules/torcedor/screens/jogo_detalhe_screen.dart';
import '../modules/torcedor/screens/jogos_screen.dart';
import '../modules/torcedor/screens/suspensos_screen.dart';
import '../modules/torcedor/torcedor_shell.dart';

GoRoute _jogos(String base) => GoRoute(
  path: base,
  builder: (_, _) => JogosScreen(rotaBase: base),
  routes: [
    GoRoute(
      path: ':id',
      builder: (_, estado) =>
          JogoDetalheScreen(partidaId: estado.pathParameters['id']!, voltarPara: base),
    ),
  ],
);

GoRouter criarRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/entrar', builder: (_, _) => const EntradaScreen()),

    // Torcedor: sem login.
    StatefulShellRoute.indexedStack(
      builder: (_, _, navegacao) => TorcedorShell(navegacao: navegacao),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/torcedor', builder: (_, _) => const InicioScreen())],
        ),
        StatefulShellBranch(routes: [_jogos('/torcedor/jogos')]),
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

    // Participante: o shell mostra login / vínculo até a conta ser aprovada.
    StatefulShellRoute.indexedStack(
      builder: (_, _, navegacao) => ParticipanteShell(navegacao: navegacao),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/participante', builder: (_, _) => const ParticipanteInicioScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/participante/time', builder: (_, _) => const MeuTimeScreen())],
        ),
        StatefulShellBranch(routes: [_jogos('/participante/jogos')]),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/participante/tabela', builder: (_, _) => const ClassificacaoScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/participante/perfil', builder: (_, _) => const PerfilScreen())],
        ),
      ],
    ),
  ],
);
