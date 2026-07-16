import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool get isLoggedIn => currentUser != null;

  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    final identities = response.user?.identities;
    if (identities != null && identities.isEmpty) {
      throw const AuthException(
        'An account with this email already exists. Try logging in instead.',
      );
    }

    return response.session != null;
  }

  Future<void> login({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }
  
  Future<void> ensureProfileExists() async {
    final user = currentUser;
    if (user == null) return;

    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return;

    final fallbackUsername =
        (user.userMetadata?['username'] as String?) ?? user.email?.split('@').first ?? 'user';

    await _client.from('profiles').insert({
      'id': user.id,
      'username': fallbackUsername,
    });
  }
}