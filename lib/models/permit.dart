import 'package:flutter/material.dart';
import 'user.dart';

class Permit {
  final String id;
  final String permitNumber;
  final PermitType type;
  final DateTime startDate;
  final DateTime endDate;
  final PermitStatus status;
  final Vehicle vehicle;
  final String? zone;
  final double cost;
  final String qrCode;

  const Permit({
    required this.id,
    required this.permitNumber,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.vehicle,
    this.zone,
    required this.cost,
    required this.qrCode,
  });

  factory Permit.fromJson(Map<String, dynamic> json) {
    return Permit(
      id: json['id'] as String,
      permitNumber: json['permitNumber'] as String,
      type: PermitType.values.firstWhere((e) => e.name == json['type']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: PermitStatus.values.firstWhere((e) => e.name == json['status']),
      vehicle: Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
      zone: json['zone'] as String?,
      cost: (json['cost'] as num).toDouble(),
      qrCode: json['qrCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'permitNumber': permitNumber,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'vehicle': vehicle.toJson(),
      'zone': zone,
      'cost': cost,
      'qrCode': qrCode,
    };
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isActive => status == PermitStatus.active && !isExpired;

  Duration get timeRemaining =>
      isExpired ? Duration.zero : endDate.difference(DateTime.now());
}

enum PermitType {
  residential,
  visitor,
  business,
  handicap,
  monthly,
  annual,
  temporary,
}

enum PermitStatus { active, expired, suspended, pending, cancelled }
