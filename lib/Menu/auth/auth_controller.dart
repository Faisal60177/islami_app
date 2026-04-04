import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth      _auth         = FirebaseAuth.instance;
  final FirebaseFirestore _firestore    = FirebaseFirestore.instance;
  final GoogleSignIn      _googleSignIn = GoogleSignIn();

  final Rx<User?>  firebaseUser = Rx<User?>(null);
  final RxBool     isLoading    = false.obs;
  final RxString   errorMessage = ''.obs;

  final RxString displayName = ''.obs;
  final RxString email       = ''.obs;
  final RxString photoUrl    = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ CRITICAL FIX: use userChanges() NOT authStateChanges()
    // authStateChanges() does NOT fire when updateDisplayName() is called.
    // userChanges() fires on ALL profile updates including displayName.
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _handleUserChanged);
  }

  // ✅ FIX: made this a regular void (not async) — async void is fire-and-forget
  // and causes race conditions with GetX reactivity.
  void _handleUserChanged(User? user) {
    if (user != null) {
      _loadUserData(user);
    } else {
      displayName.value = '';
      email.value       = '';
      photoUrl.value    = '';
    }
  }

  // ✅ Separate async method — safe to await internally
  Future<void> _loadUserData(User user) async {
    // First set whatever Firebase Auth has right now
    displayName.value = user.displayName ?? '';
    email.value       = user.email       ?? '';
    photoUrl.value    = user.photoURL    ?? '';

    // If displayName is empty (known Firebase Android bug after signup),
    // fetch from Firestore as the reliable fallback
    if (displayName.value.isEmpty) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final firestoreName = doc.data()?['name'] as String? ?? '';
          if (firestoreName.isNotEmpty) {
            displayName.value = firestoreName;
          }
        }
      } catch (_) {
        // Silently ignore — network may be unavailable
      }
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

      final user = credential.user!;

      // ✅ Write to Firestore FIRST (this is the reliable name store)
      await _firestore.collection('users').doc(user.uid).set({
        'uid':       user.uid,
        'name':      name.trim(),
        'email':     email.trim(),
        'photoUrl':  '',
        'provider':  'email',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // ✅ Update Firebase Auth profile (best-effort — known Android bug means
      // this may not reflect immediately in the stream)
      await user.updateDisplayName(name.trim());

      // ✅ Set reactive values IMMEDIATELY — do not wait for stream
      // This guarantees the UI shows the name right after signup
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

      final uid = credential.user!.uid;

      // ✅ Always fetch name from Firestore — it's the reliable source
      // Firebase Auth displayName may be null for email/password users
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          displayName.value = (data['name'] as String? ?? '').isNotEmpty
              ? data['name']
              : credential.user!.displayName ?? 'Muslim User';
          this.email.value = data['email'] as String? ?? email.trim();
          photoUrl.value   = data['photoUrl'] as String? ?? '';
        }

        // Update last login timestamp
        await _firestore
            .collection('users')
            .doc(uid)
            .update({'lastLogin': FieldValue.serverTimestamp()});
      } catch (_) {
        // Firestore fetch failed — fall back to Firebase Auth values
        displayName.value = credential.user!.displayName ?? 'Muslim User';
        this.email.value  = credential.user!.email ?? email.trim();
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
        // User pressed back/cancelled — not an error
        isLoading.value = false;
        return false;
      }

      final googleAuth = await googleUser.authentication;

      // ✅ Verify tokens are not null before proceeding
      if (googleAuth.idToken == null) {
        errorMessage.value = 'Google sign in failed. Please try again.';
        return false;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user           = userCredential.user!;

      final name     = user.displayName ?? googleUser.displayName ?? '';
      final userEmail = user.email ?? googleUser.email;
      final photo    = user.photoURL ?? googleUser.photoUrl ?? '';

      // Save/update in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid':       user.uid,
        'name':      name,
        'email':     userEmail,
        'photoUrl':  photo,
        'provider':  'google',
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ Set reactive values immediately
      displayName.value = name;
      email.value       = userEmail ?? '';
      photoUrl.value    = photo;

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'Google sign in failed. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Forgot Password ─────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String emailAddress) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: emailAddress.trim());
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
    // Reactive values cleared automatically by _handleUserChanged(null)
  }

  // ── Update Profile ──────────────────────────────────────────────────────
  Future<bool> updateProfile({required String name}) async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return false;

      // Update Firestore first (reliable)
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'name': name.trim()});

      // Update Firebase Auth profile
      await user.updateDisplayName(name.trim());

      // Set immediately
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
      case 'sign_in_failed':
        return 'Google sign in failed. Check SHA-1 in Firebase Console.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}