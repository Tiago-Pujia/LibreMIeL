import 'package:material_ui/material_ui.dart';

/// Renderiza el ícono de tipo de archivo con la paleta semántica exacta de
/// `material-file-types.css` y `material-file-types-dark.css` de MIeL (`2025.2.0`).
class MielFileTypeIcon extends StatelessWidget {
  const MielFileTypeIcon({super.key, required this.fileType, this.size = 22});

  final String fileType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final norm = fileType.trim().toLowerCase();

    final (IconData icon, Color lightColor, Color darkColor) = switch (norm) {
      'pdf' => (
        Icons.picture_as_pdf,
        const Color(0xFFF44336),
        const Color(0xFFD47D75),
      ),
      'word' || 'doc' || 'docx' => (
        Icons.article,
        const Color(0xFF3F51B5),
        const Color(0xFF7887D6),
      ),
      'excel' || 'xls' || 'xlsx' => (
        Icons.table_chart,
        const Color(0xFF4CAF50),
        const Color(0xFF9AC89C),
      ),
      'power' || 'ppt' || 'pptx' => (
        Icons.slideshow,
        const Color(0xFFFF9800),
        const Color(0xFFEBB850),
      ),
      'zip' || 'rar' || '7z' => (
        Icons.folder_zip,
        const Color(0xFF9C27B0),
        const Color(0xFFCA84D6),
      ),
      'cloud' => (
        Icons.cloud_download,
        const Color(0xFF2196F3),
        const Color(0xFF72A0C5),
      ),
      'explore' || 'web' || 'link' => (
        Icons.pageview,
        const Color(0xFF2196F3),
        const Color(0xFF72A0C5),
      ),
      'exe' || 'settings' => (
        Icons.terminal,
        const Color(0xFF607D8B),
        const Color(0xFFC5CCD9),
      ),
      'code' => (Icons.code, const Color(0xFF009688), const Color(0xFF71B0AB)),
      'picture' ||
      'image' ||
      'png' ||
      'jpg' ||
      'jpeg' => (Icons.image, const Color(0xFFFFC107), const Color(0xFFE8E79D)),
      'audio' || 'mp3' => (
        Icons.audiotrack,
        const Color(0xFFE91E63),
        const Color(0xFFF1809D),
      ),
      'video' || 'youtube' || 'mp4' => (
        Icons.ondemand_video,
        const Color(0xFFE91E63),
        const Color(0xFFF1809D),
      ),
      _ => (
        Icons.description,
        const Color(0xFF9E9E9E),
        const Color(0xFFBBBBBB),
      ),
    };

    return Icon(icon, size: size, color: isDark ? darkColor : lightColor);
  }
}
