import '../exceptions/telemetria_exceptions.dart';

/// Representa um snapshot de leitura de telemetria emitido pelos sensores do veículo.
class LeituraTelemetria {
  final String veiculoId;
  final double latitude;
  final double longitude;
  final double velocidade;
  final double bateria;
  final DateTime timestamp;
  final bool conectado;

  /// Construtor gerativo com validação completa de limites físicos.
  LeituraTelemetria({
    required this.veiculoId,
    required this.latitude,
    required this.longitude,
    required this.velocidade,
    required this.bateria,
    DateTime? timestamp,
    this.conectado = true,
  }) : timestamp = timestamp ?? DateTime.now() {
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

  /// Construtor factory seguro para desserialização de dados recebidos via telemetria.
  factory LeituraTelemetria.fromMap(Map<String, dynamic> map) {
    final rawVeiculoId = map['veiculoId'];
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

    final bool conectado = (map['conectado'] is bool) ? map['conectado'] : true;

    return LeituraTelemetria(
      veiculoId: rawVeiculoId,
      latitude: rawLat.toDouble(),
      longitude: rawLng.toDouble(),
      velocidade: rawVel.toDouble(),
      bateria: rawBat.toDouble(),
      timestamp: parsedTimestamp,
      conectado: conectado,
    );
  }

  @override
  String toString() {
    final status = conectado ? 'ONLINE' : 'OFFLINE';
    return 'Leitura[$veiculoId | GPS: (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}) | '
        'Vel: ${velocidade.toStringAsFixed(1)} km/h | Bat: ${bateria.toStringAsFixed(1)}% | Status: $status]';
  }
}
