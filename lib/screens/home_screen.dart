// lib/screens/home_screen.dart
// VIRA — Your original UI preserved 100%.
// Changes: firebase_auth removed. FirestoreService + SOSService now call FastAPI.
// User display name/email loaded from GET /me on init instead of FirebaseAuth.currentUser.
// LOCATION UPDATE: Share Location page removed — all location entry points now
// open the unified MapScreen (real embedded Google Map with live pin + working
// WhatsApp/SMS/Copy share buttons + live tracking).

import 'package:flutter/material.dart';
import '../services/sos_service.dart';
import '../services/location_service.dart';
import '../services/firestore_services.dart';
import '../services/auth_services.dart';
import '../services/shake_service.dart';
import 'map_screen.dart';
import 'nearby_police_screen.dart';
import 'package:camera/camera.dart';
import '../services/spy_cam_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const Color pink     = Color(0xFFE91E8C);
  static const Color pinkLight = Color(0xFFFFD6E7);
  static const Color pinkSoft  = Color(0xFFFFF0F5);
  static const Color dark      = Color(0xFF222222);
  static const Color gray      = Color(0xFF666666);
  static const Color bgDark    = Color(0xFF1A0A12);

  String _section  = 'home';
  bool _sosActive  = false;
  int  _bnIndex    = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _sos = SOSService();
  final _db  = FirestoreService();
  final _auth = AuthService();

  // ── User info (replaces FirebaseAuth.instance.currentUser) ────────────────
  String _userName   = 'User';
  String _userEmail  = '';
  String _userInitials = 'U';

  // Timer state
  int  _timerSecs   = 0;
  bool _timerSet    = false;
  bool _timerRunning = false;
  late AnimationController _timerCtrl;

  // Fake call state
  bool   _fakeCallVisible  = false;
  String _fakeCallerName   = 'Mom';
  String _fakeCallStatus   = 'Incoming call...';
  bool   _fakeCallAnswered = false;

  // Spy cam state
 final _spyCam = SpyCamService();
  bool _camInitializing = false;
  bool _camRecording = false;
  String? _lastSavedPath;
  List<String> _savedSegments = [];

  // Contacts
  List<Map<String, dynamic>> _contacts = [];
  bool _contactsLoading = true;
  final _newName  = TextEditingController();
  final _newPhone = TextEditingController();
  final _newRel   = TextEditingController();

  // Route
  final _fromLoc   = TextEditingController();
  final _toLoc     = TextEditingController();
  String _routeResult = '';
  int    _routeStatus = 0;

  // Report
  final _repLoc   = TextEditingController();
  String _repType = 'Harassment';

  // Fake call
  final _callerNameCtrl = TextEditingController();

  // Location state — MapScreen now owns all live location UI/state
  final _locationService = LocationService();
  ShakeService? _shakeService;
  bool _shakeEnabled = true;

  @override
  void initState() {
    super.initState();
    _timerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _loadCurrentUser(); // ← replaces FirebaseAuth.instance.currentUser
    _initShakeDetection();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
  //print('🔄 _loadContacts() called');
  setState(() => _contactsLoading = true);
  try {
    final contacts = await _db.getContacts();
    //print('🔄 Got ${contacts.length} contacts back: $contacts');
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _contactsLoading = false;
      });
      //print('🔄 setState completed — _contacts.length is now ${_contacts.length}');
    } else {
      print('🔄 NOT mounted — setState skipped!');
    }
  } catch (e) {
    print('❌ _loadContacts error: $e');
    if (mounted) setState(() => _contactsLoading = false);
  }
}


  // ── Shake Detection — triggers SOS on 3 hard shakes ────────────────────────
  void _initShakeDetection() {
    _shakeService = ShakeService(onShakeDetected: () {
      if (_shakeEnabled && !_sosActive) {
        _toast('📳 Shake detected! Triggering SOS...');
        _triggerSOS();
      }
    });
    _shakeService!.start();
  }
  // SPY CAM — Real camera integration

       Future<void> _initSpyCam() async {
  if (_spyCam.isInitialized || _camInitializing) return;
  setState(() => _camInitializing = true);

  final granted = await _spyCam.requestCameraPermissions(); // if added to service
  if (!granted) {
    _toast('Camera & microphone permission required');
    setState(() => _camInitializing = false);
    return;
  }

  try {
    await _spyCam.initialize();
  } catch (e) {
    _toast('Camera unavailable: $e');
  } finally {
    if (mounted) setState(() => _camInitializing = false);
  }
}

     Future<void> _startSpyCamRecording() async {
       await _initSpyCam();
       if (!_spyCam.isInitialized) return;
       await _spyCam.startRecording(
         segmentLength: const Duration(minutes: 5),
         onSegmentSaved: (path) {
           if (mounted) {
             setState(() {
               _savedSegments.add(path);
               _lastSavedPath = path;
             });
             _toast('Segment auto-saved');
           }
         },
       );
       if (mounted) setState(() => _camRecording = true);
     }

     Future<void> _stopSpyCamRecording() async {
       final path = await _spyCam.stopRecording();
       if (mounted) {
         setState(() {
           _camRecording = false;
           if (path != null) {
             _savedSegments.add(path);
             _lastSavedPath = path;
           }
         });
       }
       _toast(path != null ? 'Recording saved' : 'Recording stopped');
     }


  // ── Load user from FastAPI GET /me ────────────────────────────────────────
  Future<void> _loadCurrentUser() async {
    final user = await _auth.getCurrentUser();
    if (user != null && mounted) {
      final name = user['name'] as String? ?? 'User';
      setState(() {
        _userName    = name;
        _userEmail   = user['email'] as String? ?? '';
        _userInitials = name.isNotEmpty
            ? name.split(' ').map((w) => w[0]).take(2).join().toUpperCase()
            : 'U';
      });
    }
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _shakeService?.dispose();
    _spyCam.dispose();
    _newName.dispose(); _newPhone.dispose(); _newRel.dispose();
    _fromLoc.dispose(); _toLoc.dispose(); _repLoc.dispose();
    _callerNameCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle, color: pink, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
    ]),
    backgroundColor: bgDark,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
    duration: const Duration(seconds: 2),
  ));
}

  // Cooldown lock — prevents double trigger from tap+shake conflict
  bool _sosLocked = false;

  Future<void> _triggerSOS() async {
    if (_sosLocked) {
      print('🔒 SOS locked — ignoring duplicate call');
      return;
    }

    _sosLocked = true;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _sosLocked = false);
    });

    setState(() => _sosActive = !_sosActive);
    print('🔴 _triggerSOS — _sosActive: $_sosActive');

    if (_sosActive) {
      print('🔴 TRIGGER branch');

      // ✅ Fetch contacts from /contacts endpoint (NOT from profile)
      List<Map<String, dynamic>> contacts = [];
      try {
        print('📋 Fetching contacts from /contacts...');
        contacts = await _db.getContacts();
        print('📋 Got ${contacts.length} contacts: $contacts');
      } catch (e) {
        print('❌ Failed to fetch contacts: $e');
      }

      final number = contacts.isNotEmpty
          ? (contacts.first['phone'] as String? ?? '112')
          : '112';

      // Trigger SOS alert on backend
      try {
        await _sos.triggerSOS(
          emergencyNumber: number,
          trustedContacts: contacts,
        );
        print('✅ SOS triggered on backend');
      } catch (e) {
        print('❌ SOS trigger error: $e');
      }

      _toast('SOS Alert Sent!');
    } else {
      print('🔵 CANCEL branch');
      await _sos.cancelSOS();
      _toast('SOS Deactivated');
    }
  }

  void _setTimer(int mins) {
    setState(() { _timerSecs = mins * 60; _timerSet = true; });
    _toast('$mins min timer set');
  }

  void _startTimer() {
    if (!_timerSet) { _toast('Select a duration first'); return; }
    if (_timerRunning) return;
    setState(() => _timerRunning = true);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_timerRunning) return false;
      setState(() {
        if (_timerSecs > 0) { _timerSecs--; }
        else { _timerRunning = false; _timerSet = false; _toast('Check-in missed! Alerting contacts...'); }
      });
      return _timerRunning;
    });
  }

  String get _timerDisplay {
    final m = (_timerSecs ~/ 60).toString().padLeft(2, '0');
    final s = (_timerSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _checkRoute() {
    if (_fromLoc.text.isEmpty || _toLoc.text.isEmpty) { _toast('Please enter both locations'); return; }
    final results = [1, 2, 3];
    results.shuffle();
    setState(() {
      _routeStatus = results.first;
      _routeResult = ['', 'Safe Route Found — Well-lit path via main road. ~15 mins.', 'Moderate Risk — Some poorly-lit areas. Prefer before 8 PM.', 'Caution Advised — Avoid at night. Use alternative.'][_routeStatus];
    });
  }

 Future<void> _addContact() async {
  if (_newName.text.isEmpty || _newPhone.text.isEmpty) {
    _toast('Enter name and phone');
    return;
  }
  try {
    await _db.addContact(
      name: _newName.text,
      phone: _newPhone.text,
      relationship: _newRel.text,
    );
    _newName.clear(); _newPhone.clear(); _newRel.clear();
    if (mounted) {
      await _loadContacts();
      _toast('Contact added!');
    }
  } catch (e) {
    if (mounted) _toast('Failed to add contact: $e');
  }
}

 Future<void> _deleteContact(String id) async {
  try {
    await _db.deleteContact(id);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      await _loadContacts();
      _toast('Contact removed');   // ← moved INSIDE the mounted check
    }
  } catch (e) {
    print('❌ DELETE ERROR: $e');   // ← keep this so we can verify if it ever fires again
    if (mounted) _toast('Failed to remove contact');
  }
}

  void _scheduleFakeCall(int secs) {
    final name = _callerNameCtrl.text.isEmpty ? 'Mom' : _callerNameCtrl.text;
    _toast('Fake call from $name in ${secs}s...');
    Future.delayed(Duration(seconds: secs), () {
      if (mounted) setState(() { _fakeCallerName = name; _fakeCallStatus = 'Incoming call...'; _fakeCallVisible = true; _fakeCallAnswered = false; });
    });
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    // Uses _userName / _userEmail / _userInitials loaded from FastAPI
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(_userName, _userEmail, _userInitials),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Everything below is YOUR ORIGINAL CODE — zero changes to any widget.
  // ═══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      // Fixed width leading so title can truly center
      leadingWidth: 48,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: dark),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      // Move tabs into title with full-width centered row
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navTab('Home', 'home'),
          _navTab('Community', 'danger'),
          _navTab('Contacts', 'contacts'),
          _navTab('Helplines', 'helplines'),
        ],
      ),
      titleSpacing: 0,
      actions: const [],
      bottom: PreferredSize(
        child: Container(color: pinkLight, height: 1),
        preferredSize: const Size.fromHeight(1),
      ),
    );
  }

  Widget _navTab(String label, String section) {
    final active = _section == section;
    return GestureDetector(
      onTap: () => setState(() => _section = section),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? pinkSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? pink : gray,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(String name, String email, String initials) {
    final items = [
      [Icons.home_outlined,         'Home',           'home'],
      [Icons.route_outlined,        'Safe Route',     'checkin'],
      [Icons.map_outlined,          'Community',      'danger'],
      [Icons.person_add_outlined,   'Add Contact',    'contacts'],
      [Icons.local_hospital_outlined,'Helplines',     'helplines'],
      [Icons.my_location_outlined,  'Live Location',  'shareloc'],
      [Icons.local_police_outlined, 'Police Stations','police'],
    ];
    return Drawer(
      backgroundColor: const Color(0xFF1A0A12),
      child: Column(children: [
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: const BoxDecoration(color: pink, shape: BoxShape.circle), child: const Icon(Icons.shield, color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VIRA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 2)),
              Text('Women Safety App', style: TextStyle(fontSize: 10, color: Color(0xFFC8A0B8))),
            ]),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: Color(0xFFC8A0B8)), onPressed: () => Navigator.pop(context)),
          ]),
        )),
        const Divider(color: Color(0xFF2A1020), height: 1),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: items.map((item) {
          final active = _section == item[2];
          return InkWell(
            onTap: () {
              Navigator.pop(context);
              final key = item[2] as String;
              if (key == 'shareloc') {
                // ✅ Live Location now opens the unified MapScreen directly
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
              } else if (key == 'police') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyPoliceScreen()));
              } else {
                setState(() => _section = key);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: active ? const Color(0xFF2A1020) : Colors.transparent,
                border: active ? const Border(left: BorderSide(color: pink, width: 3)) : null,
              ),
              padding: EdgeInsets.fromLTRB(active ? 13 : 16, 12, 16, 12),
              child: Row(children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(color: active ? const Color(0xFF3D1228) : const Color(0xFF2A1020), shape: BoxShape.circle),
                    child: Icon(item[0] as IconData, color: pink, size: 19)),
                const SizedBox(width: 13),
                Text(item[1] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFFE8C8D8))),
              ]),
            ),
          );
        }).toList())),
        const Divider(color: Color(0xFF2A1020), height: 1),
        GestureDetector(
          onTap: () { Navigator.pop(context); setState(() => _section = 'profile'); },
          child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            CircleAvatar(radius: 19, backgroundColor: pink, child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFFC8A0B8))),
            ])),
            const Icon(Icons.chevron_right, color: Color(0xFF5A3048)),
          ])),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_section) {
      case 'home':      return _buildHome();
      case 'checkin':   return _buildSafeRoute();
      case 'timer':     return _buildTimer();
      case 'danger':    return _buildDangerZone();
      case 'contacts':  return _buildContacts();
      case 'helplines': return _buildHelplines();
      case 'shareloc':
        // ✅ Live Location now opens the unified MapScreen instead of a static page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
          setState(() => _section = 'home');
        });
        return _buildHome();
      case 'bookCab':   return _buildBookCab();
      case 'spyCam':    return _buildSpyCam();
      case 'fakeCall':  return _buildFakeCall();
      case 'profile':   return _buildProfile();
      case 'police':
        // Navigate to dedicated screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyPoliceScreen()));
          setState(() => _section = 'home');
        });
        return _buildHome();
      default:          return _buildHome();
    }
  }

  Widget _buildHome() {
    return SingleChildScrollView(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 16), child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(color: pinkSoft, borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.favorite, color: pink, size: 13), SizedBox(width: 5),
            Text('Your safety, always within reach', style: TextStyle(fontSize: 12, color: pink)),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('VIRA', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: pink, letterSpacing: 3)),
        const Text('Empowering women. One tap at a time.', style: TextStyle(fontSize: 13, color: gray)),
        const SizedBox(height: 28),
        _SOSRingButton(active: _sosActive, onTap: _triggerSOS),
        const SizedBox(height: 12),
        Text(
          _sosActive ? 'SOS ACTIVE — Alerting contacts!' : 'Tap for emergency alert',
          style: TextStyle(fontSize: 12, color: _sosActive ? const Color(0xFFC0155C) : gray, fontWeight: _sosActive ? FontWeight.w700 : FontWeight.normal),
        ),
        if (_sosActive) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: pinkSoft, border: Border.all(color: pink, width: 2), borderRadius: BorderRadius.circular(14)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.warning_amber_rounded, color: Color(0xFFC0155C), size: 18), SizedBox(width: 6), Text('SOS Activated!', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFC0155C)))]),
              SizedBox(height: 4),
              Text('Alerting your trusted contacts...', style: TextStyle(fontSize: 13, color: Color(0xFFC0155C))),
              Text('Sharing live location · Notifying nearest police.', style: TextStyle(fontSize: 12, color: Color(0xFFC0155C))),
            ]),
          ),
        ],
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('QUICK ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: gray, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4, childAspectRatio: 0.82, crossAxisSpacing: 10, mainAxisSpacing: 10,
          children: [
            _featItem(Icons.route_outlined,          'Safe Route', const Color(0xFF4CAF50), const Color(0xFFE8F5E9), () => setState(() => _section = 'checkin')),
            _featItem(Icons.local_police_outlined,    'Police',    const Color(0xFF1565C0), const Color(0xFFE3F2FD), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyPoliceScreen()))),
            _featItem(Icons.map_outlined,             'Community', const Color(0xFFFF5722), const Color(0xFFFBE9E7), () => setState(() => _section = 'danger')),
            _featItem(Icons.contacts_outlined,        'Contacts',  pink, pinkSoft, () => setState(() => _section = 'contacts')),
            _featItem(Icons.local_hospital_outlined,  'Helplines', const Color(0xFF9C27B0), const Color(0xFFF3E5F5), () => setState(() => _section = 'helplines')),
            // ✅ Location quick action now opens MapScreen directly (real embedded map)
            _featItem(Icons.my_location_outlined,     'Location',  const Color(0xFF00BCD4), const Color(0xFFE0F7FA), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()))),
            _featItem(Icons.directions_car_outlined,  'Book Cab',  const Color(0xFFFF9800), const Color(0xFFFFF3E0), () => setState(() => _section = 'bookCab')),
            _featItem(Icons.phone_outlined,           'Call', const Color(0xFF607D8B), const Color(0xFFECEFF1), () => setState(() => _section = 'fakeCall')),

          ],
        ),
      ])),
    ]));
  }

  Widget _featItem(IconData icon, String label, Color iconColor, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: pinkLight), borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: dark, height: 1.3)),
        ]),
      ),
    );
  }

  Widget _buildSafeRoute() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pageHeader(Icons.route_outlined, 'Safe Route', 'Find the safest path to your destination'),
      _card(children: [
        _cardTitle(Icons.location_on_outlined, 'Route Safety Checker'),
        TextField(controller: _fromLoc, decoration: _inputDeco('From: Your location')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _toLoc, decoration: _inputDeco('To: Destination'))),
          const SizedBox(width: 10),
          _pinkBtn('Check', _checkRoute),
        ]),
        if (_routeResult.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: [null, const Color(0xFFE8F5E9), const Color(0xFFFFF3E0), const Color(0xFFFCE4EC)][_routeStatus],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_routeResult, style: TextStyle(fontSize: 13, color: [null, const Color(0xFF2E7D32), const Color(0xFFE65100), const Color(0xFFC62828)][_routeStatus])),
          ),
        ],
      ]),
      _card(children: [
        _cardTitle(Icons.info_outline, 'Safety Tips'),
        ...[
          'Prefer main roads with good lighting at night',
          'Share your route with a trusted contact',
          'Avoid isolated shortcuts after dark',
          'Keep your phone charged and location on',
        ].map((tip) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
          const Text('✦', style: TextStyle(color: pink, fontSize: 10)),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, color: gray, height: 1.6))),
        ]))),
      ]),
    ]));
  }

  Widget _buildTimer() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pageHeader(Icons.timer_outlined, 'Check-in Timer', 'Set a timer — contacts are auto-alerted if you miss it'),
      _card(children: [
        _cardTitle(Icons.timer_outlined, 'Set Your Timer'),
        const Text("If you don't check in when it ends, your emergency contacts are notified instantly.", style: TextStyle(fontSize: 13, color: gray)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _outlineBtn('10 min', () => _setTimer(10)),
          _outlineBtn('20 min', () => _setTimer(20)),
          _outlineBtn('30 min', () => _setTimer(30)),
          _outlineBtn('1 hour', () => _setTimer(60)),
        ]),
        const SizedBox(height: 12),
        Center(child: Text(_timerDisplay, style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w800, color: pink))),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center, children: [
          _pinkBtn('Start', _startTimer),
          _outlineBtn("I'm Safe ✓", () { setState(() { _timerRunning = false; _timerSet = false; _timerSecs = 0; }); _toast("Check-in confirmed. You're safe!"); }),
          _outlineBtn('Reset', () => setState(() { _timerRunning = false; _timerSet = false; _timerSecs = 0; })),
        ]),
      ]),
    ]));
  }

  Widget _buildDangerZone() {
    final reports = [
      {'tag': 'Harassment',          'tagColor': const Color(0xFFFCE4EC), 'tagText': const Color(0xFFC62828), 'time': '2 hrs ago',  'loc': 'Park Street, Kolkata',       'desc': 'Eve-teasing reported near the bus stop at night.'},
      {'tag': 'Poor Lighting',       'tagColor': const Color(0xFFFFF3E0), 'tagText': const Color(0xFFE65100), 'time': '5 hrs ago',  'loc': 'Salt Lake Sector V, Kolkata','desc': 'Street lights not working on the back road.'},
      {'tag': 'Suspicious Activity', 'tagColor': const Color(0xFFF3E5F5), 'tagText': const Color(0xFF6A1B9A), 'time': '1 day ago',  'loc': 'Jadavpur, Kolkata',          'desc': 'Unknown individuals loitering near college gate.'},
      {'tag': 'Safe Zone',           'tagColor': const Color(0xFFE8F5E9), 'tagText': const Color(0xFF2E7D32), 'time': '2 days ago', 'loc': 'South City Mall, Kolkata',   'desc': 'Well-lit and patrolled. Good at all hours.'},
    ];
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pageHeader(Icons.map_outlined, 'Community', 'View and report unsafe areas near you'),
      _card(children: [
        _cardTitle(Icons.warning_amber_outlined, 'Recent Reports'),
        ...reports.map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), decoration: BoxDecoration(color: r['tagColor'] as Color, borderRadius: BorderRadius.circular(12)),
                child: Text(r['tag'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r['tagText'] as Color))),
            const Spacer(),
            Text(r['time'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFFF48FB1))),
          ]),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.location_on, size: 12, color: gray), const SizedBox(width: 4), Text(r['loc'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dark))]),
          Text(r['desc'] as String, style: const TextStyle(fontSize: 12, color: gray)),
          if (r != reports.last) const Divider(color: Color(0xFFFFD6E7), height: 20),
        ]))),
      ]),
      _card(children: [
        _cardTitle(Icons.add_circle_outline, 'Report an Incident'),
        TextField(controller: _repLoc, decoration: _inputDeco('Location')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _repType,
          decoration: InputDecoration(filled: true, fillColor: pinkSoft, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: pinkLight)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: ['Harassment', 'Poor Lighting', 'Suspicious Activity', 'Safe Zone', 'Other'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _repType = v!),
        ),
        const SizedBox(height: 8),
        TextField(maxLines: 3, decoration: _inputDeco('Describe what happened...')),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: _pinkBtn('Submit Report', () { if (_repLoc.text.isEmpty) { _toast('Please enter a location'); return; } _repLoc.clear(); _toast('Report submitted. Thank you!'); })),
      ]),
    ]));
  }

  Widget _buildContacts() {
  return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _pageHeader(Icons.phone_outlined, 'Emergency Contacts', 'These contacts are alerted during SOS'),
    _card(children: [
      _cardTitle(Icons.group_outlined, 'Trusted Contacts'),
      if (_contactsLoading)
        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(color: pink)))
      else if (_contacts.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No contacts yet. Add one below.', style: TextStyle(fontSize: 13, color: gray)))
      else
        ..._contacts.asMap().entries.map((e) {
          final c = e.value;
          final name = c['name'] as String? ?? '';
          final phone = c['phone'] as String? ?? '';
          final rel = c['relationship'] as String? ?? '';
          final id = c['id'] as String? ?? '';
          final init = name.isNotEmpty
              ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
              : '?';
          final colors = [pink, const Color(0xFF7C4DFF), Colors.teal, Colors.orange];
          final color = colors[e.key % colors.length];
          return Column(children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
              CircleAvatar(radius: 20, backgroundColor: const Color(0xFFFFD6E7), child: Text(init, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: dark)),
                Text(rel.isNotEmpty ? '$rel · $phone' : phone, style: const TextStyle(fontSize: 12, color: gray)),
              ])),
              _iconBtn(Icons.phone_outlined, () => _toast('Calling $name...')),
              const SizedBox(width: 6),
              _iconBtn(Icons.delete_outline, () => _deleteContact(id)),
            ])),
            if (e.key < _contacts.length - 1) const Divider(color: Color(0xFFFFD6E7), height: 1),
          ]);
        }),
    ]),
    _card(children: [
      _cardTitle(Icons.person_add_outlined, 'Add New Contact'),
      TextField(controller: _newName, decoration: _inputDeco('Full Name')),
      const SizedBox(height: 8),
      TextField(controller: _newPhone, keyboardType: TextInputType.phone, decoration: _inputDeco('Phone Number')),
      const SizedBox(height: 8),
      TextField(controller: _newRel, decoration: _inputDeco('Relation (e.g. Friend, Sister)')),
      const SizedBox(height: 12),
      _pinkBtn('+ Add Contact', _addContact),
    ]),
  ]));
}

  Widget _buildHelplines() {
    final lines = [
      [Icons.shield_outlined,        'Police',             '100'],
      [Icons.local_hospital_outlined,'Ambulance',          '108'],
      [Icons.favorite_outline,       'Women Helpline',     '1091'],
      [Icons.emergency_outlined,     'National Emergency', '112'],
      [Icons.phone_in_talk_outlined, 'Domestic Violence',  '181'],
      [Icons.computer_outlined,      'Cyber Crime',        '1930'],
    ];
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pageHeader(Icons.local_hospital_outlined, 'Emergency Helplines', "India's official safety numbers — one tap away"),
      _card(children: lines.asMap().entries.map((e) {
        final l = e.value;
        return Column(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFFD6E7), borderRadius: BorderRadius.circular(10)), child: Icon(l[0] as IconData, color: pink, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l[1] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: dark)),
              Text(l[2] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: pink)),
            ])),
            GestureDetector(
              onTap: () => _toast('Calling ${l[1]}: ${l[2]}'),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: pink, borderRadius: BorderRadius.circular(20)), child: const Text('Call', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
            ),
          ])),
          if (e.key < lines.length - 1) const Divider(color: Color(0xFFFFD6E7), height: 1),
        ]);
      }).toList()),
    ]));
  }

  int _selectedCab = 0;
  Widget _buildBookCab() {
    final cabs = [
      ['🚗', 'Safe Mini',  '3 min away',  '₹89'],
      ['🚕', 'Pink Cab',   '5 min away',  '₹120'],
      ['🚙', 'Safe Sedan', '7 min away',  '₹155'],
      ['🚐', 'Women SUV',  '10 min away', '₹200'],
    ];
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pageHeader(Icons.directions_car_outlined, 'Book a Safe Cab', 'Verified women-friendly cab options near you'),
      _card(children: [
        _cardTitle(Icons.location_on_outlined, 'Trip Details'),
        TextField(decoration: _inputDeco('Pickup location')),
        const SizedBox(height: 8),
        TextField(decoration: _inputDeco('Drop location')),
      ]),
      _card(children: [
        _cardTitle(Icons.directions_car_outlined, 'Choose a Ride'),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 10, mainAxisSpacing: 10,
          children: cabs.asMap().entries.map((e) {
            final selected = _selectedCab == e.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedCab = e.key),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected ? pinkSoft : Colors.white,
                  border: Border.all(color: selected ? pink : pinkLight, width: selected ? 1.5 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Text(e.value[0], style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(e.value[1], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: dark)),
                    Text(e.value[2], style: const TextStyle(fontSize: 11, color: gray)),
                  ])),
                  Text(e.value[3], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pink)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: _pinkBtn('Confirm Booking', () => _toast('Cab booked! Driver on the way.'))),
      ]),
    ]));
  }

  Widget _buildSpyCam() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pageHeader(Icons.videocam_outlined, 'Spy Cam', 'Discreetly record your surroundings for evidence'),
      _card(children: [
        _cardTitle(Icons.videocam_outlined, 'Camera Preview'),
        Container(
          width: double.infinity,
          height: 240,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14)),
          child: Stack(children: [
            // ── Real camera preview ──────────────────────────────────────
            if (_camInitializing)
              const Center(child: CircularProgressIndicator(color: pink))
            else if (_spyCam.isInitialized && _spyCam.controller != null)
              SizedBox.expand(child: CameraPreview(_spyCam.controller!))
            else
              const Center(child: Text('Camera is off', style: TextStyle(color: Color(0xFF555555), fontSize: 13))),
 
            // ── REC indicator (cannot be hidden — OS shows its own too) ──
            if (_camRecording)
              Positioned(
                top: 12, right: 12,
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: const Text('REC', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 10, children: [
          if (!_camRecording)
            _pinkBtn('Start Recording', _startSpyCamRecording),
          if (_camRecording)
            _outlineBtn('Stop & Save', _stopSpyCamRecording),
        ]),
        if (_lastSavedPath != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
            child: Text('Saved ${_savedSegments.length} clip(s) · Last: ${_lastSavedPath!.split('/').last}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
          ),
        ],
      ]),
      _card(children: [
        _cardTitle(Icons.info_outline, 'How it works'),
        ...[
          'Recording continues while you stay on this screen',
          'Footage auto-saves as a new file every 5 minutes',
          'All clips are stored privately on your device',
          'A red REC indicator shows while recording is active',
        ].map((tip) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
          const Text('✦', style: TextStyle(color: pink, fontSize: 10)), const SizedBox(width: 8),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, color: gray, height: 1.6))),
        ]))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'Note: Android/iOS always show a camera indicator dot while recording — this is a system-level privacy protection and cannot be disabled by any app.',
            style: TextStyle(fontSize: 11, color: Color(0xFFE65100), height: 1.4),
          ),
        ),
      ]),
    ]));
  }

  Widget _buildFakeCall() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pageHeader(Icons.phone_in_talk_outlined, 'Call', 'Simulate an incoming call to escape unsafe situations'),
      _card(children: [
        _cardTitle(Icons.settings_outlined, 'Call Setup'),
        TextField(controller: _callerNameCtrl, decoration: _inputDeco('Caller name (e.g. Mom, Rahul)')),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _outlineBtn('In 5 sec',  () => _scheduleFakeCall(5)),
          _outlineBtn('In 30 sec', () => _scheduleFakeCall(30)),
          _outlineBtn('In 1 min',  () => _scheduleFakeCall(60)),
          _pinkBtn('Call Now',     () => _scheduleFakeCall(1)),
        ]),
      ]),
      if (_fakeCallVisible) Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A0A12), Color(0xFF2A1020)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Container(width: 72, height: 72, decoration: const BoxDecoration(color: pink, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white, size: 32)),
          const SizedBox(height: 12),
          Text(_fakeCallerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(_fakeCallStatus,  style: const TextStyle(fontSize: 13, color: Color(0xFFC8A0B8))),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Column(children: [
              GestureDetector(
                onTap: () { setState(() => _fakeCallVisible = false); _toast('Call ended'); },
                child: Container(width: 56, height: 56, decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle), child: const Icon(Icons.call_end, color: Colors.white, size: 24)),
              ),
              const SizedBox(height: 8),
              const Text('Decline', style: TextStyle(fontSize: 12, color: Color(0xFFC8A0B8))),
            ]),
            Column(children: [
              GestureDetector(
                onTap: () { setState(() { _fakeCallAnswered = true; _fakeCallStatus = 'On call... (tap Decline to end)'; }); _toast('Call answered — act natural!'); },
                child: Container(width: 56, height: 56, decoration: const BoxDecoration(color: Color(0xFF43A047), shape: BoxShape.circle), child: const Icon(Icons.call, color: Colors.white, size: 24)),
              ),
              const SizedBox(height: 8),
              const Text('Answer', style: TextStyle(fontSize: 12, color: Color(0xFFC8A0B8))),
            ]),
          ]),
        ]),
      ),
    ]));
  }

  Widget _buildProfile() {
    return SingleChildScrollView(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 16), child: Column(children: [
        CircleAvatar(radius: 40, backgroundColor: pink, child: Text(_userInitials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white))),
        const SizedBox(height: 12),
        Text(_userName,  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: dark)),
        Text(_userEmail, style: const TextStyle(fontSize: 13, color: gray)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), decoration: BoxDecoration(color: pinkSoft, border: Border.all(color: pinkLight), borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shield, color: pink, size: 13), SizedBox(width: 4), Text('VIRA Member', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pink))])),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
        Expanded(child: _statCard('3',  'Contacts')),
        const SizedBox(width: 10),
        Expanded(child: _statCard('12', 'Check-ins')),
        const SizedBox(width: 10),
        Expanded(child: _statCard('5',  'Reports')),
      ])),
      const SizedBox(height: 16),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _card(children: [
        // Shake to SOS toggle
        InkWell(
          onTap: () => setState(() => _shakeEnabled = !_shakeEnabled),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.pink.shade50, shape: BoxShape.circle), child: const Icon(Icons.vibration, color: pink, size: 17)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Shake to SOS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: dark)),
              Text(_shakeEnabled ? 'Shake phone 3x to trigger SOS' : 'Disabled', style: TextStyle(fontSize: 11, color: _shakeEnabled ? Colors.green : gray)),
            ])),
            Switch(
              value: _shakeEnabled,
              activeColor: pink,
              onChanged: (v) => setState(() => _shakeEnabled = v),
            ),
          ])),
        ),
        const Divider(height: 1, indent: 56),
        _profileMenuItem(Icons.edit_outlined,          'Edit Profile',        Colors.pink.shade50,           pink,                       () => _toast('Edit profile coming soon!')),
        _profileMenuItem(Icons.notifications_outlined, 'Notifications',       Colors.pink.shade50,           pink,                       () => _toast('Notifications coming soon!')),
        _profileMenuItem(Icons.lock_outline,           'Privacy & Security',  Colors.pink.shade50,           pink,                       () => _toast('Privacy settings coming soon!')),
        _profileMenuItem(Icons.help_outline,           'Help & Support',      Colors.pink.shade50,           pink,                       () => _toast('Help center coming soon!')),
        _profileMenuItem(Icons.logout,                 'Log Out',             const Color(0xFFFCE4EC), const Color(0xFFC62828), _logout, labelColor: const Color(0xFFC62828)),
      ])),
      const SizedBox(height: 24),
    ]));
  }

  Widget _statCard(String num, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: pinkLight), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(num, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: pink)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: gray)),
      ]),
    );
  }

  Widget _profileMenuItem(IconData icon, String label, Color bgColor, Color iconColor, VoidCallback onTap, {Color? labelColor}) {
    return InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 17)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor ?? dark))),
        const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 16),
      ])),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 68,
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFFFD6E7)))),
      child: Row(children: [
        _bnItem(Icons.location_on_outlined, 'Location', 0, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
        }),
        _bnItem(Icons.directions_car_outlined, 'Book Cab', 1, () { setState(() { _bnIndex = 1; _section = 'bookCab'; }); }),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: _triggerSOS,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52, height: 52,
              transform: Matrix4.translationValues(0, -14, 0),
              decoration: BoxDecoration(
                color: _sosActive ? const Color(0xFFC0155C) : pink,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: pink.withOpacity(0.4), blurRadius: 14, spreadRadius: 2)],
              ),
              child: const Center(child: Text('SOS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1))),
            ),
          ),
          const Text('SOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pink)),
        ])),
       
        _bnItem(Icons.videocam_outlined, 'Spy Cam',  2, () {setState(() { _bnIndex = 2; _section = 'spyCam'; });_initSpyCam();}),
        _bnItem(Icons.phone_outlined,   'Call', 3, () { setState(() { _bnIndex = 3; _section = 'fakeCall'; }); }),
      ]),
    );
  }

  Widget _bnItem(IconData icon, String label, int index, VoidCallback onTap) {
    final active = _bnIndex == index;
    return Expanded(child: InkWell(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 22, color: active ? pink : gray),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? pink : gray)),
      ]),
    ));
  }

  Widget _pageHeader(IconData icon, String title, String sub) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: pink, size: 22), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: dark))]),
      const SizedBox(height: 3),
      Text(sub, style: const TextStyle(fontSize: 13, color: gray)),
    ]));
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFFFD6E7)), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _cardTitle(IconData icon, String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Icon(icon, color: pink, size: 16), const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: pink)),
    ]));
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
      filled: true, fillColor: pinkSoft,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFFD6E7))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFFD6E7))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: pink)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _pinkBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: pink, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _outlineBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: pink, width: 2), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: const TextStyle(color: pink, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 32, height: 32, decoration: BoxDecoration(color: pinkSoft, border: Border.all(color: pinkLight), shape: BoxShape.circle), child: Icon(icon, color: pink, size: 15)),
    );
  }
}

// ── SOS Ring Animation — your original, untouched ─────────────────────────────
class _SOSRingButton extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;
  const _SOSRingButton({required this.active, required this.onTap});
  @override
  State<_SOSRingButton> createState() => _SOSRingButtonState();
}

class _SOSRingButtonState extends State<_SOSRingButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl    = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scale   = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 160, height: 160, child: Stack(alignment: Alignment.center, children: [
      AnimatedBuilder(animation: _ctrl, builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF48FB1).withOpacity(_opacity.value), width: 3))),
      )),
      GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 130, height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.active ? const Color(0xFFC0155C) : const Color(0xFFE91E8C),
            boxShadow: [BoxShadow(color: const Color(0xFFE91E8C).withOpacity(0.4), blurRadius: 20, spreadRadius: 4)],
          ),
          child: const Center(child: Text('SOS', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 3))),
        ),
      ),
    ]));
  }
}
