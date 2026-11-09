import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../exceptions/telemetria_exceptions.dart';
import '../models/condicao_clima.dart';
import '../models/leitura_telemetria.dart';
import '../models/rota.dart';

/// Fonte de dados remota da frota (API REST).
///
/// Endpoint padrão: JSONPlaceholder (https://jsonplaceholder.typicode.com),
/// que simula POST (201) e DELETE (200) sem persistir de fato.
class FleetApiDatasource {
  static final Uri endpointPadrao = Uri.parse('https://jsonplaceholder.typicode.com');

  final http.Client _client;
  final Uri _baseUrl;
  final Duration timeout;

  FleetApiDatasource({
    required http.Client client,
    Uri? baseUrl,
    this.timeout = const Duration(seconds: 8),
  })  : _client = client,
        _baseUrl = baseUrl ?? endpointPadrao;

  static const _headers = {'Content-Type': 'application/json; charset=UTF-8'};

  Uri get _recurso => _baseUrl.replace(path: '/posts');

  /// POST de uma rota criada/editada offline (upsert).
  Future<void> enviarRota(Rota rota) async {
    final resposta = await _executar(
      () => _client.post(_recurso, headers: _headers, body: rota.toJson()),
    );
    _validarStatus(resposta, 'envio da rota ${rota.id}');
  }

  /// DELETE de um registro excluído localmente.
  Future<void> excluir(String id) async {
    final uri = _baseUrl.replace(path: '/posts/${Uri.encodeComponent(id)}');
    final resposta = await _executar(() => _client.delete(uri, headers: _headers));
    _validarStatus(resposta, 'exclusão do registro $id');
  }

  /// POST de um lote de leituras de telemetria. Retorna o id gerado pela API.
  Future<Object?> enviarLoteLeituras(List<LeituraTelemetria> leituras) async {
    final corpo = jsonEncode({
      'tipo': 'lote_telemetria',
      'quantidade': leituras.length,
      'leituras': leituras.map((l) => l.toApiMap()).toList(),
    });
    final resposta = await _executar(
      () => _client.post(_recurso, headers: _headers, body: corpo),
    );
    _validarStatus(resposta, 'envio do lote de telemetria');
    final json = jsonDecode(resposta.body);
    return json is Map<String, dynamic> ? json['id'] : null;
  }

  /// Converte falhas de baixo nível em [RedeIndisponivelException].
  Future<http.Response> _executar(Future<http.Response> Function() requisicao) async {
    try {
      return await requisicao().timeout(timeout);
    } on TimeoutException {
      throw RedeIndisponivelException('Tempo limite de ${timeout.inSeconds}s excedido.');
    } on SocketException catch (e) {
      throw RedeIndisponivelException('Sem conexão: ${e.message}');
    } on http.ClientException catch (e) {
      throw RedeIndisponivelException('Falha de rede: ${e.message}');
    }
  }

  void _validarStatus(http.Response resposta, String contexto) {
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw SincronizacaoException(
        'API recusou $contexto',
        statusCode: resposta.statusCode,
      );
    }
  }
}

/// Fonte de dados remota de clima - API pública Open-Meteo (GET, sem chave).
class ClimaApiDatasource {
  final http.Client _client;
  final Duration timeout;

  ClimaApiDatasource({
    required http.Client client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client;

  Future<CondicaoClima> buscarClimaAtual(double latitude, double longitude) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'current_weather': 'true',
    });

    final http.Response resposta;
    try {
      resposta = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw RedeIndisponivelException('Open-Meteo não respondeu a tempo.');
    } on SocketException catch (e) {
      throw RedeIndisponivelException('Sem conexão: ${e.message}');
    } on http.ClientException catch (e) {
      throw RedeIndisponivelException('Falha de rede: ${e.message}');
    }

    if (resposta.statusCode != 200) {
      throw SincronizacaoException('Falha ao consultar clima', statusCode: resposta.statusCode);
    }
    return CondicaoClima.fromJson(jsonDecode(resposta.body) as Map<String, dynamic>);
  }
}
