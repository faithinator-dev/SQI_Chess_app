import 'package:flutter/material.dart';

class CommunityLoadingSkeleton extends StatefulWidget {
  const CommunityLoadingSkeleton({super.key});

  @override
  State<CommunityLoadingSkeleton> createState() =>
      _CommunityLoadingSkeletonState();
}

class _CommunityLoadingSkeletonState extends State<CommunityLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFFD7DCE2);
    const highlight = Color(0xFFF8F9FA);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shift = (_controller.value * 2) - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(shift - 1, 0),
            end: Alignment(shift + 1, 0),
            colors: [base, highlight, base],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(bounds),
          child: child,
        );
      },
      child: Column(
        children: [
          for (var index = 0; index < 3; index++)
            Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _block(width: 42, height: 42, radius: 21, color: base),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _block(width: 150, height: 14, color: base),
                              const SizedBox(height: 8),
                              _block(width: 90, height: 11, color: base),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _block(width: double.infinity, height: 13, color: base),
                    const SizedBox(height: 8),
                    _block(width: 230, height: 13, color: base),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _block(width: 58, height: 12, color: base),
                        const SizedBox(width: 14),
                        _block(width: 58, height: 12, color: base),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _block({
    required double width,
    required double height,
    required Color color,
    double radius = 7,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
