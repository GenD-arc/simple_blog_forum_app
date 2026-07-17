import 'package:flutter/material.dart';

import '../core/theme.dart';

class AuthFormContainer extends StatelessWidget {
  const AuthFormContainer({super.key, required this.child, this.maxWidth = 420});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}