import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  static const Color danger = Color(0xFFFF5C70);
  static const Color white = Color(0xFF1A1A1A);
  static const Color purple = Color(0xFF9B7BFF);

  // ============================================================
  // SETTINGS STATE
  // ============================================================

  bool _autoMatchmaking = true;
  bool _crossLevelMatchmaking = true;
  bool _allowSpectators = true;
  bool _autoRecordGames = true;
  bool _publicGameHistory = true;
  bool _maintenanceMode = false;
  bool _registrationEnabled = true;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _soundEnabled = true;

  String _defaultTimeControl = '10+5';
  String _defaultSkillLevel = 'Intermediate';
  String _defaultCompetitionFormat = 'Swiss';
  String _language = 'English';
  String _timezone = 'Africa/Lagos';

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1050;
    final isTablet = width >= 700 && width < 1050;

    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(isDesktop),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop
                ? 32
                : isTablet
                ? 24
                : 16,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: background,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: isDesktop ? 32 : 16,
      title: Row(
        children: [
          if (!isDesktop)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: white),
            ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: blue.withValues(alpha: 0.22)),
            ),
            child: const Icon(Icons.settings_rounded, color: blue, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Admin Settings',
            style: TextStyle(
              color: white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Row(
              children: [
                _statusBadge(),
                const SizedBox(width: 12),
                _saveButton(),
              ],
            ),
          )
        else
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save_rounded, color: blue),
          ),
      ],
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: green.withValues(alpha: 0.16)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: green, size: 14),
          SizedBox(width: 6),
          Text(
            'System Operational',
            style: TextStyle(
              color: green,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return ElevatedButton.icon(
      onPressed: _saveSettings,
      icon: const Icon(Icons.save_rounded, size: 17),
      label: const Text('Save Changes'),
      style: ElevatedButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 230, child: _buildSettingsNavigation()),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(),
              const SizedBox(height: 24),
              _buildGeneralSection(),
              const SizedBox(height: 20),
              _buildCompetitionSection(),
              const SizedBox(height: 20),
              _buildGameSection(),
              const SizedBox(height: 20),
              _buildNotificationSection(),
              const SizedBox(height: 20),
              _buildSystemSection(),
              const SizedBox(height: 20),
              _buildDangerSection(),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 24),
        _buildGeneralSection(),
        const SizedBox(height: 20),
        _buildCompetitionSection(),
        const SizedBox(height: 20),
        _buildGameSection(),
        const SizedBox(height: 20),
        _buildNotificationSection(),
        const SizedBox(height: 20),
        _buildSystemSection(),
        const SizedBox(height: 20),
        _buildDangerSection(),
      ],
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Platform Settings',
          style: TextStyle(
            color: white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Configure competition rules, matchmaking, games and platform behaviour.',
          style: TextStyle(color: muted.withValues(alpha: 0.9), fontSize: 14),
        ),
      ],
    );
  }

  // ============================================================
  // SETTINGS NAVIGATION
  // ============================================================

  Widget _buildSettingsNavigation() {
    final items = [
      {'icon': Icons.tune_rounded, 'title': 'General'},
      {'icon': Icons.emoji_events_rounded, 'title': 'Competitions'},
      {'icon': Icons.sports_esports_rounded, 'title': 'Games'},
      {'icon': Icons.notifications_rounded, 'title': 'Notifications'},
      {'icon': Icons.dns_rounded, 'title': 'System'},
      {'icon': Icons.warning_rounded, 'title': 'Danger Zone'},
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: _settingsNavItem(
                items[i]['icon'] as IconData,
                items[i]['title'] as String,
                i == 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _settingsNavItem(IconData icon, String title, bool selected) {
    return InkWell(
      onTap: () {
        _showSnackBar('$title settings selected.');
      },
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? blue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? blue : muted, size: 18),
            const SizedBox(width: 11),
            Text(
              title,
              style: TextStyle(
                color: selected ? white : muted,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GENERAL
  // ============================================================

  Widget _buildGeneralSection() {
    return _settingsCard(
      icon: Icons.tune_rounded,
      iconColor: blue,
      title: 'General Settings',
      subtitle: 'Basic platform configuration and localization.',
      children: [
        _settingDropdown(
          icon: Icons.language_rounded,
          title: 'Platform Language',
          subtitle: 'Default language used across the admin platform.',
          value: _language,
          items: const ['English', 'French', 'Spanish', 'Portuguese'],
          onChanged: (value) {
            setState(() {
              _language = value;
            });
          },
        ),
        _divider(),
        _settingDropdown(
          icon: Icons.public_rounded,
          title: 'Timezone',
          subtitle: 'Timezone used for competition schedules and timestamps.',
          value: _timezone,
          items: const [
            'Africa/Lagos',
            'Africa/Accra',
            'Africa/Nairobi',
            'UTC',
          ],
          onChanged: (value) {
            setState(() {
              _timezone = value;
            });
          },
        ),
        _divider(),
        _settingSwitch(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Player Registration',
          subtitle: 'Allow new players to create arena accounts.',
          value: _registrationEnabled,
          onChanged: (value) {
            setState(() {
              _registrationEnabled = value;
            });
          },
        ),
        _divider(),
        _settingSwitch(
          icon: Icons.notifications_active_rounded,
          title: 'Platform Notifications',
          subtitle: 'Enable system-wide platform notifications.',
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // COMPETITION
  // ============================================================

  Widget _buildCompetitionSection() {
    return _settingsCard(
      icon: Icons.emoji_events_rounded,
      iconColor: gold,
      title: 'Competition Settings',
      subtitle: 'Default rules and matchmaking behaviour.',
      children: [
        _settingSwitch(
          icon: Icons.auto_awesome_rounded,
          title: 'Automatic Matchmaking',
          subtitle: 'Automatically pair players when they enter matchmaking.',
          value: _autoMatchmaking,
          onChanged: (value) {
            setState(() {
              _autoMatchmaking = value;
            });
          },
        ),
        _divider(),
        _settingSwitch(
          icon: Icons.compare_arrows_rounded,
          title: 'Cross-Level Matchmaking',
          subtitle: 'Allow players to be matched across nearby skill levels.',
          value: _crossLevelMatchmaking,
          onChanged: (value) {
            setState(() {
              _crossLevelMatchmaking = value;
            });
          },
        ),
        _divider(),
        _settingDropdown(
          icon: Icons.speed_rounded,
          title: 'Default Skill Level',
          subtitle: 'Skill level used when creating a new competition.',
          value: _defaultSkillLevel,
          items: const ['Beginner', 'Intermediate', 'Advanced', 'All Levels'],
          onChanged: (value) {
            setState(() {
              _defaultSkillLevel = value;
            });
          },
        ),
        _divider(),
        _settingDropdown(
          icon: Icons.timer_rounded,
          title: 'Default Time Control',
          subtitle: 'Default clock setting for newly created matches.',
          value: _defaultTimeControl,
          items: const ['3+2', '5+3', '10+0', '10+5', '15+10', '30+0'],
          onChanged: (value) {
            setState(() {
              _defaultTimeControl = value;
            });
          },
        ),
        _divider(),
        _settingDropdown(
          icon: Icons.account_tree_rounded,
          title: 'Default Competition Format',
          subtitle: 'Default tournament format for new competitions.',
          value: _defaultCompetitionFormat,
          items: const ['Swiss', 'Arena', 'Knockout', 'Round Robin'],
          onChanged: (value) {
            setState(() {
              _defaultCompetitionFormat = value;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // GAME SETTINGS
  // ============================================================

  Widget _buildGameSection() {
    return _settingsCard(
      icon: Icons.sports_esports_rounded,
      iconColor: purple,
      title: 'Game Settings',
      subtitle: 'Control gameplay, spectators and recorded matches.',
      children: [
        _settingSwitch(
          icon: Icons.visibility_rounded,
          title: 'Allow Spectators',
          subtitle: 'Allow users to watch active competitive games.',
          value: _allowSpectators,
          onChanged: (value) {
            setState(() {
              _allowSpectators = value;
            });
          },
        ),
        _divider(),
        _settingSwitch(
          icon: Icons.video_camera_back_rounded,
          title: 'Automatic Game Recording',
          subtitle: 'Automatically save every competitive game for review.',
          value: _autoRecordGames,
          onChanged: (value) {
            setState(() {
              _autoRecordGames = value;
            });
          },
        ),
        _divider(),
        _settingSwitch(
          icon: Icons.history_rounded,
          title: 'Public Game History',
          subtitle: 'Allow completed games to appear in public archives.',
          value: _publicGameHistory,
          onChanged: (value) {
            setState(() {
              _publicGameHistory = value;
            });
          },
        ),
        _divider(),
        _settingSwitch(
          icon: Icons.volume_up_rounded,
          title: 'Game Sounds',
          subtitle: 'Enable sound effects during active matches.',
          value: _soundEnabled,
          onChanged: (value) {
            setState(() {
              _soundEnabled = value;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Widget _buildNotificationSection() {
    return _settingsCard(
      icon: Icons.notifications_rounded,
      iconColor: green,
      title: 'Notification Settings',
      subtitle: 'Configure how administrators receive alerts.',
      children: [
        _settingSwitch(
          icon: Icons.email_rounded,
          title: 'Email Notifications',
          subtitle: 'Receive important system and competition alerts by email.',
          value: _emailNotifications,
          onChanged: (value) {
            setState(() {
              _emailNotifications = value;
            });
          },
        ),
        _divider(),
        _settingSwitch(
          icon: Icons.phone_android_rounded,
          title: 'Push Notifications',
          subtitle: 'Receive real-time notifications on supported devices.',
          value: _pushNotifications,
          onChanged: (value) {
            setState(() {
              _pushNotifications = value;
            });
          },
        ),
        _divider(),
        _notificationRow(
          Icons.warning_amber_rounded,
          'Match Alerts',
          'Live match interruptions and critical game events.',
          true,
          gold,
        ),
        _divider(),
        _notificationRow(
          Icons.emoji_events_rounded,
          'Competition Alerts',
          'Competition starts, finishes and registration updates.',
          true,
          blue,
        ),
        _divider(),
        _notificationRow(
          Icons.security_rounded,
          'Security Alerts',
          'Important account and platform security events.',
          true,
          danger,
        ),
      ],
    );
  }

  // ============================================================
  // SYSTEM
  // ============================================================

  Widget _buildSystemSection() {
    return _settingsCard(
      icon: Icons.dns_rounded,
      iconColor: blue,
      title: 'System',
      subtitle: 'Platform health and operational controls.',
      children: [
        _systemStatusRow(
          Icons.cloud_done_rounded,
          'Database',
          'Connected',
          green,
        ),
        _divider(),
        _systemStatusRow(
          Icons.sync_rounded,
          'Realtime Service',
          'Operational',
          green,
        ),
        _divider(),
        _systemStatusRow(
          Icons.shield_rounded,
          'Authentication',
          'Operational',
          green,
        ),
        _divider(),
        _systemStatusRow(
          Icons.video_library_rounded,
          'Recording Service',
          'Operational',
          green,
        ),
        _divider(),
        _systemStatusRow(
          Icons.memory_rounded,
          'API Service',
          'Operational',
          green,
        ),
        _divider(),
        _settingSwitch(
          icon: Icons.build_circle_rounded,
          title: 'Maintenance Mode',
          subtitle: 'Temporarily prevent players from accessing the platform.',
          value: _maintenanceMode,
          dangerSwitch: true,
          onChanged: (value) {
            _confirmMaintenanceMode(value);
          },
        ),
      ],
    );
  }

  // ============================================================
  // DANGER ZONE
  // ============================================================

  Widget _buildDangerSection() {
    return Container(
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: danger.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: danger,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danger Zone',
                        style: TextStyle(
                          color: white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'These actions can affect the entire platform.',
                        style: TextStyle(color: muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: danger.withValues(alpha: 0.12)),
          _dangerAction(
            icon: Icons.restart_alt_rounded,
            title: 'Reset Competition Data',
            subtitle: 'Competition data management is not connected.',
            buttonText: 'Reset',
            onTap: _resetCompetitionData,
          ),
          Divider(height: 1, color: danger.withValues(alpha: 0.12)),
          _dangerAction(
            icon: Icons.delete_sweep_rounded,
            title: 'Clear Game Recordings',
            subtitle: 'Delete all stored game recordings from the platform.',
            buttonText: 'Clear',
            onTap: _clearRecordings,
          ),
          Divider(height: 1, color: danger.withValues(alpha: 0.12)),
          _dangerAction(
            icon: Icons.delete_forever_rounded,
            title: 'Delete Platform Data',
            subtitle: 'Permanently remove all platform data and accounts.',
            buttonText: 'Delete',
            onTap: _deletePlatformData,
            destructive: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GENERIC SETTINGS CARD
  // ============================================================

  Widget _settingsCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.055)),
          ...children,
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.045),
      indent: 72,
    );
  }

  // ============================================================
  // SWITCH
  // ============================================================

  Widget _settingSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool dangerSwitch = false,
  }) {
    final color = dangerSwitch ? danger : blue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveThumbColor: muted,
            inactiveTrackColor: surfaceLight,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _settingDropdown({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: blue, size: 18),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 125),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                dropdownColor: surfaceLight,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: muted,
                  size: 18,
                ),
                style: const TextStyle(
                  color: white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (selected) {
                  if (selected != null) {
                    onChanged(selected);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICATION ROW
  // ============================================================

  Widget _notificationRow(
    IconData icon,
    String title,
    String subtitle,
    bool enabled,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: muted, fontSize: 14),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (_) {
              _showSnackBar('$title preference updated.');
            },
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveThumbColor: muted,
            inactiveTrackColor: surfaceLight,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SYSTEM STATUS
  // ============================================================

  Widget _systemStatusRow(
    IconData icon,
    String title,
    String status,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DANGER ACTION
  // ============================================================

  Widget _dangerAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: danger, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: danger,
              side: BorderSide(
                color: danger.withValues(alpha: destructive ? 0.4 : 0.22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIRMATION DIALOGS
  // ============================================================

  void _confirmMaintenanceMode(bool value) {
    if (!value) {
      setState(() {
        _maintenanceMode = false;
      });
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: gold),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Enable Maintenance Mode?',
                  style: TextStyle(
                    color: white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Players will temporarily be unable to access competitive features while maintenance mode is active.',
            style: TextStyle(color: muted, fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: muted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  _maintenanceMode = true;
                });

                _showSnackBar('Maintenance mode enabled.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: background,
              ),
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  void _resetCompetitionData() {
    _showSnackBar('Competition reset is unavailable; no data was changed.');
  }

  void _clearRecordings() {
    _showSnackBar('Recording cleanup is unavailable; no data was changed.');
  }

  void _deletePlatformData() {
    _showSnackBar(
      'Platform-wide deletion is not available from this client. No data was changed.',
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _saveSettings() {
    _showSnackBar('Admin settings saved successfully.');
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: surfaceLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
