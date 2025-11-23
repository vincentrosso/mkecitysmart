import 'package:flutter/foundation.dart';

import '../models/permit.dart';
import '../models/payment_receipt.dart';
import '../models/permit_eligibility.dart';
import '../models/reservation.dart';
import '../models/street_sweeping.dart';
import '../models/sighting_report.dart';
import '../models/ticket.dart';
import '../models/user_preferences.dart';
import '../models/user_profile.dart';
import '../models/vehicle.dart';
import '../services/user_repository.dart';
import '../data/sample_tickets.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({required UserRepository userRepository})
    : _repository = userRepository;

  final UserRepository _repository;

  UserProfile? _profile;
  bool _initializing = true;
  bool _guestMode = false;
  List<Permit> _guestPermits = const [];
  List<Reservation> _guestReservations = const [];
  List<StreetSweepingSchedule> _guestSweepingSchedules = const [];
  List<Ticket> _tickets = const [];
  List<SightingReport> _sightings = const [];

  bool get isInitializing => _initializing;
  bool get isLoggedIn => _profile != null;
  bool get isGuest => _guestMode;
  UserProfile? get profile => _profile;
  List<Permit> get permits => _profile?.permits ?? _guestPermits;
  List<Reservation> get reservations =>
      _profile?.reservations ?? _guestReservations;
  List<StreetSweepingSchedule> get sweepingSchedules =>
      _profile?.sweepingSchedules ?? _guestSweepingSchedules;
  List<Ticket> get tickets => _tickets;
  List<SightingReport> get sightings => _sightings;
  List<String> get cityParkingSuggestions {
    final set = <String>{};
    for (final schedule in sweepingSchedules) {
      set.addAll(schedule.alternativeParking);
    }
    return set.toList();
  }

  Future<void> initialize() async {
    _profile = await _repository.loadProfile();
    _tickets = List<Ticket>.from(sampleTickets);
    _sightings = await _repository.loadSightings();
    _initializing = false;
    _guestMode = false;
    _guestPermits = const [];
    _guestReservations = const [];
    _guestSweepingSchedules = const [];
    notifyListeners();
  }

  void continueAsGuest() {
    _guestMode = true;
    _profile = null;
    _guestPermits = _seedPermits();
    _guestReservations = _seedReservations();
    _guestSweepingSchedules = _seedSweepingSchedules();
    notifyListeners();
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (_profile != null) {
      return 'An account is already signed in on this device.';
    }
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return 'All fields are required.';
    }

    final newProfile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password,
      phone: phone,
      preferences: UserPreferences.defaults(),
      vehicles: const [],
      permits: _seedPermits(ownerHint: name),
      reservations: _seedReservations(ownerHint: name),
      sweepingSchedules: _seedSweepingSchedules(ownerHint: name),
    );
    await _repository.saveProfile(newProfile);
    _profile = newProfile;
    _guestMode = false;
    notifyListeners();
    return null;
  }

  Future<String?> login(String email, String password) async {
    final stored = await _repository.loadProfile();
    if (stored == null) {
      return 'No account found on this device.';
    }
    if (stored.email.trim().toLowerCase() != email.trim().toLowerCase() ||
        stored.password != password) {
      return 'Invalid email or password.';
    }
    _profile = stored;
    _guestMode = false;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _profile = null;
    _guestMode = false;
    _guestPermits = const [];
    _guestReservations = const [];
    _guestSweepingSchedules = const [];
    _tickets = const [];
    _sightings = const [];
    await _repository.clearProfile();
    await _repository.saveSightings(const []);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(
      name: name ?? _profile!.name,
      email: email ?? _profile!.email,
      phone: phone ?? _profile!.phone,
      address: address ?? _profile!.address,
    );
    _profile = updated;
    await _repository.saveProfile(updated);
    notifyListeners();
  }

  Future<void> reportSighting({
    required SightingType type,
    required String location,
    String notes = '',
    double? latitude,
    double? longitude,
  }) async {
    final report = SightingReport(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      location: location,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
      reportedAt: DateTime.now(),
    );
    _sightings = [report, ..._sightings];
    await _repository.saveSightings(_sightings);
    notifyListeners();
  }

  PermitEligibilityResult evaluatePermitEligibility({
    required PermitType type,
    required bool hasProofOfResidence,
    required int unpaidTicketCount,
    required bool isLowIncome,
    required bool isSenior,
    required bool ecoVehicle,
  }) {
    final baseFees = {
      PermitType.residential: 45.0,
      PermitType.visitor: 20.0,
      PermitType.business: 120.0,
      PermitType.handicap: 0.0,
      PermitType.monthly: 90.0,
      PermitType.annual: 250.0,
      PermitType.temporary: 35.0,
    };
    final base = baseFees[type] ?? 50.0;
    final surcharge = (unpaidTicketCount * 12).toDouble();

    if (!hasProofOfResidence) {
      return PermitEligibilityResult(
        permitType: type,
        eligible: false,
        reason: 'Proof of residency required.',
        baseFee: base,
        surcharges: surcharge,
        waiverAmount: 0,
        totalDue: 0,
        notes: ['Upload ID or utility bill to continue.'],
      );
    }
    if (unpaidTicketCount > 3) {
      return PermitEligibilityResult(
        permitType: type,
        eligible: false,
        reason: 'Resolve outstanding tickets before applying.',
        baseFee: base,
        surcharges: surcharge,
        waiverAmount: 0,
        totalDue: 0,
        notes: ['Unpaid tickets: $unpaidTicketCount'],
      );
    }

    final beforeWaiver = base + surcharge;
    double waiverPct = 0;
    final notes = <String>[];
    if (isLowIncome) {
      waiverPct += 0.4;
      notes.add('Low-income waiver applied (-40%).');
    }
    if (ecoVehicle) {
      waiverPct += 0.15;
      notes.add('EV/Hybrid discount applied (-15%).');
    }
    if (isSenior) {
      waiverPct += 0.1;
      notes.add('Senior discount applied (-10%).');
    }
    waiverPct = waiverPct.clamp(0, 0.6);
    final waiverAmount = beforeWaiver * waiverPct;
    final total =
        (beforeWaiver - waiverAmount).clamp(0, double.infinity).toDouble();

    return PermitEligibilityResult(
      permitType: type,
      eligible: true,
      reason: 'Eligible for issuance',
      baseFee: base,
      surcharges: surcharge,
      waiverAmount: waiverAmount,
      totalDue: total,
      notes: notes,
    );
  }

  PaymentReceipt settlePermit({
    required PermitEligibilityResult result,
    required String method,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return PaymentReceipt(
      id: id,
      amountCharged: result.totalDue,
      method: method,
      reference: 'PERMIT-$id',
      createdAt: DateTime.now(),
      waivedAmount: result.waiverAmount,
      description: 'Permit settlement for ${result.permitType.name}',
    );
  }

  Ticket? findTicket(String plate, String ticketId) {
    try {
      return _tickets.firstWhere(
        (ticket) =>
            ticket.plate.toUpperCase() == plate.toUpperCase() &&
            ticket.id.toUpperCase() == ticketId.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  PaymentReceipt settleTicket({
    required Ticket ticket,
    required String method,
    required bool lowIncome,
    required bool firstOffense,
    required bool resident,
  }) {
    final overduePenalty = ticket.isOverdue ? 15.0 : 0.0;
    final base = ticket.amount + overduePenalty;
    double waiverPct = 0;
    final waiverNotes = <String>[];
    if (lowIncome) {
      waiverPct += 0.35;
      waiverNotes.add('Low-income relief (-35%)');
    }
    if (firstOffense) {
      waiverPct += 0.25;
      waiverNotes.add('First-offense forgiveness (-25%)');
    }
    if (resident) {
      waiverPct += 0.1;
      waiverNotes.add('Resident discount (-10%)');
    }
    waiverPct = waiverPct.clamp(0, 0.6);
    final waiverAmount = base * waiverPct;
    final totalDue =
        (base - waiverAmount).clamp(0, double.infinity).toDouble();

    final updated = ticket.copyWith(
      status: totalDue == 0 ? TicketStatus.waived : TicketStatus.paid,
      paidAt: DateTime.now(),
      waiverReason: waiverNotes.join('; '),
      paymentMethod: method,
    );
    _tickets = _tickets
        .map((t) => t.id == ticket.id ? updated : t)
        .toList();
    notifyListeners();

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return PaymentReceipt(
      id: id,
      amountCharged: totalDue,
      waivedAmount: waiverAmount,
      method: method,
      reference: 'TICKET-$id',
      createdAt: DateTime.now(),
      description: 'Settlement for ${ticket.id}',
    );
  }

  Future<void> changePassword(String password) async {
    if (_profile == null || password.isEmpty) return;
    _profile = _profile!.copyWith(password: password);
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    if (_profile == null) return;
    final currentVehicles = List<Vehicle>.from(_profile!.vehicles)
      ..add(vehicle);
    final prefs = _profile!.preferences.defaultVehicleId == null
        ? _profile!.preferences.copyWith(defaultVehicleId: vehicle.id)
        : _profile!.preferences;
    _profile = _profile!.copyWith(
      vehicles: currentVehicles,
      preferences: prefs,
    );
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    if (_profile == null) return;
    final updatedVehicles = _profile!.vehicles
        .map((existing) => existing.id == vehicle.id ? vehicle : existing)
        .toList();
    _profile = _profile!.copyWith(vehicles: updatedVehicles);
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> removeVehicle(String vehicleId) async {
    if (_profile == null) return;
    final updatedVehicles = _profile!.vehicles
        .where((vehicle) => vehicle.id != vehicleId)
        .toList();
    var preferences = _profile!.preferences;
    if (preferences.defaultVehicleId == vehicleId) {
      preferences = preferences.copyWith(
        defaultVehicleId: updatedVehicles.isEmpty
            ? null
            : updatedVehicles.first.id,
      );
    }
    _profile = _profile!.copyWith(
      vehicles: updatedVehicles,
      preferences: preferences,
    );
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> updatePreferences({
    bool? parkingNotifications,
    bool? towAlerts,
    bool? reminderNotifications,
    String? defaultVehicleId,
  }) async {
    if (_profile == null) return;
    final prefs = _profile!.preferences.copyWith(
      parkingNotifications: parkingNotifications,
      towAlerts: towAlerts,
      reminderNotifications: reminderNotifications,
      defaultVehicleId: defaultVehicleId,
    );
    _profile = _profile!.copyWith(preferences: prefs);
    await _repository.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> addPermit(Permit permit) async {
    final updated = List<Permit>.from(permits)..add(permit);
    await _updatePermitList(updated);
  }

  Future<void> renewPermit(String permitId) async {
    await _mutatePermit(permitId, (permit) {
      final now = DateTime.now();
      final start = permit.endDate.isAfter(now) ? permit.endDate : now;
      return permit.copyWith(
        status: PermitStatus.active,
        startDate: start,
        endDate: start.add(_permitDuration(permit.type)),
      );
    });
  }

  Future<void> updatePermitStatus(String permitId, PermitStatus status) async {
    await _mutatePermit(permitId, (permit) => permit.copyWith(status: status));
  }

  Future<void> toggleOfflineAccess(String permitId) async {
    await _mutatePermit(
      permitId,
      (permit) => permit.copyWith(offlineAccess: !permit.offlineAccess),
    );
  }

  Future<void> updatePermitVehicles(
    String permitId,
    List<String> vehicleIds,
  ) async {
    await _mutatePermit(
      permitId,
      (permit) => permit.copyWith(vehicleIds: vehicleIds),
    );
  }

  Future<void> updateAutoRenew(String permitId, bool enabled) async {
    await _mutatePermit(
      permitId,
      (permit) => permit.copyWith(autoRenew: enabled),
    );
  }

  Future<void> createReservation(Reservation reservation) async {
    final updated = List<Reservation>.from(reservations)..add(reservation);
    await _saveReservations(updated);
  }

  Future<void> updateReservationStatus(
    String reservationId,
    ReservationStatus status,
  ) async {
    await _mutateReservation(
      reservationId,
      (reservation) => reservation.copyWith(status: status),
    );
  }

  Future<void> recordPayment({
    required String reservationId,
    required String paymentMethod,
    required double amount,
    required String transactionId,
  }) async {
    await _mutateReservation(
      reservationId,
      (reservation) => reservation.copyWith(
        paymentMethod: paymentMethod,
        totalPaid: amount,
        transactionId: transactionId,
        status: ReservationStatus.completed,
      ),
    );
  }

  Future<void> updateSweepingNotifications(
    String id, {
    bool? gpsMonitoring,
    bool? advance24h,
    bool? final2h,
    int? customMinutes,
  }) async {
    await _mutateSweeping(
      id,
      (schedule) => schedule.copyWith(
        gpsMonitoring: gpsMonitoring,
        advance24h: advance24h,
        final2h: final2h,
        customMinutes: customMinutes,
      ),
    );
  }

  Future<void> logVehicleMoved(String id) async {
    await _mutateSweeping(
      id,
      (schedule) => schedule.copyWith(
        cleanStreakDays: schedule.cleanStreakDays + 1,
        violationsPrevented: schedule.violationsPrevented + 1,
      ),
    );
  }

  Duration _permitDuration(PermitType type) {
    switch (type) {
      case PermitType.residential:
      case PermitType.visitor:
      case PermitType.business:
      case PermitType.handicap:
      case PermitType.monthly:
        return const Duration(days: 30);
      case PermitType.annual:
        return const Duration(days: 365);
      case PermitType.temporary:
        return const Duration(days: 7);
    }
  }

  Future<void> _mutatePermit(
    String permitId,
    Permit Function(Permit permit) transform,
  ) async {
    final updated = permits
        .map((permit) => permit.id == permitId ? transform(permit) : permit)
        .toList();
    await _updatePermitList(updated);
  }

  Future<void> _updatePermitList(List<Permit> updated) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(permits: updated);
      await _repository.saveProfile(_profile!);
    } else {
      _guestPermits = updated;
    }
    notifyListeners();
  }

  Future<void> _mutateReservation(
    String reservationId,
    Reservation Function(Reservation reservation) transform,
  ) async {
    final updated = reservations
        .map(
          (reservation) => reservation.id == reservationId
              ? transform(reservation)
              : reservation,
        )
        .toList();
    await _saveReservations(updated);
  }

  Future<void> _saveReservations(List<Reservation> updated) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(reservations: updated);
      await _repository.saveProfile(_profile!);
    } else {
      _guestReservations = updated;
    }
    notifyListeners();
  }

  Future<void> _mutateSweeping(
    String id,
    StreetSweepingSchedule Function(StreetSweepingSchedule schedule) transform,
  ) async {
    final updated = sweepingSchedules
        .map((schedule) => schedule.id == id ? transform(schedule) : schedule)
        .toList();
    if (_profile != null) {
      _profile = _profile!.copyWith(sweepingSchedules: updated);
      await _repository.saveProfile(_profile!);
    } else {
      _guestSweepingSchedules = updated;
    }
    notifyListeners();
  }

  List<Permit> _seedPermits({String? ownerHint}) {
    final now = DateTime.now();
    final baseName = ownerHint ?? 'Guest';
    return [
      Permit(
        id: 'permit-res',
        type: PermitType.residential,
        status: PermitStatus.active,
        zone: 'Zone 3 - North Riverwest',
        startDate: now.subtract(const Duration(days: 40)),
        endDate: now.add(const Duration(days: 20)),
        vehicleIds: ['MKE-5123', 'EV-2108'],
        qrCodeData: 'RES-$baseName-${now.year}',
        offlineAccess: true,
        autoRenew: true,
      ),
      Permit(
        id: 'permit-visitor',
        type: PermitType.visitor,
        status: PermitStatus.active,
        zone: 'Zone 1 - Historic Third Ward',
        startDate: now,
        endDate: now.add(const Duration(days: 6)),
        vehicleIds: ['VIS-LOANER'],
        qrCodeData: 'VISITOR-$baseName-${now.millisecondsSinceEpoch}',
        offlineAccess: false,
      ),
      Permit(
        id: 'permit-business',
        type: PermitType.business,
        status: PermitStatus.expired,
        zone: 'Zone 6 - Harbor District',
        startDate: now.subtract(const Duration(days: 430)),
        endDate: now.subtract(const Duration(days: 60)),
        vehicleIds: ['FLEET-42'],
        qrCodeData: 'BIZ-$baseName',
        offlineAccess: true,
      ),
      Permit(
        id: 'permit-handicap',
        type: PermitType.handicap,
        status: PermitStatus.inactive,
        zone: 'Citywide',
        startDate: now,
        endDate: now.add(const Duration(days: 365)),
        vehicleIds: ['ACCESS-01'],
        qrCodeData: 'ADA-$baseName',
        offlineAccess: true,
      ),
    ];
  }

  List<Reservation> _seedReservations({String? ownerHint}) {
    final now = DateTime.now();
    final baseName = ownerHint ?? 'Guest';
    return [
      Reservation(
        id: 'res-001',
        spotId: 'EV-18',
        location: '3rd Ward Garage',
        status: ReservationStatus.reserved,
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 3)),
        ratePerHour: 2.5,
        vehiclePlate: 'MKE-5123',
        paymentMethod: 'Apple Pay',
        transactionId: 'txn-${DateTime.now().millisecondsSinceEpoch}',
        totalPaid: 0,
      ),
      Reservation(
        id: 'res-002',
        spotId: 'OUT-09',
        location: 'East Side Meter 221',
        status: ReservationStatus.completed,
        startTime: now.subtract(const Duration(days: 1, hours: 3)),
        endTime: now.subtract(const Duration(days: 1, hours: 1)),
        ratePerHour: 1.5,
        vehiclePlate: 'EV-2108',
        paymentMethod: 'Visa **** 8211',
        transactionId: 'txn-${baseName.toUpperCase()}-002',
        totalPaid: 3.0,
      ),
    ];
  }

  List<StreetSweepingSchedule> _seedSweepingSchedules({String? ownerHint}) {
    final now = DateTime.now();
    return [
      StreetSweepingSchedule(
        id: 'sweep-1',
        zone: 'Riverwest Sector A',
        side: 'Odd side',
        nextSweep: now.add(const Duration(days: 3, hours: 5)),
        gpsMonitoring: true,
        advance24h: true,
        final2h: true,
        customMinutes: 90,
        alternativeParking: const [
          'Booth St lot – 0.2 mi',
          'Holton & Center ramp',
        ],
        cleanStreakDays: 21,
        violationsPrevented: 4,
      ),
      StreetSweepingSchedule(
        id: 'sweep-2',
        zone: 'Downtown East',
        side: 'Even side',
        nextSweep: now.add(const Duration(days: 5, hours: 2)),
        gpsMonitoring: false,
        advance24h: true,
        final2h: true,
        customMinutes: 60,
        alternativeParking: const ['Market St garage', 'Broadway public lot'],
        cleanStreakDays: 12,
        violationsPrevented: 2,
      ),
    ];
  }
}
