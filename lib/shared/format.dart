const _dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

/// "Sex 19/02 · 20:30"
String dataHoraJogo(DateTime d) =>
    '${_dias[d.weekday - 1]} ${_doisDigitos(d.day)}/${_doisDigitos(d.month)} · ${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

/// "Sex 19/02"
String dataCurta(DateTime d) =>
    '${_dias[d.weekday - 1]} ${_doisDigitos(d.day)}/${_doisDigitos(d.month)}';

/// "R$ 30,00" a partir de centavos.
String reais(int centavos) {
  final inteiro = centavos ~/ 100;
  final resto = _doisDigitos(centavos % 100);
  final milhar = inteiro.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );
  return 'R\$ $milhar,$resto';
}

/// Centavos a partir do que foi digitado ("100", "100,50", "R$ 1.250,00").
/// Nulo se não for um valor válido.
int? centavosDe(String texto) {
  final limpo = texto.replaceAll(RegExp(r'[R$\s.]'), '');
  if (limpo.isEmpty) return 0;
  final m = RegExp(r'^(\d+)(?:,(\d{1,2}))?$').firstMatch(limpo);
  if (m == null) return null;
  final centavos = (m[2] ?? '').padRight(2, '0');
  return int.parse(m[1]!) * 100 + int.parse(centavos);
}

/// "100" ou "100,50", para preencher um campo de valor.
String valorParaCampo(int centavos) {
  if (centavos == 0) return '';
  final resto = centavos % 100;
  return resto == 0 ? '${centavos ~/ 100}' : '${centavos ~/ 100},${_doisDigitos(resto)}';
}
