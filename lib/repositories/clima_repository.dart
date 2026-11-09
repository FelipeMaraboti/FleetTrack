import 'dart:convert';

import '../datasources/remote_datasources.dart';
import '../exceptions/telemetria_exceptions.dart';
import '../models/condicao_clima.dart';
import 'repositorio_base.dart';

/// Consulta o clima no ponto GPS (GET Open-Meteo) com cache local para
/// funcionamento sem rede.
class ClimaRepository extends RepositorioBase {
  final ClimaApiDatasource _api;

  ClimaRepository({
    required ClimaApiDatasource api,
    required super.preferencias,
    required super.logs,
  }) : _api = api;

  static String chaveCache(double lat, double lng) =>
      'clima_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}';

  /// Busca na API; se estiver offline, devolve o último valor em cache.
  /// Sem cache disponível, a [RedeIndisponivelException] é propagada.
  Future<CondicaoClima> obterClima(double latitude, double longitude) async {
    final chave = chaveCache(latitude, longitude);
    try {
      garantirOnline();
      final clima = await _api.buscarClimaAtual(latitude, longitude);
      await preferencias.salvarCache(chave, jsonEncode(clima.toJson()));
      await registrarHistorico(entidade: 'CLIMA', operacao: 'GET', sucesso: true, mensagem: 'Clima atualizado ($chave).');
      return clima;
    } on RedeIndisponivelException {
      final cache = preferencias.lerCache(chave);
      if (cache != null) {
        return CondicaoClima.fromJson(jsonDecode(cache) as Map<String, dynamic>, doCache: true);
      }
      rethrow;
    }
  }
}
