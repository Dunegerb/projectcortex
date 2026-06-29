# Changelog

## 1.2.2 (build 13)

- Remove o gradiente de fundo do card de energia atual.
- Centraliza automaticamente o chakra ativo no recorte da figura para os sete estágios.
- Mantém o fundo sólido `#0E0E0E` e o painel translúcido de descrição.
- Ajusta os títulos para “Solar Plexus Chakra” e “Third Eye Chakra”.
- Rebaixa a barra de navegação em mais 8 pt no iPhone X, respeitando a área segura.
- Preserva os SVGs de referência dos sete estados em `DesignSource/CurrentEnergyStages`.

## 1.2.1 (build 12)

- Adiciona os cartões Goal e Notes abaixo de Recovered time, seguindo o grid e os raios do redesign.
- Adiciona o cartão Add today's note conectado ao registro diário opcional.
- Goal usa a meta configurada no perfil e Notes conta apenas observações salvas.
- Mantém SF Pro nativa, tracking reduzido, cores e espaçamentos da Home.
- Reposiciona a barra inferior 8 pt mais próxima da área segura inferior no iPhone X.
- Preserva Diário, Marcos, Escudo, Ajustes e o fluxo de emergência sem redesign interno.

## 1.2.0 (build 11)

- Home redesenhada a partir do layout 739 × 1600 fornecido, equivalente à composição do iPhone X.
- SF Pro nativa mantida em toda a interface.
- Cabeçalho com saudação dinâmica, escudo e indicador automático de 7 energias.
- Cartões de ciclo, energia atual e tempo recuperado refeitos com proporções responsivas.
- Figura Kundalini passa a acompanhar visualmente o centro ativo dentro do cartão.
- Barra inferior personalizada com ação central “Estou com fissura”.
- Recursos vetoriais originais e JSON de posicionamento preservados em `DesignSource`.
- Contagem automática, notas opcionais e reinício por recaída preservados.

# 1.1.4

- Reduz a figura Kundalini para 80% do tamanho anterior na Home.
- Mantém o cartão e todas as animações, mas cria respiro visual ao redor do personagem.
- Aplica a mesma escala ao WebView animado e ao SVG de fallback.
- Adiciona verificação automática para impedir que a figura volte a ocupar o cartão inteiro.

# 1.1.3

- Garante `ChakraExperience.html` e `personkundalini.svg` no bundle principal.
- Adiciona fase de build explícita para copiar os recursos Kundalini.
- Adiciona salvaguarda de empacotamento e validação de arquivos não vazios.


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

## 1.1.7 — App Icon final
- Corrige a ausência do ícone na tela inicial do iPhone.
- Adiciona metadados explícitos `CFBundleIcons`, `CFBundleIconName` e `CFBundleIconFiles`.
- Instala ícones PNG fallback de 120 px e 180 px diretamente no bundle final.
- Exige `Assets.car` compilado antes de empacotar a IPA.
- Valida o ícone dentro da IPA, não apenas no código-fonte.

## 1.1.7 (build 10)

- Corrige a declaração do catálogo `Assets.xcassets` no XcodeGen: recursos agora entram em `sources` com `buildPhase: resources`.
- Adiciona validação do `Cortex.xcodeproj` gerado antes da compilação.
- Adiciona fallback determinístico com `xcrun actool` caso um runner não produza `Assets.car` durante o build unsigned.
- Mantém os PNGs de compatibilidade e mescla no `Info.plist` as chaves geradas pelo `actool`.
