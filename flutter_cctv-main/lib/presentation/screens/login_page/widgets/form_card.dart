import 'package:central_command/utils/app_text_styles.dart';

import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/widgets.dart';
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
    return Align(
      alignment: AlignmentDirectional(1.0, 0.0),
      child: Container(
        width: double.infinity,
        height: MediaQuery.sizeOf(context).height * 1.0,
        constraints: const BoxConstraints(maxWidth: 570.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              blurRadius: 4.0,
              color: Color(0x33000000),
              offset: Offset(0.0, 2.0),
            ),
          ],
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: Align(
          alignment: AlignmentDirectional(0.0, 0.0),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).displaySmall.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                        color: const Color(0xFF101213),
                        fontSize: AppTextStyles.displayLarge,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                ),

                // Subtitle
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 24.0),
                  child: Text(
                    'Fill out the information below in order to access your account.',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500,
                          ),
                          color: const Color(0xFF57636C),
                          fontSize: AppTextStyles.labelNormal,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),

                // Spacer
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    height: 10.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),

                // Username Field
                UsernameField(model: model),

                // Password Field
                PasswordField(
                  model: model,
                  onSubmit: onLogin,
                  onToggleVisibility: onTogglePasswordVisibility,
                ),

                // Spacer
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    height: 10.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),

                // Login Button
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                  child: FFButtonWidget(
                    onPressed: model.isLoading ? null : onLogin,
                    text: model.isLoading ? 'Loading...' : 'Log In',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 44.0,
                      padding: EdgeInsetsDirectional.zero,
                      iconPadding: EdgeInsetsDirectional.zero,
                      color: const Color(0xFF4B39EF),
                      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w500,
                            ),
                            color: Colors.white,
                            fontSize: AppTextStyles.tableHeader,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                          ),
                      elevation: 3.0,
                      borderSide: const BorderSide(
                        color: Colors.transparent,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}