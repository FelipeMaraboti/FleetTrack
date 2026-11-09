import '../exceptions/telemetria_exceptions.dart';

/// Condição climática atual no ponto GPS de um veículo (API Open-Meteo).
class CondicaoClima {
  final double temperatura;
  final double ventoKmh;
  final int codigo;
  final DateTime horario;

  /// `true` quando o valor veio do cache local (sem rede).
  final bool doCache;

  const CondicaoClima({
    required this.temperatura,
    required this.ventoKmh,
    required this.codigo,
    required this.horario,
    this.doCache = false,
  });

  /// Converte o JSON da Open-Meteo (`current_weather`) ou do cache local.
  factory CondicaoClima.fromJson(Map<String, dynamic> json, {bool doCache = false}) {
    final atual = json['current_weather'];
    if (atual is! Map<String, dynamic>) {
      throw SincronizacaoException('Resposta de clima sem "current_weather".');
    }
    final temp = atual['temperature'];
    final vento = atual['windspeed'];
    if (temp is! num || vento is! num) {
      throw SincronizacaoException('Resposta de clima com campos inválidos.');
    }
    return CondicaoClima(
      temperatura: temp.toDouble(),
      ventoKmh: vento.toDouble(),
      codigo: (atual['weathercode'] as num?)?.toInt() ?? 0,
      horario: DateTime.tryParse(atual['time']?.toString() ?? '') ?? DateTime.now(),
      doCache: doCache,
    );
  }

  Map<String, dynamic> toJson() => {
        'current_weather': {
          'temperature': temperatura,
          'windspeed': ventoKmh,
          'weathercode': codigo,
          'time': horario.toIso8601String(),
        },
      };

  /// Descrição simplificada dos códigos WMO usados pela Open-Meteo.
  String get descricao {
    if (codigo == 0) return 'Céu limpo';
    if (codigo <= 3) return 'Parcialmente nublado';
    if (codigo <= 48) return 'Neblina';
    if (codigo <= 67) return 'Chuva';
    if (codigo <= 77) return 'Neve';
    if (codigo <= 82) return 'Pancadas de chuva';
    return 'Tempestade';
  }
}
