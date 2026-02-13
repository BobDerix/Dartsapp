import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/player.dart';
import '../models/challenge.dart';
import '../models/chaos_card.dart';
import '../models/game_session.dart';
import '../models/challenge_result.dart';
import '../database/database_helper.dart';
import '../services/challenge_service.dart';
import '../services/chaos_card_service.dart';
import '../services/commentary_service.dart';
import '../services/audio_service.dart';

/// Per-player in-game state (not persisted directly).
class PlayerState {
  int score = 0;
  int attempts = 0;
  int hits = 0;
  int streak = 0;

  // Current challenge input
  bool? hitMissChoice; // true=hit, false=miss, null=not chosen
  int? scoreEntry; // for bestScore/threshold
  int eliminationLives = 3;
  int eliminationHits = 0;
  bool eliminationDone = false;

  // Auction state
  int? auctionBid; // number of darts bid (1-6)

  // Progressive state
  int progressiveRound = 0; // which sub-round we're on
  bool progressiveFailed = false; // has this player failed?

  void reset() {
    hitMissChoice = null;
    scoreEntry = null;
    eliminationLives = 3;
    eliminationHits = 0;
    eliminationDone = false;
    auctionBid = null;
    progressiveRound = 0;
    progressiveFailed = false;
  }

  Map<String, dynamic> toJson() => {
    'score': score,
    'attempts': attempts,
    'hits': hits,
    'streak': streak,
  };

  void fromJson(Map<String, dynamic> json) {
    score = json['score'] as int;
    attempts = json['attempts'] as int;
    hits = json['hits'] as int;
    streak = json['streak'] as int;
  }
}

enum GamePhase { setup, playing, finished }

/// Auction sub-phases.
enum AuctionPhase { bidding, executing }

/// Controls all game logic. Used with Provider.
class GameState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final ChallengeService _challengeService = ChallengeService();
  final ChaosCardService _chaosCardService = ChaosCardService();
  final CommentaryService _commentary = CommentaryService();
  final AudioService _audio = AudioService();

  // Game config
  Player? player1;
  Player? player2;
  int targetScore = 10;
  String focusArea = 'all';
  bool isSinglePlayer = false;

  // Runtime state
  GamePhase phase = GamePhase.setup;
  PlayerState p1State = PlayerState();
  PlayerState p2State = PlayerState();
  Challenge? currentChallenge;
  int roundNumber = 0;
  int? judgeWinner; // 0=p1, 1=p2, null=not decided (for closest type)
  bool roundComplete = false;

  // Chaos card state
  ChaosCard? activeChaosCard;
  bool showingChaosCard = false; // true during the reveal animation

  // Commentary state
  String? commentaryText; // current commentary text to display
  bool showCommentary = false;

  // Auction state
  AuctionPhase auctionPhase = AuctionPhase.bidding;
  int? auctionWinnerIdx; // 0=p1, 1=p2

  // Progressive state
  int progressiveTarget = 0; // current target to beat
  int progressiveTurn = 0; // 0=p1's turn, 1=p2's turn
  bool progressiveResolved = false;

  // DB tracking
  GameSession? _currentSession;
  final List<ChallengeResult> _pendingResults = [];

  // Undo history
  final List<String> _history = [];
  static const _maxHistory = 10;

  // Winner info (for winner screen)
  Player? winner;

  double get p1HitRate => p1State.attempts > 0 ? p1State.hits / p1State.attempts : 0;
  double get p2HitRate => p2State.attempts > 0 ? p2State.hits / p2State.attempts : 0;

  /// Start a new game.
  Future<void> startGame({
    required String p1Name,
    String? p2Name,
    required int target,
  }) async {
    player1 = await _db.getOrCreatePlayer(p1Name);
    if (p2Name != null && p2Name.isNotEmpty) {
      player2 = await _db.getOrCreatePlayer(p2Name);
      isSinglePlayer = false;
    } else {
      player2 = null;
      isSinglePlayer = true;
    }

    targetScore = target;
    focusArea = 'all';

    p1State = PlayerState();
    p2State = PlayerState();
    roundNumber = 0;
    winner = null;
    activeChaosCard = null;
    showingChaosCard = false;
    commentaryText = null;
    showCommentary = false;
    _history.clear();
    _pendingResults.clear();
    _chaosCardService.reset();

    // Create DB session
    _currentSession = GameSession(
      player1Id: player1!.id!,
      player2Id: player2?.id,
      targetScore: target,
      focusArea: focusArea,
      isSinglePlayer: isSinglePlayer,
    );
    final sessionId = await _db.insertGameSession(_currentSession!);
    _currentSession = GameSession(
      id: sessionId,
      player1Id: player1!.id!,
      player2Id: player2?.id,
      targetScore: target,
      focusArea: focusArea,
      isSinglePlayer: isSinglePlayer,
    );

    phase = GamePhase.playing;
    nextChallenge();
  }

  /// Save current state to undo history.
  void _saveHistory() {
    _history.add(jsonEncode({
      'p1': p1State.toJson(),
      'p2': p2State.toJson(),
      'round': roundNumber,
    }));
    if (_history.length > _maxHistory) _history.removeAt(0);
  }

  /// Undo the last completed round.
  void undo() {
    if (_history.isEmpty) return;
    final prev = jsonDecode(_history.removeLast()) as Map<String, dynamic>;
    p1State.fromJson(prev['p1'] as Map<String, dynamic>);
    p2State.fromJson(prev['p2'] as Map<String, dynamic>);
    roundNumber = prev['round'] as int;
    roundComplete = false;
    p1State.reset();
    p2State.reset();
    judgeWinner = null;
    activeChaosCard = null;
    showingChaosCard = false;
    commentaryText = null;
    showCommentary = false;
    // Re-generate a challenge (can't restore exact previous one, but close enough)
    nextChallenge(isUndo: true);
  }

  /// Show a commentary message that auto-hides.
  void _showCommentary(String text) {
    commentaryText = text;
    showCommentary = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      if (commentaryText == text) {
        showCommentary = false;
        notifyListeners();
      }
    });
  }

  /// Dismiss chaos card reveal and continue.
  void dismissChaosCard() {
    showingChaosCard = false;
    notifyListeners();
  }

  /// Generate next challenge.
  void nextChallenge({bool forceSuddenDeath = false, bool isUndo = false}) {
    if (!isUndo) {
      p1State.reset();
      p2State.reset();
    }
    judgeWinner = null;
    roundComplete = false;
    auctionPhase = AuctionPhase.bidding;
    auctionWinnerIdx = null;
    progressiveTarget = 0;
    progressiveTurn = 0;
    progressiveResolved = false;

    if (forceSuddenDeath) {
      currentChallenge = _challengeService.suddenDeath();
    } else {
      currentChallenge = _challengeService.generate(
        focusArea: focusArea,
        isTwoPlayer: !isSinglePlayer,
        lastChallenge: currentChallenge,
      );
    }

    // Set elimination lives
    if (currentChallenge!.type == ChallengeType.elimination) {
      p1State.eliminationLives = currentChallenge!.subRounds;
      p2State.eliminationLives = currentChallenge!.subRounds;
    }

    roundNumber++;

    // Check for chaos card (not on undo, not on sudden death)
    if (!isUndo && !forceSuddenDeath) {
      activeChaosCard = _chaosCardService.maybeDrawCard(
        roundNumber: roundNumber,
        isTwoPlayer: !isSinglePlayer,
      );
      if (activeChaosCard != null) {
        showingChaosCard = true;
        _audio.chaosCard();
      }
    } else if (isUndo) {
      activeChaosCard = null;
    }

    // Occasional commentary on round start
    if (!isUndo && activeChaosCard == null && roundNumber > 1) {
      if (roundNumber % 5 == 0) {
        _showCommentary(_commentary.onRoundStart());
      }
    }

    notifyListeners();
  }

  // ── Input Handlers ──

  /// Handle hit/miss input for a player (type: hitMiss, countdown).
  void setHitMiss(int playerIdx, bool isHit) {
    if (roundComplete) return;
    final ps = playerIdx == 0 ? p1State : p2State;
    if (ps.hitMissChoice != null) return; // Already chosen

    ps.hitMissChoice = isHit;
    _audio.tap();
    _checkRoundReady();
    notifyListeners();
  }

  /// Handle score entry for a player (type: bestScore, threshold).
  void setScore(int playerIdx, int score) {
    if (roundComplete) return;
    final ps = playerIdx == 0 ? p1State : p2State;
    ps.scoreEntry = score;
    _checkRoundReady();
    notifyListeners();
  }

  /// Handle judge decision (type: closest). 0=p1, 1=p2.
  void setJudgeWinner(int winnerIdx) {
    if (roundComplete) return;
    judgeWinner = winnerIdx;
    _resolveRound();
  }

  /// Handle elimination sub-round hit/miss.
  void setEliminationHit(int playerIdx, bool isHit) {
    final ps = playerIdx == 0 ? p1State : p2State;
    if (ps.eliminationDone) return;

    if (isHit) {
      ps.eliminationHits++;
      _audio.hit();
    } else {
      ps.eliminationLives--;
      _audio.miss();
    }

    if (ps.eliminationLives <= 0) {
      ps.eliminationDone = true;
    }

    // Check max sub-rounds reached
    final totalThrows = ps.eliminationHits + (currentChallenge!.subRounds - ps.eliminationLives);
    if (totalThrows >= currentChallenge!.subRounds) {
      ps.eliminationDone = true;
    }

    // Check if all players are done - show result first, don't auto-advance
    final otherPs = playerIdx == 0 ? p2State : p1State;
    if (isSinglePlayer) {
      if (ps.eliminationDone) {
        roundComplete = true;
      }
    } else if (ps.eliminationDone && otherPs.eliminationDone) {
      roundComplete = true;
    }

    notifyListeners();
  }

  /// Handle auction bid.
  void setAuctionBid(int playerIdx, int bid) {
    if (auctionPhase != AuctionPhase.bidding) return;
    final ps = playerIdx == 0 ? p1State : p2State;
    ps.auctionBid = bid;
    _audio.tap();

    // Check if both players have bid
    if (p1State.auctionBid != null && p2State.auctionBid != null) {
      // Lower bid wins (fewer darts = more confident)
      if (p1State.auctionBid! <= p2State.auctionBid!) {
        auctionWinnerIdx = 0;
      } else {
        auctionWinnerIdx = 1;
      }
      auctionPhase = AuctionPhase.executing;
    }
    notifyListeners();
  }

  /// Handle auction execution result (hit/miss by the bidding winner).
  void setAuctionResult(bool isHit) {
    if (auctionPhase != AuctionPhase.executing) return;
    final winnerPs = auctionWinnerIdx == 0 ? p1State : p2State;
    winnerPs.hitMissChoice = isHit;
    roundComplete = true;
    notifyListeners();
  }

  /// Handle progressive score entry.
  void setProgressiveScore(int playerIdx, int score) {
    if (progressiveResolved) return;
    final ps = playerIdx == 0 ? p1State : p2State;

    if (progressiveTurn == 0 && playerIdx == 0 && p1State.scoreEntry == null) {
      // P1's first throw
      ps.scoreEntry = score;
      progressiveTarget = score;
      progressiveTurn = 1;
      _audio.tap();
      notifyListeners();
    } else if (progressiveTurn == 1 && playerIdx == 1 && p2State.scoreEntry == null) {
      // P2 must beat P1's score
      ps.scoreEntry = score;
      if (score > progressiveTarget) {
        // P2 beats it -> P2 wins
        progressiveResolved = true;
        roundComplete = true;
      } else {
        // P2 fails -> P1 wins
        progressiveResolved = true;
        roundComplete = true;
      }
      _audio.tap();
      notifyListeners();
    }
  }

  void _checkRoundReady() {
    final type = currentChallenge!.type;

    if (type == ChallengeType.hitMiss || type == ChallengeType.countdown) {
      final p1Ready = p1State.hitMissChoice != null;
      final p2Ready = isSinglePlayer || p2State.hitMissChoice != null;
      if (p1Ready && p2Ready) {
        roundComplete = true;
        notifyListeners();
      }
    } else if (type == ChallengeType.bestScore || type == ChallengeType.threshold) {
      final p1Ready = p1State.scoreEntry != null;
      final p2Ready = isSinglePlayer || p2State.scoreEntry != null;
      if (p1Ready && p2Ready) {
        roundComplete = true;
        notifyListeners();
      }
    }
  }

  /// Confirm and resolve the current round. Called when user taps "NEXT".
  void confirmRound() {
    if (!roundComplete && currentChallenge!.type != ChallengeType.closest) return;
    if (currentChallenge!.type == ChallengeType.elimination) {
      _resolveElimination();
    } else if (currentChallenge!.type == ChallengeType.auction) {
      _resolveAuction();
    } else if (currentChallenge!.type == ChallengeType.progressive) {
      _resolveProgressive();
    } else {
      _resolveRound();
    }
  }

  void _resolveRound() {
    _saveHistory();

    final type = currentChallenge!.type;
    int p1Points = 0;
    int p2Points = 0;
    bool p1Hit = false;
    bool p2Hit = false;

    switch (type) {
      case ChallengeType.hitMiss:
      case ChallengeType.countdown:
        p1Hit = p1State.hitMissChoice == true;
        p2Hit = !isSinglePlayer && p2State.hitMissChoice == true;
        if (p1Hit) p1Points = 1;
        if (p2Hit) p2Points = 1;
        break;

      case ChallengeType.threshold:
        final threshold = currentChallenge!.targetValue ?? 0;
        p1Hit = (p1State.scoreEntry ?? 0) >= threshold;
        p2Hit = !isSinglePlayer && (p2State.scoreEntry ?? 0) >= threshold;
        if (p1Hit) p1Points = 1;
        if (p2Hit) p2Points = 1;
        break;

      case ChallengeType.bestScore:
        final s1 = p1State.scoreEntry ?? 0;
        final s2 = p2State.scoreEntry ?? 0;
        if (s1 > s2) {
          p1Points = 1;
          p1Hit = true;
        } else if (s2 > s1) {
          p2Points = 1;
          p2Hit = true;
        }
        // Tie = no points
        break;

      case ChallengeType.closest:
        if (judgeWinner == 0) {
          p1Points = 1;
          p1Hit = true;
        } else if (judgeWinner == 1) {
          p2Points = 1;
          p2Hit = true;
        }
        break;

      case ChallengeType.elimination:
      case ChallengeType.auction:
      case ChallengeType.progressive:
        // Handled by their own methods
        return;
    }

    // Apply chaos card modifiers
    if (activeChaosCard != null) {
      final card = activeChaosCard!;
      final calc = _chaosCardService.calculatePoints(
        activeCard: card,
        isHit: p1Hit,
        isBidWinner: true,
      );
      if (p1Hit) {
        p1Points = calc.hitPts;
      } else {
        p1Points = calc.missPts;
      }

      if (!isSinglePlayer) {
        final calc2 = _chaosCardService.calculatePoints(
          activeCard: card,
          isHit: p2Hit,
          isBidWinner: true,
        );
        if (p2Hit) {
          p2Points = calc2.hitPts;
        } else {
          p2Points = calc2.missPts;
        }

        // Steal mechanic
        if (card.type == ChaosCardType.steal) {
          if (p1Hit && calc.stealPts > 0) {
            p2Points -= calc.stealPts;
          }
          if (p2Hit && calc2.stealPts > 0) {
            p1Points -= calc2.stealPts;
          }
        }
      }
    }

    // Commentary based on results
    _generateCommentary(p1Hit, p2Hit);

    _applyPoints(p1Points, p2Points, p1Hit, p2Hit);
  }

  void _resolveElimination() {
    _saveHistory();

    int p1Points = 0;
    int p2Points = 0;
    bool p1Hit = false;
    bool p2Hit = false;

    if (isSinglePlayer) {
      p1Hit = p1State.eliminationLives > 0;
      if (p1Hit) p1Points = 1;
    } else {
      // More lives remaining = winner
      if (p1State.eliminationLives > p2State.eliminationLives) {
        p1Points = 1;
        p1Hit = true;
      } else if (p2State.eliminationLives > p1State.eliminationLives) {
        p2Points = 1;
        p2Hit = true;
      } else {
        // Both same lives: compare hits
        if (p1State.eliminationHits > p2State.eliminationHits) {
          p1Points = 1;
          p1Hit = true;
        } else if (p2State.eliminationHits > p1State.eliminationHits) {
          p2Points = 1;
          p2Hit = true;
        }
        // Complete tie = no points
      }
    }

    _generateCommentary(p1Hit, p2Hit);
    _applyPoints(p1Points, p2Points, p1Hit, p2Hit);
  }

  void _resolveAuction() {
    _saveHistory();

    int p1Points = 0;
    int p2Points = 0;
    bool p1Hit = false;
    bool p2Hit = false;

    final winnerIdx = auctionWinnerIdx ?? 0;
    final winnerPs = winnerIdx == 0 ? p1State : p2State;
    final loserIdx = winnerIdx == 0 ? 1 : 0;
    final isHit = winnerPs.hitMissChoice == true;

    if (isHit) {
      // Bidder succeeded: 2 points
      if (winnerIdx == 0) {
        p1Points = 2;
        p1Hit = true;
      } else {
        p2Points = 2;
        p2Hit = true;
      }
      _showCommentary(_commentary.onCheckout(currentChallenge?.targetValue ?? 0));
    } else {
      // Bidder failed: opponent gets 1 point
      if (loserIdx == 0) {
        p1Points = 1;
        p1Hit = true;
      } else {
        p2Points = 1;
        p2Hit = true;
      }
      _showCommentary(_commentary.onMiss());
    }

    _applyPoints(p1Points, p2Points, p1Hit, p2Hit);
  }

  void _resolveProgressive() {
    _saveHistory();

    int p1Points = 0;
    int p2Points = 0;
    bool p1Hit = false;
    bool p2Hit = false;

    final s1 = p1State.scoreEntry ?? 0;
    final s2 = p2State.scoreEntry ?? 0;

    if (s2 > s1) {
      // P2 beat P1's score
      p2Points = 1;
      p2Hit = true;
    } else {
      // P2 couldn't beat it
      p1Points = 1;
      p1Hit = true;
    }

    _generateCommentary(p1Hit, p2Hit);
    _applyPoints(p1Points, p2Points, p1Hit, p2Hit);
  }

  void _generateCommentary(bool p1Hit, bool p2Hit) {
    // Score-specific commentary
    if (currentChallenge?.type == ChallengeType.bestScore ||
        currentChallenge?.type == ChallengeType.threshold) {
      final score = p1State.scoreEntry ?? p2State.scoreEntry ?? 0;
      final scoreComment = _commentary.onScore(score);
      if (scoreComment != null) {
        _showCommentary(scoreComment);
        if (score >= 140) _audio.bigScore();
        return;
      }
    }

    // Streak commentary
    if (p1Hit && p1State.streak >= 2) {
      _showCommentary(_commentary.onStreak(p1State.streak + 1));
      return;
    }
    if (p2Hit && p2State.streak >= 2) {
      _showCommentary(_commentary.onStreak(p2State.streak + 1));
      return;
    }

    // Checkout commentary
    if (currentChallenge?.type == ChallengeType.countdown && (p1Hit || p2Hit)) {
      _showCommentary(_commentary.onCheckout(currentChallenge?.targetValue ?? 0));
      return;
    }

    // General hit/miss
    if (p1Hit || p2Hit) {
      _showCommentary(_commentary.onHit());
    } else {
      _showCommentary(_commentary.onMiss());
    }
  }

  void _applyPoints(int p1Points, int p2Points, bool p1Hit, bool p2Hit) {
    p1State.score += p1Points;
    // Prevent negative scores
    if (p1State.score < 0) p1State.score = 0;
    p1State.attempts++;
    if (p1Hit) {
      p1State.hits++;
      p1State.streak++;
      if (p1State.streak >= 3) {
        _audio.streak();
      } else {
        _audio.hit();
      }
    } else {
      p1State.streak = 0;
      if (p1Points == 0) _audio.miss();
    }

    if (!isSinglePlayer) {
      p2State.score += p2Points;
      if (p2State.score < 0) p2State.score = 0;
      p2State.attempts++;
      if (p2Hit) {
        p2State.hits++;
        p2State.streak++;
      } else {
        p2State.streak = 0;
      }
    }

    // Record results
    if (_currentSession != null) {
      _pendingResults.add(ChallengeResult(
        gameSessionId: _currentSession!.id!,
        roundNumber: roundNumber,
        challengeText: currentChallenge!.text,
        challengeCategory: currentChallenge!.category.name,
        challengeType: currentChallenge!.type.dbValue,
        playerId: player1!.id!,
        hit: p1Hit,
        score: p1State.scoreEntry,
        pointsAwarded: p1Points,
      ));
      if (!isSinglePlayer && player2 != null) {
        _pendingResults.add(ChallengeResult(
          gameSessionId: _currentSession!.id!,
          roundNumber: roundNumber,
          challengeText: currentChallenge!.text,
          challengeCategory: currentChallenge!.category.name,
          challengeType: currentChallenge!.type.dbValue,
          playerId: player2!.id!,
          hit: p2Hit,
          score: p2State.scoreEntry,
          pointsAwarded: p2Points,
        ));
      }
    }

    // Clear chaos card after resolution
    activeChaosCard = null;

    // Check for win
    _checkWin();
  }

  void _checkWin() {
    final p1Win = p1State.score >= targetScore;
    final p2Win = !isSinglePlayer && p2State.score >= targetScore;

    if (p1Win || p2Win) {
      if (p1Win && p2Win && p1State.score == p2State.score) {
        // Sudden death
        nextChallenge(forceSuddenDeath: true);
        return;
      }

      if (isSinglePlayer && p1Win) {
        winner = player1;
      } else if (p1Win && (!p2Win || p1State.score > p2State.score)) {
        winner = player1;
      } else if (p2Win) {
        winner = player2;
      }

      if (winner != null) {
        _finishGame();
        return;
      }
    }

    // No winner yet, continue
    nextChallenge();
  }

  Future<void> _finishGame() async {
    phase = GamePhase.finished;
    _audio.win();

    // Update DB
    if (_currentSession != null) {
      _currentSession!.endedAt = DateTime.now();
      _currentSession!.winnerId = winner?.id;
      _currentSession!.player1FinalScore = p1State.score;
      _currentSession!.player2FinalScore = p2State.score;
      _currentSession!.totalRounds = roundNumber;
      await _db.updateGameSession(_currentSession!);
      await _db.insertChallengeResults(_pendingResults);
    }

    // Update player stats
    if (player1 != null) {
      player1 = await _db.getPlayer(player1!.id!);
      if (player1 != null) {
        player1!.gamesPlayed++;
        if (winner?.id == player1!.id) player1!.gamesWon++;
        player1!.totalChallengesAttempted += p1State.attempts;
        player1!.totalChallengesHit += p1State.hits;
        if (p1State.streak > player1!.bestStreak) {
          player1!.bestStreak = p1State.streak;
        }
        await _db.updatePlayer(player1!);
      }
    }
    if (player2 != null) {
      player2 = await _db.getPlayer(player2!.id!);
      if (player2 != null) {
        player2!.gamesPlayed++;
        if (winner?.id == player2!.id) player2!.gamesWon++;
        player2!.totalChallengesAttempted += p2State.attempts;
        player2!.totalChallengesHit += p2State.hits;
        if (p2State.streak > player2!.bestStreak) {
          player2!.bestStreak = p2State.streak;
        }
        await _db.updatePlayer(player2!);
      }
    }

    notifyListeners();
  }

  /// Quit the current game without recording a winner.
  Future<void> quitGame() async {
    if (_currentSession != null) {
      _currentSession!.endedAt = DateTime.now();
      _currentSession!.player1FinalScore = p1State.score;
      _currentSession!.player2FinalScore = p2State.score;
      _currentSession!.totalRounds = roundNumber;
      await _db.updateGameSession(_currentSession!);
    }
    phase = GamePhase.setup;
    notifyListeners();
  }

  /// Reset to setup phase for rematch.
  void backToSetup() {
    phase = GamePhase.setup;
    notifyListeners();
  }

  bool get canUndo => _history.isNotEmpty;
}
