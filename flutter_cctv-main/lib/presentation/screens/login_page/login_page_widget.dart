import '/core/state/app_state.dart';
import '/data/services/index.dart';
import '/utils/flutter_flow/animations.dart';
import '/utils/flutter_flow/util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:central_command/presentation/screens/login_page/widgets/background.dart';
import 'package:central_command/presentation/screens/login_page/widgets/form_card.dart';
import 'package:central_command/presentation/screens/login_page/login_page_model.dart';
export 'package:central_command/presentation/screens/login_page/login_page_model.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  static String routeName = 'LoginPage';
  static String routePath = '/LoginPage';

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget>
    with TickerProviderStateMixin {
  late LoginPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginPageModel());

    _model.emailAddressTextController ??= TextEditingController();
    _model.emailAddressFocusNode ??= FocusNode();

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(0.0, 140.0),
            end: Offset.zero,
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(0.9, 1.0),
            end: const Offset(1.0, 1.0),
          ),
          TiltEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(-0.349, 0),
            end: Offset.zero,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // ─── Login Logic ────────────────────────────────────────────────────────────

  Future<void> _triggerLogin(BuildContext context) async {
    final username = _model.emailAddressTextController.text.trim();
    final password = _model.passwordTextController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar(context, 'Please fill in Username and Password');
      return;
    }

    safeSetState(() => _model.isLoading = true);

    _model.apiAuthResult = await AuthService().login(
      username: username,
      password: password,
    );

    if (!mounted) return;

    if (_model.apiAuthResult?.succeeded ?? false) {
      final body = _model.apiAuthResult!.jsonBody;
      final token = body?['accessToken'] ?? body?['token'] ?? '';
      AppState().authToken = token?.toString() ?? '';
      context.goNamed(ListCameraPageWidget.routeName);
    } else {
      safeSetState(() => _model.isLoading = false);
      _showSnackBar(context, 'Login failed. Please check your credentials.');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            LoginBackground(
              child: LoginFormCard(
                model: _model,
                onLogin: () => _triggerLogin(context),
                onTogglePasswordVisibility: () {
                  safeSetState(
                    () => _model.passwordVisibility = !_model.passwordVisibility,
                  );
                },
              ).animateOnPageLoad(
                animationsMap['containerOnPageLoadAnimation']!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}