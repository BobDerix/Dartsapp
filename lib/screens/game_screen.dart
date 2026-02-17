import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../game/game_state.dart';
import '../models/challenge.dart';
import '../models/chaos_card.dart';
import '../theme/app_theme.dart';
import 'winner_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _bgAnim = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _bgAnim.dispose();
    super.dispose();
  }

  void _onQuit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Quit Game?'),
        content: const Text('Progress will be saved but no winner recorded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GameState>().quitGame();
              Navigator.pop(context);
            },
            child: const Text('Quit', style: TextStyle(color: AppColors.miss)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, game, _) {
        // Navigate to winner screen when game finishes
        if (game.phase == GamePhase.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WinnerScreen()),
            );
          });
        }

        return Scaffold(
          body: Stack(
            children: [
              // Animated background
              AnimatedBuilder(
                animation: _bgAnim,
                builder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(
                        sin(_bgAnim.value * 2 * pi) * 0.5,
                        cos(_bgAnim.value * 2 * pi) * 0.5,
                      ),
                      end: Alignment(
                        cos(_bgAnim.value * 2 * pi) * 0.5,
                        sin(_bgAnim.value * 2 * pi) * -0.5,
                      ),
                      colors: [
                        AppColors.background,
                        AppColors.background.withBlue(25),
                        AppColors.background,
                        AppColors.commentaryBg,
                      ],
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  // Header
                  _GameHeader(
                    onQuit: _onQuit,
                    onUndo: game.canUndo ? () => game.undo() : null,
                    roundNumber: game.roundNumber,
                  ),

                  // Scoreboard
                  _Scoreboard(game: game),

                  // Commentary banner
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: Tween(
                        begin: const Offset(0, -1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOutBack,
                      )),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: game.showCommentary && game.commentaryText != null
                        ? _CommentaryBanner(
                            key: ValueKey(game.commentaryText),
                            text: game.commentaryText!,
                          )
                        : const SizedBox.shrink(key: ValueKey('no_comment')),
                  ),

                  // Chaos card indicator (when active but dismissed)
                  if (game.activeChaosCard != null && !game.showingChaosCard)
                    _ChaosCardIndicator(card: game.activeChaosCard!),

                  // Challenge display
                  Expanded(
                    child: _ChallengeDisplay(
                      challenge: game.currentChallenge,
                      key: ValueKey('challenge_${game.roundNumber}'),
                    ),
                  ),

                  // Control area
                  _ControlArea(
                    game: game,
                    onConfetti: () => _confetti.play(),
                  ),
                ],
              ),

              // Confetti overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 30,
                  maxBlastForce: 20,
                  minBlastForce: 5,
                  colors: const [
                    AppColors.player1,
                    AppColors.player2,
                    AppColors.hit,
                    AppColors.catFinish,
                  ],
                ),
              ),

              // Chaos card overlay (full-screen reveal)
              if (game.showingChaosCard && game.activeChaosCard != null)
                _ChaosCardOverlay(
                  card: game.activeChaosCard!,
                  onDismiss: () => game.dismissChaosCard(),
                ),

              // Category picker overlay (redemption card)
              if (game.showingCategoryPicker)
                _CategoryPickerOverlay(
                  playerName: game.redemptionPlayerIdx == 0
                      ? (game.player1?.name ?? 'P1')
                      : (game.player2?.name ?? 'P2'),
                  onPick: (category) => game.pickCategory(category),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ──

class _GameHeader extends StatelessWidget {
  final VoidCallback onQuit;
  final VoidCallback? onUndo;
  final int roundNumber;

  const _GameHeader({required this.onQuit, this.onUndo, required this.roundNumber});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _HeaderButton(icon: Icons.close, onTap: onQuit),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.neutral.withAlpha(60),
                    AppColors.neutral.withAlpha(30),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neutral.withAlpha(80)),
              ),
              child: Text(
                'ROUND $roundNumber',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutral,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const Spacer(),
            _HeaderButton(
              icon: Icons.undo,
              label: 'Undo',
              onTap: onUndo,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  const _HeaderButton({required this.icon, this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: onTap != null ? Colors.white70 : Colors.white24,
                size: 18),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  color: onTap != null ? Colors.white70 : Colors.white24,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Commentary Banner ──

class _CommentaryBanner extends StatefulWidget {
  final String text;
  const _CommentaryBanner({super.key, required this.text});

  @override
  State<_CommentaryBanner> createState() => _CommentaryBannerState();
}

class _CommentaryBannerState extends State<_CommentaryBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.commentaryBg,
              Color.lerp(
                    const Color(0xFF16213E),
                    const Color(0xFF2A1A4E),
                    (sin(_shimmer.value * 2 * pi) + 1) / 2,
                  ) ??
                  const Color(0xFF16213E),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.chaosGold.withAlpha(
              (77 + 50 * sin(_shimmer.value * 2 * pi)).toInt(),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.chaosGold.withAlpha(30),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.chaosGold,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── Chaos Card Indicator (small pill when active) ──

class _ChaosCardIndicator extends StatefulWidget {
  final ChaosCard card;
  const _ChaosCardIndicator({required this.card});

  @override
  State<_ChaosCardIndicator> createState() => _ChaosCardIndicatorState();
}

class _ChaosCardIndicatorState extends State<_ChaosCardIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.chaosBackground, Color(0xFF330066)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.chaosBorder.withAlpha(
              (150 + 105 * _pulse.value).toInt(),
            ),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.chaosBorder.withAlpha(
                (20 + 40 * _pulse.value).toInt(),
              ),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.card.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              widget.card.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.chaosGold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.card.description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withAlpha(178),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chaos Card Overlay (full-screen dramatic reveal) ──

class _ChaosCardOverlay extends StatefulWidget {
  final ChaosCard card;
  final VoidCallback onDismiss;
  const _ChaosCardOverlay({required this.card, required this.onDismiss});

  @override
  State<_ChaosCardOverlay> createState() => _ChaosCardOverlayState();
}

class _ChaosCardOverlayState extends State<_ChaosCardOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shimmer;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shimmer = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _scaleAnim = Tween(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _rotateAnim = Tween(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _shimmer]),
      builder: (_, __) => GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          color: Colors.black.withAlpha((_opacityAnim.value * 220).toInt()),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Transform.rotate(
                angle: _rotateAnim.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(
                        sin(_shimmer.value * 2 * pi) * 0.5,
                        cos(_shimmer.value * 2 * pi) * 0.5,
                      ),
                      end: Alignment.bottomRight,
                      colors: const [
                        AppColors.chaosBackground,
                        Color(0xFF330066),
                        Color(0xFF1A004D),
                        AppColors.chaosBackground,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.chaosBorder.withAlpha(
                        (180 + 75 * sin(_shimmer.value * 2 * pi)).toInt(),
                      ),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.chaosBorder.withAlpha(
                          (80 + 60 * sin(_shimmer.value * 2 * pi)).toInt(),
                        ),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: AppColors.chaosGold.withAlpha(40),
                        blurRadius: 60,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'CHAOS CARD',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.chaosBorder,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.card.emoji,
                        style: const TextStyle(fontSize: 72),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.card.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.chaosGold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.card.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withAlpha(204),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _PulsingText(
                        text: 'TAP TO CONTINUE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(140),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category Picker Overlay (Redemption card) ──

class _CategoryPickerOverlay extends StatefulWidget {
  final String playerName;
  final void Function(ChallengeCategory) onPick;

  const _CategoryPickerOverlay({required this.playerName, required this.onPick});

  @override
  State<_CategoryPickerOverlay> createState() => _CategoryPickerOverlayState();
}

class _CategoryPickerOverlayState extends State<_CategoryPickerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _entry;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  static const _categories = [
    (ChallengeCategory.precision, 'PRECISION', Icons.gps_fixed, AppColors.catPrecision),
    (ChallengeCategory.scoring, 'SCORING', Icons.scoreboard, AppColors.catScoring),
    (ChallengeCategory.finish, 'FINISH', Icons.flag, AppColors.catFinish),
    (ChallengeCategory.battle, 'BATTLE', Icons.sports_mma, AppColors.catBattle),
    (ChallengeCategory.special, 'SPECIAL', Icons.star, AppColors.catSpecial),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (_, __) => Container(
        color: Colors.black.withAlpha((_fadeAnim.value * 200).toInt()),
        child: Center(
          child: Opacity(
            opacity: _fadeAnim.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.card, AppColors.surface],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.chaosGold.withAlpha(120), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.chaosGold.withAlpha(40),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'REDEMPTION',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.chaosGold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.playerName}, pick a category!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(_categories.length, (i) {
                    final (category, label, icon, color) = _categories[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => widget.onPick(category),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withAlpha(100)),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: color, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pulsing Text Helper ──

class _PulsingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _PulsingText({required this.text, required this.style});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: 0.4 + 0.6 * _controller.value,
        child: Text(widget.text, style: widget.style),
      ),
    );
  }
}

// ── Scoreboard ──

class _Scoreboard extends StatelessWidget {
  final GameState game;
  const _Scoreboard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _PlayerCard(
              name: game.player1?.name ?? 'P1',
              score: game.p1State.score,
              targetScore: game.targetScore,
              hitRate: game.p1HitRate,
              streak: game.p1State.streak,
              color: AppColors.player1,
            ),
          ),
          // VS divider
          if (!game.isSinglePlayer) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(15),
                      border: Border.all(color: Colors.white.withAlpha(30)),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white38,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _PlayerCard(
                name: game.player2?.name ?? 'P2',
                score: game.p2State.score,
                targetScore: game.targetScore,
                hitRate: game.p2HitRate,
                streak: game.p2State.streak,
                color: AppColors.player2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerCard extends StatefulWidget {
  final String name;
  final int score;
  final int targetScore;
  final double hitRate;
  final int streak;
  final Color color;

  const _PlayerCard({
    required this.name,
    required this.score,
    required this.targetScore,
    required this.hitRate,
    required this.streak,
    required this.color,
  });

  @override
  State<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<_PlayerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.targetScore > 0
        ? (widget.score / widget.targetScore).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.card.withAlpha(250),
              Color.lerp(AppColors.card, widget.color, 0.08)!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: BorderSide(
              color: widget.color.withAlpha(
                (180 + 75 * _glow.value).toInt(),
              ),
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withAlpha(
                (15 + 25 * _glow.value).toInt(),
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              widget.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withAlpha(204),
                letterSpacing: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: widget.score),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, value, __) => Text(
                '$value',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: widget.color.withAlpha(80),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Progress bar toward target
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withAlpha(20),
                valueColor: AlwaysStoppedAnimation(widget.color.withAlpha(150)),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(widget.hitRate * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.streak >= 3)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFFF0000)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.streak}x',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Challenge Display ──

class _ChallengeDisplay extends StatefulWidget {
  final Challenge? challenge;
  const _ChallengeDisplay({super.key, this.challenge});

  @override
  State<_ChallengeDisplay> createState() => _ChallengeDisplayState();
}

class _ChallengeDisplayState extends State<_ChallengeDisplay>
    with TickerProviderStateMixin {
  late AnimationController _entry;
  late AnimationController _bounce;
  late Animation<double> _entryScale;
  late Animation<double> _entryFade;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounce = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _entryScale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entry, curve: Curves.easeOutBack),
    );
    _entryFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entry, curve: Curves.easeOut),
    );
    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.challenge == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_entry, _bounce]),
      builder: (_, __) => Opacity(
        opacity: _entryFade.value,
        child: Transform.scale(
          scale: _entryScale.value,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category pill with glow
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.categoryColor(
                          widget.challenge!.category.displayName),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.categoryColor(
                                  widget.challenge!.category.displayName)
                              .withAlpha(80),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.challenge!.category.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.background,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Roulette spinner or emoji with bounce
                  if (widget.challenge!.isRoulette)
                    _RouletteSpinner(
                        key: ValueKey('roulette_${widget.challenge!.text}'))
                  else
                    Transform.translate(
                      offset: Offset(0, sin(_bounce.value * pi) * 4),
                      child: Text(
                        widget.challenge!.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Challenge text with shimmer
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: const [
                        Colors.white,
                        Color(0xFFCCCCCC),
                        Colors.white,
                      ],
                      stops: [
                        (_bounce.value - 0.3).clamp(0.0, 1.0),
                        _bounce.value.clamp(0.0, 1.0),
                        (_bounce.value + 0.3).clamp(0.0, 1.0),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      widget.challenge!.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Difficulty dots
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final isFilled = i < widget.challenge!.difficulty;
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + i * 100),
                        width: isFilled ? 10 : 8,
                        height: isFilled ? 10 : 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? AppColors.catFinish
                              : Colors.white.withAlpha(51),
                          boxShadow: isFilled
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.catFinish.withAlpha(80),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),

                  // Roulette badge
                  if (widget.challenge!.isRoulette) ...[
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ChallengeBadge(
                          icon: Icons.casino,
                          label: 'ROULETTE',
                          color: AppColors.catBattle,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ChallengeBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Roulette Spinner ──

class _RouletteSpinner extends StatefulWidget {
  const _RouletteSpinner({super.key});

  @override
  State<_RouletteSpinner> createState() => _RouletteSpinnerState();
}

class _RouletteSpinnerState extends State<_RouletteSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  static const _segments = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17,
    3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
  ];

  int _displaySegment = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rotation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Randomly pick which segment to land on
    _displaySegment = Random().nextInt(_segments.length);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (_, __) {
        // Show cycling numbers during animation
        final totalCycles = 20 + _displaySegment; // spin past at least 20
        final currentIdx =
            (_rotation.value * totalCycles).floor() % _segments.length;
        final number = _segments[currentIdx];
        final isDone = _rotation.value >= 0.98;

        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                isDone ? AppColors.catBattle : AppColors.card,
                AppColors.surface,
              ],
            ),
            border: Border.all(
              color: isDone ? AppColors.chaosGold : AppColors.catBattle,
              width: 3,
            ),
            boxShadow: isDone
                ? [
                    BoxShadow(
                        color: AppColors.catBattle.withAlpha(100),
                        blurRadius: 20),
                    BoxShadow(
                        color: AppColors.chaosGold.withAlpha(60),
                        blurRadius: 30,
                        spreadRadius: 5),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: isDone ? 42 : 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: isDone
                    ? [
                        const Shadow(
                            color: Colors.white24, blurRadius: 10),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Control Area ──

class _ControlArea extends StatelessWidget {
  final GameState game;
  final VoidCallback onConfetti;

  const _ControlArea({required this.game, required this.onConfetti});

  @override
  Widget build(BuildContext context) {
    final challenge = game.currentChallenge;
    if (challenge == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.card, AppColors.surface],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withAlpha(20),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInputControls(context, challenge),
              const SizedBox(height: 12),
              _buildNextButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputControls(BuildContext context, Challenge challenge) {
    switch (challenge.type) {
      case ChallengeType.hitMiss:
        return _HitMissControls(game: game);

      case ChallengeType.bestScore:
        return _BestScoreControls(game: game);

      case ChallengeType.threshold:
        return _ScoreEntryControls(game: game);

      case ChallengeType.closest:
        return _JudgeControls(game: game);

      case ChallengeType.elimination:
        return _EliminationControls(game: game);

      case ChallengeType.auction:
        return _AuctionControls(game: game);

      case ChallengeType.progressive:
        return _ProgressiveControls(game: game);
    }
  }

  Widget _buildNextButton(BuildContext context) {
    final isReady = game.roundComplete;
    final isJudge = game.currentChallenge?.type == ChallengeType.closest ||
        game.currentChallenge?.type == ChallengeType.bestScore;

    // Judge resolves itself
    if (isJudge) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: isReady ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSlide(
        offset: isReady ? Offset.zero : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          width: double.infinity,
          child: _GlowButton(
            label: 'NEXT CHALLENGE  \u27A1',
            color: AppColors.neutral,
            onTap: isReady
                ? () {
                    onConfetti();
                    game.confirmRound();
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

// ── Glow Button ──

class _GlowButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _GlowButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color,
                Color.lerp(widget.color, Colors.white, 0.15)!,
                widget.color,
              ],
              stops: [
                0.0,
                _glow.value,
                1.0,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha(
                  (60 + 60 * _glow.value).toInt(),
                ),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hit/Miss Controls ──

class _HitMissControls extends StatelessWidget {
  final GameState game;
  const _HitMissControls({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HitMissRow(
          label: game.player1?.name ?? 'P1',
          labelColor: AppColors.player1,
          choice: game.p1State.hitMissChoice,
          onHit: () => game.setHitMiss(0, true),
          onMiss: () => game.setHitMiss(0, false),
        ),
        if (!game.isSinglePlayer) ...[
          const SizedBox(height: 10),
          _HitMissRow(
            label: game.player2?.name ?? 'P2',
            labelColor: AppColors.player2,
            choice: game.p2State.hitMissChoice,
            onHit: () => game.setHitMiss(1, true),
            onMiss: () => game.setHitMiss(1, false),
          ),
        ],
      ],
    );
  }
}

class _HitMissRow extends StatelessWidget {
  final String label;
  final Color labelColor;
  final bool? choice;
  final VoidCallback onHit;
  final VoidCallback onMiss;

  const _HitMissRow({
    required this.label,
    required this.labelColor,
    required this.choice,
    required this.onHit,
    required this.onMiss,
  });

  @override
  Widget build(BuildContext context) {
    final locked = choice != null;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: labelColor,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            label: 'HIT',
            isActive: choice == true,
            activeColor: AppColors.hit,
            isLocked: locked && choice != true,
            onTap: locked ? null : onHit,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            label: 'MISS',
            isActive: choice == false,
            activeColor: AppColors.miss,
            isLocked: locked && choice != false,
            onTap: locked ? null : onMiss,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final bool isLocked;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.isLocked,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _anim.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _anim.reverse();
              widget.onTap!();
            }
          : null,
      onTapCancel: () => _anim.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.isActive
                ? LinearGradient(
                    colors: [
                      widget.activeColor,
                      Color.lerp(widget.activeColor, Colors.white, 0.15)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isActive ? null : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                        color: widget.activeColor.withAlpha(120),
                        blurRadius: 12,
                        spreadRadius: 1),
                  ]
                : null,
          ),
          child: AnimatedOpacity(
            opacity: widget.isLocked ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Score Entry Controls ──

class _ScoreEntryControls extends StatefulWidget {
  final GameState game;
  const _ScoreEntryControls({required this.game});

  @override
  State<_ScoreEntryControls> createState() => _ScoreEntryControlsState();
}

class _ScoreEntryControlsState extends State<_ScoreEntryControls> {
  final _p1Controller = TextEditingController();
  final _p2Controller = TextEditingController();

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ScoreEntryControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset controllers on new challenge
    if (widget.game.p1State.scoreEntry == null) {
      _p1Controller.clear();
      _p2Controller.clear();
    }
  }

  void _submitP1() {
    final score = int.tryParse(_p1Controller.text);
    if (score != null && score >= 0 && score <= 180) {
      widget.game.setScore(0, score);
    } else if (score != null && score > 180) {
      _p1Controller.text = '180';
      widget.game.setScore(0, 180);
    }
  }

  void _submitP2() {
    final score = int.tryParse(_p2Controller.text);
    if (score != null && score >= 0 && score <= 180) {
      widget.game.setScore(1, score);
    } else if (score != null && score > 180) {
      _p2Controller.text = '180';
      widget.game.setScore(1, 180);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isThreshold = game.currentChallenge?.type == ChallengeType.threshold;
    final target = game.currentChallenge?.targetValue;

    return Column(
      children: [
        _ScoreEntryRow(
          label: game.player1?.name ?? 'P1',
          labelColor: AppColors.player1,
          controller: _p1Controller,
          submitted: game.p1State.scoreEntry != null,
          submittedValue: game.p1State.scoreEntry,
          isThreshold: isThreshold,
          target: target,
          onSubmit: _submitP1,
        ),
        if (!game.isSinglePlayer) ...[
          const SizedBox(height: 10),
          _ScoreEntryRow(
            label: game.player2?.name ?? 'P2',
            labelColor: AppColors.player2,
            controller: _p2Controller,
            submitted: game.p2State.scoreEntry != null,
            submittedValue: game.p2State.scoreEntry,
            isThreshold: isThreshold,
            target: target,
            onSubmit: _submitP2,
          ),
        ],
      ],
    );
  }
}

class _ScoreEntryRow extends StatelessWidget {
  final String label;
  final Color labelColor;
  final TextEditingController controller;
  final bool submitted;
  final int? submittedValue;
  final bool isThreshold;
  final int? target;
  final VoidCallback onSubmit;

  const _ScoreEntryRow({
    required this.label,
    required this.labelColor,
    required this.controller,
    required this.submitted,
    this.submittedValue,
    required this.isThreshold,
    this.target,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (submitted) {
      final met = isThreshold && target != null && submittedValue != null
          ? submittedValue! >= target!
          : null;
      return Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: labelColor)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: met == true
                    ? AppColors.hit.withAlpha(51)
                    : met == false
                        ? AppColors.miss.withAlpha(51)
                        : Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: met == true
                      ? AppColors.hit
                      : met == false
                          ? AppColors.miss
                          : Colors.white24,
                ),
              ),
              child: Text(
                '$submittedValue',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: labelColor)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            decoration: InputDecoration(
              hintText: isThreshold
                  ? 'Score (target: $target, max 180)'
                  : 'Enter score (max 180)',
            ),
            onSubmitted: (_) => onSubmit(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSubmit,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.player1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

// ── Best Score Controls (tap winner) ──

class _BestScoreControls extends StatelessWidget {
  final GameState game;
  const _BestScoreControls({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Who scored highest?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PlayerPickButton(
                name: game.player1?.name ?? 'Player 1',
                color: AppColors.player1,
                onTap: () => game.setJudgeWinner(0),
              ),
            ),
            const SizedBox(width: 10),
            if (!game.isSinglePlayer)
              Expanded(
                child: _PlayerPickButton(
                  name: game.player2?.name ?? 'Player 2',
                  color: AppColors.player2,
                  onTap: () => game.setJudgeWinner(1),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => game.nextChallenge(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Tie / Redo',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable Player Pick Button ──

class _PlayerPickButton extends StatefulWidget {
  final String name;
  final Color color;
  final VoidCallback onTap;

  const _PlayerPickButton({
    required this.name,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PlayerPickButton> createState() => _PlayerPickButtonState();
}

class _PlayerPickButtonState extends State<_PlayerPickButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scale = Tween(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) {
        _anim.reverse();
        widget.onTap();
      },
      onTapCancel: () => _anim.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color,
                Color.lerp(widget.color, Colors.white, 0.12)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha(80),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            widget.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Judge Controls (Closest) ──

class _JudgeControls extends StatelessWidget {
  final GameState game;
  const _JudgeControls({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Who was closest?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PlayerPickButton(
                name: game.player1?.name ?? 'Player 1',
                color: AppColors.player1,
                onTap: () => game.setJudgeWinner(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PlayerPickButton(
                name: game.player2?.name ?? 'Player 2',
                color: AppColors.player2,
                onTap: () => game.setJudgeWinner(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Tie = skip, no points
            game.nextChallenge();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Tie / Redo',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Elimination Controls ──

class _EliminationControls extends StatelessWidget {
  final GameState game;
  const _EliminationControls({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EliminationPlayerRow(
          label: game.player1?.name ?? 'P1',
          labelColor: AppColors.player1,
          lives: game.p1State.eliminationLives,
          maxLives: game.currentChallenge?.subRounds ?? 3,
          hits: game.p1State.eliminationHits,
          isDone: game.p1State.eliminationDone,
          onHit: () => game.setEliminationHit(0, true),
          onMiss: () => game.setEliminationHit(0, false),
        ),
        if (!game.isSinglePlayer) ...[
          const SizedBox(height: 10),
          _EliminationPlayerRow(
            label: game.player2?.name ?? 'P2',
            labelColor: AppColors.player2,
            lives: game.p2State.eliminationLives,
            maxLives: game.currentChallenge?.subRounds ?? 3,
            hits: game.p2State.eliminationHits,
            isDone: game.p2State.eliminationDone,
            onHit: () => game.setEliminationHit(1, true),
            onMiss: () => game.setEliminationHit(1, false),
          ),
        ],
      ],
    );
  }
}

class _EliminationPlayerRow extends StatefulWidget {
  final String label;
  final Color labelColor;
  final int lives;
  final int maxLives;
  final int hits;
  final bool isDone;
  final VoidCallback onHit;
  final VoidCallback onMiss;

  const _EliminationPlayerRow({
    required this.label,
    required this.labelColor,
    required this.lives,
    required this.maxLives,
    required this.hits,
    required this.isDone,
    required this.onHit,
    required this.onMiss,
  });

  @override
  State<_EliminationPlayerRow> createState() => _EliminationPlayerRowState();
}

class _EliminationPlayerRowState extends State<_EliminationPlayerRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashAnim;
  bool _lastWasHit = false;
  int _prevHits = 0;
  int _prevLives = 0;

  @override
  void initState() {
    super.initState();
    _prevHits = widget.hits;
    _prevLives = widget.lives;
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flashAnim = CurvedAnimation(parent: _flashController, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_EliminationPlayerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hits > _prevHits) {
      _lastWasHit = true;
      _flashController.forward(from: 0);
    } else if (widget.lives < _prevLives) {
      _lastWasHit = false;
      _flashController.forward(from: 0);
    }
    _prevHits = widget.hits;
    _prevLives = widget.lives;
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flashAnim,
      builder: (context, child) {
        final flashColor = _lastWasHit
            ? AppColors.hit.withAlpha((80 * (1 - _flashAnim.value)).round())
            : AppColors.miss.withAlpha((80 * (1 - _flashAnim.value)).round());
        return Container(
          decoration: BoxDecoration(
            color: _flashController.isAnimating ? flashColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: _buildContent(),
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(widget.label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: widget.labelColor)),
            ),
            // Lives display
            ...List.generate(widget.maxLives, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    i < widget.lives ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey('${widget.label}-life-$i-${i < widget.lives}'),
                    color: i < widget.lives ? AppColors.miss : Colors.white24,
                    size: 20,
                  ),
                ),
              );
            }),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Text(
                '${widget.hits} hits',
                key: ValueKey('hits-${widget.hits}'),
                style: const TextStyle(
                    color: AppColors.hit,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (!widget.isDone)
          Row(
            children: [
              const SizedBox(width: 80),
              Expanded(
                child: _ActionButton(
                  label: 'HIT',
                  isActive: false,
                  activeColor: AppColors.hit,
                  isLocked: false,
                  onTap: widget.onHit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'MISS',
                  isActive: false,
                  activeColor: AppColors.miss,
                  isLocked: false,
                  onTap: widget.onMiss,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              const SizedBox(width: 80),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.lives > 0
                        ? AppColors.hit.withAlpha(51)
                        : AppColors.miss.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.lives > 0 ? AppColors.hit : AppColors.miss,
                    ),
                  ),
                  child: Text(
                    widget.lives > 0 ? 'SURVIVED (${widget.hits} hits)' : 'ELIMINATED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: widget.lives > 0 ? AppColors.hit : AppColors.miss,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ── Auction Controls ──

class _AuctionControls extends StatefulWidget {
  final GameState game;
  const _AuctionControls({required this.game});

  @override
  State<_AuctionControls> createState() => _AuctionControlsState();
}

class _AuctionControlsState extends State<_AuctionControls> {
  final _p1Controller = TextEditingController();
  final _p2Controller = TextEditingController();

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    super.dispose();
  }

  void _submitBid(int playerIdx) {
    final controller = playerIdx == 0 ? _p1Controller : _p2Controller;
    final bid = int.tryParse(controller.text);
    if (bid != null && bid >= 1 && bid <= 20) {
      widget.game.setAuctionBid(playerIdx, bid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    if (game.auctionPhase == AuctionPhase.bidding) {
      return _buildBiddingPhase(game);
    } else {
      return _buildExecutionPhase(game);
    }
  }

  Widget _buildBiddingPhase(GameState game) {
    final checkout = game.currentChallenge?.targetValue ?? 0;
    return Column(
      children: [
        Text(
          'How many darts to checkout $checkout?',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Text(
          'Bid low to win! (1-20 darts)',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        _AuctionBidRow(
          label: game.player1?.name ?? 'P1',
          labelColor: AppColors.player1,
          controller: _p1Controller,
          submitted: game.p1State.auctionBid != null,
          submittedValue: game.p1State.auctionBid,
          onSubmit: () => _submitBid(0),
        ),
        const SizedBox(height: 8),
        _AuctionBidRow(
          label: game.player2?.name ?? 'P2',
          labelColor: AppColors.player2,
          controller: _p2Controller,
          submitted: game.p2State.auctionBid != null,
          submittedValue: game.p2State.auctionBid,
          onSubmit: () => _submitBid(1),
        ),
      ],
    );
  }

  Widget _buildExecutionPhase(GameState game) {
    final winnerIdx = game.auctionWinnerIdx ?? 0;
    final winnerName = winnerIdx == 0
        ? (game.player1?.name ?? 'P1')
        : (game.player2?.name ?? 'P2');
    final winnerColor =
        winnerIdx == 0 ? AppColors.player1 : AppColors.player2;
    final bid =
        winnerIdx == 0 ? game.p1State.auctionBid : game.p2State.auctionBid;
    final winnerPs = winnerIdx == 0 ? game.p1State : game.p2State;

    if (winnerPs.hitMissChoice != null) {
      // Result already entered
      final isHit = winnerPs.hitMissChoice == true;
      return Column(
        children: [
          Text(
            '$winnerName bid $bid darts',
            style: TextStyle(color: winnerColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isHit
                  ? AppColors.hit.withAlpha(51)
                  : AppColors.miss.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: isHit ? AppColors.hit : AppColors.miss),
            ),
            child: Text(
              isHit ? 'CHECKOUT! (+2 pts)' : 'FAILED! (opponent +1 pt)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isHit ? AppColors.hit : AppColors.miss,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 14),
            children: [
              TextSpan(
                text: winnerName,
                style: TextStyle(
                    color: winnerColor, fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: ' won with bid of $bid darts!',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Did they make the checkout?',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'CHECKOUT!',
                isActive: false,
                activeColor: AppColors.hit,
                isLocked: false,
                onTap: () => game.setAuctionResult(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'FAILED',
                isActive: false,
                activeColor: AppColors.miss,
                isLocked: false,
                onTap: () => game.setAuctionResult(false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuctionBidRow extends StatelessWidget {
  final String label;
  final Color labelColor;
  final TextEditingController controller;
  final bool submitted;
  final int? submittedValue;
  final VoidCallback onSubmit;

  const _AuctionBidRow({
    required this.label,
    required this.labelColor,
    required this.controller,
    required this.submitted,
    this.submittedValue,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (submitted) {
      return Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: labelColor)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: labelColor.withAlpha(100)),
              ),
              child: Text(
                '$submittedValue darts',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: labelColor)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            decoration: const InputDecoration(hintText: 'Bid (1-20 darts)'),
            onSubmitted: (_) => onSubmit(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSubmit,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: labelColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.gavel, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

// ── Progressive Controls ──

class _ProgressiveControls extends StatefulWidget {
  final GameState game;
  const _ProgressiveControls({required this.game});

  @override
  State<_ProgressiveControls> createState() => _ProgressiveControlsState();
}

class _ProgressiveControlsState extends State<_ProgressiveControls> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final score = int.tryParse(_controller.text);
    if (score != null && score >= 0 && score <= 180) {
      final game = widget.game;
      game.setProgressiveScore(game.progressiveTurn, score);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    if (game.progressiveResolved) {
      return _buildResult(game);
    }

    final isP1Turn = game.progressiveTurn == 0;
    final currentName = isP1Turn
        ? (game.player1?.name ?? 'P1')
        : (game.player2?.name ?? 'P2');
    final currentColor = isP1Turn ? AppColors.player1 : AppColors.player2;

    return Column(
      children: [
        if (game.progressiveTarget > 0) ...[
          Text(
            'Target to beat: ${game.progressiveTarget}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.catFinish,
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Show P1's score if already entered
        if (game.p1State.scoreEntry != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    game.player1?.name ?? 'P1',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.player1,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.player1.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.player1.withAlpha(80)),
                    ),
                    child: Text(
                      '${game.p1State.scoreEntry}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.player1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Current player's turn
        if (!game.progressiveResolved)
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  currentName,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: currentColor),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: isP1Turn
                        ? 'Set the target! (max 180)'
                        : 'Beat ${game.progressiveTarget}! (max 180)',
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submit,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: currentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildResult(GameState game) {
    final s1 = game.p1State.scoreEntry ?? 0;
    final s2 = game.p2State.scoreEntry ?? 0;
    final p2Won = s2 > s1;
    final winnerName = p2Won
        ? (game.player2?.name ?? 'P2')
        : (game.player1?.name ?? 'P1');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProgressiveScoreChip(
              name: game.player1?.name ?? 'P1',
              score: s1,
              color: AppColors.player1,
              isWinner: !p2Won,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child:
                  Text('vs', style: TextStyle(color: AppColors.textMuted)),
            ),
            _ProgressiveScoreChip(
              name: game.player2?.name ?? 'P2',
              score: s2,
              color: AppColors.player2,
              isWinner: p2Won,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$winnerName wins the round!',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.chaosGold,
          ),
        ),
      ],
    );
  }
}

class _ProgressiveScoreChip extends StatelessWidget {
  final String name;
  final int score;
  final Color color;
  final bool isWinner;

  const _ProgressiveScoreChip({
    required this.name,
    required this.score,
    required this.color,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isWinner ? color.withAlpha(40) : Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner ? color : Colors.white24,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(name,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isWinner ? color : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
