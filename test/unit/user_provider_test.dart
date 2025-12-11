import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mkecitysmart/providers/user_provider.dart';
import 'package:mkecitysmart/services/user_repository.dart';
import 'package:mkecitysmart/models/user_profile.dart';
import 'package:mkecitysmart/models/sighting_report.dart';

import 'user_provider_test.mocks.dart';

@GenerateMocks([UserRepository, FirebaseAuth, User])
void main() {
  late MockUserRepository mockUserRepository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late UserProvider userProvider;

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    when(mockUser.uid).thenReturn('test_uid');
  });

  group('UserProvider', () {
    group('initialization', () {
      test('initializes in guest mode when Firebase is not ready', () async {
        userProvider = UserProvider(
          userRepository: mockUserRepository,
          firebaseReady: false,
        );
        await userProvider.initialize();
        expect(userProvider.isGuest, isTrue);
        expect(userProvider.isLoggedIn, isFalse);
      });

      test('initializes as guest when no user is logged in', () async {
        when(mockFirebaseAuth.currentUser).thenReturn(null);
        userProvider = UserProvider(
          userRepository: mockUserRepository,
          auth: mockFirebaseAuth,
          firebaseReady: true,
        );
        await userProvider.initialize();
        expect(userProvider.isGuest, isTrue);
        expect(userProvider.isLoggedIn, isFalse);
      });

      test('initializes as logged in user', () async {
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUserRepository.loadProfile()).thenAnswer((_) async => UserProfile(id: 'test', name: 'Test User', email: 'test@test.com'));
        userProvider = UserProvider(
          userRepository: mockUserRepository,
          auth: mockFirebaseAuth,
          firebaseReady: true,
        );
        await userProvider.initialize();
        expect(userProvider.isGuest, isFalse);
        expect(userProvider.isLoggedIn, isTrue);
        expect(userProvider.profile?.name, 'Test User');
      });
    });

    group('authentication', () {
      test('login success', () async {
        final mockUserCredential = MockUserCredential(mockUser);
        when(mockFirebaseAuth.signInWithEmailAndPassword(email: 'test@test.com', password: 'password'))
            .thenAnswer((_) async => Future.value(mockUserCredential));
        when(mockUserRepository.loadProfile()).thenAnswer((_) async => UserProfile(id: 'test', name: 'Test User', email: 'test@test.com'));
        
        userProvider = UserProvider(
          userRepository: mockUserRepository,
          auth: mockFirebaseAuth,
          firebaseReady: true,
        );

        final error = await userProvider.login('test@test.com', 'password');

        expect(error, isNull);
        expect(userProvider.isLoggedIn, isTrue);
      });

      test('register success', () async {
        final mockUserCredential = MockUserCredential(mockUser);
        when(mockFirebaseAuth.createUserWithEmailAndPassword(email: 'test@test.com', password: 'password'))
            .thenAnswer((_) async => Future.value(mockUserCredential));
        when(mockUserRepository.loadProfile()).thenAnswer((_) async => null); // New user, no profile yet

        userProvider = UserProvider(
          userRepository: mockUserRepository,
          auth: mockFirebaseAuth,
          firebaseReady: true,
        );

        final error = await userProvider.register(name: 'Test User', email: 'test@test.com', password: 'password');

        expect(error, isNull);
        expect(userProvider.isLoggedIn, isTrue);
        verify(mockUserRepository.saveProfile(any)).called(1);
      });

      test('logout', () async {
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUserRepository.loadProfile()).thenAnswer((_) async => UserProfile(id: 'test', name: 'Test User', email: 'test@test.com'));
        userProvider = UserProvider(
          userRepository: mockUserRepository,
          auth: mockFirebaseAuth,
          firebaseReady: true,
        );
        await userProvider.initialize();
        expect(userProvider.isLoggedIn, isTrue);

        await userProvider.logout();

        expect(userProvider.isLoggedIn, isFalse);
        expect(userProvider.isGuest, isTrue);
        verify(mockFirebaseAuth.signOut()).called(1);
      });
    });

    group('profile', () {
      setUp(() {
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUserRepository.loadProfile()).thenAnswer((_) async => UserProfile(id: 'test_uid', name: 'Test User', email: 'test@test.com'));
        userProvider = UserProvider(
          userRepository: mockUserRepository,
          auth: mockFirebaseAuth,
          firebaseReady: true,
        );
        userProvider.initialize();
      });

      test('updateProfile saves the profile', () async {
        await userProvider.updateProfile(name: 'New Name');
        final captured = verify(mockUserRepository.saveProfile(captureAny)).captured;
        final savedProfile = captured.first as UserProfile;
        expect(savedProfile.name, 'New Name');
      });
    });

    group('sightings', () {
      setUp(() {
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        userProvider = UserProvider(
          userRepository: mockUserRepository,
          auth: mockFirebaseAuth,
          firebaseReady: true,
        );
         userProvider.initialize();
      });

      test('reportSighting saves the sighting', () async {
        await userProvider.reportSighting(type: SightingType.towTruck, location: 'here');
        verify(mockUserRepository.saveSightings(any)).called(1);
      });
    });
  });
}

// Mock UserCredential to be used in tests
class MockUserCredential extends Mock implements UserCredential {
  MockUserCredential(this._user);
  final User _user;
  @override
  User get user => _user;
}