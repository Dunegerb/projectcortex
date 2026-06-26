# 1.1.4

- Reduz a figura Kundalini para 80% do tamanho anterior na Home.
- Mantém o cartão e todas as animações, mas cria respiro visual ao redor do personagem.
- Aplica a mesma escala ao WebView animado e ao SVG de fallback.
- Adiciona verificação automática para impedir que a figura volte a ocupar o cartão inteiro.

# 1.1.3

- Garante `ChakraExperience.html` e `personkundalini.svg` no bundle principal.
- Adiciona fase de build explícita para copiar os recursos Kundalini.
- Adiciona salvaguarda de empacotamento e validação de arquivos não vazios.

# Changelog

## 1.1.2 — build 5

- Corrige o GitHub Actions quando um `BrainSceneView.swift` antigo permanece rastreado no repositório.
- Remove automaticamente o componente SceneKit legado antes do XcodeGen e das verificações.
- Mantém apenas a experiência Kundalini na Home e impede referências ao cérebro 3D.

## 1.1.1 (build 4)

- Corrige a área vazia da figura Kundalini na Home.
- Carrega o HTML por `loadHTMLString` e procura o recurso em caminhos alternativos do bundle.
- Adiciona handshake `cortexReady` antes de ocultar o fallback vetorial.
- Preserva o SVG original como recurso e como imagem vetorial de contingência.
- Sincroniza os centros com dias fixos: 1, 5, 10, 15, 21, 30 e 90.
- Garante terceiro olho no dia 30 e coroa no dia 90 ou posterior.
- Valida os recursos dentro da IPA automática.

## 1.1.5 (build 8)

- App icon preto e branco integrado diretamente ao `AppIcon.appiconset`.
- Todos os tamanhos de iPhone foram regenerados como PNG RGB de 8 bits, sem canal alpha e sem metadados extras.
- O fluxo não depende mais da opção “Custom App Icon” do Sideloadly.
- Adicionada validação automática de formato, dimensões e transparência antes da compilação.

## 1.1.6 — App Icon final
- Corrige a ausência do ícone na tela inicial do iPhone.
- Adiciona metadados explícitos `CFBundleIcons`, `CFBundleIconName` e `CFBundleIconFiles`.
- Instala ícones PNG fallback de 120 px e 180 px diretamente no bundle final.
- Exige `Assets.car` compilado antes de empacotar a IPA.
- Valida o ícone dentro da IPA, não apenas no código-fonte.
