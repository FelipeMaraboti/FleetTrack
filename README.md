# FleetTrack — Sistema de Gestão de Frota e Telemetria Veicular (Offline-First)

> Projeto acadêmico desenvolvido para a disciplina de **Computação Móvel** (**AP2B — Marco 2**, evolução da AP1B).
> Aplicação móvel multiplataforma em **Flutter (Material Design 3)** com persistência relacional local (**SQLite / `sqflite`** + **`shared_preferences`**), sincronização assíncrona **HTTP REST** operando sob arquitetura **Offline-First** e suíte completa de testes automatizados (**`flutter_test`**).

---

## 👥 Identificação do Grupo

* **Instituição:** Faculdade Multivix
* **Curso:** Sistemas de Informação (7º/8º Período — Turma Noturna)
* **Disciplina:** Computação Móvel (2026/2) — Professor Edgard da Cunha Pontes
* **Tema 01:** Mobilidade Urbana & Telemetria
* **Entrega AP2B:** Até 12/11/2026

### Integrantes da Equipe
1. **Enock de Oliveira Memelli Junio**
2. **Felipe Sabino Maraboti**
3. **Pedro José Muchelin Acha**
4. **Samuel Mota Moysés**

---

## 1. Descrição do Projeto e Evolução (AP1B → AP2B)

O **FleetTrack** é uma plataforma de monitoramento de frotas e telemetria veicular voltada para cenários de mobilidade urbana com conectividade intermitente.

* **Na AP1B (Marco 1):** Foi construído o núcleo de domínio em Dart 3 puro (`DispositivoMovel`, `Veiculo`, `CarroEletrico`, `CarroCombustao`, `Rota`, `LeituraTelemetria`, `GerenciadorFrota`, `GerenciadorRotas`, `ServicoTelemetria` e `LogAuditoriaMixin`), aplicando POO avançada, polimorfismo, Sound Null Safety, coleções funcionais e tratamento de exceções customizadas.
* **Na AP2B (Marco 2):** O núcleo de regras de negócio foi preservado integralmente e evoluído para um aplicativo **Flutter Offline-First**, persistindo rotas urbanas, leituras de sensores/telemetria e logs históricos de sincronização em banco de dados local **SQLite**, sincronizando lotes de pendências via **HTTP REST** e consultando dados meteorológicos em tempo real (com fallback de cache offline) na API pública **Open-Meteo**.

---

## 2. Arquitetura Offline-First (*Single Source of Truth*)

Na arquitetura adotada, a camada de interface gráfica (**UI**) **nunca realiza chamadas HTTP nem queries SQL diretamente dentro de `build()`**. O banco de dados local (**SQLite**) atua como **Fonte Única da Verdade (*Single Source of Truth*)**, orquestrado pela camada de **Repositórios**:

```
+-----------------------------------------------------------------------+
|                      CAMADA DE APRESENTAÇÃO (UI)                      |
|     12 Telas Flutter (Material 3 / StatefulWidget / Form / Rotas)     |
+-----------------------------------+-----------------------------------+
                                    |
                   Leitura/Escrita Assíncrona (Future)
                                    v
+-----------------------------------------------------------------------+
|                         CAMADA DE REPOSITÓRIO                         |
|   RotaRepository | TelemetriaRepository | ClimaRepository | SyncRepo  |
+-----------------+-----------------------------------+-----------------+
                  |                                   |
  1. Prioridade Local (CRUD Imediato)    2. Sincronização HTTP (Quando Online)
                  v                                   v
+-----------------------------------+   +-------------------------------+
|     FONTE DE DADOS LOCAL (DAO)    |   |  FONTE DE DADOS REMOTA (API)  |
|  SQLite (sqflite) + Preferences   |   |  JSONPlaceholder + Open-Meteo |
+-----------------------------------+   +-------------------------------+
```

### Fluxo Operacional
1. **Leitura Imediata Local:** Ao abrir o aplicativo ou navegar entre telas, a UI consome os dados diretamente do SQLite (`SqliteRotaDatasource`, `SqliteLeituraDatasource`, `SqliteLogDatasource`), garantindo carregamento instantâneo mesmo em modo avião.
2. **Escrita Resiliente:** Cadastros, edições e exclusões lógicas (*soft delete*) gravam primeiro no banco local com marcador `sincronizado = false` (`0` no SQLite) e atualizam a interface imediatamente com ícone de pendência (`Icons.cloud_upload_outlined`).
3. **Sincronização Transparente e Fallback:** Os repositórios tentam sincronizar em seguida com a API externa com `timeout` configurado. Em caso de sucesso (`HTTP 200/201`), o registro local é atualizado para `sincronizado = true` (`Icons.cloud_done`) ou removido fisicamente após confirmação de `DELETE`. Caso ocorra falha de socket, DNS, timeout ou erro `5xx`, a exceção (`RedeIndisponivelException` / `SincronizacaoException`) é capturada e registrada no histórico sem interromper a operação do usuário.

---

## 3. Endpoints das APIs Utilizadas

| Finalidade | Método HTTP | Endpoint | Observação |
|---|---|---|---|
| Sincronização de Rotas e Lotes de Telemetria | `POST` | `https://jsonplaceholder.typicode.com/posts` | Envia payload JSON (`toMap()/toJson()`) com `timeout` de 8s e verifica status `200/201`. |
| Exclusão Remota de Registros | `DELETE` | `https://jsonplaceholder.typicode.com/posts/{id}` | Confirma exclusões lógicas pendentes e remove fisicamente do SQLite. |
| Clima na Coordenada GPS do Veículo | `GET` | `https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}&current_weather=true` | API pública sem chave; armazena resposta em cache local (`shared_preferences`) para leitura offline. |

---

## 4. Estrutura de Pastas do Projeto

```
fleet_track/
├── bin/
│   └── fleet_track_cli.dart              # CLI interativa original da AP1B preservada
├── lib/
│   ├── datasources/                      # Camada de acesso a dados (Local SQLite/Prefs e Remoto HTTP)
│   │   ├── local_datasources.dart        # Contratos abstratos para inversão de dependência
│   │   ├── preferencias_datasource.dart  # SharedPreferences (última sync, modo offline, cache clima)
│   │   ├── remote_datasources.dart       # Clientes HTTP REST (FleetApiDatasource e ClimaApiDatasource)
│   │   └── sqlite_datasources.dart       # DatabaseHelper e DAOs SQLite (rotas, leituras, logs)
│   ├── exceptions/
│   │   └── telemetria_exceptions.dart    # Exceções de domínio (AP1B) e de rede/sincronização (AP2B)
│   ├── mixins/
│   │   └── log_auditoria_mixin.dart      # Mixin transversal de auditoria com timestamp ISO-8601
│   ├── models/                           # Entidades de domínio com toMap(), fromMap(), copyWith() e toJson()
│   │   ├── carro_combustao.dart
│   │   ├── carro_eletrico.dart
│   │   ├── condicao_clima.dart
│   │   ├── dispositivo_movel.dart
│   │   ├── leitura_telemetria.dart
│   │   ├── log_sincronizacao.dart
│   │   ├── rota.dart
│   │   └── veiculo.dart
│   ├── repositories/                     # Orquestração Offline-First e fallback de rede
│   │   ├── clima_repository.dart
│   │   ├── repositorio_base.dart
│   │   ├── rota_repository.dart
│   │   ├── sincronizacao_repository.dart
│   │   └── telemetria_repository.dart
│   ├── routes/
│   │   └── app_routes.dart               # Roteamento nomeado centralizado (12 rotas) com argumentos seguros
│   ├── screens/                          # 12 Telas Material Design 3
│   │   ├── configuracoes_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── leitura_detalhe_screen.dart
│   │   ├── leitura_form_screen.dart
│   │   ├── leituras_screen.dart
│   │   ├── rota_detalhe_screen.dart
│   │   ├── rota_form_screen.dart
│   │   ├── rotas_screen.dart
│   │   ├── sincronizacao_screen.dart
│   │   ├── sobre_screen.dart
│   │   ├── veiculo_detalhe_screen.dart
│   │   └── veiculos_screen.dart
│   ├── services/                         # Serviços de domínio e métricas funcionais (AP1B)
│   │   ├── gerenciador_frota.dart
│   │   ├── gerenciador_rotas.dart
│   │   └── servico_telemetria.dart
│   ├── widgets/
│   │   └── comuns.dart                   # SyncStatusIcon, OfflineBanner, MetricCard, BateriaIndicator, AppDrawer
│   ├── app.dart                          # Configuração do MaterialApp (Material 3) e tema
│   ├── app_dependencies.dart             # Injeção de dependências manual e AppScope (InheritedWidget)
│   └── main.dart                         # Ponto de entrada Flutter (inicialização SQLite mobile/desktop)
├── test/                                 # Suíte de testes automatizados (flutter_test)
│   ├── dominio_ap1b_test.dart            # Testes de regras de domínio, POO e coleções funcionais
│   ├── fakes.dart                        # Datasources em memória para testes isolados sem emulador
│   ├── repositorio_offline_test.dart     # Testes de fallback Offline-First, lote HTTP, timeout e cache
│   ├── serializacao_test.dart            # Testes de conversão SQLite/JSON (toMap/fromMap/copyWith)
│   └── widgets_test.dart                 # Testes de componentes visuais, listas, formulários e rotas
├── ENVIRONMENT_REPORT.md
├── pubspec.yaml
└── README.md
```

---

## 5. Telas e Rotas Implementadas (12 Rotas)

| # | Rota Nomeada | Tela (`lib/screens/`) | Descrição e Recursos |
|---|---|---|---|
| 1 | `/` | `DashboardScreen` | Painel responsivo (`LayoutBuilder`), métricas da frota, contador de pendências e botão de sincronização imediata. |
| 2 | `/veiculos` | `VeiculosScreen` | Listagem da frota (`CarroEletrico` e `CarroCombustao`) com indicador visual de bateria e status online/offline. |
| 3 | `/veiculos/detalhe` | `VeiculoDetalheScreen` | Recebe `veiculoId` por argumento seguro; exibe telemetria mais recente e consulta clima real na API Open-Meteo com cache offline. |
| 4 | `/rotas` | `RotasScreen` | Listagem dinâmica (`ListView.builder`) do SQLite, exclusão por gesto (`Dismissible`) e ícone de estado de sincronização. |
| 5 | `/rotas/form` | `RotaFormScreen` | Formulário validado (`Form`, `GlobalKey<FormState>`, `TextEditingController`, `TextFormField`) para criação e edição de rotas. |
| 6 | `/rotas/detalhe` | `RotaDetalheScreen` | Exibe dados da rota com `CustomScrollView`/`SliverList` e todas as leituras de telemetria vinculadas (`1:N`). |
| 7 | `/leituras` | `LeiturasScreen` | Histórico de snapshots de sensores salvo no SQLite com remoção via `Dismissible` e feedback via `SnackBar`. |
| 8 | `/leituras/form` | `LeituraFormScreen` | Registro de telemetria validado; aciona `ServicoTelemetria` e exibe `AlertDialog` nativo em caso de bateria crítica ($\le 5\%$). |
| 9 | `/leituras/detalhe` | `LeituraDetalheScreen` | Recebe objeto `LeituraTelemetria` via rota e inspeciona coordenadas GPS, bateria e payload JSON. |
| 10 | `/sincronizacao` | `SincronizacaoScreen` | Diagnóstico completo: fila de pendências, data/hora da última sincronização (`shared_preferences`) e log de auditoria HTTP. |
| 11 | `/configuracoes` | `ConfiguracoesScreen` | Permite ativar/desativar o **Modo Offline Simulado** (`ValueNotifier<bool>`) para demonstração prática de queda de rede. |
| 12 | `/sobre` | `SobreScreen` | Identificação da equipe, tema e resumo da arquitetura Offline-First. |

---

## 6. Como Executar o Aplicativo e os Testes

### Pré-requisitos
* **Flutter SDK** (3.x ou superior — canal `stable`) com **Dart 3**.

### 1. Instalar dependências
```bash
flutter pub get
```

### 2. Executar a suíte de testes automatizados (Unidade + Widgets)
```bash
flutter test
```
> A suíte executa **42 casos de teste** (34 testes de unidade de domínio, serialização e repositórios Offline-First + 8 testes de widgets).

### 3. Executar o aplicativo Flutter
```bash
flutter run
```
*(Compatível com emulador/dispositivo Android e também com Windows Desktop via `sqflite_common_ffi`).*

### 4. Executar a demonstração CLI original da AP1B (opcional)
```bash
dart run bin/fleet_track_cli.dart
```

---

## 7. Declaração de Uso de Inteligência Artificial

Em conformidade com a Política Institucional de Uso de IA da disciplina de Computação Móvel (Seção 6 da AP2B):

* **Ferramentas utilizadas:** Assistentes baseados em LLMs (Claude / Gemini / GitHub Copilot).
* **Como auxiliaram a equipe:** Apoio na estruturação do scaffolding inicial de persistência SQLite (`sqflite`), elaboração de mocks HTTP (`MockClient`) para cenários de falha de rede nos testes automatizados, revisão de boas práticas de desacoplamento em camadas (Datasources / Repositories / UI) e formatação da documentação técnica.
* **Autoria Cognitiva e Validação:** Todas as decisões arquiteturais, regras de negócio do domínio de Mobilidade Urbana & Telemetria, modelagem relacional, fluxos de navegação e tratamento de exceções foram revisados, testados e validados integralmente pelos membros do grupo, que detêm pleno domínio sobre o funcionamento do código para realização de alterações ao vivo durante a Defesa Técnica.

---

## 8. Referências Bibliográficas

1. **TEIXEIRA, Giovany Frossard et al.** *Fundamentos de Flutter e Dart para desenvolvimento de apps móveis*. Vitória: Edifes, 2024.
2. **MARINHO, Leonardo H.** *Flutter Framework: Desenvolva aplicações móveis no Dart Side!*. São Paulo: Casa do Código, 2020.
3. **ARAÚJO, Everton Coimbra de.** *Aprofundando em Flutter: desenvolva aplicações Dart com widgets*. São Paulo: Casa do Código, 2021.
4. **FLUTTER DEV.** *Flutter Documentation: Building Applications with Flutter*. Google, 2026. Disponível em: <https://docs.flutter.dev>.
5. **DART DEV.** *Dart Language Guide and Tour*. Google, 2026. Disponível em: <https://dart.dev/docs>.
