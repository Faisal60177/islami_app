import 'package:flutter/foundation.dart';

@immutable
class AuthState {
  final bool isLoading;
  final String errorMessage;
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final bool hasPassword;
  final bool hasGoogle;
  final bool isLoggedIn;

  const AuthState({
    this.isLoading    = false,
    this.errorMessage = '',
    this.uid          = '',
    this.displayName  = '',
    this.email        = '',
    this.photoUrl     = '',
    this.hasPassword  = false,
    this.hasGoogle    = false,
    this.isLoggedIn   = false,
  });

  AuthState copyWith({
    bool?   isLoading,
    String? errorMessage,
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    bool?   hasPassword,
    bool?   hasGoogle,
    bool?   isLoggedIn,
  }) {
    return AuthState(
      isLoading:    isLoading    ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      uid:          uid          ?? this.uid,
      displayName:  displayName  ?? this.displayName,
      email:        email        ?? this.email,
      photoUrl:     photoUrl     ?? this.photoUrl,
      hasPassword:  hasPassword  ?? this.hasPassword,
      hasGoogle:    hasGoogle    ?? this.hasGoogle,
      isLoggedIn:   isLoggedIn   ?? this.isLoggedIn,
    );
  }
}