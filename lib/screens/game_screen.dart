import 'dart:async';
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

class _GameScreenState extends State<GameScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
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
              Column(
                children: [
                  // Header
                  _GameHeader(
                    onQuit: _onQuit,
                    onUndo: game.canUndo ? () => game.undo() : null,
                  ),

                  // Scoreboard
                  _Scoreboard(game: game),

                  // Commentary banner
                  if (game.showCommentary && game.commentaryText != null)
                    _CommentaryBanner(text: game.commentaryText!),

                  // Chaos card indicator (when active but dismissed)
                  if (game.activeChaosCard != null && !game.showingChaosCard)
                    _ChaosCardIndicator(card: game.activeChaosCard!),

                  // Challenge display
                  Expanded(
                    child: _ChallengeDisplay(challenge: game.currentChallenge),
                  ),

                  // Timer widget (for timer challenges)
                  if (game.currentChallenge?.hasTimer == true && !game.roundComplete)
                    _TimerWidget(
                      seconds: game.currentChallenge!.timerSeconds,
                      key: ValueKey('timer_${game.roundNumber}'),
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

  const _GameHeader({required this.onQuit, this.onUndo});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _HeaderButton(icon: Icons.close, onTap: onQuit),
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
            Icon(icon, color: onTap != null ? Colors.white70 : Colors.white24, size: 18),
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

class _CommentaryBanner extends StatelessWidget {
  final String text;
  const _CommentaryBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.commentaryBg, Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.chaosGold.withAlpha(77)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.chaosGold,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Chaos Card Indicator (small pill when active) ──

class _ChaosCardIndicator extends StatelessWidget {
  final ChaosCard card;
  const _ChaosCardIndicator({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.chaosBackground, Color(0xFF330066)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.chaosBorder, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(card.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            card.name,
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
              card.description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withAlpha(178),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnim = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
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
      animation: _controller,
      builder: (_, __) => GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          color: Colors.black.withAlpha((_opacityAnim.value * 200).toInt()),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.chaosBackground,
                      Color(0xFF330066),
                      AppColors.chaosBackground,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.chaosBorder, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.chaosBorder.withAlpha(100),
                      blurRadius: 30,
                      spreadRadius: 5,
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
                    Text(
                      'TAP TO CONTINUE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(102),
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
    );
  }
}

// ── Timer Widget ──

class _TimerWidget extends StatefulWidget {
  final int seconds;
  const _TimerWidget({super.key, required this.seconds});

  @override
  State<_TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<_TimerWidget> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > 0) {
        setState(() => _remaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = _remaining <= 5;
    final progress = _remaining / widget.seconds;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                color: isWarning ? AppColors.timerWarning : AppColors.timerNormal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$_remaining',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isWarning ? AppColors.timerWarning : AppColors.timerNormal,
                ),
              ),
              const Text(
                's',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withAlpha(26),
              valueColor: AlwaysStoppedAnimation(
                isWarning ? AppColors.timerWarning : AppColors.timerNormal,
              ),
              minHeight: 4,
            ),
          ),
        ],
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
              hitRate: game.p1HitRate,
              streak: game.p1State.streak,
              color: AppColors.player1,
              isActive: true,
            ),
          ),
          const SizedBox(width: 12),
          if (!game.isSinglePlayer)
            Expanded(
              child: _PlayerCard(
                name: game.player2?.name ?? 'P2',
                score: game.p2State.score,
                hitRate: game.p2HitRate,
                streak: game.p2State.streak,
                color: AppColors.player2,
                isActive: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String name;
  final int score;
  final double hitRate;
  final int streak;
  final Color color;
  final bool isActive;

  const _PlayerCard({
    required this.name,
    required this.score,
    required this.hitRate,
    required this.streak,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withAlpha(242),
        borderRadius: BorderRadius.circular(16),
        border: Border(top: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withAlpha(204),
              letterSpacing: 1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(hitRate * 100).round()}% Hit',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              AnimatedOpacity(
                opacity: streak >= 3 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '🔥 $streak',
                  style: TextStyle(fontSize: 11, color: AppColors.player2, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Challenge Display ──

class _ChallengeDisplay extends StatelessWidget {
  final Challenge? challenge;
  const _ChallengeDisplay({this.challenge});

  @override
  Widget build(BuildContext context) {
    if (challenge == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.categoryColor(challenge!.category.displayName),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                challenge!.category.displayName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Roulette spinner or emoji
            if (challenge!.isRoulette)
              _RouletteSpinner(key: ValueKey('roulette_${challenge!.text}'))
            else
              Text(
                challenge!.emoji,
                style: const TextStyle(fontSize: 64),
              ),
            const SizedBox(height: 12),

            // Challenge text
            Text(
              challenge!.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),

            // Difficulty dots
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < challenge!.difficulty
                        ? AppColors.catFinish
                        : Colors.white.withAlpha(51),
                  ),
                );
              }),
            ),

            // Timer/roulette badges
            if (challenge!.hasTimer || challenge!.isRoulette) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (challenge!.hasTimer)
                    _ChallengeBadge(
                      icon: Icons.timer,
                      label: '${challenge!.timerSeconds}s',
                      color: AppColors.timerWarning,
                    ),
                  if (challenge!.isRoulette)
                    const _ChallengeBadge(
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
        final currentIdx = (_rotation.value * totalCycles).floor() % _segments.length;
        final number = _segments[currentIdx];
        final isDone = _rotation.value >= 0.98;

        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                isDone ? AppColors.catBattle : const Color(0xFF2C3E50),
                const Color(0xFF1A1A1A),
              ],
            ),
            border: Border.all(
              color: isDone ? AppColors.chaosGold : AppColors.catBattle,
              width: 3,
            ),
            boxShadow: isDone
                ? [BoxShadow(color: AppColors.catBattle.withAlpha(100), blurRadius: 20)]
                : null,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: isDone ? 42 : 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
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
      decoration: const BoxDecoration(
        color: Color(0xFF222222),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
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
      case ChallengeType.countdown:
        return _HitMissControls(game: game);

      case ChallengeType.bestScore:
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
    final isJudge = game.currentChallenge?.type == ChallengeType.closest;

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
          child: ElevatedButton(
            onPressed: isReady
                ? () {
                    onConfetti();
                    game.confirmRound();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neutral,
              disabledBackgroundColor: AppColors.neutral.withAlpha(77),
            ),
            child: const Text('NEXT CHALLENGE  ➡'),
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
            color: widget.isActive
                ? widget.activeColor
                : const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                        color: widget.activeColor.withAlpha(102),
                        blurRadius: 10)
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
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: labelColor)),
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
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: labelColor)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            decoration: InputDecoration(
              hintText: isThreshold ? 'Score (target: $target, max 180)' : 'Enter score (max 180)',
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
              child: GestureDetector(
                onTap: () => game.setJudgeWinner(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.player1,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.player1?.name ?? 'Player 1',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => game.setJudgeWinner(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.player2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.player2?.name ?? 'Player 2',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
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
              color: const Color(0xFF555555),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Tie / Redo',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
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

class _EliminationPlayerRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: labelColor)),
            ),
            // Lives display
            ...List.generate(maxLives, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  i < lives ? Icons.favorite : Icons.favorite_border,
                  color: i < lives ? AppColors.miss : Colors.white24,
                  size: 20,
                ),
              );
            }),
            const Spacer(),
            Text(
              '$hits hits',
              style: const TextStyle(color: AppColors.hit, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (!isDone)
          Row(
            children: [
              const SizedBox(width: 80),
              Expanded(
                child: _ActionButton(
                  label: 'HIT',
                  isActive: false,
                  activeColor: AppColors.hit,
                  isLocked: false,
                  onTap: onHit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'MISS',
                  isActive: false,
                  activeColor: AppColors.miss,
                  isLocked: false,
                  onTap: onMiss,
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
                    color: lives > 0 ? AppColors.hit.withAlpha(51) : AppColors.miss.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: lives > 0 ? AppColors.hit : AppColors.miss,
                    ),
                  ),
                  child: Text(
                    lives > 0 ? 'SURVIVED ($hits hits)' : 'ELIMINATED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: lives > 0 ? AppColors.hit : AppColors.miss,
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
    if (bid != null && bid >= 1 && bid <= 9) {
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
          'Bid low to win! (1-9 darts)',
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
    final winnerColor = winnerIdx == 0 ? AppColors.player1 : AppColors.player2;
    final bid = winnerIdx == 0
        ? game.p1State.auctionBid
        : game.p2State.auctionBid;
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
              color: isHit ? AppColors.hit.withAlpha(51) : AppColors.miss.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isHit ? AppColors.hit : AppColors.miss),
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
                style: TextStyle(color: winnerColor, fontWeight: FontWeight.w700),
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
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: labelColor)),
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
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: labelColor)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            decoration: const InputDecoration(hintText: 'Bid (1-9)'),
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
                      border: Border.all(color: AppColors.player1.withAlpha(80)),
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
                  style: TextStyle(fontWeight: FontWeight.w700, color: currentColor),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: isP1Turn ? 'Set the target! (max 180)' : 'Beat ${game.progressiveTarget}! (max 180)',
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
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
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
              child: Text('vs', style: TextStyle(color: AppColors.textMuted)),
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
          Text(name, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
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
