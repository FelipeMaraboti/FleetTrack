# Environment Report — FleetTrack (AP2B)

Este documento descreve o ambiente de desenvolvimento, dependências e diagnóstico técnico utilizados para construção e validação do aplicativo **FleetTrack** na Avaliação Processual 2B (Marco 2).

---

## 1. Informações do Ambiente

* **Sistema Operacional:** Windows 10 / 11 (64-bit)
* **Flutter SDK:** Flutter 3.x (Canal `stable`)
* **Dart SDK:** Dart 3.x (Sound Null Safety)
* **IDE:** Visual Studio Code / Android Studio
* **Persistência Local:** `sqflite` (Android/iOS) + `sqflite_common_ffi` (Windows/Linux Desktop) + `shared_preferences`
* **Comunicação de Rede:** `package:http` (REST JSON com `MockClient` para testes sem emulador)
* **Framework de Testes:** `flutter_test` (Testes de Unidade e `testWidgets`)

---

## 2. Comandos de Verificação e Execução

### Diagnóstico do Flutter
```bash
flutter doctor -v
```

### Análise Estática de Código
```bash
flutter analyze
```

### Execução da Suíte de Testes Automatizados
```bash
flutter test
```

### Execução do Aplicativo Móvel / Desktop
```bash
flutter pub get
flutter run
```

---

## 3. Resumo da Validação Automatizada (`flutter test`)

* **`test/dominio_ap1b_test.dart`:** 9 testes de unidade validando encapsulamento, construtores `factory`/nomeados, polimorfismo (`CarroEletrico` vs. `CarroCombustao`), coleções funcionais (`where`, `map`, `fold`, `any`, `every`) e exceções de domínio (`RecursoCriticoException`, `DadosTelemetriaInvalidosException`).
* **`test/serializacao_test.dart`:** 12 testes de unidade validando `toMap()`, `fromMap()`, `copyWith()` e `toJson()` para `Rota`, `LeituraTelemetria`, `LogSincronizacao` e `CondicaoClima`.
* **`test/repositorio_offline_test.dart`:** 13 testes de unidade validando a estratégia **Offline-First** com `MockClient`: escrita resiliente em falha HTTP `500`, queda de socket/DNS, `timeout`, modo offline simulado, sincronização em lote (`POST`), exclusão lógica seguida de `DELETE` remoto e cache local de clima.
* **`test/widgets_test.dart`:** 8 testes de widgets (`testWidgets`) validando renderização do Dashboard, ícones de estado de sincronização, listagens dinâmicas, validação de campos obrigatórios nos formulários de Rota e Telemetria, cadastro offline, alternância do banner de modo offline e proteção de rotas inválidas.
