import 'package:flutter/material.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.margin,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.25, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: shimmerColor.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.5)
        : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Multi-plot switcher skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 140, height: 20),
                    ShimmerBox(width: 32, height: 32, borderRadius: 16),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    ShimmerBox(width: 110, height: 32, borderRadius: 20),
                    SizedBox(width: 8),
                    ShimmerBox(width: 110, height: 32, borderRadius: 20),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Weather Card skeleton
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 130, height: 18),
                    ShimmerBox(width: 70, height: 18),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ShimmerBox(width: double.infinity, height: 42)),
                    SizedBox(width: 8),
                    Expanded(child: ShimmerBox(width: double.infinity, height: 42)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: ShimmerBox(width: double.infinity, height: 42)),
                    SizedBox(width: 8),
                    Expanded(child: ShimmerBox(width: double.infinity, height: 42)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Hydrological Gauge skeleton
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: const Column(
              children: [
                ShimmerBox(width: 180, height: 22),
                SizedBox(height: 16),
                ShimmerBox(width: 140, height: 140, borderRadius: 70),
                SizedBox(height: 16),
                ShimmerBox(width: double.infinity, height: 40),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Pump Runtime Card skeleton
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 50, height: 50, borderRadius: 14),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 120, height: 14),
                        SizedBox(height: 6),
                        ShimmerBox(width: 160, height: 24),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ShimmerBox(width: double.infinity, height: 44, borderRadius: 12),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Timeline section skeleton
          const ShimmerBox(width: 200, height: 20),
          const SizedBox(height: 12),
          const ShimmerBox(width: double.infinity, height: 70, margin: EdgeInsets.only(bottom: 10)),
          const ShimmerBox(width: double.infinity, height: 70, margin: EdgeInsets.only(bottom: 10)),
          const ShimmerBox(width: double.infinity, height: 70, margin: EdgeInsets.only(bottom: 10)),
        ],
      ),
    );
  }
}
