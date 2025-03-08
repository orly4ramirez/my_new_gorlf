import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    clientId: kIsWeb ? '553578579474-jrggm9uc2aidithqp3cug89ancil3vc9.apps.googleusercontent.com' : null,
  );

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web-specific flow using Firebase Auth popup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email profile openid');
        final userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;

        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'email': user.email,
            'displayName': user.displayName,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        return user;
      } else {
        // Mobile flow
        if (_googleSignIn.currentUser != null) {
          await _googleSignIn.signOut();
        }
        GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          print('User canceled Google Sign-In');
          return null;
        }

        final googleAuth = await googleUser.authentication;
        print('GoogleAuth: accessToken=${googleAuth.accessToken}, idToken=${googleAuth.idToken}');
        if (googleAuth.idToken == null) {
          print('No idToken available');
          return null;
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'email': user.email,
            'displayName': user.displayName,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        return user;
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<User?> signUpWithEmail(String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print('Sign-Up Error: $e');
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } catch (e) {
      print('Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}