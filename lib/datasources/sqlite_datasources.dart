import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/leitura_telemetria.dart';
import '../models/log_sincronizacao.dart';
import '../models/rota.dart';
import 'local_datasources.dart';

/// Responsável por abrir o banco SQLite e criar o esquema relacional.
///
/// Tabelas:
///  * `rotas`              - entidade principal
///  * `leituras`           - leituras de telemetria (FK opcional -> rotas.id)
///  * `logs_sincronizacao` - histórico de tentativas de envio para a API
class DatabaseHelper {
  static const _nomeBanco = 'fleet_track.db';
  static const _versao = 1;

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _abrir();
  }

  Future<Database> _abrir() async {
    final caminho = p.join(await getDatabasesPath(), _nomeBanco);
    return openDatabase(
      caminho,
      version: _versao,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _criarTabelas,
    );
  }

  Future<void> _criarTabelas(Database db, int versao) async {
    await db.execute('''
      CREATE TABLE rotas (
        id TEXT PRIMARY KEY,
        origem TEXT NOT NULL,
        destino TEXT NOT NULL,
        distancia_km REAL NOT NULL,
        tempo_estimado_min REAL NOT NULL,
        ativa INTEGER NOT NULL DEFAULT 1,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        excluido INTEGER NOT NULL DEFAULT 0,
        atualizado_em TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE leituras (
        id TEXT PRIMARY KEY,
        veiculo_id TEXT NOT NULL,
        rota_id TEXT REFERENCES rotas(id) ON DELETE SET NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        velocidade REAL NOT NULL,
        bateria REAL NOT NULL,
        timestamp TEXT NOT NULL,
        conectado INTEGER NOT NULL DEFAULT 1,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        excluido INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE logs_sincronizacao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_hora TEXT NOT NULL,
        entidade TEXT NOT NULL,
        operacao TEXT NOT NULL,
        sucesso INTEGER NOT NULL,
        mensagem TEXT NOT NULL
      )
    ''');

    // Carga inicial: rotas da AP1B já consideradas sincronizadas (catálogo base).
    final rotasIniciais = [
      Rota(id: 'ROTA-001', origem: 'Terminal Rodoviário', destino: 'Aeroporto Internacional', distanciaKm: 28.5, tempoEstimadoMinutos: 35, sincronizado: true),
      Rota(id: 'ROTA-002', origem: 'Centro Urbano', destino: 'Campus Universitário', distanciaKm: 14.0, tempoEstimadoMinutos: 25, sincronizado: true),
      Rota(id: 'ROTA-003', origem: 'Polo Industrial', destino: 'Porto Seco', distanciaKm: 42.0, tempoEstimadoMinutos: 50, sincronizado: true),
    ];
    for (final rota in rotasIniciais) {
      await db.insert('rotas', rota.toMap());
    }
  }
}

/// DAO de rotas (CRUD: insert / query / update / delete).
class SqliteRotaDatasource implements RotaLocalDatasource {
  final DatabaseHelper _helper;
  SqliteRotaDatasource(this._helper);

  @override
  Future<void> salvarOuAtualizar(Rota rota) async {
    final db = await _helper.database;
    final atualizadas = await db.update(
      'rotas',
      rota.toMap(),
      where: 'id = ?',
      whereArgs: [rota.id],
    );
    if (atualizadas == 0) {
      await db.insert('rotas', rota.toMap());
    }
  }

  @override
  Future<List<Rota>> listarTodas() async {
    final db = await _helper.database;
    final linhas = await db.query('rotas', where: 'excluido = 0', orderBy: 'id');
    return linhas.map(Rota.fromMap).toList();
  }

  @override
  Future<Rota?> buscarPorId(String id) async {
    final db = await _helper.database;
    final linhas = await db.query('rotas', where: 'id = ?', whereArgs: [id], limit: 1);
    return linhas.isEmpty ? null : Rota.fromMap(linhas.first);
  }

  @override
  Future<List<Rota>> listarPendentes() async {
    final db = await _helper.database;
    final linhas = await db.query('rotas', where: 'sincronizado = 0');
    return linhas.map(Rota.fromMap).toList();
  }

  @override
  Future<void> removerPorId(String id) async {
    final db = await _helper.database;
    await db.delete('rotas', where: 'id = ?', whereArgs: [id]);
  }
}

/// DAO de leituras de telemetria.
class SqliteLeituraDatasource implements LeituraLocalDatasource {
  final DatabaseHelper _helper;
  SqliteLeituraDatasource(this._helper);

  @override
  Future<void> salvarOuAtualizar(LeituraTelemetria leitura) async {
    final db = await _helper.database;
    await db.insert(
      'leituras',
      leitura.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<LeituraTelemetria>> listarTodas() async {
    final db = await _helper.database;
    final linhas = await db.query('leituras', where: 'excluido = 0', orderBy: 'timestamp DESC');
    return linhas.map(LeituraTelemetria.fromMap).toList();
  }

  @override
  Future<List<LeituraTelemetria>> listarPorRota(String rotaId) async {
    final db = await _helper.database;
    final linhas = await db.query(
      'leituras',
      where: 'rota_id = ? AND excluido = 0',
      whereArgs: [rotaId],
      orderBy: 'timestamp DESC',
    );
    return linhas.map(LeituraTelemetria.fromMap).toList();
  }

  @override
  Future<List<LeituraTelemetria>> listarPendentes() async {
    final db = await _helper.database;
    final linhas = await db.query('leituras', where: 'sincronizado = 0');
    return linhas.map(LeituraTelemetria.fromMap).toList();
  }

  @override
  Future<void> removerPorId(String id) async {
    final db = await _helper.database;
    await db.delete('leituras', where: 'id = ?', whereArgs: [id]);
  }
}

/// DAO do histórico de sincronização.
class SqliteLogDatasource implements LogLocalDatasource {
  final DatabaseHelper _helper;
  SqliteLogDatasource(this._helper);

  @override
  Future<void> registrar(LogSincronizacao log) async {
    final db = await _helper.database;
    await db.insert('logs_sincronizacao', log.toMap());
  }

  @override
  Future<List<LogSincronizacao>> listarRecentes({int limite = 50}) async {
    final db = await _helper.database;
    final linhas = await db.query('logs_sincronizacao', orderBy: 'id DESC', limit: limite);
    return linhas.map(LogSincronizacao.fromMap).toList();
  }

  @override
  Future<void> limpar() async {
    final db = await _helper.database;
    await db.delete('logs_sincronizacao');
  }
}
