// Firebase imports commented out for iOS compatibility
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Firebase instances commented out for iOS compatibility
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase authentication methods commented out for iOS compatibility
  /*
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In process');
      
      // Revoke any previous access
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('Google Sign-In account selected: ${googleUser?.email}');

      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return null;
      }

      // Obtain the auth details from the request
      print('Getting Google auth details');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('Got auth tokens - Access Token: ${googleAuth.accessToken != null}, ID Token: ${googleAuth.idToken != null}');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      print('Signing in to Firebase');
      final userCredential = await _auth.signInWithCredential(credential);
      print('Firebase sign in successful: ${userCredential.user?.email}');
      
      return userCredential;
    } catch (e) {
      print('Error during Google sign in: $e');
      rethrow; // Re-throw the error to be handled by the UI
    }
  }
  */

  /*
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    {String? referralCode}
  ) async {
    try {
      // Crear usuario con email y contraseña
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      try {
        // Intentar guardar información adicional del usuario en Firestore
        if (userCredential.user != null) {
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'name': name,
            'email': email.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            if (referralCode != null) 'referralCode': referralCode,
          });
        }
      } catch (firestoreError) {
        print('Error saving user data to Firestore: $firestoreError');
        // Si el error es por base de datos no existente, lanzamos un error específico
        if (firestoreError.toString().contains('The database (default) does not exist')) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'database-not-found',
            message: 'Firebase database has not been initialized. Please contact support.',
          );
        }
      }

      return userCredential;
    } catch (e) {
      print('Error during email/password sign up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  */
}
