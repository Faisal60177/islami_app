import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth      _auth      = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ FIX: scopes must include 'email' AND 'profile'
  // Without 'profile', photoUrl and displayName come back null on some devices.
  // Do NOT pass serverClientId unless you are using backend token verification —
  // passing a wrong serverClientId is the #1 cause of silent Google sign-in failure.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final Rx<User?>  firebaseUser = Rx<User?>(null);
  final RxBool     isLoading    = false.obs;
  final RxString   errorMessage = ''.obs;

  final RxString displayName = ''.obs;
  final RxString email       = ''.obs;
  final RxString photoUrl    = ''.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _handleUserChanged);
  }

  void _handleUserChanged(User? user) {
    if (user != null) {
      _loadUserData(user);
    } else {
      displayName.value = '';
      email.value       = '';
      photoUrl.value    = '';
    }
  }

  Future<void> _loadUserData(User user) async {
    displayName.value = user.displayName ?? '';
    email.value       = user.email       ?? '';
    photoUrl.value    = user.photoURL    ?? '';

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
      } catch (_) {}
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

      await _firestore.collection('users').doc(user.uid).set({
        'uid':       user.uid,
        'name':      name.trim(),
        'email':     email.trim(),
        'photoUrl':  '',
        'provider':  'email',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      await user.updateDisplayName(name.trim());

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

        await _firestore
            .collection('users')
            .doc(uid)
            .update({'lastLogin': FieldValue.serverTimestamp()});
      } catch (_) {
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

      // ✅ FIX: Always sign out first to force the account picker to show.
      // Without this, if a previous sign-in session is cached but broken,
      // signIn() returns null silently instead of showing the picker.
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the picker — not an error
        isLoading.value = false;
        return false;
      }

      // ✅ FIX: Wrap getAuthentication in its own try-catch.
      // This call fails independently of signIn() on some Android versions
      // when the Google Play Services token exchange times out.
      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        errorMessage.value =
        'Google authentication failed. Please try again.';
        isLoading.value = false;
        return false;
      }

      if (googleAuth.idToken == null) {
        errorMessage.value =
        'Google sign in failed — no token received. '
            'Check SHA-1 fingerprint in Firebase Console.';
        isLoading.value = false;
        return false;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user           = userCredential.user!;

      final name      = user.displayName ?? googleUser.displayName ?? '';
      final userEmail = user.email       ?? googleUser.email;
      final photo     = user.photoURL    ?? googleUser.photoUrl ?? '';

      await _firestore.collection('users').doc(user.uid).set({
        'uid':       user.uid,
        'name':      name,
        'email':     userEmail,
        'photoUrl':  photo,
        'provider':  'google',
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      displayName.value = name;
      email.value       = userEmail ?? '';
      photoUrl.value    = photo;

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
      return false;
    } catch (e) {
      // ✅ FIX: Log the actual error so you can see it in the console
      // instead of a silent failure
      print('[AuthController] signInWithGoogle error: $e');
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
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ── Update Profile ──────────────────────────────────────────────────────
  Future<bool> updateProfile({required String name}) async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'name': name.trim()});

      await user.updateDisplayName(name.trim());
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
      case 'email-alreadyflutter pub get-in-use':
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