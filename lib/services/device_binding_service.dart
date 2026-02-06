import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to bind user accounts to a single device.
/// Prevents subscription sharing by ensuring one account = one device.
/// Uses Option A: New device takes over, old device gets signed out.
class DeviceBindingService {
  DeviceBindingService._();
  static final DeviceBindingService instance = DeviceBindingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _deviceId;
  StreamSubscription<DocumentSnapshot>? _deviceListener;
  VoidCallback? _onKickedOut;

  /// Get or generate a unique device ID
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_binding_id');

    if (_deviceId == null) {
      // Generate a new device ID based on platform info + random component
      _deviceId = await _generateDeviceId();
      await prefs.setString('device_binding_id', _deviceId!);
    }

    return _deviceId!;
  }

  /// Generate a unique device identifier
  Future<String> _generateDeviceId() async {
    String platformInfo = '';

    try {
      if (!kIsWeb) {
        if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          platformInfo =
              '${iosInfo.identifierForVendor ?? ''}_${iosInfo.model}';
        } else if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          platformInfo = '${androidInfo.id}_${androidInfo.model}';
        } else if (Platform.isMacOS) {
          final macInfo = await _deviceInfo.macOsInfo;
          platformInfo = '${macInfo.systemGUID ?? ''}_${macInfo.model}';
        }
      } else {
        final webInfo = await _deviceInfo.webBrowserInfo;
        platformInfo = '${webInfo.browserName}_${webInfo.platform}';
      }
    } catch (e) {
      debugPrint('DeviceBindingService: Error getting device info: $e');
    }

    // Add timestamp for uniqueness
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${platformInfo}_$timestamp'.replaceAll(RegExp(r'[^\w]'), '_');
  }

  /// Get device name for display purposes
  Future<String> getDeviceName() async {
    try {
      if (!kIsWeb) {
        if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          return iosInfo.name;
        } else if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          return '${androidInfo.brand} ${androidInfo.model}';
        } else if (Platform.isMacOS) {
          final macInfo = await _deviceInfo.macOsInfo;
          return macInfo.computerName;
        }
      } else {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return '${webInfo.browserName.name} on ${webInfo.platform ?? 'Web'}';
      }
    } catch (e) {
      debugPrint('DeviceBindingService: Error getting device name: $e');
    }
    return 'Unknown Device';
  }

  /// Register this device for the given user.
  /// This will kick out any other device currently registered.
  Future<void> registerDevice(String userId) async {
    final deviceId = await getDeviceId();
    final deviceName = await getDeviceName();

    debugPrint(
      'DeviceBindingService: Registering device $deviceId for user $userId',
    );

    await _firestore.collection('users').doc(userId).set({
      'activeDeviceId': deviceId,
      'activeDeviceName': deviceName,
      'deviceRegisteredAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Start listening for device changes.
  /// If another device registers, the callback will be triggered.
  void startListening(String userId, VoidCallback onKickedOut) {
    _onKickedOut = onKickedOut;

    // Cancel any existing listener
    _deviceListener?.cancel();

    _deviceListener = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) async {
          if (!snapshot.exists) return;

          final data = snapshot.data();
          if (data == null) return;

          final activeDeviceId = data['activeDeviceId'] as String?;
          final currentDeviceId = await getDeviceId();

          // If the active device is not this device, we've been kicked out
          if (activeDeviceId != null && activeDeviceId != currentDeviceId) {
            debugPrint(
              'DeviceBindingService: Kicked out! Active device: $activeDeviceId, This device: $currentDeviceId',
            );
            _onKickedOut?.call();
          }
        });
  }

  /// Stop listening for device changes
  void stopListening() {
    _deviceListener?.cancel();
    _deviceListener = null;
    _onKickedOut = null;
  }

  /// Check if this device is the active device for the user
  Future<bool> isActiveDevice(String userId) async {
    final deviceId = await getDeviceId();

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return true; // No device registered yet

      final activeDeviceId = doc.data()?['activeDeviceId'] as String?;
      return activeDeviceId == null || activeDeviceId == deviceId;
    } catch (e) {
      debugPrint('DeviceBindingService: Error checking active device: $e');
      return true; // Allow on error
    }
  }

  /// Clear device binding for a user (used on logout)
  Future<void> clearDeviceBinding(String userId) async {
    stopListening();

    // Optionally clear the device from Firestore
    // Uncomment if you want logout to free up the device slot
    // await _firestore.collection('users').doc(userId).update({
    //   'activeDeviceId': FieldValue.delete(),
    //   'activeDeviceName': FieldValue.delete(),
    //   'deviceRegisteredAt': FieldValue.delete(),
    // });
  }
}
