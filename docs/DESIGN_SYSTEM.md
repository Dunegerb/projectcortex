# Sistema visual do Córtex

## Tipografia

O aplicativo usa a fonte de sistema do iOS por meio de `Font.system`. Em iPhones, isso utiliza SF Pro e mantém a integração nativa com SwiftUI, UIKit, símbolos e componentes do sistema.

| Estilo | Tamanho | Peso | Tracking |
|---|---:|---|---:|
| Large Title | 34 pt | Regular | -0,45 pt |
| Title 1 | 28 pt | Regular | -0,35 pt |
| Title 2 | 22 pt | Regular | -0,26 pt |
| Title 3 | 20 pt | Regular | -0,22 pt |
| Headline | 17 pt | Semi-Bold | -0,18 pt |
| Body | 17 pt | Regular | -0,18 pt |
| Callout | 16 pt | Regular | -0,16 pt |
| Subhead | 15 pt | Regular | -0,14 pt |
| Footnote | 13 pt | Regular | -0,10 pt |
| Caption 1 | 12 pt | Regular | -0,08 pt |
| Caption 2 | 11 pt | Regular | -0,06 pt |

A implementação está em `Shared/CortexDesignSystem.swift`. Não são incluídos arquivos `.otf` ou `.ttf`.

## Paleta adaptativa

### Dark mode

| Nível | Hex | Uso |
|---|---|---|
| Base | `#000000` | Fundo principal |
| Secundário | `#1C1C1E` | Cartões, navegação e modais |
| Terciário | `#2C2C2E` | Elementos agrupados |
| Quaternário | `#3A3A3C` | Campos, controles e divisórias |

### Light mode

| Token | Hex | Uso |
|---|---|---|
| Base | `#F1F1F1` | Fundo principal |
| Cartão | `#FFFFFF` | Cards e barra inferior |
| Controle | `#F5F5F5` | Botões, círculos e itens inativos |
| Texto principal | `#191817` | Títulos, valores e seleção ativa |
| Texto secundário | `#555555` | Legendas, ícones e textos auxiliares |
| Gradiente do cabeçalho | `#E9E9E9` → `#C2C2C2` → `#9E9E9E` | Painel superior da Home |
| Chakra raiz ativo | `#E81816` | Destaque do estágio Root |
| Status ativo | `#13A83D` | Indicador do Escudo Neural |

`CortexTheme` usa cores dinâmicas de `UIColor`, portanto SwiftUI e UIKit respondem à mesma `ColorScheme`. A preferência fica em `AppAppearanceMode` e é aplicada por `preferredColorScheme`; no modo Automático o valor é `nil`, permitindo que o iOS controle o tema.
