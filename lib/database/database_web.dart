import '../models/player.dart';
import '../models/game_session.dart';
import '../models/challenge_result.dart';
import 'database_interface.dart';

PlatformDatabase createDatabase() => WebDatabase();

/// In-memory database for web platform (sqflite is not available on web).
class WebDatabase implements PlatformDatabase {
  int _nextPlayerId = 1;
  int _nextSessionId = 1;
  int _nextResultId = 1;

  final List<Player> _players = [];
  final List<GameSession> _sessions = [];
  final List<ChallengeResult> _results = [];

  @override
  Future<int> insertPlayer(Player player) async {
    final id = _nextPlayerId++;
    _players.add(Player(
      id: id,
      name: player.name,
      createdAt: player.createdAt,
      gamesPlayed: player.gamesPlayed,
      gamesWon: player.gamesWon,
      totalChallengesAttempted: player.totalChallengesAttempted,
      totalChallengesHit: player.totalChallengesHit,
      bestStreak: player.bestStreak,
    ));
    return id;
  }

  @override
  Future<Player?> getPlayer(int id) async {
    try {
      return _players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Player?> getPlayerByName(String name) async {
    try {
      return _players.firstWhere(
          (p) => p.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Player>> getAllPlayers() async {
    final sorted = List<Player>.from(_players);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  @override
  Future<void> updatePlayer(Player player) async {
    final idx = _players.indexWhere((p) => p.id == player.id);
    if (idx >= 0) _players[idx] = player;
  }

  @override
  Future<void> deletePlayer(int id) async {
    _players.removeWhere((p) => p.id == id);
  }

  @override
  Future<int> insertGameSession(GameSession session) async {
    final id = _nextSessionId++;
    _sessions.add(GameSession(
      id: id,
      player1Id: session.player1Id,
      player2Id: session.player2Id,
      targetScore: session.targetScore,
      focusArea: session.focusArea,
      isSinglePlayer: session.isSinglePlayer,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      winnerId: session.winnerId,
      player1FinalScore: session.player1FinalScore,
      player2FinalScore: session.player2FinalScore,
      totalRounds: session.totalRounds,
    ));
    return id;
  }

  @override
  Future<void> updateGameSession(GameSession session) async {
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) _sessions[idx] = session;
  }

  @override
  Future<List<GameSession>> getRecentGames({int limit = 20}) async {
    final ended = _sessions.where((s) => s.endedAt != null).toList();
    ended.sort((a, b) => b.endedAt!.compareTo(a.endedAt!));
    return ended.take(limit).toList();
  }

  @override
  Future<List<GameSession>> getPlayerGames(int playerId,
      {int limit = 20}) async {
    final games = _sessions
        .where((s) =>
            (s.player1Id == playerId || s.player2Id == playerId) &&
            s.endedAt != null)
        .toList();
    games.sort((a, b) => b.endedAt!.compareTo(a.endedAt!));
    return games.take(limit).toList();
  }

  @override
  Future<void> insertChallengeResult(ChallengeResult result) async {
    _results.add(ChallengeResult(
      id: _nextResultId++,
      gameSessionId: result.gameSessionId,
      roundNumber: result.roundNumber,
      challengeText: result.challengeText,
      challengeCategory: result.challengeCategory,
      challengeType: result.challengeType,
      playerId: result.playerId,
      hit: result.hit,
      score: result.score,
      pointsAwarded: result.pointsAwarded,
    ));
  }

  @override
  Future<void> insertChallengeResults(List<ChallengeResult> results) async {
    for (final r in results) {
      await insertChallengeResult(r);
    }
  }

  @override
  Future<List<ChallengeResult>> getGameResults(int gameSessionId) async {
    final results =
        _results.where((r) => r.gameSessionId == gameSessionId).toList();
    results.sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    return results;
  }

  @override
  Future<Map<String, Map<String, int>>> getPlayerCategoryStats(
      int playerId) async {
    final playerResults = _results.where((r) => r.playerId == playerId);
    final stats = <String, Map<String, int>>{};
    for (final r in playerResults) {
      stats.putIfAbsent(
          r.challengeCategory, () => {'attempts': 0, 'hits': 0});
      stats[r.challengeCategory]!['attempts'] =
          stats[r.challengeCategory]!['attempts']! + 1;
      if (r.hit) {
        stats[r.challengeCategory]!['hits'] =
            stats[r.challengeCategory]!['hits']! + 1;
      }
    }
    return stats;
  }

  @override
  Future<Map<String, int>> getHeadToHead(int player1Id, int player2Id) async {
    final result = <String, int>{'p1Wins': 0, 'p2Wins': 0};
    for (final s in _sessions) {
      if (s.endedAt == null || s.winnerId == null) continue;
      final isMatch = (s.player1Id == player1Id && s.player2Id == player2Id) ||
          (s.player1Id == player2Id && s.player2Id == player1Id);
      if (!isMatch) continue;
      if (s.winnerId == player1Id) result['p1Wins'] = result['p1Wins']! + 1;
      if (s.winnerId == player2Id) result['p2Wins'] = result['p2Wins']! + 1;
    }
    return result;
  }
}
