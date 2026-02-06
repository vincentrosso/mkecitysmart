import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/local/local_database.dart'
    if (dart.library.html) '../data/local/local_database_stub.dart';
import '../models/sighting_report.dart';
import '../models/payment_receipt.dart';
import '../models/ticket.dart';
import '../models/user_profile.dart';
import '../models/maintenance_report.dart';

class UserRepository {
  UserRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    LocalDatabase? localDatabase,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _localDb = localDatabase ?? LocalDatabase();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalDatabase _localDb;

  String? get _activeUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _userCollection() {
    return _firestore.collection('users');
  }

  DocumentReference<Map<String, dynamic>> _userDocument() {
    final userId = _activeUserId;
    if (userId == null) {
      throw StateError('No active user is signed in.');
    }
    return _userCollection().doc(userId);
  }

  Future<UserProfile?> loadProfile() async {
    final userId = _activeUserId;
    if (userId == null) return null;

    // 1) Local first for offline experience.
    UserProfile? localProfile = await _localDb.fetchProfile(userId);

    // 2) Try to refresh from Firestore; update local cache if it succeeds.
    try {
      final doc = await _userDocument().get();
      if (doc.exists) {
        final remote = UserProfile.fromJson(doc.data()!);
        await _localDb.upsertProfile(remote);
        localProfile = remote;
      }
    } catch (_) {
      // Ignore remote failures; fall back to local data.
    }

    return localProfile;
  }

  Future<void> saveProfile(UserProfile profile) async {
    // Persist locally first (offline-first).
    await _localDb.upsertProfile(profile);

    try {
      await _userDocument().set(profile.toJson());
      await _localDb.removePending('profile_upsert_${profile.id}');
    } catch (_) {
      // If offline or Firestore write fails, queue for later.
      await _localDb.enqueueProfileSync(profile);
    }
  }

  Future<void> clearProfile() async {
    if (_activeUserId != null) {
      await _localDb.clearProfile(_activeUserId!);
    }
    await _userDocument().delete();
  }

  Future<List<T>> _loadSubCollection<T>({
    required String collectionName,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    if (_activeUserId == null) return [];
    try {
      final snapshot = await _userDocument().collection(collectionName).get();
      return snapshot.docs.map((doc) => fromJson(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveSubCollection<T>({
    required String collectionName,
    required List<T> items,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    if (_activeUserId == null) return;
    final batch = _firestore.batch();
    final collectionRef = _userDocument().collection(collectionName);

    // Clear existing documents in the subcollection
    final snapshot = await collectionRef.get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    // Add new documents
    for (final item in items) {
      batch.set(collectionRef.doc(), toJson(item));
    }

    await batch.commit();
  }

  Future<List<SightingReport>> loadSightings() => _loadSubCollection(
    collectionName: 'sightings',
    fromJson: SightingReport.fromJson,
  );

  Future<void> saveSightings(List<SightingReport> reports) async {
    if (_activeUserId == null) return;
    final batch = _firestore.batch();
    final collectionRef = _userDocument().collection('sightings');

    final snapshot = await collectionRef.get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    for (final report in reports) {
      final data = {
        ...report.toJson(),
        'reporterId': _activeUserId,
        'timestamp': FieldValue.serverTimestamp(),
        // Per-sighting counter baseline for global queries
        'reportCount': 0,
      };
      batch.set(collectionRef.doc(), data);
    }

    await batch.commit();

    // Ensure the parent user document has a reports counter field and
    // increment the reportCount. This helps quickly show counts without
    // querying the subcollection.
    try {
      // Ensure a baseline field exists (no-op if already present).
      await _userDocument().set({'reports': 0}, SetOptions(merge: true));

      // Try to increment the reportCount by the number of reports added.
      await _userDocument().update({
        'reportCount': FieldValue.increment(reports.length),
      });
    } catch (e) {
      // If update fails (for example the document didn't exist concurrently),
      // try to set the count explicitly as a fallback.
      try {
        await _userDocument().set({
          'reportCount': reports.length,
        }, SetOptions(merge: true));
      } catch (_) {
        // Swallow — this counter is a convenience and should not prevent app flow.
      }
    }
  }

  Future<List<Ticket>> loadTickets() =>
      _loadSubCollection(collectionName: 'tickets', fromJson: Ticket.fromJson);

  Future<void> saveTickets(List<Ticket> tickets) => _saveSubCollection(
    collectionName: 'tickets',
    items: tickets,
    toJson: (t) => t.toJson(),
  );

  Future<List<PaymentReceipt>> loadReceipts() => _loadSubCollection(
    collectionName: 'receipts',
    fromJson: PaymentReceipt.fromJson,
  );

  Future<void> saveReceipts(List<PaymentReceipt> receipts) =>
      _saveSubCollection(
        collectionName: 'receipts',
        items: receipts,
        toJson: (r) => r.toJson(),
      );

  Future<List<MaintenanceReport>> loadMaintenanceReports() =>
      _loadSubCollection(
        collectionName: 'maintenance_reports',
        fromJson: MaintenanceReport.fromJson,
      );

  Future<void> saveMaintenanceReports(List<MaintenanceReport> reports) =>
      _saveSubCollection(
        collectionName: 'maintenance_reports',
        items: reports,
        toJson: (r) => r.toJson(),
      );

  Future<void> syncPending() async {
    final mutations = await _localDb.pendingMutations();
    for (final mutation in mutations) {
      try {
        final data = jsonDecode(mutation.payload) as Map<String, dynamic>;
        if (data['type'] == 'profile_upsert') {
          final profile = UserProfile.fromJson(
            data['profile'] as Map<String, dynamic>,
          );
          await _userDocument().set(profile.toJson());
        }
        await _localDb.removePending(mutation.id);
      } catch (_) {
        // Leave mutation for the next sync attempt.
      }
    }
  }

  /// Increment the daily alert count for the current user.
  Future<void> incrementAlertCount() async {
    final userId = _activeUserId;
    if (userId == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      await _firestore.runTransaction((tx) async {
        final userDoc = _userDocument();
        final snapshot = await tx.get(userDoc);

        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final lastAlertDay = data['alertsDay'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['alertsDay'] as int)
            : null;
        final currentCount = data['alertsToday'] as int? ?? 0;

        // Reset count if it's a new day
        final newCount =
            (lastAlertDay == null || !isSameDay(lastAlertDay, today))
            ? 1
            : currentCount + 1;

        tx.update(userDoc, {
          'alertsDay': today.millisecondsSinceEpoch,
          'alertsToday': newCount,
        });
      });
    } catch (e) {
      // If transaction fails, try a simple update
      try {
        await _userDocument().update({
          'alertsDay': today.millisecondsSinceEpoch,
          'alertsToday': FieldValue.increment(1),
        });
      } catch (_) {
        // Swallow errors — alert counting should not block UX
      }
    }
  }

  /// Get the current alert count for today.
  Future<int> getCurrentAlertCount() async {
    final userId = _activeUserId;
    if (userId == null) return 0;

    try {
      final doc = await _userDocument().get();
      if (!doc.exists) return 0;

      final data = doc.data()!;
      final lastAlertDay = data['alertsDay'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['alertsDay'] as int)
          : null;
      final count = data['alertsToday'] as int? ?? 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Return 0 if it's a new day
      return (lastAlertDay == null || !isSameDay(lastAlertDay, today))
          ? 0
          : count;
    } catch (e) {
      return 0;
    }
  }

  /// Helper function to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Update the user's last activity timestamp.
  /// Called when the app opens or user performs significant actions.
  /// This is used for inactive account cleanup (30-day auto-delete).
  Future<void> updateLastActivity() async {
    final userId = _activeUserId;
    if (userId == null) return;

    try {
      await _userDocument().set({
        'lastActivityAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail - this is a background operation
    }
  }
}
