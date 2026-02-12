import 'dart:math';

/// Provides darts commentator-style quotes and reactions,
/// inspired by Sky Sports darts commentary.
class CommentaryService {
  static final CommentaryService _instance = CommentaryService._internal();
  factory CommentaryService() => _instance;
  CommentaryService._internal();

  final _random = Random();

  // ── Hit reactions (generic) ──
  static const _hitQuotes = [
    'LOVELY DARTS!',
    'What a shot!',
    'Right in the money!',
    'That\'s the business!',
    'Clinical finishing!',
    'He\'s on fire!',
    'Brilliant arrows!',
    'Take a bow!',
    'That\'s world class!',
    'Nailed it!',
    'Pinpoint accuracy!',
    'Sweet as a nut!',
    'You beauty!',
    'Class act!',
    'Stone cold!',
  ];

  // ── Miss reactions ──
  static const _missQuotes = [
    'Oh, unlucky!',
    'That\'s gone walkabout!',
    'He won\'t want to see that again!',
    'Wide of the mark!',
    'That\'s drifted!',
    'Wayward arrow!',
    'Not his finest!',
    'Oof, the pressure!',
    'Just couldn\'t find it!',
    'That\'s gone fishing!',
    'Off target!',
    'Back to the practice board!',
    'The nerves are showing!',
  ];

  // ── Big score reactions ──
  static const _bigScoreQuotes = [
    'ONE HUNDRED AND EIGHTY!',
    'MAXIMUUUUUM!',
    'THE PERFECT VISIT!',
  ];

  // ── Score-specific reactions ──
  static const _tonQuotes = [
    'TON!',
    'That\'s a ton!',
    'A lovely ton!',
    'A hundred on the board!',
  ];

  static const _tonPlusQuotes = [
    'TON PLUS!',
    'Big score!',
    'That\'s a monster visit!',
    'Filling his boots!',
  ];

  // ── Bed and Breakfast (26) ──
  static const _breakfastQuotes = [
    'BED AND BREAKFAST!',
    'The old 26!',
    'Breakfast is served!',
  ];

  // ── Streak reactions ──
  static const _streakQuotes = [
    'ON FIRE! 🔥',
    'UNSTOPPABLE!',
    'What a run!',
    'Can anyone stop them?!',
    'The hot streak continues!',
    'MACHINE!',
  ];

  // ── Checkout reactions ──
  static const _checkoutQuotes = [
    'GAME SHOT!',
    'And that\'s the checkout!',
    'Beautiful finish!',
    'What a way to check out!',
    'Clinical on the doubles!',
  ];

  // ── Big checkout reactions ──
  static const _bigCheckoutQuotes = [
    'WHAT A CHECKOUT!',
    'SENSATIONAL FINISHING!',
    'THAT IS OUTRAGEOUS!',
    'Are you kidding me?!',
  ];

  // ── Pressure moments ──
  static const _pressureQuotes = [
    'This is it...',
    'The moment of truth!',
    'All eyes on the oche!',
    'Can they handle the pressure?',
    'Nerves of steel needed here!',
    'The tension is unbearable!',
  ];

  // ── Chaos card reactions ──
  static const _chaosCardQuotes = [
    'CHAOS CARD! 🃏',
    'Here comes trouble!',
    'Expect the unexpected!',
    'Things just got interesting!',
    'Hold onto your darts!',
  ];

  // ── Round start (generic) ──
  static const _roundStartQuotes = [
    'Game on!',
    'Here we go!',
    'Let\'s see what they\'ve got!',
    'Arrows ready!',
    'Step up to the oche!',
  ];

  String _pick(List<String> list) => list[_random.nextInt(list.length)];

  /// Get a commentary line for a hit.
  String onHit() => _pick(_hitQuotes);

  /// Get a commentary line for a miss.
  String onMiss() => _pick(_missQuotes);

  /// Get a commentary for a specific score value.
  String? onScore(int score) {
    if (score == 180) return _pick(_bigScoreQuotes);
    if (score == 26) return _pick(_breakfastQuotes);
    if (score >= 140) return _pick(_tonPlusQuotes);
    if (score >= 100) return _pick(_tonQuotes);
    return null;
  }

  /// Get a commentary for a hit streak.
  String onStreak(int streakCount) {
    if (streakCount >= 5) return 'ABSOLUTELY UNBELIEVABLE! $streakCount in a row!';
    if (streakCount >= 3) return _pick(_streakQuotes);
    return _pick(_hitQuotes);
  }

  /// Get a checkout commentary.
  String onCheckout(int value) {
    if (value >= 100) return _pick(_bigCheckoutQuotes);
    return _pick(_checkoutQuotes);
  }

  /// Get a pressure moment commentary.
  String onPressure() => _pick(_pressureQuotes);

  /// Get a chaos card reveal commentary.
  String onChaosCard() => _pick(_chaosCardQuotes);

  /// Get a round start commentary (used occasionally).
  String onRoundStart() => _pick(_roundStartQuotes);
}
