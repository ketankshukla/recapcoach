import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../core/config/env.dart';
import '../../core/logging/logger.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = google ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  Stream<User?> authState() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    return cred.user;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<User?> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return null;
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final currentAnon = _auth.currentUser;
    if (currentAnon != null && currentAnon.isAnonymous) {
      try {
        final linked = await currentAnon.linkWithCredential(credential);
        return linked.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          final res = await _auth.signInWithCredential(credential);
          return res.user;
        }
        rethrow;
      }
    }
    final res = await _auth.signInWithCredential(credential);
    return res.user;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (e) {
      logger.warning('Google signOut failed: $e');
    }
    await _auth.signOut();
  }

  /// Permanently deletes the user's account via the server-side endpoint.
  ///
  /// The server:
  ///   1. Writes an anonymous SHA-256 hash of the email to `usedTrials`
  ///      (prevents free-tier re-abuse).
  ///   2. Deletes all Firestore data (notes, usage, profile).
  ///   3. Deletes the Firebase Auth user.
  ///
  /// After the server call succeeds, we sign out locally.
  Future<void> deleteAccount() async {
    final u = _auth.currentUser;
    if (u == null) return;

    if (!Env.hasBackend) {
      throw Exception(
        'Cannot delete account: backend URL is not configured.',
      );
    }

    final idToken = await u.getIdToken();
    final url = Uri.parse('${Env.backendUrl}/api/delete-account');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final body = response.body;
      String message;
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        message = json['error'] as String? ?? body;
      } catch (_) {
        message = body;
      }
      throw Exception('Account deletion failed: $message');
    }

    // Server deleted the auth user, so sign out locally.
    try {
      await _google.signOut();
    } catch (e) {
      logger.warning('Google signOut after delete failed: $e');
    }
    await _auth.signOut();
  }
}
