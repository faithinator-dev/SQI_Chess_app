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

  int currentPage = 0;

  static const Color background = Color(0xFFF9F8F6);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);

  bool get isLastPage => currentPage == onboardingPages.length - 1;

  void nextPage() {
    if (isLastPage) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  void skipOnboarding() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 24),
                  child: Column(
                    children: [
                      _buildHeader(),

                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: onboardingPages.length,
                          onPageChanged: (index) {
                            setState(() {
                              currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return _buildPage(
                              onboardingPages[index],
                              index,
                              isWide,
                            );
                          },
                        ),
                      ),

                      _buildFooter(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: blue.withValues(alpha: 0.35)),
            ),
            child: const Image(
              image: AssetImage("assets/images/chesssqi.png"),
              fit: .contain,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SQI CHECKMATE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'ARENA',
                  style: TextStyle(
                    color: blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed: skipOnboarding,
            child: const Text(
              'Skip',
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData page, int index, bool isWide) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: isWide
          ? Row(
              key: ValueKey(index),
              children: [
                Expanded(flex: 11, child: _buildArtwork(index, page)),
                const SizedBox(width: 48),
                Expanded(flex: 9, child: _buildText(page)),
              ],
            )
          : Column(
              key: ValueKey(index),
              children: [
                Expanded(flex: 11, child: _buildArtwork(index, page)),
                const SizedBox(height: 12),
                Expanded(flex: 9, child: _buildText(page)),
              ],
            ),
    );
  }

  Widget _buildArtwork(int index, OnboardingData page) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    blue.withValues(alpha: 0.20),
                    background.withValues(alpha: 0),
                  ],
                ),
              ),
            ),

            Transform.rotate(
              angle: -0.07,
              child: Container(
                width: 250,
                height: 250,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withValues(alpha: 0.13),
                      blurRadius: 55,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: _buildChessboard(index),
              ),
            ),

            Positioned(
              top: 30,
              right: 12,
              child: _floatingCard(Icons.bolt_rounded, 'MAKE YOUR MOVE'),
            ),

            Positioned(
              bottom: 32,
              left: 0,
              child: _floatingCard(page.icon, 'CHECKMATE ARENA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChessboard(int pageIndex) {
    const lightSquare = Color(0xFFCBD8F0);
    const darkSquare = Color(0xFF263B61);

    const pieces = [
      ['â™œ', 'â™ž', 'â™', 'â™›', 'â™š', 'â™', 'â™ž', 'â™œ'],
      ['â™Ÿ', 'â™Ÿ', 'â™Ÿ', 'â™Ÿ', 'â™Ÿ', 'â™Ÿ', 'â™Ÿ', 'â™Ÿ'],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['â™™', 'â™™', 'â™™', 'â™™', 'â™™', 'â™™', 'â™™', 'â™™'],
      ['â™–', 'â™˜', 'â™—', 'â™•', 'â™”', 'â™—', 'â™˜', 'â™–'],
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: List.generate(8, (row) {
            return Expanded(
              child: Row(
                children: List.generate(8, (col) {
                  final isLight = (row + col).isEven;
                  final piece = pieces[row][col];

                  return Expanded(
                    child: Container(
                      color: isLight ? lightSquare : darkSquare,
                      alignment: Alignment.center,
                      child: piece.isEmpty
                          ? null
                          : FittedBox(
                              child: Text(
                                piece,
                                style: TextStyle(
                                  fontSize: 31,
                                  color: row < 2
                                      ? const Color(0xFF101827)
                                      : Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 2,
                                      offset: Offset(1, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _floatingCard(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9E2),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: blue, size: 17),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildText(OnboardingData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                page.eyebrow,
                style: const TextStyle(
                  color: Color(0xFF76A4FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 22),

            Text(
              page.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                height: 1.13,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              page.description,
              style: const TextStyle(color: muted, fontSize: 15, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(onboardingPages.length, (index) {
              final active = index == currentPage;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: active ? 28 : 6,
                decoration: BoxDecoration(
                  color: active ? blue : const Color(0xFF303B50),
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastPage ? 'Enter the Arena' : 'Continue',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          Text(
            '${currentPage + 1} OF ${onboardingPages.length}',
            style: const TextStyle(
              color: Color(0xFF65728A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
