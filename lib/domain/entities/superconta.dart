/// Contas que rearranjam o calendário de todas as categorias e da Copa
/// (Gestão › Rearranjar calendário). A mesma lista está nas regras do
/// Firestore (`firebase/firestore.rules`): mude as duas juntas.
const supercontas = {'cesargdiniz@gmail.com'};

bool ehSuperconta(String? email) => email != null && supercontas.contains(email.toLowerCase());
