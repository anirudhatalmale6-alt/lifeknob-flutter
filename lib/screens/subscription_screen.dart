import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  final VoidCallback? onGoHome;
  const SubscriptionScreen({super.key, this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF39C12), size: 28),
                const SizedBox(width: 10),
                const Expanded(child: Text('Subscription', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                if (onGoHome != null)
                  GestureDetector(
                    onTap: onGoHome,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF27AE60), borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.home_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
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
                        color: const Color(0xFFF0FAF4),
                        border: Border.all(color: const Color(0xFF27AE60), width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YOUR CURRENT PLAN', style: TextStyle(fontSize: 12, color: Color(0xFF27AE60), fontWeight: FontWeight.w700, letterSpacing: 1)),
                          SizedBox(height: 4),
                          Text('Free', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
                          SizedBox(height: 4),
                          Text('1 connection', style: TextStyle(fontSize: 16, color: Color(0xFF27AE60), fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('3-day switch cooldown', style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Premium Monthly
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFF39C12), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -28, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF39C12), borderRadius: BorderRadius.circular(10)),
                              child: const Text('MOST POPULAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Premium Monthly', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                              const SizedBox(height: 6),
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('\$4.99', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF27AE60))),
                                  SizedBox(width: 4),
                                  Text('/ month', style: TextStyle(fontSize: 16, color: Color(0xFF95A5A6))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _feature('Connect up to 5 people'),
                              _feature('Switch connections freely'),
                              _feature('No ads'),
                              _feature('Priority notifications'),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity, height: 54,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF39C12), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                  child: const Text('Subscribe Now', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Premium Yearly
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!, width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Premium Yearly', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50))),
                          const SizedBox(height: 6),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('\$39.99', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF27AE60))),
                              SizedBox(width: 4),
                              Text('/ year', style: TextStyle(fontSize: 16, color: Color(0xFF95A5A6))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Save 33% — \$3.33/month', style: TextStyle(fontSize: 15, color: Color(0xFF27AE60), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          _feature('Everything in Monthly'),
                          _feature('Best value'),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity, height: 54,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: const Text('Subscribe Now', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'If subscription expires, you keep your first connected person.\nCancel anytime. No commitment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.4),
                    ),

                    const SizedBox(height: 16),

                    // Big Home button
                    if (onGoHome != null)
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton.icon(
                          onPressed: onGoHome,
                          icon: const Icon(Icons.home_rounded, size: 24),
                          label: const Text('Home', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
        const Icon(Icons.check_rounded, size: 20, color: Color(0xFF27AE60)),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50))),
      ]),
    );
  }
}
