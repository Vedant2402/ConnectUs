import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 700;

                return Column(
                  children: [
                    Expanded(
                      flex: isCompact ? 5 : 6,
                      child: ClipPath(
                        clipper: const _OnboardingHeaderClipper(),
                        child: Container(
                          width: double.infinity,
                          color: const Color(0xFFDDEEE3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: isCompact ? 92 : 142,
                                height: isCompact ? 92 : 142,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(42),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF6F927E,
                                      ).withValues(alpha: 0.18),
                                      blurRadius: 30,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  'assets/images/connectus_app_icon.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(height: isCompact ? 12 : 24),
                              Text(
                                'ConnectUs',
                                style: const TextStyle(
                                  color: Color(0xFF25332C),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ).copyWith(fontSize: isCompact ? 23 : 28),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: isCompact ? 6 : 5,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          32,
                          isCompact ? 12 : 20,
                          32,
                          isCompact ? 12 : 24,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Welcome to ConnectUs!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Connect securely with the people who matter, '
                              'wherever you are.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                height: 1.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (!isCompact) const Spacer(),
                            if (isCompact) const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 22,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6F927E),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _pageDot(),
                                const SizedBox(width: 6),
                                _pageDot(),
                              ],
                            ),
                            SizedBox(height: isCompact ? 12 : 24),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            SizedBox(height: isCompact ? 2 : 10),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                              child: const Text('I already have an account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static Widget _pageDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFE2E5E3),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _OnboardingHeaderClipper extends CustomClipper<Path> {
  const _OnboardingHeaderClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height * 0.83)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 1.04,
        size.width,
        size.height * 0.83,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
