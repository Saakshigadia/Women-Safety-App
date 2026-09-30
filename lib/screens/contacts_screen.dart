// NEW CODE -->

// import 'package:flutter/material.dart';
// import '../services/firestore_services.dart';
// import '../services/sos_service.dart';

// class ContactsScreen extends StatefulWidget {
//   const ContactsScreen({super.key});

//   @override
//   State<ContactsScreen> createState() => _ContactsScreenState();
// }

// class _ContactsScreenState extends State<ContactsScreen> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final SOSService _sosService = SOSService();

//   void _showAddContactDialog() {
//     final nameCtrl = TextEditingController();
//     final phoneCtrl = TextEditingController();
//     final relationCtrl = TextEditingController();
//     final formKey = GlobalKey<FormState>();

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (_) => Padding(
//         padding: EdgeInsets.only(
//           left: 24, right: 24, top: 20,
//           bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//         ),
//         child: Form(
//           key: formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Handle
//               Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
//               const SizedBox(height: 16),
//               const Text('Add Trusted Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 20),

//               TextFormField(
//                 controller: nameCtrl,
//                 textCapitalization: TextCapitalization.words,
//                 decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
//                 validator: (v) => (v == null || v.trim().isEmpty) ? 'Name required' : null,
//               ),
//               const SizedBox(height: 14),
//               TextFormField(
//                 controller: phoneCtrl,
//                 keyboardType: TextInputType.phone,
//                 decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty) return 'Phone required';
//                   if (v.trim().length < 10) return 'Enter a valid number';
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 14),
//               TextFormField(
//                 controller: relationCtrl,
//                 textCapitalization: TextCapitalization.words,
//                 decoration: const InputDecoration(
//                   labelText: 'Relation',
//                   prefixIcon: Icon(Icons.favorite_outline),
//                   hintText: 'e.g. Mother, Friend, Sister',
//                 ),
//                 validator: (v) => (v == null || v.trim().isEmpty) ? 'Relation required' : null,
//               ),
//               const SizedBox(height: 24),

//               ElevatedButton(
//                 onPressed: () async {
//                   if (!formKey.currentState!.validate()) return;
//                   Navigator.pop(context);
//                   await _firestoreService.addTrustedContact(
//                     name: nameCtrl.text.trim(),
//                     phone: phoneCtrl.text.trim(),
//                     relation: relationCtrl.text.trim(),
//                   );
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Contact added!'), backgroundColor: Colors.green),
//                     );
//                   }
//                 },
//                 child: const Text('Add Contact'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _deleteContact(Map<String, dynamic> contact) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Remove Contact'),
//         content: Text('Remove ${contact['name']} from trusted contacts?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           TextButton(
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Remove'),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       await _firestoreService.removeTrustedContact(contact);
//     }
//   }

//   Color _avatarColor(int index) {
//     final colors = [
//       const Color(0xFFE91E8C),
//       const Color(0xFF7C4DFF),
//       Colors.teal,
//       Colors.orange,
//       Colors.blue,
//     ];
//     return colors[index % colors.length];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder<List<Map<String, dynamic>>>(
//         stream: _firestoreService.getTrustedContacts(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C)));
//           }

//           final contacts = snapshot.data ?? [];

//           if (contacts.isEmpty) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(32),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.contacts_outlined, size: 80, color: Colors.grey[300]),
//                     const SizedBox(height: 16),
//                     const Text('No trusted contacts yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey)),
//                     const SizedBox(height: 8),
//                     const Text('Add people who will receive your SOS alerts', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
//                     const SizedBox(height: 24),
//                     ElevatedButton.icon(
//                       onPressed: _showAddContactDialog,
//                       icon: const Icon(Icons.add),
//                       label: const Text('Add Contact'),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }

//           return ListView(
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             children: [
//               // Info banner
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 margin: const EdgeInsets.only(bottom: 16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFCE4EC),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.info_outline, color: Color(0xFFE91E8C), size: 20),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         '${contacts.length} trusted contact${contacts.length > 1 ? 's' : ''}. First contact will be called during SOS.',
//                         style: const TextStyle(fontSize: 13, color: Color(0xFF880E4F)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               ...contacts.asMap().entries.map((entry) {
//                 final i = entry.key;
//                 final contact = entry.value;
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 10),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                   child: ListTile(
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     leading: CircleAvatar(
//                       backgroundColor: _avatarColor(i),
//                       child: Text(
//                         (contact['name'] as String).isNotEmpty
//                             ? (contact['name'] as String)[0].toUpperCase()
//                             : '?',
//                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     title: Text(contact['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(contact['phone'] ?? '', style: const TextStyle(fontSize: 13)),
//                         Text(contact['relation'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFFE91E8C))),
//                       ],
//                     ),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.phone, color: Colors.green, size: 22),
//                           onPressed: () => _sosService.callNumber(contact['phone'] as String),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
//                           onPressed: () => _deleteContact(contact),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }),
//             ],
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showAddContactDialog,
//         backgroundColor: const Color(0xFFE91E8C),
//         child: const Icon(Icons.person_add, color: Colors.white),
//       ),
//     );
//   }
// }








// OLD CODE PREVIOUS ONE -->

// import 'package:flutter/material.dart';

// class ContactsPage extends StatelessWidget {
//   const ContactsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Emergency Contacts")),
//       body: ListView(
//         children: const [
//           ListTile(
//             leading: Icon(Icons.person),
//             title: Text("Mother"),
//             subtitle: Text("9999999999"),
//           ),
//           ListTile(
//             leading: Icon(Icons.person),
//             title: Text("Friend"),
//             subtitle: Text("8888888888"),
//           ),
//           ListTile(
//             leading: Icon(Icons.local_police),
//             title: Text("Police"),
//             subtitle: Text("112"),
//           ),
//         ],
//       ),
//     );
//   }
// }
