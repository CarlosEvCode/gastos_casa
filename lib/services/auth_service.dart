import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Fetch user role from Firestore
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } else {
          // If no role is found, default to viewer or you can create it here
          // For now, we'll return a default UserModel assuming it was not created
          return UserModel(uid: user.uid, email: email, role: 'viewer');
        }
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Stream to listen to Auth changes
  Stream<User?> get user {
    return _auth.authStateChanges();
  }
}
