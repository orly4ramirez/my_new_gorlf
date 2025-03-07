import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Deferred import for web-specific code
import 'package:google_sign_in_web/google_sign_in_web.dart' deferred as web_sign_in;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web-specific sign-in is handled by renderGoogleSignInButton
        return null;
      } else {
        // Mobile sign-in
        if (_googleSignIn.currentUser != null) {
          await _googleSignIn.signOut();
        }
        GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
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

  Widget renderGoogleSignInButton({required Function(User?) onSignedIn}) {
    if (kIsWeb) {
      return FutureBuilder(
        future: web_sign_in.loadLibrary(), // Load the library when needed
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return web_sign_in.GoogleSignInPlugin().renderButton(
              configuration: web_sign_in.GSignInConfiguration(
                clientId: '553578579474-jrggm9uc2aidithqp3cug89ancil3vc9.apps.googleusercontent.com', // Replace with your Client ID
                scopes: ['email', 'profile'],
                onSignIn: (web_sign_in.GoogleIdentityUser googleUser) async {
                  try {
                    final idToken = googleUser.idToken;
                    if (idToken == null) {
                      print('No idToken returned from renderButton');
                      onSignedIn(null);
                      return;
                    }
                    final credential = GoogleAuthProvider.credential(idToken: idToken);
                    final userCredential = await _auth.signInWithCredential(credential);
                    final user = userCredential.user;

                    if (user != null) {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                        'email': user.email,
                        'displayName': user.displayName,
                        'createdAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    }
                    onSignedIn(user);
                  } catch (e) {
                    print('Google Sign-In Button Error: $e');
                    onSignedIn(null);
                  }
                },
              ),
            );
          } else {
            return const CircularProgressIndicator(); // Show a loading indicator while loading
          }
        },
      );
    } else {
      return const SizedBox.shrink(); // Return an empty widget for mobile
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