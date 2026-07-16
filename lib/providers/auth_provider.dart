import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<AuthState>? _sub;

  AuthStatus status = AuthStatus.unknown;
  bool isLoading = false;
  String? errorMessage;

  bool emailConfirmationRequired = false;

  User? get user => _authService.currentUser;
  bool get isLoggedIn => status == AuthStatus.authenticated;

  AuthProvider() {
    status = _authService.isLoggedIn
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    if (status == AuthStatus.authenticated) {
      _authService.ensureProfileExists();
    }
    _sub = _authService.authStateChanges.listen((state) {
      status = _authService.isLoggedIn
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      if (status == AuthStatus.authenticated) {
        _authService.ensureProfileExists();
      }
      notifyListeners();
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    isLoading = true;
    errorMessage = null;
    emailConfirmationRequired = false;
    notifyListeners();
    try {
      final signedInImmediately = await _authService.register(
        email: email,
        password: password,
        username: username,
      );
      emailConfirmationRequired = !signedInImmediately;
      isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) =>
      _run(() => _authService.login(email: email, password: password));

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}