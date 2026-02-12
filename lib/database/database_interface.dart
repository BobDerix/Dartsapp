import '../models/player.dart';
import '../models/game_session.dart';
import '../models/challenge_result.dart';

abstract class PlatformDatabase {
  Future<int> insertPlayer(Player player);
  Future<Player?> getPlayer(int id);
  Future<Player?> getPlayerByName(String name);
  Future<List<Player>> getAllPlayers();
  Future<void> updatePlayer(Player player);
  Future<void> deletePlayer(int id);
  Future<int> insertGameSession(GameSession session);
  Future<void> updateGameSession(GameSession session);
  Future<List<GameSession>> getRecentGames({int limit = 20});
  Future<List<GameSession>> getPlayerGames(int playerId, {int limit = 20});
  Future<void> insertChallengeResult(ChallengeResult result);
  Future<void> insertChallengeResults(List<ChallengeResult> results);
  Future<List<ChallengeResult>> getGameResults(int gameSessionId);
  Future<Map<String, Map<String, int>>> getPlayerCategoryStats(int playerId);
  Future<Map<String, int>> getHeadToHead(int player1Id, int player2Id);
}
