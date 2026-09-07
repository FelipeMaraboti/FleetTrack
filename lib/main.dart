import 'exceptions/telemetria_exceptions.dart';
import 'models/carro_combustao.dart';
import 'models/carro_eletrico.dart';
import 'models/leitura_telemetria.dart';
import 'models/rota.dart';
import 'models/veiculo.dart';
import 'services/gerenciador_frota.dart';
import 'services/gerenciador_rotas.dart';
import 'services/servico_telemetria.dart';

void main() {
  // =========================================================================
  // 1. TÍTULO DO SISTEMA
  // =========================================================================
  print('========================================');
  print('               FLEETTRACK               ');
  print('       MOBILIDADE URBANA & TELEMETRIA   ');
  print('========================================\n');

  final frotaService = GerenciadorFrota();
  final rotasService = GerenciadorRotas();
  final telemetriaService = ServicoTelemetria();

  // =========================================================================
  // 2, 3, 4, 5. INSTANCIAÇÃO E CADASTRO DE VEÍCULOS
  // Demonstrando: Construtor Gerativo, Construtor Nomeado e Factory fromMap()
  // =========================================================================
  print('## [1] CADASTRANDO VEÍCULOS');

  // [2] Construtor Gerativo Padrão (CarroEletrico e CarroCombustao)
  final v1 = CarroEletrico(
    id: 'VEI-001',
    modelo: 'BYD Dolphin EV',
    capacidadeBateriaKwh: 60.0,
    nivelBateria: 85.0,
    conectado: true,
  );

  final v2 = CarroCombustao(
    id: 'VEI-002',
    modelo: 'Toyota Corolla 2.0',
    capacidadeTanqueLitros: 50.0,
    nivelCombustivelLitros: 35.0,
    nivelBateria: 18.0, // Bateria baixa para demonstrar alerta
    conectado: true,
  );

  // [3] Construtor Nomeado (.economico)
  final v3 = CarroEletrico.economico(
    id: 'VEI-003',
    modelo: 'Renault Kwid E-Tech',
    nivelBateria: 100.0,
  );

  // [4] Construtor Factory (.fromMap) com validação de dados
  final dadosVeiculoMap = <String, dynamic>{
    'id': 'VEI-004',
    'modelo': 'Volvo XC40 Recharge',
    'bateria': 92.0,
    'capacidadeBateriaKwh': 78.0,
    'conectado': true,
    'velocidade': 0.0,
  };
  final v4 = CarroEletrico.fromMap(dadosVeiculoMap);

  // [5] Cadastrar veículos no gerenciador
  frotaService.cadastrar(v1);
  frotaService.cadastrar(v2);
  frotaService.cadastrar(v3);
  frotaService.cadastrar(v4);

  print('[OK] ${v1.id} - ${v1.modelo} (Construtor Gerativo)');
  print('[OK] ${v2.id} - ${v2.modelo} (Construtor Gerativo)');
  print('[OK] ${v3.id} - ${v3.modelo} (Construtor Nomeado .economico)');
  print('[OK] ${v4.id} - ${v4.modelo} (Construtor Factory .fromMap)\n');

  // =========================================================================
  // 6, 7. CADASTRO DE ROTAS URBANAS
  // =========================================================================
  print('## [2] CADASTRANDO ROTAS URBANAS');

  final rota1 = Rota(
    id: 'ROTA-001',
    origem: 'Centro Urbano',
    destino: 'Aeroporto Internacional',
    distanciaKm: 28.5,
    tempoEstimadoMinutos: 35.0,
  );

  final rota2 = Rota(
    id: 'ROTA-002',
    origem: 'Centro Urbano',
    destino: 'Campus Universitário',
    distanciaKm: 14.0,
    tempoEstimadoMinutos: 25.0,
  );

  final rota3 = Rota(
    id: 'ROTA-003',
    origem: 'Polo Industrial',
    destino: 'Porto Seco',
    distanciaKm: 42.0,
    tempoEstimadoMinutos: 50.0,
  );

  rotasService.cadastrar(rota1);
  rotasService.cadastrar(rota2);
  rotasService.cadastrar(rota3);

  // Atribuição de rotas aos veículos
  v1.rotaAtualId = rota1.id;
  v2.rotaAtualId = rota2.id;
  v3.rotaAtualId = rota3.id;

  print('[OK] ${rota1.id} - ${rota1.origem} -> ${rota1.destino} (${rota1.distanciaKm} km)');
  print('[OK] ${rota2.id} - ${rota2.origem} -> ${rota2.destino} (${rota2.distanciaKm} km)');
  print('[OK] ${rota3.id} - ${rota3.origem} -> ${rota3.destino} (${rota3.distanciaKm} km)');
  print('   Pontos únicos atendidos (Set): ${rotasService.obterPontosAtendidos()}\n');

  // =========================================================================
  // 8, 9. PROCESSAMENTO DE LEITURAS DE TELEMETRIA
  // =========================================================================
  print('## [3] PROCESSANDO TELEMETRIA DOS SENSORES EM TEMPO REAL');

  final leitura1 = LeituraTelemetria(
    veiculoId: 'VEI-001',
    latitude: -20.6734,
    longitude: -41.3128,
    velocidade: 52.0,
    bateria: 78.0,
    conectado: true,
  );

  final leitura2 = LeituraTelemetria(
    veiculoId: 'VEI-002',
    latitude: -20.6802,
    longitude: -41.3055,
    velocidade: 68.0,
    bateria: 17.5, // Nível que aciona alerta de bateria baixa
    conectado: true,
  );

  final leitura4 = LeituraTelemetria(
    veiculoId: 'VEI-004',
    latitude: -20.6650,
    longitude: -41.3200,
    velocidade: 45.0,
    bateria: 88.0,
    conectado: true,
  );

  // Processando leituras normais
  print('\nProcessando telemetria ${v1.id}:');
  telemetriaService.processarLeitura(leitura1, v1);
  print('   GPS: (${leitura1.latitude}, ${leitura1.longitude})');
  print('   Velocidade: ${v1.velocidadeAtual.toStringAsFixed(0)} km/h | Bateria: ${v1.nivelBateria.toStringAsFixed(1)}% | Status: ONLINE');

  print('\nProcessando telemetria ${v2.id}:');
  telemetriaService.processarLeitura(leitura2, v2);
  print('   GPS: (${leitura2.latitude}, ${leitura2.longitude})');
  print('   Velocidade: ${v2.velocidadeAtual.toStringAsFixed(0)} km/h | Bateria: ${v2.nivelBateria.toStringAsFixed(1)}% | Status: ONLINE');

  print('\nProcessando telemetria ${v4.id}:');
  telemetriaService.processarLeitura(leitura4, v4);
  print('   GPS: (${leitura4.latitude}, ${leitura4.longitude})');
  print('   Velocidade: ${v4.velocidadeAtual.toStringAsFixed(0)} km/h | Bateria: ${v4.nivelBateria.toStringAsFixed(1)}% | Status: ONLINE\n');

  // =========================================================================
  // 10, 11, 12, 13. DEMONSTRAÇÃO DE MÉTODOS FUNCIONAIS E COLEÇÕES
  // map(), where(), fold(), any(), every(), Set, Map
  // =========================================================================
  print('## [4] MÉTODOS FUNCIONAIS DE COLEÇÕES (Dart 3)');

  // [14] .map() - Transformação de objetos em strings
  print('\n-- [14] Demonstração de .map() (Mapeamento de modelos):');
  final listaFormatadaModelos = frotaService.obterResumoModelos();
  for (final item in listaFormatadaModelos) {
    print('   • $item');
  }

  // [15] .where() - Filtragem de coleções
  print('\n-- [15] Demonstração de .where() (Filtros de conectados e bateria baixa):');
  final conectados = frotaService.obterVeiculosConectados();
  final bateriaBaixa = frotaService.obterVeiculosComBateriaBaixa(limite: 20.0);
  print('   Veículos conectados (${conectados.length}): ${conectados.map((v) => v.id).toList()}');
  print('   Veículos com bateria < 20% (${bateriaBaixa.length}): ${bateriaBaixa.map((v) => "${v.id} (${v.nivelBateria.toStringAsFixed(1)}%)").toList()}');

  // [16] .fold() - Redução agregada para cálculos de médias
  print('\n-- [16] Demonstração de .fold() (Cálculo acumulado):');
  final mediaBateria = frotaService.calcularMediaBateria();
  final mediaVelocidade = frotaService.calcularVelocidadeMedia();
  final totalDistanciaRotas = rotasService.calcularDistanciaTotalAtiva();
  print('   Média de Bateria da Frota: ${mediaBateria.toStringAsFixed(1)}%');
  print('   Velocidade Média da Frota em Operação: ${mediaVelocidade.toStringAsFixed(1)} km/h');
  print('   Extensão Total das Rotas Ativas: ${totalDistanciaRotas.toStringAsFixed(1)} km');

  // [17] .any() - Verificação de existência
  print('\n-- [17] Demonstração de .any():');
  final temCritico = frotaService.existeVeiculoCritico(limiteCritico: 5.0);
  print('   Existe veículo em estado crítico (<= 5% bateria)? $temCritico');

  // [18] .every() - Verificação universal
  print('\n-- [18] Demonstração de .every():');
  final todosOperacionais = frotaService.todosAptosParaOperacao(limiteMinimo: 20.0);
  print('   Todos os veículos estão 100% aptos para operação (online e bateria >= 20%)? $todosOperacionais\n');

  // =========================================================================
  // 19, 20, 21. SPREAD OPERATOR, COLLECTION-IF E COLLECTION-FOR
  // =========================================================================
  print('## [5] SPREAD OPERATOR (...), COLLECTION-IF E COLLECTION-FOR');

  // [19] Spread Operator (...) e Null-Aware Spread Operator (...?)
  final frotaCopia = [...frotaService.obterTodos()];
  print('   Spread Operator (...): Lista de ${frotaCopia.length} veículos clonada com sucesso.');

  // [20 e 21] Collection-For, Collection-If e Null-Aware Spread Operator (...?)
  print('\n   Relatório gerado dinamicamente com Collection-For, Collection-If e Spread Operators:');
  final List<String>? avisosOperacionais = [
    '   [AVISO GERAL] Horário de pico metropolitano iniciado às 17:00.',
    '   [AVISO GERAL] Monitoramento contínuo de rota e telemetria ativo.',
  ];
  final relatorioDinamico = frotaService.gerarRelatorioFormatado(
    avisosAdicionais: avisosOperacionais,
  );
  for (final linha in relatorioDinamico) {
    print('   $linha');
  }
  print('');

  // =========================================================================
  // 22, 23, 24, 25. TRATAMENTO ROBUSTO DE EXCEÇÕES E AUDITORIA
  // try, on, catch, finally, rethrow, mixin LogAuditoriaMixin
  // =========================================================================
  print('## [6] SIMULAÇÃO DE SITUAÇÕES CRÍTICAS, EXCEÇÕES E AUDITORIA');

  // [24 e 25] Perda de conectividade registrada no mixin de auditoria
  print('\n-- [24/25] Simulação: Perda de Conectividade de Sensor');
  final leituraDesconectado = LeituraTelemetria(
    veiculoId: 'VEI-003',
    latitude: -20.6910,
    longitude: -41.3190,
    velocidade: 0.0,
    bateria: 40.0,
    conectado: false, // Perda de sinal
  );
  telemetriaService.processarLeitura(leituraDesconectado, v3);

  // [22 e 23] Simulação de bateria crítica disparando RecursoCriticoException com try/on/catch/finally e rethrow
  print('\n-- [22/23] Simulação: Bateria Crítica (<= 5%) com try-on-catch-finally e rethrow');
  final leituraCritica = LeituraTelemetria(
    veiculoId: 'VEI-003',
    latitude: -20.6950,
    longitude: -41.3250,
    velocidade: 20.0,
    bateria: 3.5, // Nível crítico (<= 5%)
    conectado: true,
  );

  try {
    print('Tentando processar ciclo crítico para ${v3.id}...');
    // O método processarComAuditoria trata a falha no serviço, loga via mixin e faz rethrow
    telemetriaService.processarComAuditoria(leituraCritica, v3);
  } on RecursoCriticoException catch (e) {
    print('   [TRATAMENTO NA CLI - on RecursoCriticoException]');
    print('   Exceção interceptada no ponto de entrada: $e');
    print('   Ação tomada: Acionando guincho e notificando central de operações!');
  } on DadosTelemetriaInvalidosException catch (e) {
    print('   [TRATAMENTO NA CLI - on DadosTelemetriaInvalidosException]: $e');
  } catch (e, stackTrace) {
    print('   [TRATAMENTO GENÉRICO]: $e\n$stackTrace');
  } finally {
    print('   [BLOCO FINALLY DA CLI]: Ciclo de contenção de emergência concluído com segurança.\n');
  }

  // [26] Demonstração de exceção de dados inválidos (GPS fora dos limites)
  print('-- [26] Demonstração: Validação de Dados Inválidos (DadosTelemetriaInvalidosException)');
  try {
    print('Tentando criar leitura com latitude impossível (150.0°)...');
    LeituraTelemetria(
      veiculoId: 'VEI-001',
      latitude: 150.0, // Inválido! Limite é [-90, +90]
      longitude: -41.0,
      velocidade: 50.0,
      bateria: 80.0,
    );
  } on DadosTelemetriaInvalidosException catch (e) {
    print('   [SUCESSO NA PROTEÇÃO]: Exceção disparada corretamente: $e\n');
  }

  // =========================================================================
  // DEMONSTRAÇÃO EXPLÍCITA DE SOUND NULL SAFETY (?, ??, ??=)
  // =========================================================================
  print('## [7] DEMONSTRAÇÃO COMPLEMENTAR DE SOUND NULL SAFETY');
  // Variável anulável T?
  String? rotaOpcional;
  print('   1. Variável anulável (T?): $rotaOpcional');

  // Operador de atribuição nula ??=
  rotaOpcional ??= 'ROTA-RESERVA-URBANA';
  print('   2. Valor após operador ??=: $rotaOpcional');

  // Operador de acesso seguro ?. e coalescência nula ??
  final Veiculo? veiculoConsultado = frotaService.buscarPorId('VEI-001');
  final idRotaSegura = veiculoConsultado?.rotaAtualId ?? 'Nenhuma rota vinculada';
  print('   3. Operadores ?. e ??: Veículo ${veiculoConsultado?.id} -> $idRotaSegura\n');

  // =========================================================================
  // 27. RELATÓRIO FINAL CONSOLIDADO DA FROTA
  // =========================================================================
  print('========================================');
  print('        RELATÓRIO CONSOLIDADO DA FROTA  ');
  print('========================================');
  print('Total de Veículos Cadastrados: ${frotaService.totalVeiculos}');
  print('Total de Veículos Conectados:   ${frotaService.obterVeiculosConectados().length}');
  print('Total de Rotas Cadastradas:     ${rotasService.totalRotas}');
  print('Bateria Média da Frota:         ${frotaService.calcularMediaBateria().toStringAsFixed(1)}%');
  print('Velocidade Média em Trânsito:   ${frotaService.calcularVelocidadeMedia().toStringAsFixed(1)} km/h');
  print('Veículos em Estado Crítico:     ${frotaService.existeVeiculoCritico() ? "SIM (Atenção imediata)" : "NÃO (Frota estável)"}');
  print('========================================');
  print('        FIM DA SIMULAÇÃO FLEETTRACK     ');
  print('========================================');
}
