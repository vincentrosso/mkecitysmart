import 'package:firebase_auth_mocks/firebase_auth_mocks.dart' as mock_auth;
import 'package:flutter_test/flutter_test.dart';

import 'package:mkecitysmart/models/ad_preferences.dart';
import 'package:mkecitysmart/models/garbage_schedule.dart';
import 'package:mkecitysmart/models/maintenance_report.dart';
import 'package:mkecitysmart/models/payment_receipt.dart';
import 'package:mkecitysmart/models/permit.dart';
import 'package:mkecitysmart/models/sighting_report.dart';
import 'package:mkecitysmart/models/street_sweeping.dart';
import 'package:mkecitysmart/models/subscription_plan.dart';
import 'package:mkecitysmart/models/ticket.dart';
import 'package:mkecitysmart/models/user_preferences.dart';
import 'package:mkecitysmart/models/user_profile.dart';
import 'package:mkecitysmart/models/vehicle.dart';
import 'package:mkecitysmart/providers/user_provider.dart';
import 'package:mkecitysmart/services/user_repository.dart';

class FakeUserRepository implements UserRepository {
  UserProfile? storedProfile;
  List<SightingReport> storedSightings = [];
  List<Ticket> storedTickets = [];
  List<PaymentReceipt> storedReceipts = [];
  List<MaintenanceReport> storedMaintenance = [];
  List<GarbageSchedule> storedSchedules = [];

  @override
  Future<UserProfile?> loadProfile() async => storedProfile;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    storedProfile = profile;
  }

  @override
  Future<void> clearProfile() async {
    storedProfile = null;
  }

  @override
  Future<List<SightingReport>> loadSightings() async => storedSightings;

  @override
  Future<void> saveSightings(List<SightingReport> reports) async {
    storedSightings = reports;
  }

  @override
  Future<List<Ticket>> loadTickets() async => storedTickets;

  @override
  Future<void> saveTickets(List<Ticket> tickets) async {
    storedTickets = tickets;
  }

  @override
  Future<List<PaymentReceipt>> loadReceipts() async => storedReceipts;

  @override
  Future<void> saveReceipts(List<PaymentReceipt> receipts) async {
    storedReceipts = receipts;
  }

  @override
  Future<List<MaintenanceReport>> loadMaintenanceReports() async =>
      storedMaintenance;

  @override
  Future<void> saveMaintenanceReports(List<MaintenanceReport> reports) async {
    storedMaintenance = reports;
  }

  @override
  Future<void> syncPending() async {}

  @override
  Future<void> incrementAlertCount() async {}

  @override
  Future<int> getCurrentAlertCount() async => 0;

  @override
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Future<void> updateLastActivity() async {}
}

void main() {
  late FakeUserRepository fakeUserRepository;
  late mock_auth.MockFirebaseAuth firebaseAuth;
  late mock_auth.MockUser fakeUser;
  late UserProvider userProvider;

  setUp(() async {
    fakeUserRepository = FakeUserRepository();
    fakeUser = mock_auth.MockUser(
      uid: 'test_uid',
      email: 'test@test.com',
      displayName: 'Test User',
    );
    firebaseAuth = mock_auth.MockFirebaseAuth(
      mockUser: fakeUser,
      signedIn: true,
    );

    final ticket = Ticket(
      id: 't1',
      plate: 'ABC123',
      amount: 50,
      reason: 'Street cleaning',
      location: 'Main St',
      issuedAt: DateTime.now().subtract(const Duration(days: 5)),
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    fakeUserRepository.storedProfile = UserProfile(
      id: fakeUser.uid,
      name: fakeUser.displayName ?? 'Test User',
      email: fakeUser.email ?? 'test@test.com',
      preferences: UserPreferences.defaults(),
      sweepingSchedules: [
        StreetSweepingSchedule(
          id: 'sweep-logic',
          zone: 'Test Zone',
          side: 'Even',
          nextSweep: DateTime.now().add(const Duration(hours: 4)),
          gpsMonitoring: true,
          advance24h: true,
          final2h: true,
          customMinutes: 30,
          alternativeParking: const ['Library Lot'],
          cleanStreakDays: 1,
          violationsPrevented: 0,
        ),
      ],
    );
    fakeUserRepository.storedTickets = [ticket];

    userProvider = UserProvider(
      userRepository: fakeUserRepository,
      auth: firebaseAuth,
      firebaseReady: true,
    );
    await userProvider.initialize();
  });

  group('UserProvider business logic', () {
    test('register reports unavailable when Firebase disabled', () async {
      final guestProvider = UserProvider(
        userRepository: fakeUserRepository,
        firebaseReady: false,
      );

      final error = await guestProvider.register(
        name: '',
        email: '',
        password: '',
      );

      expect(error, contains('unavailable'));
    });

    test('login reports unavailable when Firebase disabled', () async {
      final guestProvider = UserProvider(
        userRepository: fakeUserRepository,
        firebaseReady: false,
      );

      final error = await guestProvider.login('a@b.com', 'secret');

      expect(error, contains('unavailable'));
    });

    test('settleTicket marks ticket as paid and records receipt', () {
      final ticket = userProvider.tickets.first;

      final receipt = userProvider.settleTicket(
        ticket: ticket,
        method: 'card',
        lowIncome: true,
        firstOffense: true,
        resident: true,
      );

      expect(userProvider.tickets.first.status, isNot(TicketStatus.open));
      expect(userProvider.receipts, isNotEmpty);
      expect(receipt.reference, startsWith('TICKET-'));
      expect(fakeUserRepository.storedReceipts, isNotEmpty);
    });

    test('settlePermit stores receipt', () {
      final eligibility = userProvider.evaluatePermitEligibility(
        type: PermitType.residential,
        hasProofOfResidence: true,
        unpaidTicketCount: 0,
        isLowIncome: false,
        isSenior: false,
        ecoVehicle: false,
      );

      final receipt = userProvider.settlePermit(
        result: eligibility,
        method: 'cash',
      );

      expect(userProvider.receipts.contains(receipt), isTrue);
      expect(receipt.category, 'permit');
    });

    test('evaluatePermitEligibility enforces residency and waivers', () {
      final ineligible = userProvider.evaluatePermitEligibility(
        type: PermitType.residential,
        hasProofOfResidence: false,
        unpaidTicketCount: 0,
        isLowIncome: false,
        isSenior: false,
        ecoVehicle: false,
      );
      expect(ineligible.eligible, isFalse);
      expect(ineligible.reason, contains('Proof of residency'));

      final eligible = userProvider.evaluatePermitEligibility(
        type: PermitType.annual,
        hasProofOfResidence: true,
        unpaidTicketCount: 0,
        isLowIncome: true,
        isSenior: true,
        ecoVehicle: true,
      );
      expect(eligible.eligible, isTrue);
      expect(eligible.waiverAmount, greaterThan(0));
    });

    test(
      'evaluatePermitEligibility blocks when unpaid tickets exceed limit',
      () {
        final result = userProvider.evaluatePermitEligibility(
          type: PermitType.residential,
          hasProofOfResidence: true,
          unpaidTicketCount: 5,
          isLowIncome: false,
          isSenior: false,
          ecoVehicle: false,
        );

        expect(result.eligible, isFalse);
        expect(result.reason, contains('Resolve'));
      },
    );

    test(
      'updateAdPreferences persists to repository when profile exists',
      () async {
        const newPrefs = AdPreferences(showInsuranceAds: true);

        await userProvider.updateAdPreferences(newPrefs);

        expect(
          fakeUserRepository.storedProfile?.adPreferences.showInsuranceAds,
          isTrue,
        );
      },
    );

    test('updateSubscriptionTier updates tier even without profile', () async {
      await firebaseAuth.signOut();
      await userProvider.updateSubscriptionTier(SubscriptionTier.pro);

      expect(userProvider.tier, SubscriptionTier.pro);
    });

    test('updateCityAndTenant updates state and saves profile', () async {
      await userProvider.updateCityAndTenant(
        cityId: 'milwaukee',
        tenantId: 'citysmart',
      );

      expect(userProvider.cityId, 'milwaukee');
      expect(userProvider.tenantId, 'citysmart');
      expect(fakeUserRepository.storedProfile?.cityId, 'milwaukee');
    });

    test('updateLanguage persists to profile', () async {
      await userProvider.updateLanguage('es');

      expect(userProvider.languageCode, 'es');
      expect(fakeUserRepository.storedProfile?.languageCode, 'es');
    });

    test('setGarbageSchedules replaces schedules', () async {
      final schedules = <GarbageSchedule>[
        GarbageSchedule(
          routeId: 'g1',
          address: '123 Main',
          pickupDate: DateTime.now(),
          type: PickupType.garbage,
        ),
      ];

      await userProvider.setGarbageSchedules(schedules);

      expect(userProvider.garbageSchedules, hasLength(1));
      expect(userProvider.garbageSchedules.first.routeId, 'g1');
    });

    test('findTicket is case-insensitive', () {
      final result = userProvider.findTicket('abc123', 'T1');

      expect(result, isNotNull);
      expect(result?.id, 't1');
    });

    test('register validates required fields', () async {
      final signedOutAuth = mock_auth.MockFirebaseAuth(
        mockUser: fakeUser,
        signedIn: false,
      );
      final freshProvider = UserProvider(
        userRepository: fakeUserRepository,
        auth: signedOutAuth,
        firebaseReady: true,
      );

      final error = await freshProvider.register(
        name: '',
        email: '',
        password: '',
      );

      expect(error, contains('required'));
    });

    test(
      'towRiskIndex reflects sightings, tickets, and sweeping schedules',
      () async {
        await userProvider.reportSighting(
          type: SightingType.towTruck,
          location: 'Garage',
        );

        expect(userProvider.towRiskIndex, greaterThan(0));
      },
    );

    test('cityParkingSuggestions are derived from sweeping schedules', () {
      expect(userProvider.cityParkingSuggestions, isNotEmpty);
    });

    test('mute and unmute alerts toggle state', () {
      userProvider.muteAlerts(const Duration(hours: 1));
      expect(userProvider.alertsMutedUntil, isNotNull);

      userProvider.unmuteAlerts();
      expect(userProvider.alertsMutedUntil, isNull);
    });

    test('changePassword handles empty, disabled, and success cases', () async {
      final emptyError = await userProvider.changePassword('');
      expect(emptyError, contains('empty'));

      final guestProvider = UserProvider(
        userRepository: fakeUserRepository,
        firebaseReady: false,
      );
      final disabledError = await guestProvider.changePassword('secret123');
      expect(disabledError, contains('unavailable'));

      final result = await userProvider.changePassword('strongPassword!');
      expect(result, isNull);
    });

    test('changePassword requires a signed-in user', () async {
      final signedOutAuth = mock_auth.MockFirebaseAuth(
        mockUser: fakeUser,
        signedIn: false,
      );
      final freshProvider = UserProvider(
        userRepository: fakeUserRepository,
        auth: signedOutAuth,
        firebaseReady: true,
      );

      final error = await freshProvider.changePassword('abc12345');
      expect(error, contains('signed in'));
    });

    test('subscriptionPlan reflects tier settings', () async {
      await userProvider.updateSubscriptionTier(SubscriptionTier.pro);

      expect(userProvider.subscriptionPlan.tier, SubscriptionTier.pro);
      expect(userProvider.maxAlertRadiusMiles, greaterThan(3));
    });

    test('vehicle management updates profile vehicles', () async {
      final vehicle = Vehicle(
        id: 'v1',
        make: 'Tesla',
        model: 'Model 3',
        licensePlate: 'EV123',
        color: 'Blue',
        nickname: 'Daily',
      );

      await userProvider.addVehicle(vehicle);
      expect(userProvider.profile?.vehicles, isNotEmpty);

      final updated = vehicle.copyWith(color: 'Red');
      await userProvider.updateVehicle(updated);
      expect(userProvider.profile?.vehicles.first.color, 'Red');

      await userProvider.removeVehicle(vehicle.id);
      expect(userProvider.profile?.vehicles, isEmpty);
    });
  });
}
