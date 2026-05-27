import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthController
//
// Supports:
//   • Email + Password  — sign up, sign in, password reset
//   • Google Sign-In    — sign up, sign in  (google_sign_in v7)
//   • Auto-link / merge — Google ↔ Email+Password on the same email
//   • Add / update password on a Google-only account
//   • Update display name
//
// Dependencies:
//   firebase_auth, cloud_firestore, google_sign_in ^7.x, get
//
// IMPORTANT — replace the placeholder below with your actual Web OAuth
// Client ID (Firebase Console → Project Settings → General → Web API key,
// or Google Cloud Console → APIs & Services → Credentials → Web client).
// Without it, idToken will be null on Android and sign-in will fail.
// ─────────────────────────────────────────────────────────────────────────────

const String _kWebClientId =
    '330629038977-7ivpamsds13tqcr6v15sokcrtgav0p3o.apps.googleusercontent.com';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // v7 uses a singleton — no constructor, no GoogleSignIn()
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  // ── Observables ───────────────────────────────────────────────────────────

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString displayName = ''.obs;
  final RxString email = ''.obs;
  final RxString photoUrl = ''.obs;

  final RxBool hasPassword = false.obs;
  final RxBool hasGoogle = false.obs;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // Use userChanges() as the single source of truth for auth state.
    // It fires on sign-in, sign-out, token refresh, and provider link/unlink.
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _handleUserChanged);

    // v7: initialize once on startup with the serverClientId so that
    // idToken is always populated on Android, then attempt silent sign-in.
    _googleSignIn
        .initialize(serverClientId: _kWebClientId)
        .then((_) {
      // Listen to authentication events (silent sign-in results, etc.)
      _googleSignIn.authenticationEvents
          .listen(_handleGoogleAuthEvent)
          .onError((_) {});

      // Attempt silent / lightweight sign-in for returning Google users.
      _googleSignIn.attemptLightweightAuthentication();
    }).catchError((_) {
      // initialization failure is non-fatal — user can still sign in manually
    });
  }

  // Google auth events are informational only.
  // Firebase userChanges() stream is the source of truth.
  void _handleGoogleAuthEvent(GoogleSignInAuthenticationEvent event) {}

  void _handleUserChanged(User? user) {
    if (user != null) {
      _loadUserData(user);
    } else {
      displayName.value = '';
      email.value = '';
      photoUrl.value = '';
      hasPassword.value = false;
      hasGoogle.value = false;
    }
  }

  Future<void> _loadUserData(User user) async {
    // Seed from Firebase Auth immediately so UI isn't blank
    displayName.value = user.displayName ?? '';
    email.value = user.email ?? '';

    // Read providers from live Firebase Auth
    hasPassword.value =
        user.providerData.any((p) => p.providerId == 'password');
    hasGoogle.value =
        user.providerData.any((p) => p.providerId == 'google.com');

    // Enrich from Firestore (name & photo may differ from Firebase Auth)
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final firestoreName = data['name'] as String? ?? '';
        final firestorePhoto = data['photoUrl'] as String? ?? '';
        if (firestoreName.isNotEmpty) displayName.value = firestoreName;
        photoUrl.value =
        firestorePhoto.isNotEmpty ? firestorePhoto : user.photoURL ?? '';
      } else {
        photoUrl.value = user.photoURL ?? '';
      }
    } catch (_) {
      photoUrl.value = user.photoURL ?? '';
    }
  }

  // ── Computed getters ──────────────────────────────────────────────────────

  bool get isLoggedIn => firebaseUser.value != null;

  bool get hasPasswordLinked =>
      hasPassword.value ||
          (_auth.currentUser?.providerData
              .any((p) => p.providerId == 'password') ??
              false);

  bool get hasGoogleLinked =>
      hasGoogle.value ||
          (_auth.currentUser?.providerData
              .any((p) => p.providerId == 'google.com') ??
              false);

  // ── Firestore provider lookup (best-effort) ───────────────────────────────
  // Used to detect existing accounts before Firebase Auth calls, so we can
  // give better error messages and auto-link where appropriate.

  Future<List<String>> _getProvidersFromFirestore(
      String emailAddress) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: emailAddress.trim())
          .limit(1)
          .get();
      if (query.docs.isEmpty) return [];
      final raw = query.docs.first.data()['providers'];
      if (raw is List) return List<String>.from(raw);
      if (raw is String) return [raw];
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Google credential helper (v7 API) ─────────────────────────────────────
  //
  // Key v7 changes vs v6:
  //   • GoogleSignIn.instance  (singleton, no constructor)
  //   • initialize(serverClientId: ...)  must be called once at startup
  //   • authenticate()  replaces signIn() — throws instead of returning null
  //   • authorizationClient is on the ACCOUNT object, not the instance
  //   • Catch GoogleSignInException, check e.code.name for 'canceled' etc.

  Future<
      ({
      AuthCredential credential,
      String email,
      String displayName,
      String photoUrl,
      })> _getGoogleCredential() async {
    // Sign out first so the account picker is always shown.
    // Remove this line if you want to skip the picker for returning users.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    if (!_googleSignIn.supportsAuthenticate()) {
      throw Exception(
        'Google Sign-In is not supported on this platform/device.',
      );
    }

    // authenticate() shows the Credential Manager / account picker.
    // scopeHint tells it which scopes we'll need so it can optimise the UX.
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
      scopeHint: ['email', 'profile'],
    );

    // idToken identifies the user — requires serverClientId to be set.
    final String? idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw Exception(
        'Google sign-in failed: idToken is null. '
            'Ensure serverClientId is set in initialize() and your '
            'SHA-1 fingerprint is registered in Firebase Console.',
      );
    }

    // authorizationClient lives on the ACCOUNT object (not on the instance).
    // Try cached auth first; fall back to requesting user consent.
    final clientAuth =
        await googleUser.authorizationClient.authorizationForScopes(
          ['email', 'profile'],
        ) ??
            await googleUser.authorizationClient.authorizeScopes(
              ['email', 'profile'],
            );

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: clientAuth?.accessToken, // nullable — Firebase only needs idToken
    );

    return (
    credential: credential,
    email: googleUser.email,
    displayName: googleUser.displayName ?? '',
    photoUrl: googleUser.photoUrl ?? '',
    );
  }

  // ── Email / Password — Sign Up ────────────────────────────────────────────

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Check Firestore first for a friendlier early-exit message
      final existingProviders = await _getProvidersFromFirestore(email);
      if (existingProviders.contains('password')) {
        errorMessage.value =
        'This email is already registered. Please sign in instead.';
        return false;
      }

      UserCredential credential;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // A Google account already exists for this email.
          // Verify the user owns it, then link password to it.
          return await _linkPasswordToGoogleAccount(
            email: email.trim(),
            password: password,
            name: name.trim(),
          );
        }
        rethrow;
      }

      final user = credential.user!;
      await user.updateDisplayName(name.trim());

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim(),
        'photoUrl': '',
        'providers': ['password'],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      displayName.value = name.trim();
      this.email.value = email.trim();
      photoUrl.value = '';
      hasPassword.value = true;

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
      return false;
    } catch (_) {
      errorMessage.value = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Email / Password — Sign In ────────────────────────────────────────────

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // ✅ Just try — don't pre-check Firestore providers
      // Email enumeration protection means we can't reliably detect
      // Google-only accounts before attempting sign-in anyway
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;
      final uid = user.uid;

      // After successful sign-in, sync Firestore
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          displayName.value = (data['name'] as String? ?? '').isNotEmpty
              ? data['name'] as String
              : user.displayName ?? 'User';
          this.email.value = data['email'] as String? ?? email.trim();
          photoUrl.value = data['photoUrl'] as String? ?? '';
        } else {
          displayName.value = user.displayName ?? 'User';
          this.email.value = user.email ?? email.trim();
          photoUrl.value = user.photoURL ?? '';
        }
        await _firestore.collection('users').doc(uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        displayName.value = user.displayName ?? 'User';
        this.email.value = user.email ?? email.trim();
      }

      hasPassword.value =
          user.providerData.any((p) => p.providerId == 'password');
      hasGoogle.value =
          user.providerData.any((p) => p.providerId == 'google.com');

      return true;
    } on FirebaseAuthException catch (e) {
      // With email enumeration protection ON, Firebase returns
      // 'invalid-credential' for ALL failures — wrong password,
      // email not found, AND google-only accounts
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        // Check Firestore ONLY after failure to give a better message
        final providers = await _getProvidersFromFirestore(email);
        if (providers.isNotEmpty &&
            providers.contains('google') &&
            !providers.contains('password')) {
          errorMessage.value =
          'This account uses Google sign-in only. '
              'Tap "Continue with Google", or go to Profile → Security '
              'to add a password first.';
        } else {
          errorMessage.value = 'Incorrect email or password. Please try again.';
        }
      } else if (e.code == 'user-not-found') {
        errorMessage.value =
        'No account found with this email. Please sign up first.';
      } else {
        errorMessage.value = _mapFirebaseError(e.code);
      }
      return false;
    } catch (_) {
      errorMessage.value = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Google — Sign In / Sign Up ────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final google = await _getGoogleCredential();
      final providers = await _getProvidersFromFirestore(google.email);

      if (providers.isEmpty) {
        // Brand-new user — create account
        return await _completeGoogleSignIn(
          google.credential,
          google.email,
          google.displayName,
          google.photoUrl,
          isNew: true,
        );
      }

      if (providers.contains('google')) {
        // Returning Google user
        return await _completeGoogleSignIn(
          google.credential,
          google.email,
          google.displayName,
          google.photoUrl,
          isNew: false,
        );
      }

      if (providers.contains('password')) {
        // Email+password account exists — auto-link Google to it
        return await _linkGoogleToPasswordAccount(
          google.credential,
          google.email,
          google.displayName,
          google.photoUrl,
        );
      }

      return false;
    } on GoogleSignInException catch (e) {
      // User dismissed the picker — silent failure, no error shown
      if (e.code.name == 'canceled') return false;
      errorMessage.value =
          _mapGoogleSignInError(e.code.name);
      return false;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
      return false;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('not supported')) {
        errorMessage.value = msg;
      } else {
        errorMessage.value = 'Google sign-in failed. Please try again.';
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Completes Google sign-in after Firebase credential exchange.
  Future<bool> _completeGoogleSignIn(
      AuthCredential credential,
      String googleEmail,
      String googleName,
      String googlePhoto, {
        required bool isNew,
      }) async {
    final userCred = await _auth.signInWithCredential(credential);
    final user = userCred.user!;

    final name = user.displayName ?? googleName;
    final uEmail = user.email ?? googleEmail;
    final photo = user.photoURL ?? googlePhoto;

    if (isNew) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': uEmail,
        'photoUrl': photo,
        'providers': ['google'],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('users').doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }

    displayName.value = name;
    email.value = uEmail;
    photoUrl.value = photo;
    hasGoogle.value = true;
    hasPassword.value =
        user.providerData.any((p) => p.providerId == 'password');

    return true;
  }

  // ── Merge: Google → existing Email+Password account ───────────────────────
  //
  // Firebase auto-merges when "Link accounts with same email" is enabled in
  // Firebase Console → Authentication → Settings → User actions.

  Future<bool> _linkGoogleToPasswordAccount(
      AuthCredential googleCredential,
      String googleEmail,
      String googleName,
      String googlePhoto,
      ) async {
    try {
      final userCred = await _auth.signInWithCredential(googleCredential);
      final user = userCred.user!;
      final photo = user.photoURL ?? googlePhoto;

      final existingDoc =
      await _firestore.collection('users').doc(user.uid).get();
      final existingName = existingDoc.data()?['name'] as String? ?? '';
      final existingPhoto = existingDoc.data()?['photoUrl'] as String? ?? '';

      // Read real provider state from Firebase Auth (source of truth)
      final realHasPassword =
      user.providerData.any((p) => p.providerId == 'password');
      final realHasGoogle =
      user.providerData.any((p) => p.providerId == 'google.com');

      // Sync Firestore to match real Firebase Auth provider state
      final Map<String, dynamic> updateData = {
        'providers': [
          if (realHasPassword) 'password',
          if (realHasGoogle) 'google',
        ],
        'lastLogin': FieldValue.serverTimestamp(),
      };

      if (existingPhoto.isEmpty && photo.isNotEmpty) {
        updateData['photoUrl'] = photo;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);

      displayName.value =
      existingName.isNotEmpty ? existingName : user.displayName ?? googleName;
      email.value = user.email ?? googleEmail;
      photoUrl.value = existingPhoto.isNotEmpty ? existingPhoto : photo;
      hasPassword.value = realHasPassword;   // reflects reality
      hasGoogle.value = realHasGoogle;       // reflects reality

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage.value =
        'Could not link Google to this account. '
            'Enable "Link accounts with same email" in '
            'Firebase Console → Authentication → Settings.';
      } else {
        errorMessage.value = _mapFirebaseError(e.code);
      }
      return false;
    }
  }

  // ── Merge: Email+Password → existing Google account ───────────────────────
  //
  // Called from signUpWithEmail() when Firebase returns email-already-in-use
  // and we know a Google account exists for that email.
  // We verify the user owns the Google account, then link the password to it.

  Future<bool> _linkPasswordToGoogleAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final google = await _getGoogleCredential();

      if (google.email.toLowerCase() != email.toLowerCase()) {
        errorMessage.value =
        'The Google account selected does not match the email entered. '
            'Please select the correct Google account.';
        return false;
      }

      final userCred = await _auth.signInWithCredential(google.credential);
      final user = userCred.user!;

      final emailCred = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.linkWithCredential(emailCred);

      await _firestore.collection('users').doc(user.uid).update({
        'providers': FieldValue.arrayUnion(['password']),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      hasPassword.value = true;
      hasGoogle.value = true;
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code.name == 'canceled') return false;
      errorMessage.value = _mapGoogleSignInError(e.code.name);
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        errorMessage.value =
        'This email is already registered. Please sign in instead.';
      } else {
        errorMessage.value = _mapFirebaseError(e.code);
      }
      return false;
    } catch (e) {
      errorMessage.value = 'Google verification failed. Please try again.';
      return false;
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String emailAddress) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final providers = await _getProvidersFromFirestore(emailAddress);
      if (providers.isNotEmpty &&
          providers.contains('google') &&
          !providers.contains('password')) {
        errorMessage.value =
        'This account uses Google sign-in. '
            'There is no password to reset — tap "Continue with Google".';
        return false;
      }

      await _auth.sendPasswordResetEmail(email: emailAddress.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ── Update Display Name ───────────────────────────────────────────────────

  Future<bool> updateProfile({required String name}) async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return false;

      await Future.wait([
        _firestore
            .collection('users')
            .doc(user.uid)
            .update({'name': name.trim()}),
        user.updateDisplayName(name.trim()),
      ]);

      displayName.value = name.trim();
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Add OR Update Password ────────────────────────────────────────────────
  //
  // Works for both cases:
  //   • Google-only account → links a new password provider
  //   • Account already has password → updates it
  //
  // Re-authentication strategy:
  //   • If Google is linked → re-auth via Google picker
  //   • If only email+password → surface a "please sign in again" message
  //     (we can't re-auth with email without knowing the current password)

  Future<bool> addPasswordToAccount({required String password}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = 'No user signed in.';
        return false;
      }

      // Reload to get the freshest provider list
      await user.reload();
      final freshUser = _auth.currentUser!;
      final alreadyLinked =
      freshUser.providerData.any((p) => p.providerId == 'password');

      if (alreadyLinked) {
        // UPDATE existing password
        try {
          await freshUser.updatePassword(password);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            if (hasGoogleLinked) {
              // Re-auth via Google then retry
              final google = await _getGoogleCredential();
              await freshUser
                  .reauthenticateWithCredential(google.credential);
              await _auth.currentUser!.updatePassword(password);
            } else {
              // Only email+password — we can't re-auth without current password
              errorMessage.value =
              'For security, please sign out and sign in again '
                  'before changing your password.';
              return false;
            }
          } else {
            rethrow;
          }
        }
      } else {
        // LINK new password provider (Google-only account)
        final emailCred = EmailAuthProvider.credential(
          email: freshUser.email!,
          password: password,
        );
        await freshUser.linkWithCredential(emailCred);
        await _firestore
            .collection('users')
            .doc(freshUser.uid)
            .update({
          'providers': FieldValue.arrayUnion(['password']),
        });
      }

      hasPassword.value = true;
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code.name == 'canceled') return false;
      errorMessage.value = _mapGoogleSignInError(e.code.name);
      return false;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapFirebaseError(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'Failed to set password. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'account-exists-with-different-credential':
        return 'This email is registered with a different sign-in method.';
      case 'provider-already-linked':
        return 'This sign-in method is already linked to your account.';
      case 'requires-recent-login':
        return 'Please sign in again before making this change.';
      case 'credential-already-in-use':
        return 'This Google account is already linked to another user.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // Maps GoogleSignInExceptionCode.name values to user-friendly messages.
  String _mapGoogleSignInError(String codeName) {
    switch (codeName) {
      case 'canceled':
        return ''; // silent — user dismissed the picker intentionally
      case 'interrupted':
        return 'Sign-in was interrupted. Please try again.';
      case 'clientConfigurationError':
        return 'Google Sign-In configuration error. Please contact support.';
      case 'providerConfigurationError':
      case 'uiUnavailable':
        return 'Google Sign-In is currently unavailable. Please try again later.';
      case 'userMismatch':
        return 'Account mismatch. Please sign out and try again.';
      default:
        return 'Google sign-in failed. Please try again.';
    }
  }
}