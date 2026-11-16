import 'package:flutter/material.dart';
import 'package:sqi_chess_club/features/guest/guest_entry_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _supabase = Supabase.instance.client;
  static const _googleRedirectUri = 'sqi-chess-club://login-callback';

  static const Color danger = Color(0xFFEF4444);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.session == null) {
        setState(() {
          _errorMessage = 'Sign in could not be completed. Please try again.';
          _isLoading = false;
        });
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _friendlyAuthError(error);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Something went wrong while signing in. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }

    if (message.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    if (message.contains('network')) {
      return 'Network error. Check your internet connection.';
    }

    return error.message;
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your email address first.';
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        _errorMessage = 'Enter a valid email address.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _supabase.auth.resetPasswordForEmail(email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset instructions have been sent to your email.',
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyAuthError(error);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to send password reset instructions right now.';
      });
    }
  }

  void _openRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    required Color inputBg,
    required Color inputBorder,
    required Color textMuted,
    required Color focusColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: textMuted,
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: textMuted, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: inputBorder, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: inputBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: focusColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: danger, width: 1.6),
      ),
    );
  }

  Widget _buildRealGoogleLogo({required bool isDark, bool isDimmed = false}) {
    return Opacity(
      opacity: isDimmed ? 0.5 : 1.0,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(
          painter: _GoogleLogoPainter(cutoutColor: isDark ? const Color(0xFF1B243B) : const Color(0xFFF1F5F9)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFFAFAFA);
    final cardBg = isDark ? const Color(0xFF131B2E) : Colors.white;
    final inputBg = isDark ? const Color(0xFF1B243B) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF243048) : const Color(0xFFE2E8F0);
    final brandAction = isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E293B);
    final buttonTextColor = isDark ? const Color(0xFF0A0F1D) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 40 : 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo Card
                        Center(
                          child: Container(
                            width: 76,
                            height: 76,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: borderColor,
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.35 : 0.04,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/chesssqi.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.sports_esports_rounded,
                                color: brandAction,
                                size: 36,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            color: textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Sign in to enter the SQI Checkmate Arena',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: textMuted,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Error Banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: danger.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: danger,
                                  size: 19,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: danger,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Main Form Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: borderColor,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.35 : 0.03,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Address',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 8),

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 15,
                                ),
                                decoration: _inputDecoration(
                                  hintText: 'player@example.com',
                                  icon: Icons.alternate_email_rounded,
                                  inputBg: inputBg,
                                  inputBorder: borderColor,
                                  textMuted: textMuted,
                                  focusColor: brandAction,
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return 'Email is required.';
                                  }
                                  if (!RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(email)) {
                                    return 'Enter a valid email address.';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              Text(
                                'Password',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 8),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (!_isLoading) {
                                    _signIn();
                                  }
                                },
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 15,
                                ),
                                decoration: _inputDecoration(
                                  hintText: 'Enter your password',
                                  icon: Icons.lock_outline_rounded,
                                  inputBg: inputBg,
                                  inputBorder: borderColor,
                                  textMuted: textMuted,
                                  focusColor: brandAction,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: textMuted,
                                      size: 19,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required.';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: _isLoading
                                          ? null
                                          : (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                      activeColor: brandAction,
                                      checkColor: buttonTextColor,
                                      side: BorderSide(color: borderColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed:
                                        _isLoading ? null : _forgotPassword,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: brandAction,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Sign In Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandAction,
                                    foregroundColor: buttonTextColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              buttonTextColor,
                                            ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w800,
                                                color: buttonTextColor,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                              color: buttonTextColor,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Guest Button
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const GuestEntryScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.person_pin_rounded,
                              size: 18,
                              color: brandAction,
                            ),
                            label: Text(
                              'Play as Guest without Account',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Clean OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: borderColor,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: borderColor,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Google Inactive Button
                        Tooltip(
                          message: 'Google Sign-In is currently unavailable',
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1B243B)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildRealGoogleLogo(isDark: isDark, isDimmed: true),
                                const SizedBox(width: 10),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF243048)
                                        : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'Soon',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Create Account Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : _openRegister,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Create one',
                                style: TextStyle(
                                  color: brandAction,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'SQI Checkmate Arena',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Official 4-color Google "G" vector logo with adaptable inner cutout
class _GoogleLogoPainter extends CustomPainter {
  final Color cutoutColor;

  _GoogleLogoPainter({required this.cutoutColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = w / 2;
    final Rect rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Red (Top quadrant)
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, -0.75 * 3.14159, 0.75 * 3.14159, false)
      ..close();
    canvas.drawPath(redPath, paint);

    // Yellow (Left quadrant)
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, -1.5 * 3.14159, 0.75 * 3.14159, false)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green (Bottom quadrant)
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, 0.25 * 3.14159, 0.75 * 3.14159, false)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Blue (Right arc)
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(cx, cy)
      ..arcTo(rect, -0.15 * 3.14159, 0.45 * 3.14159, false)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Inner cutout to form the "G" ring
    paint.color = cutoutColor;
    canvas.drawCircle(Offset(cx, cy), radius * 0.58, paint);

    // Horizontal bar of the "G"
    paint.color = const Color(0xFF4285F4);
    final Rect barRect = Rect.fromLTWH(
      cx - (radius * 0.05),
      cy - (radius * 0.22),
      radius * 1.05,
      radius * 0.44,
    );
    canvas.drawRect(barRect, paint);
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) =>
      oldDelegate.cutoutColor != cutoutColor;
}
