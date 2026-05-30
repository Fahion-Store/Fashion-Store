import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Address {
  final String id;
  final String label;
  final String street;
  final String city;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'street': street,
      'city': city,
      'isDefault': isDefault,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }
}

class AddressProvider with ChangeNotifier {
  final List<Address> _addresses = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AddressProvider() {
    if (_auth.currentUser != null) {
      _loadAddressesFromFirestore(_auth.currentUser!.uid);
    }
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadAddressesFromFirestore(user.uid);
      } else {
        _addresses.clear();
        notifyListeners();
      }
    });
  }

  List<Address> get addresses => [..._addresses];

  void addAddress(Address address) {
    _addresses.add(address);
    notifyListeners();
    _saveAddressesToFirestore();
  }

  void removeAddress(String id) {
    _addresses.removeWhere((a) => a.id == id);
    notifyListeners();
    _saveAddressesToFirestore();
  }

  void setDefault(String id) {
    for (var i = 0; i < _addresses.length; i++) {
      if (_addresses[i].id == id) {
        _addresses[i] = Address(
          id: _addresses[i].id,
          label: _addresses[i].label,
          street: _addresses[i].street,
          city: _addresses[i].city,
          isDefault: true,
        );
      } else {
        _addresses[i] = Address(
          id: _addresses[i].id,
          label: _addresses[i].label,
          street: _addresses[i].street,
          city: _addresses[i].city,
          isDefault: false,
        );
      }
    }
    notifyListeners();
    _saveAddressesToFirestore();
  }

  // ── Firestore Sync ─────────────────────────────────────────────────────────

  Future<void> _saveAddressesToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final addressData = _addresses.map((a) => a.toMap()).toList();
      await _db.collection('users').doc(user.uid).set({
        'addresses': addressData,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving addresses to Firestore: $e');
    }
  }

  Future<void> _loadAddressesFromFirestore(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data()?['addresses'] != null) {
        final List<dynamic> addressList = doc.data()!['addresses'];
        _addresses.clear();
        for (var itemMap in addressList) {
          _addresses.add(Address.fromMap(Map<String, dynamic>.from(itemMap)));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading addresses from Firestore: $e');
    }
  }
}
