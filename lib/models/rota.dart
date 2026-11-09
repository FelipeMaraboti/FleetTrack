import 'dart:convert';

import '../exceptions/telemetria_exceptions.dart';

/// Representa uma rota urbana planejada para os veículos da frota.
///
/// AP2B: a rota passou a ser uma entidade persistida no SQLite, com
/// marcadores de sincronização Offline-First (`sincronizado` e `excluido`)
/// e conversões `toMap()/fromMap()` + JSON.
class Rota {
  final String id;
  final String origem;
  final String destino;
  final double distanciaKm;
  final double tempoEstimadoMinutos;
  bool _ativa;

  /// `false` enquanto a alteração local ainda não foi enviada para a API.
  final bool sincronizado;

  /// Exclusão lógica (soft delete): a rota some da UI, mas permanece no banco
  /// até que o DELETE seja confirmado pela API.
  final bool excluido;

  /// Data/hora da última alteração local.
  final DateTime atualizadoEm;

  Rota({
    required this.id,
    required this.origem,
    required this.destino,
    required this.distanciaKm,
    required this.tempoEstimadoMinutos,
    bool ativa = true,
    this.sincronizado = false,
    this.excluido = false,
    DateTime? atualizadoEm,
  })  : _ativa = ativa,
        atualizadoEm = atualizadoEm ?? DateTime.now() {
    if (id.trim().isEmpty || origem.trim().isEmpty || destino.trim().isEmpty) {
      throw RotaInvalidaException(
        'Id, origem e destino da rota são obrigatórios e não podem ser vazios.',
      );
    }

    if (distanciaKm < 0.0) {
      throw RotaInvalidaException(
        'Distância da rota não pode ser negativa: $distanciaKm km',
      );
    }

    if (tempoEstimadoMinutos <= 0.0) {
      throw RotaInvalidaException(
        'Tempo estimado da rota deve ser positivo: $tempoEstimadoMinutos min',
      );
    }
  }

  /// Getter para verificação do status da rota.
  bool get ativa => _ativa;

  /// Ativa a rota para operação.
  void ativar() => _ativa = true;

  /// Desativa temporariamente a rota.
  void desativar() => _ativa = false;

  /// Calcula a velocidade média planejada da rota em km/h.
  double calcularVelocidadeMedia() {
    final horas = tempoEstimadoMinutos / 60.0;
    return distanciaKm / horas;
  }

  /// Cria uma cópia imutável alterando apenas os campos informados.
  Rota copyWith({
    String? origem,
    String? destino,
    double? distanciaKm,
    double? tempoEstimadoMinutos,
    bool? ativa,
    bool? sincronizado,
    bool? excluido,
    DateTime? atualizadoEm,
  }) {
    return Rota(
      id: id,
      origem: origem ?? this.origem,
      destino: destino ?? this.destino,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      tempoEstimadoMinutos: tempoEstimadoMinutos ?? this.tempoEstimadoMinutos,
      ativa: ativa ?? _ativa,
      sincronizado: sincronizado ?? this.sincronizado,
      excluido: excluido ?? this.excluido,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  /// Converte para Map compatível com SQLite (bool -> 0/1).
  Map<String, dynamic> toMap() => {
        'id': id,
        'origem': origem,
        'destino': destino,
        'distancia_km': distanciaKm,
        'tempo_estimado_min': tempoEstimadoMinutos,
        'ativa': _ativa ? 1 : 0,
        'sincronizado': sincronizado ? 1 : 0,
        'excluido': excluido ? 1 : 0,
        'atualizado_em': atualizadoEm.toIso8601String(),
      };

  /// Instancia a rota a partir de um registro do SQLite ou payload da API.
  factory Rota.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    if (rawId == null || rawId.toString().trim().isEmpty) {
      throw RotaInvalidaException('Rota sem "id" no Map recebido.');
    }
    final distancia = map['distancia_km'];
    final tempo = map['tempo_estimado_min'];
    if (distancia is! num || tempo is! num) {
      throw RotaInvalidaException(
        'Campos numéricos "distancia_km" e "tempo_estimado_min" são obrigatórios.',
      );
    }
    return Rota(
      id: rawId.toString(),
      origem: map['origem'] as String? ?? '',
      destino: map['destino'] as String? ?? '',
      distanciaKm: distancia.toDouble(),
      tempoEstimadoMinutos: tempo.toDouble(),
      ativa: _lerBool(map['ativa'], padrao: true),
      sincronizado: _lerBool(map['sincronizado'], padrao: false),
      excluido: _lerBool(map['excluido'], padrao: false),
      atualizadoEm: DateTime.tryParse(map['atualizado_em']?.toString() ?? ''),
    );
  }

  /// Payload JSON enviado para a API (sem os marcadores internos de sync).
  String toJson() {
    final mapa = toMap()
      ..remove('sincronizado')
      ..remove('excluido');
    return jsonEncode(mapa);
  }

  /// SQLite armazena booleanos como inteiros; a API pode enviar `true/false`.
  static bool _lerBool(Object? valor, {required bool padrao}) {
    if (valor is bool) return valor;
    if (valor is num) return valor == 1;
    return padrao;
  }

  @override
  String toString() {
    final status = _ativa ? 'ATIVA' : 'INATIVA';
    return '$id - $origem -> $destino (${distanciaKm.toStringAsFixed(1)} km, ${tempoEstimadoMinutos.toStringAsFixed(0)} min, $status)';
  }
}
