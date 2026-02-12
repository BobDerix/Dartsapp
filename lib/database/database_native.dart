import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/player.dart';
import '../models/game_session.dart';
import '../models/challenge_result.dart';
import 'database_interface.dart';

PlatformDatabase createDatabase() => NativeDatabase();

class NativeDatabase implements PlatformDatabase {
  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dartsapp.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        games_played INTEGER DEFAULT 0,
        games_won INTEGER DEFAULT 0,
        total_challenges_attempted INTEGER DEFAULT 0,
        total_challenges_hit INTEGER DEFAULT 0,
        best_streak INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE game_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player1_id INTEGER NOT NULL,
        player2_id INTEGER,
        target_score INTEGER NOT NULL,
        focus_area TEXT DEFAULT 'all',
        is_single_player INTEGER DEFAULT 0,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        winner_id INTEGER,
        player1_final_score INTEGER DEFAULT 0,
        player2_final_score INTEGER DEFAULT 0,
        total_rounds INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE challenge_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_session_id INTEGER NOT NULL,
        round_number INTEGER NOT NULL,
        challenge_text TEXT NOT NULL,
        challenge_category TEXT NOT NULL,
        challenge_type TEXT NOT NULL,
        player_id INTEGER NOT NULL,
        hit INTEGER NOT NULL,
        score INTEGER,
        points_awarded INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<int> insertPlayer(Player player) async {
    final db = await database;
    return await db.insert('players', player.toMap());
  }

  @override
  Future<Player?> getPlayer(int id) async {
    final db = await database;
    final maps = await db.query('players', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Player.fromMap(maps.first);
  }

  @override
  Future<Player?> getPlayerByName(String name) async {
    final db = await database;
    final maps = await db.query('players', where: 'LOWER(name) = LOWER(?)', whereArgs: [name]);
    if (maps.isEmpty) return null;
    return Player.fromMap(maps.first);
  }

  @override
  Future<List<Player>> getAllPlayers() async {
    final db = await database;
    final maps = await db.query('players', orderBy: 'name ASC');
    return maps.map((m) => Player.fromMap(m)).toList();
  }

  @override
  Future<void> updatePlayer(Player player) async {
    final db = await database;
    await db.update('players', player.toMap(), where: 'id = ?', whereArgs: [player.id]);
  }

  @override
  Future<void> deletePlayer(int id) async {
    final db = await database;
    await db.delete('players', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> insertGameSession(GameSession session) async {
    final db = await database;
    return await db.insert('game_sessions', session.toMap());
  }

  @override
  Future<void> updateGameSession(GameSession session) async {
    final db = await database;
    await db.update('game_sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  @override
  Future<List<GameSession>> getRecentGames({int limit = 20}) async {
    final db = await database;
    final maps = await db.query('game_sessions', where: 'ended_at IS NOT NULL', orderBy: 'ended_at DESC', limit: limit);
    return maps.map((m) => GameSession.fromMap(m)).toList();
  }

  @override
  Future<List<GameSession>> getPlayerGames(int playerId, {int limit = 20}) async {
    final db = await database;
    final maps = await db.query('game_sessions', where: '(player1_id = ? OR player2_id = ?) AND ended_at IS NOT NULL', whereArgs: [playerId, playerId], orderBy: 'ended_at DESC', limit: limit);
    return maps.map((m) => GameSession.fromMap(m)).toList();
  }

  @override
  Future<void> insertChallengeResult(ChallengeResult result) async {
    final db = await database;
    await db.insert('challenge_results', result.toMap());
  }

  @override
  Future<void> insertChallengeResults(List<ChallengeResult> results) async {
    final db = await database;
    final batch = db.batch();
    for (final result in results) {
      batch.insert('challenge_results', result.toMap());
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<ChallengeResult>> getGameResults(int gameSessionId) async {
    final db = await database;
    final maps = await db.query('challenge_results', where: 'game_session_id = ?', whereArgs: [gameSessionId], orderBy: 'round_number ASC');
    return maps.map((m) => ChallengeResult.fromMap(m)).toList();
  }

  @override
  Future<Map<String, Map<String, int>>> getPlayerCategoryStats(int playerId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT challenge_category, COUNT(*) as attempts,
        SUM(CASE WHEN hit = 1 THEN 1 ELSE 0 END) as hits
      FROM challenge_results WHERE player_id = ? GROUP BY challenge_category
    ''', [playerId]);
    final stats = <String, Map<String, int>>{};
    for (final row in maps) {
      stats[row['challenge_category'] as String] = {
        'attempts': row['attempts'] as int,
        'hits': row['hits'] as int,
      };
    }
    return stats;
  }

  @override
  Future<Map<String, int>> getHeadToHead(int player1Id, int player2Id) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT winner_id, COUNT(*) as wins FROM game_sessions
      WHERE ((player1_id = ? AND player2_id = ?) OR (player1_id = ? AND player2_id = ?))
        AND ended_at IS NOT NULL AND winner_id IS NOT NULL
      GROUP BY winner_id
    ''', [player1Id, player2Id, player2Id, player1Id]);
    final result = <String, int>{'p1Wins': 0, 'p2Wins': 0};
    for (final row in maps) {
      final winnerId = row['winner_id'] as int;
      final wins = row['wins'] as int;
      if (winnerId == player1Id) {
        result['p1Wins'] = wins;
      } else if (winnerId == player2Id) {
        result['p2Wins'] = wins;
      }
    }
    return result;
  }
}
