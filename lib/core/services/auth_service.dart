import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Auth state changes stream
  Stream<User?> get user => _auth.authStateChanges();

  // Sign up with email & password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name in Firebase Auth
      await result.user?.updateDisplayName(name);

      // Create user document in Firestore with a timeout
      if (result.user != null) {
        try {
          await _db.collection('users').doc(result.user!.uid).set({
            'uid': result.user!.uid,
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'cart': [],
            'wishlist': [],
            'addresses': [],
          }).timeout(const Duration(seconds: 10));
          debugPrint('User data saved to Firestore successfully.');
        } catch (e) {
          debugPrint('Warning: Could not save user data to Firestore: $e');
          // We don't rethrow here because the Auth account was already created successfully
          // and we don't want to block the user from entering the app.
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error code: ${e.code}');
      debugPrint('Sign up error message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email & password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login in Firestore
      if (result.user != null) {
        try {
          await _db.collection('users').doc(result.user!.uid).set({
            'lastLogin': FieldValue.serverTimestamp(),
            'email': email, // Ensure email is up to date
          }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
          debugPrint('User last login updated in Firestore.');
        } catch (e) {
          debugPrint('Warning: Could not update last login in Firestore: $e');
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.message}');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: ${e.toString()}');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}
