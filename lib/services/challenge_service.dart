import 'dart:math';
import '../models/challenge.dart';

class ChallengeService {
  final _random = Random();
  final List<int> _segments = List.generate(20, (i) => i + 1);

  // Bogey checkouts (impossible to finish on a double with 3 darts)
  static const _bogeyCheckouts = {159, 162, 163, 165, 166, 168, 169};

  /// Master list of static challenges.
  final List<Challenge> _staticChallenges = const [
    // ── PRECISION (Hit/Miss) ──
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🐂', text: 'Hit Bull (25 or 50)', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🎯', text: 'Hit Double Bull (50)', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🔝', text: 'Hit Tops (Double 20)', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '👇', text: 'Hit D3 (Bottom of the board)', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🧱', text: 'Hit D14 (The Mensur)', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🍜', text: 'Shanghai! (S, T, D of same number)', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '2️⃣', text: 'All 3 darts in EVEN numbers', difficulty: 2),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '1️⃣', text: 'All 3 darts in ODD numbers', difficulty: 2),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🎪', text: 'Hit 3 different doubles', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🔺', text: 'Hit 3 different triples', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🎨', text: 'Hit all 3 colours (red, green, white/black)', difficulty: 2),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🏠', text: 'All 3 darts in the same number', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🪜', text: 'Hit 3 consecutive numbers (e.g. 18-19-20)', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '😈', text: 'Hit T19 (the wrong bed!)', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🟡', text: 'Hit the outer Bull (25)', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '⬅️', text: 'Left side only! (1-10 half)', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '📐', text: 'All 3 darts in the big singles', difficulty: 2),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🎰', text: 'Hit S20, D20 and T20', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🔄', text: 'Around the board: hit 3 different areas (top, left, right)', difficulty: 2),

    // ── NEW PRECISION: Darts culture classics (G) ──
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '💄', text: 'The Lipstick! Hit T20, T18 or T19', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🏝️', text: 'The Coast! Round the board: hit as many consecutive numbers from 1 upward in 3 darts', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🏠', text: 'Madhouse! Check out on D1', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🛤️', text: 'The Railway! All 3 darts between the two wires of a double', difficulty: 4),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🪶', text: 'Feather Touch! All 3 darts in the thin inner single', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🍀', text: 'Lucky 7s! Hit S7, D7 or T7', difficulty: 3),
    Challenge(category: ChallengeCategory.precision, type: ChallengeType.hitMiss, emoji: '🧲', text: 'Magnet! All 3 darts touching each other in the board', difficulty: 3),

    // ── SCORING (Hit/Miss) ──
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '📈', text: 'Score 60+', difficulty: 2),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '📈', text: 'Score 80+', difficulty: 3),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '📈', text: 'Score 100+', difficulty: 3),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '📈', text: 'Score 120+', difficulty: 4),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '📈', text: 'Score 140+', difficulty: 4),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '🔥', text: '180! Hit T20 T20 T20', difficulty: 4),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '🧱', text: 'No 1s or 5s allowed', difficulty: 2),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '🚫', text: 'Score under 20 (low is hard!)', difficulty: 3),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '🥐', text: 'Score exactly 26 (Breakfast!)', difficulty: 3),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '👑', text: 'Score a ton (100+) without T20', difficulty: 4),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '🎲', text: 'All 3 darts must score (no misses!)', difficulty: 2),

    // ── NEW SCORING: Darts culture (G) ──
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '🍽️', text: 'Bed & Breakfast & Lunch! Score 41+ (S20, S1, D10)', difficulty: 3),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '🐂', text: 'Ton-80 Territory! Score 60+ using only T20 area', difficulty: 4),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.hitMiss, emoji: '🎭', text: 'The Entertainer! Hit 3 different triples in one visit', difficulty: 4),

    // ── SCORING (Best Score) ──
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.bestScore, emoji: '⚔️', text: 'Highest 3-dart score wins!', difficulty: 2),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.bestScore, emoji: '🏹', text: 'Trebles only: highest score wins!', difficulty: 4),
    Challenge(category: ChallengeCategory.scoring, type: ChallengeType.bestScore, emoji: '🎰', text: 'Doubles only: highest score wins!', difficulty: 3),

    // ── FINISH (Hit/Miss) ──
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.hitMiss, emoji: '🎯', text: 'Checkout 32 (Double 16)', difficulty: 2),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.hitMiss, emoji: '🎯', text: 'Checkout 40 (Double 20)', difficulty: 2),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.hitMiss, emoji: '🏁', text: 'Checkout 80', difficulty: 3),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.hitMiss, emoji: '🏁', text: 'Checkout 100', difficulty: 4),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.hitMiss, emoji: '🥫', text: 'Checkout 57 (Heinz!)', difficulty: 3),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.hitMiss, emoji: '🎯', text: 'Checkout 50 (Bullseye finish!)', difficulty: 3),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.hitMiss, emoji: '2️⃣', text: 'Checkout 24 (2 Dozen)', difficulty: 2),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.hitMiss, emoji: '💯', text: 'Checkout 120', difficulty: 4),

    // ── FINISH: Darts culture ──
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.hitMiss, emoji: '🇳🇱', text: 'Checkout 84 (The Barney!)', difficulty: 3),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.hitMiss, emoji: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', text: 'Checkout 96 (The Bristow!)', difficulty: 3),
    Challenge(category: ChallengeCategory.finish, type: ChallengeType.hitMiss, emoji: '🎭', text: 'Checkout 110 (T20, Bull)', difficulty: 4),

    // ── BATTLE (Closest / Judge) ──
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.closest, emoji: '🎯', text: 'Closest to the Bull!', difficulty: 3),
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.closest, emoji: '🏹', text: 'Closest to Triple 20!', difficulty: 4),
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.closest, emoji: '🎪', text: 'Closest to Double 16!', difficulty: 3),
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.closest, emoji: '📏', text: 'Tightest grouping! (3 darts closest together)', difficulty: 3),

    // ── NEW BATTLE: Darts culture (G) ──
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.closest, emoji: '🎯', text: 'Middle for Diddle! Closest to Bull decides!', difficulty: 3),
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.closest, emoji: '🔥', text: 'Mugs Away! Loser of last round throws first. Closest to T20!', difficulty: 4),

    // ── BATTLE: Progressive (F - new type) ──
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.progressive, emoji: '📈', text: 'Progressive! Each player must beat the other\'s last score', difficulty: 3),
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.progressive, emoji: '🔥', text: 'Score War! Keep raising the bar until someone cracks', difficulty: 4),

    // ── BATTLE: Auction (F - new type) ──
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.auction, emoji: '🔨', text: 'Auction!', targetValue: 80, difficulty: 3),
    Challenge(category: ChallengeCategory.battle, type: ChallengeType.auction, emoji: '🔨', text: 'Auction!', targetValue: 120, difficulty: 4),

    // ── SPECIAL (Elimination) ──
    Challenge(category: ChallengeCategory.special, type: ChallengeType.elimination, emoji: '💀', text: 'Hit any Double (3 lives)', subRounds: 3, difficulty: 3),
    Challenge(category: ChallengeCategory.special, type: ChallengeType.elimination, emoji: '💀', text: 'Hit any Triple (3 lives)', subRounds: 3, difficulty: 4),
    Challenge(category: ChallengeCategory.special, type: ChallengeType.elimination, emoji: '☠️', text: 'Hit the Bull (3 lives)', subRounds: 3, difficulty: 4),
    Challenge(category: ChallengeCategory.special, type: ChallengeType.elimination, emoji: '🫣', text: 'Hit any number > 10 (5 lives)', subRounds: 5, difficulty: 2),
    Challenge(category: ChallengeCategory.special, type: ChallengeType.hitMiss, emoji: '🤚', text: 'Weak hand throw! Score with non-dominant hand', difficulty: 3),
    Challenge(category: ChallengeCategory.special, type: ChallengeType.hitMiss, emoji: '🙈', text: 'Eyes closed! Throw 1 dart blind - hit the board', difficulty: 2),
    Challenge(category: ChallengeCategory.special, type: ChallengeType.elimination, emoji: '🪙', text: 'Hit T20 (3 lives)', subRounds: 3, difficulty: 4),

    // ── NEW SPECIAL: Roulette (F - board roulette) ──
    Challenge(category: ChallengeCategory.special, type: ChallengeType.hitMiss, emoji: '🎡', text: 'ROULETTE!', difficulty: 3, isRoulette: true),
  ];

  /// Generate a random checkout value, avoiding bogey numbers.
  int _randomCheckout() {
    int num;
    do {
      if (_random.nextDouble() > 0.7) {
        num = _random.nextInt(70) + 101; // 101-170
      } else {
        num = _random.nextInt(99) + 2; // 2-100
      }
    } while (_bogeyCheckouts.contains(num));
    return num;
  }

  /// Generate a roulette challenge. The spinner determines the number.
  Challenge _generateRoulette() {
    final options = [
      'Hit the Single of this number!',
      'Hit the Double of this number!',
      'Hit the Triple of this number!',
      'Hit this number!',
    ];
    final difficulties = [2, 3, 4, 2];
    final idx = _random.nextInt(options.length);
    return Challenge(
      category: ChallengeCategory.special,
      type: ChallengeType.hitMiss,
      emoji: '🎡',
      text: 'ROULETTE! ${options[idx]}',
      difficulty: difficulties[idx],
      isRoulette: true,
    );
  }

  /// Generate an auction challenge with a random checkout.
  Challenge _generateAuction() {
    final co = _randomCheckout();
    return Challenge(
      category: ChallengeCategory.battle,
      type: ChallengeType.auction,
      emoji: '🔨',
      text: 'Auction! Checkout $co',
      targetValue: co,
      difficulty: co > 100 ? 4 : 3,
    );
  }

  /// Generate a challenge based on game settings.
  Challenge generate({
    required String focusArea,
    required bool isTwoPlayer,
    Challenge? lastChallenge,
  }) {
    // 8% chance of roulette
    if (_random.nextDouble() < 0.08) {
      return _generateRoulette();
    }

    // 8% chance of auction in 2P mode
    if (isTwoPlayer && _random.nextDouble() < 0.08) {
      return _generateAuction();
    }

    // 8% chance of progressive in 2P mode
    if (isTwoPlayer && _random.nextDouble() < 0.08) {
      final progressives = _staticChallenges.where(
        (c) => c.type == ChallengeType.progressive,
      ).toList();
      if (progressives.isNotEmpty) {
        return progressives[_random.nextInt(progressives.length)];
      }
    }

    // 15% chance of battle in 2P mode
    if (isTwoPlayer && _random.nextDouble() < 0.15) {
      return _pickBattle();
    }

    // 10% chance of elimination/special
    if (_random.nextDouble() < 0.12) {
      return _pickSpecial(isTwoPlayer);
    }

    final pool = <Challenge>[];

    // Build a balanced pool from all categories
    pool.addAll(_staticChallenges.where(
      (c) => c.category == ChallengeCategory.scoring,
    ));
    pool.addAll(_staticChallenges.where(
      (c) => c.category == ChallengeCategory.precision,
    ));
    pool.addAll(_staticChallenges.where(
      (c) => c.category == ChallengeCategory.finish,
    ));
    pool.addAll(_staticChallenges.where(
      (c) => c.category == ChallengeCategory.special && c.type == ChallengeType.hitMiss,
    ));

    // Add dynamic scoring challenge
    final target = 20 + (_random.nextInt(13) * 10); // 20-140
    pool.add(Challenge(
      category: ChallengeCategory.scoring,
      type: ChallengeType.hitMiss,
      emoji: '💯',
      text: 'Score $target+',
      difficulty: (target / 40).ceil().clamp(1, 5),
    ));

    // Add dynamic precision challenges
    final seg = _segments[_random.nextInt(_segments.length)];
    pool.add(Challenge(
      category: ChallengeCategory.precision,
      type: ChallengeType.hitMiss,
      emoji: '👀',
      text: 'Hit Double $seg',
      difficulty: 3,
    ));
    pool.add(Challenge(
      category: ChallengeCategory.precision,
      type: ChallengeType.hitMiss,
      emoji: '💥',
      text: 'Hit Triple $seg',
      difficulty: 4,
    ));

    // Add dynamic checkout
    final co = _randomCheckout();
    pool.add(Challenge(
      category: ChallengeCategory.finish,
      type: ChallengeType.hitMiss,
      emoji: '🏁',
      text: 'Checkout $co',
      difficulty: co > 100 ? 4 : co > 60 ? 3 : 2,
    ));

    if (pool.isEmpty) {
      pool.addAll(_staticChallenges);
    }

    // Filter out types that don't work in single-player mode
    if (!isTwoPlayer) {
      pool.removeWhere(
        (c) => c.type == ChallengeType.bestScore ||
            c.type == ChallengeType.closest ||
            c.type == ChallengeType.elimination ||
            c.type == ChallengeType.auction ||
            c.type == ChallengeType.progressive,
      );
    }

    // Try to avoid repeating the last challenge
    if (lastChallenge != null && pool.length > 1) {
      pool.removeWhere((c) => c.text == lastChallenge.text);
    }

    return pool[_random.nextInt(pool.length)];
  }

  Challenge _pickBattle() {
    final battles = _staticChallenges.where(
      (c) => c.category == ChallengeCategory.battle &&
          c.type != ChallengeType.auction &&
          c.type != ChallengeType.progressive,
    ).toList();
    // Add dynamic battle
    final seg = _segments[_random.nextInt(_segments.length)];
    battles.add(Challenge(
      category: ChallengeCategory.battle,
      type: ChallengeType.closest,
      emoji: '🏹',
      text: 'Closest to $seg!',
      difficulty: 3,
    ));
    return battles[_random.nextInt(battles.length)];
  }

  Challenge _pickSpecial(bool isTwoPlayer) {
    final specials = _staticChallenges.where(
      (c) => c.category == ChallengeCategory.special,
    ).toList();
    // Filter elimination in single player
    if (!isTwoPlayer) {
      specials.removeWhere((c) => c.type == ChallengeType.elimination);
    }
    if (specials.isEmpty) {
      return _staticChallenges[_random.nextInt(_staticChallenges.length)];
    }
    return specials[_random.nextInt(specials.length)];
  }

  /// Get a sudden-death challenge for tied games.
  Challenge suddenDeath() {
    return const Challenge(
      category: ChallengeCategory.battle,
      type: ChallengeType.closest,
      emoji: '💀',
      text: 'SUDDEN DEATH: Closest to Bull!',
      difficulty: 5,
    );
  }

  /// Get challenges filtered by category (for redemption card).
  List<Challenge> getChallengesForCategory({
    required ChallengeCategory category,
    required bool isTwoPlayer,
    Challenge? lastChallenge,
  }) {
    final pool = _staticChallenges.where((c) => c.category == category).toList();

    // Filter out types that don't work in single-player
    if (!isTwoPlayer) {
      pool.removeWhere(
        (c) => c.type == ChallengeType.bestScore ||
            c.type == ChallengeType.closest ||
            c.type == ChallengeType.elimination ||
            c.type == ChallengeType.auction ||
            c.type == ChallengeType.progressive,
      );
    }

    // Avoid repeating last challenge
    if (lastChallenge != null && pool.length > 1) {
      pool.removeWhere((c) => c.text == lastChallenge.text);
    }

    return pool;
  }

  /// Dart board segment names for roulette display.
  static const boardSegments = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17,
    3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
  ];
}
