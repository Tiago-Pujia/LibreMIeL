/// Modelos inmutables del dominio de LibreMIEL.
library;

enum MielAuthStatus {
  ok,
  invalidCredentials,
  accountBlocked,
  networkError,
  invalidResponse,
}

class MielLoginResult {
  const MielLoginResult({required this.status, this.rawCode, this.message});

  final MielAuthStatus status;
  final int? rawCode;
  final String? message;

  bool get isSuccess => status == MielAuthStatus.ok;
}

enum MielModuleType {
  contenidos,
  portafolio,
  mensajeria,
  foros,
  evaluacion,
  novedades,
  sistema,
}

/// Categoría visual semántica de cada herramienta en el panel de MIeL.
enum MielToolCategory { materials, communication, evaluation }

/// Herramientas que aparecen en la barra horizontal de cada tarjeta de materia en MIeL.
enum MielToolKind {
  contenidos(
    shortLabel: 'Contenidos',
    fullLabel: 'Contenidos',
    category: MielToolCategory.materials,
  ),
  autoguia(
    shortLabel: 'Autoguía',
    fullLabel: 'Autoguía',
    category: MielToolCategory.materials,
  ),
  portafolio(
    shortLabel: 'Portafolio',
    fullLabel: 'Portafolio',
    category: MielToolCategory.materials,
  ),
  mensajeria(
    shortLabel: 'Mensajes',
    fullLabel: 'Mensajería',
    category: MielToolCategory.communication,
  ),
  foro(
    shortLabel: 'Foro',
    fullLabel: 'Foros',
    category: MielToolCategory.communication,
  ),
  chat(
    shortLabel: 'Chat',
    fullLabel: 'Chat',
    category: MielToolCategory.communication,
  ),
  encuestas(
    shortLabel: 'Encuestas',
    fullLabel: 'Encuestas',
    category: MielToolCategory.evaluation,
  ),
  evaluacion(
    shortLabel: 'Evaluación',
    fullLabel: 'Evaluación',
    category: MielToolCategory.evaluation,
  );

  const MielToolKind({
    required this.shortLabel,
    required this.fullLabel,
    required this.category,
  });

  final String shortLabel;
  final String fullLabel;
  final MielToolCategory category;

  /// Ruta relativa oficial en MIeL para la comisión indicada.
  String pathForCommission(String idComision) {
    switch (this) {
      case MielToolKind.contenidos:
        return '/contenido/archivos/comision/$idComision';
      case MielToolKind.autoguia:
        return '/autoguia/index/comision/$idComision';
      case MielToolKind.portafolio:
        return '/portafolio/practicas/comision/$idComision';
      case MielToolKind.mensajeria:
        return '/mensajeria/entrada/comision/$idComision';
      case MielToolKind.foro:
        return '/forov2/temas/comision/$idComision';
      case MielToolKind.chat:
        return '/chat/salas/comision/$idComision';
      case MielToolKind.encuestas:
        return '/encuesta/encuestas/comision/$idComision';
      case MielToolKind.evaluacion:
        return '/evaluacion/evaluaciones/comision/$idComision';
    }
  }

  /// Clave de snapshots locales en SQLite asociada al módulo, si aplica.
  String? get snapshotModuleKey {
    switch (this) {
      case MielToolKind.contenidos:
        return 'contenidos';
      case MielToolKind.portafolio:
        return 'portafolio';
      case MielToolKind.mensajeria:
        return 'mensajeria';
      case MielToolKind.foro:
        return 'foro_temas';
      case MielToolKind.evaluacion:
        return 'evaluacion';
      case MielToolKind.autoguia:
      case MielToolKind.chat:
      case MielToolKind.encuestas:
        return null;
    }
  }
}

enum ForumSyncMode {
  /// Consulta solo /forov2/temas/comision/{id} sin abrir hilos (no borra badges en MIEL web).
  nonInvasive,

  /// Abre hilos con actividad para detectar respuestas de docentes (Tutor/a) al usuario.
  teacherReplies,
}

class MielCredentials {
  const MielCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

class MielSubjectBadgeSummary {
  const MielSubjectBadgeSummary({
    required this.idComision,
    required this.name,
    required this.commissionCode,
    required this.isHidden,
    this.subjectCode = '',
    this.roleLabel = '',
    this.contenidosBadge = 0,
    this.mensajesBadge = 0,
    this.foroBadge = 0,
    this.hasContenidos = true,
    this.hasPortafolio = false,
    this.hasMensajeria = true,
    this.hasForo = true,
    this.hasEvaluacion = false,
    this.hasChat = false,
    this.hasAutoguia = false,
    this.hasEncuestas = false,
  });

  final String idComision;
  final String name;
  final String subjectCode;
  final String commissionCode;
  final String roleLabel;
  final bool isHidden;
  final int contenidosBadge;
  final int mensajesBadge;
  final int foroBadge;
  final bool hasContenidos;
  final bool hasPortafolio;
  final bool hasMensajeria;
  final bool hasForo;
  final bool hasEvaluacion;
  final bool hasChat;
  final bool hasAutoguia;
  final bool hasEncuestas;
}

class InternoOverview {
  const InternoOverview({
    required this.studentName,
    required this.globalNovedadesBadge,
    required this.unreadTitleMessages,
    required this.subjects,
  });

  final String studentName;
  final int globalNovedadesBadge;
  final int unreadTitleMessages;
  final List<MielSubjectBadgeSummary> subjects;
}

class CourseTeacher {
  const CourseTeacher({
    required this.name,
    required this.normalizedName,
    required this.role,
  });

  final String name;
  final String normalizedName;
  final String role;
}

class CourseDetails {
  const CourseDetails({
    required this.idComision,
    required this.teachers,
    this.term = '',
    this.modality = '',
    this.classroom = '',
  });

  final String idComision;
  final List<CourseTeacher> teachers;
  final String term;
  final String modality;
  final String classroom;
}

class ContentItem {
  const ContentItem({
    required this.idElemento,
    required this.idComision,
    required this.moduleName,
    required this.title,
    required this.uploadDate,
    required this.url,
    this.fileType = '',
    this.readingType = '',
    this.sizeLabel = '',
    this.isExternal = false,
    this.isHighlightedNew = false,
    this.isDownloaded = false,
  });

  final String idElemento;
  final String idComision;
  final String moduleName;
  final String title;
  final String uploadDate;
  final String url;
  final String fileType;
  final String readingType;
  final String sizeLabel;
  final bool isExternal;
  final bool isHighlightedNew;
  final bool isDownloaded;
}

class PortfolioPractice {
  const PortfolioPractice({
    required this.idPractica,
    required this.idComision,
    required this.moduleName,
    required this.title,
    required this.deliveryType,
    required this.dueDate,
    required this.deliveryDate,
    required this.correctionDate,
    required this.status,
    required this.grade,
    required this.detailUrl,
    this.promptDownloadUrl = '',
  });

  final String idPractica;
  final String idComision;
  final String moduleName;
  final String title;
  final String deliveryType;
  final String dueDate;
  final String deliveryDate;
  final String correctionDate;
  final String status;
  final String grade;
  final String detailUrl;
  final String promptDownloadUrl;

  String get fingerprint =>
      '$dueDate|$deliveryDate|$correctionDate|$status|$grade';
}

class PortfolioCorrection {
  const PortfolioCorrection({
    required this.dateTime,
    required this.status,
    required this.grade,
    required this.observations,
    required this.correctedBy,
  });

  final String dateTime;
  final String status;
  final String grade;
  final String observations;
  final String correctedBy;
}

class InboxMessageSummary {
  const InboxMessageSummary({
    required this.idMensaje,
    required this.idComision,
    required this.date,
    required this.senderName,
    required this.subject,
    required this.hasAttachment,
    required this.isUnread,
    required this.isPracticeMessage,
    required this.readDate,
    required this.detailUrl,
  });

  final String idMensaje;
  final String idComision;
  final String date;
  final String senderName;
  final String subject;
  final bool hasAttachment;
  final bool isUnread;
  final bool isPracticeMessage;
  final String readDate;
  final String detailUrl;
}

class ForumTopicSummary {
  const ForumTopicSummary({
    required this.idTema,
    required this.idComision,
    required this.title,
    required this.description,
    required this.messageCount,
    required this.lastMessageDate,
    required this.unreadBadge,
    required this.isClosed,
    required this.url,
  });

  final String idTema;
  final String idComision;
  final String title;
  final String description;
  final int messageCount;
  final String lastMessageDate;
  final int unreadBadge;
  final bool isClosed;
  final String url;

  String get fingerprint =>
      '$messageCount|$lastMessageDate|$unreadBadge|$isClosed';
}

class ForumMessageItem {
  const ForumMessageItem({
    required this.id,
    required this.parentId,
    required this.isReply,
    required this.authorName,
    required this.authorId,
    required this.role,
    required this.isTeacher,
    required this.date,
    required this.bodyText,
    this.mentionedUserIds = const {},
    this.mentionedMessageIds = const {},
  });

  final String id;
  final String parentId;
  final bool isReply;
  final String authorName;
  final String authorId;
  final String role;
  final bool isTeacher;
  final String date;
  final String bodyText;
  final Set<String> mentionedUserIds;
  final Set<String> mentionedMessageIds;
}

class ForumThreadData {
  const ForumThreadData({
    required this.idComision,
    required this.idTema,
    required this.title,
    required this.currentUserId,
    required this.messages,
  });

  final String idComision;
  final String idTema;
  final String title;
  final String currentUserId;
  final List<ForumMessageItem> messages;
}

class EvaluationItem {
  const EvaluationItem({
    required this.id,
    required this.idComision,
    required this.type,
    required this.title,
    required this.isEnabled,
    required this.status,
    required this.requiresPassword,
  });

  final String id;
  final String idComision;
  final String type;
  final String title;
  final bool isEnabled;
  final String status;
  final bool requiresPassword;

  String get fingerprint => '$isEnabled|$status|$requiresPassword';
}

class DetectedNotification {
  const DetectedNotification({
    required this.dedupeKey,
    required this.idComision,
    required this.subjectName,
    required this.module,
    required this.title,
    required this.body,
    required this.targetUrl,
    required this.detectedAt,
  });

  final String dedupeKey;
  final String idComision;
  final String subjectName;
  final MielModuleType module;
  final String title;
  final String body;
  final String targetUrl;
  final DateTime detectedAt;
}

class SyncRunSummary {
  const SyncRunSummary({
    required this.cycle,
    required this.isBaseline,
    required this.notifications,
    this.authPaused = false,
    this.authErrorMessage,
    this.warnings = const [],
  });

  final int cycle;
  final bool isBaseline;
  final List<DetectedNotification> notifications;
  final bool authPaused;
  final String? authErrorMessage;
  final List<String> warnings;
}
