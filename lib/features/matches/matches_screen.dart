import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sqi_chess_club/features/matches/lan_chess_match_screen.dart';
import 'package:sqi_chess_club/features/matches/matchmaking_screen.dart';
import 'package:sqi_chess_club/practice/practice_screen.dart';

import '../match/local_pvp_screen.dart';
import '../match/match_config.dart';
import '../match/match_mode.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  static const Color _background = Color(0xFFF4F8FD);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _blue = Color(0xFF1A6BB5);
  static const Color _green = Color(0xFF2E9E6E);
  static const Color _gold = Color(0xFFF5A623);
  static const Color _purple = Color(0xFF7B6FF0);
  static const Color _primary = Color(0xFF0D1B2E);
  static const Color _muted = Color(0xFF5E7A99);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'THE ARENA',
                style: TextStyle(
                  fontSize: 20,
                  color: _blue,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Play & Challenge',
              style: TextStyle(
                fontSize: 20,
                color: _primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Select your battlefield or resume ongoing clashes.',
              style: TextStyle(
                fontSize: 20,
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        toolbarHeight: 90,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            _HeroCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MatchmakingScreen()),
                );
              },
            ),
            const SizedBox(height: 18),
            const _SectionTitle(
              title: 'Play',
              subtitle: 'Start a new chess game',
            ),
            const SizedBox(height: 12),
            _PlayModeCard(
              icon: Icons.bolt_rounded,
              iconColor: _blue,
              title: 'Quick Match',
              subtitle: 'Find an online opponent automatically',
              trailing: '10+0',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MatchmakingScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _PlayModeCard(
              icon: Icons.people_alt_rounded,
              iconColor: _green,
              title: 'Friend',
              subtitle: 'Challenge a friend to a game',
              trailing: 'FRIEND',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MatchmakingScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _PlayModeCard(
              icon: Icons.phone_android_rounded,
              iconColor: _purple,
              title: 'Local PvP',
              subtitle: 'Two players on this device',
              trailing: 'LOCAL',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LocalPvpScreen(
                      config: MatchConfig(
                        mode: MatchMode.local,
                        initialTimeSeconds: 600,
                        incrementSeconds: 0,
                        whitePlayerName: 'Player 1',
                        blackPlayerName: 'Player 2',
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _PlayModeCard(
              icon: Icons.wifi_rounded,
              iconColor: _gold,
              title: 'LAN / Wi-Fi',
              subtitle: 'Play with someone on the same network',
              trailing: 'LAN',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LanLobbyScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _PlayModeCard(
              icon: Icons.smart_toy_rounded,
              iconColor: _purple,
              title: 'Play Computer',
              subtitle: 'Practice against a computer opponent',
              trailing: 'OFFLINE',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PracticeScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _PlayModeCard(
              icon: Icons.extension_rounded,
              iconColor: _gold,
              title: 'Puzzles',
              subtitle: 'Train your tactics and calculation',
              trailing: 'SOON',
              onTap: () => _showComingSoon(context, 'Puzzles'),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: .06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: _blue),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SQI Checkmate Arena',
                          style: TextStyle(
                            fontSize: 20,
                            color: _primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Play. Improve. Checkmate.',
                          style: TextStyle(fontSize: 20, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  static const Color _blue = Color(0xFF1A6BB5);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFF0D1B2E);
  static const Color _secondary = Color(0xFF2E4A66);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _blue.withValues(alpha: .25)),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(Icons.bolt_rounded, color: _blue, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Match',
                      style: TextStyle(
                        fontSize: 20,
                        color: _primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Jump straight into a competitive 10+0 game.',
                      style: TextStyle(
                        fontSize: 20,
                        color: _secondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _secondary,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  static const Color _primary = Color(0xFF0D1B2E);
  static const Color _muted = Color(0xFF5E7A99);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            color: _primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(fontSize: 20, color: _muted)),
      ],
    );
  }
}

class _PlayModeCard extends StatelessWidget {
  const _PlayModeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFF0D1B2E);
  static const Color _muted = Color(0xFF5E7A99);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .055)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        color: _primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 20, color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 20,
                    color: iconColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LAN LOBBY
// -----------------------------------------------------------------------------

class LanLobbyScreen extends StatefulWidget {
  const LanLobbyScreen({super.key});

  @override
  State<LanLobbyScreen> createState() => _LanLobbyScreenState();
}

class _LanLobbyScreenState extends State<LanLobbyScreen> {
  static const int _discoveryPort = 4041;

  final List<_NearbyLanGame> _games = [];
  final TextEditingController _manualIpController = TextEditingController();

  RawDatagramSocket? _udpSocket;
  Timer? _discoveryTimer;
  Timer? _cleanupTimer;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );

      if (!mounted) {
        socket.close();
        return;
      }

      _udpSocket = socket;
      socket.broadcastEnabled = true;

      socket.listen((event) {
        if (event != RawSocketEvent.read) return;

        final datagram = socket.receive();
        if (datagram == null) return;

        try {
          final message = jsonDecode(utf8.decode(datagram.data));

          if (message is! Map) return;
          if (message['type'] != 'sqi_lan_game') return;

          final hostId = message['hostId']?.toString();
          final name = message['name']?.toString();
          final port = int.tryParse(message['port']?.toString() ?? '');

          if (hostId == null || name == null || port == null) {
            return;
          }

          final game = _NearbyLanGame(
            hostId: hostId,
            name: name,
            host: datagram.address.address,
            port: port,
            roomCode: message['roomCode']?.toString() ?? '------',
            timeControl: message['timeControl']?.toString() ?? '10+0',
            updatedAt: DateTime.now(),
          );

          if (!mounted) return;

          setState(() {
            final index = _games.indexWhere(
              (item) => item.hostId == game.hostId,
            );

            if (index == -1) {
              _games.add(game);
            } else {
              _games[index] = game;
            }

            _loading = false;
          });
        } catch (_) {
          // Ignore malformed UDP packets.
        }
      });

      _sendDiscoveryRequest();

      _discoveryTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _sendDiscoveryRequest(),
      );

      _cleanupTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();

        if (!mounted) return;

        setState(() {
          _games.removeWhere(
            (game) => now.difference(game.updatedAt).inSeconds > 6,
          );
        });
      });

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not start LAN discovery.';
      });
    }
  }

  void _sendDiscoveryRequest() {
    final socket = _udpSocket;
    if (socket == null) return;

    try {
      final data = utf8.encode(jsonEncode({'type': 'sqi_discovery_request'}));

      socket.send(data, InternetAddress('255.255.255.255'), _discoveryPort);
    } catch (_) {}
  }

  void _openManualJoin() {
    final ip = _manualIpController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the host IP address first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LanJoinScreen(host: ip, port: 4040)),
    );
  }

  Future<void> _scanAndJoin() async {
    if (Platform.isWindows || Platform.isLinux) return;
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _LanQrScannerScreen()),
    );
    if (!mounted || value == null) return;
    final uri = Uri.tryParse(value.trim());
    final host = uri?.queryParameters['host']?.trim();
    final port = int.tryParse(uri?.queryParameters['port'] ?? '');
    final timeControl = uri?.queryParameters['time'] ?? '10+0';
    if (uri == null ||
        uri.scheme != 'sqi-lan' ||
        uri.host != 'join' ||
        host == null ||
        InternetAddress.tryParse(host) == null ||
        port == null ||
        port < 1 ||
        port > 65535 ||
        !const {'3+2', '5+0', '10+0'}.contains(timeControl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That QR code is not a valid SQI LAN invite.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LanJoinScreen(
          host: host,
          port: port,
          roomCode: uri.queryParameters['room'],
          timeControl: timeControl,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _discoveryTimer?.cancel();
    _cleanupTimer?.cancel();
    _udpSocket?.close();
    _manualIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF9F8F6);
    const surface = Color(0xFFFFFFFF);
    const primary = Color(0xFF1A1A1A);
    const muted = Color(0xFF737A74);
    const gold = Color(0xFFF5C451);
    const blue = Color(0xFF2D4A3E);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'LAN / Wi-Fi',
          style: TextStyle(
            fontSize: 20,
            color: primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: gold.withValues(alpha: .16)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_rounded, color: gold, size: 30),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Same network chess',
                          style: TextStyle(
                            fontSize: 20,
                            color: primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Both devices must be connected to the same Wi-Fi network.',
                          style: TextStyle(
                            fontSize: 20,
                            color: muted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Nearby games',
              style: TextStyle(
                fontSize: 20,
                color: primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Games appear automatically when another player is hosting.',
              style: TextStyle(fontSize: 20, color: muted),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _EmptyLanCard(
                icon: Icons.error_outline_rounded,
                title: 'Discovery unavailable',
                subtitle: _error!,
              )
            else if (_games.isEmpty)
              const _EmptyLanCard(
                icon: Icons.search_rounded,
                title: 'No games found',
                subtitle:
                    'Ask the other player to create a LAN game, then wait a moment.',
              )
            else
              ..._games.map(
                (game) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LanGameCard(
                    game: game,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LanJoinScreen(
                            host: game.host,
                            port: game.port,
                            discoveredName: game.name,
                            roomCode: game.roomCode,
                            timeControl: game.timeControl,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontSize: 20,
                      color: muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.white12)),
              ],
            ),
            const SizedBox(height: 20),
            _LanActionButton(
              icon: Icons.add_circle_outline_rounded,
              label: 'Create LAN game',
              color: gold,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LanHostScreen()),
                );
              },
            ),
            if (!Platform.isWindows && !Platform.isLinux) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _scanAndJoin,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan host QR code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(color: Colors.white12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Manual IP connection',
              style: TextStyle(
                fontSize: 20,
                color: primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualIpController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 20, color: primary),
                    decoration: InputDecoration(
                      hintText: 'Example: 192.168.1.10',
                      hintStyle: const TextStyle(fontSize: 20, color: muted),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _openManualJoin,
                    style: FilledButton.styleFrom(
                      backgroundColor: blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Automatic discovery is preferred. Manual IP is a fallback.',
              style: TextStyle(fontSize: 20, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyLanGame {
  const _NearbyLanGame({
    required this.hostId,
    required this.name,
    required this.host,
    required this.port,
    required this.roomCode,
    required this.timeControl,
    required this.updatedAt,
  });

  final String hostId;
  final String name;
  final String host;
  final int port;
  final String roomCode;
  final String timeControl;
  final DateTime updatedAt;
}

class _LanGameCard extends StatelessWidget {
  const _LanGameCard({required this.game, required this.onTap});

  final _NearbyLanGame game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFFFFFFF);
    const primary = Color(0xFF1A1A1A);
    const secondary = Color(0xFF454B46);
    const muted = Color(0xFF737A74);
    const gold = Color(0xFFF5C451);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.person_rounded, color: gold),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 20,
                        color: primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${game.timeControl}  •  White',
                      style: const TextStyle(fontSize: 20, color: secondary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Room ${game.roomCode}',
                      style: const TextStyle(fontSize: 20, color: muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'JOIN',
                  style: TextStyle(
                    fontSize: 20,
                    color: gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLanCard extends StatelessWidget {
  const _EmptyLanCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFFFFFFF);
    const primary = Color(0xFF1A1A1A);
    const muted = Color(0xFF737A74);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: muted, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              color: primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LanActionButton extends StatelessWidget {
  const _LanActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: const Color(0xFFF9F8F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LAN HOST
// -----------------------------------------------------------------------------

class LanHostScreen extends StatefulWidget {
  const LanHostScreen({super.key});

  @override
  State<LanHostScreen> createState() => _LanHostScreenState();
}

class _LanHostScreenState extends State<LanHostScreen> {
  static const int _port = 4040;
  static const int _discoveryPort = 4041;

  final TextEditingController _hostNameController = TextEditingController(
    text: 'SQI Player',
  );

  ServerSocket? _server;
  Socket? _client;
  StreamSubscription<String>? _clientSubscription;
  Stream<String>? _clientLines;
  RawDatagramSocket? _udpSocket;

  Timer? _advertiseTimer;
  Timer? _cleanupTimer;

  final String _hostId = 'host-${Random().nextInt(900000) + 100000}';

  final String _roomCode = '${Random().nextInt(900000) + 100000}';

  String _timeControl = '10+0';

  bool _hosting = false;
  bool _clientConnected = false;
  bool _gameOpened = false;
  bool _socketTransferred = false;

  List<String> _localAddresses = [];

  @override
  void initState() {
    super.initState();
    _startHosting();
  }

  Future<void> _startHosting() async {
    try {
      _localAddresses = await _getLocalIpv4Addresses();

      final server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        _port,
        shared: true,
      );

      _server = server;

      final udp = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _discoveryPort,
        reuseAddress: true,
      );

      _udpSocket = udp;
      udp.broadcastEnabled = true;

      udp.listen((event) {
        if (event != RawSocketEvent.read) return;

        final datagram = udp.receive();
        if (datagram == null) return;

        try {
          final message = jsonDecode(utf8.decode(datagram.data));

          if (message is Map && message['type'] == 'sqi_discovery_request') {
            _sendAdvertisement(datagram.address);
          }
        } catch (_) {}
      });

      server.listen(_handleClient);

      _advertiseTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _advertise(),
      );

      _cleanupTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_clientConnected && mounted) {
          setState(() {});
        }
      });

      _advertise();

      if (!mounted) return;

      setState(() {
        _hosting = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create LAN game: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<List<String>> _getLocalIpv4Addresses() async {
    final result = <String>[];

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
            if (!result.contains(address.address)) {
              result.add(address.address);
            }
          }
        }
      }
    } catch (_) {}

    return result;
  }

  void _advertise() {
    _sendAdvertisement(InternetAddress('255.255.255.255'));
  }

  void _sendAdvertisement(InternetAddress address) {
    final udp = _udpSocket;
    if (udp == null) return;

    try {
      final data = utf8.encode(
        jsonEncode({
          'type': 'sqi_lan_game',
          'hostId': _hostId,
          'name': _hostNameController.text.trim().isEmpty
              ? 'SQI Player'
              : _hostNameController.text.trim(),
          'port': _port,
          'roomCode': _roomCode,
          'timeControl': _timeControl,
        }),
      );

      udp.send(data, address, _discoveryPort);
    } catch (_) {}
  }

  void _handleClient(Socket client) {
    if (_client != null || _gameOpened) {
      try {
        client.write(
          '${jsonEncode({'type': 'busy', 'message': 'This game already has a player.'})}\n',
        );
      } catch (_) {}

      client.destroy();
      return;
    }

    _client = client;

    // IMPORTANT:
    // Convert the socket stream to a broadcast stream immediately.
    // The chess screen can safely listen to it after navigation.
    final lines = client
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();

    _clientLines = lines;

    if (mounted) {
      setState(() {
        _clientConnected = true;
      });
    }

    _clientSubscription = lines.listen(
      _handleMessage,
      onError: (_) => _handleClientDisconnected(),
      onDone: _handleClientDisconnected,
      cancelOnError: false,
    );
  }

  Future<void> _handleMessage(String line) async {
    try {
      final decoded = jsonDecode(line);

      if (decoded is! Map) return;

      final message = Map<String, dynamic>.from(decoded);

      final type = message['type']?.toString();

      switch (type) {
        case 'hello':
          if (_gameOpened) return;

          final role = message['role']?.toString();

          if (role != 'black') {
            _sendMessage({'type': 'error', 'message': 'Invalid player role.'});
            return;
          }

          final socket = _client;
          final lines = _clientLines;

          if (socket == null || lines == null) {
            return;
          }

          _gameOpened = true;
          _socketTransferred = true;
          await _clientSubscription?.cancel();
          _clientSubscription = null;
          if (!mounted) return;

          _sendMessage({
            'type': 'welcome',
            'roomCode': _roomCode,
            'hostName': _hostNameController.text.trim().isEmpty
                ? 'SQI Player'
                : _hostNameController.text.trim(),
            'timeControl': _timeControl,
            'role': 'white',
          });

          await Future<void>.delayed(const Duration(milliseconds: 100));

          if (!mounted) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LanChessMatchScreen(
                socket: socket,
                isHost: true,
                timeControl: _timeControl,
                initialTimeSeconds: _initialTimeSeconds,
                incrementSeconds: _incrementSeconds,
                myName: _hostNameController.text.trim().isEmpty
                    ? 'SQI Player'
                    : _hostNameController.text.trim(),
                opponentName: 'Opponent',
              ),
            ),
          );

          break;

        default:
          break;
      }
    } catch (_) {}
  }

  int get _initialTimeSeconds {
    switch (_timeControl) {
      case '5+0':
        return 300;
      case '3+2':
        return 180;
      case '10+0':
      default:
        return 600;
    }
  }

  int get _incrementSeconds {
    switch (_timeControl) {
      case '3+2':
        return 2;
      default:
        return 0;
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    final client = _client;

    if (client == null) return;

    try {
      client.write('${jsonEncode(message)}\n');
    } catch (_) {
      _handleClientDisconnected();
    }
  }

  void _handleClientDisconnected() {
    if (_socketTransferred) return;

    _client = null;
    _clientLines = null;

    if (!mounted) return;

    setState(() {
      _clientConnected = false;
    });
  }

  void _copyRoomDetails() {
    final address = _localAddresses.isNotEmpty
        ? _localAddresses.first
        : 'your IP';

    Clipboard.setData(
      ClipboardData(text: '$address:$_port  •  Room $_roomCode'),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room details copied.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _advertiseTimer?.cancel();
    _cleanupTimer?.cancel();

    _clientSubscription?.cancel();

    if (!_socketTransferred) {
      _client?.destroy();
    }

    _server?.close();
    _udpSocket?.close();
    _hostNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF9F8F6);
    const surface = Color(0xFFFFFFFF);
    const surface2 = Color(0xFFEDE9E2);
    const primary = Color(0xFF1A1A1A);
    const secondary = Color(0xFF454B46);
    const muted = Color(0xFF737A74);
    const gold = Color(0xFFF5C451);
    const green = Color(0xFF557B63);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Create LAN Game',
          style: TextStyle(
            fontSize: 20,
            color: primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: gold.withValues(alpha: .18)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_rounded,
                      color: gold,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'You are White',
                    style: TextStyle(
                      fontSize: 20,
                      color: primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _clientConnected
                        ? 'Opponent connected'
                        : 'Waiting for another player',
                    style: TextStyle(
                      fontSize: 20,
                      color: _clientConnected ? green : muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _HostField(controller: _hostNameController, label: 'Player name'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_rounded, color: gold),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Time control',
                      style: TextStyle(
                        fontSize: 20,
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _timeControl,
                      dropdownColor: surface2,
                      style: const TextStyle(
                        fontSize: 20,
                        color: primary,
                        fontWeight: FontWeight.w800,
                      ),
                      items: const [
                        DropdownMenuItem(value: '10+0', child: Text('10 + 0')),
                        DropdownMenuItem(value: '5+0', child: Text('5 + 0')),
                        DropdownMenuItem(value: '3+2', child: Text('3 + 2')),
                      ],
                      onChanged: _hosting
                          ? (value) {
                              if (value == null) return;

                              setState(() {
                                _timeControl = value;
                              });

                              _advertise();
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _InfoCard(
              icon: Icons.key_rounded,
              title: 'Room code',
              value: _roomCode,
            ),
            if (_hosting && _localAddresses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Scan to join this game',
                      style: TextStyle(
                        fontSize: 20,
                        color: primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: _makeLanInvite(
                        _localAddresses.first,
                        _port,
                        _roomCode,
                        _timeControl,
                      ),
                      size: 190,
                      backgroundColor: Colors.white,
                      semanticsLabel: 'QR code for joining this LAN chess game',
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Both devices need to be on the same Wi-Fi network.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: secondary),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.router_rounded,
              title: 'Your local address',
              value: _localAddresses.isEmpty
                  ? 'Finding address...'
                  : _localAddresses.join('\n'),
            ),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.numbers_rounded,
              title: 'TCP port',
              value: '$_port',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _copyRoomDetails,
                icon: const Icon(Icons.copy_rounded),
                label: const Text(
                  'Copy connection details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondary,
                  side: const BorderSide(color: Colors.white12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it works',
                    style: TextStyle(
                      fontSize: 20,
                      color: primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12),
                  _InstructionRow(
                    number: '1',
                    text: 'Keep both devices on the same Wi-Fi.',
                  ),
                  _InstructionRow(
                    number: '2',
                    text: 'The other player opens LAN / Wi-Fi.',
                  ),
                  _InstructionRow(
                    number: '3',
                    text: 'They tap your name and JOIN.',
                  ),
                  _InstructionRow(
                    number: '4',
                    text: 'You play White and they play Black.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_clientConnected)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: green.withValues(alpha: .20)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Player connected. Starting the match...',
                        style: TextStyle(
                          fontSize: 20,
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HostField extends StatelessWidget {
  const _HostField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFFFFFFF);
    const primary = Color(0xFF1A1A1A);
    const muted = Color(0xFF737A74);

    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 20, color: primary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 20, color: muted),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFFFFFFF);
    const primary = Color(0xFF1A1A1A);
    const muted = Color(0xFF737A74);
    const gold = Color(0xFFF5C451);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, color: muted)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    color: primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _makeLanInvite(String host, int port, String room, String timeControl) {
  return Uri(
    scheme: 'sqi-lan',
    host: 'join',
    queryParameters: {
      'host': host,
      'port': '$port',
      'room': room,
      'time': timeControl,
    },
  ).toString();
}

class _LanQrScannerScreen extends StatefulWidget {
  const _LanQrScannerScreen();

  @override
  State<_LanQrScannerScreen> createState() => _LanQrScannerScreenState();
}

class _LanQrScannerScreenState extends State<_LanQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
    autoStart: true,
  );

  bool _returned = false;
  String? _cameraError;

  void _onDetect(BarcodeCapture capture) {
    if (_returned) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (value.isEmpty) return;
    final uri = Uri.tryParse(value);
    final host = uri?.queryParameters['host'];
    final port = int.tryParse(uri?.queryParameters['port'] ?? '');
    if (uri == null ||
        uri.scheme != 'sqi-lan' ||
        uri.host != 'join' ||
        host == null ||
        InternetAddress.tryParse(host) == null ||
        port == null ||
        port < 1 ||
        port > 65535) {
      _returned = true;
      _controller.stop();
      Navigator.of(context).pop(value);
      return;
    }
    _returned = true;
    _controller.stop();
    Navigator.of(context).pop(value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F8F6),
        foregroundColor: const Color(0xFF1A1A1A),
        title: const Text('Scan LAN invite'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _cameraError ??
                    'Center the host’s SQI invite QR code in the frame.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF454B46),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    onDetectError: (error, stackTrace) {
                      if (!mounted) return;
                      setState(
                        () => _cameraError =
                            'Camera scan failed. Check camera access and try again.',
                      );
                    },
                    errorBuilder: (context, error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Camera unavailable. Allow camera access in device settings, then reopen the scanner.\n\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFF454B46),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: state.torchState == TorchState.unavailable
                        ? null
                        : _controller.toggleTorch,
                    icon: Icon(
                      state.torchState == TorchState.on
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                    ),
                    tooltip: 'Toggle flash',
                  ),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    onPressed: _controller.switchCamera,
                    icon: const Icon(Icons.cameraswitch_rounded),
                    tooltip: 'Switch camera',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFF737A74);
    const blue = Color(0xFF2D4A3E);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 20,
                color: blue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 20, color: muted, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LAN JOIN
// -----------------------------------------------------------------------------

class LanJoinScreen extends StatefulWidget {
  const LanJoinScreen({
    super.key,
    this.host,
    this.port = 4040,
    this.discoveredName,
    this.roomCode,
    this.timeControl = '10+0',
  });

  final String? host;
  final int port;
  final String? discoveredName;
  final String? roomCode;
  final String timeControl;

  @override
  State<LanJoinScreen> createState() => _LanJoinScreenState();
}

class _LanJoinScreenState extends State<LanJoinScreen> {
  final TextEditingController _ipController = TextEditingController();

  Socket? _socket;
  Stream<String>? _incomingStream;
  StreamSubscription<String>? _socketSubscription;

  bool _connecting = false;
  bool _connected = false;
  bool _gameOpened = false;
  bool _socketTransferred = false;

  String? _status;

  @override
  void initState() {
    super.initState();

    if (widget.host != null && widget.host!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _connect(widget.host!);
      });
    }
  }

  Future<void> _connect(String host) async {
    if (_connecting || _gameOpened) return;

    if (mounted) {
      setState(() {
        _connecting = true;
        _status = 'Connecting to $host...';
      });
    }

    try {
      final socket = await Socket.connect(
        host,
        widget.port,
        timeout: const Duration(seconds: 5),
      );

      if (!mounted) {
        socket.destroy();
        return;
      }

      _socket = socket;

      // Convert the incoming socket stream to broadcast.
      final lines = socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();

      _incomingStream = lines;

      _socketSubscription = lines.listen(
        _handleMessage,
        onError: (_) => _handleDisconnected(),
        onDone: _handleDisconnected,
        cancelOnError: false,
      );

      socket.write('${jsonEncode({'type': 'hello', 'role': 'black'})}\n');

      setState(() {
        _connecting = false;
        _connected = true;
        _status = 'Connected. Waiting for the host...';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _connecting = false;
        _connected = false;
        _status = 'Could not connect to $host.';
      });
    }
  }

  Future<void> _handleMessage(String line) async {
    try {
      final decoded = jsonDecode(line);

      if (decoded is! Map) return;

      final message = Map<String, dynamic>.from(decoded);

      final type = message['type']?.toString();

      switch (type) {
        case 'busy':
          if (!mounted) return;

          setState(() {
            _status = 'That game is already full.';
            _connected = false;
          });
          break;

        case 'welcome':
          if (_gameOpened) return;

          final role = message['role']?.toString();

          if (role != 'white') {
            if (!mounted) return;

            setState(() {
              _status = 'Invalid response from host.';
            });

            return;
          }

          final socket = _socket;
          final lines = _incomingStream;

          if (socket == null || lines == null) {
            return;
          }

          _gameOpened = true;
          _socketTransferred = true;
          await _socketSubscription?.cancel();
          _socketSubscription = null;
          if (!mounted) return;

          await Future<void>.delayed(const Duration(milliseconds: 100));

          if (!mounted) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LanChessMatchScreen(
                socket: socket,
                isHost: false,
                timeControl: widget.timeControl,
                initialTimeSeconds: _initialTimeSeconds(widget.timeControl),
                incrementSeconds: _incrementSeconds(widget.timeControl),
                myName: 'You',
                opponentName:
                    message['hostName']?.toString() ??
                    widget.discoveredName ??
                    'Host',
              ),
            ),
          );

          break;

        case 'error':
          if (!mounted) return;

          setState(() {
            _status = message['message']?.toString() ?? 'Connection error.';
          });
          break;

        default:
          break;
      }
    } catch (_) {}
  }

  int _initialTimeSeconds(String value) {
    switch (value) {
      case '5+0':
        return 300;
      case '3+2':
        return 180;
      case '10+0':
      default:
        return 600;
    }
  }

  int _incrementSeconds(String value) {
    return value == '3+2' ? 2 : 0;
  }

  void _handleDisconnected() {
    if (_socketTransferred) return;

    if (!mounted) return;

    setState(() {
      _connected = false;
      _connecting = false;
      _status = 'The connection was closed.';
    });
  }

  void _manualConnect() {
    final host = _ipController.text.trim();

    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the host IP address first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    _connect(host);
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();

    if (!_socketTransferred) {
      _socket?.destroy();
    }

    _ipController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF9F8F6);
    const surface = Color(0xFFFFFFFF);
    const primary = Color(0xFF1A1A1A);
    const secondary = Color(0xFF454B46);
    const muted = Color(0xFF737A74);
    const blue = Color(0xFF2D4A3E);
    const green = Color(0xFF557B63);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Join LAN Game',
          style: TextStyle(
            fontSize: 20,
            color: primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: blue.withValues(alpha: .18)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.login_rounded,
                      color: blue,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.discoveredName ?? 'LAN Game',
                    style: const TextStyle(
                      fontSize: 20,
                      color: primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.roomCode == null
                        ? 'You will play Black'
                        : 'Room ${widget.roomCode}  •  You will play Black',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_connected)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: green.withValues(alpha: .18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _status ?? 'Connected. Waiting for the host...',
                        style: const TextStyle(
                          fontSize: 20,
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_status != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  _status!,
                  style: const TextStyle(fontSize: 20, color: secondary),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Manual connection',
              style: TextStyle(
                fontSize: 20,
                color: primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20, color: primary),
              decoration: InputDecoration(
                hintText: 'Host IP, e.g. 192.168.1.10',
                hintStyle: const TextStyle(fontSize: 20, color: muted),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _connecting ? null : _manualConnect,
                icon: _connecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find_rounded),
                label: Text(
                  _connecting ? 'Connecting...' : 'Connect',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _InstructionRow(
              number: '1',
              text: 'Make sure both devices use the same Wi-Fi.',
            ),
            const _InstructionRow(
              number: '2',
              text: 'The host should keep the LAN game open.',
            ),
            const _InstructionRow(
              number: '3',
              text: 'Once connected, you automatically become Black.',
            ),
          ],
        ),
      ),
    );
  }
}
