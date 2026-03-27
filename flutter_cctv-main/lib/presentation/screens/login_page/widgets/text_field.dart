import 'package:central_command/utils/app_text_styles.dart';
import 'package:central_command/utils/flutter_flow/model.dart';
import 'package:central_command/utils/flutter_flow/util.dart';
import '/core/i18n/i18n.dart';

import '/utils/flutter_flow/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:central_command/presentation/screens/login_page/login_page_model.dart';

/// Username Field
class UsernameField extends StatelessWidget {
  final LoginPageModel model;

  const UsernameField({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
      child: SizedBox(
        width: double.infinity,
        child: TextFormField(
          controller: model.emailAddressTextController,
          focusNode: model.emailAddressFocusNode,
          autofocus: true,
          autofillHints: const [AutofillHints.email],
          obscureText: false,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.tr('login.username', fallback: 'ชื่อผู้ใช้'),
            labelStyle: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                  color: const Color(0xFF57636C),
                  fontSize: AppTextStyles.navBrand,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFF1F4F8), width: 2.0),
              borderRadius: BorderRadius.circular(12.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF4B39EF), width: 2.0),
              borderRadius: BorderRadius.circular(12.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFE0E3E7), width: 2.0),
              borderRadius: BorderRadius.circular(12.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFE0E3E7), width: 2.0),
              borderRadius: BorderRadius.circular(12.0),
            ),
            filled: true,
            fillColor: const Color(0xFFF1F4F8),
          ),
          style: FlutterFlowTheme.of(context).bodyLarge.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                color: const Color(0xFF101213),
                fontSize: AppTextStyles.tableHeader,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
              ),
          validator: model.emailAddressTextControllerValidator.asValidator(context),
        ),
      ),
    );
  }
}

/// Password Field
class PasswordField extends StatelessWidget {
  final LoginPageModel model;
  final VoidCallback onSubmit;
  final VoidCallback onToggleVisibility;

  const PasswordField({
    super.key,
    required this.model,
    required this.onSubmit,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
      child: SizedBox(
        width: double.infinity,
        child: TextFormField(
          controller: model.passwordTextController,
          focusNode: model.passwordFocusNode,
          autofocus: true,
          autofillHints: const [AutofillHints.password],
          obscureText: !model.passwordVisibility,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (!model.isLoading) {
              model.passwordFocusNode?.unfocus();
              final username = model.emailAddressTextController.text.trim();
              final password = model.passwordTextController.text;
              if (username.isNotEmpty && password.isNotEmpty) {
                onSubmit();
              }
            }
          },
          decoration: InputDecoration(
            labelText: context.tr('login.password', fallback: 'รหัสผ่าน'),
            labelStyle: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                  color: const Color(0xFF57636C),
                  fontSize: AppTextStyles.tableHeader,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFF1F4F8), width: 2.0),
              borderRadius: BorderRadius.circular(12.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF4B39EF), width: 2.0),
              borderRadius: BorderRadius.circular(12.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFE0E3E7), width: 2.0),
              borderRadius: BorderRadius.circular(12.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFE0E3E7), width: 2.0),
              borderRadius: BorderRadius.circular(12.0),
            ),
            filled: true,
            fillColor: const Color(0xFFF1F4F8),
            suffixIcon: InkWell(
              onTap: onToggleVisibility,
              focusNode: FocusNode(skipTraversal: true),
              child: Icon(
                model.passwordVisibility
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF57636C),
                size: 24.0,
              ),
            ),
          ),
          style: FlutterFlowTheme.of(context).bodyLarge.override(
                font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                color: const Color(0xFF101213),
                fontSize: AppTextStyles.tableHeader,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
              ),
          validator: model.passwordTextControllerValidator.asValidator(context),
        ),
      ),
    );
  }
}