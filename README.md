# Calcio Firenze

App do campeonato Calcio Firenze (Master 2027), em Flutter, para Android, iPhone e web.

## O que já funciona

- **Regras do regulamento** (`packages/calcio_regras`): cartões e valores, prazo de 24 h e multa por atraso, suspensões (vermelho, 3 amarelos, decisões), pendurados, impedidos por pendência, pontuação com W.O. e perda de pontos, os 7 desempates + sorteio, chaveamento do mata-mata e rebaixamento.
- **Torcedor** (sem login): Início, Jogos por rodada, detalhe do jogo, Classificação e Suspensos/Pendurados.
- **Participante**: login (Google, link por e-mail ou senha), pedido de vínculo ao elenco, Meu Time e Perfil.
- **Organização**: pedidos de vínculo, times, importação de elencos, calendário com sorteio, súmula, disciplina (pendências e quitações), decisões e punições (suspensão e multa fora da súmula, arts. 87 e 88), movimentações de elenco (demissão, desligamento, lesão e troca de goleiro, arts. 82 a 83.2) e parâmetros do regulamento ajustáveis (pontos, valores dos cartões, prazos).
- **Firebase** (projeto `calcio-firenze`, web): login e dados da temporada no Firestore. Enquanto não houver elencos nem jogos cadastrados, o app mostra uma temporada de exemplo.
- Identidade do Figma: cores, Montserrat e Open Sans (dentro do app), logo em tamanho fixo.

Próximas etapas: ambiente de teste separado da produção, login com Apple e as versões de Android e iPhone.

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

## Galeria de telas

Para ver todas as telas sem abrir o app: no GitHub, em Actions → Galeria de telas → Run workflow. As imagens, geradas com os dados de exemplo, saem no branch `galeria-telas-capturas`. No computador:

```bash
flutter test test/galeria/galeria_telas.dart --update-goldens   # imagens em test/galeria/telas/
```

## Organização do código

Veja [docs/arquitetura.md](docs/arquitetura.md): camadas, quem calcula o quê e o modelo de dados do Firestore. As interpretações do regulamento estão em [packages/calcio_regras/README.md](packages/calcio_regras/README.md).

As skills de Flutter (gabuldev/flutter-skills, MIT) estão em `.claude/skills` e são carregadas pelo Claude Code ao trabalhar neste repositório.

## Créditos

Fontes Montserrat e Open Sans sob a SIL Open Font License (`assets/fonts/OFL-*.txt`).
