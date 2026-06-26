# Cortex 1.1.1 — Home Kundalini sincronizada + IPA automática

Projeto SwiftUI completo para iPhone. A IPA unsigned é compilada diretamente do código-fonte pelo GitHub Actions em todo `push`; não depende de uma IPA-base e não exige clicar em “Create Unsigned IPA”.

## Home redesenhada

A tela inicial foi refeita com composição inspirada nos padrões visuais do iOS:

- hierarquia clara, SF Pro nativa e espaçamento compacto;
- cartões contínuos sobre preto OLED;
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
git tag v1.1.1
git push origin v1.1.1
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
