import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme/app_text_styles.dart';

/// Endereços públicos do app (Firebase Hosting).
const siteCalcio = 'https://calcio-firenze.web.app';
const urlPrivacidade = '$siteCalcio/privacidade';
const urlSuporte = '$siteCalcio/suporte';

/// Abre um endereço no navegador do aparelho.
Future<void> abrirLink(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Links de privacidade e suporte, discretos, no rodapé de uma tela.
class LinksLegais extends StatelessWidget {
  const LinksLegais({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    children: [
      TextButton(
        onPressed: () => abrirLink(urlPrivacidade),
        child: const Text('Política de privacidade', style: AppTextStyles.pequeno),
      ),
      TextButton(
        onPressed: () => abrirLink(urlSuporte),
        child: const Text('Suporte', style: AppTextStyles.pequeno),
      ),
    ],
  );
}
