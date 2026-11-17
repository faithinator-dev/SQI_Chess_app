import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/theme.dart';
import '../core/chess/bot_difficulty.dart';
import 'practice_game_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, this.playerName});

  final String? playerName;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  static const _unlockKey = 'bot_roster_unlocked_v1';
  static const _categories = [
    'Beginners',
    'Intermediate',
    'Masters',
    'Campus Rivals',
    'Creators',
    'Instructors',
    'Developer',
  ];

  static const _bots = <_ArenaBot>[
    _ArenaBot('timi_tactician', 'Timi Tactician', 'Beginners', 650, BotDifficulty.beginner, 'A friendly first match. Timi leaves room to learn and spots simple captures.', Icons.school_rounded, 'Learns piece safety and basic captures.'),
    _ArenaBot('zain_opening', 'Zain Opening Ace', 'Beginners', 720, BotDifficulty.beginner, 'A calm opponent who likes getting pieces developed before attacking.', Icons.auto_stories_rounded, 'Opening principles and development.'),
    _ArenaBot('amara_quickstep', 'Amara Quickstep', 'Beginners', 780, BotDifficulty.beginner, 'Quick games with clear chances to practise forks and checks.', Icons.bolt_rounded, 'Checks, forks and simple tactics.'),
    _ArenaBot('kola_endgame', 'Kola Endgame', 'Beginners', 850, BotDifficulty.beginner, 'A patient learner who helps you practise converting a small advantage.', Icons.flag_rounded, 'King activity and basic endings.'),
    _ArenaBot('ayo_steadyhand', 'Ayo Steadyhand', 'Intermediate', 950, BotDifficulty.intermediate, 'A balanced rival who rewards careful, consistent play.', Icons.balance_rounded, 'Safer moves and piece coordination.'),
    _ArenaBot('nneka_nimble', 'Nneka Nimble', 'Intermediate', 1050, BotDifficulty.intermediate, 'Looks for tactical chances and makes you calculate before committing.', Icons.flash_on_rounded, 'Calculation and tactical awareness.'),
    _ArenaBot('femi_forkmaster', 'Femi Forkmaster', 'Intermediate', 1150, BotDifficulty.intermediate, 'Enjoys forks, pins and practical attacks on loose pieces.', Icons.device_hub_rounded, 'Forks, pins and double attacks.'),
    _ArenaBot('sade_strategist', 'Sade Strategist', 'Intermediate', 1250, BotDifficulty.intermediate, 'Builds a steady position and asks you to make a long-term plan.', Icons.route_rounded, 'Planning, space and pawn structure.'),
    _ArenaBot('adaking', 'AdaKing', 'Masters', 1450, BotDifficulty.advanced, 'A sharp tournament-style opponent inspired by the Arena match screens.', Icons.workspace_premium_rounded, 'Initiative, tactics and active pieces.'),
    _ArenaBot('knightrider', 'KnightRider', 'Masters', 1550, BotDifficulty.advanced, 'An adventurous player who looks for outposts and attacking routes.', Icons.directions_rounded, 'Knight manoeuvres and attack.'),
    _ArenaBot('endgamepro', 'EndgamePro', 'Masters', 1650, BotDifficulty.advanced, 'Trades into technical positions and tests your endgame precision.', Icons.flag_circle_rounded, 'Conversion and endgame technique.'),
    _ArenaBot('boardking', 'BoardKing', 'Masters', 1750, BotDifficulty.expert, 'A demanding opponent for players ready to defend accurately.', Icons.military_tech_rounded, 'Defence, calculation and counterplay.'),
    _ArenaBot('campus_ayo', 'Ayo O', 'Campus Rivals', 1000, BotDifficulty.intermediate, 'A popular campus-style rival who enjoys open positions.', Icons.people_alt_rounded, 'Open games and active development.'),
    _ArenaBot('kemimoves', 'Kemi Moves', 'Campus Rivals', 1100, BotDifficulty.intermediate, 'A thoughtful campus rival who takes time to find the right square.', Icons.psychology_alt_rounded, 'Piece placement and positional play.'),
    _ArenaBot('campus_kings', 'Campus Kings', 'Campus Rivals', 1200, BotDifficulty.intermediate, 'A lively club opponent who likes to keep the game balanced.', Icons.groups_rounded, 'Balanced play and tactical chances.'),
    _ArenaBot('sqi_sharp', 'SQI Sharp', 'Campus Rivals', 1300, BotDifficulty.advanced, 'A quick campus challenge that punishes careless moves.', Icons.bolt_rounded, 'Tempo and tactical discipline.'),
    _ArenaBot('creator_openfile', 'OpenFile', 'Creators', 1200, BotDifficulty.intermediate, 'A creative opponent who likes open files and surprising ideas.', Icons.create_rounded, 'Open files and imaginative play.'),
    _ArenaBot('creator_queen', 'QueenSide', 'Creators', 1350, BotDifficulty.advanced, 'A creator persona who builds pressure on the queenside.', Icons.auto_awesome_rounded, 'Queenside plans and pawn breaks.'),
    _ArenaBot('creator_check', 'Checkmate Muse', 'Creators', 1450, BotDifficulty.advanced, 'An attacking creator persona who searches for forcing moves.', Icons.palette_rounded, 'Forcing lines and attacking patterns.'),
    _ArenaBot('creator_pixel', 'Pixel Gambit', 'Creators', 1550, BotDifficulty.advanced, 'A playful creator persona with a taste for gambits and initiative.', Icons.draw_rounded, 'Gambits and initiative.'),
    _ArenaBot('coach_ada', 'Coach Ada', 'Instructors', 900, BotDifficulty.beginner, 'A supportive instructor persona who gives you room to practise fundamentals.', Icons.menu_book_rounded, 'Piece safety and opening habits.'),
    _ArenaBot('coach_bello', 'Coach Bello', 'Instructors', 1100, BotDifficulty.intermediate, 'A steady instructor persona for building tactical confidence.', Icons.cast_for_education_rounded, 'Tactics and calculation.'),
    _ArenaBot('coach_chika', 'Coach Chika', 'Instructors', 1300, BotDifficulty.advanced, 'A practical instructor persona who tests your positional judgement.', Icons.school_rounded, 'Strategy and positional judgement.'),
    _ArenaBot('coach_daniel', 'Coach Daniel', 'Instructors', 1500, BotDifficulty.advanced, 'A challenging instructor persona who asks you to convert advantages.', Icons.workspace_premium_rounded, 'Conversion and endgames.'),
    _ArenaBot('faith_tolu', 'Faith Tolu', 'Developer', 1300, BotDifficulty.creator, 'The SQI Checkmate Arena creator. Take on the developer bot and see if you can win.', Icons.code_rounded, 'Creator challenge and deeper calculation.'),
  ];

  String _selectedCategory = _categories.first;
  Set<String> _unlocked = {'timi_tactician'};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUnlocks();
  }

  Future<void> _loadUnlocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_unlockKey);
      if (!mounted) return;
      setState(() {
        if (saved != null) _unlocked = {...saved, 'timi_tactician'};
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isUnlocked(_ArenaBot bot) => _unlocked.contains(bot.id);

  @override
  Widget build(BuildContext context) {
    final visibleBots = _bots.where((bot) => bot.category == _selectedCategory).toList();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Play computer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            SizedBox(height: 3),
            Text('Meet your next chess rival', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.blue,
        onRefresh: _loadUnlocks,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _heroCard(),
            const SizedBox(height: 22),
            Row(children: [
              const Expanded(child: Text('Explore bots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              Text('${_unlocked.length}/${_bots.length} unlocked', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    showCheckmark: false,
                    labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
                    selectedColor: const Color(0xFF244777),
                    backgroundColor: AppTheme.surface,
                    side: BorderSide(color: selected ? AppTheme.blue.withValues(alpha: .55) : AppTheme.divider),
                    onSelected: (_) => setState(() => _selectedCategory = category),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleBots.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  childAspectRatio: .82,
                ),
                itemBuilder: (context, index) => _botCard(visibleBots[index]),
              ),
            const SizedBox(height: 15),
            const Text('Win your current challenge to unlock the next rival.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(colors: [Color(0xFF1C385F), Color(0xFF142642)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      border: Border.all(color: AppTheme.blue.withValues(alpha: .22)),
    ),
    child: Row(children: [
      Container(width: 50, height: 50, decoration: BoxDecoration(color: AppTheme.blue.withValues(alpha: .18), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.smart_toy_outlined, color: AppTheme.blueLight, size: 27)),
      const SizedBox(width: 13),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Build your streak', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        SizedBox(height: 4),
        Text('Beat a bot to reveal the next opponent. Choose a level that fits your game.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
      ])),
    ]),
  );

  Widget _botCard(_ArenaBot bot) {
    final unlocked = _isUnlocked(bot);
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => _showBotDetails(bot),
      child: Ink(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: unlocked ? AppTheme.divider : AppTheme.divider.withValues(alpha: .65))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: (unlocked ? AppTheme.blue : AppTheme.textMuted).withValues(alpha: .16), borderRadius: BorderRadius.circular(13)), child: Icon(unlocked ? bot.icon : Icons.lock_outline_rounded, color: unlocked ? AppTheme.blueLight : AppTheme.textMuted, size: 21)),
            const Spacer(),
            Icon(unlocked ? Icons.chevron_right_rounded : Icons.lock_rounded, color: unlocked ? AppTheme.textMuted : AppTheme.gold, size: 17),
          ]),
          const Spacer(),
          Text(bot.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text('${bot.rating} rating', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 9),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: unlocked ? AppTheme.blue.withValues(alpha: .12) : AppTheme.elevated, borderRadius: BorderRadius.circular(8)), child: Text(unlocked ? 'READY TO PLAY' : 'LOCKED', style: TextStyle(color: unlocked ? AppTheme.blueLight : AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .4))),
        ]),
      ),
    );
  }

  void _showBotDetails(_ArenaBot bot) {
    final unlocked = _isUnlocked(bot);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 27, backgroundColor: AppTheme.blue.withValues(alpha: .16), child: Icon(bot.icon, color: AppTheme.blueLight, size: 25)),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(bot.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('${bot.category}  ·  ${bot.rating} rating', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))])),
              if (!unlocked) const Icon(Icons.lock_outline_rounded, color: AppTheme.gold),
            ]),
            const SizedBox(height: 17),
            Text(bot.bio, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
            const SizedBox(height: 14),
            Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: AppTheme.elevated, borderRadius: BorderRadius.circular(13)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('WHAT YOU’LL PRACTISE', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .6)), const SizedBox(height: 5), Text(bot.focus, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))])),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: unlocked ? () { Navigator.pop(sheetContext); _chooseSide(bot); } : null, icon: Icon(unlocked ? Icons.play_arrow_rounded : Icons.lock_rounded), label: Text(unlocked ? 'Challenge ${bot.name}' : 'Beat the previous bot to unlock'))),
          ]),
        ),
      ),
    );
  }

  void _chooseSide(_ArenaBot bot) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Choose your side', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 5),
        Text('Play ${bot.name} (${bot.rating} rating).', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 15),
        for (final option in [(PlayerSideChoice.white, 'Play as White', Icons.circle_outlined), (PlayerSideChoice.black, 'Play as Black', Icons.circle), (PlayerSideChoice.random, 'Random side', Icons.shuffle_rounded)])
          Padding(padding: const EdgeInsets.only(bottom: 8), child: OutlinedButton.icon(onPressed: () { Navigator.pop(sheetContext); Navigator.push(context, MaterialPageRoute(builder: (_) => PracticeGameScreen(level: bot.difficulty == BotDifficulty.creator ? 'creator' : bot.difficulty.title, botId: bot.id, botName: bot.name, playerName: widget.playerName, sideChoice: option.$1))).then((_) => _loadUnlocks()); }, icon: Icon(option.$3), label: Text(option.$2), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)))),
      ]))),
    );
  }
}

class _ArenaBot {
  const _ArenaBot(this.id, this.name, this.category, this.rating, this.difficulty, this.bio, this.icon, this.focus);
  final String id;
  final String name;
  final String category;
  final int rating;
  final BotDifficulty difficulty;
  final String bio;
  final IconData icon;
  final String focus;
}
