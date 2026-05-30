import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import '../core/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  UserProvider() {
    _user = _authService.currentUser;
    _authService.user.listen(_onAuthStateChanged);
  }

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  String get displayName => _userData?['name'] ?? _user?.displayName ?? 'User';
  String? get photoUrl => _userData?['photoUrl'] ?? _user?.photoURL;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _user = firebaseUser;
    
    await _userDocSubscription?.cancel();
    _userDocSubscription = null;

    if (_user != null) {
      _userDocSubscription = _db.collection('users').doc(_user!.uid).snapshots().listen((doc) {
        if (doc.exists) {
          _userData = doc.data();
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('Error listening to user data: $e');
      });
    } else {
      _userData = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }

  Future<void> signUp(String email, String password, String name) async {
    await _authService.signUp(email: email, password: password, name: name);
  }

  Future<void> signIn(String email, String password) async {
    await _authService.signIn(email, password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? language,
    String? sizePreference,
    bool? notificationsOn,
    String? photoUrl,
  }) async {
    if (_user == null) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (language != null) updates['language'] = language;
      if (sizePreference != null) updates['sizePreference'] = sizePreference;
      if (notificationsOn != null) updates['notificationsOn'] = notificationsOn;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      // 1. Update Firestore as the source of truth
      await _db.collection('users').doc(_user!.uid).set(updates, SetOptions(merge: true));

      // 2. Safely update Firebase Auth profile
      try {
        if (name != null) {
          await _user!.updateDisplayName(name);
        }
        if (photoUrl != null) {
          await _user!.updatePhotoURL(photoUrl);
        }
      } catch (e) {
        debugPrint('Warning: Failed to update Auth profile (ignoring): $e');
      }

      // 3. Update local data cache instantly instead of fetching again
      if (_userData != null) {
        _userData!.addAll(updates);
      } else {
        _userData = Map<String, dynamic>.from(updates);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> uploadProfilePhoto(Uint8List bytes, String fileName) async {
    if (_user == null) return;
    
    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_photos/${_user!.uid}/$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = storageRef.putData(bytes, metadata);
      // Timeout after 5 seconds to avoid infinite hangs if Storage is unconfigured
      final snapshot = await uploadTask.timeout(const Duration(seconds: 5));

      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      await updateProfile(photoUrl: downloadUrl);
    } catch (e) {
      debugPrint('Firebase Storage failed, saving directly to Firestore: $e');
      try {
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await updateProfile(photoUrl: base64String);
      } catch (innerError) {
        debugPrint('Firestore fallback failed: $innerError');
        rethrow;
      }
    }
  }
}
