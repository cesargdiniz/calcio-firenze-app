const _dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

String _2(int n) => n.toString().padLeft(2, '0');

/// "Sex 19/02 · 20:30"
String dataHoraJogo(DateTime d) =>
    '${_dias[d.weekday - 1]} ${_2(d.day)}/${_2(d.month)} · ${_2(d.hour)}:${_2(d.minute)}';

/// "R$ 30,00" a partir de centavos.
String reais(int centavos) {
  final inteiro = centavos ~/ 100;
  final resto = _2(centavos % 100);
  final milhar = inteiro.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );
  return 'R\$ $milhar,$resto';
}
