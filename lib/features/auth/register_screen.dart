import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dashboard/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _supabase = Supabase.instance.client;

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ratingController = TextEditingController();
  final _bioController = TextEditingController();
  final _departmentController = TextEditingController();
  final _levelController = TextEditingController();
  final _campusController = TextEditingController();

  int _currentStep = 0;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool _notifications = true;
  bool _gameSounds = true;
  bool _boardCoordinates = true;
  bool _publicProfile = true;
  bool _acceptedTerms = false;

  String _skillLevel = 'Beginner';
  String _timeControl = 'Rapid';
  String _playStyle = 'Both';
  String _sqiStatus = 'Student';

  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ratingController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _levelController.dispose();
    _campusController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    setState(() {
      _errorMessage = null;
    });

    switch (_currentStep) {
      case 0:
        if (_fullNameController.text.trim().isEmpty) {
          _showError('Please enter your full name.');
          return false;
        }

        if (_usernameController.text.trim().isEmpty) {
          _showError('Please choose a chess handle.');
          return false;
        }

        if (!RegExp(
          r'^[a-zA-Z0-9_]+$',
        ).hasMatch(_usernameController.text.trim())) {
          _showError(
            'Chess handle can only contain letters, numbers, and underscores.',
          );
          return false;
        }

        if (_usernameController.text.trim().length < 3) {
          _showError('Chess handle must be at least 3 characters.');
          return false;
        }

        final email = _emailController.text.trim();

        if (email.isEmpty) {
          _showError('Please enter your email address.');
          return false;
        }

        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
          _showError('Please enter a valid email address.');
          return false;
        }

        if (_phoneController.text.trim().isEmpty) {
          _showError('Please enter your phone number.');
          return false;
        }

        return true;

      case 1:
        if (_passwordController.text.length < 8) {
          _showError('Password must contain at least 8 characters.');
          return false;
        }

        if (_passwordController.text != _confirmPasswordController.text) {
          _showError('Passwords do not match.');
          return false;
        }

        return true;

      case 2:
        if (_ratingController.text.trim().isNotEmpty) {
          final rating = int.tryParse(_ratingController.text.trim());

          if (rating == null || rating < 0) {
            _showError('Enter a valid approximate rating.');
            return false;
          }
        }

        return true;

      case 3:
        if (_departmentController.text.trim().isEmpty) {
          _showError('Please enter your department.');
          return false;
        }

        if (_levelController.text.trim().isEmpty) {
          _showError('Please enter your level.');
          return false;
        }

        if (_campusController.text.trim().isEmpty) {
          _showError('Please enter your campus.');
          return false;
        }

        if (!_acceptedTerms) {
          _showError('Please accept the terms and conditions to continue.');
          return false;
        }

        return true;
    }

    return false;
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _nextStep() {
    if (!_validateCurrentStep()) {
      return;
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
        _errorMessage = null;
      });
    } else {
      _register();
    }
  }

  void _previousStep() {
    if (_currentStep == 0 || _isLoading) {
      return;
    }

    setState(() {
      _currentStep--;
      _errorMessage = null;
    });
  }

  Future<void> _register() async {
    if (!_validateCurrentStep()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final username = _usernameController.text.trim().toLowerCase();

      final response = await _supabase.auth.signUp(
        email: email,
        password: _passwordController.text,
        data: {
          'full_name': _fullNameController.text.trim(),
          'username': username,
          'phone': _phoneController.text.trim(),
          'skill_level': _skillLevel,
          'approx_rating': _ratingController.text.trim(),
          'preferred_time_control': _timeControl,
          'play_style': _playStyle,
          'bio': _bioController.text.trim(),
          'sqi_status': _sqiStatus,
          'department': _departmentController.text.trim(),
          'level': _levelController.text.trim(),
          'campus': _campusController.text.trim(),
        },
      );

      if (!mounted) return;

      /*
       * EMAIL CONFIRMATION DISABLED:
       *
       * Supabase should return a session immediately.
       */
      if (response.session != null) {
        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );

        return;
      }

      /*
       * If we reach here, Supabase created the user but did not
       * create a session. That normally means email confirmation
       * is still enabled.
       */
      if (response.user != null) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Account created, but email confirmation is still enabled '
              'in Supabase. Turn off "Confirm email" in '
              'Authentication â†’ Providers â†’ Email, then try again.';
        });

        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Account creation could not be completed. Please try again.';
      });
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyAuthError(error);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong while creating your account.';
      });
    }
  }

  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('user already registered')) {
      return 'An account with this email already exists.';
    }

    if (message.contains('username')) {
      return 'That chess handle may already be in use.';
    }

    if (message.contains('password')) {
      return 'Please choose a stronger password.';
    }

    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    if (message.contains('network')) {
      return 'Network error. Check your internet connection.';
    }

    return error.message;
  }

  String _passwordStrength() {
    final password = _passwordController.text;

    if (password.isEmpty) {
      return 'Enter a password';
    }

    if (password.length < 8) {
      return 'Too short';
    }

    int score = 0;

    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

    if (score <= 2) {
      return 'Weak password';
    }

    if (score <= 3) {
      return 'Good password';
    }

    return 'Strong password';
  }

  Color _passwordStrengthColor() {
    final password = _passwordController.text;

    if (password.isEmpty || password.length < 8) {
      return const Color(0xFFFF5C70);
    }

    int score = 0;

    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

    if (score <= 2) {
      return const Color(0xFFFF5C70);
    }

    if (score <= 3) {
      return const Color(0xFFF5C451);
    }

    return const Color(0xFF557B63);
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6F7B91), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF8290A8), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF2D4A3E), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFFF5C70)),
      ),
    );
  }

  Widget _buildStepIndicator() {
    const primary = Color(0xFF2D4A3E);
    const muted = Color(0xFF536078);

    return Row(
      children: List.generate(4, (index) {
        final active = index <= _currentStep;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
            height: 4,
            decoration: BoxDecoration(
              color: active ? primary : muted,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAccountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Full name'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          enabled: !_isLoading,
          style: _fieldTextStyle(),
          decoration: _inputDecoration(
            hint: 'Your full name',
            icon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 17),
        _label('Chess handle'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          enabled: !_isLoading,
          autocorrect: false,
          style: _fieldTextStyle(),
          decoration: _inputDecoration(
            hint: 'e.g. checkmate_king',
            icon: Icons.alternate_email_rounded,
          ),
        ),
        const SizedBox(height: 17),
        _label('Email address'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          style: _fieldTextStyle(),
          decoration: _inputDecoration(
            hint: 'you@example.com',
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 17),
        _label('Phone number'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          enabled: !_isLoading,
          keyboardType: TextInputType.phone,
          style: _fieldTextStyle(),
          decoration: _inputDecoration(
            hint: '+234...',
            icon: Icons.phone_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Password'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          enabled: !_isLoading,
          obscureText: _obscurePassword,
          onChanged: (_) {
            setState(() {});
          },
          style: _fieldTextStyle(),
          decoration: _inputDecoration(
            hint: 'Create a strong password',
            icon: Icons.lock_outline_rounded,
            suffix: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF737A74),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _passwordStrength(),
          style: TextStyle(
            color: _passwordStrengthColor(),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        _label('Confirm password'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          enabled: !_isLoading,
          obscureText: _obscureConfirmPassword,
          style: _fieldTextStyle(),
          decoration: _inputDecoration(
            hint: 'Repeat your password',
            icon: Icons.lock_reset_outlined,
            suffix: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF737A74),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _infoCard(
          icon: Icons.security_outlined,
          text:
              'Use at least 8 characters. A combination of letters, numbers and symbols is recommended.',
        ),
      ],
    );
  }

  Widget _buildChessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('Chess skill level'),
        const SizedBox(height: 8),
        _dropdownField(
          value: _skillLevel,
          items: const ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
          icon: Icons.workspace_premium_outlined,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _skillLevel = value;
              });
            }
          },
        ),
        const SizedBox(height: 17),
        _label('Approximate chess rating'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ratingController,
          enabled: !_isLoading,
          keyboardType: TextInputType.number,
          style: _fieldTextStyle(),
          decoration: _inputDecoration(
            hint: 'e.g. 1200',
            icon: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(height: 17),
        _label('Preferred time control'),
        const SizedBox(height: 8),
        _dropdownField(
          value: _timeControl,
          items: const ['Bullet', 'Blitz', 'Rapid', 'Classical'],
          icon: Icons.timer_outlined,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _timeControl = value;
              });
            }
          },
        ),
        const SizedBox(height: 17),
        _label('Play style'),
        const SizedBox(height: 8),
        _dropdownField(
          value: _playStyle,
          items: const ['Aggressive', 'Defensive', 'Positional', 'Both'],
          icon: Icons.psychology_outlined,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _playStyle = value;
              });
            }
          },
        ),
        const SizedBox(height: 17),
        _label('Short bio'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bioController,
          enabled: !_isLoading,
          maxLines: 3,
          style: _fieldTextStyle(),
          decoration: _inputDecoration(
            hint: 'Tell other players a little about you',
            icon: Icons.edit_note_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSqiStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('SQI status'),
        const SizedBox(height: 8),
        _dropdownField(
          value: _sqiStatus,
          items: const ['Student', 'Staff', 'Alumni', 'Other'],
          icon: Icons.school_outlined,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _sqiStatus = value;
              });
            }
          },
        ),
        const SizedBox(height: 17),
        _label('Department'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _departmentController,
          enabled: !_isLoading,
          style: _fieldTextStyle(),
          decoration: _inputDecoration(
            hint: 'e.g. Software Engineering',
            icon: Icons.account_tree_outlined,
          ),
        ),
        const SizedBox(height: 17),
        _label('Level'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _levelController,
          enabled: !_isLoading,
          style: _fieldTextStyle(),
          decoration: _inputDecoration(
            hint: 'e.g. Level 3',
            icon: Icons.layers_outlined,
          ),
        ),
        const SizedBox(height: 17),
        _label('Campus'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _campusController,
          enabled: !_isLoading,
          style: _fieldTextStyle(),
          decoration: _inputDecoration(
            hint: 'Your SQI campus',
            icon: Icons.location_on_outlined,
          ),
        ),
        const SizedBox(height: 22),
        _settingTile(
          title: 'Notifications',
          subtitle: 'Receive important SQI updates',
          value: _notifications,
          onChanged: (value) {
            setState(() {
              _notifications = value;
            });
          },
        ),
        _settingTile(
          title: 'Game sounds',
          subtitle: 'Play sounds during games',
          value: _gameSounds,
          onChanged: (value) {
            setState(() {
              _gameSounds = value;
            });
          },
        ),
        _settingTile(
          title: 'Board coordinates',
          subtitle: 'Show coordinates on chessboards',
          value: _boardCoordinates,
          onChanged: (value) {
            setState(() {
              _boardCoordinates = value;
            });
          },
        ),
        _settingTile(
          title: 'Public profile',
          subtitle: 'Allow other players to view your profile',
          value: _publicProfile,
          onChanged: (value) {
            setState(() {
              _publicProfile = value;
            });
          },
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _acceptedTerms,
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() {
                    _acceptedTerms = value ?? false;
                  });
                },
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFF2D4A3E),
          title: const Text(
            'I agree to the SQI Checkmate Arena terms.',
            style: TextStyle(color: Color(0xFF454B46), fontSize: 14),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _settingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: _isLoading ? null : onChanged,
        activeThumbColor: const Color(0xFF2D4A3E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF737A74), fontSize: 14),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFFEDE9E2),
      iconEnabledColor: const Color(0xFF737A74),
      style: _fieldTextStyle(),
      decoration: _inputDecoration(hint: '', icon: icon),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: _isLoading ? null : onChanged,
    );
  }

  Widget _infoCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D4A3E).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2D4A3E).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2D4A3E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF454B46),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF454B46),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  TextStyle _fieldTextStyle() {
    return const TextStyle(color: Color(0xFF1A1A1A), fontSize: 16);
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildAccountStep();
      case 1:
        return _buildSecurityStep();
      case 2:
        return _buildChessStep();
      case 3:
        return _buildSqiStep();
      default:
        return _buildAccountStep();
    }
  }

  String _stepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Create your account';
      case 1:
        return 'Secure your account';
      case 2:
        return 'Your chess profile';
      case 3:
        return 'SQI preferences';
      default:
        return 'Create your account';
    }
  }

  String _stepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Enter your basic account information.';
      case 1:
        return 'Choose a password to protect your account.';
      case 2:
        return 'Tell us about your chess experience.';
      case 3:
        return 'Complete your SQI player profile.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF9F8F6);
    const primary = Color(0xFF2D4A3E);
    const textPrimary = Color(0xFF1A1A1A);
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
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _isLoading ? null : _previousStep,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF454B46),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Step ${_currentStep + 1} of 4',
                            style: const TextStyle(
                              color: muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildStepIndicator(),
                      const SizedBox(height: 28),
                      const Text(
                        'Join SQI Checkmate Arena',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _stepSubtitle(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 14,
                          height: 1.5,
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
                                    color: Color(0xFF454B46),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      Text(
                        _stepTitle(),
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildCurrentStep(),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextStep,
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
                          child: _isLoading
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
                              : Text(
                                  _currentStep == 3
                                      ? 'Create account'
                                      : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_currentStep == 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(color: muted, fontSize: 14),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).pop();
                                    },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Sign in',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
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
