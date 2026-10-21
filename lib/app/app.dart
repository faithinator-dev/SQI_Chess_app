import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import '../core/config/supabase_config.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

class CheckmateArenaApp extends StatefulWidget {
  const CheckmateArenaApp({super.key, this.client});

  final SupabaseClient? client;

  @override
  State<CheckmateArenaApp> createState() => _CheckmateArenaAppState();
}

class _CheckmateArenaAppState extends State<CheckmateArenaApp> {
  bool _initializing = true;
  String _appearance = 'System';
  String? _startupError;
  int _attempt = 0;
  StreamSubscription<Uri>? _authLinkSubscription;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    if (widget.client == null) {
      _initializeSupabase();
    } else {
      _startAuthDeepLinks(widget.client!);
    }
  }

  @override
  void dispose() {
    _authLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeSupabase() async {
    final attempt = ++_attempt;
    setState(() {
      _initializing = true;
      _startupError = null;
    });

    try {
      try {
        await dotenv.load(fileName: 'assets/.env');
      } catch (_) {
        // --dart-define remains available when no environment asset is bundled.
      }
      SupabaseConfig.validate();
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      await _startAuthDeepLinks(Supabase.instance.client);
      if (!mounted || attempt != _attempt) return;
      setState(() => _initializing = false);
    } catch (error) {
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _initializing = false;
        _startupError = _startupMessage(error);
      });
    }
  }

  Future<void> _startAuthDeepLinks(SupabaseClient client) async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleAuthDeepLink(client, initialUri);
    }
    _authLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleAuthDeepLink(client, uri),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Auth deep-link error: $error');
      },
    );
  }

  Future<void> _handleAuthDeepLink(SupabaseClient client, Uri uri) async {
    if (uri.scheme != 'sqi-chess-club' || uri.host != 'login-callback') {
      return;
    }

    try {
      await client.auth.getSessionFromUrl(uri);
    } on AuthException catch (error) {
      debugPrint('Google authentication callback failed: ${error.message}');
    }
  }

  String _startupMessage(Object error) {
    if (error is StateError && error.toString().contains('not configured')) {
      return 'This build is missing its Supabase configuration. Please install a correctly configured build.';
    }
    return 'The secure learning and account service could not start. Check your connection and retry.';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQI Checkmate Arena',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: switch (_appearance) {
        'Light' => ThemeMode.light,
        'Dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      builder: (context, child) => _AppearanceBridge(
        onChanged: (value) {
          if (mounted && value != _appearance) {
            setState(() => _appearance = value);
          }
        },
        child: child ?? const SizedBox.shrink(),
      ),
      home: widget.client != null
          ? AuthGate(client: widget.client)
          : _initializing
          ? const _StartupScreen()
          : _startupError != null
          ? _StartupScreen(error: _startupError, onRetry: _initializeSupabase)
          : const AuthGate(),
    );
  }
}

class _AppearanceBridge extends InheritedWidget {
  const _AppearanceBridge({required this.onChanged, required super.child});

  final ValueChanged<String> onChanged;

  static void update(BuildContext context, String appearance) {
    context.getInheritedWidgetOfExactType<_AppearanceBridge>()?.onChanged(
      appearance,
    );
  }

  @override
  bool updateShouldNotify(_AppearanceBridge oldWidget) =>
      onChanged != oldWidget.onChanged;
}

void updateAppAppearance(BuildContext context, String appearance) {
  _AppearanceBridge.update(context, appearance);
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen({this.error, this.onRetry});

  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sports_esports_rounded,
                    color: Color(0xFF2D4A3E),
                    size: 54,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'SQI CHESS APP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!hasError) ...[
                    const Text(
                      'Starting secure services...',
                      style: TextStyle(color: Color(0xFF737A74)),
                    ),
                    const SizedBox(height: 18),
                    const CircularProgressIndicator(color: Color(0xFF2D4A3E)),
                  ] else ...[
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF737A74),
                        height: 1.5,
                      ),
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.client});

  final SupabaseClient? client;

  @override
  Widget build(BuildContext context) {
    final supabase = client ?? Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session != null) {
      return const DashboardScreen();
    }

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final currentSession = supabase.auth.currentSession;

        if (currentSession != null) {
          return const DashboardScreen();
        }

        return const OnboardingScreen();
      },
    );
  }
}
