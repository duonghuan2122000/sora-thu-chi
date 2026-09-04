// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WalletsTable extends Wallets with TableInfo<$WalletsTable, WalletsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  @override
  late final GeneratedColumnWithTypeConverter<WalletType, String> walletType =
      GeneratedColumn<String>(
        'wallet_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WalletType>($WalletsTable.$converterwalletType);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initialBalanceMeta = const VerificationMeta(
    'initialBalance',
  );
  @override
  late final GeneratedColumn<int> initialBalance = GeneratedColumn<int>(
    'initial_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('VND'),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<int> creditLimit = GeneratedColumn<int>(
    'credit_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creditUsedMeta = const VerificationMeta(
    'creditUsed',
  );
  @override
  late final GeneratedColumn<int> creditUsed = GeneratedColumn<int>(
    'credit_used',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statementDateMeta = const VerificationMeta(
    'statementDate',
  );
  @override
  late final GeneratedColumn<DateTime> statementDate =
      GeneratedColumn<DateTime>(
        'statement_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _termMonthsMeta = const VerificationMeta(
    'termMonths',
  );
  @override
  late final GeneratedColumn<int> termMonths = GeneratedColumn<int>(
    'term_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maturityDateMeta = const VerificationMeta(
    'maturityDate',
  );
  @override
  late final GeneratedColumn<DateTime> maturityDate = GeneratedColumn<DateTime>(
    'maturity_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _institutionNameMeta = const VerificationMeta(
    'institutionName',
  );
  @override
  late final GeneratedColumn<String> institutionName = GeneratedColumn<String>(
    'institution_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastDigitsMeta = const VerificationMeta(
    'lastDigits',
  );
  @override
  late final GeneratedColumn<String> lastDigits = GeneratedColumn<String>(
    'last_digits',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    walletType,
    icon,
    color,
    initialBalance,
    balance,
    currency,
    isDefault,
    isHidden,
    sortOrder,
    creditLimit,
    creditUsed,
    statementDate,
    dueDate,
    termMonths,
    maturityDate,
    institutionName,
    lastDigits,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalletsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
        _initialBalanceMeta,
        initialBalance.isAcceptableOrUnknown(
          data['initial_balance']!,
          _initialBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialBalanceMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('credit_used')) {
      context.handle(
        _creditUsedMeta,
        creditUsed.isAcceptableOrUnknown(data['credit_used']!, _creditUsedMeta),
      );
    }
    if (data.containsKey('statement_date')) {
      context.handle(
        _statementDateMeta,
        statementDate.isAcceptableOrUnknown(
          data['statement_date']!,
          _statementDateMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('term_months')) {
      context.handle(
        _termMonthsMeta,
        termMonths.isAcceptableOrUnknown(data['term_months']!, _termMonthsMeta),
      );
    }
    if (data.containsKey('maturity_date')) {
      context.handle(
        _maturityDateMeta,
        maturityDate.isAcceptableOrUnknown(
          data['maturity_date']!,
          _maturityDateMeta,
        ),
      );
    }
    if (data.containsKey('institution_name')) {
      context.handle(
        _institutionNameMeta,
        institutionName.isAcceptableOrUnknown(
          data['institution_name']!,
          _institutionNameMeta,
        ),
      );
    }
    if (data.containsKey('last_digits')) {
      context.handle(
        _lastDigitsMeta,
        lastDigits.isAcceptableOrUnknown(data['last_digits']!, _lastDigitsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalletsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalletsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      walletType: $WalletsTable.$converterwalletType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}wallet_type'],
        )!,
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      initialBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_balance'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit'],
      ),
      creditUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_used'],
      ),
      statementDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}statement_date'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      termMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}term_months'],
      ),
      maturityDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}maturity_date'],
      ),
      institutionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution_name'],
      ),
      lastDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_digits'],
      ),
    );
  }

  @override
  $WalletsTable createAlias(String alias) {
    return $WalletsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WalletType, String, String> $converterwalletType =
      const EnumNameConverter<WalletType>(WalletType.values);
}

class WalletsRow extends DataClass implements Insertable<WalletsRow> {
  final int id;
  final String name;
  final WalletType walletType;
  final String icon;
  final int? color;
  final int initialBalance;
  final int balance;
  final String currency;
  final bool isDefault;
  final bool isHidden;
  final int sortOrder;
  final int? creditLimit;
  final int? creditUsed;
  final DateTime? statementDate;
  final DateTime? dueDate;
  final int? termMonths;
  final DateTime? maturityDate;
  final String? institutionName;
  final String? lastDigits;
  const WalletsRow({
    required this.id,
    required this.name,
    required this.walletType,
    required this.icon,
    this.color,
    required this.initialBalance,
    required this.balance,
    required this.currency,
    required this.isDefault,
    required this.isHidden,
    required this.sortOrder,
    this.creditLimit,
    this.creditUsed,
    this.statementDate,
    this.dueDate,
    this.termMonths,
    this.maturityDate,
    this.institutionName,
    this.lastDigits,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['wallet_type'] = Variable<String>(
        $WalletsTable.$converterwalletType.toSql(walletType),
      );
    }
    map['icon'] = Variable<String>(icon);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['initial_balance'] = Variable<int>(initialBalance);
    map['balance'] = Variable<int>(balance);
    map['currency'] = Variable<String>(currency);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_hidden'] = Variable<bool>(isHidden);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<int>(creditLimit);
    }
    if (!nullToAbsent || creditUsed != null) {
      map['credit_used'] = Variable<int>(creditUsed);
    }
    if (!nullToAbsent || statementDate != null) {
      map['statement_date'] = Variable<DateTime>(statementDate);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || termMonths != null) {
      map['term_months'] = Variable<int>(termMonths);
    }
    if (!nullToAbsent || maturityDate != null) {
      map['maturity_date'] = Variable<DateTime>(maturityDate);
    }
    if (!nullToAbsent || institutionName != null) {
      map['institution_name'] = Variable<String>(institutionName);
    }
    if (!nullToAbsent || lastDigits != null) {
      map['last_digits'] = Variable<String>(lastDigits);
    }
    return map;
  }

  WalletsCompanion toCompanion(bool nullToAbsent) {
    return WalletsCompanion(
      id: Value(id),
      name: Value(name),
      walletType: Value(walletType),
      icon: Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      initialBalance: Value(initialBalance),
      balance: Value(balance),
      currency: Value(currency),
      isDefault: Value(isDefault),
      isHidden: Value(isHidden),
      sortOrder: Value(sortOrder),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      creditUsed: creditUsed == null && nullToAbsent
          ? const Value.absent()
          : Value(creditUsed),
      statementDate: statementDate == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDate),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      termMonths: termMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(termMonths),
      maturityDate: maturityDate == null && nullToAbsent
          ? const Value.absent()
          : Value(maturityDate),
      institutionName: institutionName == null && nullToAbsent
          ? const Value.absent()
          : Value(institutionName),
      lastDigits: lastDigits == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDigits),
    );
  }

  factory WalletsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalletsRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      walletType: $WalletsTable.$converterwalletType.fromJson(
        serializer.fromJson<String>(json['walletType']),
      ),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<int?>(json['color']),
      initialBalance: serializer.fromJson<int>(json['initialBalance']),
      balance: serializer.fromJson<int>(json['balance']),
      currency: serializer.fromJson<String>(json['currency']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      creditLimit: serializer.fromJson<int?>(json['creditLimit']),
      creditUsed: serializer.fromJson<int?>(json['creditUsed']),
      statementDate: serializer.fromJson<DateTime?>(json['statementDate']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      termMonths: serializer.fromJson<int?>(json['termMonths']),
      maturityDate: serializer.fromJson<DateTime?>(json['maturityDate']),
      institutionName: serializer.fromJson<String?>(json['institutionName']),
      lastDigits: serializer.fromJson<String?>(json['lastDigits']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'walletType': serializer.toJson<String>(
        $WalletsTable.$converterwalletType.toJson(walletType),
      ),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<int?>(color),
      'initialBalance': serializer.toJson<int>(initialBalance),
      'balance': serializer.toJson<int>(balance),
      'currency': serializer.toJson<String>(currency),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isHidden': serializer.toJson<bool>(isHidden),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'creditLimit': serializer.toJson<int?>(creditLimit),
      'creditUsed': serializer.toJson<int?>(creditUsed),
      'statementDate': serializer.toJson<DateTime?>(statementDate),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'termMonths': serializer.toJson<int?>(termMonths),
      'maturityDate': serializer.toJson<DateTime?>(maturityDate),
      'institutionName': serializer.toJson<String?>(institutionName),
      'lastDigits': serializer.toJson<String?>(lastDigits),
    };
  }

  WalletsRow copyWith({
    int? id,
    String? name,
    WalletType? walletType,
    String? icon,
    Value<int?> color = const Value.absent(),
    int? initialBalance,
    int? balance,
    String? currency,
    bool? isDefault,
    bool? isHidden,
    int? sortOrder,
    Value<int?> creditLimit = const Value.absent(),
    Value<int?> creditUsed = const Value.absent(),
    Value<DateTime?> statementDate = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    Value<int?> termMonths = const Value.absent(),
    Value<DateTime?> maturityDate = const Value.absent(),
    Value<String?> institutionName = const Value.absent(),
    Value<String?> lastDigits = const Value.absent(),
  }) => WalletsRow(
    id: id ?? this.id,
    name: name ?? this.name,
    walletType: walletType ?? this.walletType,
    icon: icon ?? this.icon,
    color: color.present ? color.value : this.color,
    initialBalance: initialBalance ?? this.initialBalance,
    balance: balance ?? this.balance,
    currency: currency ?? this.currency,
    isDefault: isDefault ?? this.isDefault,
    isHidden: isHidden ?? this.isHidden,
    sortOrder: sortOrder ?? this.sortOrder,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
    creditUsed: creditUsed.present ? creditUsed.value : this.creditUsed,
    statementDate: statementDate.present
        ? statementDate.value
        : this.statementDate,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    termMonths: termMonths.present ? termMonths.value : this.termMonths,
    maturityDate: maturityDate.present ? maturityDate.value : this.maturityDate,
    institutionName: institutionName.present
        ? institutionName.value
        : this.institutionName,
    lastDigits: lastDigits.present ? lastDigits.value : this.lastDigits,
  );
  WalletsRow copyWithCompanion(WalletsCompanion data) {
    return WalletsRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      walletType: data.walletType.present
          ? data.walletType.value
          : this.walletType,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      balance: data.balance.present ? data.balance.value : this.balance,
      currency: data.currency.present ? data.currency.value : this.currency,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      creditUsed: data.creditUsed.present
          ? data.creditUsed.value
          : this.creditUsed,
      statementDate: data.statementDate.present
          ? data.statementDate.value
          : this.statementDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      termMonths: data.termMonths.present
          ? data.termMonths.value
          : this.termMonths,
      maturityDate: data.maturityDate.present
          ? data.maturityDate.value
          : this.maturityDate,
      institutionName: data.institutionName.present
          ? data.institutionName.value
          : this.institutionName,
      lastDigits: data.lastDigits.present
          ? data.lastDigits.value
          : this.lastDigits,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalletsRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('walletType: $walletType, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('balance: $balance, ')
          ..write('currency: $currency, ')
          ..write('isDefault: $isDefault, ')
          ..write('isHidden: $isHidden, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('creditUsed: $creditUsed, ')
          ..write('statementDate: $statementDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('termMonths: $termMonths, ')
          ..write('maturityDate: $maturityDate, ')
          ..write('institutionName: $institutionName, ')
          ..write('lastDigits: $lastDigits')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    walletType,
    icon,
    color,
    initialBalance,
    balance,
    currency,
    isDefault,
    isHidden,
    sortOrder,
    creditLimit,
    creditUsed,
    statementDate,
    dueDate,
    termMonths,
    maturityDate,
    institutionName,
    lastDigits,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletsRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.walletType == this.walletType &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.initialBalance == this.initialBalance &&
          other.balance == this.balance &&
          other.currency == this.currency &&
          other.isDefault == this.isDefault &&
          other.isHidden == this.isHidden &&
          other.sortOrder == this.sortOrder &&
          other.creditLimit == this.creditLimit &&
          other.creditUsed == this.creditUsed &&
          other.statementDate == this.statementDate &&
          other.dueDate == this.dueDate &&
          other.termMonths == this.termMonths &&
          other.maturityDate == this.maturityDate &&
          other.institutionName == this.institutionName &&
          other.lastDigits == this.lastDigits);
}

class WalletsCompanion extends UpdateCompanion<WalletsRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<WalletType> walletType;
  final Value<String> icon;
  final Value<int?> color;
  final Value<int> initialBalance;
  final Value<int> balance;
  final Value<String> currency;
  final Value<bool> isDefault;
  final Value<bool> isHidden;
  final Value<int> sortOrder;
  final Value<int?> creditLimit;
  final Value<int?> creditUsed;
  final Value<DateTime?> statementDate;
  final Value<DateTime?> dueDate;
  final Value<int?> termMonths;
  final Value<DateTime?> maturityDate;
  final Value<String?> institutionName;
  final Value<String?> lastDigits;
  const WalletsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.walletType = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.balance = const Value.absent(),
    this.currency = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.creditUsed = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.termMonths = const Value.absent(),
    this.maturityDate = const Value.absent(),
    this.institutionName = const Value.absent(),
    this.lastDigits = const Value.absent(),
  });
  WalletsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required WalletType walletType,
    required String icon,
    this.color = const Value.absent(),
    required int initialBalance,
    required int balance,
    this.currency = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.creditUsed = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.termMonths = const Value.absent(),
    this.maturityDate = const Value.absent(),
    this.institutionName = const Value.absent(),
    this.lastDigits = const Value.absent(),
  }) : name = Value(name),
       walletType = Value(walletType),
       icon = Value(icon),
       initialBalance = Value(initialBalance),
       balance = Value(balance);
  static Insertable<WalletsRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? walletType,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<int>? initialBalance,
    Expression<int>? balance,
    Expression<String>? currency,
    Expression<bool>? isDefault,
    Expression<bool>? isHidden,
    Expression<int>? sortOrder,
    Expression<int>? creditLimit,
    Expression<int>? creditUsed,
    Expression<DateTime>? statementDate,
    Expression<DateTime>? dueDate,
    Expression<int>? termMonths,
    Expression<DateTime>? maturityDate,
    Expression<String>? institutionName,
    Expression<String>? lastDigits,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (walletType != null) 'wallet_type': walletType,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (balance != null) 'balance': balance,
      if (currency != null) 'currency': currency,
      if (isDefault != null) 'is_default': isDefault,
      if (isHidden != null) 'is_hidden': isHidden,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (creditUsed != null) 'credit_used': creditUsed,
      if (statementDate != null) 'statement_date': statementDate,
      if (dueDate != null) 'due_date': dueDate,
      if (termMonths != null) 'term_months': termMonths,
      if (maturityDate != null) 'maturity_date': maturityDate,
      if (institutionName != null) 'institution_name': institutionName,
      if (lastDigits != null) 'last_digits': lastDigits,
    });
  }

  WalletsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<WalletType>? walletType,
    Value<String>? icon,
    Value<int?>? color,
    Value<int>? initialBalance,
    Value<int>? balance,
    Value<String>? currency,
    Value<bool>? isDefault,
    Value<bool>? isHidden,
    Value<int>? sortOrder,
    Value<int?>? creditLimit,
    Value<int?>? creditUsed,
    Value<DateTime?>? statementDate,
    Value<DateTime?>? dueDate,
    Value<int?>? termMonths,
    Value<DateTime?>? maturityDate,
    Value<String?>? institutionName,
    Value<String?>? lastDigits,
  }) {
    return WalletsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      walletType: walletType ?? this.walletType,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      initialBalance: initialBalance ?? this.initialBalance,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isDefault: isDefault ?? this.isDefault,
      isHidden: isHidden ?? this.isHidden,
      sortOrder: sortOrder ?? this.sortOrder,
      creditLimit: creditLimit ?? this.creditLimit,
      creditUsed: creditUsed ?? this.creditUsed,
      statementDate: statementDate ?? this.statementDate,
      dueDate: dueDate ?? this.dueDate,
      termMonths: termMonths ?? this.termMonths,
      maturityDate: maturityDate ?? this.maturityDate,
      institutionName: institutionName ?? this.institutionName,
      lastDigits: lastDigits ?? this.lastDigits,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (walletType.present) {
      map['wallet_type'] = Variable<String>(
        $WalletsTable.$converterwalletType.toSql(walletType.value),
      );
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<int>(initialBalance.value);
    }
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<int>(creditLimit.value);
    }
    if (creditUsed.present) {
      map['credit_used'] = Variable<int>(creditUsed.value);
    }
    if (statementDate.present) {
      map['statement_date'] = Variable<DateTime>(statementDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (termMonths.present) {
      map['term_months'] = Variable<int>(termMonths.value);
    }
    if (maturityDate.present) {
      map['maturity_date'] = Variable<DateTime>(maturityDate.value);
    }
    if (institutionName.present) {
      map['institution_name'] = Variable<String>(institutionName.value);
    }
    if (lastDigits.present) {
      map['last_digits'] = Variable<String>(lastDigits.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('walletType: $walletType, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('balance: $balance, ')
          ..write('currency: $currency, ')
          ..write('isDefault: $isDefault, ')
          ..write('isHidden: $isHidden, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('creditUsed: $creditUsed, ')
          ..write('statementDate: $statementDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('termMonths: $termMonths, ')
          ..write('maturityDate: $maturityDate, ')
          ..write('institutionName: $institutionName, ')
          ..write('lastDigits: $lastDigits')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WalletsTable wallets = $WalletsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [wallets];
}

typedef $$WalletsTableCreateCompanionBuilder =
    WalletsCompanion Function({
      Value<int> id,
      required String name,
      required WalletType walletType,
      required String icon,
      Value<int?> color,
      required int initialBalance,
      required int balance,
      Value<String> currency,
      Value<bool> isDefault,
      Value<bool> isHidden,
      Value<int> sortOrder,
      Value<int?> creditLimit,
      Value<int?> creditUsed,
      Value<DateTime?> statementDate,
      Value<DateTime?> dueDate,
      Value<int?> termMonths,
      Value<DateTime?> maturityDate,
      Value<String?> institutionName,
      Value<String?> lastDigits,
    });
typedef $$WalletsTableUpdateCompanionBuilder =
    WalletsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<WalletType> walletType,
      Value<String> icon,
      Value<int?> color,
      Value<int> initialBalance,
      Value<int> balance,
      Value<String> currency,
      Value<bool> isDefault,
      Value<bool> isHidden,
      Value<int> sortOrder,
      Value<int?> creditLimit,
      Value<int?> creditUsed,
      Value<DateTime?> statementDate,
      Value<DateTime?> dueDate,
      Value<int?> termMonths,
      Value<DateTime?> maturityDate,
      Value<String?> institutionName,
      Value<String?> lastDigits,
    });

class $$WalletsTableFilterComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WalletType, WalletType, String>
  get walletType => $composableBuilder(
    column: $table.walletType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditUsed => $composableBuilder(
    column: $table.creditUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get statementDate => $composableBuilder(
    column: $table.statementDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get termMonths => $composableBuilder(
    column: $table.termMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get maturityDate => $composableBuilder(
    column: $table.maturityDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get institutionName => $composableBuilder(
    column: $table.institutionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastDigits => $composableBuilder(
    column: $table.lastDigits,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WalletsTableOrderingComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get walletType => $composableBuilder(
    column: $table.walletType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditUsed => $composableBuilder(
    column: $table.creditUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get statementDate => $composableBuilder(
    column: $table.statementDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get termMonths => $composableBuilder(
    column: $table.termMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get maturityDate => $composableBuilder(
    column: $table.maturityDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get institutionName => $composableBuilder(
    column: $table.institutionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastDigits => $composableBuilder(
    column: $table.lastDigits,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WalletsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WalletType, String> get walletType =>
      $composableBuilder(
        column: $table.walletType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get creditUsed => $composableBuilder(
    column: $table.creditUsed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get statementDate => $composableBuilder(
    column: $table.statementDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get termMonths => $composableBuilder(
    column: $table.termMonths,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get maturityDate => $composableBuilder(
    column: $table.maturityDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get institutionName => $composableBuilder(
    column: $table.institutionName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastDigits => $composableBuilder(
    column: $table.lastDigits,
    builder: (column) => column,
  );
}

class $$WalletsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WalletsTable,
          WalletsRow,
          $$WalletsTableFilterComposer,
          $$WalletsTableOrderingComposer,
          $$WalletsTableAnnotationComposer,
          $$WalletsTableCreateCompanionBuilder,
          $$WalletsTableUpdateCompanionBuilder,
          (
            WalletsRow,
            BaseReferences<_$AppDatabase, $WalletsTable, WalletsRow>,
          ),
          WalletsRow,
          PrefetchHooks Function()
        > {
  $$WalletsTableTableManager(_$AppDatabase db, $WalletsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<WalletType> walletType = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<int> initialBalance = const Value.absent(),
                Value<int> balance = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int?> creditLimit = const Value.absent(),
                Value<int?> creditUsed = const Value.absent(),
                Value<DateTime?> statementDate = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<int?> termMonths = const Value.absent(),
                Value<DateTime?> maturityDate = const Value.absent(),
                Value<String?> institutionName = const Value.absent(),
                Value<String?> lastDigits = const Value.absent(),
              }) => WalletsCompanion(
                id: id,
                name: name,
                walletType: walletType,
                icon: icon,
                color: color,
                initialBalance: initialBalance,
                balance: balance,
                currency: currency,
                isDefault: isDefault,
                isHidden: isHidden,
                sortOrder: sortOrder,
                creditLimit: creditLimit,
                creditUsed: creditUsed,
                statementDate: statementDate,
                dueDate: dueDate,
                termMonths: termMonths,
                maturityDate: maturityDate,
                institutionName: institutionName,
                lastDigits: lastDigits,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required WalletType walletType,
                required String icon,
                Value<int?> color = const Value.absent(),
                required int initialBalance,
                required int balance,
                Value<String> currency = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int?> creditLimit = const Value.absent(),
                Value<int?> creditUsed = const Value.absent(),
                Value<DateTime?> statementDate = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<int?> termMonths = const Value.absent(),
                Value<DateTime?> maturityDate = const Value.absent(),
                Value<String?> institutionName = const Value.absent(),
                Value<String?> lastDigits = const Value.absent(),
              }) => WalletsCompanion.insert(
                id: id,
                name: name,
                walletType: walletType,
                icon: icon,
                color: color,
                initialBalance: initialBalance,
                balance: balance,
                currency: currency,
                isDefault: isDefault,
                isHidden: isHidden,
                sortOrder: sortOrder,
                creditLimit: creditLimit,
                creditUsed: creditUsed,
                statementDate: statementDate,
                dueDate: dueDate,
                termMonths: termMonths,
                maturityDate: maturityDate,
                institutionName: institutionName,
                lastDigits: lastDigits,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WalletsTable, WalletsRow>(table),
                  BaseReferences<_$AppDatabase, $WalletsTable, WalletsRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WalletsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WalletsTable,
      WalletsRow,
      $$WalletsTableFilterComposer,
      $$WalletsTableOrderingComposer,
      $$WalletsTableAnnotationComposer,
      $$WalletsTableCreateCompanionBuilder,
      $$WalletsTableUpdateCompanionBuilder,
      (WalletsRow, BaseReferences<_$AppDatabase, $WalletsTable, WalletsRow>),
      WalletsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db, _db.wallets);
}
