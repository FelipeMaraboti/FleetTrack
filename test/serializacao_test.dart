import 'dart:convert';

import 'package:fleet_track/exceptions/telemetria_exceptions.dart';
import 'package:fleet_track/models/condicao_clima.dart';
import 'package:fleet_track/models/leitura_telemetria.dart';
import 'package:fleet_track/models/log_sincronizacao.dart';
import 'package:fleet_track/models/rota.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('7. Serialização da Rota (SQLite / JSON)', () {
    test('toMap/fromMap preserva todos os campos (ida e volta)', () {
      final original = rotaExemplo(sincronizado: true);
      final copia = Rota.fromMap(original.toMap());

      expect(copia.id, original.id);
      expect(copia.origem, original.origem);
      expect(copia.distanciaKm, original.distanciaKm);
      expect(copia.sincronizado, isTrue);
      expect(copia.atualizadoEm, original.atualizadoEm);
    });

    test('toMap converte booleanos para 0/1 (compatível com SQLite)', () {
      final mapa = rotaExemplo().copyWith(ativa: false).toMap();
      expect(mapa['ativa'], 0);
      expect(mapa['sincronizado'], 0);
      expect(mapa['excluido'], 0);
    });

    test('toJson não envia marcadores internos de sincronização', () {
      final json = jsonDecode(rotaExemplo().toJson()) as Map<String, dynamic>;
      expect(json.containsKey('sincronizado'), isFalse);
      expect(json.containsKey('excluido'), isFalse);
      expect(json['origem'], 'Centro');
    });

    test('fromMap sem campos numéricos lança RotaInvalidaException', () {
      expect(
        () => Rota.fromMap({'id': 'R1', 'origem': 'A', 'destino': 'B'}),
        throwsA(isA<RotaInvalidaException>()),
      );
    });

    test('copyWith altera apenas os campos informados', () {
      final rota = rotaExemplo();
      final editada = rota.copyWith(sincronizado: true, destino: 'Porto');
      expect(editada.id, rota.id);
      expect(editada.origem, rota.origem);
      expect(editada.destino, 'Porto');
      expect(editada.sincronizado, isTrue);
    });

    test('construtor rejeita distância negativa', () {
      expect(
        () => Rota(id: 'R', origem: 'A', destino: 'B', distanciaKm: -1, tempoEstimadoMinutos: 10),
        throwsA(isA<RotaInvalidaException>()),
      );
    });
  });

  group('8. Serialização da LeituraTelemetria', () {
    test('toMap/fromMap preserva rotaId, timestamp e status', () {
      final original = leituraExemplo(rotaId: 'ROTA-001').copyWith(sincronizado: true);
      final copia = LeituraTelemetria.fromMap(original.toMap());

      expect(copia.id, original.id);
      expect(copia.rotaId, 'ROTA-001');
      expect(copia.timestamp, original.timestamp);
      expect(copia.sincronizado, isTrue);
      expect(copia.conectado, isTrue);
    });

    test('fromMap aceita o formato legado camelCase da AP1B', () {
      final leitura = LeituraTelemetria.fromMap({
        'veiculoId': 'VEI-009',
        'latitude': -20.0,
        'longitude': -40.0,
        'velocidade': 10,
        'bateria': 55,
        'conectado': false,
      });
      expect(leitura.veiculoId, 'VEI-009');
      expect(leitura.conectado, isFalse);
      expect(leitura.sincronizado, isFalse);
    });

    test('toApiMap envia conectado como bool e omite sincronizado', () {
      final api = leituraExemplo().toApiMap();
      expect(api['conectado'], isTrue);
      expect(api.containsKey('sincronizado'), isFalse);
    });

    test('fromMap com bateria fora da faixa lança DadosTelemetriaInvalidosException', () {
      final mapa = leituraExemplo().toMap()..['bateria'] = 150;
      expect(() => LeituraTelemetria.fromMap(mapa), throwsA(isA<DadosTelemetriaInvalidosException>()));
    });
  });

  group('9. Outros modelos', () {
    test('LogSincronizacao converte para Map e volta', () {
      final log = LogSincronizacao(entidade: 'ROTA', operacao: 'POST', sucesso: true, mensagem: 'ok');
      final copia = LogSincronizacao.fromMap({...log.toMap(), 'id': 7});
      expect(copia.id, 7);
      expect(copia.sucesso, isTrue);
      expect(copia.entidade, 'ROTA');
    });

    test('CondicaoClima interpreta o JSON da Open-Meteo', () {
      final clima = CondicaoClima.fromJson({
        'current_weather': {'temperature': 27.4, 'windspeed': 11.2, 'weathercode': 0, 'time': '2026-11-09T10:00'},
      });
      expect(clima.temperatura, 27.4);
      expect(clima.descricao, 'Céu limpo');
      expect(clima.doCache, isFalse);
    });

    test('CondicaoClima com payload inválido lança SincronizacaoException', () {
      expect(() => CondicaoClima.fromJson({'erro': true}), throwsA(isA<SincronizacaoException>()));
    });
  });
}
