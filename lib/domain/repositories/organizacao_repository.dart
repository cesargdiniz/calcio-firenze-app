import 'package:calcio_regras/calcio_regras.dart';

import '../entities/categoria.dart';
import '../entities/temporada.dart';
import '../entities/usuario.dart';

/// Acesso de uma conta à área da Organização.
class AcessoOrganizacao {
  /// A conta está em `organizacao/{uid}`.
  final bool ehOrganizacao;

  /// Categorias que a conta organiza. Vazia numa conta da Organização: ainda
  /// não informou a categoria no perfil.
  final List<Categoria> categorias;

  const AcessoOrganizacao({required this.ehOrganizacao, this.categorias = const []});

  static const nenhum = AcessoOrganizacao(ehOrganizacao: false);
}

/// Quem é da Organização e de quais categorias (documento
/// `organizacao/{uid}`, campo `temporadas`).
abstract interface class OrganizacaoRepository {
  Stream<AcessoOrganizacao> acesso(String uid);

  /// O organizador informa no perfil a categoria que organiza. Só vale na
  /// primeira vez: trocar depois é feito no console do Firebase.
  Future<void> definirCategoria(String uid, Categoria categoria);
}

/// Gravações da Organização na temporada.
abstract interface class GestaoRepository {
  /// Pedidos de vínculo da categoria aguardando decisão. Cada usuário vem só
  /// com o vínculo desta categoria.
  Stream<List<Usuario>> observarPedidos(String temporadaId);

  /// Contas já aprovadas na categoria (para avisar de nome vinculado a duas
  /// contas).
  Stream<List<Usuario>> observarAprovados(String temporadaId);

  Future<void> decidirPedido(String temporadaId, String uid, StatusVinculo status);

  /// Cria ou atualiza os times da temporada.
  Future<void> salvarTimes(String temporadaId, List<Time> times);

  /// Substitui o elenco de cada time informado.
  Future<void> importarElencos(String temporadaId, Map<String, List<Pessoa>> porTime);

  /// Cria ou substitui partidas (calendário, agenda e súmula).
  Future<void> salvarPartidas(String temporadaId, List<Partida> partidas);

  Future<void> excluirPartidas(String temporadaId, List<String> ids);

  /// Quitação de uma pendência (o pagamento é feito fora do app).
  Future<void> registrarPagamento(String temporadaId, String pendenciaId, DateTime pagoEm);

  Future<void> desfazerPagamento(String temporadaId, String pendenciaId);

  /// Cria ou substitui uma decisão da Governança (suspensão e/ou multa).
  Future<void> salvarDecisao(String temporadaId, DecisaoDisciplinar decisao);

  /// Exclui a decisão e a quitação da multa dela, se houver.
  Future<void> excluirDecisao(String temporadaId, String decisaoId);

  /// Valores do regulamento usados em todos os cálculos da temporada.
  Future<void> salvarParametros(String temporadaId, Parametros parametros);

  /// Patrocinador que dá nome à competição na súmula; nulo para tirar.
  Future<void> salvarPatrocinador(String temporadaId, String? patrocinador);

  /// Saídas de elenco registradas (só a Organização lê).
  Stream<List<Movimentacao>> observarMovimentacoes(String temporadaId);

  /// Registra a saída: marca a pessoa como fora do elenco a partir da data
  /// e, na troca de goleiro, inscreve o [substituto].
  Future<void> registrarMovimentacao(
    String temporadaId,
    Movimentacao movimentacao, {
    Pessoa? substituto,
  });

  /// Apaga o registro, devolve a pessoa ao elenco e remove o substituto.
  Future<void> desfazerMovimentacao(String temporadaId, Movimentacao movimentacao);
}
