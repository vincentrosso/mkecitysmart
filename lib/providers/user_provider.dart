import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/permit.dart';
import '../models/payment_receipt.dart';
import '../models/permit_eligibility.dart';
import '../models/reservation.dart';
import '../models/street_sweeping.dart';
import '../models/sighting_report.dart';
import '../models/ticket.dart';
import '../models/ad_preferences.dart';
import '../models/subscription_plan.dart';
import '../models/user_preferences.dart';
import '../models/user_profile.dart';
import '../models/vehicle.dart';
import '../models/maintenance_report.dart';
import '../models/garbage_schedule.dart';
import '../models/city_rule_pack.dart';
import '../services/ticket_api_service.dart';
import '../services/user_repository.dart';
import '../data/sample_tickets.dart';
import '../services/report_api_service.dart';
import '../services/api_client.dart';
import '../data/sample_schedules.dart';
import '../services/notification_service.dart';
import '../data/city_rule_packs.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({required UserRepository userRepository})
    : _repository = userRepository;

  final UserRepository _repository;
  final ReportApiService _reportApi = ReportApiService(ApiClient());

  UserProfile? _profile;
  bool _initializing = true;
  bool _guestMode = false;
  List<Permit> _guestPermits = const [];
  List<Reservation> _guestReservations = const [];
  List<StreetSweepingSchedule> _guestSweepingSchedules = const [];
  List<Ticket> _tickets = const [];
  List<SightingReport> _sightings = const [];
  List<PaymentReceipt> _receipts = const [];
  AdPreferences _adPreferences = const AdPreferences();
  SubscriptionTier _tier = SubscriptionTier.free;
  List<MaintenanceReport> _maintenanceReports = const [];
  List<GarbageSchedule> _garbageSchedules = const [];
  CityRulePack _rulePack = defaultRulePack;
  String _cityId = 'default';
  String _tenantId = 'default';
  String _languageCode = 'en';

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
  List<PaymentReceipt> get receipts => _receipts;
  AdPreferences get adPreferences =>
      _profile?.adPreferences ?? _adPreferences;
  SubscriptionTier get tier => _profile?.tier ?? _tier;
  SubscriptionPlan get subscriptionPlan => _planForTier(tier);
  double get maxAlertRadiusMiles => subscriptionPlan.maxAlertRadiusMiles;
  int get maxAlertsPerDay => subscriptionPlan.alertVolumePerDay;
  double get planFeeWaiverCap => subscriptionPlan.feeWaiverPct;
  bool get prioritySupport => subscriptionPlan.prioritySupport;
  List<MaintenanceReport> get maintenanceReports => _maintenanceReports;
  List<GarbageSchedule> get garbageSchedules => _garbageSchedules;
  CityRulePack get rulePack => _profile?.rulePack ?? _rulePack;
  String get cityId => _profile?.cityId ?? _cityId;
  String get tenantId => _profile?.tenantId ?? _tenantId;
  String get languageCode => _profile?.languageCode ?? _languageCode;

  /// Computes a rough risk score (0–100) based on recent enforcement sightings,
  /// expiring permits, overdue tickets, and impending street sweeping.
  int get towRiskIndex {
    var score = 0.0;
    // Recent sightings in last 24h boost risk.
    final now = DateTime.now();
    final recentSightings = _sightings.where(
      (s) => now.difference(s.reportedAt).inHours <= 24,
    );
    for (final s in recentSightings) {
      score += s.occurrences * 5;
      if (s.type == SightingType.towTruck) {
        score += 10;
      }
    }
    // Overdue tickets increase risk.
    final overdueTickets =
        _tickets.where((t) => t.isOverdue && t.status == TicketStatus.open);
    score += overdueTickets.length * 8;
    // Expiring permits (<7 days) increase risk.
    final expiringPermits =
        permits.where((p) => p.endDate.difference(now).inDays <= 7);
    score += expiringPermits.length * 6;
    // Upcoming street sweeping within 48h increases risk.
    final sweepingSoon = sweepingSchedules.where(
      (s) => s.nextSweep.difference(now).inHours <= 48,
    );
    score += sweepingSoon.length * 12;
    return score.clamp(0, 100).toInt();
  }
  List<String> get cityParkingSuggestions {
    final set = <String>{};
    for (final schedule in sweepingSchedules) {
      set.addAll(schedule.alternativeParking);
    }
    return set.toList();
  }

  Future<void> initialize() async {
    _profile = await _repository.loadProfile();
    final storedTickets = await _repository.loadTickets();
    _receipts = await _repository.loadReceipts();
    _adPreferences = _profile?.adPreferences ?? _adPreferences;
    _tier = _profile?.tier ?? _tier;
    _maintenanceReports = await _repository.loadMaintenanceReports();
    _garbageSchedules = sampleSchedules(
      _profile?.address ?? '1234 E Sample St',
    );
    _rulePack = _profile?.rulePack ?? rulePackFor(cityId);
    _cityId = _profile?.cityId ?? _cityId;
    _tenantId = _profile?.tenantId ?? _tenantId;
    _languageCode = _profile?.languageCode ?? _languageCode;
    _tickets = storedTickets.isNotEmpty
        ? storedTickets
        : List<Ticket>.from(sampleTickets);
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
    _adPreferences = const AdPreferences();
    _tier = SubscriptionTier.free;
    _receipts = const [];
    _maintenanceReports = const [];
    _garbageSchedules = const [];
    _rulePack = defaultRulePack;
    _cityId = 'default';
    _tenantId = 'default';
    _languageCode = 'en';
    await _repository.clearProfile();
    await _repository.saveSightings(const []);
    await _repository.saveTickets(const []);
    await _repository.saveReceipts(const []);
    await _repository.saveMaintenanceReports(const []);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    AdPreferences? adPreferences,
    SubscriptionTier? tier,
    String? cityId,
    String? tenantId,
    String? languageCode,
    CityRulePack? rulePack,
  }) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(
      name: name ?? _profile!.name,
      email: email ?? _profile!.email,
      phone: phone ?? _profile!.phone,
      address: address ?? _profile!.address,
      adPreferences: adPreferences ?? _profile!.adPreferences,
      tier: tier ?? _profile!.tier,
      cityId: cityId ?? _profile!.cityId,
      tenantId: tenantId ?? _profile!.tenantId,
      languageCode: languageCode ?? _profile!.languageCode,
      rulePack: rulePack ?? _profile!.rulePack,
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
    final deduped = _dedupeSighting(report);
    _sightings = deduped;
    await _repository.saveSightings(_sightings);
    _reportApi.sendSighting(report);
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
    final planCap = planFeeWaiverCap;
    waiverPct = waiverPct.clamp(0, planCap > 0 ? planCap : 0.6);
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
    final receipt = PaymentReceipt(
      id: id,
      amountCharged: result.totalDue,
      method: method,
      reference: 'PERMIT-$id',
      createdAt: DateTime.now(),
      waivedAmount: result.waiverAmount,
      description: 'Permit settlement for ${result.permitType.name}',
      category: 'permit',
    );
    _receipts = [receipt, ..._receipts];
    _persistReceipts();
    return receipt;
  }

  Future<void> updateAdPreferences(AdPreferences prefs) async {
    _adPreferences = prefs;
    if (_profile != null) {
      _profile = _profile!.copyWith(adPreferences: prefs);
      await _repository.saveProfile(_profile!);
    }
    notifyListeners();
  }

  Future<void> updateSubscriptionTier(SubscriptionTier tier) async {
    _tier = tier;
    if (_profile != null) {
      _profile = _profile!.copyWith(tier: tier);
      await _repository.saveProfile(_profile!);
    }
    notifyListeners();
  }

  Future<void> updateCityAndTenant({
    required String cityId,
    required String tenantId,
  }) async {
    _cityId = cityId;
    _tenantId = tenantId;
    _rulePack = rulePackFor(cityId);
    if (_profile != null) {
      _profile = _profile!.copyWith(
        cityId: cityId,
        tenantId: tenantId,
        rulePack: _rulePack,
      );
      await _repository.saveProfile(_profile!);
    }
    notifyListeners();
  }

  Future<void> updateLanguage(String languageCode) async {
    _languageCode = languageCode;
    if (_profile != null) {
      _profile = _profile!.copyWith(languageCode: languageCode);
      await _repository.saveProfile(_profile!);
    }
    notifyListeners();
  }

  Future<void> _persistTickets() async {
    await _repository.saveTickets(_tickets);
  }

  Future<void> _persistReceipts() async {
    await _repository.saveReceipts(_receipts);
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
    final planCap = planFeeWaiverCap;
    waiverPct = waiverPct.clamp(0, planCap > 0 ? planCap : 0.6);
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
    _persistTickets();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final receipt = PaymentReceipt(
      id: id,
      amountCharged: totalDue,
      waivedAmount: waiverAmount,
      method: method,
      reference: 'TICKET-$id',
      createdAt: DateTime.now(),
      description: 'Settlement for ${ticket.id}',
      category: 'ticket',
    );
    _receipts = [receipt, ..._receipts];
    _persistReceipts();
    notifyListeners();

    return receipt;
  }

  Future<void> syncTicketsWithBackend() async {
    final api = TicketApiService();
    final remote = await api.fetchTickets();
    _tickets = remote;
    await api.syncTickets(_tickets);
    await _persistTickets();
    notifyListeners();
  }

  Future<MaintenanceReport> submitMaintenanceReport({
    required MaintenanceCategory category,
    required String description,
    required String location,
    double? latitude,
    double? longitude,
    String? photoPath,
  }) async {
    final department = _routeDepartment(category, location);
    final report = MaintenanceReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: category,
      description: description,
      location: location,
      latitude: latitude,
      longitude: longitude,
      photoPath: photoPath,
      department: department,
      status: 'Submitted',
      createdAt: DateTime.now(),
    );
    _maintenanceReports = [report, ..._maintenanceReports];
    await _repository.saveMaintenanceReports(_maintenanceReports);
    _reportApi.sendMaintenance(report);
    notifyListeners();
    return report;
  }

  String _routeDepartment(MaintenanceCategory category, String location) {
    switch (category) {
      case MaintenanceCategory.pothole:
      case MaintenanceCategory.snow:
        return 'Streets & Sanitation';
      case MaintenanceCategory.streetlight:
        return 'Electrical Services';
      case MaintenanceCategory.signage:
        return 'Traffic Engineering';
      case MaintenanceCategory.graffiti:
        return 'Neighborhood Services';
      case MaintenanceCategory.trash:
        return 'Sanitation';
      case MaintenanceCategory.tree:
        return 'Forestry';
      case MaintenanceCategory.water:
        return 'Water Works';
    }
  }

  Future<void> scheduleGarbageReminders({
    Duration nightBefore = const Duration(hours: 12),
    Duration morningOf = const Duration(hours: 2),
    String languageCode = 'en',
  }) async {
    final now = DateTime.now();
    final upcoming = _garbageSchedules.where((g) => g.pickupDate.isAfter(now));
    for (final sched in upcoming) {
      final before = sched.pickupDate.subtract(nightBefore);
      final morning = sched.pickupDate.subtract(morningOf);
      final typeLabel = _pickupLabel(sched.type, languageCode);
      final address = sched.address;
      if (before.isAfter(now)) {
        await NotificationService.instance.scheduleLocal(
          title: _translate('Reminder', languageCode),
          body: '$typeLabel pickup soon near $address',
          when: before,
        );
      }
      if (morning.isAfter(now)) {
        await NotificationService.instance.scheduleLocal(
          title: _translate('Reminder', languageCode),
          body: '$typeLabel pickup today near $address',
          when: morning,
        );
      }
    }
  }

  String _pickupLabel(PickupType type, String lang) {
    final map = {
      'en': {
        PickupType.garbage: 'Garbage',
        PickupType.recycling: 'Recycling',
      },
      'fr': {
        PickupType.garbage: 'Ordures',
        PickupType.recycling: 'Recyclage',
      },
      'zh': {
        PickupType.garbage: '垃圾',
        PickupType.recycling: '回收',
      },
      'hi': {
        PickupType.garbage: 'कचरा',
        PickupType.recycling: 'रीसाइक्लिंग',
      },
      'el': {
        PickupType.garbage: 'Σκουπίδια',
        PickupType.recycling: 'Ανακύκλωση',
      },
    };
    return map[lang]?[type] ?? map['en']![type]!;
  }

  String _translate(String text, String lang) {
    final dict = {
      'Reminder': {
        'en': 'Reminder',
        'fr': 'Rappel',
        'zh': '提醒',
        'hi': 'स्मरण',
        'el': 'Υπενθύμιση',
      },
    };
    final translations = dict[text];
    if (translations == null) return text;
    return translations[lang] ?? translations['en'] ?? text;
  }

  List<SightingReport> _dedupeSighting(SightingReport incoming) {
    if (incoming.latitude == null || incoming.longitude == null) {
      return [incoming, ..._sightings];
    }
    final updated = <SightingReport>[];
    bool merged = false;
    for (final existing in _sightings) {
      if (existing.type == incoming.type &&
          existing.latitude != null &&
          existing.longitude != null &&
          _distanceMeters(
                existing.latitude!,
                existing.longitude!,
                incoming.latitude!,
                incoming.longitude!,
              ) <
              150 &&
          incoming.reportedAt.difference(existing.reportedAt).inMinutes.abs() <
              15) {
        merged = true;
        updated.add(
          SightingReport(
            id: existing.id,
            type: existing.type,
            location: incoming.location.isNotEmpty
                ? incoming.location
                : existing.location,
            latitude: existing.latitude,
            longitude: existing.longitude,
            notes: existing.notes.isNotEmpty ? existing.notes : incoming.notes,
            reportedAt: incoming.reportedAt.isAfter(existing.reportedAt)
                ? incoming.reportedAt
                : existing.reportedAt,
            occurrences: existing.occurrences + 1,
          ),
        );
      } else {
        updated.add(existing);
      }
    }
    if (!merged) {
      updated.insert(0, incoming);
    }
    return updated;
  }

  double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000; // meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  SubscriptionPlan _planForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return const SubscriptionPlan(
          tier: SubscriptionTier.free,
          maxAlertRadiusMiles: 3,
          alertVolumePerDay: 3,
          feeWaiverPct: 0,
          prioritySupport: false,
          monthlyPrice: 0,
        );
      case SubscriptionTier.plus:
        return const SubscriptionPlan(
          tier: SubscriptionTier.plus,
          maxAlertRadiusMiles: 8,
          alertVolumePerDay: 10,
          feeWaiverPct: 0.15,
          prioritySupport: false,
          monthlyPrice: 6.99,
        );
      case SubscriptionTier.pro:
        return const SubscriptionPlan(
          tier: SubscriptionTier.pro,
          maxAlertRadiusMiles: 15,
          alertVolumePerDay: 25,
          feeWaiverPct: 0.35,
          prioritySupport: true,
          monthlyPrice: 14.99,
        );
    }
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
    int? geoRadiusMiles,
    bool? ticketRiskAlerts,
  }) async {
    if (_profile == null) return;
    final prefs = _profile!.preferences.copyWith(
      parkingNotifications: parkingNotifications,
      towAlerts: towAlerts,
      reminderNotifications: reminderNotifications,
      defaultVehicleId: defaultVehicleId,
      geoRadiusMiles: geoRadiusMiles,
      ticketRiskAlerts: ticketRiskAlerts,
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
