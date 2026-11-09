import 'dart:convert';

import '../exceptions/telemetria_exceptions.dart';

/// Representa um snapshot de leitura de telemetria emitido pelos sensores do veículo.
///
/// AP2B: a leitura é persistida no SQLite (tabela `leituras`), relacionada a
/// uma [Rota] via `rotaId` (chave estrangeira opcional) e sincronizada em
/// lotes com a API REST.
class LeituraTelemetria {
  final String id;
  final String veiculoId;
  final String? rotaId;
  final double latitude;
  final double longitude;
  final double velocidade;
  final double bateria;
  final DateTime timestamp;
  final bool conectado;
  final bool sincronizado;
  final bool excluido;

  /// Construtor gerativo com validação completa de limites físicos.
  LeituraTelemetria({
    String? id,
    required this.veiculoId,
    this.rotaId,
    required this.latitude,
    required this.longitude,
    required this.velocidade,
    required this.bateria,
    DateTime? timestamp,
    this.conectado = true,
    this.sincronizado = false,
    this.excluido = false,
  })  : timestamp = timestamp ?? DateTime.now(),
        id = id ??
            'LEI-${(timestamp ?? DateTime.now()).microsecondsSinceEpoch}' {
    if (latitude < -90.0 || latitude > 90.0) {
      throw DadosTelemetriaInvalidosException(
        'Latitude fora dos limites válidos [-90, +90]: $latitude',
      );
    }

    if (longitude < -180.0 || longitude > 180.0) {
      throw DadosTelemetriaInvalidosException(
        'Longitude fora dos limites válidos [-180, +180]: $longitude',
      );
    }

    if (velocidade < 0.0) {
      throw DadosTelemetriaInvalidosException(
        'Velocidade não pode ser negativa: $velocidade km/h',
      );
    }

    if (bateria < 0.0 || bateria > 100.0) {
      throw DadosTelemetriaInvalidosException(
        'Bateria fora da faixa válida [0, 100]: $bateria%',
      );
    }
  }

  /// Construtor factory seguro para desserialização de dados recebidos via
  /// telemetria, SQLite (snake_case) ou payload legado da AP1B (camelCase).
  factory LeituraTelemetria.fromMap(Map<String, dynamic> map) {
    final rawVeiculoId = map['veiculo_id'] ?? map['veiculoId'];
    if (rawVeiculoId == null ||
        rawVeiculoId is! String ||
        rawVeiculoId.isEmpty) {
      throw DadosTelemetriaInvalidosException(
        'Leitura inválida: "veiculoId" ausente ou inválido.',
      );
    }

    final rawLat = map['latitude'];
    final rawLng = map['longitude'];
    final rawVel = map['velocidade'];
    final rawBat = map['bateria'];

    if (rawLat is! num || rawLng is! num || rawVel is! num || rawBat is! num) {
      throw DadosTelemetriaInvalidosException(
        'Leitura inválida: Campos numéricos (latitude, longitude, velocidade, bateria) obrigatórios.',
      );
    }

    final rawTimestamp = map['timestamp'];
    DateTime? parsedTimestamp;
    if (rawTimestamp is String) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp);
    }

    return LeituraTelemetria(
      id: map['id']?.toString(),
      veiculoId: rawVeiculoId,
      rotaId: (map['rota_id'] ?? map['rotaId']) as String?,
      latitude: rawLat.toDouble(),
      longitude: rawLng.toDouble(),
      velocidade: rawVel.toDouble(),
      bateria: rawBat.toDouble(),
      timestamp: parsedTimestamp,
      conectado: _lerBool(map['conectado'], padrao: true),
      sincronizado: _lerBool(map['sincronizado'], padrao: false),
      excluido: _lerBool(map['excluido'], padrao: false),
    );
  }

  /// Cria uma cópia atualizando o estado de sincronização / exclusão.
  LeituraTelemetria copyWith({bool? sincronizado, bool? excluido}) {
    return LeituraTelemetria(
      id: id,
      veiculoId: veiculoId,
      rotaId: rotaId,
      latitude: latitude,
      longitude: longitude,
      velocidade: velocidade,
      bateria: bateria,
      timestamp: timestamp,
      conectado: conectado,
      sincronizado: sincronizado ?? this.sincronizado,
      excluido: excluido ?? this.excluido,
    );
  }

  /// Converte para Map compatível com SQLite (bool -> 0/1).
  Map<String, dynamic> toMap() => {
        'id': id,
        'veiculo_id': veiculoId,
        'rota_id': rotaId,
        'latitude': latitude,
        'longitude': longitude,
        'velocidade': velocidade,
        'bateria': bateria,
        'timestamp': timestamp.toIso8601String(),
        'conectado': conectado ? 1 : 0,
        'sincronizado': sincronizado ? 1 : 0,
        'excluido': excluido ? 1 : 0,
      };

  /// Map enviado à API (sem os marcadores internos de sincronização).
  Map<String, dynamic> toApiMap() => toMap()
    ..remove('sincronizado')
    ..remove('excluido')
    ..['conectado'] = conectado;

  String toJson() => jsonEncode(toApiMap());

  static bool _lerBool(Object? valor, {required bool padrao}) {
    if (valor is bool) return valor;
    if (valor is num) return valor == 1;
    return padrao;
  }

  @override
  String toString() {
    final status = conectado ? 'ONLINE' : 'OFFLINE';
    return 'Leitura[$veiculoId | GPS: (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}) | '
        'Vel: ${velocidade.toStringAsFixed(1)} km/h | Bat: ${bateria.toStringAsFixed(1)}% | Status: $status]';
  }
}
