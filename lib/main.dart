// lib/main.dart
// VIRA — Firebase removed. Auth state checked via stored JWT token.
// Onboarding shows only on first launch, then never again.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/map_screen.dart';
import 'screens/nearby_police_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No Firebase.initializeApp() needed anymore
  runApp(const WomenSafetyApp());
}

class WomenSafetyApp extends StatelessWidget {
  const WomenSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIRA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E8C),
          primary: const Color(0xFFE91E8C),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE91E8C),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const _StartRouter(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login':      (context) => const LoginScreen(),
        '/signup':     (context) => const SignupScreen(),
        '/home':       (context) => const HomeScreen(),
        '/map':        (context) => const MapScreen(),
        '/police':     (context) => const NearbyPoliceScreen(),
      },
    );
  }
}

// ── Start Router ──────────────────────────────────────────────────────────────
// Logic:
//   1. First ever launch → show Onboarding
//   2. Launched before + JWT token exists → go straight to Home
//   3. Launched before + no JWT token → go to Login
class _StartRouter extends StatefulWidget {
  const _StartRouter();
  @override
  State<_StartRouter> createState() => _StartRouterState();
}

class _StartRouterState extends State<_StartRouter> {
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if onboarding has been seen before
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    if (!seenOnboarding) {
      // First launch — show onboarding and mark it as seen
      await prefs.setBool('seen_onboarding', true);
      if (mounted) setState(() => _destination = const OnboardingScreen());
      return;
    }

    // Not first launch — check if JWT token exists
    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      // Token found → go to Home
      if (mounted) setState(() => _destination = const HomeScreen());
    } else {
      // No token → go to Login
      if (mounted) setState(() => _destination = const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash while resolving
    if (_destination == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A0A12),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield, color: Color(0xFFE91E8C), size: 56),
              SizedBox(height: 16),
              Text(
                'VIRA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Color(0xFFE91E8C)),
            ],
          ),
        ),
      );
    }
    return _destination!;
  }
}







// OLD CODE-->

// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'screens/onboarding_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/home_screen.dart';
// import 'screens/signup_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(const WomenSafetyApp());
// }

// class WomenSafetyApp extends StatelessWidget {
//   const WomenSafetyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'VIRA',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E8C), primary: const Color(0xFFE91E8C)),
//         useMaterial3: true,
//         fontFamily: 'Roboto',
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Color(0xFFE91E8C),
//           foregroundColor: Colors.white,
//           elevation: 0,
//           centerTitle: true,
//         ),
//       ),
//       home: const _StartRouter(),
//       routes: {
//         '/onboarding': (context) => const OnboardingScreen(),
//         '/login': (context) => const LoginScreen(),
//         '/signup': (context) => const SignupScreen(),
//         '/home': (context) => const HomeScreen(),
//       },
//     );
//   }
// }

// // Shows onboarding only on first launch, then checks auth state
// class _StartRouter extends StatefulWidget {
//   const _StartRouter();
//   @override
//   State<_StartRouter> createState() => _StartRouterState();
// }

// class _StartRouterState extends State<_StartRouter> {
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             backgroundColor: Color(0xFF1A0A12),
//             body: Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C))),
//           );
//         }
//         // Already logged in → go home
//         if (snapshot.hasData && snapshot.data != null) return const HomeScreen();
//         // Not logged in → show onboarding
//         return const OnboardingScreen();
//       },
//     );
//   }
// }






/*import 'package:flutter/material.dart';

void main() {
  runApp(const WomenSafetyApp());
}

class WomenSafetyApp extends StatelessWidget {
  const WomenSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Women Safety App'),
          backgroundColor: Colors.pink,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.security, size: 80, color: Colors.pink),
              SizedBox(height: 20),
              Text(
                'Women Safety Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'SOS • Location • Emergency Help',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/



// OLDE CODE PREVIOUS ONE -->

// import 'package:flutter/material.dart';
// import 'login_page.dart';

// void main() {
//   runApp(const WomenSafetyApp());
// }

// class WomenSafetyApp extends StatelessWidget {
//   const WomenSafetyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Women Safety Analytics',
//       theme: ThemeData(primarySwatch: Colors.pink),
//       home: const LoginPage(),
//     );
//   }
// }




/*import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_app/db/share_pref.dart';
// import 'package:women_safety_app/child/bottom_screens/child_home_page.dart';

//import 'package:women_safety_app/utils/flutter_background_services.dart';
import 'child/bottom_page.dart';

final navigatorkey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MySharedPrefference.init();
  //await initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        // scaffoldMessengerKey: navigatorkey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.firaSansTextTheme(
            Theme.of(context).textTheme,
          ),
          primarySwatch: Colors.blue,
        ),
        home: BottomPage());
  }
}*/




// class CheckAuth extends StatelessWidget {
//   // const CheckAuth({Key? key}) : super(key: key);

//   checkData() {
//     if (MySharedPrefference.getUserType() == 'parent') {}
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold();
//   }
// }
