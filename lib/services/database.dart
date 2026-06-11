import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hospital.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        email TEXT UNIQUE,
        senha TEXT,
        matricula TEXT,
        cargo TEXT,
        departamento TEXT, 
        registro TEXT, 
        hospital TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE itens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        categoria TEXT NOT NULL,
        quantidade_atual INTEGER NOT NULL DEFAULT 0,
        quantidade_minima INTEGER NOT NULL DEFAULT 0,
        quantidade_maxima INTEGER NOT NULL DEFAULT 0,
        quantidade_recomendada_ia INTEGER,
        local_armazenamento TEXT,
        unidade_medida TEXT NOT NULL DEFAULT 'un',
        data_validade TEXT,
        lote TEXT,
        fornecedor_id INTEGER,
        tipo TEXT NOT NULL DEFAULT 'primordial',
        -- tipo: 'primordial' | 'essencial_baixa_demanda'
        status TEXT NOT NULL DEFAULT 'normal',
        -- status: 'normal' | 'atencao' | 'critico'
        ultima_atualizacao TEXT NOT NULL,
        historico_consumo TEXT DEFAULT '[]'
        -- JSON: lista de consumo diário dos últimos 30 dias
      )
    ''');

    await db.execute('''
      CREATE TABLE fornecedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cnpj TEXT,
        contato TEXT,
        score_confiabilidade INTEGER DEFAULT 100,
        historico_atrasos INTEGER DEFAULT 0,
        ativo INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE pedidos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL,
        fornecedor_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pendente',
        -- pendente | em_rota | atrasado | entregue | cancelado
        data_pedido TEXT NOT NULL,
        data_eta TEXT,
        data_entrega TEXT,
        valor_total REAL,
        itens TEXT NOT NULL DEFAULT '[]',
        -- JSON: [{item_id, quantidade, valor_unitario}]
        sla_horas INTEGER DEFAULT 48,
        motivo_atraso TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE alertas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        -- estoque_critico | validade | atraso_entrega | fraude | catastrofe | ia
        titulo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        item_id INTEGER,
        pedido_id INTEGER,
        prioridade TEXT NOT NULL DEFAULT 'atencao',
        -- critico | atencao | info
        status TEXT NOT NULL DEFAULT 'ativo',
        -- ativo | resolvido | ignorado
        data_criacao TEXT NOT NULL,
        data_resolucao TEXT,
        acao_tomada TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE eventos_risco (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        status TEXT NOT NULL DEFAULT 'ativo',
        -- ativo | resolvido
        prejuizo_real REAL DEFAULT 0,
        prejuizo_projetado_sem_ia REAL DEFAULT 0,
        pacientes_afetados INTEGER DEFAULT 0,
        acoes_executadas TEXT DEFAULT '[]',
        relatorio_ia TEXT
        -- JSON com o relatório gerado pela IA pós-evento
      )
    ''');

    await db.execute('''
      CREATE TABLE hospitais_parceiros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cidade TEXT,
        latitude REAL,
        longitude REAL,
        contato TEXT,
        ativo INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE transferencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_origem_id INTEGER NOT NULL,
        hospital_destino_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantidade INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pendente',
        -- pendente | aprovada | em_transito | concluida | recusada
        urgencia TEXT NOT NULL DEFAULT 'moderada',
        sugerida_por_ia INTEGER DEFAULT 1,
        data_criacao TEXT NOT NULL,
        data_conclusao TEXT,
        justificativa TEXT
      )
    ''');

  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final dbClient = await database;
    return await dbClient.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
      String table, {
        String? where,
        List<dynamic>? whereArgs,
        String? orderBy,
        int? limit,
      }) async {
    final dbClient = await database;
    return await dbClient.query(table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit);
  }

  Future<int> update(
      String table,
      Map<String, dynamic> data, {
        required String where,
        required List<dynamic> whereArgs,
      }) async {
    final dbClient = await database;
    return await dbClient.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
      String table, {
        required String where,
        required List<dynamic> whereArgs,
      }) async {
    final dbClient = await database;
    return await dbClient.delete(table, where: where, whereArgs: whereArgs);
  }
}