# Publicar no iPhone (TestFlight)

O app de iPhone é compilado e enviado ao TestFlight pela rotina **iPhone - TestFlight** do GitHub, em uma máquina Mac. Ela roda quando uma versão é marcada (`v1.0.0`, por exemplo) ou à mão, em Actions.

Dados fixos do projeto:

| | |
|---|---|
| Identificador (Bundle ID) | `br.com.calciofirenze.app` |
| Conta Apple | SOLVED SOLUCOES EM GEOINFORMACAO LTDA, time `496DP4XG3F` |
| Nome do perfil de provisionamento | `Calcio Firenze App Store` (tem de ser exatamente este) |

## Preparação, feita uma vez

Os comandos são para o **Git Bash**, que vem com o Git para Windows. Trabalhe em uma pasta fora do projeto, para nenhum desses arquivos ir parar no repositório.

### 1. Identificador

developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → **+** → App IDs → App. Bundle ID **Explicit** `br.com.calciofirenze.app`, com **Sign In with Apple** marcado.

### 2. App no App Store Connect

appstoreconnect.apple.com → Apps → **+** → Novo app. Plataforma iOS, nome "Calcio Firenze", idioma Português (Brasil), o identificador acima e um SKU qualquer (`calciofirenze`).

### 3. Firebase

No console do Firebase, projeto `calcio-firenze`:

- Configurações do projeto → Seus apps → **Adicionar app** → iOS, com o identificador acima. Baixe o `GoogleService-Info.plist`: os dados dele entram em `lib/firebase_options.dart`.
- Authentication → Método de login → ative **Apple**.

### 4. Certificado de distribuição

```bash
openssl genrsa -out dist.key 2048
openssl req -new -key dist.key -out dist.csr -subj "/emailAddress=SEU_EMAIL/CN=Calcio Firenze/C=BR"
```

No portal da Apple: Certificates → **+** → **Apple Distribution** → envie o `dist.csr` → baixe o `distribution.cer`. Depois:

```bash
openssl x509 -inform DER -in distribution.cer -out dist.pem
openssl pkcs12 -export -legacy -inkey dist.key -in dist.pem -out dist.p12 -name "Apple Distribution"
base64 -w0 dist.p12 | clip
```

O `pkcs12` pede uma senha: invente uma e guarde. O `-legacy` é necessário para o Mac conseguir abrir o arquivo. O último comando copia o certificado, já em base64, para a área de transferência.

A conta permite poucos certificados de distribuição. Se já houver um da empresa, só dá para reaproveitá-lo tendo a chave privada dele; sem ela, crie um novo como acima.

### 5. Perfil de provisionamento

Portal da Apple: Profiles → **+** → Distribution → **App Store Connect** → escolha o identificador e o certificado do passo 4 → nome **Calcio Firenze App Store** → baixe o arquivo `.mobileprovision`.

```bash
base64 -w0 Calcio_Firenze_App_Store.mobileprovision | clip
```

### 6. Chave da API do App Store Connect

App Store Connect → Usuários e acesso → Integrações → App Store Connect API → **+**, com a função **App Manager**. Anote o **Key ID** e o **Issuer ID** e baixe o arquivo `.p8`, que só pode ser baixado uma vez.

### 7. Segredos no GitHub

No repositório: Settings → Secrets and variables → Actions → **New repository secret**, um para cada linha:

| Nome | Valor |
|---|---|
| `IOS_DIST_CERT_P12` | o base64 do passo 4 |
| `IOS_DIST_CERT_PASSWORD` | a senha escolhida no passo 4 |
| `IOS_PROVISION_PROFILE` | o base64 do passo 5 |
| `APP_STORE_CONNECT_KEY_ID` | o Key ID do passo 6 |
| `APP_STORE_CONNECT_ISSUER_ID` | o Issuer ID do passo 6 |
| `APP_STORE_CONNECT_PRIVATE_KEY` | o conteúdo inteiro do arquivo `.p8` |

Guarde `dist.key`, `dist.p12` e o `.p8` em lugar seguro, fora do projeto. Quem tem esses arquivos consegue publicar em nome da conta.

## Publicar uma versão

1. Ajuste a versão em `pubspec.yaml` (`version: 1.0.0+1`). O número depois do `+` é ignorado: o GitHub numera cada compilação.
2. Marque e envie a versão:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Em cerca de 20 minutos a compilação aparece no TestFlight. Para só conferir se o projeto compila, sem assinar nem enviar: Actions → iPhone - TestFlight → Run workflow → marque "Só compilar".

## Custo

As máquinas Mac gastam a cota gratuita de minutos do GitHub dez vezes mais rápido que as Linux. Por isso esta rotina não roda a cada alteração, só nas versões marcadas.
