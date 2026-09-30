// lib/screens/login_screen.dart
// VIRA — Your original UI preserved 100%.
// Only change: firebase_auth import removed, FirebaseAuthException → ApiException.

import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../services/api_service.dart'; // ← replaces firebase_auth
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  static const Color _pink = Color(0xFFE91E8C);
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _gray = Color(0xFF888888);
  static const Color _border = Color(0xFFF0D0E0);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on ApiException catch (e) {
      _showToast(_authError(e.statusCode, e.message));
    } catch (_) {
      _showToast('Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _showToast('Enter your email first');
      return;
    }
    await _authService.resetPassword(_emailCtrl.text.trim());
    _showToast('Reset link sent to your email!');
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: _pink, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: const Color(0xFF1A0A12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _authError(int statusCode, String serverMessage) {
    // Map FastAPI HTTP status codes to user-friendly messages
    switch (statusCode) {
      case 404: return 'No account found with this email.';
      case 401: return 'Incorrect password. Try again.';
      case 422: return 'Enter a valid email address.';
      case 429: return 'Too many attempts. Try later.';
      default:  return serverMessage.isNotEmpty ? serverMessage : 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Your original build method — untouched ────────────────────────────
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: const BoxDecoration(color: _pink, shape: BoxShape.circle),
                          child: const Icon(Icons.shield, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(text: 'VIRA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _pink, letterSpacing: 3)),
                              WidgetSpan(child: _PinkDot()),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    const Text('Welcome back', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _dark)),
                    const SizedBox(height: 6),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontSize: 13, color: _gray, height: 1.6),
                        children: [
                          TextSpan(text: 'Sign in to your account — '),
                          TextSpan(text: 'stay safe, stay strong.', style: TextStyle(color: _pink, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Email address'),
                    _buildInput(
                      controller: _emailCtrl,
                      hint: 'you@example.com',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Password'),
                    _buildInput(
                      controller: _passwordCtrl,
                      hint: 'Your password',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _resetPassword,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Forgot password?', style: TextStyle(fontSize: 12, color: _pink)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    _buildMainButton(
                      label: 'Sign In',
                      icon: Icons.login,
                      onTap: _loading ? null : _login,
                      loading: _loading,
                    ),
                    const SizedBox(height: 20),

                    _buildDivider(),
                    const SizedBox(height: 14),

                    _buildGoogleButton(() => _showToast('Google sign-in coming soon!')),
                    const SizedBox(height: 18),

                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: _gray),
                          children: [
                            const TextSpan(text: 'New to VIRA? '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                                child: const Text('Create a free account', style: TextStyle(color: _pink, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF555555), letterSpacing: 0.6)),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
        prefixIcon: Icon(icon, color: const Color(0xFFCCCCCC), size: 18),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFFCCCCCC), size: 18),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFFDFAFA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _pink, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      ),
    );
  }

  Widget _buildMainButton({required String label, required IconData icon, VoidCallback? onTap, bool loading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(children: const [
      Expanded(child: Divider(color: Color(0xFFF0D8E4))),
      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or continue with', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)))),
      Expanded(child: Divider(color: Color(0xFFF0D8E4))),
    ]);
  }

  Widget _buildGoogleButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _GoogleLogo(),
          const SizedBox(width: 8),
          const Text('Continue with Google', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _dark)),
        ]),
      ),
    );
  }
}

// ── Pink dot + Google logo — your originals, unchanged ────────────────────────

class _PinkDot extends StatelessWidget {
  const _PinkDot();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 2, bottom: 12),
      child: CircleAvatar(radius: 3.5, backgroundColor: Color(0xFFE91E8C)),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 18, height: 18, child: CustomPaint(painter: _GooglePainter()));
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -1.57, 2.1, false, Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.35);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),  0.53, 1.57, false, Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.35);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),  2.10, 1.05, false, Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.35);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),  3.15, 1.00, false, Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.35);
    canvas.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(cx, cy - size.height * 0.12, r * 0.9, size.height * 0.24), Paint()..color = const Color(0xFF4285F4));
  }
  @override
  bool shouldRepaint(_GooglePainter old) => false;
}








// OLD CODE PREVIOUS ONE -->

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/auth_services.dart';
// import 'signup_screen.dart';
// import 'home_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _emailCtrl = TextEditingController();
//   final _passwordCtrl = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   final _authService = AuthService();

//   bool _loading = false;
//   bool _obscurePassword = true;

//   static const Color _pink = Color(0xFFE91E8C);
//   //static const Color _pinkDark = Color(0xFFB5156C);
//   //static const Color _pinkLight = Color(0xFFFFF0F5);
//   static const Color _dark = Color(0xFF1A1A1A);
//   static const Color _gray = Color(0xFF888888);
//   static const Color _border = Color(0xFFF0D0E0);

//   @override
//   void dispose() {
//     _emailCtrl.dispose();
//     _passwordCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _login() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _loading = true);
//     try {
//       await _authService.signIn(email: _emailCtrl.text.trim(), password: _passwordCtrl.text.trim());
//       if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
//     } on FirebaseAuthException catch (e) {
//       _showToast(_authError(e.code));
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _resetPassword() async {
//     if (_emailCtrl.text.trim().isEmpty) { _showToast('Enter your email first'); return; }
//     await _authService.resetPassword(_emailCtrl.text.trim());
//     _showToast('Reset link sent to your email!');
//   }

//   void _showToast(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(children: [const Icon(Icons.check_circle, color: _pink, size: 18), const SizedBox(width: 8), Expanded(child: Text(msg))]),
//         backgroundColor: const Color(0xFF1A0A12),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   String _authError(String code) {
//     switch (code) {
//       case 'user-not-found': return 'No account found with this email.';
//       case 'wrong-password': return 'Incorrect password. Try again.';
//       case 'invalid-email': return 'Enter a valid email address.';
//       case 'too-many-requests': return 'Too many attempts. Try later.';
//       default: return 'Login failed. Please try again.';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFFF5F8),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//             child: Container(
//               constraints: const BoxConstraints(maxWidth: 420),
//               padding: const EdgeInsets.all(32),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: _border),
//               ),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     // Logo
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           width: 44, height: 44,
//                           decoration: const BoxDecoration(color: _pink, shape: BoxShape.circle),
//                           child: const Icon(Icons.shield, color: Colors.white, size: 22),
//                         ),
//                         const SizedBox(width: 10),
//                         RichText(
//                           text: const TextSpan(
//                             children: [
//                               TextSpan(text: 'VIRA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _pink, letterSpacing: 3)),
//                               WidgetSpan(child: _PinkDot()),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 22),

//                     // Title
//                     const Text('Welcome back', textAlign: TextAlign.center,
//                         style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _dark)),
//                     const SizedBox(height: 6),
//                     RichText(
//                       textAlign: TextAlign.center,
//                       text: const TextSpan(
//                         style: TextStyle(fontSize: 13, color: _gray, height: 1.6),
//                         children: [
//                           TextSpan(text: 'Sign in to your account — '),
//                           TextSpan(text: 'stay safe, stay strong.', style: TextStyle(color: _pink, fontWeight: FontWeight.w600)),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // Email
//                     _buildLabel('Email address'),
//                     _buildInput(
//                       controller: _emailCtrl,
//                       hint: 'you@example.com',
//                       icon: Icons.mail_outline,
//                       keyboardType: TextInputType.emailAddress,
//                       validator: (v) {
//                         if (v == null || v.trim().isEmpty) return 'Email is required';
//                         if (!v.contains('@')) return 'Enter a valid email';
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 14),

//                     // Password
//                     _buildLabel('Password'),
//                     _buildInput(
//                       controller: _passwordCtrl,
//                       hint: 'Your password',
//                       icon: Icons.lock_outline,
//                       obscure: _obscurePassword,
//                       onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
//                       validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
//                     ),
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: GestureDetector(
//                         onTap: _resetPassword,
//                         child: const Padding(
//                           padding: EdgeInsets.symmetric(vertical: 6),
//                           child: Text('Forgot password?', style: TextStyle(fontSize: 12, color: _pink)),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 6),

//                     // Sign In button
//                     _buildMainButton(
//                       label: 'Sign In',
//                       icon: Icons.login,
//                       onTap: _loading ? null : _login,
//                       loading: _loading,
//                     ),
//                     const SizedBox(height: 20),

//                     // Divider
//                     _buildDivider(),
//                     const SizedBox(height: 14),

//                     // Google button
//                     _buildGoogleButton(() => _showToast('Google sign-in coming soon!')),
//                     const SizedBox(height: 18),

//                     // Switch to signup
//                     Center(
//                       child: RichText(
//                         text: TextSpan(
//                           style: const TextStyle(fontSize: 13, color: _gray),
//                           children: [
//                             const TextSpan(text: 'New to VIRA? '),
//                             WidgetSpan(
//                               child: GestureDetector(
//                                 onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
//                                 child: const Text('Create a free account', style: TextStyle(color: _pink, fontWeight: FontWeight.w700, fontSize: 13)),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLabel(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 5),
//       child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF555555), letterSpacing: 0.6)),
//     );
//   }

//   Widget _buildInput({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     bool obscure = false,
//     VoidCallback? onToggleObscure,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: obscure,
//       keyboardType: keyboardType,
//       validator: validator,
//       style: const TextStyle(fontSize: 14, color: _dark),
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
//         prefixIcon: Icon(icon, color: const Color(0xFFCCCCCC), size: 18),
//         suffixIcon: onToggleObscure != null
//             ? IconButton(
//                 icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFFCCCCCC), size: 18),
//                 onPressed: onToggleObscure,
//               )
//             : null,
//         filled: true,
//         fillColor: const Color(0xFFFDFAFA),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border, width: 1.5)),
//         enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border, width: 1.5)),
//         focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _pink, width: 1.5)),
//         errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
//         contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
//       ),
//     );
//   }

//   Widget _buildMainButton({required String label, required IconData icon, VoidCallback? onTap, bool loading = false}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 14),
//         decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(10)),
//         child: Center(
//           child: loading
//               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
//               : Row(mainAxisSize: MainAxisSize.min, children: [
//                   Icon(icon, color: Colors.white, size: 18),
//                   const SizedBox(width: 8),
//                   Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
//                 ]),
//         ),
//       ),
//     );
//   }

//   Widget _buildDivider() {
//     return Row(children: [
//       const Expanded(child: Divider(color: Color(0xFFF0D8E4))),
//       const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or continue with', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)))),
//       const Expanded(child: Divider(color: Color(0xFFF0D8E4))),
//     ]);
//   }

//   Widget _buildGoogleButton(VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: _border, width: 1.5),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           _GoogleLogo(),
//           const SizedBox(width: 8),
//           const Text('Continue with Google', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _dark)),
//         ]),
//       ),
//     );
//   }
// }

// // Pink dot after VIRA
// class _PinkDot extends StatelessWidget {
//   const _PinkDot();
//   @override
//   Widget build(BuildContext context) {
//     return const Padding(
//       padding: EdgeInsets.only(left: 2, bottom: 12),
//       child: CircleAvatar(radius: 3.5, backgroundColor: Color(0xFFE91E8C)),
//     );
//   }
// }

// // Google G logo
// class _GoogleLogo extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 18, height: 18,
//       child: CustomPaint(painter: _GooglePainter()),
//     );
//   }
// }

// class _GooglePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final cx = size.width / 2;
//     final cy = size.height / 2;
//     final r = size.width / 2;

//     // Red arc (top)
//     canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
//         -1.57, 2.1, false, Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.35);
//     // Blue arc (right)
//     canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
//         0.53, 1.57, false, Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.35);
//     // Yellow arc (bottom)
//     canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
//         2.1, 1.05, false, Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.35);
//     // Green arc (left)
//     canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
//         3.15, 1.0, false, Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = size.width * 0.35);
//     // White fill center
//     canvas.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = Colors.white);
//     // Blue bar (the G crossbar)
//     canvas.drawRect(Rect.fromLTWH(cx, cy - size.height * 0.12, r * 0.9, size.height * 0.24),
//         Paint()..color = const Color(0xFF4285F4));
//   }

//   @override
//   bool shouldRepaint(_GooglePainter old) => false;
// }
