import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final _p1Controller = TextEditingController(text: 'Player 1');
  final _p2Controller = TextEditingController(text: 'Player 2');

  String _mode = '2p';
  int _target = 10;

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    super.dispose();
  }

  void _startGame() async {
    final gameState = context.read<GameState>();

    await gameState.startGame(
      p1Name: _p1Controller.text.isEmpty ? 'Player 1' : _p1Controller.text,
      p2Name: _mode == '2p'
          ? (_p2Controller.text.isEmpty ? 'Player 2' : _p2Controller.text)
          : null,
      target: _target,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Game Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game Mode
              _SettingsGroup(
                label: 'GAME MODE',
                child: _ToggleRow(
                  options: const {'1p': 'Practice', '2p': 'Versus'},
                  selected: _mode,
                  onChanged: (v) => setState(() => _mode = v),
                ),
              ),
              const SizedBox(height: 12),

              // Target Score
              _SettingsGroup(
                label: 'TARGET SCORE',
                child: _ToggleRow(
                  options: const {'10': 'First to 10', '20': 'First to 20', '50': 'First to 50'},
                  selected: _target.toString(),
                  onChanged: (v) => setState(() => _target = int.parse(v)),
                ),
              ),
              const SizedBox(height: 12),

              // Player Names
              _SettingsGroup(
                label: 'PLAYER NAMES',
                child: Column(
                  children: [
                    TextField(
                      controller: _p1Controller,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.player1, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(hintText: 'Player 1'),
                    ),
                    if (_mode == '2p') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _p2Controller,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.player2, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(hintText: 'Player 2'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Start Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startGame,
                  child: const Text('START MATCH'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingsGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final Map<String, String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ToggleRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.entries.map((e) {
        final isSelected = e.key == selected;
        final idx = options.keys.toList().indexOf(e.key);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: idx > 0 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.cyan : AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.cyan : AppColors.cardBorder,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.cyan.withAlpha(80), blurRadius: 15)]
                      : null,
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
