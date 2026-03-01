import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/viewer_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        title: 'Gastos Casa',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          String role =
              (snapshot.data!.data() as Map<String, dynamic>)['role'] ??
              'viewer';
          if (role == 'admin') {
            return const AdminHomeScreen();
          } else {
            return ViewerHomeScreen();
          }
        }
        return ViewerHomeScreen();
      },
    );
  }
}
