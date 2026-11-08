# Calcio Firenze

App do campeonato Calcio Firenze (Master 2027), em Flutter, para Android, iPhone e web.

## O que já funciona (versão 0.1)

- **Regras do regulamento** (`packages/calcio_regras`): cartões e valores, prazo de 24 h e multa por atraso, suspensões (vermelho, 3 amarelos, decisões), pendurados, impedidos por pendência, pontuação com W.O. e perda de pontos, os 7 desempates + sorteio, chaveamento do mata-mata e rebaixamento. 49 testes.
- **App do Torcedor** com dados de exemplo: Splash, "Como você quer entrar?", Início, Jogos (por rodada), detalhe do jogo, Classificação e Suspensos/Pendurados. Tudo calculado pelas regras acima.
- Identidade do Figma: cores, Montserrat e Open Sans (dentro do app), logo em tamanho fixo.

Próximas etapas: login e perfil Participante, súmula e gestão da Organização, ligação com o Firebase.

## Rodar no seu computador

Requisitos: [Flutter](https://docs.flutter.dev/get-started/install) estável (3.32 ou mais novo).

Na primeira vez, gere as pastas de Android, iPhone e web (o código do app não é alterado):

```bash
flutter create . --platforms android,ios,web --org br.com.calciofirenze --project-name calcio_firenze
rm -f test/widget_test.dart   # arquivo de exemplo que o comando cria
```

Depois:

```bash
flutter pub get
flutter run                 # celular ou emulador conectado
flutter run -d chrome       # versão web
```

Testes:

```bash
flutter test                                   # telas e casos de uso
cd packages/calcio_regras && dart test         # regras do regulamento
```

## Organização do código

Veja [docs/arquitetura.md](docs/arquitetura.md): camadas, quem calcula o quê e o modelo de dados do Firestore. As interpretações do regulamento estão em [packages/calcio_regras/README.md](packages/calcio_regras/README.md).

As skills de Flutter (gabuldev/flutter-skills, MIT) estão em `.claude/skills` e são carregadas pelo Claude Code ao trabalhar neste repositório.

## Créditos

Fontes Montserrat e Open Sans sob a SIL Open Font License (`assets/fonts/OFL-*.txt`).
