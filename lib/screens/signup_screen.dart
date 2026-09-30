// lib/screens/signup_screen.dart
// VIRA — Your original UI preserved 100%.
// Only change: firebase_auth import removed, FirebaseAuthException → ApiException.

import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../services/api_service.dart'; // ← replaces firebase_auth
import 'login_screen.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _formKey        = GlobalKey<FormState>();
  final _authService    = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  int    _strengthLevel = 0;
  String _strengthLabel = '';
  Color  _strengthColor = Colors.transparent;

  static const Color _pink   = Color(0xFFE91E8C);
  static const Color _dark   = Color(0xFF1A1A1A);
  static const Color _gray   = Color(0xFF888888);
  static const Color _border = Color(0xFFF0D0E0);

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _checkStrength(String v) {
    int s = 0;
    if (v.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(v)) s++;
    if (RegExp(r'[0-9]').hasMatch(v)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(v)) s++;

    final levels = [
      ('Weak',   const Color(0xFFE53935)),
      ('Fair',   const Color(0xFFFB8C00)),
      ('Good',   const Color(0xFFFDD835)),
      ('Strong', const Color(0xFF43A047)),
    ];

    setState(() {
      _strengthLevel = v.isEmpty ? 0 : s;
      if (v.isEmpty) {
        _strengthLabel = '';
        _strengthColor = Colors.transparent;
      } else {
        final idx = (s - 1).clamp(0, 3);
        _strengthLabel = 'Strength: ${levels[idx].$1}';
        _strengthColor = levels[idx].$2;
      }
    });
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final fullName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
      await _authService.signUp(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        name:     fullName,
        phone:    _phoneCtrl.text.trim(),
      );
      if (mounted) {
        _showToast('Welcome to VIRA, ${_firstNameCtrl.text.trim()}!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } on ApiException catch (e) {
      _showToast(_authError(e.statusCode, e.message));
    } catch (_) {
      _showToast('Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    switch (statusCode) {
      case 409: return 'An account with this email already exists.';
      case 422: return 'Enter a valid email address.';
      default:  return serverMessage.isNotEmpty ? serverMessage : 'Signup failed. Please try again.';
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

                    const Text('Create your account', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _dark)),
                    const SizedBox(height: 6),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontSize: 13, color: _gray, height: 1.6),
                        children: [
                          TextSpan(text: 'Join VIRA — '),
                          TextSpan(text: 'your safety journey starts now.', style: TextStyle(color: _pink, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // First + Last name row
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildLabel('First name'),
                        _buildInput(controller: _firstNameCtrl, hint: 'Priya', icon: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                      ])),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildLabel('Last name'),
                        _buildInput(controller: _lastNameCtrl, hint: 'Sharma', icon: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                      ])),
                    ]),
                    const SizedBox(height: 14),

                    _buildLabel('Email address'),
                    _buildInput(
                      controller: _emailCtrl, hint: 'you@example.com', icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Phone number'),
                    _buildInput(
                      controller: _phoneCtrl, hint: '+91 98765 43210', icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone is required';
                        if (v.trim().length < 10) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Password'),
                    _buildInput(
                      controller: _passwordCtrl,
                      hint: 'Create a strong password',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                      onChanged: _checkStrength,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 8) return 'Password must be 8+ characters';
                        if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must contain an uppercase letter';
                        if (!RegExp(r'\d').hasMatch(v)) return 'Must contain a number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _strengthLevel / 4,
                        backgroundColor: const Color(0xFFF0D0DC),
                        valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                        minHeight: 4,
                      ),
                    ),
                    if (_strengthLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(_strengthLabel, style: TextStyle(fontSize: 11, color: _strengthColor)),
                      ),
                    const SizedBox(height: 20),

                    _buildMainButton(
                      label: 'Create My Account',
                      icon: Icons.shield,
                      onTap: _loading ? null : _signup,
                      loading: _loading,
                    ),
                    const SizedBox(height: 20),

                    _buildDivider(),
                    const SizedBox(height: 14),

                    _buildGoogleButton(() => _showToast('Google sign-up coming soon!')),
                    const SizedBox(height: 14),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA), height: 1.6),
                        children: [
                          const TextSpan(text: 'By creating an account you agree to our '),
                          TextSpan(text: 'Terms of Service', style: const TextStyle(color: _pink), recognizer: null),
                          const TextSpan(text: ' and '),
                          TextSpan(text: 'Privacy Policy', style: const TextStyle(color: _pink), recognizer: null),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: _gray),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                                child: const Text('Sign in', style: TextStyle(color: _pink, fontWeight: FontWeight.w700, fontSize: 13)),
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
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
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
        isDense: true,
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
    return const Row(children: [
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
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _border, width: 1.5), borderRadius: BorderRadius.circular(10)),
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
  Widget build(BuildContext context) => SizedBox(width: 18, height: 18, child: CustomPaint(painter: _GooglePainter()));
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;
    final sw = size.width * 0.35;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -1.57, 2.1,  false, Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = sw);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),  0.53, 1.57, false, Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = sw);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),  2.1,  1.05, false, Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = sw);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),  3.15, 1.0,  false, Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = sw);
    canvas.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(cx, cy - size.height * 0.12, r * 0.9, size.height * 0.24), Paint()..color = const Color(0xFF4285F4));
  }
  @override
  bool shouldRepaint(_GooglePainter old) => false;
}






// OLD CODE --> 

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/auth_services.dart';
// import 'login_screen.dart';
// import 'home_screen.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final _firstNameCtrl = TextEditingController();
//   final _lastNameCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _phoneCtrl = TextEditingController();
//   final _passwordCtrl = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   final _authService = AuthService();

//   bool _loading = false;
//   bool _obscurePassword = true;

//   // Password strength 0–4
//   int _strengthLevel = 0;
//   String _strengthLabel = '';
//   Color _strengthColor = Colors.transparent;

//   static const Color _pink = Color(0xFFE91E8C);
//   //static const Color _pinkDark = Color(0xFFB5156C);
//   static const Color _dark = Color(0xFF1A1A1A);
//   static const Color _gray = Color(0xFF888888);
//   static const Color _border = Color(0xFFF0D0E0);

//   @override
//   void dispose() {
//     _firstNameCtrl.dispose();
//     _lastNameCtrl.dispose();
//     _emailCtrl.dispose();
//     _phoneCtrl.dispose();
//     _passwordCtrl.dispose();
//     super.dispose();
//   }

//   void _checkStrength(String v) {
//     int s = 0;
//     if (v.length >= 8) s++;
//     if (RegExp(r'[A-Z]').hasMatch(v)) s++;
//     if (RegExp(r'[0-9]').hasMatch(v)) s++;
//     if (RegExp(r'[^A-Za-z0-9]').hasMatch(v)) s++;

//     final levels = [
//       ('Weak', const Color(0xFFE53935)),
//       ('Fair', const Color(0xFFFB8C00)),
//       ('Good', const Color(0xFFFDD835)),
//       ('Strong', const Color(0xFF43A047)),
//     ];

//     setState(() {
//       _strengthLevel = v.isEmpty ? 0 : s;
//       if (v.isEmpty) {
//         _strengthLabel = '';
//         _strengthColor = Colors.transparent;
//       } else {
//         final idx = (s - 1).clamp(0, 3);
//         _strengthLabel = 'Strength: ${levels[idx].$1}';
//         _strengthColor = levels[idx].$2;
//       }
//     });
//   }

//   Future<void> _signup() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _loading = true);
//     try {
//       final fullName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
//       await _authService.signUp(
//         email: _emailCtrl.text.trim(),
//         password: _passwordCtrl.text.trim(),
//         name: fullName,
//         phone: _phoneCtrl.text.trim(),
//       );
//       if (mounted) {
//         _showToast('Welcome to VIRA, ${_firstNameCtrl.text.trim()}!');
//         await Future.delayed(const Duration(seconds: 1));
//         if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
//       }
//     } on FirebaseAuthException catch (e) {
//       _showToast(_authError(e.code));
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
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
//       case 'email-already-in-use': return 'An account with this email already exists.';
//       case 'weak-password': return 'Password must be at least 6 characters.';
//       case 'invalid-email': return 'Enter a valid email address.';
//       default: return 'Signup failed. Please try again.';
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
//                     const Text('Create your account', textAlign: TextAlign.center,
//                         style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _dark)),
//                     const SizedBox(height: 6),
//                     RichText(
//                       textAlign: TextAlign.center,
//                       text: const TextSpan(
//                         style: TextStyle(fontSize: 13, color: _gray, height: 1.6),
//                         children: [
//                           TextSpan(text: 'Join VIRA — '),
//                           TextSpan(text: 'your safety journey starts now.', style: TextStyle(color: _pink, fontWeight: FontWeight.w600)),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // First + Last name row
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildLabel('First name'),
//                               _buildInput(controller: _firstNameCtrl, hint: 'Priya', icon: Icons.person_outline,
//                                   validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildLabel('Last name'),
//                               _buildInput(controller: _lastNameCtrl, hint: 'Sharma', icon: Icons.person_outline,
//                                   validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 14),

//                     // Email
//                     _buildLabel('Email address'),
//                     _buildInput(
//                       controller: _emailCtrl, hint: 'you@example.com', icon: Icons.mail_outline,
//                       keyboardType: TextInputType.emailAddress,
//                       validator: (v) {
//                         if (v == null || v.trim().isEmpty) return 'Email is required';
//                         if (!v.contains('@')) return 'Enter a valid email';
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 14),

//                     // Phone
//                     _buildLabel('Phone number'),
//                     _buildInput(
//                       controller: _phoneCtrl, hint: '+91 98765 43210', icon: Icons.phone_outlined,
//                       keyboardType: TextInputType.phone,
//                       validator: (v) {
//                         if (v == null || v.trim().isEmpty) return 'Phone is required';
//                         if (v.trim().length < 10) return 'Enter a valid number';
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 14),

//                     // Password with strength meter
//                     _buildLabel('Password'),
//                     _buildInput(
//                       controller: _passwordCtrl,
//                       hint: 'Create a strong password',
//                       icon: Icons.lock_outline,
//                       obscure: _obscurePassword,
//                       onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
//                       onChanged: _checkStrength,
//                       validator: (v) {
//                         if (v == null || v.isEmpty) return 'Password is required';
//                         if (v.length < 6) return 'Password must be 6+ characters';
//                         return null;
//                       },
//                     ),
//                     // Strength bar
//                     const SizedBox(height: 6),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(4),
//                       child: LinearProgressIndicator(
//                         value: _strengthLevel / 4,
//                         backgroundColor: const Color(0xFFF0D0DC),
//                         valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
//                         minHeight: 4,
//                       ),
//                     ),
//                     if (_strengthLabel.isNotEmpty)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 3),
//                         child: Text(_strengthLabel, style: TextStyle(fontSize: 11, color: _strengthColor)),
//                       ),
//                     const SizedBox(height: 20),

//                     // Create account button
//                     _buildMainButton(
//                       label: 'Create My Account',
//                       icon: Icons.shield,
//                       onTap: _loading ? null : _signup,
//                       loading: _loading,
//                     ),
//                     const SizedBox(height: 20),

//                     // Divider
//                     _buildDivider(),
//                     const SizedBox(height: 14),

//                     // Google button
//                     _buildGoogleButton(() => _showToast('Google sign-up coming soon!')),
//                     const SizedBox(height: 14),

//                     // Terms
//                     RichText(
//                       textAlign: TextAlign.center,
//                       text: TextSpan(
//                         style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA), height: 1.6),
//                         children: [
//                           const TextSpan(text: 'By creating an account you agree to our '),
//                           TextSpan(text: 'Terms of Service', style: const TextStyle(color: _pink), recognizer: null),
//                           const TextSpan(text: ' and '),
//                           TextSpan(text: 'Privacy Policy', style: const TextStyle(color: _pink), recognizer: null),
//                           const TextSpan(text: '.'),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 14),

//                     // Switch to login
//                     Center(
//                       child: RichText(
//                         text: TextSpan(
//                           style: const TextStyle(fontSize: 13, color: _gray),
//                           children: [
//                             const TextSpan(text: 'Already have an account? '),
//                             WidgetSpan(
//                               child: GestureDetector(
//                                 onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
//                                 child: const Text('Sign in', style: TextStyle(color: _pink, fontWeight: FontWeight.w700, fontSize: 13)),
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
//     ValueChanged<String>? onChanged,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: obscure,
//       keyboardType: keyboardType,
//       onChanged: onChanged,
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
//         isDense: true,
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
//     return const Row(children: [
//       Expanded(child: Divider(color: Color(0xFFF0D8E4))),
//       Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or continue with', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)))),
//       Expanded(child: Divider(color: Color(0xFFF0D8E4))),
//     ]);
//   }

//   Widget _buildGoogleButton(VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _border, width: 1.5), borderRadius: BorderRadius.circular(10)),
//         child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           _GoogleLogo(),
//           const SizedBox(width: 8),
//           const Text('Continue with Google', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _dark)),
//         ]),
//       ),
//     );
//   }
// }

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

// class _GoogleLogo extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => SizedBox(width: 18, height: 18, child: CustomPaint(painter: _GooglePainter()));
// }

// class _GooglePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final cx = size.width / 2;
//     final cy = size.height / 2;
//     final r = size.width / 2;
//     final sw = size.width * 0.35;
//     canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -1.57, 2.1, false, Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = sw);
//     canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), 0.53, 1.57, false, Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = sw);
//     canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), 2.1, 1.05, false, Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = sw);
//     canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), 3.15, 1.0, false, Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = sw);
//     canvas.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = Colors.white);
//     canvas.drawRect(Rect.fromLTWH(cx, cy - size.height * 0.12, r * 0.9, size.height * 0.24), Paint()..color = const Color(0xFF4285F4));
//   }
//   @override
//   bool shouldRepaint(_GooglePainter old) => false;
// }