# Mapa de implementação

| Função | Implementação |
|---|---|
| Home de transmutação | `DashboardView` |
| Figura vetorial sincronizada | `ChakraExperienceView` + `Resources/ChakraExperience.html` |
| Contagem automática | `RecoveryEngine` usando `UserProfile.startDate` |
| Recomeço após recaída | `DashboardView.registerRelapse` |
| Observação diária opcional | `DailyCheckInSheet` e `DailyCheckIn` |
| Tempo recuperado | `RecoveryEngine.hoursRecovered` |
| Média diária configurável | `SettingsView` e `ForgeStepView` |
| Atualização automática do widget | `WidgetSharedState`, `CortexWidgetSnapshot` e `CortexWidgetEntry` |
| Protocolo de emergência | `EmergencyFlowView` |
| Tela cheia | `Config/Cortex-Info.plist` e `AppRootView` |
| IPA automática | `.github/workflows/unsigned-ipa.yml` |
