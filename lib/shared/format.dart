const _dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

/// "Sex 19/02 · 20:30"
String dataHoraJogo(DateTime d) =>
    '${_dias[d.weekday - 1]} ${_doisDigitos(d.day)}/${_doisDigitos(d.month)} · ${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

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
