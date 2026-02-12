import '../models/player.dart';
import '../models/game_session.dart';
import '../models/challenge_result.dart';
import 'database_interface.dart';

// Conditional import: use sqflite on native, in-memory on web
import 'database_native.dart' if (dart.library.html) 'database_web.dart'
    as platform_db;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  final PlatformDatabase _db = platform_db.createDatabase();

  // ── Player CRUD ──

  Future<int> insertPlayer(Player player) => _db.insertPlayer(player);
  Future<Player?> getPlayer(int id) => _db.getPlayer(id);
  Future<Player?> getPlayerByName(String name) => _db.getPlayerByName(name);
  Future<List<Player>> getAllPlayers() => _db.getAllPlayers();
  Future<void> updatePlayer(Player player) => _db.updatePlayer(player);
  Future<void> deletePlayer(int id) => _db.deletePlayer(id);

  Future<Player> getOrCreatePlayer(String name) async {
    var player = await getPlayerByName(name);
    if (player != null) return player;
    final id = await insertPlayer(Player(name: name));
    return Player(id: id, name: name);
  }

  // ── Game Session CRUD ──

  Future<int> insertGameSession(GameSession session) =>
      _db.insertGameSession(session);
  Future<void> updateGameSession(GameSession session) =>
      _db.updateGameSession(session);
  Future<List<GameSession>> getRecentGames({int limit = 20}) =>
      _db.getRecentGames(limit: limit);
  Future<List<GameSession>> getPlayerGames(int playerId, {int limit = 20}) =>
      _db.getPlayerGames(playerId, limit: limit);

  // ── Challenge Results ──

  Future<void> insertChallengeResult(ChallengeResult result) =>
      _db.insertChallengeResult(result);
  Future<void> insertChallengeResults(List<ChallengeResult> results) =>
      _db.insertChallengeResults(results);
  Future<List<ChallengeResult>> getGameResults(int gameSessionId) =>
      _db.getGameResults(gameSessionId);
  Future<Map<String, Map<String, int>>> getPlayerCategoryStats(int playerId) =>
      _db.getPlayerCategoryStats(playerId);
  Future<Map<String, int>> getHeadToHead(int player1Id, int player2Id) =>
      _db.getHeadToHead(player1Id, player2Id);
}
