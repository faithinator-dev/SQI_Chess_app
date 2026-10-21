import 'package:flutter/material.dart';

import '../../core/repositories/admin_repository.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);

  final TextEditingController _searchController = TextEditingController();
  final AdminRepository _repository = AdminRepository();

  String _filter = 'All';
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _changingRole = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _repository.getPlayers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final message =
          error.toString().contains('permission denied') ||
              error.toString().contains('Admins can view all profiles')
          ? 'Administrator access is required. Apply the admin role migration and sign in with an authorized administrator account.'
          : error.toString();
      setState(() {
        _error = message;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();

    return _users.where((user) {
      final matchesSearch =
          query.isEmpty ||
          user['name'].toString().toLowerCase().contains(query) ||
          user['username'].toString().toLowerCase().contains(query) ||
          user['role'].toString().toLowerCase().contains(query);

      final matchesFilter =
          _filter == 'All' ||
          user['status'] == _filter ||
          user['level'] == _filter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Players',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: _loading ? null : _loadUsers,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh players',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 950;

            return SingleChildScrollView(
              padding: EdgeInsets.all(desktop ? 28 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(desktop),
                      const SizedBox(height: 22),
                      _summaryCards(desktop),
                      const SizedBox(height: 22),
                      _toolbar(desktop),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        _loadError()
                      else
                        desktop ? _desktopTable() : _mobileList(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(bool desktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Player Management',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'View, search and manage registered arena players.',
                style: TextStyle(fontSize: 20, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCards(bool desktop) {
    final cards = [
      _summary(
        '${_users.length}',
        'Total Players',
        Icons.people_alt_rounded,
        blue,
      ),
      _summary(
        '${_users.where((u) => u['status'] == 'Online').length}',
        'Online Now',
        Icons.wifi_rounded,
        green,
      ),
      _summary(
        '${_users.where((u) => u['status'] == 'Playing').length}',
        'Playing',
        Icons.sports_esports_rounded,
        gold,
      ),
      _summary(
        '${_users.where((u) {
          final created = u['joinedAt'] as DateTime?;
          return created != null && DateTime.now().difference(created).inDays < 7;
        }).length}',
        'New This Week',
        Icons.person_add_alt_1_rounded,
        const Color(0xFF9B7BFF),
      ),
    ];

    if (!desktop) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _summary(String value, String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(bool desktop) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: desktop
          ? Row(
              children: [
                Expanded(child: _searchField()),
                const SizedBox(width: 12),
                _filterButton(),
              ],
            )
          : Column(
              children: [
                _searchField(),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: _filterButton()),
              ],
            ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) {
        setState(() {});
      },
      style: const TextStyle(fontSize: 20, color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search name, username or role...',
        hintStyle: const TextStyle(fontSize: 20, color: muted),
        prefixIcon: const Icon(Icons.search_rounded, color: muted, size: 19),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded, color: muted, size: 17),
              )
            : null,
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
      ),
    );
  }

  Widget _filterButton() {
    return PopupMenuButton<String>(
      color: surfaceLight,
      onSelected: (value) {
        setState(() {
          _filter = value;
        });
      },
      itemBuilder: (context) {
        return [
              'All',
              'Online',
              'Playing',
              'Away',
              'Offline',
              'Admin',
              'Beginner',
              'Intermediate',
              'Advanced',
            ]
            .map(
              (filter) => PopupMenuItem<String>(
                value: filter,
                child: Text(
                  filter,
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            )
            .toList();
      },
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, color: muted, size: 17),
            const SizedBox(width: 8),
            Text(
              'Filter: $_filter',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: muted,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopTable() {
    final users = _filteredUsers;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _tableHeader(),
          if (users.isEmpty) _emptyState() else ...users.map(_tableRow),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 260,
            child: Text(
              'PLAYER',
              style: TextStyle(
                fontSize: 20,
                color: muted,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'RATING',
              style: TextStyle(
                fontSize: 20,
                color: muted,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'LEVEL',
              style: TextStyle(
                fontSize: 20,
                color: muted,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'GAMES',
              style: TextStyle(
                fontSize: 20,
                color: muted,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'STATUS',
              style: TextStyle(
                fontSize: 20,
                color: muted,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'ACTION',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 20,
                color: muted,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> user) {
    final statusColor = _statusColor(user['status']);

    return InkWell(
      onTap: () => _showUserDetails(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.045)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 260, child: _playerIdentity(user)),
            Expanded(
              child: Text(
                '${user['rating']}',
                style: const TextStyle(
                  fontSize: 20,
                  color: gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Text(
                user['level'],
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            Expanded(
              child: Text(
                '${user['games']}',
                style: const TextStyle(fontSize: 20, color: muted),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user['status'],
                    style: TextStyle(
                      fontSize: 20,
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => _showUserDetails(user),
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: muted,
                    size: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerIdentity(Map<String, dynamic> user) {
    final name = user['name'].toString();

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: blue.withValues(alpha: 0.13),
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              color: blue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${user['username']} | ${user['role'] == 'admin' ? 'Admin' : 'Player'}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileList() {
    final users = _filteredUsers;

    if (users.isEmpty) {
      return _emptyState();
    }

    return Column(children: users.map(_mobileCard).toList());
  }

  Widget _mobileCard(Map<String, dynamic> user) {
    final statusColor = _statusColor(user['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _playerIdentity(user),
              IconButton(
                onPressed: () => _showUserDetails(user),
                icon: const Icon(Icons.more_vert_rounded, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                _mobileStat('Rating', '${user['rating']}', gold),
                _mobileStat('Level', user['level'], Colors.white),
                _mobileStat('Games', '${user['games']}', muted),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'STATUS',
                        style: TextStyle(
                          fontSize: 20,
                          color: muted,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            user['status'],
                            style: TextStyle(
                              fontSize: 20,
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileStat(String title, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              color: muted,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_search_rounded, color: muted, size: 42),
          SizedBox(height: 12),
          Text(
            'No players found',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try changing your search or filter.',
            style: TextStyle(fontSize: 20, color: muted),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Online':
        return green;
      case 'Playing':
        return gold;
      default:
        return muted;
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 32,
                backgroundColor: blue.withValues(alpha: 0.15),
                child: Text(
                  user['name'].toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    color: blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user['name'],
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user['username'],
                style: const TextStyle(fontSize: 20, color: muted),
              ),
              const SizedBox(height: 22),
              _detailRow('Rating', '${user['rating']}'),
              _detailRow('Skill Level', user['level']),
              _detailRow('Games Played', '${user['games']}'),
              _detailRow('Status', user['status']),
              _detailRow(
                'Role',
                user['role'] == 'admin' ? 'Administrator' : 'Player',
              ),
              _detailRow('Joined', user['joined']),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _changingRole || user['id'] == null
                      ? null
                      : () => _confirmRoleChange(user),
                  icon: Icon(
                    user['role'] == 'admin'
                        ? Icons.remove_moderator
                        : Icons.admin_panel_settings,
                  ),
                  label: Text(
                    user['role'] == 'admin'
                        ? 'Remove admin access'
                        : 'Make administrator',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user['role'] == 'admin'
                        ? surfaceLight
                        : blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 20, color: muted)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadError() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, color: muted, size: 36),
        const SizedBox(height: 10),
        const Text(
          'Could not load player profiles',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _error ?? 'Unknown error',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, color: muted),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _loadUsers,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    ),
  );

  Future<void> _confirmRoleChange(Map<String, dynamic> user) async {
    final makingAdmin = user['role'] != 'admin';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surface,
        title: Text(
          makingAdmin ? 'Make administrator?' : 'Remove administrator access?',
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
        content: Text(
          '${user['name']} will ${makingAdmin ? 'gain' : 'lose'} administrator permissions.',
          style: const TextStyle(fontSize: 20, color: muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _changingRole = true);
    try {
      await _repository.setPlayerAdminRole(
        user['id'] as String,
        makeAdmin: makingAdmin,
      );
      if (!mounted) return;
      if (mounted) Navigator.of(context).pop();
      _showSnack(
        makingAdmin
            ? 'Administrator role granted.'
            : 'Administrator role removed.',
      );
      await _loadUsers();
    } catch (error) {
      if (!mounted) return;
      _showSnack('Role change failed: $error');
    } finally {
      if (mounted) setState(() => _changingRole = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: surfaceLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
