# Configuração Apple Developer

## Identificadores

Crie dois App IDs explícitos:

1. `com.suaempresa.cortex`
2. `com.suaempresa.cortex.widget`

Crie também um App Group, por exemplo `group.com.suaempresa.cortex`, e associe-o aos dois IDs.

## Capacidades do app principal

- App Groups
- HealthKit
- Family Controls

A capacidade Family Controls depende de solicitação/aprovação da Apple para distribuição. Sem essa capacidade no provisioning profile, o build assinado falhará ou os bloqueios não funcionarão.

## Capacidades do widget

- App Groups

## Perfis

Gere um provisioning profile de distribuição para cada target. Exporte o certificado Apple Distribution com a chave privada como `.p12`.

Conversão para Base64 no macOS:

```bash
base64 -i certificate.p12 | pbcopy
base64 -i Cortex_AppStore.mobileprovision | pbcopy
base64 -i CortexWidget_AppStore.mobileprovision | pbcopy
```

Cole cada valor no secret correspondente do GitHub, sem compartilhar os arquivos no repositório.

## App Group no código

O valor padrão aparece em `Shared/CortexShared.swift`. Antes da distribuição, altere-o para o mesmo App Group usado no portal Apple. O XcodeGen também recebe `CORTEX_APP_GROUP` para os entitlements.

## Exportação

O workflow usa `method = app-store-connect`. Para distribuição Ad Hoc, altere o método em `.github/workflows/signed-ipa.yml` e use perfis Ad Hoc nos dois targets.
