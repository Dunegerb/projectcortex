# Cortex 1.2.5 — Dark mode, Light mode e tema automático

Projeto SwiftUI completo para iPhone. A IPA unsigned é compilada diretamente do código-fonte pelo GitHub Actions em todo `push`; não depende de uma IPA-base e não exige clicar em “Create Unsigned IPA”.

## Home redesenhada

A tela inicial foi refeita com composição inspirada nos padrões visuais do iOS:

- hierarquia clara, SF Pro nativa e espaçamento compacto;
- cartões contínuos com superfícies adaptativas para claro e escuro;
- figura de transmutação no lugar do cérebro 3D;
- sete centros ativados por uma linha do tempo fixa e verificável;
- energia Kundalini sincronizada com o dia real do ciclo;
- terceiro olho roxo alcançado no dia 30;
- coroa branca alcançada no dia 90 e mantida depois disso;
- fallback vetorial nativo para impedir a área vazia caso o WebView demore a carregar;
- destaque central para dias, etapa atual e tempo recuperado;
- registro diário reduzido a uma ação opcional;
- protocolo de emergência preservado em uma ação separada.

O desenho vetorial fornecido está preservado em `CortexApp/Resources/personkundalini.svg` e incorporado à animação local em `CortexApp/Resources/ChakraExperience.html`. O HTML é carregado como string dentro de um `WKWebView` transparente e sem interação. Enquanto o WebView não confirma que o JavaScript está pronto, o app mostra `KundaliniPerson.imageset` como fallback vetorial, evitando a área vazia observada no iPhone.

Linha do tempo da figura:

```text
Dia 1   Raiz
Dia 5   Sacral
Dia 10  Plexo solar
Dia 15  Coração
Dia 21  Garganta
Dia 30  Terceiro olho (roxo)
Dia 90+ Coroa/alma (branco)
```

## Contagem automática

A contagem começa automaticamente na criação do perfil e avança pelo relógio do aparelho. Check-ins não adicionam dias, não pausam o ciclo e não alteram o progresso.

O registro do dia agora serve apenas para observações opcionais. Ao registrar uma recaída com confirmação, o histórico é mantido, mas:

- o ciclo atual volta ao dia 1;
- a data de início passa a ser o momento da recaída;
- o tempo recuperado volta a ser calculado a partir desse instante.

A Home atualiza o relógio a cada minuto e também ao voltar para o primeiro plano. O widget recebe a data de início do ciclo e recalcula os dias automaticamente.

## Tempo recuperado

O campo antigo “Uso estimado” foi substituído por:

```text
Tempo gasto no ato da autosatisfação: X min/dia
```

Esse valor representa a média diária e é usado para estimar o tempo recuperado desde a criação da conta ou desde a última recaída. O cálculo usa o tempo exato decorrido, não a quantidade de check-ins.

## Tela cheia

O app usa `UILaunchScreen` em `Config/Cortex-Info.plist`, com `LaunchBackground`, `LaunchMark` e `UIRequiresFullScreen`. O layout consome toda a janela e respeita as safe areas dos iPhones modernos.

## SF Pro e superfícies OLED

A tipografia usa `Font.system`, que resolve para SF Pro no iPhone. A escala está centralizada em `Shared/CortexDesignSystem.swift`, com tracking negativo discreto.

```text
Base          #000000
Secundário    #1C1C1E
Terciário     #2C2C2E
Quaternário   #3A3A3C
```

O script `Scripts/verify_design_system.py` valida a tipografia e a paleta antes de cada build automático.

## Teclado nativo do iPhone

Todos os `TextField` e `TextEditor` usam o teclado padrão da Apple. Não há `inputView`, extensão de teclado ou aparência forçada. Teclados de terceiros permanecem bloqueados dentro do app para evitar o encerramento observado anteriormente.

O script `Scripts/verify_native_keyboard.py` valida todos os campos antes da compilação.

## IPA automática no GitHub Actions

O workflow `.github/workflows/unsigned-ipa.yml` executa automaticamente em qualquer `push` e em tags `v*`.

Resultado em **Actions → execução → Artifacts**:

```text
Cortex-unsigned-fullscreen.ipa
Cortex-unsigned-fullscreen.ipa.sha256
```

Para criar também uma Release:

```bash
git tag v1.2.5
git push origin v1.2.5
```

## Build local no macOS

Requisitos: Xcode e XcodeGen.

```bash
brew install xcodegen
./Scripts/package_unsigned_ipa.sh
python3 Scripts/verify_unsigned_ipa.py build/Cortex-unsigned-fullscreen.ipa
```

A IPA gerada é unsigned e precisa ser assinada antes da instalação em um iPhone físico.

## Correção de repositórios atualizados sem clone

O workflow executa `Scripts/remove_legacy_brain.sh` antes de gerar o projeto. Isso remove automaticamente um `BrainSceneView.swift` antigo que possa ter permanecido rastreado no GitHub depois da substituição manual dos arquivos.

## Correção de empacotamento Kundalini (1.1.3)

Os arquivos `ChakraExperience.html` e `personkundalini.svg` agora são instalados no bundle principal por uma fase explícita do target e novamente validados durante o empacotamento unsigned. Isso evita que a IPA seja publicada sem a animação da Home.
## Ajuste visual da figura Kundalini (1.1.4)

A figura animada da Home usa agora 80% da área disponível, mantendo o cartão original e criando margens visuais ao redor do personagem. A escala é aplicada tanto à animação WebKit quanto ao SVG de fallback.


## App icon integrado

O ícone do Cortex já está dentro do catálogo `AppIcon.appiconset`. No Sideloadly, carregue somente a IPA e deixe a opção de ícone personalizado desativada. O Xcode inclui o ícone correto durante a compilação do GitHub Actions.

### App Icon 1.1.7
O build agora valida o catálogo compilado (`Assets.car`), os metadados do `Info.plist` e os PNGs fallback no bundle final. Para atualizar o ícone no iPhone, remova a instalação anterior antes de instalar a nova IPA, evitando o cache antigo do SpringBoard.

### Correção do App Icon no build unsigned (v1.1.7)

O catálogo `Assets.xcassets` é adicionado explicitamente à fase **Copy Bundle Resources** do target Cortex. O empacotador valida o projeto Xcode gerado e, como proteção adicional, executa `xcrun actool` quando `Assets.car` não for produzido automaticamente.

## Home 1.2.0

A Home utiliza uma composição responsiva baseada no frame de referência 739 × 1600, com escala de largura para iPhones e ajuste pelas áreas seguras do aparelho. A tipografia usa exclusivamente SF Pro por meio de `Font.system`. O indicador superior, a figura Kundalini e a cor do estágio avançam automaticamente nos dias 1, 5, 10, 15, 21, 30 e 90.

A barra inferior é própria do aplicativo: Início, Diário, ação de emergência, Marcos e Ajustes. O Escudo Neural permanece disponível pelo botão no cabeçalho.

## Home 1.2.1 — cartões complementares

A área abaixo de `Recovered time` agora segue os SVGs fornecidos: dois cartões compactos lado a lado para `Goal` e `Notes`, seguidos pelo botão largo `Add today's note`. Os valores são dinâmicos; a meta usa `targetDays` do perfil e as notas contam apenas observações não vazias. A barra inferior foi deslocada 8 pt para baixo no iPhone X, respeitando a área segura nos demais iPhones.

## Home 1.2.2 — energia centralizada

O card “Current energy” agora usa fundo sólido, sem o gradiente antigo. A figura Kundalini mantém o mesmo zoom, mas aplica um deslocamento próprio para cada um dos sete centros, deixando o chakra atual centralizado no enquadramento. A barra inferior também foi rebaixada em mais 8 pt no iPhone X e continua responsiva em outros iPhones.
## Correção nativa do card de energia atual (1.2.3)

O card **Current energy** não usa mais `WKWebView`. Cada um dos sete estados fornecidos no redesign foi incorporado ao catálogo de assets em resoluções 1x, 2x e 3x. Isso remove duas falhas observadas no iPhone: o salto de escala após o carregamento do HTML e o desaparecimento da figura quando o processo WebKit era suspenso ou encerrado em segundo plano.

A animação Kundalini original permanece preservada no projeto, mas o recorte de energia atual da Home agora é renderizado nativamente pelo SwiftUI e continua sincronizado com os dias 1, 5, 10, 15, 21, 30 e 90.
## Acabamento cinematográfico e overscroll elástico (1.2.4)

A Home usa agora o gradiente radial original do redesign no card de boas-vindas. A origem escura fica no canto inferior esquerdo e a luz se abre diagonalmente até o canto superior direito, com as três paradas exatas do arquivo de referência.

O botão central de fissura recebeu o mesmo tratamento radial em vermelho e um stroke direcional que desaparece na direção da luz. O cabeçalho também se estende durante o gesto de puxar a tela para baixo, evitando qualquer recorte preto. A resistência visual é progressiva, os pulsos hápticos aumentam suavemente com a tensão e o conteúdo retorna com uma mola interpolada quando o gesto termina.
## Light mode e aparência automática (1.2.5)

A Home possui agora uma composição clara nativa baseada diretamente nos SVGs de referência fornecidos. O fundo usa `#F1F1F1`, os cartões usam `#FFFFFF`, os controles usam `#F5F5F5`, o texto principal usa `#191817` e o texto secundário usa `#555555`. O cabeçalho preserva a mesma direção de luz do dark mode com o gradiente `#E9E9E9` → `#C2C2C2` → `#9E9E9E`.

Os sete estados do card **Current energy** possuem assets claros próprios em 1x, 2x e 3x, evitando filtros em tempo de execução e preservando as cores dos chakras. Em **Ajustes → Aparência**, o usuário pode selecionar:

- **Automático**: acompanha o tema claro/escuro do iPhone;
- **Claro**: mantém o aplicativo no light mode;
- **Escuro**: mantém o aplicativo no dark mode.

A preferência é salva localmente por `AppStorage` e aplicada à janela inteira, incluindo formulários, navegação, sheets e fluxos de emergência.

