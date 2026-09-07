# FleetTrack - Sistema de Gestão de Frota e Telemetria Veicular

> Projeto acadêmico desenvolvido para a disciplina de **Computação Móvel** (AP1B - Marco 1).
> Demonstração de domínio avançado em **Dart 3**, Programação Orientada a Objetos (POO), Sound Null Safety, coleções funcionais e regras de negócio de mobilidade urbana.

---

## 👥 Identificação do Grupo

* **Instituição:** Faculdade Multivix
* **Disciplina:** Computação Móvel (2026/2) - Professor Edgard Pontes
* **Tema 01:** Mobilidade Urbana & Telemetria
* **Prazo de Entrega:** Até 10/09/2026

### Integrantes da Equipe (Máximo 5 pessoas):
1. **Enock de Oliveira Memelli Junio**
2. **Felipe Sabino Maraboti**
3. **Pedro José Muchelin Acha**
4. **Samuel Mota Moysés**

---

## 1. Descrição do Projeto

O **FleetTrack** é um sistema de monitoramento de frotas e telemetria veicular em tempo real voltado para cenários urbanos conectados. O sistema atua como o núcleo de processamento lógico de dados emitidos por dispositivos móveis embarcados em veículos elétricos e a combustão, monitorando parâmetros vitais como posicionamento GPS, velocidade instantânea, níveis de energia/combustível e estado de conectividade.

---

## 2. Tema e Domínio

* **Tema:** Mobilidade Urbana & Telemetria
* **Domínio:** Gestão de rotas, consumo energético, veículos conectados e telemetria de sensores móveis (GPS, velocidade, bateria).

---

## 3. Objetivo Acadêmico

O objetivo central desta etapa é implementar e consolidar uma arquitetura de domínio limpa, robusta e modular em Dart puro (executável via CLI), servindo de alicerce para futuras interfaces móveis em Flutter. O código foi projetado para ser **didático, conciso e 100% defensável em arguição oral**, sem abstrações desnecessárias ou bibliotecas mágicas.

---

## 4. Funcionalidades Principais

* **Cadastro e Gestão de Veículos:** Suporte a modelos polimórficos (veículos elétricos e veículos a combustão).
* **Gestão de Rotas Urbanas:** Cadastro de percursos, ativação/desativação, cálculo de velocidades médias planejadas e malha de pontos atendidos.
* **Processamento de Telemetria:** Ingestão de snapshots de sensores (coordenadas GPS, velocidade e carga).
* **Monitoramento de Bateria e Consumo:** Simulação polimórfica de consumo energético com recálculo de autonomia em km e dreno de combustível.
* **Sistema de Alertas e Segurança:**
  * Alerta de bateria baixa (nível abaixo de 20%).
  * Disparo de `RecursoCriticoException` em situações de risco operacional (bateria ≤ 5%).
  * Detecção e auditoria de perda de sinal/desconexão.
* **Métricas da Frota com Programação Funcional:** Cálculo de médias de bateria, velocidade da frota em trânsito e verificação de prontidão operacional.
* **Registro Transversal de Auditoria:** Rastreamento com carimbo temporal via Mixin (`LogAuditoriaMixin`).

---

## 5. Arquitetura do Software

A aplicação adota uma organização em camadas de responsabilidade única:

```
fleet_track/
│
├── lib/
│   ├── exceptions/              # Exceções customizadas de domínio
│   │   └── telemetria_exceptions.dart
│   │
│   ├── mixins/                  # Comportamentos transversais reutilizáveis
│   │   └── log_auditoria_mixin.dart
│   │
│   ├── models/                  # Entidades de domínio e POO pura
│   │   ├── dispositivo_movel.dart  # Abstração base de hardware conectado
│   │   ├── veiculo.dart           # Especialização intermediária para veículos
│   │   ├── carro_eletrico.dart    # Subclasse de veículo 100% elétrico
│   │   ├── carro_combustao.dart   # Subclasse de veículo a combustão
│   │   ├── leitura_telemetria.dart# Snapshot de leitura de sensores
│   │   └── rota.dart              # Modelagem de trajetos urbanos
│   │
│   ├── services/                # Regras de negócio e agregação de dados
│   │   ├── gerenciador_frota.dart # Gerenciamento, buscas e métricas funcionais
│   │   ├── gerenciador_rotas.dart # Gestão e somatórios da malha de trajetos
│   │   └── servico_telemetria.dart# Processamento de sensores e contenção
│   │
│   └── main.dart                # Ponto de entrada e fluxo CLI demonstrativo
│
├── test/
│   └── fleet_track_test.dart    # Suíte de testes unitários automatizados
│
├── ENVIRONMENT_REPORT.md        # Relatório de ambiente e ferramentas
├── .gitignore                   # Regras de exclusão para Git
└── pubspec.yaml                 # Manifesto do projeto Dart
```

---

## 6. Conceitos de Dart 3 Aplicados

| Conceito | Aplicação Prática no FleetTrack |
|---|---|
| **Abstração** | `abstract class DispositivoMovel` define o contrato e método abstrato `processarCargaTrabalho()`. |
| **Herança & Polimorfismo** | `CarroEletrico` e `CarroCombustao` herdam de `Veiculo` (que herda de `DispositivoMovel`) e implementam regras distintas de consumo. |
| **Encapsulamento** | Campo privado `_nivelBateria` protegido por getter e setter com validação estrita (0 a 100). |
| **Mixins** | `LogAuditoriaMixin` com `registrarLog()` acoplado via `with` em `ServicoTelemetria`. |
| **Construtores Gerativos** | Utilização de `this.atributo` e inicialização de superclasse com `super.id`. |
| **Construtor Nomeado** | `CarroEletrico.economico()` parametrizando veículos para máxima eficiência energética. |
| **Construtor Factory** | `CarroEletrico.fromMap()` e `LeituraTelemetria.fromMap()` para desserialização segura sem crashes. |
| **Sound Null Safety** | Tipos anuláveis (`String? rotaAtualId`), chamadas seguras (`?.`), coalescência nula (`??`) e atribuição condicional (`??=`). |
| **Coleções Funcionais** | `.where()` (filtros), `.map()` (transformações), `.fold()` (agregações e médias), `.any()` e `.every()` (validações). |
| **Operadores de Coleção** | Spread operator (`...`), Collection-if e Collection-for gerando relatórios dinâmicos. |
| **Tratamento de Exceções** | `try`, `on TipoExcecao`, `catch`, `finally` e propagação explícita com `rethrow`. |

---

## 7. Como Executar

### Pré-requisitos
* **Dart SDK** (versão 3.0.0 ou superior) ou **Flutter SDK**.

### Instalação de Dependências
Abra o terminal na pasta raiz do projeto e execute:
```bash
dart pub get
```

### Execução da Aplicação (CLI)
Para executar a simulação completa no terminal:
```bash
dart run
```
*(ou `dart run bin/main.dart` / `dart run lib/main.dart`)*

### Execução dos Testes Unitários
Para rodar a suíte de validações automatizadas:
```bash
dart test
```

---

## 8. Declaração de Uso de Inteligência Artificial

Ferramentas de Inteligência Artificial Generativa foram utilizadas como recurso de apoio durante o desenvolvimento do projeto, principalmente em atividades de brainstorming, organização de documentos e sugestão de casos de teste.

As decisões relacionadas à arquitetura, implementação e funcionamento do sistema foram realizadas e validadas pelos estudantes. Todo o conteúdo gerado com auxílio de IA foi revisado pela equipe, que possui domínio sobre as soluções e decisões adotadas no projeto.

---

## 9. Referências Bibliográficas

1. **DART DEV**. *Dart Programming Language Documentation*. Disponível em: <https://dart.dev/guides>. Acesso em: 2026.
2. **FLUTTER DEV**. *Flutter Architectural Overview*. Disponível em: <https://docs.flutter.dev>. Acesso em: 2026.
3. **GAMMA, E. et al.** *Padrões de Projeto: Soluções Reutilizáveis de Software Orientado a Objetos*. Porto Alegre: Bookman, 2000.
4. **MARTIN, R. C.** *Clean Code: A Handbook of Agile Software Craftsmanship*. Prentice Hall, 2008.
