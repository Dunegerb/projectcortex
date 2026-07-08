# Changelog

## 1.2.11 (build 25)

- Remove completamente o filme `CortexSplashIntro.mp4` e toda dependência de `AVFoundation` da abertura.
- Reconstrói a animação diretamente em SwiftUI com os vetores originais de `textlogo`, `iconlogo` e `glasslogo`.
- Mantém as coordenadas do design 739 × 1600, blur 23.4, luzes externas e refratadas, shader Metal de deslocamento, caustics e crossfades sincronizados.
- Preserva 900 ms do frame inicial, 800 ms com `cubic-bezier(1, 0.01, 0, 0.99)` e 50 ms finais antes da Home.
- Atualiza os validadores para rejeitar vídeo, HTML, WebKit e AVPlayer na splash.

## 1.2.10 (build 24)

- Impede que a tela de entrada seja encerrada em milissegundos quando o iPhone está com Reduzir Movimento ativo.
- Remove qualquer caminho normal de conclusão baseado em atraso curto ou timeout iniciado antes do vídeo estar pronto.
- Libera a Home somente após `AVPlayerItemDidPlayToEndTime` confirmar que o filme chegou ao timestamp final real.
- Mantém a splash sobre a interface já carregada até os 900 ms iniciais, 800 ms de transição e os frames finais terminarem.
- Adiciona uma proteção contra notificações prematuras de término e um fallback nativo com duração completa caso o MP4 não possa ser decodificado.

## 1.2.9 (build 23)

- Remove completamente `SplashIntro.html`, JavaScript e `WKWebView` da animação de abertura.
- Reproduz a referência aprovada em um filme H.264 silencioso de 60 fps, renderizado offline a partir dos estados e do easing exatos.
- Executa a abertura nativamente com `AVPlayerLayer`, decodificação de vídeo por hardware e sem acesso à rede.
- Mantém 900 ms do frame inicial, 800 ms de transição com `cubic-bezier(1, .01, 0, .99)` e dois frames finais antes de liberar a interface.
- Adiciona frames estáticos 1x, 2x e 3x para continuidade visual e para a preferência Reduzir Movimento.
- Atualiza os validadores do projeto e da IPA para exigir o MP4 aprovado e rejeitar qualquer regressão para HTML/WebKit no splash.

## 1.2.8 (build 22)

- Substitui a aproximação nativa anterior pela animação HTML/CSS fornecida, preservada byte a byte em `SplashIntro.html`.
- Renderiza a abertura dentro de um `WKWebView` local para manter exatamente as máscaras, filtros SVG, refração, blur, posições e escalas da referência.
- Mantém o frame inicial por 900 ms e executa a transição principal em 800 ms com `cubic-bezier(1, .01, 0, .99)`.
- Remove a tela de entrada somente após o evento real `transitionend`, sem estimar o término da animação pelo código Swift.
- Desativa interação no loader para impedir replay acidental dentro do aplicativo.
- Atualiza o Launch Screen com um recorte renderizado do frame 1, evitando o flash branco da implementação anterior.

## 1.2.7 (build 21)

- Adiciona uma nova animação nativa de entrada baseada nos dois frames SVG fornecidos.
- Mantém o `glasslogo` centralizado com material translúcido e luzes desfocadas que atravessam a marca da esquerda para a direita.
- Transforma o `textlogo` de 131 × 88 para 29 × 19 enquanto o `iconlogo` cresce de 66 × 53 para 164 × 131.
- Usa exatamente 800 ms com `cubic-bezier(1, 0.01, 0, 0.99)` para a transição principal.
- Atualiza a imagem estática do Launch Screen para coincidir com o primeiro frame e evitar troca visual antes da animação.
- Respeita a preferência Reduzir Movimento do iPhone e preserva os SVGs originais em `DesignSource/LaunchAnimation`.

## 1.2.6 (build 20)

- Corrige o ícone exibido nas notificações do iPhone, apontando o bundle para uma nova identidade interna de App Icon (`CortexAppIcon`).
- Renomeia também os PNGs fallback para `CortexIcon*`, evitando que o iOS ou o Sideloadly reutilizem arquivos com o nome antigo em cache.
- Mantém a logo atual fornecida em `DesignSource/AppIcon/appleicone.svg` em todos os tamanhos de 20, 29, 40, 60 e 1024 pontos.
- Atualiza as validações do catálogo, do projeto Xcode e da IPA para impedir regressões.

## 1.2.5 (build 19)

- Adiciona modo claro baseado nos SVGs fornecidos, com as cores exatas `#F1F1F1`, `#FFFFFF`, `#F5F5F5`, `#191817` e `#555555`.
- Reproduz no cabeçalho claro o gradiente radial `#E9E9E9` → `#C2C2C2` (73%) → `#9E9E9E`.
- Adiciona sete cards nativos claros para Root, Sacral, Solar Plexus, Heart, Throat, Third Eye e Crown.
- Mantém o modo escuro atual sem alterar sua identidade visual.
- Inclui em Ajustes as opções **Automático**, **Claro** e **Escuro**; o modo Automático acompanha o tema do iPhone.
- Torna superfícies SwiftUI e barras UIKit adaptativas e persiste a escolha em `AppStorage`.
- Corrige novamente o painel **Current energy** no modo claro usando o mesmo princípio visual do dark mode: blur de raio 4 sobre a própria arte e preenchimento `#F5F5F5` a 31%, sem brilho, borda, sombra ou tonalização extra.
- Substitui o App Icon por uma nova marca vetorial branca sobre fundo preto, gerada diretamente do SVG fornecido.
- Atualiza todos os tamanhos do catálogo `AppIcon`, os oito PNGs fallback injetados na IPA para o Sideloadly e a marca da tela de abertura.
- Garante que os ícones fallback sejam binariamente idênticos aos tamanhos correspondentes do catálogo principal.

## 1.2.4 (build 15)

- Reproduz o gradiente radial cinematográfico do card de boas-vindas com as paradas `#262626`, `#575757` (73%) e `#6A6A6A`.
- Corrige a direção da luz: o tom escuro nasce no canto inferior esquerdo e clareia em direção ao canto superior direito.
- Recria o botão “Estou com fissura” com gradiente `#431414` → `#A81312` (62%) → `#F18585`.
- Adiciona stroke diagonal `#F18585` que se dissolve até transparência no canto superior direito.
- Estende o card de boas-vindas durante o overscroll, eliminando a faixa preta no topo.
- Adiciona resistência progressiva, pulsos hápticos suaves e retorno com mola personalizada ao soltar.

## 1.2.3 (build 14)

- Remove o `WKWebView` do card **Current energy** e usa sete imagens nativas pré-renderizadas.
- Elimina o salto de escala que ocorria quando o fallback era substituído pelo conteúdo WebKit.
- Impede que a figura desapareça ao voltar do segundo plano por encerramento do processo WebKit.
- Mantém exatamente os enquadramentos fornecidos para Root, Sacral, Solar Plexus, Heart, Throat, Third Eye e Crown.
- Inclui recursos 1x, 2x e 3x no catálogo de assets e força a troca do card por identidade de estágio.

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
