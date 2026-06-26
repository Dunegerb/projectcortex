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

## Elevação escura

| Nível | Hex | Uso |
|---|---|---|
| Base | `#000000` | Fundo principal e launch screen |
| Secundário | `#1C1C1E` | Cartões, navegação, tab bar e modais |
| Terciário | `#2C2C2E` | Elementos agrupados e opções não selecionadas |
| Quaternário | `#3A3A3C` | Campos, busca, controles inativos e divisórias |

As cores são centralizadas em `CortexPalette`, e `CortexTheme` configura também a aparência UIKit de barras de navegação, tab bar e campos de busca.
