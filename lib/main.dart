import 'dart:io';

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
  final frotaService = GerenciadorFrota();
  final rotasService = GerenciadorRotas();
  final telemetriaService = ServicoTelemetria();

  // Inicializa dados padrão para o ambiente
  _inicializarDadosBase(frotaService, rotasService);

  bool executando = true;

  while (executando) {
    _imprimirCabecalhoMenu();
    stdout.write('Escolha uma opção [0-9]: ');
    final entrada = stdin.readLineSync()?.trim();

    print('\n========================================');
    switch (entrada) {
      case '1':
        _opcaoCadastrarVeiculos(frotaService);
        break;
      case '2':
        _opcaoCadastrarRotas(rotasService);
        break;
      case '3':
        _opcaoProcessarTelemetria(telemetriaService, frotaService);
        break;
      case '4':
        _opcaoMetodosFuncionais(frotaService, rotasService);
        break;
      case '5':
        _opcaoColecoesAvancadas(frotaService);
        break;
      case '6':
        _opcaoExcecoesAuditoria(telemetriaService, frotaService);
        break;
      case '7':
        _opcaoSoundNullSafety(frotaService);
        break;
      case '8':
        _opcaoRelatorioConsolidado(frotaService, rotasService);
        break;
      case '9':
        _opcaoExecutarSimulacaoCompleta(
          frotaService,
          rotasService,
          telemetriaService,
        );
        break;
      case '0':
        print('Encerrando o FleetTrack. Até logo!');
        print('========================================\n');
        executando = false;
        continue;
      default:
        print('❌ Opção inválida! Por favor, escolha um número de 0 a 9.');
    }

    if (executando) {
      _pausarParaContinuar();
    }
  }
}

// =========================================================================
// INICIALIZAÇÃO DE DADOS BASE
// =========================================================================
void _inicializarDadosBase(
  GerenciadorFrota frotaService,
  GerenciadorRotas rotasService,
) {
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
    nivelBateria: 18.0,
    conectado: true,
  );

  final v3 = CarroEletrico.economico(
    id: 'VEI-003',
    modelo: 'Renault Kwid E-Tech',
    nivelBateria: 100.0,
  );

  final dadosVeiculoMap = <String, dynamic>{
    'id': 'VEI-004',
    'modelo': 'Volvo XC40 Recharge',
    'bateria': 92.0,
    'capacidadeBateriaKwh': 78.0,
    'conectado': true,
    'velocidade': 0.0,
  };
  final v4 = CarroEletrico.fromMap(dadosVeiculoMap);

  frotaService.cadastrar(v1);
  frotaService.cadastrar(v2);
  frotaService.cadastrar(v3);
  frotaService.cadastrar(v4);

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

  v1.rotaAtualId = rota1.id;
  v2.rotaAtualId = rota2.id;
  v3.rotaAtualId = rota3.id;
}

// =========================================================================
// MENU PRINCIPAL
// =========================================================================
void _imprimirCabecalhoMenu() {
  print('''
========================================
               FLEETTRACK               
       MOBILIDADE URBANA & TELEMETRIA   
========================================
 [1] 🚗 Cadastro & Demonstração de Construtores
 [2] 🗺️  Cadastro & Gestão de Rotas Urbanas
 [3] 📡 Processamento de Telemetria dos Sensores
 [4] ⚡ Métodos Funcionais de Coleções (Dart 3)
 [5] 📊 Painel Dinâmico (Spread & Collection-If/For)
 [6] ⚠️  Simulação de Exceções & Auditoria
 [7] 🛡️  Sound Null Safety (?, ?., ??, ??=)
 [8] 📈 Relatório Consolidado da Frota
 [9] 🚀 Executar Simulação Completa (Tudo)
 [0] ❌ Sair
========================================''');
}

void _pausarParaContinuar() {
  stdout.write('\nPressione [ENTER] para voltar ao menu principal...');
  stdin.readLineSync();
  print('\n');
}

// =========================================================================
// OPÇÃO 1: CADASTRO E CONSTRUTORES
// =========================================================================
void _opcaoCadastrarVeiculos(GerenciadorFrota frotaService) {
  print('## [1] CADASTRANDO VEÍCULOS & TIPOS DE CONSTRUTORES\n');

  final v1 = frotaService.buscarPorId('VEI-001');
  final v2 = frotaService.buscarPorId('VEI-002');
  final v3 = frotaService.buscarPorId('VEI-003');
  final v4 = frotaService.buscarPorId('VEI-004');

  print('[OK] ${v1.id} - ${v1.modelo} (Construtor Gerativo Padrão)');
  print(
      '     ↳ Bateria: ${v1.nivelBateria.toStringAsFixed(1)}% | Tração: Elétrica');

  print('[OK] ${v2.id} - ${v2.modelo} (Construtor Gerativo)');
  print(
      '     ↳ Bateria: ${v2.nivelBateria.toStringAsFixed(1)}% | Tanque: ${(v2 as CarroCombustao).nivelCombustivelLitros}L');

  print('[OK] ${v3.id} - ${v3.modelo} (Construtor Nomeado .economico)');
  print(
      '     ↳ Bateria: ${v3.nivelBateria.toStringAsFixed(1)}% | Autonomia otimizada');

  print('[OK] ${v4.id} - ${v4.modelo} (Construtor Factory .fromMap)');
  print(
      '     ↳ Bateria: ${v4.nivelBateria.toStringAsFixed(1)}% | Criado a partir de Map com validações');

  print('\nTotal de veículos ativos no sistema: ${frotaService.totalVeiculos}');
}

// =========================================================================
// OPÇÃO 2: ROTAS URBANAS
// =========================================================================
void _opcaoCadastrarRotas(GerenciadorRotas rotasService) {
  print('## [2] CADASTRO E GESTÃO DE ROTAS URBANAS\n');

  for (final rota in rotasService.obterTodas()) {
    print('[OK] ${rota.id} - ${rota.origem} ➔ ${rota.destino}');
    print(
        '     ↳ Distância: ${rota.distanciaKm} km | Tempo Estimado: ${rota.tempoEstimadoMinutos} min');
  }

  print('\n📍 Pontos únicos atendidos na malha viária (Set):');
  print('   ${rotasService.obterPontosAtendidos()}');
  print(
      '\nDistância total da malha: ${rotasService.calcularDistanciaTotalAtiva()} km');
}

// =========================================================================
// OPÇÃO 3: TELEMETRIA EM TEMPO REAL
// =========================================================================
void _opcaoProcessarTelemetria(
  ServicoTelemetria telemetriaService,
  GerenciadorFrota frotaService,
) {
  print('## [3] PROCESSANDO TELEMETRIA DOS SENSORES EM TEMPO REAL\n');

  final v1 = frotaService.buscarPorId('VEI-001');
  final v2 = frotaService.buscarPorId('VEI-002');
  final v4 = frotaService.buscarPorId('VEI-004');

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
    bateria: 17.5,
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

  print('Processando telemetria ${v1.id}:');
  telemetriaService.processarLeitura(leitura1, v1);
  print('   GPS: (${leitura1.latitude}, ${leitura1.longitude})');
  print(
      '   Velocidade: ${v1.velocidadeAtual.toStringAsFixed(0)} km/h | Bateria: ${v1.nivelBateria.toStringAsFixed(1)}% | Status: ONLINE\n');

  print('Processando telemetria ${v2.id}:');
  telemetriaService.processarLeitura(leitura2, v2);
  print('   GPS: (${leitura2.latitude}, ${leitura2.longitude})');
  print(
      '   Velocidade: ${v2.velocidadeAtual.toStringAsFixed(0)} km/h | Bateria: ${v2.nivelBateria.toStringAsFixed(1)}% | Status: ONLINE\n');

  print('Processando telemetria ${v4.id}:');
  telemetriaService.processarLeitura(leitura4, v4);
  print('   GPS: (${leitura4.latitude}, ${leitura4.longitude})');
  print(
      '   Velocidade: ${v4.velocidadeAtual.toStringAsFixed(0)} km/h | Bateria: ${v4.nivelBateria.toStringAsFixed(1)}% | Status: ONLINE');
}

// =========================================================================
// OPÇÃO 4: MÉTODOS FUNCIONAIS DE COLEÇÕES (Dart 3)
// =========================================================================
void _opcaoMetodosFuncionais(
  GerenciadorFrota frotaService,
  GerenciadorRotas rotasService,
) {
  print('## [4] MÉTODOS FUNCIONAIS DE COLEÇÕES (Dart 3)\n');

  // .map()
  print('-- [14] Demonstração de .map() (Mapeamento de modelos):');
  final listaFormatadaModelos = frotaService.obterResumoModelos();
  for (final item in listaFormatadaModelos) {
    print('   • $item');
  }

  // .where()
  print(
      '\n-- [15] Demonstração de .where() (Filtros de conectados e bateria baixa):');
  final conectados = frotaService.obterVeiculosConectados();
  final bateriaBaixa = frotaService.obterVeiculosComBateriaBaixa(limite: 20.0);
  print(
      '   Veículos conectados (${conectados.length}): ${conectados.map((v) => v.id).toList()}');
  print(
      '   Veículos com bateria < 20% (${bateriaBaixa.length}): ${bateriaBaixa.map((v) => "${v.id} (${v.nivelBateria.toStringAsFixed(1)}%)").toList()}');

  // .fold()
  print('\n-- [16] Demonstração de .fold() (Cálculo acumulado):');
  final mediaBateria = frotaService.calcularMediaBateria();
  final mediaVelocidade = frotaService.calcularVelocidadeMedia();
  final totalDistanciaRotas = rotasService.calcularDistanciaTotalAtiva();
  print('   Média de Bateria da Frota: ${mediaBateria.toStringAsFixed(1)}%');
  print(
      '   Velocidade Média da Frota em Operação: ${mediaVelocidade.toStringAsFixed(1)} km/h');
  print(
      '   Extensão Total das Rotas Ativas: ${totalDistanciaRotas.toStringAsFixed(1)} km');

  // .any()
  print('\n-- [17] Demonstração de .any():');
  final temCritico = frotaService.existeVeiculoCritico(limiteCritico: 5.0);
  print('   Existe veículo em estado crítico (<= 5% bateria)? $temCritico');

  // .every()
  print('\n-- [18] Demonstração de .every():');
  final todosOperacionais =
      frotaService.todosAptosParaOperacao(limiteMinimo: 20.0);
  print(
      '   Todos os veículos estão 100% aptos para operação (online e bateria >= 20%)? $todosOperacionais');
}

// =========================================================================
// OPÇÃO 5: SPREAD OPERATOR, COLLECTION-IF E COLLECTION-FOR
// =========================================================================
void _opcaoColecoesAvancadas(GerenciadorFrota frotaService) {
  print('## [5] SPREAD OPERATOR (...), COLLECTION-IF E COLLECTION-FOR\n');

  // Spread Operator (...)
  final frotaCopia = [...frotaService.obterTodos()];
  print(
      'Spread Operator (...): Lista de ${frotaCopia.length} veículos clonada com sucesso.\n');

  // Collection-For, Collection-If e Null-Aware Spread (...?)
  print('Relatório gerado dinamicamente no painel:');
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
}

// =========================================================================
// OPÇÃO 6: EXCEÇÕES & AUDITORIA
// =========================================================================
void _opcaoExcecoesAuditoria(
  ServicoTelemetria telemetriaService,
  GerenciadorFrota frotaService,
) {
  print('## [6] SIMULAÇÃO DE SITUAÇÕES CRÍTICAS, EXCEÇÕES E AUDITORIA\n');

  final v3 = frotaService.buscarPorId('VEI-003');

  // Perda de conectividade
  print('-- [24/25] Simulação: Perda de Conectividade de Sensor');
  final leituraDesconectado = LeituraTelemetria(
    veiculoId: 'VEI-003',
    latitude: -20.6910,
    longitude: -41.3190,
    velocidade: 0.0,
    bateria: 40.0,
    conectado: false,
  );
  telemetriaService.processarLeitura(leituraDesconectado, v3);

  // Bateria Crítica com try/on/catch/finally e rethrow
  print(
      '\n-- [22/23] Simulação: Bateria Crítica (<= 5%) com try-on-catch-finally e rethrow');
  final leituraCritica = LeituraTelemetria(
    veiculoId: 'VEI-003',
    latitude: -20.6950,
    longitude: -41.3250,
    velocidade: 20.0,
    bateria: 3.5,
    conectado: true,
  );

  try {
    print('Tentando processar ciclo crítico para ${v3.id}...');
    telemetriaService.processarComAuditoria(leituraCritica, v3);
  } on RecursoCriticoException catch (e) {
    print('   [TRATAMENTO NA CLI - on RecursoCriticoException]');
    print('   Exceção interceptada no ponto de entrada: $e');
    print(
        '   Ação tomada: Acionando guincho e notificando central de operações!');
  } on DadosTelemetriaInvalidosException catch (e) {
    print('   [TRATAMENTO NA CLI - on DadosTelemetriaInvalidosException]: $e');
  } catch (e, stackTrace) {
    print('   [TRATAMENTO GENÉRICO]: $e\n$stackTrace');
  } finally {
    print(
        '   [BLOCO FINALLY DA CLI]: Ciclo de contenção de emergência concluído com segurança.\n');
  }

  // Validação de dados inválidos
  print(
      '-- [26] Demonstração: Validação de Dados Inválidos (DadosTelemetriaInvalidosException)');
  try {
    print('Tentando criar leitura com latitude impossível (150.0°)...');
    LeituraTelemetria(
      veiculoId: 'VEI-001',
      latitude: 150.0,
      longitude: -41.0,
      velocidade: 50.0,
      bateria: 80.0,
    );
  } on DadosTelemetriaInvalidosException catch (e) {
    print('   [SUCESSO NA PROTEÇÃO]: Exceção disparada corretamente: $e');
  }
}

// =========================================================================
// OPÇÃO 7: SOUND NULL SAFETY
// =========================================================================
void _opcaoSoundNullSafety(GerenciadorFrota frotaService) {
  print('## [7] DEMONSTRAÇÃO COMPLEMENTAR DE SOUND NULL SAFETY\n');

  // 1. Variável anulável T?
  String? rotaOpcional;
  print('1. Variável anulável (T?): $rotaOpcional');

  // 2. Operador ??=
  rotaOpcional ??= 'ROTA-RESERVA-URBANA';
  print('2. Valor após operador ??=: $rotaOpcional');

  // 3. Operadores ?. e ??
  final Veiculo? veiculoConsultado = frotaService.buscarPorIdOuNull('VEI-001');
  final idRotaSegura =
      veiculoConsultado?.rotaAtualId ?? 'Nenhuma rota vinculada';
  print(
      '3. Operadores ?. e ??: Veículo ${veiculoConsultado?.id} -> $idRotaSegura');

  final Veiculo? veiculoInexistente = frotaService.buscarPorIdOuNull('VEI-999');
  final rotaInexistente = veiculoInexistente?.rotaAtualId ??
      'Veículo não encontrado (Fallback seguro)';
  print(
      '4. Acesso seguro a veículo nulo (?.) com fallback (??): $rotaInexistente');
}

// =========================================================================
// OPÇÃO 8: RELATÓRIO CONSOLIDADO
// =========================================================================
void _opcaoRelatorioConsolidado(
  GerenciadorFrota frotaService,
  GerenciadorRotas rotasService,
) {
  print('========================================');
  print('        RELATÓRIO CONSOLIDADO DA FROTA  ');
  print('========================================');
  print('Total de Veículos Cadastrados: ${frotaService.totalVeiculos}');
  print(
      'Total de Veículos Conectados:   ${frotaService.obterVeiculosConectados().length}');
  print('Total de Rotas Cadastradas:     ${rotasService.totalRotas}');
  print(
      'Bateria Média da Frota:         ${frotaService.calcularMediaBateria().toStringAsFixed(1)}%');
  print(
      'Velocidade Média em Trânsito:   ${frotaService.calcularVelocidadeMedia().toStringAsFixed(1)} km/h');
  print(
      'Veículos em Estado Crítico:     ${frotaService.existeVeiculoCritico() ? "SIM (Atenção imediata)" : "NÃO (Frota estável)"}');
  print('========================================');
}

// =========================================================================
// OPÇÃO 9: SIMULAÇÃO COMPLETA
// =========================================================================
void _opcaoExecutarSimulacaoCompleta(
  GerenciadorFrota frotaService,
  GerenciadorRotas rotasService,
  ServicoTelemetria telemetriaService,
) {
  print('🚀 EXECUTANDO TODAS AS ETAPAS EM SEQUÊNCIA...\n');
  _opcaoCadastrarVeiculos(frotaService);
  print('\n----------------------------------------\n');
  _opcaoCadastrarRotas(rotasService);
  print('\n----------------------------------------\n');
  _opcaoProcessarTelemetria(telemetriaService, frotaService);
  print('\n----------------------------------------\n');
  _opcaoMetodosFuncionais(frotaService, rotasService);
  print('\n----------------------------------------\n');
  _opcaoColecoesAvancadas(frotaService);
  print('\n----------------------------------------\n');
  _opcaoExcecoesAuditoria(telemetriaService, frotaService);
  print('\n----------------------------------------\n');
  _opcaoSoundNullSafety(frotaService);
  print('\n----------------------------------------\n');
  _opcaoRelatorioConsolidado(frotaService, rotasService);
}
