import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth      _auth      = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn      _googleSignIn = GoogleSignIn.instance;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSub;
  GoogleSignInAccount? _currentGoogleUser;

  final Rx<User?>  firebaseUser = Rx<User?>(null);
  final RxBool     isLoading    = false.obs;
  final RxString   errorMessage = ''.obs;

  final RxString displayName = ''.obs;
  final RxString email       = ''.obs;
  final RxString photoUrl    = ''.obs;

  final RxBool hasPassword = false.obs;
  final RxBool hasGoogle   = false.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _handleUserChanged);
    _initGoogleSignIn();
  }

  void _initGoogleSignIn() {
    _googleSignIn.initialize().then((_) {
      _googleAuthSub = _googleSignIn.authenticationEvents.listen(
            (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _currentGoogleUser = event.user;
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _currentGoogleUser = null;
          }
        },
        onError: (_) {
          _currentGoogleUser = null;
        },
      );
      _googleSignIn.attemptLightweightAuthentication();
    });
  }

  @override
  void onClose() {
    _googleAuthSub?.cancel();
    super.onClose();
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

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;

        final firestoreName  = data['name']     as String? ?? '';
        final firestorePhoto = data['photoUrl'] as String? ?? '';
        final providers      = List<String>.from(data['providers'] ?? []);

        if (firestoreName.isNotEmpty) displayName.value = firestoreName;

        photoUrl.value = firestorePhoto.isNotEmpty
            ? firestorePhoto
            : user.photoURL ?? '';

        hasPassword.value = providers.contains('password');
        hasGoogle.value   = providers.contains('google');
      } else {
        photoUrl.value    = user.photoURL ?? '';
        hasPassword.value = user.providerData.any((p) => p.providerId == 'password');
        hasGoogle.value   = user.providerData.any((p) => p.providerId == 'google.com');
      }
    } catch (_) {
      photoUrl.value    = user.photoURL ?? '';
      hasPassword.value = user.providerData.any((p) => p.providerId == 'password');
      hasGoogle.value   = user.providerData.any((p) => p.providerId == 'google.com');
    }
  }

  bool get hasPasswordLinked =>
      hasPassword.value ||
          (_auth.currentUser?.providerData.any((p) => p.providerId == 'password') ?? false);

  bool get hasGoogleLinked =>
      hasGoogle.value ||
          (_auth.currentUser?.providerData.any((p) => p.providerId == 'google.com') ?? false);

  bool get isLoggedIn => firebaseUser.value != null;

  Future<List<String>> _getProviderForEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) return [];
      final data = query.docs.first.data();

      final raw = data['providers'];
      if (raw is List) return List<String>.from(raw);
      if (raw is String) return [raw];
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Email/Password Sign Up ──────────────────────────────────────────────
  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value    = true;
      errorMessage.value = '';

      final providers = await _getProviderForEmail(email);
      if (providers.isNotEmpty) {
        if (providers.contains('google') && !providers.contains('password')) {
          errorMessage.value = 'This email is already registered with Google. '
              'Please tap "Continue with Google" to sign in.';
        } else {
          errorMessage.value = 'This email is already registered. Please sign in instead.';
        }
        return false;
      }

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
        'providers': ['password'],
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

      final providers = await _getProviderForEmail(email);

      if (providers.isEmpty) {
        errorMessage.value = 'No account found with this email. Please sign up first.';
        return false;
      }

      if (providers.contains('google') && !providers.contains('password')) {
        errorMessage.value =
        'This account uses Google sign-in only. '
            'Go to Profile → Security to add a password, '
            'or tap "Continue with Google".';
        return false;
      }

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

        await _firestore.collection('users').doc(uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        displayName.value = credential.user!.displayName ?? 'Muslim User';
        this.email.value  = credential.user!.email ?? email.trim();
      }

      return true;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        errorMessage.value = 'Incorrect password. Please try again.';
      } else {
        errorMessage.value = _mapFirebaseError(e.code);
      }
      return false;
    } catch (e) {
      errorMessage.value = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Google Sign In / Sign Up ────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    try {
      isLoading.value    = true;
      errorMessage.value = '';

      // Sign out first to force account picker
      await _googleSignIn.signOut();

      // Trigger authentication — shows account picker
      final googleUser = await _googleSignIn.authenticate();

      // authentication is now synchronous in v7
      final googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        errorMessage.value = 'Google sign in failed — no token received. '
            'Check SHA-1 fingerprint in Firebase Console.';
        isLoading.value = false;
        return false;
      }

      final googleCredential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final providers = await _getProviderForEmail(googleUser.email);

      if (providers.isEmpty) {
        return await _completeGoogleSignIn(googleCredential, googleUser, isNew: true);
      }

      if (providers.contains('google')) {
        return await _completeGoogleSignIn(googleCredential, googleUser, isNew: false);
      }

      if (providers.contains('password')) {
        return await _linkGoogleToExistingAccount(googleCredential, googleUser);
      }

      return false;

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

  Future<bool> _completeGoogleSignIn(
      AuthCredential credential,
      GoogleSignInAccount googleUser, {
        required bool isNew,
      }) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final user           = userCredential.user!;

    final name      = user.displayName ?? googleUser.displayName ?? '';
    final userEmail = user.email       ?? googleUser.email;
    final photo     = user.photoURL    ?? googleUser.photoUrl ?? '';

    if (isNew) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid':       user.uid,
        'name':      name,
        'email':     userEmail,
        'photoUrl':  photo,
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
    email.value       = userEmail ?? '';
    photoUrl.value    = photo;
    return true;
  }

  // ── Auto-links Google to existing email+password account ───────────────
  Future<bool> _linkGoogleToExistingAccount(
      AuthCredential googleCredential,
      GoogleSignInAccount googleUser,
      ) async {
    try {
      final userCredential = await _auth.signInWithCredential(googleCredential);
      final user = userCredential.user!;

      final providerIds = user.providerData.map((p) => p.providerId).toList();
      print('[Auth] Providers after Google link: $providerIds');

      final name      = user.displayName ?? googleUser.displayName ?? '';
      final userEmail = user.email       ?? googleUser.email;
      final photo     = user.photoURL    ?? googleUser.photoUrl ?? '';

      final existingDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final existingPhoto = existingDoc.data()?['photoUrl'] as String? ?? '';
      final existingName  = existingDoc.data()?['name']     as String? ?? '';

      final linkedProviders = providerIds
          .map((id) => id == 'google.com' ? 'google' : id)
          .toList();

      final Map<String, dynamic> updateData = {
        'providers': FieldValue.arrayUnion(['google']),
        'lastLogin': FieldValue.serverTimestamp(),
      };

      if (existingPhoto.isEmpty && photo.isNotEmpty) {
        updateData['photoUrl'] = photo;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);

      displayName.value = existingName.isNotEmpty ? existingName : name;
      email.value       = userEmail ?? '';
      photoUrl.value    = existingPhoto.isNotEmpty ? existingPhoto : photo;
      hasPassword.value = linkedProviders.contains('password');
      hasGoogle.value   = linkedProviders.contains('google');

      return true;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage.value =
        'Could not link Google. Please enable account linking '
            'in Firebase Console, or contact support.';
      } else {
        errorMessage.value = _mapFirebaseError(e.code);
      }
      return false;
    }
  }

  // ── Forgot Password ─────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String emailAddress) async {
    try {
      isLoading.value = true;

      final providers = await _getProviderForEmail(emailAddress);
      if (providers.isEmpty) {
        errorMessage.value = 'No account found with this email.';
        return false;
      }
      if (providers.contains('google') && !providers.contains('password')) {
        errorMessage.value = 'This account uses Google sign-in. '
            'No password to reset — use "Continue with Google".';
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

  // ── Add OR Update Password ──────────────────────────────────────────────
  Future<bool> addPasswordToAccount({required String password}) async {
    try {
      isLoading.value    = true;
      errorMessage.value = '';

      final user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = 'No user signed in.';
        return false;
      }

      await user.reload();
      final freshUser = _auth.currentUser!;

      final alreadyLinked = freshUser.providerData
          .any((p) => p.providerId == 'password');

      if (alreadyLinked) {
        // UPDATE existing password — re-auth with Google if session expired
        try {
          await freshUser.updatePassword(password);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            // Re-auth with Google
            await _googleSignIn.signOut();
            final gUser = await _googleSignIn.authenticate();
            final gAuth = gUser.authentication;
            final gCred = GoogleAuthProvider.credential(
              idToken: gAuth.idToken,
            );
            await freshUser.reauthenticateWithCredential(gCred);
            await _auth.currentUser!.updatePassword(password);
          } else {
            rethrow;
          }
        }

        hasPassword.value = true;
        return true;

      } else {
        // ADD new password credential
        final emailCredential = EmailAuthProvider.credential(
          email:    freshUser.email!,
          password: password,
        );

        await freshUser.linkWithCredential(emailCredential);

        await _firestore.collection('users').doc(freshUser.uid).update({
          'providers': FieldValue.arrayUnion(['password']),
        });

        hasPassword.value = true;
        return true;
      }

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

  // ── Error Mapping ───────────────────────────────────────────────────────
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
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
        return 'Network error. Check your connection.';
      case 'account-exists-with-different-credential':
        return 'This email is registered with a different sign-in method.';
      case 'sign_in_failed':
        return 'Google sign in failed. Check SHA-1 in Firebase Console.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}