import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/features/auth/data/impl/auth_remote_ds_impl.dart';
import 'package:transient_team_ws/features/auth/data/models/auth_request_model.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  late AuthRemoteDsImpl remoteDs;
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    remoteDs = AuthRemoteDsImpl(mockAuth);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password';
  final tAuthModel = AuthRequestParamModel(email: tEmail, password: tPassword);

  group('login', () {
    test('should return UserModel when login is successful', () async {
      // arrange
      when(() => mockAuth.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          )).thenAnswer((_) async => mockUserCredential);
      when(() => mockUserCredential.user).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('uid123');
      when(() => mockUser.email).thenReturn(tEmail);

      // act
      final result = await remoteDs.login(authRequestParmModel: tAuthModel);

      // assert
      expect(result.id, 'uid123');
      expect(result.email, tEmail);
    });

    test('should throw AuthenticationFailure when user has no email', () async {
      // arrange
      when(() => mockAuth.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          )).thenAnswer((_) async => mockUserCredential);
      when(() => mockUserCredential.user).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('uid123');
      when(() => mockUser.email).thenReturn(null);

      // act & assert
      expect(
        () => remoteDs.login(authRequestParmModel: tAuthModel),
        throwsA(isA<AuthenticationFailure>()),
      );
    });

    test('should throw mapped failure on FirebaseAuthException', () async {
      // arrange
      when(() => mockAuth.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          )).thenThrow(FirebaseAuthException(code: 'user-not-found'));

      // act & assert
      expect(
        () => remoteDs.login(authRequestParmModel: tAuthModel),
        throwsA(isA<AuthenticationFailure>()),
      );
    });
  });

  group('signUp', () {
    test('should return UserModel when signup is successful', () async {
      // arrange
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          )).thenAnswer((_) async => mockUserCredential);
      when(() => mockUserCredential.user).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('uid123');
      when(() => mockUser.email).thenReturn(tEmail);

      // act
      final result = await remoteDs.signUp(authRequestParmModel: tAuthModel);

      // assert
      expect(result.id, 'uid123');
      expect(result.email, tEmail);
    });
  });

  group('logout', () {
    test('should call signOut', () async {
      // arrange
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});

      // act
      await remoteDs.logout();

      // assert
      verify(() => mockAuth.signOut()).called(1);
    });
  });

  group('getCurrentUser', () {
    test('should return UserModel when user is logged in', () async {
      // arrange
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('uid123');
      when(() => mockUser.email).thenReturn(tEmail);

      // act
      final result = await remoteDs.getCurrentUser();

      // assert
      expect(result.id, 'uid123');
      expect(result.email, tEmail);
    });

    test('should throw UnauthorizedFailure when no user is logged in', () async {
      // arrange
      when(() => mockAuth.currentUser).thenReturn(null);

      // act & assert
      expect(() => remoteDs.getCurrentUser(), throwsA(isA<UnauthorizedFailure>()));
    });
  });
}
