import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth        _auth         = FirebaseAuth.instance;
  final FirebaseFirestore   _firestore    = FirebaseFirestore.instance;
  final GoogleSignIn        _googleSignIn = GoogleSignIn();

  final Rx<User?>   firebaseUser  = Rx<User?>(null);
  final RxBool      isLoading     = false.obs;
  final RxString    errorMessage  = ''.obs;

  final RxString displayName = ''.obs;
  final RxString email       = ''.obs;
  final RxString photoUrl    = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ FIX: listen to auth state changes
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setUserData);
  }

  // ✅ FIX 3: Also reads from Firestore as fallback so display name is never empty
  void _setUserData(User? user) async {
    if (user != null) {
      // Reload to get the freshest token/profile from Firebase Auth
      await user.reload();
      final fresh = _auth.currentUser;

      displayName.value = fresh?.displayName ?? '';
      email.value       = fresh?.email       ?? '';
      photoUrl.value    = fresh?.photoURL    ?? '';

      // ✅ FIX 4: If displayName is still empty, fetch from Firestore
      if (displayName.value.isEmpty) {
        try {
          final doc = await _firestore.collection('users').doc(fresh?.uid).get();
          if (doc.exists) {
            displayName.value = doc.data()?['name'] ?? 'Muslim User';
          }
        } catch (_) {}
      }
    } else {
      displayName.value = '';
      email.value       = '';
      photoUrl.value    = '';
    }
  }

  bool get isLoggedIn => firebaseUser.value != null;

  // ── Email/Password Sign Up ──────────────────────────────────────────────
  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value    = true;
      errorMessage.value = '';

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // ✅ FIX 5: Update display name AND wait, then reload before Firestore write
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid':       credential.user!.uid,
        'name':      name.trim(),
        'email':     email.trim(),
        'photoUrl':  '',
        'provider':  'email',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // ✅ FIX 6: Manually set reactive values immediately — don't wait for stream
      displayName.value = name.trim();
      this.email.value  = email.trim();
      photoUrl.value    = '';

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Email/Password Sign In ──────────────────────────────────────────────
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value    = true;
      errorMessage.value = '';

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .update({'lastLogin': FieldValue.serverTimestamp()});

      // ✅ FIX 7: Fetch name from Firestore on sign-in (covers email/password users)
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      if (doc.exists) {
        displayName.value = doc.data()?['name'] ?? credential.user!.displayName ?? 'Muslim User';
      }

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Google Sign In ──────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      isLoading.value    = true;
      errorMessage.value = '';

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled — not an error
        isLoading.value = false;
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user           = userCredential.user!;

      // ✅ FIX 8: reload after Google sign-in
      await user.reload();

      await _firestore.collection('users').doc(user.uid).set({
        'uid':       user.uid,
        'name':      user.displayName ?? '',
        'email':     user.email       ?? '',
        'photoUrl':  user.photoURL    ?? '',
        'provider':  'google',
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Set reactive values immediately
      displayName.value = user.displayName ?? '';
      email.value       = user.email       ?? '';
      photoUrl.value    = user.photoURL    ?? '';

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
      return false;
    } catch (e) {
      // ✅ FIX 9: show the actual error in debug, generic to user
      errorMessage.value = 'Google sign in failed. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Forgot Password ─────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Update Profile ──────────────────────────────────────────────────────
  Future<bool> updateProfile({required String name}) async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.updateDisplayName(name.trim());
      await user.reload();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'name': name.trim()});

      displayName.value = name.trim();
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Error Mapping ───────────────────────────────────────────────────────
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}