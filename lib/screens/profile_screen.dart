// lib/screens/profile_screen.dart
// VIRA — Your original UI preserved 100%.
// Changes: firebase_auth removed, FirestoreService/AuthService now call FastAPI.
// StreamBuilder kept — firestore_services.dart provides a one-shot REST stream.

import 'package:flutter/material.dart';
import '../services/firestore_services.dart';
import '../services/auth_services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _editing = false;
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await _firestoreService.updateUserProfile({
        'name':  _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      setState(() => _editing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder kept — getUserStream() emits once from GET /profile
    return StreamBuilder<dynamic>(
      stream: _firestoreService.getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C)));
        }

        // snapshot.data is a _FakeSnapshot — call .data() just like Firestore
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name     = data['name']  ?? 'User';
        final email    = data['email'] ?? '';
        final phone    = data['phone'] ?? '';
        final initials = name.isNotEmpty
            ? name.split(' ').map((w) => w[0]).take(2).join().toUpperCase()
            : 'U';

        if (!_editing) {
          _nameCtrl.text  = name;
          _phoneCtrl.text = phone;
        }

        // ── Your original build tree — untouched ──────────────────────────
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: const Color(0xFFE91E8C),
                    child: Text(initials, style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  if (!_editing)
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _editing = true),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFFE91E8C), shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (!_editing) ...[
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],

              const SizedBox(height: 24),

              // Profile Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Personal Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 16),

                      if (_editing) ...[
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                        ),
                        const SizedBox(height: 20),
                        Row(children: [
                          Expanded(child: OutlinedButton(
                            onPressed: () => setState(() => _editing = false),
                            child: const Text('Cancel'),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: ElevatedButton(
                            onPressed: _saving ? null : _saveProfile,
                            child: _saving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save'),
                          )),
                        ]),
                      ] else ...[
                        _profileRow(Icons.person_outline, 'Name', name),
                        const Divider(height: 20),
                        _profileRow(Icons.email_outlined, 'Email', email),
                        const Divider(height: 20),
                        _profileRow(Icons.phone_outlined, 'Phone', phone.isNotEmpty ? phone : 'Not set'),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Settings Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  _menuItem(Icons.history, 'SOS History', () {}),
                  const Divider(height: 1, indent: 56),
                  _menuItem(Icons.lock_outline, 'Change Password', () async {
                    if (email.isNotEmpty) {
                      await _authService.resetPassword(email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset email sent!'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  }),
                  const Divider(height: 1, indent: 56),
                  _menuItem(Icons.logout, 'Sign Out', _signOut, color: Colors.red),
                ]),
              ),

              const SizedBox(height: 30),
              const Text('VIRA v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: const Color(0xFFE91E8C), size: 20),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 15)),
      ]),
    ]);
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFFE91E8C)),
      title: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}










// OLD CODE PREVIOUS ONE -->

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/firestore_services.dart';
// import '../services/auth_services.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final AuthService _authService = AuthService();

//   bool _editing = false;
//   final _nameCtrl = TextEditingController();
//   final _phoneCtrl = TextEditingController();
//   bool _saving = false;

//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _phoneCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _saveProfile() async {
//     setState(() => _saving = true);
//     try {
//       await _firestoreService.updateUserProfile({
//         'name': _nameCtrl.text.trim(),
//         'phone': _phoneCtrl.text.trim(),
//       });
//       await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameCtrl.text.trim());
//       setState(() => _editing = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   Future<void> _signOut() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Sign Out'),
//         content: const Text('Are you sure you want to sign out?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Sign Out'),
//           ),
//         ],
//       ),
//     );
//     if (confirm == true) {
//       await _authService.signOut();
//       if (mounted) Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<dynamic>(
//       stream: _firestoreService.getUserStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C)));
//         }

//         final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
//         final name = data['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'User';
//         final email = data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
//         final phone = data['phone'] ?? '';
//         final initials = name.isNotEmpty ? name.split(' ').map((w) => w[0]).take(2).join().toUpperCase() : 'U';

//         if (!_editing) {
//           _nameCtrl.text = name;
//           _phoneCtrl.text = phone;
//         }

//         return SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//           child: Column(
//             children: [
//               // Avatar
//               Stack(
//                 children: [
//                   CircleAvatar(
//                     radius: 54,
//                     backgroundColor: const Color(0xFFE91E8C),
//                     child: Text(initials, style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
//                   ),
//                   if (!_editing)
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: GestureDetector(
//                         onTap: () => setState(() => _editing = true),
//                         child: Container(
//                           padding: const EdgeInsets.all(6),
//                           decoration: const BoxDecoration(
//                             color: Color(0xFFE91E8C),
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(Icons.edit, color: Colors.white, size: 16),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 12),

//               if (!_editing) ...[
//                 Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
//                 const SizedBox(height: 4),
//                 Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
//               ],

//               const SizedBox(height: 24),

//               // Profile Card
//               Card(
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       const Text('Personal Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
//                       const SizedBox(height: 16),

//                       if (_editing) ...[
//                         TextFormField(
//                           controller: _nameCtrl,
//                           textCapitalization: TextCapitalization.words,
//                           decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
//                         ),
//                         const SizedBox(height: 14),
//                         TextFormField(
//                           controller: _phoneCtrl,
//                           keyboardType: TextInputType.phone,
//                           decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
//                         ),
//                         const SizedBox(height: 20),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: OutlinedButton(
//                                 onPressed: () => setState(() => _editing = false),
//                                 child: const Text('Cancel'),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: ElevatedButton(
//                                 onPressed: _saving ? null : _saveProfile,
//                                 child: _saving
//                                     ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
//                                     : const Text('Save'),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ] else ...[
//                         _profileRow(Icons.person_outline, 'Name', name),
//                         const Divider(height: 20),
//                         _profileRow(Icons.email_outlined, 'Email', email),
//                         const Divider(height: 20),
//                         _profileRow(Icons.phone_outlined, 'Phone', phone.isNotEmpty ? phone : 'Not set'),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // Safety Settings Card
//               Card(
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 child: Column(
//                   children: [
//                     _menuItem(Icons.history, 'SOS History', () {}),
//                     const Divider(height: 1, indent: 56),
//                     _menuItem(Icons.lock_outline, 'Change Password', () async {
//                       final user = FirebaseAuth.instance.currentUser;
//                       if (user?.email != null) {
//                         await _authService.resetPassword(user!.email!);
//                         if (mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('Password reset email sent!'), backgroundColor: Colors.green),
//                           );
//                         }
//                       }
//                     }),
//                     const Divider(height: 1, indent: 56),
//                     _menuItem(Icons.logout, 'Sign Out', _signOut, color: Colors.red),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 30),
//               const Text('SafeHer v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _profileRow(IconData icon, String label, String value) {
//     return Row(
//       children: [
//         Icon(icon, color: const Color(0xFFE91E8C), size: 20),
//         const SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
//             Text(value, style: const TextStyle(fontSize: 15)),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
//     return ListTile(
//       leading: Icon(icon, color: color ?? const Color(0xFFE91E8C)),
//       title: Text(label, style: TextStyle(color: color)),
//       trailing: const Icon(Icons.chevron_right, color: Colors.grey),
//       onTap: onTap,
//     );
//   }
// }
