import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing referrals and rewards
class ReferralService {
  ReferralService._();
  static final instance = ReferralService._();

  // Rewards configuration
  static const int _premiumTrialDays = 7; // Days of premium for successful referral
  static const int _maxReferralRewards = 10; // Max rewards per user

  FirebaseFirestore? _firestore;
  String? _userId;
  String? _referralCode;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  String? get referralCode => _referralCode;
  int get premiumTrialDays => _premiumTrialDays;

  /// Initialize the referral service
  Future<void> initialize({
    required String userId,
    FirebaseFirestore? firestore,
  }) async {
    _userId = userId;
    _firestore = firestore ?? FirebaseFirestore.instance;

    try {
      // Get or create referral code
      await _ensureReferralCode();
      _initialized = true;
      debugPrint('ReferralService: Initialized with code $_referralCode');
    } catch (e) {
      debugPrint('ReferralService: Failed to initialize - $e');
    }
  }

  /// Get the user's referral code
  Future<String> getReferralCode() async {
    if (_referralCode != null) return _referralCode!;
    await _ensureReferralCode();
    return _referralCode!;
  }

  /// Generate a unique referral code
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude confusing chars
    final random = Random.secure();
    final code = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    return 'MKE$code'; // Prefix for branding
  }

  Future<void> _ensureReferralCode() async {
    if (_userId == null || _firestore == null) {
      // Fallback to local code if Firebase not available
      final prefs = await SharedPreferences.getInstance();
      _referralCode = prefs.getString('referral_code');
      if (_referralCode == null) {
        _referralCode = _generateCode();
        await prefs.setString('referral_code', _referralCode!);
      }
      return;
    }

    try {
      final userRef = _firestore!.collection('users').doc(_userId);
      final userDoc = await userRef.get();

      if (userDoc.exists && userDoc.data()?['referralCode'] != null) {
        _referralCode = userDoc.data()!['referralCode'];
      } else {
        // Generate and save new code
        _referralCode = _generateCode();

        // Make sure code is unique
        var attempts = 0;
        while (attempts < 5) {
          final existing = await _firestore!
              .collection('referral_codes')
              .doc(_referralCode)
              .get();

          if (!existing.exists) break;
          _referralCode = _generateCode();
          attempts++;
        }

        // Save code to user profile and codes collection
        await Future.wait([
          userRef.set({
            'referralCode': _referralCode,
          }, SetOptions(merge: true)),
          _firestore!.collection('referral_codes').doc(_referralCode).set({
            'ownerId': _userId,
            'createdAt': FieldValue.serverTimestamp(),
            'uses': 0,
          }),
        ]);
      }
    } catch (e) {
      debugPrint('ReferralService: Error ensuring code - $e');
      // Fallback to local
      final prefs = await SharedPreferences.getInstance();
      _referralCode = prefs.getString('referral_code') ?? _generateCode();
      await prefs.setString('referral_code', _referralCode!);
    }
  }

  /// Apply a referral code during signup
  Future<ReferralResult> applyReferralCode(String code) async {
    if (_userId == null) {
      return const ReferralResult(
        success: false,
        error: 'User not logged in',
      );
    }

    code = code.trim().toUpperCase();

    if (code.isEmpty) {
      return const ReferralResult(
        success: false,
        error: 'Please enter a referral code',
      );
    }

    // Can't use own code
    if (code == _referralCode) {
      return const ReferralResult(
        success: false,
        error: 'You cannot use your own referral code',
      );
    }

    try {
      // Check if user already used a referral code
      final userRef = _firestore!.collection('users').doc(_userId);
      final userDoc = await userRef.get();
      final userData = userDoc.data() ?? {};

      if (userData['appliedReferralCode'] != null) {
        return const ReferralResult(
          success: false,
          error: 'You have already used a referral code',
        );
      }

      // Validate code exists
      final codeRef = _firestore!.collection('referral_codes').doc(code);
      final codeDoc = await codeRef.get();

      if (!codeDoc.exists) {
        return const ReferralResult(
          success: false,
          error: 'Invalid referral code',
        );
      }

      final codeData = codeDoc.data()!;
      final referrerId = codeData['ownerId'] as String?;

      if (referrerId == null) {
        return const ReferralResult(
          success: false,
          error: 'Invalid referral code',
        );
      }

      // Apply the referral in a transaction
      await _firestore!.runTransaction((tx) async {
        // Update referral code usage
        tx.update(codeRef, {
          'uses': FieldValue.increment(1),
          'lastUsedAt': FieldValue.serverTimestamp(),
        });

        // Record the referral
        final referralRef = _firestore!.collection('referrals').doc();
        tx.set(referralRef, {
          'referrerId': referrerId,
          'referredId': _userId,
          'code': code,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'completed',
        });

        // Grant premium trial to new user
        final now = DateTime.now();
        final trialEnd = now.add(Duration(days: _premiumTrialDays));
        tx.set(userRef, {
          'appliedReferralCode': code,
          'referredBy': referrerId,
          'premiumTrialEnd': Timestamp.fromDate(trialEnd),
        }, SetOptions(merge: true));

        // Grant reward to referrer (if under limit)
        final referrerRef = _firestore!.collection('users').doc(referrerId);
        final referrerDoc = await tx.get(referrerRef);
        final referrerData = referrerDoc.data() ?? {};
        final currentRewards = (referrerData['referralRewardsCount'] ?? 0) as int;

        if (currentRewards < _maxReferralRewards) {
          final existingTrialEnd = referrerData['premiumTrialEnd'] as Timestamp?;
          DateTime referrerTrialEnd;

          if (existingTrialEnd != null &&
              existingTrialEnd.toDate().isAfter(now)) {
            // Extend existing trial
            referrerTrialEnd = existingTrialEnd
                .toDate()
                .add(Duration(days: _premiumTrialDays));
          } else {
            // Start new trial
            referrerTrialEnd = now.add(Duration(days: _premiumTrialDays));
          }

          tx.set(referrerRef, {
            'premiumTrialEnd': Timestamp.fromDate(referrerTrialEnd),
            'referralRewardsCount': currentRewards + 1,
            'lastReferralRewardAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });

      return ReferralResult(
        success: true,
        message:
            'Referral code applied! You have $_premiumTrialDays days of premium access.',
        trialDays: _premiumTrialDays,
      );
    } catch (e) {
      debugPrint('ReferralService: Error applying code - $e');
      return ReferralResult(
        success: false,
        error: 'Failed to apply referral code: $e',
      );
    }
  }

  /// Get referral statistics for the current user
  Future<ReferralStats> getStats() async {
    if (_userId == null || _firestore == null) {
      return const ReferralStats(
        totalReferrals: 0,
        successfulReferrals: 0,
        rewardsEarned: 0,
        maxRewards: _maxReferralRewards,
      );
    }

    try {
      // Get user's referrals
      final referralsQuery = await _firestore!
          .collection('referrals')
          .where('referrerId', isEqualTo: _userId)
          .get();

      final userDoc = await _firestore!.collection('users').doc(_userId).get();
      final userData = userDoc.data() ?? {};
      final rewardsCount = (userData['referralRewardsCount'] ?? 0) as int;

      return ReferralStats(
        totalReferrals: referralsQuery.docs.length,
        successfulReferrals: referralsQuery.docs
            .where((d) => d.data()['status'] == 'completed')
            .length,
        rewardsEarned: rewardsCount,
        maxRewards: _maxReferralRewards,
        premiumTrialEnd: userData['premiumTrialEnd'] != null
            ? (userData['premiumTrialEnd'] as Timestamp).toDate()
            : null,
      );
    } catch (e) {
      debugPrint('ReferralService: Error getting stats - $e');
      return const ReferralStats(
        totalReferrals: 0,
        successfulReferrals: 0,
        rewardsEarned: 0,
        maxRewards: _maxReferralRewards,
      );
    }
  }

  /// Check if user has active premium trial from referral
  Future<bool> hasActiveReferralTrial() async {
    if (_userId == null || _firestore == null) return false;

    try {
      final userDoc = await _firestore!.collection('users').doc(_userId).get();
      final userData = userDoc.data();
      if (userData == null) return false;

      final trialEnd = userData['premiumTrialEnd'] as Timestamp?;
      if (trialEnd == null) return false;

      return trialEnd.toDate().isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Get days remaining in premium trial
  Future<int> getRemainingTrialDays() async {
    if (_userId == null || _firestore == null) return 0;

    try {
      final userDoc = await _firestore!.collection('users').doc(_userId).get();
      final userData = userDoc.data();
      if (userData == null) return 0;

      final trialEnd = userData['premiumTrialEnd'] as Timestamp?;
      if (trialEnd == null) return 0;

      final remaining = trialEnd.toDate().difference(DateTime.now());
      return remaining.inDays > 0 ? remaining.inDays : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get referral link for sharing
  String getReferralLink() {
    final code = _referralCode ?? 'LOADING';
    return 'https://mke-citysmart.app/invite/$code';
  }

  /// Get share message
  String getShareMessage() {
    final code = _referralCode ?? 'LOADING';
    return '''
Hey! I'm using MKE CitySmart to avoid parking tickets in Milwaukee. 

Use my referral code $code when you sign up and we'll both get $_premiumTrialDays days of Premium access FREE!

Download here: https://mke-citysmart.app/invite/$code
''';
  }
}

/// Result of applying a referral code
class ReferralResult {
  const ReferralResult({
    required this.success,
    this.error,
    this.message,
    this.trialDays,
  });

  final bool success;
  final String? error;
  final String? message;
  final int? trialDays;
}

/// User's referral statistics
class ReferralStats {
  const ReferralStats({
    required this.totalReferrals,
    required this.successfulReferrals,
    required this.rewardsEarned,
    required this.maxRewards,
    this.premiumTrialEnd,
  });

  final int totalReferrals;
  final int successfulReferrals;
  final int rewardsEarned;
  final int maxRewards;
  final DateTime? premiumTrialEnd;

  bool get hasActiveReward =>
      premiumTrialEnd != null && premiumTrialEnd!.isAfter(DateTime.now());

  int get remainingRewards => maxRewards - rewardsEarned;
}
