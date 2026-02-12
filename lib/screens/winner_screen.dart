import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../game/game_state.dart';
import '../theme/app_theme.dart';
import 'game_setup_screen.dart';

class WinnerScreen extends StatefulWidget {
  const WinnerScreen({super.key});

  @override
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameState>();

    final winnerName = game.winner?.name ?? 'Nobody';
    final isSingle = game.isSinglePlayer;
    final p1Score = game.p1State.score;
    final p2Score = game.p2State.score;
    final p1Rate = (game.p1HitRate * 100).round();
    final p2Rate = (game.p2HitRate * 100).round();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 16),

                    // Winner card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(51)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isSingle ? 'Target Reached!' : '$winnerName Wins!',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isSingle ? '$p1Score points' : '$p1Score - $p2Score',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 12),

                          // Stats
                          _StatRow(
                            label: 'Rounds Played',
                            value: '${game.roundNumber}',
                          ),
                          const SizedBox(height: 8),
                          _StatRow(
                            label: '${game.player1?.name ?? "P1"} Accuracy',
                            value: '$p1Rate%',
                            valueColor: AppColors.player1,
                          ),
                          if (!isSingle) ...[
                            const SizedBox(height: 8),
                            _StatRow(
                              label: '${game.player2?.name ?? "P2"} Accuracy',
                              value: '$p2Rate%',
                              valueColor: AppColors.player2,
                            ),
                          ],
                          const SizedBox(height: 8),
                          _StatRow(
                            label: '${game.player1?.name ?? "P1"} Best Streak',
                            value: '${game.p1State.streak}',
                          ),
                          if (!isSingle) ...[
                            const SizedBox(height: 8),
                            _StatRow(
                              label: '${game.player2?.name ?? "P2"} Best Streak',
                              value: '${game.p2State.streak}',
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rematch
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const GameSetupScreen()),
                          );
                        },
                        child: const Text('PLAY AGAIN'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Back to menu
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          game.backToSetup();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF444444)),
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back to Menu'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 50,
              maxBlastForce: 25,
              minBlastForce: 5,
              gravity: 0.1,
              colors: const [
                AppColors.player1,
                AppColors.player2,
                AppColors.hit,
                AppColors.catFinish,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
