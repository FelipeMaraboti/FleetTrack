import 'package:fleet_track/exceptions/telemetria_exceptions.dart';
import 'package:fleet_track/models/carro_combustao.dart';
import 'package:fleet_track/models/carro_eletrico.dart';
import 'package:fleet_track/models/leitura_telemetria.dart';
import 'package:fleet_track/models/rota.dart';
import 'package:fleet_track/services/gerenciador_frota.dart';
import 'package:fleet_track/services/servico_telemetria.dart';
import 'package:test/test.dart';

void main() {
  group('1. Validação de Bateria e Encapsulamento', () {
    test('Deve permitir atribuir bateria válida entre 0 e 100', () {
      final carro = CarroEletrico(
        id: 'TEST-01',
        modelo: 'Test Car',
        nivelBateria: 50.0,
      );
      expect(carro.nivelBateria, equals(50.0));

      carro.nivelBateria = 75.0;
      expect(carro.nivelBateria, equals(75.0));
    });

    test('Deve lançar DadosTelemetriaInvalidosException para bateria menor que 0 ou maior que 100', () {
      final carro = CarroEletrico(
        id: 'TEST-02',
        modelo: 'Test Car',
        nivelBateria: 80.0,
      );

      expect(
        () => carro.nivelBateria = -5.0,
        throwsA(isA<DadosTelemetriaInvalidosException>()),
      );

      expect(
        () => carro.nivelBateria = 105.0,
        throwsA(isA<DadosTelemetriaInvalidosException>()),
      );
    });
  });

  group('2. Construtores Factory e Nomeado', () {
    test('CarroEletrico.fromMap deve instanciar corretamente a partir de um Map', () {
      final mapa = {
        'id': 'EV-99',
        'modelo': 'Tesla Model 3',
        'bateria': 90.0,
        'capacidadeBateriaKwh': 75.0,
        'conectado': true,
      };

      final carro = CarroEletrico.fromMap(mapa);
      expect(carro.id, equals('EV-99'));
      expect(carro.modelo, equals('Tesla Model 3'));
      expect(carro.nivelBateria, equals(90.0));
      expect(carro.capacidadeBateriaKwh, equals(75.0));
      expect(carro.conectado, isTrue);
    });

    test('CarroEletrico.economico deve criar veículo com configuração otimizada', () {
      final carro = CarroEletrico.economico(id: 'ECO-01', modelo: 'Leaf');
      expect(carro.capacidadeBateriaKwh, equals(45.0));
      expect(carro.modelo, contains('[ECO]'));
    });

    test('CarroEletrico.fromMap deve lançar exceção se campos obrigatórios faltarem', () {
      final mapaInvalido = {'bateria': 50.0};
      expect(
        () => CarroEletrico.fromMap(mapaInvalido),
        throwsA(isA<DadosTelemetriaInvalidosException>()),
      );
    });
  });

  group('3. Regras Críticas de Telemetria e Exceções', () {
    test('ServicoTelemetria deve lançar RecursoCriticoException para bateria <= 5%', () {
      final servico = ServicoTelemetria();
      final carro = CarroEletrico(id: 'EV-01', modelo: 'Zoe', nivelBateria: 50.0);

      final leituraCritica = LeituraTelemetria(
        veiculoId: 'EV-01',
        latitude: -20.0,
        longitude: -41.0,
        velocidade: 30.0,
        bateria: 4.5,
        conectado: true,
      );

      expect(
        () => servico.processarLeitura(leituraCritica, carro),
        throwsA(isA<RecursoCriticoException>()),
      );
    });

    test('LeituraTelemetria deve validar limites de GPS e velocidade', () {
      expect(
        () => LeituraTelemetria(
          veiculoId: 'EV-01',
          latitude: 95.0, // Inválido (> 90)
          longitude: -40.0,
          velocidade: 50.0,
          bateria: 50.0,
        ),
        throwsA(isA<DadosTelemetriaInvalidosException>()),
      );

      expect(
        () => LeituraTelemetria(
          veiculoId: 'EV-01',
          latitude: -20.0,
          longitude: -40.0,
          velocidade: -10.0, // Inválido (< 0)
          bateria: 50.0,
        ),
        throwsA(isA<DadosTelemetriaInvalidosException>()),
      );
    });
  });

  group('4. Métodos Funcionais e Cálculos da Frota', () {
    test('calcularMediaBateria e calcularVelocidadeMedia com fold()', () {
      final frota = GerenciadorFrota();
      final v1 = CarroEletrico(id: 'V1', modelo: 'Carro 1', nivelBateria: 80.0, velocidadeAtual: 40.0, conectado: true);
      final v2 = CarroCombustao(id: 'V2', modelo: 'Carro 2', nivelBateria: 40.0, velocidadeAtual: 60.0, conectado: true);

      frota.cadastrar(v1);
      frota.cadastrar(v2);

      expect(frota.calcularMediaBateria(), equals(60.0));
      expect(frota.calcularVelocidadeMedia(), equals(50.0));
    });

    test('where, any e every no gerenciamento de frota', () {
      final frota = GerenciadorFrota();
      final v1 = CarroEletrico(id: 'V1', modelo: 'Carro 1', nivelBateria: 90.0, conectado: true);
      final v2 = CarroCombustao(id: 'V2', modelo: 'Carro 2', nivelBateria: 15.0, conectado: true);

      frota.cadastrar(v1);
      frota.cadastrar(v2);

      expect(frota.obterVeiculosComBateriaBaixa(limite: 20.0).length, equals(1));
      expect(frota.existeVeiculoCritico(limiteCritico: 5.0), isFalse);
      expect(frota.todosAptosParaOperacao(limiteMinimo: 20.0), isFalse);
    });
  });

  group('5. Polimorfismo e Processamento de Carga', () {
    test('CarroEletrico e CarroCombustao devem processar consumo com regras polimórficas', () {
      final ev = CarroEletrico(id: 'EV-1', modelo: 'Bolt', nivelBateria: 100.0, capacidadeBateriaKwh: 60.0);
      final combustao = CarroCombustao(id: 'ICE-1', modelo: 'Onix', nivelBateria: 100.0, nivelCombustivelLitros: 40.0);

      ev.processarCargaTrabalho(2.0);
      combustao.processarCargaTrabalho(2.0);

      expect(ev.nivelBateria, lessThan(100.0));
      expect(combustao.nivelCombustivelLitros, lessThan(40.0));
    });
  });

  group('6. Rotas e Cálculos de Distância', () {
    test('Rota deve calcular velocidade média e validar dados', () {
      final rota = Rota(
        id: 'R1',
        origem: 'A',
        destino: 'B',
        distanciaKm: 60.0,
        tempoEstimadoMinutos: 60.0,
      );

      expect(rota.calcularVelocidadeMedia(), equals(60.0));
      rota.desativar();
      expect(rota.ativa, isFalse);
    });
  });
}
