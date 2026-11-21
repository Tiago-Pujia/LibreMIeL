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
        return '/autoguia/modulos/comision/$idComision';
      case MielToolKind.portafolio:
        return '/portafolio/practicas/comision/$idComision';
      case MielToolKind.mensajeria:
        return '/mensajeria/entrada/comision/$idComision';
      case MielToolKind.foro:
        return '/forov2/temas/comision/$idComision';
      case MielToolKind.chat:
        return '/chat/chat/comision/$idComision';
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
    this.studentAvatarUrl = '',
  });

  final String studentName;
  final String studentAvatarUrl;
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

/// Archivo o imagen adjunta en Mensajería, Foros o Portafolio.
class MielAttachment {
  const MielAttachment({
    required this.fileName,
    required this.downloadUrl,
    this.fileType = 'archivo',
    this.isImage = false,
  });

  final String fileName;
  final String downloadUrl;
  final String fileType;
  final bool isImage;
}

class ContentItem {
  const ContentItem({
    required this.idElemento,
    required this.idComision,
    required this.moduleName,
    required this.title,
    required this.uploadDate,
    required this.url,
    this.submoduleName = '',
    this.description = '',
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
  final String submoduleName;
  final String title;
  final String description;
  final String uploadDate;
  final String url;
  final String fileType;
  final String readingType;
  final String sizeLabel;
  final bool isExternal;
  final bool isHighlightedNew;
  final bool isDownloaded;

  ContentItem copyWith({bool? isDownloaded}) {
    return ContentItem(
      idElemento: idElemento,
      idComision: idComision,
      moduleName: moduleName,
      submoduleName: submoduleName,
      title: title,
      description: description,
      uploadDate: uploadDate,
      url: url,
      fileType: fileType,
      readingType: readingType,
      sizeLabel: sizeLabel,
      isExternal: isExternal,
      isHighlightedNew: isHighlightedNew,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

/// Submódulo dentro de una tabla de Contenidos (par `<thead>` + `<tbody>`).
class ContentSubmodule {
  const ContentSubmodule({
    required this.title,
    required this.items,
    this.description = '',
  });

  final String title;
  final String description;
  final List<ContentItem> items;
}

/// Carpeta plegable (`.desplegarModulo`) o sección directa de Contenidos.
class ContentSection {
  const ContentSection({
    required this.title,
    required this.isCollapsibleFolder,
    required this.submodules,
    this.description = '',
    this.unreadBadge = 0,
  });

  final String title;
  final String description;
  final bool isCollapsibleFolder;
  final int unreadBadge;
  final List<ContentSubmodule> submodules;

  List<ContentItem> get allItems => <ContentItem>[
    for (final sub in submodules) ...sub.items,
  ];
}

/// Estructura completa de `/contenido/archivos/comision/{idComision}`.
class ContentPageData {
  const ContentPageData({
    required this.idComision,
    required this.sections,
    required this.allItems,
  });

  final String idComision;
  final List<ContentSection> sections;
  final List<ContentItem> allItems;
}

class GlossaryEntry {
  const GlossaryEntry({required this.term, required this.definition});

  final String term;
  final String definition;
}

class GlossaryPageData {
  const GlossaryPageData({
    required this.activeLetter,
    required this.enabledLetters,
    required this.entries,
  });

  final String activeLetter;
  final Set<String> enabledLetters;
  final List<GlossaryEntry> entries;
}

class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
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

/// Bloque `div.entrega` en `/portafolio/entregas/comision/{id}/id/{idPractica}`.
class PortfolioDelivery {
  const PortfolioDelivery({
    required this.title,
    required this.dateTime,
    required this.fileName,
    required this.downloadUrl,
    this.isGroupDelivery = false,
    this.groupName = '',
    this.members = const [],
    this.message = '',
  });

  final String title;
  final String dateTime;
  final String fileName;
  final String downloadUrl;
  final bool isGroupDelivery;
  final String groupName;
  final List<String> members;
  final String message;
}

/// Detalle completo de una práctica (`/portafolio/entregas/...`).
class PortfolioPracticeDetail {
  const PortfolioPracticeDetail({
    required this.idComision,
    required this.idPractica,
    required this.headerTitle,
    required this.deliveryModeLabel,
    required this.corrections,
    required this.deliveries,
    this.promptDownloadUrl = '',
  });

  final String idComision;
  final String idPractica;
  final String headerTitle;
  final String promptDownloadUrl;
  final String deliveryModeLabel;
  final List<PortfolioCorrection> corrections;
  final List<PortfolioDelivery> deliveries;
}

class PortfolioSentFile {
  const PortfolioSentFile({
    required this.idEntrega,
    required this.practiceTitle,
    required this.fileName,
    required this.fileType,
    required this.dateTime,
    required this.sizeLabel,
    required this.downloadUrl,
  });

  final String idEntrega;
  final String practiceTitle;
  final String fileName;
  final String fileType;
  final String dateTime;
  final String sizeLabel;
  final String downloadUrl;
}

class PortfolioGroup {
  const PortfolioGroup({
    required this.idGrupo,
    required this.name,
    required this.members,
    this.messageUrl = '',
  });

  final String idGrupo;
  final String name;
  final List<String> members;
  final String messageUrl;
}

class AttendanceEntry {
  const AttendanceEntry({
    required this.date,
    required this.status,
    required this.isPresent,
    this.isJustified = false,
    this.modality = '',
  });

  final String date;
  final String status;
  final bool isPresent;
  final bool isJustified;
  final String modality;
}

class EvaluationGradeEntry {
  const EvaluationGradeEntry({
    required this.title,
    this.date = '',
    this.grade = '',
    this.status = '',
  });

  final String title;
  final String date;
  final String grade;
  final String status;
}

class CertificateItem {
  const CertificateItem({
    required this.title,
    required this.downloadUrl,
    this.date = '',
  });

  final String title;
  final String date;
  final String downloadUrl;
}

class PortfolioGradesData {
  const PortfolioGradesData({
    required this.attendance,
    required this.evaluationGrades,
    required this.certificates,
  });

  final List<AttendanceEntry> attendance;
  final List<EvaluationGradeEntry> evaluationGrades;
  final List<CertificateItem> certificates;
}

class CompetencyRow {
  const CompetencyRow({
    required this.title,
    this.level = '',
    this.observations = '',
  });

  final String title;
  final String level;
  final String observations;
}

class PortfolioCompetenciesData {
  const PortfolioCompetenciesData({
    required this.isEnabled,
    required this.rows,
    this.emptyMessage = '',
  });

  final bool isEnabled;
  final String emptyMessage;
  final List<CompetencyRow> rows;
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
    this.isFavorite = false,
    this.isReplied = false,
    this.isOutbox = false,
    this.readByRecipient = false,
    this.subjectNameLabel = '',
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
  final bool isFavorite;
  final bool isReplied;
  final bool isOutbox;
  final bool readByRecipient;
  final String subjectNameLabel;

  InboxMessageSummary copyWith({
    bool? isUnread,
    bool? isFavorite,
    String? readDate,
    String? subjectNameLabel,
  }) {
    return InboxMessageSummary(
      idMensaje: idMensaje,
      idComision: idComision,
      date: date,
      senderName: senderName,
      subject: subject,
      hasAttachment: hasAttachment,
      isUnread: isUnread ?? this.isUnread,
      isPracticeMessage: isPracticeMessage,
      readDate: readDate ?? this.readDate,
      detailUrl: detailUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isReplied: isReplied,
      isOutbox: isOutbox,
      readByRecipient: readByRecipient,
      subjectNameLabel: subjectNameLabel ?? this.subjectNameLabel,
    );
  }
}

class MessageBoxPageData {
  const MessageBoxPageData({
    required this.idComision,
    required this.currentPage,
    required this.totalPages,
    required this.messages,
    this.unreadGeneralCount = 0,
    this.unreadPracticesCount = 0,
  });

  final String idComision;
  final int currentPage;
  final int totalPages;
  final int unreadGeneralCount;
  final int unreadPracticesCount;
  final List<InboxMessageSummary> messages;
}

class MessageRecipient {
  const MessageRecipient({required this.name, this.roleType = 'alumno'});

  final String name;
  final String roleType;
}

class MessageDetail {
  const MessageDetail({
    required this.idComision,
    required this.idMensaje,
    required this.subject,
    required this.senderName,
    required this.senderRole,
    required this.isTeacher,
    required this.recipientsSummary,
    required this.dateTime,
    required this.bodyHtml,
    required this.bodyPlainText,
    this.senderAvatarUrl = '',
    this.recipientsPopupUrl = '',
    this.attachments = const [],
  });

  final String idComision;
  final String idMensaje;
  final String subject;
  final String senderName;
  final String senderRole;
  final String senderAvatarUrl;
  final bool isTeacher;
  final String recipientsSummary;
  final String recipientsPopupUrl;
  final String dateTime;
  final String bodyHtml;
  final String bodyPlainText;
  final List<MielAttachment> attachments;
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
    this.isPublic = false,
  });

  final String idTema;
  final String idComision;
  final String title;
  final String description;
  final int messageCount;
  final String lastMessageDate;
  final int unreadBadge;
  final bool isClosed;
  final bool isPublic;
  final String url;

  String get fingerprint =>
      '$messageCount|$lastMessageDate|$unreadBadge|$isClosed';
}

class ForumSidebarTopic {
  const ForumSidebarTopic({
    required this.idTema,
    required this.title,
    required this.url,
  });

  final String idTema;
  final String title;
  final String url;
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
    this.authorAvatarUrl = '',
    this.bodyHtml = '',
    this.mentionedUserIds = const {},
    this.mentionedMessageIds = const {},
    this.imageAttachments = const [],
    this.fileAttachments = const [],
    this.likesCount = 0,
    this.likedByMe = false,
    this.isCollapsedByDefault = false,
  });

  final String id;
  final String parentId;
  final bool isReply;
  final String authorName;
  final String authorId;
  final String authorAvatarUrl;
  final String role;
  final bool isTeacher;
  final String date;
  final String bodyText;
  final String bodyHtml;
  final Set<String> mentionedUserIds;
  final Set<String> mentionedMessageIds;
  final List<MielAttachment> imageAttachments;
  final List<MielAttachment> fileAttachments;
  final int likesCount;
  final bool likedByMe;
  final bool isCollapsedByDefault;
}

class ForumThreadData {
  const ForumThreadData({
    required this.idComision,
    required this.idTema,
    required this.title,
    required this.currentUserId,
    required this.messages,
    this.description = '',
    this.lastMessageDate = '',
    this.totalMessagesCount = 0,
    this.isClosed = false,
    this.sidebarTopics = const [],
  });

  final String idComision;
  final String idTema;
  final String title;
  final String description;
  final String lastMessageDate;
  final int totalMessagesCount;
  final bool isClosed;
  final String currentUserId;
  final List<ForumMessageItem> messages;
  final List<ForumSidebarTopic> sidebarTopics;
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
    this.isLockOpen = true,
  });

  final String id;
  final String idComision;
  final String type;
  final String title;
  final bool isEnabled;
  final String status;
  final bool requiresPassword;
  final bool isLockOpen;

  String get fingerprint => '$isEnabled|$status|$requiresPassword';
}

class SurveyItem {
  const SurveyItem({
    required this.id,
    required this.idComision,
    required this.title,
    required this.status,
    required this.url,
    this.isAvailable = true,
  });

  final String id;
  final String idComision;
  final String title;
  final String status;
  final String url;
  final bool isAvailable;
}

class AutoguiaModule {
  const AutoguiaModule({
    required this.id,
    required this.idComision,
    required this.title,
    this.description = '',
    this.progressPercent = 0,
    this.url = '',
  });

  final String id;
  final String idComision;
  final String title;
  final String description;
  final int progressPercent;
  final String url;
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
