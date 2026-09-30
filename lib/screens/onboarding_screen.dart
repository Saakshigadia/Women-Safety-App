import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color _pink = Color(0xFFE91E8C);
  static const Color _bgDark = Color(0xFF1A0A12);

  final List<_OnboardSlide> _slides = const [
    _OnboardSlide(
      bgColor: Color(0xFF1A0A12),
      tag: '♥  Empowerment',
      quote: '"She remembered who she was — and the game changed."',
      author: 'Lalah Delia',
      role: 'Author & Spiritual Teacher',
      avatarPrimaryColor: Color(0xFFC2185B),
      avatarSkinColor: Color(0xFFF8BBD0),
      avatarHairColor: Color(0xFF880E4F),
      avatarBodyColor: Color(0xFFE91E8C),
    ),
    _OnboardSlide(
      bgColor: Color(0xFF0D1A2E),
      tag: '★  Courage',
      quote: '"A woman with a voice is, by definition, a strong woman."',
      author: 'Melinda Gates',
      role: 'Philanthropist & Author',
      avatarPrimaryColor: Color(0xFF1565C0),
      avatarSkinColor: Color(0xFFFFCCBC),
      avatarHairColor: Color(0xFF4A148C),
      avatarBodyColor: Color(0xFF1976D2),
    ),
    _OnboardSlide(
      bgColor: Color(0xFF1A120A),
      tag: '🛡  Safety',
      quote: '"Above all, be the heroine of your life, not the victim."',
      author: 'Nora Ephron',
      role: 'Writer & Filmmaker',
      avatarPrimaryColor: Color(0xFFE65100),
      avatarSkinColor: Color(0xFFFFE0B2),
      avatarHairColor: Color(0xFFBF360C),
      avatarBodyColor: Color(0xFFF4511E),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _goLogin() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  void _goSignup() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const SignupScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemCount: 3,
        itemBuilder: (context, index) {
          final slide = _slides[index];
          final isLast = index == 2;
          return _buildSlide(slide, index, isLast);
        },
      ),
    );
  }

  Widget _buildSlide(_OnboardSlide slide, int index, bool isLast) {
    return Container(
      color: slide.bgColor,
      child: Column(
        children: [
          // ── Top illustration ──────────────────────────────────
          Expanded(
            flex: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _AvatarPainter(slide: slide)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        slide.bgColor.withOpacity(0.1),
                        slide.bgColor.withOpacity(0.88),
                      ],
                    ),
                  ),
                ),
                // Brand
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: _pink, shape: BoxShape.circle),
                      child: const Icon(Icons.shield, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 9),
                    const Text('VIRA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 2.5)),
                  ]),
                ),
                // Skip
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 20,
                  child: GestureDetector(
                    onTap: _goLogin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        border: Border.all(color: Colors.white.withOpacity(0.22)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Skip', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom content — wrapped in SingleChildScrollView ──
          Expanded(
            flex: 40,
            child: Container(
              color: slide.bgColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _pink.withOpacity(0.15),
                        border: Border.all(color: _pink.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(slide.tag, style: const TextStyle(color: _pink, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    ),
                    const SizedBox(height: 10),

                    // Quote
                    Text(slide.quote, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, height: 1.45)),
                    const SizedBox(height: 6),

                    // Author
                    Text(slide.author, style: const TextStyle(fontSize: 13, color: Color(0xFFC8A0B8), fontStyle: FontStyle.italic)),
                    Text(slide.role, style: const TextStyle(fontSize: 13, color: _pink, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),

                    // Dots + buttons
                    if (!isLast) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: List.generate(3, (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 7),
                            width: _currentPage == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i ? _pink : const Color(0xFF3D1A2E),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ))),
                          GestureDetector(
                            onTap: _nextPage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(24)),
                              child: const Row(children: [
                                Text('Next', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Last slide dots
                      Row(children: List.generate(3, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 7),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? _pink : const Color(0xFF3D1A2E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ))),
                      const SizedBox(height: 16),

                      // Get Started
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: _goSignup,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(12)),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.shield, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text("Get Started — It's Free", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Sign in link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, color: Color(0xFFC8A0B8)),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: _goLogin,
                                  child: const Text('Sign in', style: TextStyle(color: _pink, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardSlide {
  final Color bgColor;
  final String tag;
  final String quote;
  final String author;
  final String role;
  final Color avatarPrimaryColor;
  final Color avatarSkinColor;
  final Color avatarHairColor;
  final Color avatarBodyColor;

  const _OnboardSlide({
    required this.bgColor, required this.tag, required this.quote,
    required this.author, required this.role, required this.avatarPrimaryColor,
    required this.avatarSkinColor, required this.avatarHairColor, required this.avatarBodyColor,
  });
}

class _AvatarPainter extends CustomPainter {
  final _OnboardSlide slide;
  const _AvatarPainter({required this.slide});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, size.height * 1.08), width: size.width * 0.72, height: size.height * 0.55),
        Paint()..color = slide.avatarHairColor.withOpacity(0.6));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, size.height * 0.62), width: size.width * 0.36, height: size.height * 0.68),
        Paint()..color = slide.avatarBodyColor);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, size.height * 0.44), width: size.width * 0.235, height: size.height * 0.31),
        Paint()..color = slide.avatarSkinColor);
    final hairPath = Path()
      ..moveTo(cx - size.width * 0.23, size.height * 0.375)
      ..quadraticBezierTo(cx, size.height * 0.275, cx + size.width * 0.23, size.height * 0.375)
      ..quadraticBezierTo(cx + size.width * 0.25, size.height * 0.29, cx, size.height * 0.255)
      ..quadraticBezierTo(cx - size.width * 0.25, size.height * 0.29, cx - size.width * 0.23, size.height * 0.375)
      ..close();
    canvas.drawPath(hairPath, Paint()..color = slide.avatarHairColor);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, size.height * 0.36), width: size.width * 0.255, height: size.height * 0.082),
        Paint()..color = slide.avatarPrimaryColor);
    final eyePaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(cx - size.width * 0.07, size.height * 0.445), size.width * 0.028, eyePaint);
    canvas.drawCircle(Offset(cx + size.width * 0.07, size.height * 0.445), size.width * 0.028, eyePaint);
    canvas.drawCircle(Offset(cx - size.width * 0.065, size.height * 0.44), size.width * 0.010, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + size.width * 0.075, size.height * 0.44), size.width * 0.010, Paint()..color = Colors.white);
    final smilePath = Path()
      ..moveTo(cx - size.width * 0.048, size.height * 0.485)
      ..quadraticBezierTo(cx, size.height * 0.51, cx + size.width * 0.048, size.height * 0.485);
    canvas.drawPath(smilePath, Paint()..color = const Color(0xFFE91E8C)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.013..strokeCap = StrokeCap.round);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - size.width * 0.42, size.height * 0.585, size.width * 0.14, size.height * 0.38), Radius.circular(size.width * 0.07)), Paint()..color = slide.avatarBodyColor);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + size.width * 0.28, size.height * 0.585, size.width * 0.14, size.height * 0.38), Radius.circular(size.width * 0.07)), Paint()..color = slide.avatarBodyColor);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - size.width * 0.175, size.height * 0.86), width: size.width * 0.13, height: size.height * 0.09), Paint()..color = slide.avatarHairColor);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + size.width * 0.175, size.height * 0.86), width: size.width * 0.13, height: size.height * 0.09), Paint()..color = slide.avatarHairColor);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.22), size.width * 0.072, Paint()..color = slide.bgColor.withOpacity(0.85));
    final checkPath = Path()
      ..moveTo(size.width * 0.772, size.height * 0.22)
      ..lineTo(size.width * 0.794, size.height * 0.238)
      ..lineTo(size.width * 0.828, size.height * 0.202);
    canvas.drawPath(checkPath, Paint()..color = const Color(0xFFE91E8C)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.015..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.28), size.width * 0.052, Paint()..color = slide.bgColor.withOpacity(0.85));
    final textPainter = TextPainter(text: const TextSpan(text: '♀', style: TextStyle(fontSize: 22, color: Color(0xFFE91E8C))), textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, Offset(size.width * 0.174, size.height * 0.248));
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.4), size.width * 0.015, Paint()..color = const Color(0xFFE91E8C).withOpacity(0.35));
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.52), size.width * 0.01, Paint()..color = const Color(0xFFE91E8C).withOpacity(0.25));
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.slide != slide;
}