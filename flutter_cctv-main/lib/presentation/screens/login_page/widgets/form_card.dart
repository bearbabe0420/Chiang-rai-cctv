import 'package:central_command/utils/app_text_styles.dart';

import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/widgets.dart';
import '/core/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:central_command/presentation/screens/login_page/login_page_model.dart';
import 'text_field.dart';

/// Card ฟอร์ม Login ฝั่งขวา
class LoginFormCard extends StatelessWidget {
  final LoginPageModel model;
  final VoidCallback onLogin;
  final VoidCallback onTogglePasswordVisibility;

  const LoginFormCard({
    super.key,
    required this.model,
    required this.onLogin,
    required this.onTogglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    final headingSize = isMobile ? 30.0 : AppTextStyles.displayLarge;

    return Align(
      alignment: isMobile ? Alignment.center : const AlignmentDirectional(1.0, 0.0),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          isMobile ? 20.0 : 0.0,
          isMobile ? 24.0 : 32.0,
          isMobile ? 20.0 : 32.0,
          isMobile ? 24.0 : 32.0,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFDFEFF),
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(
                color: const Color(0xFFCDD8E5),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18.0,
                  color: Color(0x1A0B1A2A),
                  offset: Offset(0.0, 8.0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.0),
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 24.0 : 36.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEF5),
                          borderRadius: BorderRadius.circular(999.0),
                          border: Border.all(color: const Color(0xFFC6D3E1)),
                        ),
                        child: Text(
                          'CENTRALIZED CAMERA COMMAND CENTRE',
                          style: FlutterFlowTheme.of(context).labelSmall.override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                ),
                                color: const Color(0xFF23476B),
                                fontSize: 11.0,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: 18.0),
                      Text(
                        context.tr('login.welcome_back'),
                        style: FlutterFlowTheme.of(context).displaySmall.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                              color: const Color(0xFF163A5F),
                              fontSize: headingSize,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        context.tr('login.subtitle'),
                        style: FlutterFlowTheme.of(context).labelMedium.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w500,
                              ),
                              color: const Color(0xFF5A6E82),
                              fontSize: AppTextStyles.labelNormal,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 24.0),
                      UsernameField(model: model),
                      PasswordField(
                        model: model,
                        onSubmit: onLogin,
                        onToggleVisibility: onTogglePasswordVisibility,
                      ),
                      const SizedBox(height: 10.0),
                      FFButtonWidget(
                        onPressed: model.isLoading ? null : onLogin,
                        text: model.isLoading
                            ? context.tr('login.loading')
                            : context.tr('login.login'),
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 50.0,
                          padding: EdgeInsetsDirectional.zero,
                          iconPadding: EdgeInsetsDirectional.zero,
                          color: const Color(0xFF1F4469),
                          textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                                color: Colors.white,
                                fontSize: AppTextStyles.tableHeader,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                              ),
                          elevation: 0.0,
                          borderSide: const BorderSide(color: Color(0xFF183654), width: 1.0),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}