import 'package:flutter/material.dart';
import '../config/theme.dart';

class SubscriptionScreen extends StatelessWidget {
  final VoidCallback? onGoHome;
  const SubscriptionScreen({super.key, this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Icon(Icons.star_rounded, color: LKTheme.gold, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text('Membership', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: LKTheme.textPrimary))),
                if (onGoHome != null)
                  GestureDetector(
                    onTap: onGoHome,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.home_rounded, size: 18, color: LKTheme.onAccent),
                        const SizedBox(width: 6),
                        Text('Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: LKTheme.onAccent)),
                      ]),
                    ),
                  ),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    // Current plan
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: LKTheme.gold.withValues(alpha: 0.1),
                        border: Border.all(color: LKTheme.gold, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YOUR CURRENT PLAN', style: TextStyle(fontSize: 12, color: LKTheme.gold, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          SizedBox(height: 4),
                          Text('Free', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: LKTheme.textPrimary)),
                          SizedBox(height: 4),
                          Text('1 connection', style: TextStyle(fontSize: 16, color: LKTheme.gold, fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('3-day switch cooldown', style: TextStyle(fontSize: 14, color: LKTheme.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // $5 plan
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: LKTheme.surface,
                        border: Border.all(color: LKTheme.gold, width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -28, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(10)),
                              child: Text('MOST POPULAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: LKTheme.onAccent)),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Premium', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LKTheme.textPrimary)),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('\$5', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: LKTheme.gold)),
                                  SizedBox(width: 4),
                                  Text('/ month', style: TextStyle(fontSize: 16, color: LKTheme.textSecondary)),
                                  SizedBox(width: 12),
                                  Text('or \$50/year', style: TextStyle(fontSize: 15, color: LKTheme.teal, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _feature('Connect up to 3 people'),
                              _feature('No ads'),
                              _feature('No cooldown on switching'),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity, height: 54,
                                child: Container(
                                  decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(14)),
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                    child: const Text('Subscribe Now', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // $8 plan
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: LKTheme.surface,
                        border: Border.all(color: LKTheme.isDarkBg ? LKTheme.border : LKTheme.contrastText.withValues(alpha: 0.12), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Premium Plus', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LKTheme.textPrimary)),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('\$8', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: LKTheme.gold)),
                              SizedBox(width: 4),
                              Text('/ month', style: TextStyle(fontSize: 16, color: LKTheme.textSecondary)),
                              SizedBox(width: 12),
                              Text('or \$80/year', style: TextStyle(fontSize: 15, color: LKTheme.teal, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _feature('Connect up to 10 people'),
                          _feature('No ads'),
                          _feature('No cooldown on switching'),
                          _feature('Priority notifications'),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity, height: 54,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(backgroundColor: LKTheme.surfaceAlt, foregroundColor: LKTheme.gold, side: BorderSide(color: LKTheme.gold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: const Text('Subscribe Now', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Cancel anytime. No commitment.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: LKTheme.textMuted, height: 1.4)),
                    const SizedBox(height: 16),

                    if (onGoHome != null)
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: Container(
                          decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                          child: ElevatedButton.icon(
                            onPressed: onGoHome,
                            icon: Icon(Icons.home_rounded, size: 24, color: LKTheme.onAccent),
                            label: Text('Home', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LKTheme.onAccent)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(Icons.check_rounded, size: 20, color: LKTheme.gold),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 16, color: LKTheme.textPrimary)),
      ]),
    );
  }
}
