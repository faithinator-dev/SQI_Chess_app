import 'package:flutter/material.dart';

import 'onboarding_data.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get isLastPage => _currentPage == onboardingPages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (isLastPage) {
      _finishOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final activeData = onboardingPages[_currentPage];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFFAFAFA);
    final cardColor = isDark ? const Color(0xFF131B2E) : Colors.white;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark
        ? const Color(0xFF243048)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 20),
                  child: Column(
                    children: [
                      _buildHeader(
                        activeData: activeData,
                        cardColor: cardColor,
                        textMain: textMain,
                        textSub: textSub,
                        borderColor: borderColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: onboardingPages.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final page = onboardingPages[index];
                            return _buildPageContent(
                              page: page,
                              index: index,
                              isWide: isWide,
                              cardColor: cardColor,
                              textMain: textMain,
                              textSub: textSub,
                              borderColor: borderColor,
                              isDark: isDark,
                            );
                          },
                        ),
                      ),

                      _buildFooter(
                        activeData: activeData,
                        isDark: isDark,
                        textMain: textMain,
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

  // --- Header with Clean Logo, Club Name & Skip Button ---
  Widget _buildHeader({
    required OnboardingData activeData,
    required Color cardColor,
    required Color textMain,
    required Color textSub,
    required Color borderColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Image.asset(
              'assets/images/chesssqi.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.sports_esports_rounded,
                color: isDark ? const Color(0xFF38BDF8) : activeData.themeColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'SQI CHESS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: textMain,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? const Color(0xFF38BDF8)
                                  : activeData.themeColor)
                              .withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CLUB',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFF38BDF8)
                            : activeData.themeColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Play • Learn • Connect',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSub,
                ),
              ),
            ],
          ),

          const Spacer(),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _finishOnboarding,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSub,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.chevron_right_rounded, size: 16, color: textSub),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Page Content ---
  Widget _buildPageContent({
    required OnboardingData page,
    required int index,
    required bool isWide,
    required Color cardColor,
    required Color textMain,
    required Color textSub,
    required Color borderColor,
    required bool isDark,
  }) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: _buildArtwork(
              page: page,
              cardColor: cardColor,
              textMain: textMain,
              borderColor: borderColor,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 36),
          Expanded(
            flex: 5,
            child: _buildTextCard(
              page: page,
              textMain: textMain,
              textSub: textSub,
              isDark: isDark,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          flex: 11,
          child: _buildArtwork(
            page: page,
            cardColor: cardColor,
            textMain: textMain,
            borderColor: borderColor,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 9,
          child: _buildTextCard(
            page: page,
            textMain: textMain,
            textSub: textSub,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // --- Center Artwork: Crisp Card with Subtle Chess Board ---
  Widget _buildArtwork({
    required OnboardingData page,
    required Color cardColor,
    required Color textMain,
    required Color borderColor,
    required bool isDark,
  }) {
    final themeAccent = isDark ? const Color(0xFF38BDF8) : page.themeColor;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft solid outer ring
          Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeAccent.withValues(alpha: isDark ? 0.08 : 0.05),
            ),
          ),

          // Main Card Container
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.06),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  _buildCleanChessboard(page, isDark),
                  Center(child: _buildHeroDisplay(page, isDark)),
                ],
              ),
            ),
          ),

          // Top-Right Feature Badge
          Positioned(
            top: 20,
            right: 8,
            child: _buildBadge(
              icon: page.icon,
              label: page.badgeText,
              color: themeAccent,
              cardColor: cardColor,
              borderColor: borderColor,
              textMain: textMain,
            ),
          ),

          // Bottom-Left Arena Badge
          Positioned(
            bottom: 20,
            left: 8,
            child: _buildBadge(
              icon: Icons.check_circle_rounded,
              label: 'SQI Arena',
              color: isDark ? const Color(0xFF38BDF8) : textMain,
              cardColor: cardColor,
              borderColor: borderColor,
              textMain: textMain,
            ),
          ),
        ],
      ),
    );
  }

  // --- Hero Display: Real Picture or Chess Mascot ---
  Widget _buildHeroDisplay(OnboardingData page, bool isDark) {
    final showPicture =
        page.isPicturehere &&
        page.chessPicture != null &&
        page.chessPicture!.isNotEmpty;

    if (showPicture) {
      return Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(70),
          child: Image.asset(
            page.chessPicture!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildEmojiMascot(page, isDark);
            },
          ),
        ),
      );
    }

    return _buildEmojiMascot(page, isDark);
  }

  Widget _buildEmojiMascot(OnboardingData page, bool isDark) {
    final bgMascotColor = isDark ? const Color(0xFF1E293B) : page.themeColor;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgMascotColor,
        border: Border.all(
          color: isDark ? const Color(0xFF38BDF8) : Colors.white,
          width: isDark ? 2.5 : 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          page.chessEmoji ?? '♟',
          style: TextStyle(
            fontSize: 46,
            color: isDark ? const Color(0xFF38BDF8) : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- Clean Chessboard Grid with Dark Mode Contrast ---
  Widget _buildCleanChessboard(OnboardingData page, bool isDark) {
    final lightSquare = isDark ? const Color(0xFF131B2E) : Colors.white;
    final darkSquare = isDark
        ? const Color(0xFF1B243B)
        : page.themeColor.withValues(alpha: 0.05);

    return Column(
      children: List.generate(8, (row) {
        return Expanded(
          child: Row(
            children: List.generate(8, (col) {
              final isLight = (row + col).isEven;
              return Expanded(
                child: Container(color: isLight ? lightSquare : darkSquare),
              );
            }),
          ),
        );
      }),
    );
  }

  // --- Crisp Badge with Adaptive Colors ---
  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color cardColor,
    required Color borderColor,
    required Color textMain,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textMain,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- Text Content Section ---
  Widget _buildTextCard({
    required OnboardingData page,
    required Color textMain,
    required Color textSub,
    required bool isDark,
  }) {
    final themeAccent = isDark ? const Color(0xFF38BDF8) : page.themeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: themeAccent.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: themeAccent.withValues(alpha: isDark ? 0.35 : 0.18),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(page.icon, size: 15, color: themeAccent),
                const SizedBox(width: 6),
                Text(
                  page.eyebrow,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: themeAccent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: textMain,
              height: 1.2,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            page.description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.55,
              color: textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Footer with Indicator and Button ---
  Widget _buildFooter({
    required OnboardingData activeData,
    required bool isDark,
    required Color textMain,
  }) {
    final buttonBg = isDark ? const Color(0xFF38BDF8) : activeData.themeColor;
    final buttonTextColor = isDark ? const Color(0xFF0A0F1D) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        children: [
          // Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(onboardingPages.length, (index) {
              final active = index == _currentPage;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 7,
                width: active ? 28 : 7,
                decoration: BoxDecoration(
                  color: active
                      ? buttonBg
                      : (isDark
                            ? const Color(0xFF243048)
                            : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Solid High-Contrast CTA Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: buttonTextColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastPage ? "Let's Play Chess" : 'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: buttonTextColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
                    color: buttonTextColor,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${_currentPage + 1} of ${onboardingPages.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
