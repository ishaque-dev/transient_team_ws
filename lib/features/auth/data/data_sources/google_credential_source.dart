import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';

/// Wraps the native Google account picker so the auth data source stays
/// testable.
abstract interface class IGoogleCredentialSource {
  /// Returns null when the user dismisses the picker.
  Future<AuthCredential?> obtainCredential();

  Future<void> signOut();
}

final class GoogleCredentialSource implements IGoogleCredentialSource {
  GoogleCredentialSource(
    this._googleSignIn, {
    this.clientId,
    this.serverClientId,
  });

  final GoogleSignIn _googleSignIn;

  /// iOS OAuth client (from `GoogleService-Info.plist`).
  final String? clientId;

  /// Web OAuth client. Android needs it to mint an ID token Firebase accepts.
  final String? serverClientId;

  Future<void>? _initialization;

  Future<void> _ensureInitialized() {
    return _initialization ??= _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  @override
  Future<AuthCredential?> obtainCredential() async {
    try {
      await _ensureInitialized();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw AuthenticationFailure(
          message: 'Google did not return an identity token. Please try again.',
        );
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (error) {
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted => null,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          throw AuthenticationFailure(
            cause: error,
            message:
                'Google sign-in is not configured for this build yet. '
                'Use email and password, or ask an admin to finish setup.',
          ),
        _ => throw AuthenticationFailure(
          cause: error,
          message: 'Google sign-in failed. Please try again.',
        ),
      };
    }
  }

  @override
  Future<void> signOut() async {
    // Nothing to do if Google sign-in was never used in this session; this
    // also avoids initialising the Google SDK just to sign out.
    if (_initialization == null) return;
    try {
      await _initialization!.timeout(const Duration(seconds: 3));
      await _googleSignIn.signOut().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Best effort: the Firebase sign-out is what ends the session.
    }
  }
}
