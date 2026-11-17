import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import '../core/config/supabase_config.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../core/repositories/guest_preferences_repository.dart';
import '../features/guest/guest_dashboard_screen.dart';

class CheckmateArenaApp extends StatefulWidget {
  const CheckmateArenaApp({super.key, this.client});

  final SupabaseClient? client;

  @override
  State<CheckmateArenaApp> createState() => _CheckmateArenaAppState();
}

class _CheckmateArenaAppState extends State<CheckmateArenaApp> {
  bool _initializing = true;
  String? _guestName;
  String _appearance = 'Dark';
  String? _appearanceUserId;
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
      await _loadSavedAppearance(Supabase.instance.client);
      await _checkGuestSession();
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

  Future<void> _checkGuestSession() async {
    final name = await GuestPreferencesRepository().getActiveGuestName();
    final savedAppearance = await GuestPreferencesRepository().getAppearance();
    final appearance = savedAppearance;
    if (!mounted) return;
    setState(() {
      _guestName = name != null && name.trim().isNotEmpty ? name : null;
      if (appearance != null &&
          const ['Dark', 'Light', 'System'].contains(appearance)) {
        _appearance = appearance;
      }
    });
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

  Future<void> _loadSavedAppearance(SupabaseClient client) async {
    final user = client.auth.currentUser;
    if (user == null || _appearanceUserId == user.id) return;
    _appearanceUserId = user.id;
    try {
      final localAppearance = await GuestPreferencesRepository()
          .getAppearance();
      if (localAppearance != null &&
          const ['Dark', 'Light', 'System'].contains(localAppearance)) {
        if (mounted) _setAppearance(localAppearance);
      }
    } catch (error) {
      _appearanceUserId = null;
      debugPrint('Could not load local appearance: $error');
    }
  }

  void _setAppearance(String appearance) {
    if (!const ['Dark', 'Light', 'System'].contains(appearance)) return;
    if (_appearance != appearance && mounted) {
      setState(() => _appearance = appearance);
    }
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
      // UserSettingsModel defaults to Dark; start there and let the persisted
      // preference replace it as soon as the preferences page loads.
      builder: (context, child) => _AppearanceBridge(
        onLoad: _loadSavedAppearance,
        onChanged: (value) {
          if (mounted && value != _appearance) {
            _setAppearance(value);
          }
        },
        child: _GuestSessionBridge(
          onAuthenticated: () async {
            await GuestPreferencesRepository().clear();
            if (mounted) setState(() => _guestName = null);
          },
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: widget.client != null
          ? AuthGate(client: widget.client)
          : _initializing
          ? const _StartupScreen()
          : _startupError != null
          ? _StartupScreen(error: _startupError, onRetry: _initializeSupabase)
          : _guestName != null
          ? GuestDashboardScreen(playerName: _guestName!)
          : const AuthGate(),
    );
  }
}

class _GuestSessionBridge extends InheritedWidget {
  const _GuestSessionBridge({
    required this.onAuthenticated,
    required super.child,
  });
  final VoidCallback onAuthenticated;
  static void authenticated(BuildContext context) => context
      .getInheritedWidgetOfExactType<_GuestSessionBridge>()
      ?.onAuthenticated();
  @override
  bool updateShouldNotify(_GuestSessionBridge oldWidget) =>
      onAuthenticated != oldWidget.onAuthenticated;
}

void clearGuestSessionAfterAuthentication(BuildContext context) =>
    _GuestSessionBridge.authenticated(context);

class _AppearanceBridge extends InheritedWidget {
  const _AppearanceBridge({
    required this.onChanged,
    required this.onLoad,
    required super.child,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<SupabaseClient> onLoad;

  static void update(BuildContext context, String appearance) {
    context.getInheritedWidgetOfExactType<_AppearanceBridge>()?.onChanged(
      appearance,
    );
  }

  static void loadAppearance(BuildContext context, SupabaseClient client) {
    context.getInheritedWidgetOfExactType<_AppearanceBridge>()?.onLoad(client);
  }

  @override
  bool updateShouldNotify(_AppearanceBridge oldWidget) =>
      onChanged != oldWidget.onChanged || onLoad != oldWidget.onLoad;
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
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Game Logo Container
                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppTheme.divider, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.blue.withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/chesssqi.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.sports_esports_rounded,
                        color: AppTheme.blue,
                        size: 44,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Game Title
                  const Text(
                    'SQI CHECKMATE ARENA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    hasError ? 'Startup Failed' : 'Loading Game Arena...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: hasError
                          ? AppTheme.errorColor
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 28),

                  if (!hasError) ...[
                    // Gaming Style Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: const SizedBox(
                        width: 160,
                        height: 6,
                        child: LinearProgressIndicator(
                          backgroundColor: AppTheme.elevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.blue,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.errorColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.errorColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.blue,
                          foregroundColor: AppTheme.canvas,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(140, 46),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
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
      _AppearanceBridge.loadAppearance(context, supabase);
    }

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
