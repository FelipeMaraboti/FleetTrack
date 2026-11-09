import 'package:shared_preferences/shared_preferences.dart';

import 'local_datasources.dart';

/// Implementação de [PreferenciasDatasource] com shared_preferences.
/// A instância é carregada uma vez no startup, permitindo leituras síncronas.
class SharedPrefsDatasource implements PreferenciasDatasource {
  static const _kUltimaSync = 'ultima_sincronizacao';
  static const _kModoOffline = 'modo_offline_simulado';
  static const _kCachePrefixo = 'cache_';

  final SharedPreferences _prefs;
  SharedPrefsDatasource(this._prefs);

  static Future<SharedPrefsDatasource> carregar() async {
    return SharedPrefsDatasource(await SharedPreferences.getInstance());
  }

  @override
  DateTime? get ultimaSincronizacao {
    final valor = _prefs.getString(_kUltimaSync);
    return valor == null ? null : DateTime.tryParse(valor);
  }

  @override
  Future<void> salvarUltimaSincronizacao(DateTime dataHora) =>
      _prefs.setString(_kUltimaSync, dataHora.toIso8601String());

  @override
  bool get modoOfflineSimulado => _prefs.getBool(_kModoOffline) ?? false;

  @override
  Future<void> salvarModoOfflineSimulado(bool valor) =>
      _prefs.setBool(_kModoOffline, valor);

  @override
  String? lerCache(String chave) => _prefs.getString('$_kCachePrefixo$chave');

  @override
  Future<void> salvarCache(String chave, String valor) =>
      _prefs.setString('$_kCachePrefixo$chave', valor);
}

/// Implementação em memória (usada nos testes e como fallback).
class MemoriaPreferenciasDatasource implements PreferenciasDatasource {
  DateTime? _ultimaSync;
  bool _offline;
  final Map<String, String> _cache = {};

  MemoriaPreferenciasDatasource({bool modoOffline = false}) : _offline = modoOffline;

  @override
  DateTime? get ultimaSincronizacao => _ultimaSync;

  @override
  Future<void> salvarUltimaSincronizacao(DateTime dataHora) async => _ultimaSync = dataHora;

  @override
  bool get modoOfflineSimulado => _offline;

  @override
  Future<void> salvarModoOfflineSimulado(bool valor) async => _offline = valor;

  @override
  String? lerCache(String chave) => _cache[chave];

  @override
  Future<void> salvarCache(String chave, String valor) async => _cache[chave] = valor;
}
