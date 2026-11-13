import 'package:calcio_regras/calcio_regras.dart';
import 'package:go_router/go_router.dart';

import '../modules/entrada/entrada_screen.dart';
import '../modules/entrada/splash_screen.dart';
import '../modules/organizacao/organizacao_shell.dart';
import '../modules/organizacao/screens/decisoes_screen.dart';
import '../modules/organizacao/screens/disciplina_screen.dart';
import '../modules/organizacao/screens/gestao_screen.dart';
import '../modules/organizacao/screens/jogo_org_screen.dart';
import '../modules/organizacao/screens/movimentacoes_screen.dart';
import '../modules/organizacao/screens/org_jogos_screen.dart';
import '../modules/organizacao/screens/sumula_screen.dart';
import '../modules/organizacao/screens/importar_elencos_screen.dart';
import '../modules/organizacao/screens/org_inicio_screen.dart';
import '../modules/organizacao/screens/parametros_screen.dart';
import '../modules/organizacao/screens/pedidos_screen.dart';
import '../modules/organizacao/screens/times_screen.dart';
import '../modules/participante/participante_shell.dart';
import '../modules/participante/screens/avisos_screen.dart';
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
            GoRoute(
              path: '/participante',
              builder: (_, _) => const ParticipanteInicioScreen(),
              routes: [GoRoute(path: 'avisos', builder: (_, _) => const AvisosScreen())],
            ),
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

    // Organização: acesso restrito a quem está em organizacao/{uid}.
    StatefulShellRoute.indexedStack(
      builder: (_, _, navegacao) => OrganizacaoShell(navegacao: navegacao),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/organizacao', builder: (_, _) => const OrgInicioScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/organizacao/jogos',
              builder: (_, _) => const OrgJogosScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, e) => JogoOrgScreen(partidaId: e.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'sumula',
                      builder: (_, e) => SumulaScreen(
                        partidaId: e.pathParameters['id']!,
                        inicial: e.extra is Sumula ? e.extra! as Sumula : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/organizacao/disciplina', builder: (_, _) => const DisciplinaScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/organizacao/tabela', builder: (_, _) => const ClassificacaoScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/organizacao/gestao',
              builder: (_, _) => const GestaoScreen(),
              routes: [
                GoRoute(path: 'pedidos', builder: (_, _) => const PedidosScreen()),
                GoRoute(path: 'elencos', builder: (_, _) => const ImportarElencosScreen()),
                GoRoute(path: 'parametros', builder: (_, _) => const ParametrosScreen()),
                GoRoute(
                  path: 'movimentacoes',
                  builder: (_, _) => const MovimentacoesScreen(),
                  routes: [
                    GoRoute(path: 'nova', builder: (_, _) => const NovaMovimentacaoScreen()),
                  ],
                ),
                GoRoute(
                  path: 'decisoes',
                  builder: (_, _) => const DecisoesScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, e) => EditarDecisaoScreen(decisaoId: e.pathParameters['id']!),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'times',
                  builder: (_, _) => const TimesScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, e) => EditarTimeScreen(timeId: e.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
