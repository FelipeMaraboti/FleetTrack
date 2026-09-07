# 🎓 Guia Definitivo de Estudo e Arguição Técnica Oral - FleetTrack

> Este documento foi elaborado para que qualquer integrante do grupo consiga entender, defender com segurança e explicar com total domínio técnico cada decisão, linha de código e conceito do sistema **FleetTrack** na avaliação oral da disciplina de **Computação Móvel**.

---

## 📌 1. O que é uma "Arguição Oral"?

A **arguição oral** (ou entrevista técnica) é uma avaliação presencial/ao vivo de curta duração (cerca de **10 minutos**) onde o professor conversa diretamente com o grupo sobre o projeto entregue.

### Qual é o objetivo do professor na arguição?
O professor **não** quer apenas ver o código funcionando. O objetivo principal dele é avaliar se:
1. **Você realmente entende o que escreveu:** Ele quer garantir que o código não foi apenas copiado da internet ou gerado por IA sem compreensão.
2. **Você domina os conceitos da disciplina:** Saber explicar o que é uma *Classe Abstrata*, *Polimorfismo*, *Sound Null Safety*, *Mixins*, *Métodos Funcionais* e *JIT vs AOT*.
3. **Você sabe justificar as decisões arquiteturais:** Por que escolheu usar um `factory`? Por que a bateria é privada com `_`? Por que usamos `rethrow`?

### Dicas de ouro para a arguição:
* **Fale com calma e use os termos técnicos corretos:** Em vez de falar *"coloquei uma interrogação para não quebrar"*, diga *"utilizei tipos anuláveis e o operador de acesso seguro do Sound Null Safety"*.
* **Aponte para o arquivo certo:** Se o professor perguntar de validação, diga: *"Isso está encapsulado no setter do arquivo `dispositivo_movel.dart`"*.
* **Seja direto:** Responda a pergunta com a regra de negócio e cite o conceito teórico por trás.

---

## 🚗 2. O que é e o que faz a ferramenta FleetTrack?

O **FleetTrack** é um sistema de monitoramento de frotas e telemetria veicular para cidades inteligentes. Ele simula o **módulo central de lógica e domínio** que roda no servidor ou no dispositivo móvel de uma central de transportes.

### O fluxo principal do sistema:
1. **Cadastra veículos:** Suporta tanto carros 100% elétricos (`CarroEletrico`) quanto carros a combustão (`CarroCombustao`).
2. **Cadastra rotas urbanas:** Registra trajetos com distância em km e tempo estimado.
3. **Processa telemetria dos sensores:** Recebe coordenadas de GPS (latitude/longitude), velocidade instantânea, status da conexão e nível de bateria.
4. **Aplica regras de proteção:**
   * Se a bateria cai para menos de 20%, emite um alerta de bateria baixa.
   * Se a bateria atinge o nível crítico de **5% ou menos**, lança a exceção `RecursoCriticoException` para parada emergencial do veículo.
   * Se perde o sinal de rede (`conectado: false`), aciona o `LogAuditoriaMixin` para registrar auditoria com data e hora.
5. **Calcula métricas da frota:** Utiliza programação funcional (`fold`, `where`, `map`) para calcular média de bateria, velocidade média e quilometragem total das rotas.

---

## 🏛️ 3. Por que a arquitetura foi dividida em pastas?

Separamos o projeto no padrão de camadas de responsabilidade única:

```
lib/
├── exceptions/  -> Centraliza todos os tipos de erros próprios do negócio.
├── mixins/      -> Códigos utilitários que podem ser "plugados" em várias classes.
├── models/      -> As entidades e estruturas de dados (Veículos, Rotas, Telemetria).
├── services/    -> Onde ficam as regras de negócio complexas, listas e cálculos.
└── main.dart    -> Ponto de entrada que executa a simulação no terminal.
```

**Por que não colocar tudo em um arquivo só?**
* **Manutenibilidade e Desacoplamento:** Se a regra de cálculo de rotas mudar, alteramos apenas `GerenciadorRotas` sem risco de quebrar o modelo do `CarroEletrico`.
* **Prontidão para o Flutter:** Quando formos criar a interface gráfica na próxima etapa, os modelos e serviços já estão 100% prontos e isolados de qualquer tela.

---

## 🧠 4. Decisões Técnicas e Conceitos de Dart 3 Explicados Linha a Linha

---

### A) Abstração e Encapsulamento (`dispositivo_movel.dart`)

```dart
abstract class DispositivoMovel {
  final String id;
  final String modelo;
  double _nivelBateria; // Campo privado com _

  double get nivelBateria => _nivelBateria; // Getter

  set nivelBateria(double valor) { // Setter com validação
    if (valor < 0 || valor > 100) {
      throw DadosTelemetriaInvalidosException('Bateria fora da faixa 0-100');
    }
    _nivelBateria = valor;
  }

  void processarCargaTrabalho(double intensidade); // Método Abstrato
}
```

* **Por que `abstract class`?** Porque "Dispositivo Móvel" é um conceito genérico. Não existe um objeto "Dispositivo Móvel puro" rodando na rua; o que existe é um `CarroEletrico` ou `CarroCombustao`. A classe abstrata serve como contrato obrigatório.
* **Por que `_nivelBateria` com underline?** O `_` torna o atributo privado ao nível de arquivo (library-private). Isso impede que outro desenvolvedor faça `carro._nivelBateria = -999;` burlou as regras da física.
* **Por que Getter e Setter?** O `getter` permite que qualquer um leia a bateria livremente, mas o `setter` intercepta qualquer alteração para validar se o valor está entre 0% e 100%. Se for inválido, lança erro antes de corromper o estado do objeto.
* **Por que `final` no `id` e `modelo`?** Porque o identificador e o modelo do veículo são imutáveis após a fabricação/cadastro.

---

### B) Herança e Polimorfismo (`carro_eletrico.dart` e `carro_combustao.dart`)

```dart
// Herança: CarroEletrico herda tudo de Veiculo (que herda de DispositivoMovel)
class CarroEletrico extends Veiculo {
  final double capacidadeBateriaKwh;
  double autonomiaRestanteKm;

  // Polimorfismo: Sobrescrita do método de consumo com lógica própria de EV
  @override
  void processarCargaTrabalho(double intensidade) {
    final consumo = (intensidade * 12.0) / (capacidadeBateriaKwh / 50.0);
    nivelBateria = (nivelBateria - consumo).clamp(0.0, 100.0);
    autonomiaRestanteKm = (capacidadeBateriaKwh * 6.5) * (nivelBateria / 100);
  }
}
```

* **O que é `extends`?** É a herança direta de código. `CarroEletrico` recebe automaticamente `id`, `modelo`, `nivelBateria`, `velocidadeAtual`, etc., sem precisar reescrever essas variáveis.
* **O que é `super`?** É a chamada ao construtor ou métodos da classe pai (`super(id: id, modelo: modelo)`).
* **O que é Polimorfismo e `@override`?** É a capacidade de um mesmo método (`processarCargaTrabalho`) se comportar de formas diferentes dependendo de quem o executa:
  * No `CarroEletrico`, ele consome kWh da bateria de tração e recalcula a autonomia em km.
  * No `CarroCombustao`, o mesmo método consome litros de combustível do tanque (`nivelCombustivelLitros`) e descarrega a bateria auxiliar de 12V.

---

### C) Os Três Tipos de Construtores

O projeto demonstra obrigatoriamente os três tipos de construtores exigidos:

1. **Construtor Gerativo Padrão com Açúcar Sintático (`this.atributo` e `super.atributo`):**
   ```dart
   CarroEletrico({
     required super.id,
     required super.modelo,
     this.capacidadeBateriaKwh = 60.0,
   });
   ```
   * *Explicação:* Atribui os parâmetros diretamente aos campos sem necessidade de blocos manuais de código repetitivo.

2. **Construtor Nomeado (`Classe.nome(...)`):**
   ```dart
   CarroEletrico.economico({required String id, required String modelo})
       : capacidadeBateriaKwh = 45.0,
         autonomiaRestanteKm = 315.0,
         super(id: id, modelo: '$modelo [ECO]');
   ```
   * *Explicação:* Cria uma instância já pré-configurada para uma finalidade de negócio específica (no caso, Modo Econômico com bateria menor e motor calibrado).

3. **Construtor Factory (`factory Classe.fromMap(...)`):**
   ```dart
   factory CarroEletrico.fromMap(Map<String, dynamic> map) {
     final id = map['id'] as String?;
     if (id == null || id.isEmpty) {
       throw DadosTelemetriaInvalidosException('ID obrigatório');
     }
     return CarroEletrico(id: id, modelo: map['modelo'] ?? 'Genérico');
   }
   ```
   * *Explicação:* O `factory` não cria o objeto às cegas. Ele pode inspecionar o dicionário `Map`, validar os tipos, aplicar valores padrão com `??` e, se os dados forem inválidos, abortar e disparar uma exceção de domínio em vez de criar um objeto corrompido.

---

### D) Mixin de Auditoria (`log_auditoria_mixin.dart`)

```dart
mixin LogAuditoriaMixin {
  void registrarLog(String mensagem) {
    final timestamp = DateTime.now().toIso8601String();
    print('[AUDITORIA TELEMETRIA - $timestamp] $mensagem');
  }
}

// Uso no serviço através da palavra-chave 'with':
class ServicoTelemetria with LogAuditoriaMixin { ... }
```

* **Por que usar `mixin` em vez de herança (`extends`)?** Herança serve para modelar o que a classe **É** (`CarroEletrico` É UM `Veiculo`). O mixin serve para modelar o que a classe **FAZ** ou uma habilidade transversal que ela possui (`ServicoTelemetria` TEM A CAPACIDADE DE registrar logs de auditoria). Isso evita o problema de herança múltipla.

---

### E) Sound Null Safety e Operadores Modernos

O Dart 3 possui **Sound Null Safety**, o que significa que o sistema de tipos garante que variáveis normais nunca serão nulas em tempo de execução, eliminando erros do tipo `NullPointerException`.

* **`T?` (Tipo Anulável):** `String? rotaAtualId;` -> Indica explicitamente que o veículo pode estar sem nenhuma rota atribuída no momento (`null`).
* **`?.` (Acesso Seguro / Null-Aware Access):** `veiculo?.rotaAtualId` -> Só tenta ler a propriedade se `veiculo` não for nulo; se for nulo, retorna `null` sem quebrar o app.
* **`??` (Coalescência Nula / If-Null Operator):** `map['bateria'] as num? ?? 100.0` -> Se o valor da esquerda for nulo, assume o valor padrão da direita (100.0).
* **`??=` (Atribuição Nula):** `rotaPadrao ??= 'ROTA-CENTRO';` -> Atribui o valor `'ROTA-CENTRO'` somente se a variável `rotaPadrao` estiver nula.
* **Por que NUNCA usar o operador `!`?** O operador `!` (*bang*) força o compilador a ignorar a segurança. Se a variável for nula em tempo de execução, o sistema sofre um encerramento forçado (*crash*). No FleetTrack, tratamos a nulidade com `??` ou validações prévias.

---

### F) Programação Funcional em Coleções (`gerenciador_frota.dart`)

O professor dará muita atenção a estes métodos. Veja como explicar cada um:

1. **`.where()` (Filtragem):**
   ```dart
   _veiculos.where((v) => v.conectado).toList();
   ```
   * *O que faz:* Percorre a lista e retorna apenas os elementos que satisfazem a condição booleana (veículos online).
2. **`.map()` (Transformação):**
   ```dart
   _veiculos.map((v) => '${v.id} -> ${v.modelo}').toList();
   ```
   * *O que faz:* Transforma cada objeto `Veiculo` da lista em uma nova estrutura (neste caso, uma lista de `String`).
3. **`.fold()` (Redução / Acumulador):**
   ```dart
   final soma = _veiculos.fold<double>(0.0, (acc, v) => acc + v.nivelBateria);
   return soma / _veiculos.length;
   ```
   * *O que faz:* Começa com o valor inicial `0.0` e acumula a soma de todas as baterias da frota, permitindo calcular a média aritmética.
4. **`.any()` (Existe pelo menos um?):**
   ```dart
   _veiculos.any((v) => v.nivelBateria <= 5.0);
   ```
   * *O que faz:* Retorna `true` se encontrar **pelo menos um** veículo com bateria crítica.
5. **`.every()` (Todos atendem?):**
   ```dart
   _veiculos.every((v) => v.conectado && v.nivelBateria >= 20.0);
   ```
   * *O que faz:* Retorna `true` apenas se **todos** os veículos da frota estiverem conectados e com carga suficiente.

---

### G) Operadores de Coleção: Spread Operator, Collection-If e Collection-For

```dart
List<String> gerarRelatorioFormatado({List<String>? avisosAdicionais}) {
  return [
    '=== PAINEL DE MONITORAMENTO ===',
    // Collection-For com Spread Operator (...)
    for (final veiculo in _veiculos) ...[
      'Veículo ${veiculo.id}: ${veiculo.modelo}',
      // Collection-If
      if (veiculo.nivelBateria < 20.0)
        '   [ALERTA] Bateria baixa no veículo ${veiculo.id}!',
    ],
    // Null-Aware Spread Operator (...?)
    ...?avisosAdicionais,
    '===============================',
  ];
}
```

* **Spread Operator (`...`):** Despeja múltiplos itens de uma lista dentro de outra lista. Exemplo: `[..._veiculos]` clona a lista original defensivamente.
* **Null-Aware Spread Operator (`...?`):** Só expande a lista `avisosAdicionais` se ela **não** for nula.
* **Collection-If:** Inclui uma linha na lista apenas se uma condição for verdadeira (ex: só adiciona a linha de aviso se a bateria for menor que 20%).
* **Collection-For:** Executa um laço `for` diretamente na declaração da lista, gerando os itens dinamicamente.

---

### H) Tratamento de Exceções com `try`, `on`, `catch`, `finally` e `rethrow`

```dart
void processarComAuditoria(LeituraTelemetria leitura, Veiculo veiculo) {
  try {
    processarLeitura(leitura, veiculo);
  } on RecursoCriticoException catch (e) {
    // 1. Registra a auditoria no serviço
    registrarLog('Falha crítica capturada: ${e.mensagem}');
    // 2. Propaga o erro para a CLI tratar com rethrow
    rethrow;
  } finally {
    // 3. SEMPRE é executado, dando ou não erro
    registrarLog('Ciclo de telemetria finalizado.');
  }
}
```

* **`try`:** Bloco onde o código perigoso é executado.
* **`on RecursoCriticoException`:** Filtra para capturar especificamente a nossa exceção customizada de bateria crítica.
* **`catch (e)`:** Recebe a instância do erro com a mensagem.
* **`finally`:** Bloco que executa **sempre**, ocorra erro ou não (ideal para fechar conexões, limpar memória e finalizar ciclos).
* **`rethrow`:** Permite que o serviço trate o erro parcialmente (gerando o log de auditoria) e repasse a mesma exceção para que a camada superior (`main.dart`) receba o erro e decida acionar o guincho/alerta.

---

## 📱 5. Relação com a Computação Móvel e Flutter (Perguntas Chave do Professor)

### 1. O que é JIT vs AOT em Dart/Flutter?
* **JIT (*Just-In-Time*):** Compila o código em tempo de execução no modo de desenvolvimento (*debug*). É graças ao JIT que o Flutter possui o **Stateful Hot Reload**, permitindo alterar o código e ver o resultado na tela do celular em 1 segundo sem reiniciar o app.
* **AOT (*Ahead-Of-Time*):** Compila o código Dart diretamente para código de máquina nativo (binário ARM/x86) antes da instalação. É utilizado no modo de produção (*release*), garantindo que o app abra rápido e rode liso a 60/120 FPS sem depender de máquina virtual pesada.

### 2. Como o FleetTrack respeita as restrições da Computação Móvel?
* **Economia de Energia/Bateria:** Celulares e rastreadores automotivos têm bateria finita. O sistema simula o gasto energético e possui construtores em modo econômico (`CarroEletrico.economico`), reduzindo o consumo de processamento.
* **Tolerância a Perda de Sinal (Offline-First):** O sistema detecta quando `conectado: false`, mantendo a integridade dos dados e gerando logs para sincronização posterior.
* **Contenção de Falhas Críticas:** Com o `RecursoCriticoException`, o app suspende operações antes que o hardware do dispositivo desligue abruptamente e corrompa o banco de dados local.

---

## 🎤 6. Simulado Rápido de Arguição (Top 10 Perguntas Frequentes)

| Pergunta do Professor | Resposta Direta e Certeira |
|---|---|
| **1. Onde está o polimorfismo?** | No método `processarCargaTrabalho()`, onde o carro elétrico consome kWh e recalcula autonomia em km, enquanto o a combustão consome litros do tanque e desgasta a bateria de 12V. |
| **2. Para que serve o mixin?** | Para reutilizar a função de log de auditoria (`registrarLog`) com timestamp no `ServicoTelemetria` via `with LogAuditoriaMixin`, sem poluir a árvore de herança. |
| **3. Por que a bateria é `_nivelBateria`?** | Para encapsulamento. O `_` impede que ela seja alterada diretamente de fora do arquivo, forçando a passagem pelo setter que valida a faixa de 0% a 100%. |
| **4. O que faz o construtor `factory`?** | Valida os dados de um `Map` antes de instanciar o objeto. Se vierem dados nulos ou inválidos, ele aplica valores padrão ou lança `DadosTelemetriaInvalidosException`. |
| **5. Qual a diferença entre `...` e `...?`?** | O `...` expande uma lista normal; o `...?` é null-aware e só expande a lista se ela não for nula, evitando erros em tempo de execução. |
| **6. Como foi calculada a média de bateria?** | Usando o método funcional `_veiculos.fold<double>(0.0, (soma, v) => soma + v.nivelBateria) / _veiculos.length`. |
| **7. Por que criamos exceções próprias?** | Para representar cenários reais do domínio (como `RecursoCriticoException` para bateria ≤ 5%), permitindo capturas seletivas com a cláusula `on`. |
| **8. Quando você usa `rethrow`?** | Quando queremos interceptar o erro no serviço para gravar um log de auditoria e, em seguida, propagar o mesmo erro para a interface de usuário tratar. |
| **9. Onde foi demonstrado o Sound Null Safety?** | Em todo o código: usamos tipos anuláveis (`String? rotaAtualId`), acessos seguros `?.`, coalescência nula `??` e atribuição `??=`, sem nenhum operador inseguro `!`. |
| **10. O que acontece na próxima etapa com Flutter?** | Vamos plugar esses mesmos modelos e serviços em Widgets reativos do Flutter (como Google Maps para plotar os veículos e velocímetros visuais com `CustomPainter`). |

---

> 💡 **Dica Final:** Antes de ir para a avaliação, execute o comando `dart run` uma vez no seu terminal acompanhando o arquivo [lib/main.dart](file:///c:/Users/user/Downloads/FleetTrack/lib/main.dart). A apresentação segue exatamente a mesma ordem das seções impressas no console!
