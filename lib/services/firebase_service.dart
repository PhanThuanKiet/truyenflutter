import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'image_service.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageService _imageService = ImageService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  FirebaseService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String password, String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Truyện related functions
  Future<void> saveTruyen(Map<String, dynamic> truyenData) async {
    try {
      if (_user == null) throw Exception('User not logged in');

      // Upload thumbnail if exists
      if (truyenData['thumb'] != null && truyenData['thumb'] is File) {
        final thumbUrl = await _imageService.uploadImage(truyenData['thumb']);
        truyenData['thumb'] = thumbUrl;
      }

      final truyenRef = _firestore.collection('truyens').doc();
      await truyenRef.set({
        ...truyenData,
        'userId': _user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveChapter(String truyenId, Map<String, dynamic> chapterData) async {
    try {
      if (_user == null) throw Exception('User not logged in');

      // Upload chapter images if they exist
      if (chapterData['images'] != null && chapterData['images'] is List) {
        final List<dynamic> images = chapterData['images'];
        final List<String> uploadedUrls = [];
        
        for (var image in images) {
          if (image is File) {
            final url = await _imageService.uploadImage(image);
            uploadedUrls.add(url);
          } else if (image is String) {
            final url = await _imageService.uploadImageFromUrl(image);
            uploadedUrls.add(url);
          }
        }
        
        chapterData['images'] = uploadedUrls;
      }

      final chapterRef = _firestore
          .collection('truyens')
          .doc(truyenId)
          .collection('chapters')
          .doc();

      await chapterRef.set({
        ...chapterData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<QuerySnapshot> getTruyens() {
    return _firestore
        .collection('truyens')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getChapters(String truyenId) {
    return _firestore
        .collection('truyens')
        .doc(truyenId)
        .collection('chapters')
        .orderBy('chapterNumber')
        .snapshots();
  }

  Future<DocumentSnapshot> getTruyen(String truyenId) {
    return _firestore.collection('truyens').doc(truyenId).get();
  }

  Future<DocumentSnapshot> getChapter(String truyenId, String chapterId) {
    return _firestore
        .collection('truyens')
        .doc(truyenId)
        .collection('chapters')
        .doc(chapterId)
        .get();
  }
} 