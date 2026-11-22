// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idComisionMeta = const VerificationMeta(
    'idComision',
  );
  @override
  late final GeneratedColumn<String> idComision = GeneratedColumn<String>(
    'id_comision',
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
  static const VerificationMeta _subjectCodeMeta = const VerificationMeta(
    'subjectCode',
  );
  @override
  late final GeneratedColumn<String> subjectCode = GeneratedColumn<String>(
    'subject_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _commissionCodeMeta = const VerificationMeta(
    'commissionCode',
  );
  @override
  late final GeneratedColumn<String> commissionCode = GeneratedColumn<String>(
    'commission_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _roleLabelMeta = const VerificationMeta(
    'roleLabel',
  );
  @override
  late final GeneratedColumn<String> roleLabel = GeneratedColumn<String>(
    'role_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isHiddenInMielMeta = const VerificationMeta(
    'isHiddenInMiel',
  );
  @override
  late final GeneratedColumn<bool> isHiddenInMiel = GeneratedColumn<bool>(
    'is_hidden_in_miel',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden_in_miel" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _mutedMeta = const VerificationMeta('muted');
  @override
  late final GeneratedColumn<bool> muted = GeneratedColumn<bool>(
    'muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notifyContenidosMeta = const VerificationMeta(
    'notifyContenidos',
  );
  @override
  late final GeneratedColumn<bool> notifyContenidos = GeneratedColumn<bool>(
    'notify_contenidos',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_contenidos" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifyPortafolioMeta = const VerificationMeta(
    'notifyPortafolio',
  );
  @override
  late final GeneratedColumn<bool> notifyPortafolio = GeneratedColumn<bool>(
    'notify_portafolio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_portafolio" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifyMensajeriaMeta = const VerificationMeta(
    'notifyMensajeria',
  );
  @override
  late final GeneratedColumn<bool> notifyMensajeria = GeneratedColumn<bool>(
    'notify_mensajeria',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_mensajeria" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifyForosMeta = const VerificationMeta(
    'notifyForos',
  );
  @override
  late final GeneratedColumn<bool> notifyForos = GeneratedColumn<bool>(
    'notify_foros',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_foros" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifyEvaluacionMeta = const VerificationMeta(
    'notifyEvaluacion',
  );
  @override
  late final GeneratedColumn<bool> notifyEvaluacion = GeneratedColumn<bool>(
    'notify_evaluacion',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_evaluacion" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _hasContenidosMeta = const VerificationMeta(
    'hasContenidos',
  );
  @override
  late final GeneratedColumn<bool> hasContenidos = GeneratedColumn<bool>(
    'has_contenidos',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_contenidos" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _hasAutoguiaMeta = const VerificationMeta(
    'hasAutoguia',
  );
  @override
  late final GeneratedColumn<bool> hasAutoguia = GeneratedColumn<bool>(
    'has_autoguia',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_autoguia" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasPortafolioMeta = const VerificationMeta(
    'hasPortafolio',
  );
  @override
  late final GeneratedColumn<bool> hasPortafolio = GeneratedColumn<bool>(
    'has_portafolio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_portafolio" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasMensajeriaMeta = const VerificationMeta(
    'hasMensajeria',
  );
  @override
  late final GeneratedColumn<bool> hasMensajeria = GeneratedColumn<bool>(
    'has_mensajeria',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_mensajeria" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _hasForoMeta = const VerificationMeta(
    'hasForo',
  );
  @override
  late final GeneratedColumn<bool> hasForo = GeneratedColumn<bool>(
    'has_foro',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_foro" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _hasChatMeta = const VerificationMeta(
    'hasChat',
  );
  @override
  late final GeneratedColumn<bool> hasChat = GeneratedColumn<bool>(
    'has_chat',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_chat" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasEncuestasMeta = const VerificationMeta(
    'hasEncuestas',
  );
  @override
  late final GeneratedColumn<bool> hasEncuestas = GeneratedColumn<bool>(
    'has_encuestas',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_encuestas" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasEvaluacionMeta = const VerificationMeta(
    'hasEvaluacion',
  );
  @override
  late final GeneratedColumn<bool> hasEvaluacion = GeneratedColumn<bool>(
    'has_evaluacion',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_evaluacion" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastContenidosBadgeMeta =
      const VerificationMeta('lastContenidosBadge');
  @override
  late final GeneratedColumn<int> lastContenidosBadge = GeneratedColumn<int>(
    'last_contenidos_badge',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastMensajesBadgeMeta = const VerificationMeta(
    'lastMensajesBadge',
  );
  @override
  late final GeneratedColumn<int> lastMensajesBadge = GeneratedColumn<int>(
    'last_mensajes_badge',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastForoBadgeMeta = const VerificationMeta(
    'lastForoBadge',
  );
  @override
  late final GeneratedColumn<int> lastForoBadge = GeneratedColumn<int>(
    'last_foro_badge',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _localVisibilityOverrideMeta =
      const VerificationMeta('localVisibilityOverride');
  @override
  late final GeneratedColumn<int> localVisibilityOverride =
      GeneratedColumn<int>(
        'local_visibility_override',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idComision,
    name,
    subjectCode,
    commissionCode,
    roleLabel,
    isHiddenInMiel,
    muted,
    notifyContenidos,
    notifyPortafolio,
    notifyMensajeria,
    notifyForos,
    notifyEvaluacion,
    hasContenidos,
    hasAutoguia,
    hasPortafolio,
    hasMensajeria,
    hasForo,
    hasChat,
    hasEncuestas,
    hasEvaluacion,
    lastContenidosBadge,
    lastMensajesBadge,
    lastForoBadge,
    sortOrder,
    localVisibilityOverride,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subject> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_comision')) {
      context.handle(
        _idComisionMeta,
        idComision.isAcceptableOrUnknown(data['id_comision']!, _idComisionMeta),
      );
    } else if (isInserting) {
      context.missing(_idComisionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('subject_code')) {
      context.handle(
        _subjectCodeMeta,
        subjectCode.isAcceptableOrUnknown(
          data['subject_code']!,
          _subjectCodeMeta,
        ),
      );
    }
    if (data.containsKey('commission_code')) {
      context.handle(
        _commissionCodeMeta,
        commissionCode.isAcceptableOrUnknown(
          data['commission_code']!,
          _commissionCodeMeta,
        ),
      );
    }
    if (data.containsKey('role_label')) {
      context.handle(
        _roleLabelMeta,
        roleLabel.isAcceptableOrUnknown(data['role_label']!, _roleLabelMeta),
      );
    }
    if (data.containsKey('is_hidden_in_miel')) {
      context.handle(
        _isHiddenInMielMeta,
        isHiddenInMiel.isAcceptableOrUnknown(
          data['is_hidden_in_miel']!,
          _isHiddenInMielMeta,
        ),
      );
    }
    if (data.containsKey('muted')) {
      context.handle(
        _mutedMeta,
        muted.isAcceptableOrUnknown(data['muted']!, _mutedMeta),
      );
    }
    if (data.containsKey('notify_contenidos')) {
      context.handle(
        _notifyContenidosMeta,
        notifyContenidos.isAcceptableOrUnknown(
          data['notify_contenidos']!,
          _notifyContenidosMeta,
        ),
      );
    }
    if (data.containsKey('notify_portafolio')) {
      context.handle(
        _notifyPortafolioMeta,
        notifyPortafolio.isAcceptableOrUnknown(
          data['notify_portafolio']!,
          _notifyPortafolioMeta,
        ),
      );
    }
    if (data.containsKey('notify_mensajeria')) {
      context.handle(
        _notifyMensajeriaMeta,
        notifyMensajeria.isAcceptableOrUnknown(
          data['notify_mensajeria']!,
          _notifyMensajeriaMeta,
        ),
      );
    }
    if (data.containsKey('notify_foros')) {
      context.handle(
        _notifyForosMeta,
        notifyForos.isAcceptableOrUnknown(
          data['notify_foros']!,
          _notifyForosMeta,
        ),
      );
    }
    if (data.containsKey('notify_evaluacion')) {
      context.handle(
        _notifyEvaluacionMeta,
        notifyEvaluacion.isAcceptableOrUnknown(
          data['notify_evaluacion']!,
          _notifyEvaluacionMeta,
        ),
      );
    }
    if (data.containsKey('has_contenidos')) {
      context.handle(
        _hasContenidosMeta,
        hasContenidos.isAcceptableOrUnknown(
          data['has_contenidos']!,
          _hasContenidosMeta,
        ),
      );
    }
    if (data.containsKey('has_autoguia')) {
      context.handle(
        _hasAutoguiaMeta,
        hasAutoguia.isAcceptableOrUnknown(
          data['has_autoguia']!,
          _hasAutoguiaMeta,
        ),
      );
    }
    if (data.containsKey('has_portafolio')) {
      context.handle(
        _hasPortafolioMeta,
        hasPortafolio.isAcceptableOrUnknown(
          data['has_portafolio']!,
          _hasPortafolioMeta,
        ),
      );
    }
    if (data.containsKey('has_mensajeria')) {
      context.handle(
        _hasMensajeriaMeta,
        hasMensajeria.isAcceptableOrUnknown(
          data['has_mensajeria']!,
          _hasMensajeriaMeta,
        ),
      );
    }
    if (data.containsKey('has_foro')) {
      context.handle(
        _hasForoMeta,
        hasForo.isAcceptableOrUnknown(data['has_foro']!, _hasForoMeta),
      );
    }
    if (data.containsKey('has_chat')) {
      context.handle(
        _hasChatMeta,
        hasChat.isAcceptableOrUnknown(data['has_chat']!, _hasChatMeta),
      );
    }
    if (data.containsKey('has_encuestas')) {
      context.handle(
        _hasEncuestasMeta,
        hasEncuestas.isAcceptableOrUnknown(
          data['has_encuestas']!,
          _hasEncuestasMeta,
        ),
      );
    }
    if (data.containsKey('has_evaluacion')) {
      context.handle(
        _hasEvaluacionMeta,
        hasEvaluacion.isAcceptableOrUnknown(
          data['has_evaluacion']!,
          _hasEvaluacionMeta,
        ),
      );
    }
    if (data.containsKey('last_contenidos_badge')) {
      context.handle(
        _lastContenidosBadgeMeta,
        lastContenidosBadge.isAcceptableOrUnknown(
          data['last_contenidos_badge']!,
          _lastContenidosBadgeMeta,
        ),
      );
    }
    if (data.containsKey('last_mensajes_badge')) {
      context.handle(
        _lastMensajesBadgeMeta,
        lastMensajesBadge.isAcceptableOrUnknown(
          data['last_mensajes_badge']!,
          _lastMensajesBadgeMeta,
        ),
      );
    }
    if (data.containsKey('last_foro_badge')) {
      context.handle(
        _lastForoBadgeMeta,
        lastForoBadge.isAcceptableOrUnknown(
          data['last_foro_badge']!,
          _lastForoBadgeMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('local_visibility_override')) {
      context.handle(
        _localVisibilityOverrideMeta,
        localVisibilityOverride.isAcceptableOrUnknown(
          data['local_visibility_override']!,
          _localVisibilityOverrideMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idComision};
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      idComision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_comision'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      subjectCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_code'],
      )!,
      commissionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commission_code'],
      )!,
      roleLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_label'],
      )!,
      isHiddenInMiel: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden_in_miel'],
      )!,
      muted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}muted'],
      )!,
      notifyContenidos: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_contenidos'],
      )!,
      notifyPortafolio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_portafolio'],
      )!,
      notifyMensajeria: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_mensajeria'],
      )!,
      notifyForos: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_foros'],
      )!,
      notifyEvaluacion: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_evaluacion'],
      )!,
      hasContenidos: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_contenidos'],
      )!,
      hasAutoguia: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_autoguia'],
      )!,
      hasPortafolio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_portafolio'],
      )!,
      hasMensajeria: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_mensajeria'],
      )!,
      hasForo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_foro'],
      )!,
      hasChat: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_chat'],
      )!,
      hasEncuestas: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_encuestas'],
      )!,
      hasEvaluacion: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_evaluacion'],
      )!,
      lastContenidosBadge: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_contenidos_badge'],
      )!,
      lastMensajesBadge: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_mensajes_badge'],
      )!,
      lastForoBadge: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_foro_badge'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      localVisibilityOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_visibility_override'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class Subject extends DataClass implements Insertable<Subject> {
  final String idComision;
  final String name;
  final String subjectCode;
  final String commissionCode;
  final String roleLabel;
  final bool isHiddenInMiel;
  final bool muted;
  final bool notifyContenidos;
  final bool notifyPortafolio;
  final bool notifyMensajeria;
  final bool notifyForos;
  final bool notifyEvaluacion;
  final bool hasContenidos;
  final bool hasAutoguia;
  final bool hasPortafolio;
  final bool hasMensajeria;
  final bool hasForo;
  final bool hasChat;
  final bool hasEncuestas;
  final bool hasEvaluacion;
  final int lastContenidosBadge;
  final int lastMensajesBadge;
  final int lastForoBadge;
  final int sortOrder;
  final int localVisibilityOverride;
  final DateTime? lastSyncedAt;
  const Subject({
    required this.idComision,
    required this.name,
    required this.subjectCode,
    required this.commissionCode,
    required this.roleLabel,
    required this.isHiddenInMiel,
    required this.muted,
    required this.notifyContenidos,
    required this.notifyPortafolio,
    required this.notifyMensajeria,
    required this.notifyForos,
    required this.notifyEvaluacion,
    required this.hasContenidos,
    required this.hasAutoguia,
    required this.hasPortafolio,
    required this.hasMensajeria,
    required this.hasForo,
    required this.hasChat,
    required this.hasEncuestas,
    required this.hasEvaluacion,
    required this.lastContenidosBadge,
    required this.lastMensajesBadge,
    required this.lastForoBadge,
    required this.sortOrder,
    required this.localVisibilityOverride,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_comision'] = Variable<String>(idComision);
    map['name'] = Variable<String>(name);
    map['subject_code'] = Variable<String>(subjectCode);
    map['commission_code'] = Variable<String>(commissionCode);
    map['role_label'] = Variable<String>(roleLabel);
    map['is_hidden_in_miel'] = Variable<bool>(isHiddenInMiel);
    map['muted'] = Variable<bool>(muted);
    map['notify_contenidos'] = Variable<bool>(notifyContenidos);
    map['notify_portafolio'] = Variable<bool>(notifyPortafolio);
    map['notify_mensajeria'] = Variable<bool>(notifyMensajeria);
    map['notify_foros'] = Variable<bool>(notifyForos);
    map['notify_evaluacion'] = Variable<bool>(notifyEvaluacion);
    map['has_contenidos'] = Variable<bool>(hasContenidos);
    map['has_autoguia'] = Variable<bool>(hasAutoguia);
    map['has_portafolio'] = Variable<bool>(hasPortafolio);
    map['has_mensajeria'] = Variable<bool>(hasMensajeria);
    map['has_foro'] = Variable<bool>(hasForo);
    map['has_chat'] = Variable<bool>(hasChat);
    map['has_encuestas'] = Variable<bool>(hasEncuestas);
    map['has_evaluacion'] = Variable<bool>(hasEvaluacion);
    map['last_contenidos_badge'] = Variable<int>(lastContenidosBadge);
    map['last_mensajes_badge'] = Variable<int>(lastMensajesBadge);
    map['last_foro_badge'] = Variable<int>(lastForoBadge);
    map['sort_order'] = Variable<int>(sortOrder);
    map['local_visibility_override'] = Variable<int>(localVisibilityOverride);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      idComision: Value(idComision),
      name: Value(name),
      subjectCode: Value(subjectCode),
      commissionCode: Value(commissionCode),
      roleLabel: Value(roleLabel),
      isHiddenInMiel: Value(isHiddenInMiel),
      muted: Value(muted),
      notifyContenidos: Value(notifyContenidos),
      notifyPortafolio: Value(notifyPortafolio),
      notifyMensajeria: Value(notifyMensajeria),
      notifyForos: Value(notifyForos),
      notifyEvaluacion: Value(notifyEvaluacion),
      hasContenidos: Value(hasContenidos),
      hasAutoguia: Value(hasAutoguia),
      hasPortafolio: Value(hasPortafolio),
      hasMensajeria: Value(hasMensajeria),
      hasForo: Value(hasForo),
      hasChat: Value(hasChat),
      hasEncuestas: Value(hasEncuestas),
      hasEvaluacion: Value(hasEvaluacion),
      lastContenidosBadge: Value(lastContenidosBadge),
      lastMensajesBadge: Value(lastMensajesBadge),
      lastForoBadge: Value(lastForoBadge),
      sortOrder: Value(sortOrder),
      localVisibilityOverride: Value(localVisibilityOverride),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory Subject.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      idComision: serializer.fromJson<String>(json['idComision']),
      name: serializer.fromJson<String>(json['name']),
      subjectCode: serializer.fromJson<String>(json['subjectCode']),
      commissionCode: serializer.fromJson<String>(json['commissionCode']),
      roleLabel: serializer.fromJson<String>(json['roleLabel']),
      isHiddenInMiel: serializer.fromJson<bool>(json['isHiddenInMiel']),
      muted: serializer.fromJson<bool>(json['muted']),
      notifyContenidos: serializer.fromJson<bool>(json['notifyContenidos']),
      notifyPortafolio: serializer.fromJson<bool>(json['notifyPortafolio']),
      notifyMensajeria: serializer.fromJson<bool>(json['notifyMensajeria']),
      notifyForos: serializer.fromJson<bool>(json['notifyForos']),
      notifyEvaluacion: serializer.fromJson<bool>(json['notifyEvaluacion']),
      hasContenidos: serializer.fromJson<bool>(json['hasContenidos']),
      hasAutoguia: serializer.fromJson<bool>(json['hasAutoguia']),
      hasPortafolio: serializer.fromJson<bool>(json['hasPortafolio']),
      hasMensajeria: serializer.fromJson<bool>(json['hasMensajeria']),
      hasForo: serializer.fromJson<bool>(json['hasForo']),
      hasChat: serializer.fromJson<bool>(json['hasChat']),
      hasEncuestas: serializer.fromJson<bool>(json['hasEncuestas']),
      hasEvaluacion: serializer.fromJson<bool>(json['hasEvaluacion']),
      lastContenidosBadge: serializer.fromJson<int>(
        json['lastContenidosBadge'],
      ),
      lastMensajesBadge: serializer.fromJson<int>(json['lastMensajesBadge']),
      lastForoBadge: serializer.fromJson<int>(json['lastForoBadge']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      localVisibilityOverride: serializer.fromJson<int>(
        json['localVisibilityOverride'],
      ),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idComision': serializer.toJson<String>(idComision),
      'name': serializer.toJson<String>(name),
      'subjectCode': serializer.toJson<String>(subjectCode),
      'commissionCode': serializer.toJson<String>(commissionCode),
      'roleLabel': serializer.toJson<String>(roleLabel),
      'isHiddenInMiel': serializer.toJson<bool>(isHiddenInMiel),
      'muted': serializer.toJson<bool>(muted),
      'notifyContenidos': serializer.toJson<bool>(notifyContenidos),
      'notifyPortafolio': serializer.toJson<bool>(notifyPortafolio),
      'notifyMensajeria': serializer.toJson<bool>(notifyMensajeria),
      'notifyForos': serializer.toJson<bool>(notifyForos),
      'notifyEvaluacion': serializer.toJson<bool>(notifyEvaluacion),
      'hasContenidos': serializer.toJson<bool>(hasContenidos),
      'hasAutoguia': serializer.toJson<bool>(hasAutoguia),
      'hasPortafolio': serializer.toJson<bool>(hasPortafolio),
      'hasMensajeria': serializer.toJson<bool>(hasMensajeria),
      'hasForo': serializer.toJson<bool>(hasForo),
      'hasChat': serializer.toJson<bool>(hasChat),
      'hasEncuestas': serializer.toJson<bool>(hasEncuestas),
      'hasEvaluacion': serializer.toJson<bool>(hasEvaluacion),
      'lastContenidosBadge': serializer.toJson<int>(lastContenidosBadge),
      'lastMensajesBadge': serializer.toJson<int>(lastMensajesBadge),
      'lastForoBadge': serializer.toJson<int>(lastForoBadge),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'localVisibilityOverride': serializer.toJson<int>(
        localVisibilityOverride,
      ),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  Subject copyWith({
    String? idComision,
    String? name,
    String? subjectCode,
    String? commissionCode,
    String? roleLabel,
    bool? isHiddenInMiel,
    bool? muted,
    bool? notifyContenidos,
    bool? notifyPortafolio,
    bool? notifyMensajeria,
    bool? notifyForos,
    bool? notifyEvaluacion,
    bool? hasContenidos,
    bool? hasAutoguia,
    bool? hasPortafolio,
    bool? hasMensajeria,
    bool? hasForo,
    bool? hasChat,
    bool? hasEncuestas,
    bool? hasEvaluacion,
    int? lastContenidosBadge,
    int? lastMensajesBadge,
    int? lastForoBadge,
    int? sortOrder,
    int? localVisibilityOverride,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => Subject(
    idComision: idComision ?? this.idComision,
    name: name ?? this.name,
    subjectCode: subjectCode ?? this.subjectCode,
    commissionCode: commissionCode ?? this.commissionCode,
    roleLabel: roleLabel ?? this.roleLabel,
    isHiddenInMiel: isHiddenInMiel ?? this.isHiddenInMiel,
    muted: muted ?? this.muted,
    notifyContenidos: notifyContenidos ?? this.notifyContenidos,
    notifyPortafolio: notifyPortafolio ?? this.notifyPortafolio,
    notifyMensajeria: notifyMensajeria ?? this.notifyMensajeria,
    notifyForos: notifyForos ?? this.notifyForos,
    notifyEvaluacion: notifyEvaluacion ?? this.notifyEvaluacion,
    hasContenidos: hasContenidos ?? this.hasContenidos,
    hasAutoguia: hasAutoguia ?? this.hasAutoguia,
    hasPortafolio: hasPortafolio ?? this.hasPortafolio,
    hasMensajeria: hasMensajeria ?? this.hasMensajeria,
    hasForo: hasForo ?? this.hasForo,
    hasChat: hasChat ?? this.hasChat,
    hasEncuestas: hasEncuestas ?? this.hasEncuestas,
    hasEvaluacion: hasEvaluacion ?? this.hasEvaluacion,
    lastContenidosBadge: lastContenidosBadge ?? this.lastContenidosBadge,
    lastMensajesBadge: lastMensajesBadge ?? this.lastMensajesBadge,
    lastForoBadge: lastForoBadge ?? this.lastForoBadge,
    sortOrder: sortOrder ?? this.sortOrder,
    localVisibilityOverride:
        localVisibilityOverride ?? this.localVisibilityOverride,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
      idComision: data.idComision.present
          ? data.idComision.value
          : this.idComision,
      name: data.name.present ? data.name.value : this.name,
      subjectCode: data.subjectCode.present
          ? data.subjectCode.value
          : this.subjectCode,
      commissionCode: data.commissionCode.present
          ? data.commissionCode.value
          : this.commissionCode,
      roleLabel: data.roleLabel.present ? data.roleLabel.value : this.roleLabel,
      isHiddenInMiel: data.isHiddenInMiel.present
          ? data.isHiddenInMiel.value
          : this.isHiddenInMiel,
      muted: data.muted.present ? data.muted.value : this.muted,
      notifyContenidos: data.notifyContenidos.present
          ? data.notifyContenidos.value
          : this.notifyContenidos,
      notifyPortafolio: data.notifyPortafolio.present
          ? data.notifyPortafolio.value
          : this.notifyPortafolio,
      notifyMensajeria: data.notifyMensajeria.present
          ? data.notifyMensajeria.value
          : this.notifyMensajeria,
      notifyForos: data.notifyForos.present
          ? data.notifyForos.value
          : this.notifyForos,
      notifyEvaluacion: data.notifyEvaluacion.present
          ? data.notifyEvaluacion.value
          : this.notifyEvaluacion,
      hasContenidos: data.hasContenidos.present
          ? data.hasContenidos.value
          : this.hasContenidos,
      hasAutoguia: data.hasAutoguia.present
          ? data.hasAutoguia.value
          : this.hasAutoguia,
      hasPortafolio: data.hasPortafolio.present
          ? data.hasPortafolio.value
          : this.hasPortafolio,
      hasMensajeria: data.hasMensajeria.present
          ? data.hasMensajeria.value
          : this.hasMensajeria,
      hasForo: data.hasForo.present ? data.hasForo.value : this.hasForo,
      hasChat: data.hasChat.present ? data.hasChat.value : this.hasChat,
      hasEncuestas: data.hasEncuestas.present
          ? data.hasEncuestas.value
          : this.hasEncuestas,
      hasEvaluacion: data.hasEvaluacion.present
          ? data.hasEvaluacion.value
          : this.hasEvaluacion,
      lastContenidosBadge: data.lastContenidosBadge.present
          ? data.lastContenidosBadge.value
          : this.lastContenidosBadge,
      lastMensajesBadge: data.lastMensajesBadge.present
          ? data.lastMensajesBadge.value
          : this.lastMensajesBadge,
      lastForoBadge: data.lastForoBadge.present
          ? data.lastForoBadge.value
          : this.lastForoBadge,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      localVisibilityOverride: data.localVisibilityOverride.present
          ? data.localVisibilityOverride.value
          : this.localVisibilityOverride,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('idComision: $idComision, ')
          ..write('name: $name, ')
          ..write('subjectCode: $subjectCode, ')
          ..write('commissionCode: $commissionCode, ')
          ..write('roleLabel: $roleLabel, ')
          ..write('isHiddenInMiel: $isHiddenInMiel, ')
          ..write('muted: $muted, ')
          ..write('notifyContenidos: $notifyContenidos, ')
          ..write('notifyPortafolio: $notifyPortafolio, ')
          ..write('notifyMensajeria: $notifyMensajeria, ')
          ..write('notifyForos: $notifyForos, ')
          ..write('notifyEvaluacion: $notifyEvaluacion, ')
          ..write('hasContenidos: $hasContenidos, ')
          ..write('hasAutoguia: $hasAutoguia, ')
          ..write('hasPortafolio: $hasPortafolio, ')
          ..write('hasMensajeria: $hasMensajeria, ')
          ..write('hasForo: $hasForo, ')
          ..write('hasChat: $hasChat, ')
          ..write('hasEncuestas: $hasEncuestas, ')
          ..write('hasEvaluacion: $hasEvaluacion, ')
          ..write('lastContenidosBadge: $lastContenidosBadge, ')
          ..write('lastMensajesBadge: $lastMensajesBadge, ')
          ..write('lastForoBadge: $lastForoBadge, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('localVisibilityOverride: $localVisibilityOverride, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    idComision,
    name,
    subjectCode,
    commissionCode,
    roleLabel,
    isHiddenInMiel,
    muted,
    notifyContenidos,
    notifyPortafolio,
    notifyMensajeria,
    notifyForos,
    notifyEvaluacion,
    hasContenidos,
    hasAutoguia,
    hasPortafolio,
    hasMensajeria,
    hasForo,
    hasChat,
    hasEncuestas,
    hasEvaluacion,
    lastContenidosBadge,
    lastMensajesBadge,
    lastForoBadge,
    sortOrder,
    localVisibilityOverride,
    lastSyncedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.idComision == this.idComision &&
          other.name == this.name &&
          other.subjectCode == this.subjectCode &&
          other.commissionCode == this.commissionCode &&
          other.roleLabel == this.roleLabel &&
          other.isHiddenInMiel == this.isHiddenInMiel &&
          other.muted == this.muted &&
          other.notifyContenidos == this.notifyContenidos &&
          other.notifyPortafolio == this.notifyPortafolio &&
          other.notifyMensajeria == this.notifyMensajeria &&
          other.notifyForos == this.notifyForos &&
          other.notifyEvaluacion == this.notifyEvaluacion &&
          other.hasContenidos == this.hasContenidos &&
          other.hasAutoguia == this.hasAutoguia &&
          other.hasPortafolio == this.hasPortafolio &&
          other.hasMensajeria == this.hasMensajeria &&
          other.hasForo == this.hasForo &&
          other.hasChat == this.hasChat &&
          other.hasEncuestas == this.hasEncuestas &&
          other.hasEvaluacion == this.hasEvaluacion &&
          other.lastContenidosBadge == this.lastContenidosBadge &&
          other.lastMensajesBadge == this.lastMensajesBadge &&
          other.lastForoBadge == this.lastForoBadge &&
          other.sortOrder == this.sortOrder &&
          other.localVisibilityOverride == this.localVisibilityOverride &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<String> idComision;
  final Value<String> name;
  final Value<String> subjectCode;
  final Value<String> commissionCode;
  final Value<String> roleLabel;
  final Value<bool> isHiddenInMiel;
  final Value<bool> muted;
  final Value<bool> notifyContenidos;
  final Value<bool> notifyPortafolio;
  final Value<bool> notifyMensajeria;
  final Value<bool> notifyForos;
  final Value<bool> notifyEvaluacion;
  final Value<bool> hasContenidos;
  final Value<bool> hasAutoguia;
  final Value<bool> hasPortafolio;
  final Value<bool> hasMensajeria;
  final Value<bool> hasForo;
  final Value<bool> hasChat;
  final Value<bool> hasEncuestas;
  final Value<bool> hasEvaluacion;
  final Value<int> lastContenidosBadge;
  final Value<int> lastMensajesBadge;
  final Value<int> lastForoBadge;
  final Value<int> sortOrder;
  final Value<int> localVisibilityOverride;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.idComision = const Value.absent(),
    this.name = const Value.absent(),
    this.subjectCode = const Value.absent(),
    this.commissionCode = const Value.absent(),
    this.roleLabel = const Value.absent(),
    this.isHiddenInMiel = const Value.absent(),
    this.muted = const Value.absent(),
    this.notifyContenidos = const Value.absent(),
    this.notifyPortafolio = const Value.absent(),
    this.notifyMensajeria = const Value.absent(),
    this.notifyForos = const Value.absent(),
    this.notifyEvaluacion = const Value.absent(),
    this.hasContenidos = const Value.absent(),
    this.hasAutoguia = const Value.absent(),
    this.hasPortafolio = const Value.absent(),
    this.hasMensajeria = const Value.absent(),
    this.hasForo = const Value.absent(),
    this.hasChat = const Value.absent(),
    this.hasEncuestas = const Value.absent(),
    this.hasEvaluacion = const Value.absent(),
    this.lastContenidosBadge = const Value.absent(),
    this.lastMensajesBadge = const Value.absent(),
    this.lastForoBadge = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.localVisibilityOverride = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String idComision,
    required String name,
    this.subjectCode = const Value.absent(),
    this.commissionCode = const Value.absent(),
    this.roleLabel = const Value.absent(),
    this.isHiddenInMiel = const Value.absent(),
    this.muted = const Value.absent(),
    this.notifyContenidos = const Value.absent(),
    this.notifyPortafolio = const Value.absent(),
    this.notifyMensajeria = const Value.absent(),
    this.notifyForos = const Value.absent(),
    this.notifyEvaluacion = const Value.absent(),
    this.hasContenidos = const Value.absent(),
    this.hasAutoguia = const Value.absent(),
    this.hasPortafolio = const Value.absent(),
    this.hasMensajeria = const Value.absent(),
    this.hasForo = const Value.absent(),
    this.hasChat = const Value.absent(),
    this.hasEncuestas = const Value.absent(),
    this.hasEvaluacion = const Value.absent(),
    this.lastContenidosBadge = const Value.absent(),
    this.lastMensajesBadge = const Value.absent(),
    this.lastForoBadge = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.localVisibilityOverride = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : idComision = Value(idComision),
       name = Value(name);
  static Insertable<Subject> custom({
    Expression<String>? idComision,
    Expression<String>? name,
    Expression<String>? subjectCode,
    Expression<String>? commissionCode,
    Expression<String>? roleLabel,
    Expression<bool>? isHiddenInMiel,
    Expression<bool>? muted,
    Expression<bool>? notifyContenidos,
    Expression<bool>? notifyPortafolio,
    Expression<bool>? notifyMensajeria,
    Expression<bool>? notifyForos,
    Expression<bool>? notifyEvaluacion,
    Expression<bool>? hasContenidos,
    Expression<bool>? hasAutoguia,
    Expression<bool>? hasPortafolio,
    Expression<bool>? hasMensajeria,
    Expression<bool>? hasForo,
    Expression<bool>? hasChat,
    Expression<bool>? hasEncuestas,
    Expression<bool>? hasEvaluacion,
    Expression<int>? lastContenidosBadge,
    Expression<int>? lastMensajesBadge,
    Expression<int>? lastForoBadge,
    Expression<int>? sortOrder,
    Expression<int>? localVisibilityOverride,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idComision != null) 'id_comision': idComision,
      if (name != null) 'name': name,
      if (subjectCode != null) 'subject_code': subjectCode,
      if (commissionCode != null) 'commission_code': commissionCode,
      if (roleLabel != null) 'role_label': roleLabel,
      if (isHiddenInMiel != null) 'is_hidden_in_miel': isHiddenInMiel,
      if (muted != null) 'muted': muted,
      if (notifyContenidos != null) 'notify_contenidos': notifyContenidos,
      if (notifyPortafolio != null) 'notify_portafolio': notifyPortafolio,
      if (notifyMensajeria != null) 'notify_mensajeria': notifyMensajeria,
      if (notifyForos != null) 'notify_foros': notifyForos,
      if (notifyEvaluacion != null) 'notify_evaluacion': notifyEvaluacion,
      if (hasContenidos != null) 'has_contenidos': hasContenidos,
      if (hasAutoguia != null) 'has_autoguia': hasAutoguia,
      if (hasPortafolio != null) 'has_portafolio': hasPortafolio,
      if (hasMensajeria != null) 'has_mensajeria': hasMensajeria,
      if (hasForo != null) 'has_foro': hasForo,
      if (hasChat != null) 'has_chat': hasChat,
      if (hasEncuestas != null) 'has_encuestas': hasEncuestas,
      if (hasEvaluacion != null) 'has_evaluacion': hasEvaluacion,
      if (lastContenidosBadge != null)
        'last_contenidos_badge': lastContenidosBadge,
      if (lastMensajesBadge != null) 'last_mensajes_badge': lastMensajesBadge,
      if (lastForoBadge != null) 'last_foro_badge': lastForoBadge,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (localVisibilityOverride != null)
        'local_visibility_override': localVisibilityOverride,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith({
    Value<String>? idComision,
    Value<String>? name,
    Value<String>? subjectCode,
    Value<String>? commissionCode,
    Value<String>? roleLabel,
    Value<bool>? isHiddenInMiel,
    Value<bool>? muted,
    Value<bool>? notifyContenidos,
    Value<bool>? notifyPortafolio,
    Value<bool>? notifyMensajeria,
    Value<bool>? notifyForos,
    Value<bool>? notifyEvaluacion,
    Value<bool>? hasContenidos,
    Value<bool>? hasAutoguia,
    Value<bool>? hasPortafolio,
    Value<bool>? hasMensajeria,
    Value<bool>? hasForo,
    Value<bool>? hasChat,
    Value<bool>? hasEncuestas,
    Value<bool>? hasEvaluacion,
    Value<int>? lastContenidosBadge,
    Value<int>? lastMensajesBadge,
    Value<int>? lastForoBadge,
    Value<int>? sortOrder,
    Value<int>? localVisibilityOverride,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SubjectsCompanion(
      idComision: idComision ?? this.idComision,
      name: name ?? this.name,
      subjectCode: subjectCode ?? this.subjectCode,
      commissionCode: commissionCode ?? this.commissionCode,
      roleLabel: roleLabel ?? this.roleLabel,
      isHiddenInMiel: isHiddenInMiel ?? this.isHiddenInMiel,
      muted: muted ?? this.muted,
      notifyContenidos: notifyContenidos ?? this.notifyContenidos,
      notifyPortafolio: notifyPortafolio ?? this.notifyPortafolio,
      notifyMensajeria: notifyMensajeria ?? this.notifyMensajeria,
      notifyForos: notifyForos ?? this.notifyForos,
      notifyEvaluacion: notifyEvaluacion ?? this.notifyEvaluacion,
      hasContenidos: hasContenidos ?? this.hasContenidos,
      hasAutoguia: hasAutoguia ?? this.hasAutoguia,
      hasPortafolio: hasPortafolio ?? this.hasPortafolio,
      hasMensajeria: hasMensajeria ?? this.hasMensajeria,
      hasForo: hasForo ?? this.hasForo,
      hasChat: hasChat ?? this.hasChat,
      hasEncuestas: hasEncuestas ?? this.hasEncuestas,
      hasEvaluacion: hasEvaluacion ?? this.hasEvaluacion,
      lastContenidosBadge: lastContenidosBadge ?? this.lastContenidosBadge,
      lastMensajesBadge: lastMensajesBadge ?? this.lastMensajesBadge,
      lastForoBadge: lastForoBadge ?? this.lastForoBadge,
      sortOrder: sortOrder ?? this.sortOrder,
      localVisibilityOverride:
          localVisibilityOverride ?? this.localVisibilityOverride,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idComision.present) {
      map['id_comision'] = Variable<String>(idComision.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (subjectCode.present) {
      map['subject_code'] = Variable<String>(subjectCode.value);
    }
    if (commissionCode.present) {
      map['commission_code'] = Variable<String>(commissionCode.value);
    }
    if (roleLabel.present) {
      map['role_label'] = Variable<String>(roleLabel.value);
    }
    if (isHiddenInMiel.present) {
      map['is_hidden_in_miel'] = Variable<bool>(isHiddenInMiel.value);
    }
    if (muted.present) {
      map['muted'] = Variable<bool>(muted.value);
    }
    if (notifyContenidos.present) {
      map['notify_contenidos'] = Variable<bool>(notifyContenidos.value);
    }
    if (notifyPortafolio.present) {
      map['notify_portafolio'] = Variable<bool>(notifyPortafolio.value);
    }
    if (notifyMensajeria.present) {
      map['notify_mensajeria'] = Variable<bool>(notifyMensajeria.value);
    }
    if (notifyForos.present) {
      map['notify_foros'] = Variable<bool>(notifyForos.value);
    }
    if (notifyEvaluacion.present) {
      map['notify_evaluacion'] = Variable<bool>(notifyEvaluacion.value);
    }
    if (hasContenidos.present) {
      map['has_contenidos'] = Variable<bool>(hasContenidos.value);
    }
    if (hasAutoguia.present) {
      map['has_autoguia'] = Variable<bool>(hasAutoguia.value);
    }
    if (hasPortafolio.present) {
      map['has_portafolio'] = Variable<bool>(hasPortafolio.value);
    }
    if (hasMensajeria.present) {
      map['has_mensajeria'] = Variable<bool>(hasMensajeria.value);
    }
    if (hasForo.present) {
      map['has_foro'] = Variable<bool>(hasForo.value);
    }
    if (hasChat.present) {
      map['has_chat'] = Variable<bool>(hasChat.value);
    }
    if (hasEncuestas.present) {
      map['has_encuestas'] = Variable<bool>(hasEncuestas.value);
    }
    if (hasEvaluacion.present) {
      map['has_evaluacion'] = Variable<bool>(hasEvaluacion.value);
    }
    if (lastContenidosBadge.present) {
      map['last_contenidos_badge'] = Variable<int>(lastContenidosBadge.value);
    }
    if (lastMensajesBadge.present) {
      map['last_mensajes_badge'] = Variable<int>(lastMensajesBadge.value);
    }
    if (lastForoBadge.present) {
      map['last_foro_badge'] = Variable<int>(lastForoBadge.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (localVisibilityOverride.present) {
      map['local_visibility_override'] = Variable<int>(
        localVisibilityOverride.value,
      );
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('idComision: $idComision, ')
          ..write('name: $name, ')
          ..write('subjectCode: $subjectCode, ')
          ..write('commissionCode: $commissionCode, ')
          ..write('roleLabel: $roleLabel, ')
          ..write('isHiddenInMiel: $isHiddenInMiel, ')
          ..write('muted: $muted, ')
          ..write('notifyContenidos: $notifyContenidos, ')
          ..write('notifyPortafolio: $notifyPortafolio, ')
          ..write('notifyMensajeria: $notifyMensajeria, ')
          ..write('notifyForos: $notifyForos, ')
          ..write('notifyEvaluacion: $notifyEvaluacion, ')
          ..write('hasContenidos: $hasContenidos, ')
          ..write('hasAutoguia: $hasAutoguia, ')
          ..write('hasPortafolio: $hasPortafolio, ')
          ..write('hasMensajeria: $hasMensajeria, ')
          ..write('hasForo: $hasForo, ')
          ..write('hasChat: $hasChat, ')
          ..write('hasEncuestas: $hasEncuestas, ')
          ..write('hasEvaluacion: $hasEvaluacion, ')
          ..write('lastContenidosBadge: $lastContenidosBadge, ')
          ..write('lastMensajesBadge: $lastMensajesBadge, ')
          ..write('lastForoBadge: $lastForoBadge, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('localVisibilityOverride: $localVisibilityOverride, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedTeachersTable extends CachedTeachers
    with TableInfo<$CachedTeachersTable, CachedTeacher> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTeachersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idComisionMeta = const VerificationMeta(
    'idComision',
  );
  @override
  late final GeneratedColumn<String> idComision = GeneratedColumn<String>(
    'id_comision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Tutor/a'),
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idComision,
    normalizedName,
    displayName,
    role,
    avatarUrl,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_teachers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedTeacher> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_comision')) {
      context.handle(
        _idComisionMeta,
        idComision.isAcceptableOrUnknown(data['id_comision']!, _idComisionMeta),
      );
    } else if (isInserting) {
      context.missing(_idComisionMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idComision, normalizedName};
  @override
  CachedTeacher map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTeacher(
      idComision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_comision'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedTeachersTable createAlias(String alias) {
    return $CachedTeachersTable(attachedDatabase, alias);
  }
}

class CachedTeacher extends DataClass implements Insertable<CachedTeacher> {
  final String idComision;
  final String normalizedName;
  final String displayName;
  final String role;
  final String avatarUrl;
  final DateTime cachedAt;
  const CachedTeacher({
    required this.idComision,
    required this.normalizedName,
    required this.displayName,
    required this.role,
    required this.avatarUrl,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_comision'] = Variable<String>(idComision);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['display_name'] = Variable<String>(displayName);
    map['role'] = Variable<String>(role);
    map['avatar_url'] = Variable<String>(avatarUrl);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedTeachersCompanion toCompanion(bool nullToAbsent) {
    return CachedTeachersCompanion(
      idComision: Value(idComision),
      normalizedName: Value(normalizedName),
      displayName: Value(displayName),
      role: Value(role),
      avatarUrl: Value(avatarUrl),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedTeacher.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTeacher(
      idComision: serializer.fromJson<String>(json['idComision']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      role: serializer.fromJson<String>(json['role']),
      avatarUrl: serializer.fromJson<String>(json['avatarUrl']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idComision': serializer.toJson<String>(idComision),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'displayName': serializer.toJson<String>(displayName),
      'role': serializer.toJson<String>(role),
      'avatarUrl': serializer.toJson<String>(avatarUrl),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedTeacher copyWith({
    String? idComision,
    String? normalizedName,
    String? displayName,
    String? role,
    String? avatarUrl,
    DateTime? cachedAt,
  }) => CachedTeacher(
    idComision: idComision ?? this.idComision,
    normalizedName: normalizedName ?? this.normalizedName,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedTeacher copyWithCompanion(CachedTeachersCompanion data) {
    return CachedTeacher(
      idComision: data.idComision.present
          ? data.idComision.value
          : this.idComision,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTeacher(')
          ..write('idComision: $idComision, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idComision,
    normalizedName,
    displayName,
    role,
    avatarUrl,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTeacher &&
          other.idComision == this.idComision &&
          other.normalizedName == this.normalizedName &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.avatarUrl == this.avatarUrl &&
          other.cachedAt == this.cachedAt);
}

class CachedTeachersCompanion extends UpdateCompanion<CachedTeacher> {
  final Value<String> idComision;
  final Value<String> normalizedName;
  final Value<String> displayName;
  final Value<String> role;
  final Value<String> avatarUrl;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedTeachersCompanion({
    this.idComision = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedTeachersCompanion.insert({
    required String idComision,
    required String normalizedName,
    required String displayName,
    this.role = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : idComision = Value(idComision),
       normalizedName = Value(normalizedName),
       displayName = Value(displayName),
       cachedAt = Value(cachedAt);
  static Insertable<CachedTeacher> custom({
    Expression<String>? idComision,
    Expression<String>? normalizedName,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<String>? avatarUrl,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idComision != null) 'id_comision': idComision,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedTeachersCompanion copyWith({
    Value<String>? idComision,
    Value<String>? normalizedName,
    Value<String>? displayName,
    Value<String>? role,
    Value<String>? avatarUrl,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedTeachersCompanion(
      idComision: idComision ?? this.idComision,
      normalizedName: normalizedName ?? this.normalizedName,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idComision.present) {
      map['id_comision'] = Variable<String>(idComision.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTeachersCompanion(')
          ..write('idComision: $idComision, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SnapshotEntriesTable extends SnapshotEntries
    with TableInfo<$SnapshotEntriesTable, SnapshotEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idComisionMeta = const VerificationMeta(
    'idComision',
  );
  @override
  late final GeneratedColumn<String> idComision = GeneratedColumn<String>(
    'id_comision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
    'module',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idComision,
    module,
    itemId,
    fingerprint,
    summary,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snapshot_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_comision')) {
      context.handle(
        _idComisionMeta,
        idComision.isAcceptableOrUnknown(data['id_comision']!, _idComisionMeta),
      );
    } else if (isInserting) {
      context.missing(_idComisionMeta);
    }
    if (data.containsKey('module')) {
      context.handle(
        _moduleMeta,
        module.isAcceptableOrUnknown(data['module']!, _moduleMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idComision, module, itemId};
  @override
  SnapshotEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotEntry(
      idComision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_comision'],
      )!,
      module: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SnapshotEntriesTable createAlias(String alias) {
    return $SnapshotEntriesTable(attachedDatabase, alias);
  }
}

class SnapshotEntry extends DataClass implements Insertable<SnapshotEntry> {
  final String idComision;
  final String module;
  final String itemId;
  final String fingerprint;
  final String summary;
  final DateTime updatedAt;
  const SnapshotEntry({
    required this.idComision,
    required this.module,
    required this.itemId,
    required this.fingerprint,
    required this.summary,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_comision'] = Variable<String>(idComision);
    map['module'] = Variable<String>(module);
    map['item_id'] = Variable<String>(itemId);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['summary'] = Variable<String>(summary);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SnapshotEntriesCompanion toCompanion(bool nullToAbsent) {
    return SnapshotEntriesCompanion(
      idComision: Value(idComision),
      module: Value(module),
      itemId: Value(itemId),
      fingerprint: Value(fingerprint),
      summary: Value(summary),
      updatedAt: Value(updatedAt),
    );
  }

  factory SnapshotEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotEntry(
      idComision: serializer.fromJson<String>(json['idComision']),
      module: serializer.fromJson<String>(json['module']),
      itemId: serializer.fromJson<String>(json['itemId']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      summary: serializer.fromJson<String>(json['summary']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idComision': serializer.toJson<String>(idComision),
      'module': serializer.toJson<String>(module),
      'itemId': serializer.toJson<String>(itemId),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'summary': serializer.toJson<String>(summary),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SnapshotEntry copyWith({
    String? idComision,
    String? module,
    String? itemId,
    String? fingerprint,
    String? summary,
    DateTime? updatedAt,
  }) => SnapshotEntry(
    idComision: idComision ?? this.idComision,
    module: module ?? this.module,
    itemId: itemId ?? this.itemId,
    fingerprint: fingerprint ?? this.fingerprint,
    summary: summary ?? this.summary,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SnapshotEntry copyWithCompanion(SnapshotEntriesCompanion data) {
    return SnapshotEntry(
      idComision: data.idComision.present
          ? data.idComision.value
          : this.idComision,
      module: data.module.present ? data.module.value : this.module,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      summary: data.summary.present ? data.summary.value : this.summary,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotEntry(')
          ..write('idComision: $idComision, ')
          ..write('module: $module, ')
          ..write('itemId: $itemId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('summary: $summary, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(idComision, module, itemId, fingerprint, summary, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotEntry &&
          other.idComision == this.idComision &&
          other.module == this.module &&
          other.itemId == this.itemId &&
          other.fingerprint == this.fingerprint &&
          other.summary == this.summary &&
          other.updatedAt == this.updatedAt);
}

class SnapshotEntriesCompanion extends UpdateCompanion<SnapshotEntry> {
  final Value<String> idComision;
  final Value<String> module;
  final Value<String> itemId;
  final Value<String> fingerprint;
  final Value<String> summary;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SnapshotEntriesCompanion({
    this.idComision = const Value.absent(),
    this.module = const Value.absent(),
    this.itemId = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.summary = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnapshotEntriesCompanion.insert({
    required String idComision,
    required String module,
    required String itemId,
    required String fingerprint,
    this.summary = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : idComision = Value(idComision),
       module = Value(module),
       itemId = Value(itemId),
       fingerprint = Value(fingerprint),
       updatedAt = Value(updatedAt);
  static Insertable<SnapshotEntry> custom({
    Expression<String>? idComision,
    Expression<String>? module,
    Expression<String>? itemId,
    Expression<String>? fingerprint,
    Expression<String>? summary,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idComision != null) 'id_comision': idComision,
      if (module != null) 'module': module,
      if (itemId != null) 'item_id': itemId,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (summary != null) 'summary': summary,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnapshotEntriesCompanion copyWith({
    Value<String>? idComision,
    Value<String>? module,
    Value<String>? itemId,
    Value<String>? fingerprint,
    Value<String>? summary,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SnapshotEntriesCompanion(
      idComision: idComision ?? this.idComision,
      module: module ?? this.module,
      itemId: itemId ?? this.itemId,
      fingerprint: fingerprint ?? this.fingerprint,
      summary: summary ?? this.summary,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idComision.present) {
      map['id_comision'] = Variable<String>(idComision.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
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
    return (StringBuffer('SnapshotEntriesCompanion(')
          ..write('idComision: $idComision, ')
          ..write('module: $module, ')
          ..write('itemId: $itemId, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('summary: $summary, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationLogsTable extends NotificationLogs
    with TableInfo<$NotificationLogsTable, NotificationLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dedupeKeyMeta = const VerificationMeta(
    'dedupeKey',
  );
  @override
  late final GeneratedColumn<String> dedupeKey = GeneratedColumn<String>(
    'dedupe_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _idComisionMeta = const VerificationMeta(
    'idComision',
  );
  @override
  late final GeneratedColumn<String> idComision = GeneratedColumn<String>(
    'id_comision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectNameMeta = const VerificationMeta(
    'subjectName',
  );
  @override
  late final GeneratedColumn<String> subjectName = GeneratedColumn<String>(
    'subject_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
    'module',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetUrlMeta = const VerificationMeta(
    'targetUrl',
  );
  @override
  late final GeneratedColumn<String> targetUrl = GeneratedColumn<String>(
    'target_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dedupeKey,
    idComision,
    subjectName,
    module,
    title,
    body,
    targetUrl,
    isRead,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dedupe_key')) {
      context.handle(
        _dedupeKeyMeta,
        dedupeKey.isAcceptableOrUnknown(data['dedupe_key']!, _dedupeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dedupeKeyMeta);
    }
    if (data.containsKey('id_comision')) {
      context.handle(
        _idComisionMeta,
        idComision.isAcceptableOrUnknown(data['id_comision']!, _idComisionMeta),
      );
    } else if (isInserting) {
      context.missing(_idComisionMeta);
    }
    if (data.containsKey('subject_name')) {
      context.handle(
        _subjectNameMeta,
        subjectName.isAcceptableOrUnknown(
          data['subject_name']!,
          _subjectNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectNameMeta);
    }
    if (data.containsKey('module')) {
      context.handle(
        _moduleMeta,
        module.isAcceptableOrUnknown(data['module']!, _moduleMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('target_url')) {
      context.handle(
        _targetUrlMeta,
        targetUrl.isAcceptableOrUnknown(data['target_url']!, _targetUrlMeta),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dedupeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dedupe_key'],
      )!,
      idComision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_comision'],
      )!,
      subjectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_name'],
      )!,
      module: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      targetUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_url'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NotificationLogsTable createAlias(String alias) {
    return $NotificationLogsTable(attachedDatabase, alias);
  }
}

class NotificationLog extends DataClass implements Insertable<NotificationLog> {
  final int id;
  final String dedupeKey;
  final String idComision;
  final String subjectName;
  final String module;
  final String title;
  final String body;
  final String targetUrl;
  final bool isRead;
  final DateTime createdAt;
  const NotificationLog({
    required this.id,
    required this.dedupeKey,
    required this.idComision,
    required this.subjectName,
    required this.module,
    required this.title,
    required this.body,
    required this.targetUrl,
    required this.isRead,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dedupe_key'] = Variable<String>(dedupeKey);
    map['id_comision'] = Variable<String>(idComision);
    map['subject_name'] = Variable<String>(subjectName);
    map['module'] = Variable<String>(module);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['target_url'] = Variable<String>(targetUrl);
    map['is_read'] = Variable<bool>(isRead);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NotificationLogsCompanion toCompanion(bool nullToAbsent) {
    return NotificationLogsCompanion(
      id: Value(id),
      dedupeKey: Value(dedupeKey),
      idComision: Value(idComision),
      subjectName: Value(subjectName),
      module: Value(module),
      title: Value(title),
      body: Value(body),
      targetUrl: Value(targetUrl),
      isRead: Value(isRead),
      createdAt: Value(createdAt),
    );
  }

  factory NotificationLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationLog(
      id: serializer.fromJson<int>(json['id']),
      dedupeKey: serializer.fromJson<String>(json['dedupeKey']),
      idComision: serializer.fromJson<String>(json['idComision']),
      subjectName: serializer.fromJson<String>(json['subjectName']),
      module: serializer.fromJson<String>(json['module']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      targetUrl: serializer.fromJson<String>(json['targetUrl']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dedupeKey': serializer.toJson<String>(dedupeKey),
      'idComision': serializer.toJson<String>(idComision),
      'subjectName': serializer.toJson<String>(subjectName),
      'module': serializer.toJson<String>(module),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'targetUrl': serializer.toJson<String>(targetUrl),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NotificationLog copyWith({
    int? id,
    String? dedupeKey,
    String? idComision,
    String? subjectName,
    String? module,
    String? title,
    String? body,
    String? targetUrl,
    bool? isRead,
    DateTime? createdAt,
  }) => NotificationLog(
    id: id ?? this.id,
    dedupeKey: dedupeKey ?? this.dedupeKey,
    idComision: idComision ?? this.idComision,
    subjectName: subjectName ?? this.subjectName,
    module: module ?? this.module,
    title: title ?? this.title,
    body: body ?? this.body,
    targetUrl: targetUrl ?? this.targetUrl,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
  );
  NotificationLog copyWithCompanion(NotificationLogsCompanion data) {
    return NotificationLog(
      id: data.id.present ? data.id.value : this.id,
      dedupeKey: data.dedupeKey.present ? data.dedupeKey.value : this.dedupeKey,
      idComision: data.idComision.present
          ? data.idComision.value
          : this.idComision,
      subjectName: data.subjectName.present
          ? data.subjectName.value
          : this.subjectName,
      module: data.module.present ? data.module.value : this.module,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      targetUrl: data.targetUrl.present ? data.targetUrl.value : this.targetUrl,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLog(')
          ..write('id: $id, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('idComision: $idComision, ')
          ..write('subjectName: $subjectName, ')
          ..write('module: $module, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('targetUrl: $targetUrl, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dedupeKey,
    idComision,
    subjectName,
    module,
    title,
    body,
    targetUrl,
    isRead,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationLog &&
          other.id == this.id &&
          other.dedupeKey == this.dedupeKey &&
          other.idComision == this.idComision &&
          other.subjectName == this.subjectName &&
          other.module == this.module &&
          other.title == this.title &&
          other.body == this.body &&
          other.targetUrl == this.targetUrl &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt);
}

class NotificationLogsCompanion extends UpdateCompanion<NotificationLog> {
  final Value<int> id;
  final Value<String> dedupeKey;
  final Value<String> idComision;
  final Value<String> subjectName;
  final Value<String> module;
  final Value<String> title;
  final Value<String> body;
  final Value<String> targetUrl;
  final Value<bool> isRead;
  final Value<DateTime> createdAt;
  const NotificationLogsCompanion({
    this.id = const Value.absent(),
    this.dedupeKey = const Value.absent(),
    this.idComision = const Value.absent(),
    this.subjectName = const Value.absent(),
    this.module = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.targetUrl = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NotificationLogsCompanion.insert({
    this.id = const Value.absent(),
    required String dedupeKey,
    required String idComision,
    required String subjectName,
    required String module,
    required String title,
    required String body,
    this.targetUrl = const Value.absent(),
    this.isRead = const Value.absent(),
    required DateTime createdAt,
  }) : dedupeKey = Value(dedupeKey),
       idComision = Value(idComision),
       subjectName = Value(subjectName),
       module = Value(module),
       title = Value(title),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<NotificationLog> custom({
    Expression<int>? id,
    Expression<String>? dedupeKey,
    Expression<String>? idComision,
    Expression<String>? subjectName,
    Expression<String>? module,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? targetUrl,
    Expression<bool>? isRead,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
      if (idComision != null) 'id_comision': idComision,
      if (subjectName != null) 'subject_name': subjectName,
      if (module != null) 'module': module,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (targetUrl != null) 'target_url': targetUrl,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NotificationLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? dedupeKey,
    Value<String>? idComision,
    Value<String>? subjectName,
    Value<String>? module,
    Value<String>? title,
    Value<String>? body,
    Value<String>? targetUrl,
    Value<bool>? isRead,
    Value<DateTime>? createdAt,
  }) {
    return NotificationLogsCompanion(
      id: id ?? this.id,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      idComision: idComision ?? this.idComision,
      subjectName: subjectName ?? this.subjectName,
      module: module ?? this.module,
      title: title ?? this.title,
      body: body ?? this.body,
      targetUrl: targetUrl ?? this.targetUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dedupeKey.present) {
      map['dedupe_key'] = Variable<String>(dedupeKey.value);
    }
    if (idComision.present) {
      map['id_comision'] = Variable<String>(idComision.value);
    }
    if (subjectName.present) {
      map['subject_name'] = Variable<String>(subjectName.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (targetUrl.present) {
      map['target_url'] = Variable<String>(targetUrl.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogsCompanion(')
          ..write('id: $id, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('idComision: $idComision, ')
          ..write('subjectName: $subjectName, ')
          ..write('module: $module, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('targetUrl: $targetUrl, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadedResourcesTable extends DownloadedResources
    with TableInfo<$DownloadedResourcesTable, DownloadedResource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadedResourcesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _idComisionMeta = const VerificationMeta(
    'idComision',
  );
  @override
  late final GeneratedColumn<String> idComision = GeneratedColumn<String>(
    'id_comision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
    'module',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<BigInt> fileSize = GeneratedColumn<BigInt>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idComision,
    module,
    resourceId,
    title,
    localPath,
    fileSize,
    sha256,
    downloadedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloaded_resources';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadedResource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('id_comision')) {
      context.handle(
        _idComisionMeta,
        idComision.isAcceptableOrUnknown(data['id_comision']!, _idComisionMeta),
      );
    } else if (isInserting) {
      context.missing(_idComisionMeta);
    }
    if (data.containsKey('module')) {
      context.handle(
        _moduleMeta,
        module.isAcceptableOrUnknown(data['module']!, _moduleMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadedResource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadedResource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      idComision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_comision'],
      )!,
      module: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module'],
      )!,
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}file_size'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
    );
  }

  @override
  $DownloadedResourcesTable createAlias(String alias) {
    return $DownloadedResourcesTable(attachedDatabase, alias);
  }
}

class DownloadedResource extends DataClass
    implements Insertable<DownloadedResource> {
  final int id;
  final String idComision;
  final String module;
  final String resourceId;
  final String title;
  final String localPath;
  final BigInt fileSize;
  final String? sha256;
  final DateTime downloadedAt;
  const DownloadedResource({
    required this.id,
    required this.idComision,
    required this.module,
    required this.resourceId,
    required this.title,
    required this.localPath,
    required this.fileSize,
    this.sha256,
    required this.downloadedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['id_comision'] = Variable<String>(idComision);
    map['module'] = Variable<String>(module);
    map['resource_id'] = Variable<String>(resourceId);
    map['title'] = Variable<String>(title);
    map['local_path'] = Variable<String>(localPath);
    map['file_size'] = Variable<BigInt>(fileSize);
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  DownloadedResourcesCompanion toCompanion(bool nullToAbsent) {
    return DownloadedResourcesCompanion(
      id: Value(id),
      idComision: Value(idComision),
      module: Value(module),
      resourceId: Value(resourceId),
      title: Value(title),
      localPath: Value(localPath),
      fileSize: Value(fileSize),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory DownloadedResource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadedResource(
      id: serializer.fromJson<int>(json['id']),
      idComision: serializer.fromJson<String>(json['idComision']),
      module: serializer.fromJson<String>(json['module']),
      resourceId: serializer.fromJson<String>(json['resourceId']),
      title: serializer.fromJson<String>(json['title']),
      localPath: serializer.fromJson<String>(json['localPath']),
      fileSize: serializer.fromJson<BigInt>(json['fileSize']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'idComision': serializer.toJson<String>(idComision),
      'module': serializer.toJson<String>(module),
      'resourceId': serializer.toJson<String>(resourceId),
      'title': serializer.toJson<String>(title),
      'localPath': serializer.toJson<String>(localPath),
      'fileSize': serializer.toJson<BigInt>(fileSize),
      'sha256': serializer.toJson<String?>(sha256),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  DownloadedResource copyWith({
    int? id,
    String? idComision,
    String? module,
    String? resourceId,
    String? title,
    String? localPath,
    BigInt? fileSize,
    Value<String?> sha256 = const Value.absent(),
    DateTime? downloadedAt,
  }) => DownloadedResource(
    id: id ?? this.id,
    idComision: idComision ?? this.idComision,
    module: module ?? this.module,
    resourceId: resourceId ?? this.resourceId,
    title: title ?? this.title,
    localPath: localPath ?? this.localPath,
    fileSize: fileSize ?? this.fileSize,
    sha256: sha256.present ? sha256.value : this.sha256,
    downloadedAt: downloadedAt ?? this.downloadedAt,
  );
  DownloadedResource copyWithCompanion(DownloadedResourcesCompanion data) {
    return DownloadedResource(
      id: data.id.present ? data.id.value : this.id,
      idComision: data.idComision.present
          ? data.idComision.value
          : this.idComision,
      module: data.module.present ? data.module.value : this.module,
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      title: data.title.present ? data.title.value : this.title,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedResource(')
          ..write('id: $id, ')
          ..write('idComision: $idComision, ')
          ..write('module: $module, ')
          ..write('resourceId: $resourceId, ')
          ..write('title: $title, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('sha256: $sha256, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idComision,
    module,
    resourceId,
    title,
    localPath,
    fileSize,
    sha256,
    downloadedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadedResource &&
          other.id == this.id &&
          other.idComision == this.idComision &&
          other.module == this.module &&
          other.resourceId == this.resourceId &&
          other.title == this.title &&
          other.localPath == this.localPath &&
          other.fileSize == this.fileSize &&
          other.sha256 == this.sha256 &&
          other.downloadedAt == this.downloadedAt);
}

class DownloadedResourcesCompanion extends UpdateCompanion<DownloadedResource> {
  final Value<int> id;
  final Value<String> idComision;
  final Value<String> module;
  final Value<String> resourceId;
  final Value<String> title;
  final Value<String> localPath;
  final Value<BigInt> fileSize;
  final Value<String?> sha256;
  final Value<DateTime> downloadedAt;
  const DownloadedResourcesCompanion({
    this.id = const Value.absent(),
    this.idComision = const Value.absent(),
    this.module = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.title = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.downloadedAt = const Value.absent(),
  });
  DownloadedResourcesCompanion.insert({
    this.id = const Value.absent(),
    required String idComision,
    required String module,
    required String resourceId,
    required String title,
    required String localPath,
    required BigInt fileSize,
    this.sha256 = const Value.absent(),
    required DateTime downloadedAt,
  }) : idComision = Value(idComision),
       module = Value(module),
       resourceId = Value(resourceId),
       title = Value(title),
       localPath = Value(localPath),
       fileSize = Value(fileSize),
       downloadedAt = Value(downloadedAt);
  static Insertable<DownloadedResource> custom({
    Expression<int>? id,
    Expression<String>? idComision,
    Expression<String>? module,
    Expression<String>? resourceId,
    Expression<String>? title,
    Expression<String>? localPath,
    Expression<BigInt>? fileSize,
    Expression<String>? sha256,
    Expression<DateTime>? downloadedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idComision != null) 'id_comision': idComision,
      if (module != null) 'module': module,
      if (resourceId != null) 'resource_id': resourceId,
      if (title != null) 'title': title,
      if (localPath != null) 'local_path': localPath,
      if (fileSize != null) 'file_size': fileSize,
      if (sha256 != null) 'sha256': sha256,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
    });
  }

  DownloadedResourcesCompanion copyWith({
    Value<int>? id,
    Value<String>? idComision,
    Value<String>? module,
    Value<String>? resourceId,
    Value<String>? title,
    Value<String>? localPath,
    Value<BigInt>? fileSize,
    Value<String?>? sha256,
    Value<DateTime>? downloadedAt,
  }) {
    return DownloadedResourcesCompanion(
      id: id ?? this.id,
      idComision: idComision ?? this.idComision,
      module: module ?? this.module,
      resourceId: resourceId ?? this.resourceId,
      title: title ?? this.title,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
      sha256: sha256 ?? this.sha256,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (idComision.present) {
      map['id_comision'] = Variable<String>(idComision.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<BigInt>(fileSize.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadedResourcesCompanion(')
          ..write('id: $id, ')
          ..write('idComision: $idComision, ')
          ..write('module: $module, ')
          ..write('resourceId: $resourceId, ')
          ..write('title: $title, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('sha256: $sha256, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $CachedTeachersTable cachedTeachers = $CachedTeachersTable(this);
  late final $SnapshotEntriesTable snapshotEntries = $SnapshotEntriesTable(
    this,
  );
  late final $NotificationLogsTable notificationLogs = $NotificationLogsTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $DownloadedResourcesTable downloadedResources =
      $DownloadedResourcesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    subjects,
    cachedTeachers,
    snapshotEntries,
    notificationLogs,
    appSettings,
    downloadedResources,
  ];
}

typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  required String idComision,
  required String name,
  Value<String> subjectCode,
  Value<String> commissionCode,
  Value<String> roleLabel,
  Value<bool> isHiddenInMiel,
  Value<bool> muted,
  Value<bool> notifyContenidos,
  Value<bool> notifyPortafolio,
  Value<bool> notifyMensajeria,
  Value<bool> notifyForos,
  Value<bool> notifyEvaluacion,
  Value<bool> hasContenidos,
  Value<bool> hasAutoguia,
  Value<bool> hasPortafolio,
  Value<bool> hasMensajeria,
  Value<bool> hasForo,
  Value<bool> hasChat,
  Value<bool> hasEncuestas,
  Value<bool> hasEvaluacion,
  Value<int> lastContenidosBadge,
  Value<int> lastMensajesBadge,
  Value<int> lastForoBadge,
  Value<int> sortOrder,
  Value<int> localVisibilityOverride,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<String> idComision,
  Value<String> name,
  Value<String> subjectCode,
  Value<String> commissionCode,
  Value<String> roleLabel,
  Value<bool> isHiddenInMiel,
  Value<bool> muted,
  Value<bool> notifyContenidos,
  Value<bool> notifyPortafolio,
  Value<bool> notifyMensajeria,
  Value<bool> notifyForos,
  Value<bool> notifyEvaluacion,
  Value<bool> hasContenidos,
  Value<bool> hasAutoguia,
  Value<bool> hasPortafolio,
  Value<bool> hasMensajeria,
  Value<bool> hasForo,
  Value<bool> hasChat,
  Value<bool> hasEncuestas,
  Value<bool> hasEvaluacion,
  Value<int> lastContenidosBadge,
  Value<int> lastMensajesBadge,
  Value<int> lastForoBadge,
  Value<int> sortOrder,
  Value<int> localVisibilityOverride,
  Value<DateTime?> lastSyncedAt,
  Value<int> rowid,
});

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectCode => $composableBuilder(
    column: $table.subjectCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commissionCode => $composableBuilder(
    column: $table.commissionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleLabel => $composableBuilder(
    column: $table.roleLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHiddenInMiel => $composableBuilder(
    column: $table.isHiddenInMiel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get muted => $composableBuilder(
    column: $table.muted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyContenidos => $composableBuilder(
    column: $table.notifyContenidos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyPortafolio => $composableBuilder(
    column: $table.notifyPortafolio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyMensajeria => $composableBuilder(
    column: $table.notifyMensajeria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyForos => $composableBuilder(
    column: $table.notifyForos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyEvaluacion => $composableBuilder(
    column: $table.notifyEvaluacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasContenidos => $composableBuilder(
    column: $table.hasContenidos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasAutoguia => $composableBuilder(
    column: $table.hasAutoguia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasPortafolio => $composableBuilder(
    column: $table.hasPortafolio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasMensajeria => $composableBuilder(
    column: $table.hasMensajeria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasForo => $composableBuilder(
    column: $table.hasForo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasChat => $composableBuilder(
    column: $table.hasChat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasEncuestas => $composableBuilder(
    column: $table.hasEncuestas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasEvaluacion => $composableBuilder(
    column: $table.hasEvaluacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastContenidosBadge => $composableBuilder(
    column: $table.lastContenidosBadge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMensajesBadge => $composableBuilder(
    column: $table.lastMensajesBadge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastForoBadge => $composableBuilder(
    column: $table.lastForoBadge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localVisibilityOverride => $composableBuilder(
    column: $table.localVisibilityOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectCode => $composableBuilder(
    column: $table.subjectCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commissionCode => $composableBuilder(
    column: $table.commissionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleLabel => $composableBuilder(
    column: $table.roleLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHiddenInMiel => $composableBuilder(
    column: $table.isHiddenInMiel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get muted => $composableBuilder(
    column: $table.muted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyContenidos => $composableBuilder(
    column: $table.notifyContenidos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyPortafolio => $composableBuilder(
    column: $table.notifyPortafolio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyMensajeria => $composableBuilder(
    column: $table.notifyMensajeria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyForos => $composableBuilder(
    column: $table.notifyForos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyEvaluacion => $composableBuilder(
    column: $table.notifyEvaluacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasContenidos => $composableBuilder(
    column: $table.hasContenidos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasAutoguia => $composableBuilder(
    column: $table.hasAutoguia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasPortafolio => $composableBuilder(
    column: $table.hasPortafolio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasMensajeria => $composableBuilder(
    column: $table.hasMensajeria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasForo => $composableBuilder(
    column: $table.hasForo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasChat => $composableBuilder(
    column: $table.hasChat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasEncuestas => $composableBuilder(
    column: $table.hasEncuestas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasEvaluacion => $composableBuilder(
    column: $table.hasEvaluacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastContenidosBadge => $composableBuilder(
    column: $table.lastContenidosBadge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMensajesBadge => $composableBuilder(
    column: $table.lastMensajesBadge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastForoBadge => $composableBuilder(
    column: $table.lastForoBadge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localVisibilityOverride => $composableBuilder(
    column: $table.localVisibilityOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get subjectCode => $composableBuilder(
    column: $table.subjectCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commissionCode => $composableBuilder(
    column: $table.commissionCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roleLabel =>
      $composableBuilder(column: $table.roleLabel, builder: (column) => column);

  GeneratedColumn<bool> get isHiddenInMiel => $composableBuilder(
    column: $table.isHiddenInMiel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get muted =>
      $composableBuilder(column: $table.muted, builder: (column) => column);

  GeneratedColumn<bool> get notifyContenidos => $composableBuilder(
    column: $table.notifyContenidos,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyPortafolio => $composableBuilder(
    column: $table.notifyPortafolio,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyMensajeria => $composableBuilder(
    column: $table.notifyMensajeria,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyForos => $composableBuilder(
    column: $table.notifyForos,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyEvaluacion => $composableBuilder(
    column: $table.notifyEvaluacion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasContenidos => $composableBuilder(
    column: $table.hasContenidos,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasAutoguia => $composableBuilder(
    column: $table.hasAutoguia,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasPortafolio => $composableBuilder(
    column: $table.hasPortafolio,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasMensajeria => $composableBuilder(
    column: $table.hasMensajeria,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasForo =>
      $composableBuilder(column: $table.hasForo, builder: (column) => column);

  GeneratedColumn<bool> get hasChat =>
      $composableBuilder(column: $table.hasChat, builder: (column) => column);

  GeneratedColumn<bool> get hasEncuestas => $composableBuilder(
    column: $table.hasEncuestas,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasEvaluacion => $composableBuilder(
    column: $table.hasEvaluacion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastContenidosBadge => $composableBuilder(
    column: $table.lastContenidosBadge,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMensajesBadge => $composableBuilder(
    column: $table.lastMensajesBadge,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastForoBadge => $composableBuilder(
    column: $table.lastForoBadge,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get localVisibilityOverride => $composableBuilder(
    column: $table.localVisibilityOverride,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SubjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectsTable,
          Subject,
          $$SubjectsTableFilterComposer,
          $$SubjectsTableOrderingComposer,
          $$SubjectsTableAnnotationComposer,
          $$SubjectsTableCreateCompanionBuilder,
          $$SubjectsTableUpdateCompanionBuilder,
          (Subject, BaseReferences<_$AppDatabase, $SubjectsTable, Subject>),
          Subject,
          PrefetchHooks Function()
        > {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idComision = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> subjectCode = const Value.absent(),
                Value<String> commissionCode = const Value.absent(),
                Value<String> roleLabel = const Value.absent(),
                Value<bool> isHiddenInMiel = const Value.absent(),
                Value<bool> muted = const Value.absent(),
                Value<bool> notifyContenidos = const Value.absent(),
                Value<bool> notifyPortafolio = const Value.absent(),
                Value<bool> notifyMensajeria = const Value.absent(),
                Value<bool> notifyForos = const Value.absent(),
                Value<bool> notifyEvaluacion = const Value.absent(),
                Value<bool> hasContenidos = const Value.absent(),
                Value<bool> hasAutoguia = const Value.absent(),
                Value<bool> hasPortafolio = const Value.absent(),
                Value<bool> hasMensajeria = const Value.absent(),
                Value<bool> hasForo = const Value.absent(),
                Value<bool> hasChat = const Value.absent(),
                Value<bool> hasEncuestas = const Value.absent(),
                Value<bool> hasEvaluacion = const Value.absent(),
                Value<int> lastContenidosBadge = const Value.absent(),
                Value<int> lastMensajesBadge = const Value.absent(),
                Value<int> lastForoBadge = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> localVisibilityOverride = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectsCompanion(
                idComision: idComision,
                name: name,
                subjectCode: subjectCode,
                commissionCode: commissionCode,
                roleLabel: roleLabel,
                isHiddenInMiel: isHiddenInMiel,
                muted: muted,
                notifyContenidos: notifyContenidos,
                notifyPortafolio: notifyPortafolio,
                notifyMensajeria: notifyMensajeria,
                notifyForos: notifyForos,
                notifyEvaluacion: notifyEvaluacion,
                hasContenidos: hasContenidos,
                hasAutoguia: hasAutoguia,
                hasPortafolio: hasPortafolio,
                hasMensajeria: hasMensajeria,
                hasForo: hasForo,
                hasChat: hasChat,
                hasEncuestas: hasEncuestas,
                hasEvaluacion: hasEvaluacion,
                lastContenidosBadge: lastContenidosBadge,
                lastMensajesBadge: lastMensajesBadge,
                lastForoBadge: lastForoBadge,
                sortOrder: sortOrder,
                localVisibilityOverride: localVisibilityOverride,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idComision,
                required String name,
                Value<String> subjectCode = const Value.absent(),
                Value<String> commissionCode = const Value.absent(),
                Value<String> roleLabel = const Value.absent(),
                Value<bool> isHiddenInMiel = const Value.absent(),
                Value<bool> muted = const Value.absent(),
                Value<bool> notifyContenidos = const Value.absent(),
                Value<bool> notifyPortafolio = const Value.absent(),
                Value<bool> notifyMensajeria = const Value.absent(),
                Value<bool> notifyForos = const Value.absent(),
                Value<bool> notifyEvaluacion = const Value.absent(),
                Value<bool> hasContenidos = const Value.absent(),
                Value<bool> hasAutoguia = const Value.absent(),
                Value<bool> hasPortafolio = const Value.absent(),
                Value<bool> hasMensajeria = const Value.absent(),
                Value<bool> hasForo = const Value.absent(),
                Value<bool> hasChat = const Value.absent(),
                Value<bool> hasEncuestas = const Value.absent(),
                Value<bool> hasEvaluacion = const Value.absent(),
                Value<int> lastContenidosBadge = const Value.absent(),
                Value<int> lastMensajesBadge = const Value.absent(),
                Value<int> lastForoBadge = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> localVisibilityOverride = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectsCompanion.insert(
                idComision: idComision,
                name: name,
                subjectCode: subjectCode,
                commissionCode: commissionCode,
                roleLabel: roleLabel,
                isHiddenInMiel: isHiddenInMiel,
                muted: muted,
                notifyContenidos: notifyContenidos,
                notifyPortafolio: notifyPortafolio,
                notifyMensajeria: notifyMensajeria,
                notifyForos: notifyForos,
                notifyEvaluacion: notifyEvaluacion,
                hasContenidos: hasContenidos,
                hasAutoguia: hasAutoguia,
                hasPortafolio: hasPortafolio,
                hasMensajeria: hasMensajeria,
                hasForo: hasForo,
                hasChat: hasChat,
                hasEncuestas: hasEncuestas,
                hasEvaluacion: hasEvaluacion,
                lastContenidosBadge: lastContenidosBadge,
                lastMensajesBadge: lastMensajesBadge,
                lastForoBadge: lastForoBadge,
                sortOrder: sortOrder,
                localVisibilityOverride: localVisibilityOverride,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubjectsTable, Subject>(table),
                  BaseReferences<_$AppDatabase, $SubjectsTable, Subject>(
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

typedef $$SubjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectsTable,
      Subject,
      $$SubjectsTableFilterComposer,
      $$SubjectsTableOrderingComposer,
      $$SubjectsTableAnnotationComposer,
      $$SubjectsTableCreateCompanionBuilder,
      $$SubjectsTableUpdateCompanionBuilder,
      (Subject, BaseReferences<_$AppDatabase, $SubjectsTable, Subject>),
      Subject,
      PrefetchHooks Function()
    >;
typedef $$CachedTeachersTableCreateCompanionBuilder =
    CachedTeachersCompanion Function({
      required String idComision,
      required String normalizedName,
      required String displayName,
      Value<String> role,
      Value<String> avatarUrl,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedTeachersTableUpdateCompanionBuilder =
    CachedTeachersCompanion Function({
      Value<String> idComision,
      Value<String> normalizedName,
      Value<String> displayName,
      Value<String> role,
      Value<String> avatarUrl,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedTeachersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedTeachersTable> {
  $$CachedTeachersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedTeachersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedTeachersTable> {
  $$CachedTeachersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedTeachersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedTeachersTable> {
  $$CachedTeachersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedTeachersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedTeachersTable,
          CachedTeacher,
          $$CachedTeachersTableFilterComposer,
          $$CachedTeachersTableOrderingComposer,
          $$CachedTeachersTableAnnotationComposer,
          $$CachedTeachersTableCreateCompanionBuilder,
          $$CachedTeachersTableUpdateCompanionBuilder,
          (
            CachedTeacher,
            BaseReferences<_$AppDatabase, $CachedTeachersTable, CachedTeacher>,
          ),
          CachedTeacher,
          PrefetchHooks Function()
        > {
  $$CachedTeachersTableTableManager(
    _$AppDatabase db,
    $CachedTeachersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTeachersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedTeachersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTeachersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idComision = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> avatarUrl = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedTeachersCompanion(
                idComision: idComision,
                normalizedName: normalizedName,
                displayName: displayName,
                role: role,
                avatarUrl: avatarUrl,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idComision,
                required String normalizedName,
                required String displayName,
                Value<String> role = const Value.absent(),
                Value<String> avatarUrl = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedTeachersCompanion.insert(
                idComision: idComision,
                normalizedName: normalizedName,
                displayName: displayName,
                role: role,
                avatarUrl: avatarUrl,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedTeachersTable, CachedTeacher>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedTeachersTable,
                    CachedTeacher
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedTeachersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedTeachersTable,
      CachedTeacher,
      $$CachedTeachersTableFilterComposer,
      $$CachedTeachersTableOrderingComposer,
      $$CachedTeachersTableAnnotationComposer,
      $$CachedTeachersTableCreateCompanionBuilder,
      $$CachedTeachersTableUpdateCompanionBuilder,
      (
        CachedTeacher,
        BaseReferences<_$AppDatabase, $CachedTeachersTable, CachedTeacher>,
      ),
      CachedTeacher,
      PrefetchHooks Function()
    >;
typedef $$SnapshotEntriesTableCreateCompanionBuilder =
    SnapshotEntriesCompanion Function({
      required String idComision,
      required String module,
      required String itemId,
      required String fingerprint,
      Value<String> summary,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SnapshotEntriesTableUpdateCompanionBuilder =
    SnapshotEntriesCompanion Function({
      Value<String> idComision,
      Value<String> module,
      Value<String> itemId,
      Value<String> fingerprint,
      Value<String> summary,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SnapshotEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SnapshotEntriesTable> {
  $$SnapshotEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SnapshotEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SnapshotEntriesTable> {
  $$SnapshotEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SnapshotEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SnapshotEntriesTable> {
  $$SnapshotEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SnapshotEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SnapshotEntriesTable,
          SnapshotEntry,
          $$SnapshotEntriesTableFilterComposer,
          $$SnapshotEntriesTableOrderingComposer,
          $$SnapshotEntriesTableAnnotationComposer,
          $$SnapshotEntriesTableCreateCompanionBuilder,
          $$SnapshotEntriesTableUpdateCompanionBuilder,
          (
            SnapshotEntry,
            BaseReferences<_$AppDatabase, $SnapshotEntriesTable, SnapshotEntry>,
          ),
          SnapshotEntry,
          PrefetchHooks Function()
        > {
  $$SnapshotEntriesTableTableManager(
    _$AppDatabase db,
    $SnapshotEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnapshotEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnapshotEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idComision = const Value.absent(),
                Value<String> module = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotEntriesCompanion(
                idComision: idComision,
                module: module,
                itemId: itemId,
                fingerprint: fingerprint,
                summary: summary,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idComision,
                required String module,
                required String itemId,
                required String fingerprint,
                Value<String> summary = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SnapshotEntriesCompanion.insert(
                idComision: idComision,
                module: module,
                itemId: itemId,
                fingerprint: fingerprint,
                summary: summary,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SnapshotEntriesTable, SnapshotEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SnapshotEntriesTable,
                    SnapshotEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SnapshotEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SnapshotEntriesTable,
      SnapshotEntry,
      $$SnapshotEntriesTableFilterComposer,
      $$SnapshotEntriesTableOrderingComposer,
      $$SnapshotEntriesTableAnnotationComposer,
      $$SnapshotEntriesTableCreateCompanionBuilder,
      $$SnapshotEntriesTableUpdateCompanionBuilder,
      (
        SnapshotEntry,
        BaseReferences<_$AppDatabase, $SnapshotEntriesTable, SnapshotEntry>,
      ),
      SnapshotEntry,
      PrefetchHooks Function()
    >;
typedef $$NotificationLogsTableCreateCompanionBuilder =
    NotificationLogsCompanion Function({
      Value<int> id,
      required String dedupeKey,
      required String idComision,
      required String subjectName,
      required String module,
      required String title,
      required String body,
      Value<String> targetUrl,
      Value<bool> isRead,
      required DateTime createdAt,
    });
typedef $$NotificationLogsTableUpdateCompanionBuilder =
    NotificationLogsCompanion Function({
      Value<int> id,
      Value<String> dedupeKey,
      Value<String> idComision,
      Value<String> subjectName,
      Value<String> module,
      Value<String> title,
      Value<String> body,
      Value<String> targetUrl,
      Value<bool> isRead,
      Value<DateTime> createdAt,
    });

class $$NotificationLogsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableFilterComposer({
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

  ColumnFilters<String> get dedupeKey => $composableBuilder(
    column: $table.dedupeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetUrl => $composableBuilder(
    column: $table.targetUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableOrderingComposer({
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

  ColumnOrderings<String> get dedupeKey => $composableBuilder(
    column: $table.dedupeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetUrl => $composableBuilder(
    column: $table.targetUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dedupeKey =>
      $composableBuilder(column: $table.dedupeKey, builder: (column) => column);

  GeneratedColumn<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get targetUrl =>
      $composableBuilder(column: $table.targetUrl, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NotificationLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationLogsTable,
          NotificationLog,
          $$NotificationLogsTableFilterComposer,
          $$NotificationLogsTableOrderingComposer,
          $$NotificationLogsTableAnnotationComposer,
          $$NotificationLogsTableCreateCompanionBuilder,
          $$NotificationLogsTableUpdateCompanionBuilder,
          (
            NotificationLog,
            BaseReferences<
              _$AppDatabase,
              $NotificationLogsTable,
              NotificationLog
            >,
          ),
          NotificationLog,
          PrefetchHooks Function()
        > {
  $$NotificationLogsTableTableManager(
    _$AppDatabase db,
    $NotificationLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dedupeKey = const Value.absent(),
                Value<String> idComision = const Value.absent(),
                Value<String> subjectName = const Value.absent(),
                Value<String> module = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> targetUrl = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => NotificationLogsCompanion(
                id: id,
                dedupeKey: dedupeKey,
                idComision: idComision,
                subjectName: subjectName,
                module: module,
                title: title,
                body: body,
                targetUrl: targetUrl,
                isRead: isRead,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dedupeKey,
                required String idComision,
                required String subjectName,
                required String module,
                required String title,
                required String body,
                Value<String> targetUrl = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                required DateTime createdAt,
              }) => NotificationLogsCompanion.insert(
                id: id,
                dedupeKey: dedupeKey,
                idComision: idComision,
                subjectName: subjectName,
                module: module,
                title: title,
                body: body,
                targetUrl: targetUrl,
                isRead: isRead,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotificationLogsTable, NotificationLog>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $NotificationLogsTable,
                    NotificationLog
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationLogsTable,
      NotificationLog,
      $$NotificationLogsTableFilterComposer,
      $$NotificationLogsTableOrderingComposer,
      $$NotificationLogsTableAnnotationComposer,
      $$NotificationLogsTableCreateCompanionBuilder,
      $$NotificationLogsTableUpdateCompanionBuilder,
      (
        NotificationLog,
        BaseReferences<_$AppDatabase, $NotificationLogsTable, NotificationLog>,
      ),
      NotificationLog,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
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

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$DownloadedResourcesTableCreateCompanionBuilder =
    DownloadedResourcesCompanion Function({
      Value<int> id,
      required String idComision,
      required String module,
      required String resourceId,
      required String title,
      required String localPath,
      required BigInt fileSize,
      Value<String?> sha256,
      required DateTime downloadedAt,
    });
typedef $$DownloadedResourcesTableUpdateCompanionBuilder =
    DownloadedResourcesCompanion Function({
      Value<int> id,
      Value<String> idComision,
      Value<String> module,
      Value<String> resourceId,
      Value<String> title,
      Value<String> localPath,
      Value<BigInt> fileSize,
      Value<String?> sha256,
      Value<DateTime> downloadedAt,
    });

class $$DownloadedResourcesTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadedResourcesTable> {
  $$DownloadedResourcesTableFilterComposer({
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

  ColumnFilters<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadedResourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadedResourcesTable> {
  $$DownloadedResourcesTableOrderingComposer({
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

  ColumnOrderings<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadedResourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadedResourcesTable> {
  $$DownloadedResourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idComision => $composableBuilder(
    column: $table.idComision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<BigInt> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );
}

class $$DownloadedResourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadedResourcesTable,
          DownloadedResource,
          $$DownloadedResourcesTableFilterComposer,
          $$DownloadedResourcesTableOrderingComposer,
          $$DownloadedResourcesTableAnnotationComposer,
          $$DownloadedResourcesTableCreateCompanionBuilder,
          $$DownloadedResourcesTableUpdateCompanionBuilder,
          (
            DownloadedResource,
            BaseReferences<
              _$AppDatabase,
              $DownloadedResourcesTable,
              DownloadedResource
            >,
          ),
          DownloadedResource,
          PrefetchHooks Function()
        > {
  $$DownloadedResourcesTableTableManager(
    _$AppDatabase db,
    $DownloadedResourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadedResourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadedResourcesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DownloadedResourcesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> idComision = const Value.absent(),
                Value<String> module = const Value.absent(),
                Value<String> resourceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<BigInt> fileSize = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
              }) => DownloadedResourcesCompanion(
                id: id,
                idComision: idComision,
                module: module,
                resourceId: resourceId,
                title: title,
                localPath: localPath,
                fileSize: fileSize,
                sha256: sha256,
                downloadedAt: downloadedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String idComision,
                required String module,
                required String resourceId,
                required String title,
                required String localPath,
                required BigInt fileSize,
                Value<String?> sha256 = const Value.absent(),
                required DateTime downloadedAt,
              }) => DownloadedResourcesCompanion.insert(
                id: id,
                idComision: idComision,
                module: module,
                resourceId: resourceId,
                title: title,
                localPath: localPath,
                fileSize: fileSize,
                sha256: sha256,
                downloadedAt: downloadedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadedResourcesTable, DownloadedResource>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $DownloadedResourcesTable,
                    DownloadedResource
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadedResourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadedResourcesTable,
      DownloadedResource,
      $$DownloadedResourcesTableFilterComposer,
      $$DownloadedResourcesTableOrderingComposer,
      $$DownloadedResourcesTableAnnotationComposer,
      $$DownloadedResourcesTableCreateCompanionBuilder,
      $$DownloadedResourcesTableUpdateCompanionBuilder,
      (
        DownloadedResource,
        BaseReferences<
          _$AppDatabase,
          $DownloadedResourcesTable,
          DownloadedResource
        >,
      ),
      DownloadedResource,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$CachedTeachersTableTableManager get cachedTeachers =>
      $$CachedTeachersTableTableManager(_db, _db.cachedTeachers);
  $$SnapshotEntriesTableTableManager get snapshotEntries =>
      $$SnapshotEntriesTableTableManager(_db, _db.snapshotEntries);
  $$NotificationLogsTableTableManager get notificationLogs =>
      $$NotificationLogsTableTableManager(_db, _db.notificationLogs);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$DownloadedResourcesTableTableManager get downloadedResources =>
      $$DownloadedResourcesTableTableManager(_db, _db.downloadedResources);
}
