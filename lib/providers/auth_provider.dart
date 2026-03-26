import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide User, AuthException;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart' as local_user;
import '../data/repositories/repositories_impl.dart';
import '../data/datasources/remote_datasource.dart';
import '../data/exceptions/exceptions.dart' as exceptions;

class AuthProvider with ChangeNotifier {
  final RemoteDataSource remoteDataSource;
  late final UserProfileRepositoryImpl _userProfileRepository;
  late final GoogleSignIn _googleSignIn;
  StreamSubscription<AuthState>? _authSubscription;
  bool _isDisposed = false;

  local_user.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGoogleSigningIn = false;
  bool _isRestoringSession = true;

  local_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isGoogleSigningIn => _isGoogleSigningIn;
  bool get isRestoringSession => _isRestoringSession;
  bool get hasAuthenticatedSession =>
      Supabase.instance.client.auth.currentUser != null;
  bool get isLoggedIn => _currentUser != null || hasAuthenticatedSession;
  String? get currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? _currentUser?.id;
  String? get errorMessage => _errorMessage;

  AuthProvider({required this.remoteDataSource}) {
    _initRepository();
    _initializeAuthListener();
    _initializeGoogleSignIn();
    _restoreSession();
  }

  void _initRepository() {
    _userProfileRepository = UserProfileRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
  }

  void _initializeGoogleSignIn() {
    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ],
    );
  }

  Future<void> _restoreSession() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _loadUserProfile(user.id);
      }
    } catch (e) {
      debugPrint('Restore session error: $e');
    } finally {
      _isRestoringSession = false;
      _notifySafely();
    }
  }

  /// Listen to Supabase auth state changes
  void _initializeAuthListener() {
    try {
      _authSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((
        data,
      ) {
        unawaited(_handleAuthStateChange(data));
      });
    } catch (e) {
      debugPrint('Auth listener error: $e');
    }
  }

  Future<void> _handleAuthStateChange(AuthState data) async {
    if (data.session?.user != null) {
      final user = data.session!.user;
      await _loadUserProfile(user.id);
      _isRestoringSession = false;
      _notifySafely();
      return;
    }

    _currentUser = null;
    _isRestoringSession = false;
    _notifySafely();
  }

  /// Login with Supabase Auth
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        await _loadUserProfile(user.id);
        _isLoading = false;
        _isRestoringSession = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (e.toString().contains('Invalid login credentials') ||
          e.toString().contains('invalid_credentials')) {
        _errorMessage = 'Invalid email or password';
      } else {
        _errorMessage = 'Login error: ${e.toString()}';
      }
      _isLoading = false;
      _isRestoringSession = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with Supabase Auth
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create auth account
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Create profile in profiles table
        try {
          await remoteDataSource.upsertUserProfile(
            userId: user.id,
            email: email,
            name: name,
          );
        } catch (profileError) {
          debugPrint(
              'Profile creation error (might be duplicate): $profileError');
          // Continue anyway - profile might already exist
        }

        // Load the created profile
        await _loadUserProfile(user.id);
        _isLoading = false;
        _isRestoringSession = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (e.toString().contains('already registered')) {
        _errorMessage = 'Email already registered';
      } else {
        _errorMessage = 'Signup error: ${e.toString()}';
      }
      _isLoading = false;
      _isRestoringSession = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with Google
  Future<bool> signUpWithGoogle() async {
    _isGoogleSigningIn = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isGoogleSigningIn = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        _errorMessage = 'Failed to get Google credentials';
        _isGoogleSigningIn = false;
        notifyListeners();
        return false;
      }

      // Sign in with Google via Supabase
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken ?? accessToken,
      );

      final user = response.user;
      if (user != null) {
        // Check if profile exists, if not create it
        try {
          await remoteDataSource.upsertUserProfile(
            userId: user.id,
            email: user.email ?? googleUser.email,
            name: user.userMetadata?['full_name'] ??
                googleUser.displayName ??
                'User',
          );
        } catch (profileError) {
          // Profile might already exist, ignore error
          debugPrint('Profile creation skipped: $profileError');
        }

        await _loadUserProfile(user.id);
        _isGoogleSigningIn = false;
        _isRestoringSession = false;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in failed: ${e.toString()}';
      _isGoogleSigningIn = false;
      _isRestoringSession = false;
      notifyListeners();
      return false;
    }
  }

  /// Load user profile from Supabase
  Future<void> _loadUserProfile(String userId) async {
    try {
      final userProfile = await _userProfileRepository.getUserProfile(userId);

      _currentUser = local_user.User(
        id: userProfile.id,
        name: userProfile.name ?? 'User',
        email: userProfile.email,
        phone: userProfile.phone,
        address: userProfile.address,
      );

      _notifySafely();
    } catch (e) {
      debugPrint('Load profile error: $e');

      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null || authUser.id != userId) {
        return;
      }

      try {
        await remoteDataSource.upsertUserProfile(
          userId: authUser.id,
          email: authUser.email ?? _currentUser?.email ?? '',
          name: authUser.userMetadata?['full_name'] ??
              _currentUser?.name ??
              'User',
          phone: _currentUser?.phone,
        );

        final fallbackProfile =
            await _userProfileRepository.getUserProfile(userId);
        _currentUser = local_user.User(
          id: fallbackProfile.id,
          name: fallbackProfile.name ?? 'User',
          email: fallbackProfile.email,
          phone: fallbackProfile.phone,
          address: fallbackProfile.address,
        );
        _notifySafely();
      } catch (profileRecoveryError) {
        debugPrint('Profile recovery error: $profileRecoveryError');
        final recoveredName =
            (authUser.userMetadata?['full_name'] as String?)?.trim();
        _currentUser = local_user.User(
          id: authUser.id,
          name: (recoveredName != null && recoveredName.isNotEmpty)
              ? recoveredName
              : _currentUser?.name ?? 'User',
          email: authUser.email ?? _currentUser?.email ?? '',
          phone: _currentUser?.phone,
          address: _currentUser?.address,
        );
        _notifySafely();
      }
    }
  }

  void _notifySafely() {
    if (_isDisposed) {
      return;
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) {
        return;
      }
      notifyListeners();
    });
  }

  /// Logout - sign out from Supabase
  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signOut();
      // Also sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      _currentUser = null;
      _errorMessage = null;
      _isLoading = false;
      _isRestoringSession = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Logout error: ${e.toString()}';
      _isLoading = false;
      _isRestoringSession = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw exceptions.AuthException('User not authenticated');
      }

      final currentAuthUser = Supabase.instance.client.auth.currentUser;
      if (currentAuthUser == null) {
        throw exceptions.AuthException('User not authenticated');
      }

      final normalizedEmail = email.trim();
      if (normalizedEmail.isNotEmpty &&
          normalizedEmail != (currentAuthUser.email ?? '')) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(email: normalizedEmail),
        );
      }

      // Update in Supabase
      await _userProfileRepository.updateUserProfile(
        userId: userId,
        name: name,
        email: normalizedEmail,
        phone: phone,
      );

      // Update local state
      _currentUser = local_user.User(
        id: _currentUser?.id ?? userId,
        name: name,
        email: normalizedEmail,
        phone: phone ?? _currentUser?.phone,
        address: _currentUser?.address,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Profile update error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Check if user is authenticated with Supabase
  Future<bool> checkAuthStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _loadUserProfile(user.id);
        _isRestoringSession = false;
        notifyListeners();
        return true;
      }
      _isRestoringSession = false;
      return false;
    } catch (e) {
      debugPrint('Check auth status error: $e');
      _isRestoringSession = false;
      return false;
    }
  }

  /// Get current Supabase session user
  local_user.User? getSessionUser() {
    return Supabase.instance.client.auth.currentUser != null
        ? _currentUser
        : null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
