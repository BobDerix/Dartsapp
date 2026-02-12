import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _db = DatabaseHelper();
  List<_GameHistoryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final games = await _db.getRecentGames(limit: 50);
    final entries = <_GameHistoryEntry>[];

    for (final game in games) {
      final p1 = await _db.getPlayer(game.player1Id);
      final p2 = game.player2Id != null ? await _db.getPlayer(game.player2Id!) : null;
      final winner = game.winnerId != null ? await _db.getPlayer(game.winnerId!) : null;

      entries.add(_GameHistoryEntry(
        session: game,
        player1: p1,
        player2: p2,
        winner: winner,
      ));
    }

    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      const Text(
                        'No games played yet',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    return _HistoryTile(entry: _entries[index]);
                  },
                ),
    );
  }
}

class _GameHistoryEntry {
  final GameSession session;
  final Player? player1;
  final Player? player2;
  final Player? winner;

  _GameHistoryEntry({
    required this.session,
    this.player1,
    this.player2,
    this.winner,
  });
}

class _HistoryTile extends StatelessWidget {
  final _GameHistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final game = entry.session;
    final p1Name = entry.player1?.name ?? 'Player 1';
    final p2Name = entry.player2?.name ?? 'CPU';
    final winnerName = entry.winner?.name;
    final dateStr = game.endedAt != null
        ? DateFormat('d MMM yyyy, HH:mm').format(game.endedAt!)
        : 'In progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                game.isSinglePlayer ? 'Practice' : 'Versus',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Score display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      p1Name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: winnerName == p1Name ? AppColors.player1 : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${game.player1FinalScore}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: winnerName == p1Name ? AppColors.player1 : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'vs',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      p2Name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: winnerName == p2Name ? AppColors.player2 : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${game.player2FinalScore}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: winnerName == p2Name ? AppColors.player2 : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target: ${game.targetScore}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Text(
                '${game.totalRounds} rounds',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              if (winnerName != null)
                Text(
                  '🏆 $winnerName',
                  style: const TextStyle(fontSize: 12, color: AppColors.catFinish, fontWeight: FontWeight.w600),
                )
              else
                const Text(
                  'No winner',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
