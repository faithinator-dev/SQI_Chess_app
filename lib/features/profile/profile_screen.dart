import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/profile_model.dart';
import '../../core/repositories/profile_repository.dart';

import '../admin/admin_dashboard_screen.dart';
import 'player_statistics_screen.dart';
import 'game_history_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _repository = ProfileRepository();

  ProfileModel? _profile;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get isAdmin => _profile?.isAdmin ?? false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _repository.getCurrentProfile();

      if (!mounted) {
        return;
      }

      if (profile == null) {
        setState(() {
          _profile = null;
          _loading = false;
          _error = 'Your player profile could not be found.';
        });

        return;
      }

      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    if (error is PostgrestException) {
      return 'Profile request failed (${error.code}): ${error.message}';
    }

    return 'We could not load your profile: $error';
  }

  Future<void> _saveProfile({
    required String fullName,
    required String username,
    required String bio,
    required BuildContext sheetContext,
  }) async {
    setState(() {
      _saving = true;
    });

    try {
      final updated = await _repository.updateCurrentProfile(
        fullName: fullName,
        username: username,
        bio: bio,
      );

      if (!mounted) {
        return;
      }

      if (!sheetContext.mounted) return;
      Navigator.pop(sheetContext);

      setState(() {
        _profile = updated;
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlySaveError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _friendlySaveError(Object error) {
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();

      if (message.contains('duplicate') ||
          message.contains('unique') ||
          message.contains('username')) {
        return 'That username is already in use. Choose another one.';
      }

      return error.message;
    }

    return 'Could not save your profile. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileColors.background,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const _ProfileLoading()
            : _error != null
            ? _ProfileError(message: _error!, onRetry: _loadProfile)
            : _profile == null
            ? _ProfileError(
                message: 'No player profile is available.',
                onRetry: _loadProfile,
              )
            : _buildProfile(_profile!),
      ),
    );
  }

  Widget _buildProfile(ProfileModel profile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1050;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      desktop ? 34 : 17,
                      desktop ? 26 : 18,
                      desktop ? 34 : 17,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(context),
                        const SizedBox(height: 18),
                        _profileHero(context, profile, desktop),
                        const SizedBox(height: 18),
                        _ratingCard(context, profile, desktop),
                        const SizedBox(height: 18),
                        _statsGrid(profile, desktop),
                        const SizedBox(height: 24),
                        _sectionTitle(
                          'Recent games',
                          'View all',
                          () => _push(context, const GameHistoryScreen()),
                        ),
                        const SizedBox(height: 10),
                        _recentGames(profile),
                        const SizedBox(height: 24),
                        _sectionTitle(
                          'Achievements',
                          'See all',
                          () => _push(context, const AchievementsScreen()),
                        ),
                        const SizedBox(height: 10),
                        _achievementPreview(profile),
                        const SizedBox(height: 24),
                        _accountMenu(context),
                        if (profile.isAdmin) ...[
                          const SizedBox(height: 22),
                          _adminPortal(context),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROFILE',
                style: TextStyle(
                  color: _ProfileColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Your chess identity.',
                style: TextStyle(
                  color: _ProfileColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _push(context, const SettingsScreen()),
          tooltip: 'Settings',
          icon: const Icon(
            Icons.settings_outlined,
            color: _ProfileColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _profileHero(
    BuildContext context,
    ProfileModel profile,
    bool desktop,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(desktop ? 27 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ProfileColors.blue.withValues(alpha: 0.15),
            _ProfileColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _ProfileColors.blue.withValues(alpha: 0.11)),
      ),
      child: desktop
          ? Row(
              children: [
                _avatar(profile, 86),
                const SizedBox(width: 18),
                Expanded(child: _identity(profile)),
                const SizedBox(width: 20),
                _editButton(context, profile),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _avatar(profile, 72),
                    const SizedBox(width: 14),
                    Expanded(child: _identity(profile)),
                  ],
                ),
                const SizedBox(height: 16),
                _editButton(context, profile),
              ],
            ),
    );
  }

  Widget _avatar(ProfileModel profile, double size) {
    if (profile.avatarUrl != null && profile.avatarUrl!.trim().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profile.avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return _initialAvatar(profile, size);
          },
        ),
      );
    }

    return _initialAvatar(profile, size);
  }

  Widget _initialAvatar(ProfileModel profile, double size) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _ProfileColors.blue.withValues(alpha: 0.13),
            shape: BoxShape.circle,
            border: Border.all(
              color: _ProfileColors.blue.withValues(alpha: 0.20),
              width: 2,
            ),
          ),
          child: Text(
            profile.initials,
            style: TextStyle(
              color: _ProfileColors.blue,
              fontSize: size * 0.27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 3,
          child: Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              color: _ProfileColors.green,
              shape: BoxShape.circle,
              border: Border.all(color: _ProfileColors.surface, width: 3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _identity(ProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                profile.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ProfileColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (profile.isAdmin) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: _ProfileColors.purple,
                size: 18,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '@${profile.username}',
          style: const TextStyle(color: _ProfileColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _ProfilePill(text: profile.skillLevel, color: _ProfileColors.blue),
            if (profile.level != null && profile.level!.trim().isNotEmpty)
              _ProfilePill(text: profile.level!, color: _ProfileColors.purple),
            _ProfilePill(
              text: '${profile.gamesPlayed} games',
              color: _ProfileColors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _editButton(BuildContext context, ProfileModel profile) {
    return SizedBox(
      width: 140,
      child: OutlinedButton.icon(
        onPressed: () => _showEditProfile(context, profile),
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Edit profile'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _ProfileColors.blue,
          minimumSize: const Size(140, 45),
          side: BorderSide(color: _ProfileColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  Widget _ratingCard(BuildContext context, ProfileModel profile, bool desktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ProfileColors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _ProfileColors.border),
      ),
      child: desktop
          ? Row(
              children: [
                _ratingIcon(),
                const SizedBox(width: 14),
                Expanded(child: _ratingDetails(profile)),
                const SizedBox(width: 18),
                SizedBox(width: 170, child: _ratingProgress(profile)),
                const SizedBox(width: 18),
                _viewStatsButton(context),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ratingIcon(),
                    const SizedBox(width: 12),
                    Expanded(child: _ratingDetails(profile)),
                  ],
                ),
                const SizedBox(height: 15),
                _ratingProgress(profile),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  child: _viewStatsButton(context),
                ),
              ],
            ),
    );
  }

  Widget _ratingIcon() {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _ProfileColors.gold.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.emoji_events_outlined,
        color: _ProfileColors.gold,
        size: 23,
      ),
    );
  }

  Widget _ratingDetails(ProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CURRENT RATING',
          style: TextStyle(
            color: _ProfileColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          profile.formattedRating,
          style: const TextStyle(
            color: _ProfileColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          profile.preferredTimeControl ?? 'Rapid',
          style: const TextStyle(color: _ProfileColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _ratingProgress(ProfileModel profile) {
    const baseRating = 1000;
    const milestone = 1400;

    final progress =
        ((profile.chessRating - baseRating) / (milestone - baseRating)).clamp(
          0.0,
          1.0,
        );

    final remaining = milestone - profile.chessRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Next milestone',
                style: TextStyle(color: _ProfileColors.muted, fontSize: 12),
              ),
            ),
            Text(
              '1,400',
              style: TextStyle(
                color: _ProfileColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: _ProfileColors.surface3,
            valueColor: const AlwaysStoppedAnimation<Color>(
              _ProfileColors.blue,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          remaining > 0 ? '$remaining points to go' : 'Milestone reached',
          style: const TextStyle(color: _ProfileColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _viewStatsButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _push(context, const PlayerStatisticsScreen()),
      style: OutlinedButton.styleFrom(
        foregroundColor: _ProfileColors.blue,
        minimumSize: const Size(145, 45),
        side: BorderSide(color: _ProfileColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      child: const Text(
        'View statistics',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _statsGrid(ProfileModel profile, bool desktop) {
    final winRate = profile.gamesPlayed == 0
        ? '0%'
        : '${(profile.winRate * 100).round()}%';

    final stats = [
      (
        'GAMES',
        '${profile.gamesPlayed}',
        Icons.sports_esports_outlined,
        _ProfileColors.blue,
      ),
      (
        'WINS',
        '${profile.wins}',
        Icons.check_circle_outline_rounded,
        _ProfileColors.green,
      ),
      ('WIN RATE', winRate, Icons.percent_rounded, _ProfileColors.purple),
      (
        'STREAK',
        '${profile.currentStreak}',
        Icons.local_fire_department_outlined,
        _ProfileColors.gold,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = desktop ? 4 : 2;

        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _ProfileColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _ProfileColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: stat.$4.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(stat.$3, color: stat.$4, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.$1,
                            style: const TextStyle(
                              color: _ProfileColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            stat.$2,
                            style: const TextStyle(
                              color: _ProfileColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String title, String action, VoidCallback onAction) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ProfileColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            action,
            style: const TextStyle(
              color: _ProfileColors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _recentGames(ProfileModel profile) {
    if (profile.gamesPlayed == 0) {
      return _emptyCard(
        icon: Icons.sports_esports_outlined,
        title: 'No games yet',
        subtitle: 'Your completed competitive games will appear here.',
      );
    }

    return _emptyCard(
      icon: Icons.history_rounded,
      title: 'Game history is being connected',
      subtitle:
          'Your ${profile.gamesPlayed} recorded games will appear here once Game History is connected to Supabase.',
    );
  }

  Widget _achievementPreview(ProfileModel profile) {
    return _emptyCard(
      icon: Icons.workspace_premium_outlined,
      title: 'Achievements',
      subtitle:
          'Verified achievements will appear here as you complete Arena milestones.',
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ProfileColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ProfileColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _ProfileColors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _ProfileColors.blue, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ProfileColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _ProfileColors.muted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ProfileColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _ProfileColors.border),
      ),
      child: Column(
        children: [
          _menuItem(
            icon: Icons.bar_chart_rounded,
            color: _ProfileColors.blue,
            title: 'Statistics',
            subtitle: 'Rating and performance',
            onTap: () => _push(context, const PlayerStatisticsScreen()),
          ),
          _divider(),
          _menuItem(
            icon: Icons.history_rounded,
            color: _ProfileColors.purple,
            title: 'Game History',
            subtitle: 'Review completed games',
            onTap: () => _push(context, const GameHistoryScreen()),
          ),
          _divider(),
          _menuItem(
            icon: Icons.workspace_premium_outlined,
            color: _ProfileColors.gold,
            title: 'Achievements',
            subtitle: 'Milestones and badges',
            onTap: () => _push(context, const AchievementsScreen()),
          ),
          _divider(),
          _menuItem(
            icon: Icons.settings_outlined,
            color: _ProfileColors.muted,
            title: 'Settings',
            subtitle: 'Account and app preferences',
            onTap: () => _push(context, const SettingsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ProfileColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _ProfileColors.muted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _ProfileColors.muted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminPortal(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _ProfileColors.purple.withValues(alpha: 0.13),
            _ProfileColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _ProfileColors.purple.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _ProfileColors.purple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: _ProfileColors.purple,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN PORTAL',
                  style: TextStyle(
                    color: _ProfileColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage SQI Checkmate Arena',
                  style: TextStyle(
                    color: _ProfileColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Players, competitions, pairings, matches and settings.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ProfileColors.muted,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () {
              _push(context, const AdminDashboardScreen());
            },
            style: FilledButton.styleFrom(
              backgroundColor: _ProfileColors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(110, 43),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text(
              'Open Admin',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, ProfileModel profile) {
    final nameController = TextEditingController(text: profile.fullName);

    final usernameController = TextEditingController(text: profile.username);

    final bioController = TextEditingController(text: profile.bio ?? '');

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _ProfileColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  5,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 22,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Edit profile',
                          style: TextStyle(
                            color: _ProfileColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _editField(nameController, 'Display name'),
                      const SizedBox(height: 10),
                      _editField(usernameController, 'Username', prefix: '@'),
                      const SizedBox(height: 10),
                      _editField(bioController, 'Bio', maxLines: 3),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving
                              ? null
                              : () async {
                                  await _saveProfile(
                                    fullName: nameController.text,
                                    username: usernameController.text,
                                    bio: bioController.text,
                                    sheetContext: sheetContext,
                                  );

                                  if (mounted) {
                                    setSheetState(() {});
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: _ProfileColors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save changes',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      usernameController.dispose();
      bioController.dispose();
    });
  }

  Widget _editField(
    TextEditingController controller,
    String label, {
    String? prefix,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: _ProfileColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _ProfileColors.muted, fontSize: 14),
        prefixText: prefix,
        prefixStyle: const TextStyle(color: _ProfileColors.muted),
        filled: true,
        fillColor: _ProfileColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _ProfileColors.blue.withValues(alpha: 0.40),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: _ProfileColors.border, indent: 72);
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _ProfileColors.blue),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _ProfileColors.red.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off_outlined,
                color: _ProfileColors.red,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile unavailable',
              style: TextStyle(
                color: _ProfileColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ProfileColors.muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _ProfileColors.blue,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileColors {
  static const Color background = Color(0xFFF4F8FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFEDE9E2);
  static const Color surface3 = Color(0xFFE8F0EC);

  static const Color blue = Color(0xFF2D4A3E);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  static const Color purple = Color(0xFF9B7BFF);
  static const Color red = Color(0xFFFF5C70);

  static const Color muted = Color(0xFF737A74);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF454B46);
  static const Color border = Color(0xFFCCDEF0);
}
