import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_providers.dart';
import '../../core/network/miel_client.dart';
import '../../core/theme/libremiel_brand.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _rememberCredentials = true;
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '¡Buenos días!';
    if (hour >= 12 && hour < 20) return '¡Buenas tardes!';
    return '¡Buenas noches!';
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final result = await ref
        .read(appSessionProvider.notifier)
        .login(
          username: _userController.text.trim(),
          password: _passController.text,
          saveCredentials: _rememberCredentials,
        );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (!result.isSuccess) {
        _errorText = result.message ?? 'No se pudo iniciar sesión en MIeL.';
      }
    });
  }

  InputDecoration _mielInputDecoration({String? hint, Widget? suffixIcon}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.55),
        width: 1,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.92),
        width: 1.2,
      ),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: const BorderSide(color: Color(0xFFFFD6D6), width: 1.2),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.12),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      errorStyle: const TextStyle(
        color: Color(0xFFFFF3C4),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 768;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado esmeralda -> verde lima estilo MIeL + hexágonos flotantes animados
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF009674), Color(0xFF63CB5F)],
                ),
              ),
              child: RepaintBoundary(child: _AnimatedHexagonsBackground()),
            ),
          ),

          // Contenido principal con barra superior oscura
          Column(
            children: [
              // Header fijo superior (rgba(0, 22, 6, 0.9))
              Container(
                height: isWide ? 68 : 54,
                width: double.infinity,
                color: const Color.fromRGBO(0, 22, 6, 0.90),
                padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      LibreMielMark(size: isWide ? 36 : 30, lightText: true),
                      if (isWide) ...[
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'Cliente no oficial · Open Source',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Área Hero (2 columnas en desktop, 1 columna centrada en mobile)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 36 : 18,
                      vertical: 28,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(flex: 6, child: _buildHeroTitles()),
                                const SizedBox(width: 48),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 440,
                                  ),
                                  child: _buildLoginCard(),
                                ),
                              ],
                            )
                          : Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 440,
                                ),
                                child: _buildLoginCard(),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTitles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Materias\nInteractivas\nen Línea',
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.02,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Cliente libre y multiplataforma para MIeL\nde la Universidad Nacional de La Matanza',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: Colors.white.withValues(alpha: 0.95),
            height: 1.25,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Notificaciones locales de contenidos, portafolio, mensajería y foros.\n'
          'Conexión directa a miel.unlam.edu.ar sin servidores intermedios.',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _greetingForNow(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 22),

            // Campo Usuario
            const Text(
              'Usuario:',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _userController,
              enabled: !_submitting,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: _mielInputDecoration(hint: 'DNI'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresá tu DNI';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo Contraseña + link "Olvidé mi contraseña"
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 2,
              children: [
                const Text(
                  'Contraseña:',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _openExternal(
                      '$kMielBaseUrl/principal/event/recuperarClave/',
                    ),
                    child: const Text(
                      'Olvidé mi contraseña',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passController,
              enabled: !_submitting,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: _mielInputDecoration(
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Mostrar' : 'Ocultar',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresá tu contraseña';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Checkbox "Mantener mi sesión activa." + tooltip de ayuda
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _rememberCredentials,
                    onChanged: _submitting
                        ? null
                        : (v) =>
                              setState(() => _rememberCredentials = v ?? true),
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.transparent;
                    }),
                    checkColor: const Color(0xFF009674),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: MouseRegion(
                    cursor: _submitting
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _submitting
                          ? null
                          : () => setState(
                              () =>
                                  _rememberCredentials = !_rememberCredentials,
                            ),
                      child: const Text(
                        'Mantener mi sesión activa.',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message:
                      'Guarda tus credenciales en el llavero seguro del dispositivo '
                      'para revisar novedades de MIeL en segundo plano.',
                  child: Icon(
                    Icons.help_outline,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A1616).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: const Color(0xFFFFB4AB).withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Botón primario blanco con texto #009674 (.primary-button)
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.92),
                  foregroundColor: const Color(0xFF009674),
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.65),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                child: _submitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFF009674),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Conectando con MIeL…',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Ingresar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 16),

            // Botón secundario translúcido
            SizedBox(
              height: 42,
              child: TextButton(
                onPressed: () => _openExternal('$kMielBaseUrl/principal/home/'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Abrir MIeL en el navegador',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            Text(
              'Privacidad local: tus credenciales se envían directo a '
              'miel.unlam.edu.ar y nunca pasan por servidores externos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondo animado de hexágonos blancos translúcidos subiendo y rotando como en `/principal/home/` de MIeL.
class _AnimatedHexagonsBackground extends StatefulWidget {
  const _AnimatedHexagonsBackground();

  @override
  State<_AnimatedHexagonsBackground> createState() =>
      _AnimatedHexagonsBackgroundState();
}

class _AnimatedHexagonsBackgroundState
    extends State<_AnimatedHexagonsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FloatingHexagonsPainter(progress: _controller),
    );
  }
}

class _FloatingHexagonsPainter extends CustomPainter {
  _FloatingHexagonsPainter({required this.progress}) : super(repaint: progress);

  final Animation<double> progress;

  static const _hexSpecs =
      <
        ({
          double x,
          double phase,
          double r,
          double speed,
          double rotSpeed,
          double sway,
          double maxAlpha,
        })
      >[
        (
          x: 0.07,
          phase: 0.08,
          r: 68,
          speed: 1.0,
          rotSpeed: 0.8,
          sway: 16,
          maxAlpha: 0.13,
        ),
        (
          x: 0.14,
          phase: 0.42,
          r: 92,
          speed: 0.75,
          rotSpeed: -0.6,
          sway: 20,
          maxAlpha: 0.11,
        ),
        (
          x: 0.22,
          phase: 0.76,
          r: 26,
          speed: 1.45,
          rotSpeed: 1.4,
          sway: 12,
          maxAlpha: 0.17,
        ),
        (
          x: 0.31,
          phase: 0.22,
          r: 80,
          speed: 0.85,
          rotSpeed: 0.7,
          sway: 18,
          maxAlpha: 0.12,
        ),
        (
          x: 0.41,
          phase: 0.61,
          r: 50,
          speed: 1.15,
          rotSpeed: -1.0,
          sway: 14,
          maxAlpha: 0.13,
        ),
        (
          x: 0.52,
          phase: 0.15,
          r: 34,
          speed: 1.35,
          rotSpeed: 1.2,
          sway: 10,
          maxAlpha: 0.15,
        ),
        (
          x: 0.63,
          phase: 0.88,
          r: 72,
          speed: 0.9,
          rotSpeed: -0.75,
          sway: 16,
          maxAlpha: 0.12,
        ),
        (
          x: 0.76,
          phase: 0.34,
          r: 42,
          speed: 1.25,
          rotSpeed: 1.1,
          sway: 15,
          maxAlpha: 0.14,
        ),
        (
          x: 0.87,
          phase: 0.68,
          r: 58,
          speed: 1.05,
          rotSpeed: -0.9,
          sway: 18,
          maxAlpha: 0.14,
        ),
        (
          x: 0.94,
          phase: 0.04,
          r: 84,
          speed: 0.8,
          rotSpeed: 0.65,
          sway: 14,
          maxAlpha: 0.11,
        ),
      ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    for (final spec in _hexSpecs) {
      final cycle = (spec.phase + t * spec.speed) % 1.0;
      // Flota desde abajo (1.18) hacia arriba (-0.18)
      final cy = size.height * (1.18 - cycle * 1.36);
      final cx =
          size.width * spec.x +
          math.sin(cycle * math.pi * 2 + spec.phase * 6) * spec.sway;

      // Fundido suave al entrar por abajo y salir por arriba
      final edgeFade = cycle < 0.12
          ? cycle / 0.12
          : cycle > 0.86
          ? (1.0 - cycle) / 0.14
          : 1.0;
      final alpha = (spec.maxAlpha * edgeFade).clamp(0.0, 1.0);
      if (alpha <= 0.002) continue;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      final rot = spec.phase * math.pi + t * spec.rotSpeed * math.pi * 2;
      final path = Path();
      for (var i = 0; i < 6; i++) {
        final angle = rot + (math.pi / 3) * i;
        final px = cx + spec.r * math.cos(angle);
        final py = cy + spec.r * math.sin(angle);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingHexagonsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
