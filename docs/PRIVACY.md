# Privacidade

Esta versão foi projetada sem servidor próprio.

## Dados locais

- Nome e identidade escolhida
- Meta de 90 dias
- Inventário de perdas
- Carta pessoal
- Check-ins
- Diário
- Sessões de emergência

Esses dados são armazenados localmente por SwiftData.

## APIs do sistema

- **HealthKit:** leitura opcional de sono, passos, treinos e frequência cardíaca.
- **Family Controls / Screen Time:** seleção e bloqueio opcional de apps, categorias e sites.
- **CoreMotion:** contagem temporária de movimentos durante o protocolo de emergência.
- **LocalAuthentication:** confirmação opcional do compromisso.
- **Notificações:** dois lembretes locais, silenciosos e previsíveis.

A V1 não envia o conteúdo do diário, carta ou dados de saúde a terceiros.
