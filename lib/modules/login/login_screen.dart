import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/widgets/logo_calcio.dart';
import 'login_controller.dart';

/// 03 · Login do Participante e 03b · Link enviado.
class LoginScreen extends StatelessWidget {
  final String titulo;
  final String subtitulo;

  const LoginScreen({
    super.key,
    this.titulo = 'Entrar como Participante',
    this.subtitulo = 'Atletas, técnicos e dirigentes inscritos na temporada.',
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (c) => LoginController(c.read<AuthRepository>()),
    child: _Login(titulo: titulo, subtitulo: subtitulo),
  );
}

class _Login extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  const _Login({required this.titulo, required this.subtitulo});

  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _comSenha = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<LoginController>();
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<LoginController, LoginStatus>(
          builder: (context, status) {
            final ocupado = status is LoginEnviando;
            if (status is LoginLinkEnviado) {
              return _LinkEnviado(
                email: status.email,
                onReenviar: () => controller.enviarLink(status.email),
                onOutroEmail: controller.voltar,
              );
            }
            return ListView(
              padding: AppSpacing.tela,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.go('/entrar'),
                    icon: const Icon(Icons.chevron_left_rounded, color: AppColors.oliva),
                    label: Text('Voltar', style: AppTextStyles.subtitulo.copyWith(fontSize: 14)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Align(alignment: Alignment.centerLeft, child: LogoCalcio()),
                const SizedBox(height: AppSpacing.lg),
                Text(widget.titulo, style: AppTextStyles.tituloTela),
                const SizedBox(height: AppSpacing.xs),
                Text(widget.subtitulo, style: AppTextStyles.corpo),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  onPressed: ocupado ? null : controller.entrarComGoogle,
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.verde,
                    ),
                  ),
                  label: const Text('Continuar com Google'),
                ),
                // A App Store exige o login com Apple onde há login com Google.
                if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: ocupado ? null : controller.entrarComApple,
                    icon: const Icon(Icons.apple, color: AppColors.tinta),
                    label: const Text('Continuar com Apple'),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('ou', style: AppTextStyles.pequeno),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    hintText: 'seu@email.com',
                    border: OutlineInputBorder(borderRadius: AppRadius.botao),
                  ),
                ),
                if (_comSenha) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _senha,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(borderRadius: AppRadius.botao),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (!_comSenha)
                  FilledButton(
                    onPressed: ocupado ? null : () => controller.enviarLink(_email.text),
                    child: const Text('Receber link por e-mail'),
                  )
                else ...[
                  FilledButton(
                    onPressed: ocupado
                        ? null
                        : () => controller.entrarComSenha(_email.text, _senha.text),
                    child: const Text('Entrar'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: ocupado
                        ? null
                        : () => controller.criarConta(_email.text, _senha.text),
                    child: const Text('Criar conta com senha'),
                  ),
                  TextButton(
                    onPressed: ocupado ? null : () => controller.redefinirSenha(_email.text),
                    child: const Text('Esqueci a senha'),
                  ),
                ],
                if (ocupado)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: Center(child: CircularProgressIndicator(color: AppColors.verde)),
                  ),
                if (status is LoginErro)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      status.mensagem,
                      style: AppTextStyles.corpo.copyWith(color: AppColors.vermelho),
                    ),
                  ),
                if (status is LoginSenhaRedefinida)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      'Enviamos um e-mail para ${status.email} com o link para criar uma nova senha.',
                      style: AppTextStyles.corpo,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => setState(() {
                    _comSenha = !_comSenha;
                    controller.voltar();
                  }),
                  child: Text(_comSenha ? 'Prefiro receber um link' : 'Prefiro entrar com senha'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LinkEnviado extends StatelessWidget {
  final String email;
  final VoidCallback onReenviar;
  final VoidCallback onOutroEmail;

  const _LinkEnviado({required this.email, required this.onReenviar, required this.onOutroEmail});

  @override
  Widget build(BuildContext context) => ListView(
    padding: AppSpacing.tela,
    children: [
      const SizedBox(height: AppSpacing.xl),
      const Align(alignment: Alignment.centerLeft, child: LogoCalcio()),
      const SizedBox(height: AppSpacing.xl),
      const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.verde),
      const SizedBox(height: AppSpacing.md),
      const Text('Confira seu e-mail', style: AppTextStyles.tituloTela),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Enviamos um link de acesso para $email. Abra o link neste mesmo aparelho '
        'e navegador para entrar. Se não chegar em alguns minutos, olhe o spam.',
        style: AppTextStyles.corpo,
      ),
      const SizedBox(height: AppSpacing.xl),
      OutlinedButton(onPressed: onReenviar, child: const Text('Reenviar link')),
      TextButton(onPressed: onOutroEmail, child: const Text('Usar outro e-mail')),
    ],
  );
}
