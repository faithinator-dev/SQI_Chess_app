import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dashboard/dashboard_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  final _supabase = Supabase.instance.client;

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  Timer? _timer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();

        setState(() {
          _secondsRemaining = 0;
        });

        return;
      }

      setState(() {
        _secondsRemaining--;
      });
    });
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();

    final code = _codeController.text.trim();

    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _errorMessage = 'Enter the 6-digit verification code.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase.auth.verifyOTP(
        email: widget.email,
        token: code,
        type: OtpType.signup,
      );

      if (!mounted) return;

      if (response.session == null) {
        setState(() {
          _isVerifying = false;
          _errorMessage =
              'Your email was verified, but your session could not be created. Please sign in.';
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
        _isVerifying = false;
        _errorMessage = _friendlyError(error);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0 || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.resend(type: OtpType.signup, email: widget.email);

      if (!mounted) return;

      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new verification code has been sent.')),
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _isResending = false;
        _errorMessage = _friendlyError(error);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isResending = false;
        _errorMessage = 'Unable to resend the code right now.';
      });
    }

    if (mounted) {
      setState(() {
        _isResending = false;
      });
    }
  }

  String _friendlyError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('expired')) {
      return 'This verification code has expired. Request a new one.';
    }

    if (message.contains('invalid')) {
      return 'That verification code is incorrect.';
    }

    if (message.contains('too many')) {
      return 'Too many attempts. Please wait and try again.';
    }

    if (message.contains('rate limit')) {
      return 'Please wait before requesting another code.';
    }

    return error.message;
  }

  void _changeEmail() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF9F8F6);
    const surface = Color(0xFFFFFFFF);
    const primary = Color(0xFF2D4A3E);
    const textPrimary = Color(0xFF1A1A1A);
    const textSecondary = Color(0xFF454B46);
    const muted = Color(0xFF737A74);
    const danger = Color(0xFFFF5C70);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 40 : 22,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: _isVerifying ? null : _changeEmail,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: textSecondary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            color: primary,
                            size: 38,
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      const Text(
                        'Verify your email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'We sent a 6-digit verification code to',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: muted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 30),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: danger.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: danger,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      const Text(
                        'Verification code',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        maxLength: 6,
                        enabled: !_isVerifying,
                        textAlign: TextAlign.center,
                        onSubmitted: (_) {
                          if (!_isVerifying) {
                            _verifyCode();
                          }
                        },
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 9,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '000000',
                          hintStyle: const TextStyle(
                            color: Color(0xFF4E5A71),
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 9,
                          ),
                          filled: true,
                          fillColor: surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: primary,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            disabledBackgroundColor: primary.withValues(
                              alpha: 0.45,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Verify email',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Didn't receive the code? ",
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                          TextButton(
                            onPressed:
                                (_secondsRemaining == 0 &&
                                    !_isResending &&
                                    !_isVerifying)
                                ? _resendCode
                                : null,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _isResending
                                  ? 'Sending...'
                                  : _secondsRemaining > 0
                                  ? 'Resend in ${_secondsRemaining}s'
                                  : 'Resend code',
                              style: TextStyle(
                                color: _secondsRemaining == 0 ? primary : muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: _isVerifying ? null : _changeEmail,
                        child: const Text(
                          'Use a different email',
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'The verification code is only for confirming '
                        'ownership of your email address.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF5F6A80),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'SQI Checkmate Arena',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF5F6A80),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
}
