// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $DbUserProfilesTable extends DbUserProfiles
    with TableInfo<$DbUserProfilesTable, DbUserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbUserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formattedAddressMeta = const VerificationMeta(
    'formattedAddress',
  );
  @override
  late final GeneratedColumn<String> formattedAddress = GeneratedColumn<String>(
    'formatted_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressLatitudeMeta = const VerificationMeta(
    'addressLatitude',
  );
  @override
  late final GeneratedColumn<double> addressLatitude = GeneratedColumn<double>(
    'address_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressLongitudeMeta = const VerificationMeta(
    'addressLongitude',
  );
  @override
  late final GeneratedColumn<double> addressLongitude = GeneratedColumn<double>(
    'address_longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferencesJsonMeta = const VerificationMeta(
    'preferencesJson',
  );
  @override
  late final GeneratedColumn<String> preferencesJson = GeneratedColumn<String>(
    'preferences_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adPreferencesJsonMeta = const VerificationMeta(
    'adPreferencesJson',
  );
  @override
  late final GeneratedColumn<String> adPreferencesJson =
      GeneratedColumn<String>(
        'ad_preferences_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cityIdMeta = const VerificationMeta('cityId');
  @override
  late final GeneratedColumn<String> cityId = GeneratedColumn<String>(
    'city_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _rulePackJsonMeta = const VerificationMeta(
    'rulePackJson',
  );
  @override
  late final GeneratedColumn<String> rulePackJson = GeneratedColumn<String>(
    'rule_pack_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    email,
    phone,
    address,
    formattedAddress,
    addressLatitude,
    addressLongitude,
    preferencesJson,
    adPreferencesJson,
    tier,
    cityId,
    tenantId,
    rulePackJson,
    languageCode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbUserProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('formatted_address')) {
      context.handle(
        _formattedAddressMeta,
        formattedAddress.isAcceptableOrUnknown(
          data['formatted_address']!,
          _formattedAddressMeta,
        ),
      );
    }
    if (data.containsKey('address_latitude')) {
      context.handle(
        _addressLatitudeMeta,
        addressLatitude.isAcceptableOrUnknown(
          data['address_latitude']!,
          _addressLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('address_longitude')) {
      context.handle(
        _addressLongitudeMeta,
        addressLongitude.isAcceptableOrUnknown(
          data['address_longitude']!,
          _addressLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('preferences_json')) {
      context.handle(
        _preferencesJsonMeta,
        preferencesJson.isAcceptableOrUnknown(
          data['preferences_json']!,
          _preferencesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_preferencesJsonMeta);
    }
    if (data.containsKey('ad_preferences_json')) {
      context.handle(
        _adPreferencesJsonMeta,
        adPreferencesJson.isAcceptableOrUnknown(
          data['ad_preferences_json']!,
          _adPreferencesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adPreferencesJsonMeta);
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    } else if (isInserting) {
      context.missing(_tierMeta);
    }
    if (data.containsKey('city_id')) {
      context.handle(
        _cityIdMeta,
        cityId.isAcceptableOrUnknown(data['city_id']!, _cityIdMeta),
      );
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    }
    if (data.containsKey('rule_pack_json')) {
      context.handle(
        _rulePackJsonMeta,
        rulePackJson.isAcceptableOrUnknown(
          data['rule_pack_json']!,
          _rulePackJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rulePackJsonMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbUserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbUserProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      formattedAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formatted_address'],
      ),
      addressLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}address_latitude'],
      ),
      addressLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}address_longitude'],
      ),
      preferencesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferences_json'],
      )!,
      adPreferencesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ad_preferences_json'],
      )!,
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier'],
      )!,
      cityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city_id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      rulePackJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_pack_json'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $DbUserProfilesTable createAlias(String alias) {
    return $DbUserProfilesTable(attachedDatabase, alias);
  }
}

class DbUserProfile extends DataClass implements Insertable<DbUserProfile> {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? formattedAddress;
  final double? addressLatitude;
  final double? addressLongitude;
  final String preferencesJson;
  final String adPreferencesJson;
  final String tier;
  final String cityId;
  final String tenantId;
  final String rulePackJson;
  final String languageCode;
  final DateTime? updatedAt;
  const DbUserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.formattedAddress,
    this.addressLatitude,
    this.addressLongitude,
    required this.preferencesJson,
    required this.adPreferencesJson,
    required this.tier,
    required this.cityId,
    required this.tenantId,
    required this.rulePackJson,
    required this.languageCode,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || formattedAddress != null) {
      map['formatted_address'] = Variable<String>(formattedAddress);
    }
    if (!nullToAbsent || addressLatitude != null) {
      map['address_latitude'] = Variable<double>(addressLatitude);
    }
    if (!nullToAbsent || addressLongitude != null) {
      map['address_longitude'] = Variable<double>(addressLongitude);
    }
    map['preferences_json'] = Variable<String>(preferencesJson);
    map['ad_preferences_json'] = Variable<String>(adPreferencesJson);
    map['tier'] = Variable<String>(tier);
    map['city_id'] = Variable<String>(cityId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['rule_pack_json'] = Variable<String>(rulePackJson);
    map['language_code'] = Variable<String>(languageCode);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  DbUserProfilesCompanion toCompanion(bool nullToAbsent) {
    return DbUserProfilesCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      formattedAddress: formattedAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(formattedAddress),
      addressLatitude: addressLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(addressLatitude),
      addressLongitude: addressLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(addressLongitude),
      preferencesJson: Value(preferencesJson),
      adPreferencesJson: Value(adPreferencesJson),
      tier: Value(tier),
      cityId: Value(cityId),
      tenantId: Value(tenantId),
      rulePackJson: Value(rulePackJson),
      languageCode: Value(languageCode),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory DbUserProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbUserProfile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      formattedAddress: serializer.fromJson<String?>(json['formattedAddress']),
      addressLatitude: serializer.fromJson<double?>(json['addressLatitude']),
      addressLongitude: serializer.fromJson<double?>(json['addressLongitude']),
      preferencesJson: serializer.fromJson<String>(json['preferencesJson']),
      adPreferencesJson: serializer.fromJson<String>(json['adPreferencesJson']),
      tier: serializer.fromJson<String>(json['tier']),
      cityId: serializer.fromJson<String>(json['cityId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      rulePackJson: serializer.fromJson<String>(json['rulePackJson']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'formattedAddress': serializer.toJson<String?>(formattedAddress),
      'addressLatitude': serializer.toJson<double?>(addressLatitude),
      'addressLongitude': serializer.toJson<double?>(addressLongitude),
      'preferencesJson': serializer.toJson<String>(preferencesJson),
      'adPreferencesJson': serializer.toJson<String>(adPreferencesJson),
      'tier': serializer.toJson<String>(tier),
      'cityId': serializer.toJson<String>(cityId),
      'tenantId': serializer.toJson<String>(tenantId),
      'rulePackJson': serializer.toJson<String>(rulePackJson),
      'languageCode': serializer.toJson<String>(languageCode),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  DbUserProfile copyWith({
    String? id,
    String? name,
    String? email,
    Value<String?> phone = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> formattedAddress = const Value.absent(),
    Value<double?> addressLatitude = const Value.absent(),
    Value<double?> addressLongitude = const Value.absent(),
    String? preferencesJson,
    String? adPreferencesJson,
    String? tier,
    String? cityId,
    String? tenantId,
    String? rulePackJson,
    String? languageCode,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => DbUserProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone.present ? phone.value : this.phone,
    address: address.present ? address.value : this.address,
    formattedAddress: formattedAddress.present
        ? formattedAddress.value
        : this.formattedAddress,
    addressLatitude: addressLatitude.present
        ? addressLatitude.value
        : this.addressLatitude,
    addressLongitude: addressLongitude.present
        ? addressLongitude.value
        : this.addressLongitude,
    preferencesJson: preferencesJson ?? this.preferencesJson,
    adPreferencesJson: adPreferencesJson ?? this.adPreferencesJson,
    tier: tier ?? this.tier,
    cityId: cityId ?? this.cityId,
    tenantId: tenantId ?? this.tenantId,
    rulePackJson: rulePackJson ?? this.rulePackJson,
    languageCode: languageCode ?? this.languageCode,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  DbUserProfile copyWithCompanion(DbUserProfilesCompanion data) {
    return DbUserProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      formattedAddress: data.formattedAddress.present
          ? data.formattedAddress.value
          : this.formattedAddress,
      addressLatitude: data.addressLatitude.present
          ? data.addressLatitude.value
          : this.addressLatitude,
      addressLongitude: data.addressLongitude.present
          ? data.addressLongitude.value
          : this.addressLongitude,
      preferencesJson: data.preferencesJson.present
          ? data.preferencesJson.value
          : this.preferencesJson,
      adPreferencesJson: data.adPreferencesJson.present
          ? data.adPreferencesJson.value
          : this.adPreferencesJson,
      tier: data.tier.present ? data.tier.value : this.tier,
      cityId: data.cityId.present ? data.cityId.value : this.cityId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      rulePackJson: data.rulePackJson.present
          ? data.rulePackJson.value
          : this.rulePackJson,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbUserProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('formattedAddress: $formattedAddress, ')
          ..write('addressLatitude: $addressLatitude, ')
          ..write('addressLongitude: $addressLongitude, ')
          ..write('preferencesJson: $preferencesJson, ')
          ..write('adPreferencesJson: $adPreferencesJson, ')
          ..write('tier: $tier, ')
          ..write('cityId: $cityId, ')
          ..write('tenantId: $tenantId, ')
          ..write('rulePackJson: $rulePackJson, ')
          ..write('languageCode: $languageCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    phone,
    address,
    formattedAddress,
    addressLatitude,
    addressLongitude,
    preferencesJson,
    adPreferencesJson,
    tier,
    cityId,
    tenantId,
    rulePackJson,
    languageCode,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbUserProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.formattedAddress == this.formattedAddress &&
          other.addressLatitude == this.addressLatitude &&
          other.addressLongitude == this.addressLongitude &&
          other.preferencesJson == this.preferencesJson &&
          other.adPreferencesJson == this.adPreferencesJson &&
          other.tier == this.tier &&
          other.cityId == this.cityId &&
          other.tenantId == this.tenantId &&
          other.rulePackJson == this.rulePackJson &&
          other.languageCode == this.languageCode &&
          other.updatedAt == this.updatedAt);
}

class DbUserProfilesCompanion extends UpdateCompanion<DbUserProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> email;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<String?> formattedAddress;
  final Value<double?> addressLatitude;
  final Value<double?> addressLongitude;
  final Value<String> preferencesJson;
  final Value<String> adPreferencesJson;
  final Value<String> tier;
  final Value<String> cityId;
  final Value<String> tenantId;
  final Value<String> rulePackJson;
  final Value<String> languageCode;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const DbUserProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.formattedAddress = const Value.absent(),
    this.addressLatitude = const Value.absent(),
    this.addressLongitude = const Value.absent(),
    this.preferencesJson = const Value.absent(),
    this.adPreferencesJson = const Value.absent(),
    this.tier = const Value.absent(),
    this.cityId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.rulePackJson = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbUserProfilesCompanion.insert({
    required String id,
    required String name,
    required String email,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.formattedAddress = const Value.absent(),
    this.addressLatitude = const Value.absent(),
    this.addressLongitude = const Value.absent(),
    required String preferencesJson,
    required String adPreferencesJson,
    required String tier,
    this.cityId = const Value.absent(),
    this.tenantId = const Value.absent(),
    required String rulePackJson,
    this.languageCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       email = Value(email),
       preferencesJson = Value(preferencesJson),
       adPreferencesJson = Value(adPreferencesJson),
       tier = Value(tier),
       rulePackJson = Value(rulePackJson);
  static Insertable<DbUserProfile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? formattedAddress,
    Expression<double>? addressLatitude,
    Expression<double>? addressLongitude,
    Expression<String>? preferencesJson,
    Expression<String>? adPreferencesJson,
    Expression<String>? tier,
    Expression<String>? cityId,
    Expression<String>? tenantId,
    Expression<String>? rulePackJson,
    Expression<String>? languageCode,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (formattedAddress != null) 'formatted_address': formattedAddress,
      if (addressLatitude != null) 'address_latitude': addressLatitude,
      if (addressLongitude != null) 'address_longitude': addressLongitude,
      if (preferencesJson != null) 'preferences_json': preferencesJson,
      if (adPreferencesJson != null) 'ad_preferences_json': adPreferencesJson,
      if (tier != null) 'tier': tier,
      if (cityId != null) 'city_id': cityId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (rulePackJson != null) 'rule_pack_json': rulePackJson,
      if (languageCode != null) 'language_code': languageCode,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbUserProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? email,
    Value<String?>? phone,
    Value<String?>? address,
    Value<String?>? formattedAddress,
    Value<double?>? addressLatitude,
    Value<double?>? addressLongitude,
    Value<String>? preferencesJson,
    Value<String>? adPreferencesJson,
    Value<String>? tier,
    Value<String>? cityId,
    Value<String>? tenantId,
    Value<String>? rulePackJson,
    Value<String>? languageCode,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return DbUserProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      addressLatitude: addressLatitude ?? this.addressLatitude,
      addressLongitude: addressLongitude ?? this.addressLongitude,
      preferencesJson: preferencesJson ?? this.preferencesJson,
      adPreferencesJson: adPreferencesJson ?? this.adPreferencesJson,
      tier: tier ?? this.tier,
      cityId: cityId ?? this.cityId,
      tenantId: tenantId ?? this.tenantId,
      rulePackJson: rulePackJson ?? this.rulePackJson,
      languageCode: languageCode ?? this.languageCode,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (formattedAddress.present) {
      map['formatted_address'] = Variable<String>(formattedAddress.value);
    }
    if (addressLatitude.present) {
      map['address_latitude'] = Variable<double>(addressLatitude.value);
    }
    if (addressLongitude.present) {
      map['address_longitude'] = Variable<double>(addressLongitude.value);
    }
    if (preferencesJson.present) {
      map['preferences_json'] = Variable<String>(preferencesJson.value);
    }
    if (adPreferencesJson.present) {
      map['ad_preferences_json'] = Variable<String>(adPreferencesJson.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (cityId.present) {
      map['city_id'] = Variable<String>(cityId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (rulePackJson.present) {
      map['rule_pack_json'] = Variable<String>(rulePackJson.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbUserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('formattedAddress: $formattedAddress, ')
          ..write('addressLatitude: $addressLatitude, ')
          ..write('addressLongitude: $addressLongitude, ')
          ..write('preferencesJson: $preferencesJson, ')
          ..write('adPreferencesJson: $adPreferencesJson, ')
          ..write('tier: $tier, ')
          ..write('cityId: $cityId, ')
          ..write('tenantId: $tenantId, ')
          ..write('rulePackJson: $rulePackJson, ')
          ..write('languageCode: $languageCode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbVehiclesTable extends DbVehicles
    with TableInfo<$DbVehiclesTable, DbVehicle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbVehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _makeMeta = const VerificationMeta('make');
  @override
  late final GeneratedColumn<String> make = GeneratedColumn<String>(
    'make',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _licensePlateMeta = const VerificationMeta(
    'licensePlate',
  );
  @override
  late final GeneratedColumn<String> licensePlate = GeneratedColumn<String>(
    'license_plate',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    make,
    model,
    licensePlate,
    color,
    nickname,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbVehicle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('make')) {
      context.handle(
        _makeMeta,
        make.isAcceptableOrUnknown(data['make']!, _makeMeta),
      );
    } else if (isInserting) {
      context.missing(_makeMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('license_plate')) {
      context.handle(
        _licensePlateMeta,
        licensePlate.isAcceptableOrUnknown(
          data['license_plate']!,
          _licensePlateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_licensePlateMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbVehicle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbVehicle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      make: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}make'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      licensePlate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license_plate'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
    );
  }

  @override
  $DbVehiclesTable createAlias(String alias) {
    return $DbVehiclesTable(attachedDatabase, alias);
  }
}

class DbVehicle extends DataClass implements Insertable<DbVehicle> {
  final String id;
  final String profileId;
  final String make;
  final String model;
  final String licensePlate;
  final String color;
  final String nickname;
  const DbVehicle({
    required this.id,
    required this.profileId,
    required this.make,
    required this.model,
    required this.licensePlate,
    required this.color,
    required this.nickname,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['make'] = Variable<String>(make);
    map['model'] = Variable<String>(model);
    map['license_plate'] = Variable<String>(licensePlate);
    map['color'] = Variable<String>(color);
    map['nickname'] = Variable<String>(nickname);
    return map;
  }

  DbVehiclesCompanion toCompanion(bool nullToAbsent) {
    return DbVehiclesCompanion(
      id: Value(id),
      profileId: Value(profileId),
      make: Value(make),
      model: Value(model),
      licensePlate: Value(licensePlate),
      color: Value(color),
      nickname: Value(nickname),
    );
  }

  factory DbVehicle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbVehicle(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      make: serializer.fromJson<String>(json['make']),
      model: serializer.fromJson<String>(json['model']),
      licensePlate: serializer.fromJson<String>(json['licensePlate']),
      color: serializer.fromJson<String>(json['color']),
      nickname: serializer.fromJson<String>(json['nickname']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'make': serializer.toJson<String>(make),
      'model': serializer.toJson<String>(model),
      'licensePlate': serializer.toJson<String>(licensePlate),
      'color': serializer.toJson<String>(color),
      'nickname': serializer.toJson<String>(nickname),
    };
  }

  DbVehicle copyWith({
    String? id,
    String? profileId,
    String? make,
    String? model,
    String? licensePlate,
    String? color,
    String? nickname,
  }) => DbVehicle(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    make: make ?? this.make,
    model: model ?? this.model,
    licensePlate: licensePlate ?? this.licensePlate,
    color: color ?? this.color,
    nickname: nickname ?? this.nickname,
  );
  DbVehicle copyWithCompanion(DbVehiclesCompanion data) {
    return DbVehicle(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      make: data.make.present ? data.make.value : this.make,
      model: data.model.present ? data.model.value : this.model,
      licensePlate: data.licensePlate.present
          ? data.licensePlate.value
          : this.licensePlate,
      color: data.color.present ? data.color.value : this.color,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbVehicle(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('make: $make, ')
          ..write('model: $model, ')
          ..write('licensePlate: $licensePlate, ')
          ..write('color: $color, ')
          ..write('nickname: $nickname')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, profileId, make, model, licensePlate, color, nickname);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbVehicle &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.make == this.make &&
          other.model == this.model &&
          other.licensePlate == this.licensePlate &&
          other.color == this.color &&
          other.nickname == this.nickname);
}

class DbVehiclesCompanion extends UpdateCompanion<DbVehicle> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> make;
  final Value<String> model;
  final Value<String> licensePlate;
  final Value<String> color;
  final Value<String> nickname;
  final Value<int> rowid;
  const DbVehiclesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.make = const Value.absent(),
    this.model = const Value.absent(),
    this.licensePlate = const Value.absent(),
    this.color = const Value.absent(),
    this.nickname = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbVehiclesCompanion.insert({
    required String id,
    required String profileId,
    required String make,
    required String model,
    required String licensePlate,
    required String color,
    required String nickname,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       make = Value(make),
       model = Value(model),
       licensePlate = Value(licensePlate),
       color = Value(color),
       nickname = Value(nickname);
  static Insertable<DbVehicle> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? make,
    Expression<String>? model,
    Expression<String>? licensePlate,
    Expression<String>? color,
    Expression<String>? nickname,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (licensePlate != null) 'license_plate': licensePlate,
      if (color != null) 'color': color,
      if (nickname != null) 'nickname': nickname,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbVehiclesCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? make,
    Value<String>? model,
    Value<String>? licensePlate,
    Value<String>? color,
    Value<String>? nickname,
    Value<int>? rowid,
  }) {
    return DbVehiclesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      make: make ?? this.make,
      model: model ?? this.model,
      licensePlate: licensePlate ?? this.licensePlate,
      color: color ?? this.color,
      nickname: nickname ?? this.nickname,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (make.present) {
      map['make'] = Variable<String>(make.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (licensePlate.present) {
      map['license_plate'] = Variable<String>(licensePlate.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbVehiclesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('make: $make, ')
          ..write('model: $model, ')
          ..write('licensePlate: $licensePlate, ')
          ..write('color: $color, ')
          ..write('nickname: $nickname, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DbPendingMutationsTable extends DbPendingMutations
    with TableInfo<$DbPendingMutationsTable, DbPendingMutation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DbPendingMutationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    payload,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'db_pending_mutations';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbPendingMutation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbPendingMutation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbPendingMutation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DbPendingMutationsTable createAlias(String alias) {
    return $DbPendingMutationsTable(attachedDatabase, alias);
  }
}

class DbPendingMutation extends DataClass
    implements Insertable<DbPendingMutation> {
  final String id;
  final String type;
  final String payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DbPendingMutation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DbPendingMutationsCompanion toCompanion(bool nullToAbsent) {
    return DbPendingMutationsCompanion(
      id: Value(id),
      type: Value(type),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DbPendingMutation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbPendingMutation(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DbPendingMutation copyWith({
    String? id,
    String? type,
    String? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DbPendingMutation(
    id: id ?? this.id,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DbPendingMutation copyWithCompanion(DbPendingMutationsCompanion data) {
    return DbPendingMutation(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbPendingMutation(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, payload, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbPendingMutation &&
          other.id == this.id &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DbPendingMutationsCompanion extends UpdateCompanion<DbPendingMutation> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DbPendingMutationsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DbPendingMutationsCompanion.insert({
    required String id,
    required String type,
    required String payload,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       payload = Value(payload);
  static Insertable<DbPendingMutation> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DbPendingMutationsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DbPendingMutationsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DbPendingMutationsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $DbUserProfilesTable dbUserProfiles = $DbUserProfilesTable(this);
  late final $DbVehiclesTable dbVehicles = $DbVehiclesTable(this);
  late final $DbPendingMutationsTable dbPendingMutations =
      $DbPendingMutationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dbUserProfiles,
    dbVehicles,
    dbPendingMutations,
  ];
}

typedef $$DbUserProfilesTableCreateCompanionBuilder =
    DbUserProfilesCompanion Function({
      required String id,
      required String name,
      required String email,
      Value<String?> phone,
      Value<String?> address,
      Value<String?> formattedAddress,
      Value<double?> addressLatitude,
      Value<double?> addressLongitude,
      required String preferencesJson,
      required String adPreferencesJson,
      required String tier,
      Value<String> cityId,
      Value<String> tenantId,
      required String rulePackJson,
      Value<String> languageCode,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$DbUserProfilesTableUpdateCompanionBuilder =
    DbUserProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> email,
      Value<String?> phone,
      Value<String?> address,
      Value<String?> formattedAddress,
      Value<double?> addressLatitude,
      Value<double?> addressLongitude,
      Value<String> preferencesJson,
      Value<String> adPreferencesJson,
      Value<String> tier,
      Value<String> cityId,
      Value<String> tenantId,
      Value<String> rulePackJson,
      Value<String> languageCode,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$DbUserProfilesTableFilterComposer
    extends Composer<_$LocalDatabase, $DbUserProfilesTable> {
  $$DbUserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formattedAddress => $composableBuilder(
    column: $table.formattedAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get addressLatitude => $composableBuilder(
    column: $table.addressLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get addressLongitude => $composableBuilder(
    column: $table.addressLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferencesJson => $composableBuilder(
    column: $table.preferencesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adPreferencesJson => $composableBuilder(
    column: $table.adPreferencesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cityId => $composableBuilder(
    column: $table.cityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rulePackJson => $composableBuilder(
    column: $table.rulePackJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DbUserProfilesTableOrderingComposer
    extends Composer<_$LocalDatabase, $DbUserProfilesTable> {
  $$DbUserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formattedAddress => $composableBuilder(
    column: $table.formattedAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get addressLatitude => $composableBuilder(
    column: $table.addressLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get addressLongitude => $composableBuilder(
    column: $table.addressLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferencesJson => $composableBuilder(
    column: $table.preferencesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adPreferencesJson => $composableBuilder(
    column: $table.adPreferencesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cityId => $composableBuilder(
    column: $table.cityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rulePackJson => $composableBuilder(
    column: $table.rulePackJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DbUserProfilesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $DbUserProfilesTable> {
  $$DbUserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get formattedAddress => $composableBuilder(
    column: $table.formattedAddress,
    builder: (column) => column,
  );

  GeneratedColumn<double> get addressLatitude => $composableBuilder(
    column: $table.addressLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get addressLongitude => $composableBuilder(
    column: $table.addressLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferencesJson => $composableBuilder(
    column: $table.preferencesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adPreferencesJson => $composableBuilder(
    column: $table.adPreferencesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<String> get cityId =>
      $composableBuilder(column: $table.cityId, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get rulePackJson => $composableBuilder(
    column: $table.rulePackJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DbUserProfilesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $DbUserProfilesTable,
          DbUserProfile,
          $$DbUserProfilesTableFilterComposer,
          $$DbUserProfilesTableOrderingComposer,
          $$DbUserProfilesTableAnnotationComposer,
          $$DbUserProfilesTableCreateCompanionBuilder,
          $$DbUserProfilesTableUpdateCompanionBuilder,
          (
            DbUserProfile,
            BaseReferences<
              _$LocalDatabase,
              $DbUserProfilesTable,
              DbUserProfile
            >,
          ),
          DbUserProfile,
          PrefetchHooks Function()
        > {
  $$DbUserProfilesTableTableManager(
    _$LocalDatabase db,
    $DbUserProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbUserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbUserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbUserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> formattedAddress = const Value.absent(),
                Value<double?> addressLatitude = const Value.absent(),
                Value<double?> addressLongitude = const Value.absent(),
                Value<String> preferencesJson = const Value.absent(),
                Value<String> adPreferencesJson = const Value.absent(),
                Value<String> tier = const Value.absent(),
                Value<String> cityId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> rulePackJson = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DbUserProfilesCompanion(
                id: id,
                name: name,
                email: email,
                phone: phone,
                address: address,
                formattedAddress: formattedAddress,
                addressLatitude: addressLatitude,
                addressLongitude: addressLongitude,
                preferencesJson: preferencesJson,
                adPreferencesJson: adPreferencesJson,
                tier: tier,
                cityId: cityId,
                tenantId: tenantId,
                rulePackJson: rulePackJson,
                languageCode: languageCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String email,
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> formattedAddress = const Value.absent(),
                Value<double?> addressLatitude = const Value.absent(),
                Value<double?> addressLongitude = const Value.absent(),
                required String preferencesJson,
                required String adPreferencesJson,
                required String tier,
                Value<String> cityId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                required String rulePackJson,
                Value<String> languageCode = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DbUserProfilesCompanion.insert(
                id: id,
                name: name,
                email: email,
                phone: phone,
                address: address,
                formattedAddress: formattedAddress,
                addressLatitude: addressLatitude,
                addressLongitude: addressLongitude,
                preferencesJson: preferencesJson,
                adPreferencesJson: adPreferencesJson,
                tier: tier,
                cityId: cityId,
                tenantId: tenantId,
                rulePackJson: rulePackJson,
                languageCode: languageCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DbUserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $DbUserProfilesTable,
      DbUserProfile,
      $$DbUserProfilesTableFilterComposer,
      $$DbUserProfilesTableOrderingComposer,
      $$DbUserProfilesTableAnnotationComposer,
      $$DbUserProfilesTableCreateCompanionBuilder,
      $$DbUserProfilesTableUpdateCompanionBuilder,
      (
        DbUserProfile,
        BaseReferences<_$LocalDatabase, $DbUserProfilesTable, DbUserProfile>,
      ),
      DbUserProfile,
      PrefetchHooks Function()
    >;
typedef $$DbVehiclesTableCreateCompanionBuilder =
    DbVehiclesCompanion Function({
      required String id,
      required String profileId,
      required String make,
      required String model,
      required String licensePlate,
      required String color,
      required String nickname,
      Value<int> rowid,
    });
typedef $$DbVehiclesTableUpdateCompanionBuilder =
    DbVehiclesCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> make,
      Value<String> model,
      Value<String> licensePlate,
      Value<String> color,
      Value<String> nickname,
      Value<int> rowid,
    });

class $$DbVehiclesTableFilterComposer
    extends Composer<_$LocalDatabase, $DbVehiclesTable> {
  $$DbVehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get make => $composableBuilder(
    column: $table.make,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get licensePlate => $composableBuilder(
    column: $table.licensePlate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DbVehiclesTableOrderingComposer
    extends Composer<_$LocalDatabase, $DbVehiclesTable> {
  $$DbVehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get make => $composableBuilder(
    column: $table.make,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get licensePlate => $composableBuilder(
    column: $table.licensePlate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DbVehiclesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $DbVehiclesTable> {
  $$DbVehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get make =>
      $composableBuilder(column: $table.make, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get licensePlate => $composableBuilder(
    column: $table.licensePlate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);
}

class $$DbVehiclesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $DbVehiclesTable,
          DbVehicle,
          $$DbVehiclesTableFilterComposer,
          $$DbVehiclesTableOrderingComposer,
          $$DbVehiclesTableAnnotationComposer,
          $$DbVehiclesTableCreateCompanionBuilder,
          $$DbVehiclesTableUpdateCompanionBuilder,
          (
            DbVehicle,
            BaseReferences<_$LocalDatabase, $DbVehiclesTable, DbVehicle>,
          ),
          DbVehicle,
          PrefetchHooks Function()
        > {
  $$DbVehiclesTableTableManager(_$LocalDatabase db, $DbVehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbVehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbVehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbVehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> make = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> licensePlate = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DbVehiclesCompanion(
                id: id,
                profileId: profileId,
                make: make,
                model: model,
                licensePlate: licensePlate,
                color: color,
                nickname: nickname,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String make,
                required String model,
                required String licensePlate,
                required String color,
                required String nickname,
                Value<int> rowid = const Value.absent(),
              }) => DbVehiclesCompanion.insert(
                id: id,
                profileId: profileId,
                make: make,
                model: model,
                licensePlate: licensePlate,
                color: color,
                nickname: nickname,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DbVehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $DbVehiclesTable,
      DbVehicle,
      $$DbVehiclesTableFilterComposer,
      $$DbVehiclesTableOrderingComposer,
      $$DbVehiclesTableAnnotationComposer,
      $$DbVehiclesTableCreateCompanionBuilder,
      $$DbVehiclesTableUpdateCompanionBuilder,
      (DbVehicle, BaseReferences<_$LocalDatabase, $DbVehiclesTable, DbVehicle>),
      DbVehicle,
      PrefetchHooks Function()
    >;
typedef $$DbPendingMutationsTableCreateCompanionBuilder =
    DbPendingMutationsCompanion Function({
      required String id,
      required String type,
      required String payload,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$DbPendingMutationsTableUpdateCompanionBuilder =
    DbPendingMutationsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DbPendingMutationsTableFilterComposer
    extends Composer<_$LocalDatabase, $DbPendingMutationsTable> {
  $$DbPendingMutationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DbPendingMutationsTableOrderingComposer
    extends Composer<_$LocalDatabase, $DbPendingMutationsTable> {
  $$DbPendingMutationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DbPendingMutationsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $DbPendingMutationsTable> {
  $$DbPendingMutationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DbPendingMutationsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $DbPendingMutationsTable,
          DbPendingMutation,
          $$DbPendingMutationsTableFilterComposer,
          $$DbPendingMutationsTableOrderingComposer,
          $$DbPendingMutationsTableAnnotationComposer,
          $$DbPendingMutationsTableCreateCompanionBuilder,
          $$DbPendingMutationsTableUpdateCompanionBuilder,
          (
            DbPendingMutation,
            BaseReferences<
              _$LocalDatabase,
              $DbPendingMutationsTable,
              DbPendingMutation
            >,
          ),
          DbPendingMutation,
          PrefetchHooks Function()
        > {
  $$DbPendingMutationsTableTableManager(
    _$LocalDatabase db,
    $DbPendingMutationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DbPendingMutationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DbPendingMutationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DbPendingMutationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DbPendingMutationsCompanion(
                id: id,
                type: type,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String payload,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DbPendingMutationsCompanion.insert(
                id: id,
                type: type,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DbPendingMutationsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $DbPendingMutationsTable,
      DbPendingMutation,
      $$DbPendingMutationsTableFilterComposer,
      $$DbPendingMutationsTableOrderingComposer,
      $$DbPendingMutationsTableAnnotationComposer,
      $$DbPendingMutationsTableCreateCompanionBuilder,
      $$DbPendingMutationsTableUpdateCompanionBuilder,
      (
        DbPendingMutation,
        BaseReferences<
          _$LocalDatabase,
          $DbPendingMutationsTable,
          DbPendingMutation
        >,
      ),
      DbPendingMutation,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$DbUserProfilesTableTableManager get dbUserProfiles =>
      $$DbUserProfilesTableTableManager(_db, _db.dbUserProfiles);
  $$DbVehiclesTableTableManager get dbVehicles =>
      $$DbVehiclesTableTableManager(_db, _db.dbVehicles);
  $$DbPendingMutationsTableTableManager get dbPendingMutations =>
      $$DbPendingMutationsTableTableManager(_db, _db.dbPendingMutations);
}
