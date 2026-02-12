import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _db = DatabaseHelper();
  List<Player> _players = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players = await _db.getAllPlayers();
    setState(() {
      _players = players;
      _loading = false;
    });
  }

  Future<void> _addPlayer() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('New Player'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Player name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      await _db.getOrCreatePlayer(name.trim());
      _loadPlayers();
    }
  }

  Future<void> _deletePlayer(Player player) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Delete ${player.name}?'),
        content: const Text('This will remove the player and their stats.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.miss)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deletePlayer(player.id!);
      _loadPlayers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addPlayer,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _players.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🎯',
                        style: TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No players yet',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Players are created automatically\nwhen you start a game.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    return _PlayerTile(
                      player: player,
                      onDelete: () => _deletePlayer(player),
                    );
                  },
                ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final Player player;
  final VoidCallback onDelete;

  const _PlayerTile({required this.player, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final winRate = player.gamesPlayed > 0
        ? (player.gamesWon / player.gamesPlayed * 100).round()
        : 0;
    final hitRate = player.totalChallengesAttempted > 0
        ? (player.totalChallengesHit / player.totalChallengesAttempted * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.player1.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.player1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniStat(label: 'Games', value: '${player.gamesPlayed}'),
                    const SizedBox(width: 12),
                    _MiniStat(label: 'Win%', value: '$winRate%'),
                    const SizedBox(width: 12),
                    _MiniStat(label: 'Hit%', value: '$hitRate%'),
                    const SizedBox(width: 12),
                    _MiniStat(label: 'Streak', value: '${player.bestStreak}'),
                  ],
                ),
              ],
            ),
          ),

          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
