import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. SIGN UP (Puthu User Account Create Panna)
  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Signup Backend Error: ${e.message}");
      rethrow; // Screen-la error message kaata idhu uthavum
    }
  }

  // 2. SIGN IN (Login Panna)
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Login Backend Error: ${e.message}");
      rethrow;
    }
  }

  // 3. SIGN OUT (Logout Panna)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
