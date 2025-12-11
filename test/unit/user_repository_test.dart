import 'package:mkecitysmart/data/local/local_database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:mkecitysmart/models/user_profile.dart';
import 'package:mkecitysmart/models/ticket.dart';
import 'package:mkecitysmart/models/payment_receipt.dart';
import 'package:mkecitysmart/models/sighting_report.dart';
import 'package:mkecitysmart/models/maintenance_report.dart';
import 'package:mkecitysmart/services/user_repository.dart';

import 'user_repository_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() { driftRuntimeOptions.dontWarnAboutMultipleDatabases = true; });

  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late UserRepository userRepository;
  late LocalDatabase localDb;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(auth.currentUser).thenReturn(user);
    when(user.uid).thenReturn('user1');
    localDb = LocalDatabase.test();
    userRepository = UserRepository(auth: auth, firestore: firestore, localDatabase: localDb);
  });

  tearDown(() async { await localDb.close(); });

  group('UserRepository', () {
    test('saves and loads profile', () async {
      final profile = UserProfile(id: 'user1', name: 'Alice', email: 'a@x.com');
      await userRepository.saveProfile(profile);

      final loadedProfile = await userRepository.loadProfile();
      expect(loadedProfile?.name, 'Alice');
    });

    test('clears profile', () async {
      final profile = UserProfile(id: 'user1', name: 'Test', email: 't@x.com');
      await userRepository.saveProfile(profile);

      await userRepository.clearProfile();
      final loaded = await userRepository.loadProfile();
      expect(loaded, isNull);
    });

    test('persists scoped domain data (tickets, receipts, sightings)', () async {
      final tickets = [
        Ticket(
          id: 't1',
          plate: 'ABC',
          amount: 50,
          reason: 'Test',
          location: 'Loc',
          issuedAt: DateTime(2024, 1, 1),
          dueDate: DateTime(2024, 2, 1),
        ),
      ];
      final receipts = [
        PaymentReceipt(
          id: 'r1',
          amountCharged: 10,
          method: 'card',
          reference: 'ref1',
          createdAt: DateTime(2024, 3, 1),
        ),
      ];
      final sightings = [
        SightingReport(
          id: 's1',
          type: SightingType.parkingEnforcer,
          location: 'Main',
          notes: 'note',
          reportedAt: DateTime(2024, 4, 1),
        ),
      ];
      final reports = [
        MaintenanceReport(
          id: 'm1',
          category: MaintenanceCategory.pothole,
          description: 'desc',
          location: 'loc',
          createdAt: DateTime(2024, 5, 1),
        ),
      ];

      await userRepository.saveTickets(tickets);
      await userRepository.saveReceipts(receipts);
      await userRepository.saveSightings(sightings);
      await userRepository.saveMaintenanceReports(reports);

      final loadedTickets = await userRepository.loadTickets();
      final loadedReceipts = await userRepository.loadReceipts();
      final loadedSightings = await userRepository.loadSightings();
      final loadedReports = await userRepository.loadMaintenanceReports();

      expect(loadedTickets.single.id, 't1');
      expect(loadedReceipts.single.id, 'r1');
      expect(loadedSightings.single.id, 's1');
      expect(loadedReports.single.id, 'm1');
    });

    test('saveTickets replaces existing subcollection documents', () async {
      await userRepository.saveTickets([
        Ticket(
          id: 'old',
          plate: 'OLD',
          amount: 10,
          reason: 'old',
          location: 'loc',
          issuedAt: DateTime(2024, 1, 1),
          dueDate: DateTime(2024, 1, 2),
        ),
      ]);

      await userRepository.saveTickets([
        Ticket(
          id: 'new',
          plate: 'NEW',
          amount: 20,
          reason: 'new',
          location: 'loc',
          issuedAt: DateTime(2024, 2, 1),
          dueDate: DateTime(2024, 2, 2),
        ),
      ]);

      final loadedTickets = await userRepository.loadTickets();
      expect(loadedTickets.single.id, 'new');
    });

    test('syncPending flushes queued profile upserts', () async {
      final profile = UserProfile(
        id: 'user1',
        name: 'Queued User',
        email: 'queued@example.com',
      );
      await localDb.enqueueProfileSync(profile);

      await userRepository.syncPending();

      final pending = await localDb.pendingMutations();
      expect(pending, isEmpty);
      final stored =
          await firestore.collection('users').doc('user1').get();
      expect(stored.data()?['name'], 'Queued User');
    });
  });

  group('UserRepository with no authenticated user', () {
    setUp(() {
      auth = MockFirebaseAuth();
      when(auth.currentUser).thenReturn(null);
      localDb = LocalDatabase.test();
    userRepository = UserRepository(auth: auth, firestore: firestore, localDatabase: localDb);
    });

    test('loadProfile returns null', () async {
      final profile = await userRepository.loadProfile();
      expect(profile, isNull);
    });

    test('loadSightings returns empty list', () async {
      final sightings = await userRepository.loadSightings();
      expect(sightings, isEmpty);
    });

    test('saveProfile queues mutation when no user is active', () async {
      final profile = UserProfile(
        id: 'pending-user',
        name: 'Offline',
        email: 'offline@example.com',
      );

      await userRepository.saveProfile(profile);

      final pending = await localDb.pendingMutations();
      expect(pending, isNotEmpty);
      expect(pending.first.type, 'profile_upsert');
    });
  });
}
