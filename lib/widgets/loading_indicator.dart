import 'package:flutter/material.dart';

import '../core/theme.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          strokeWidth: 2.4,
          color: AppColors.crimson,
        ),
      ),
    );
  }
}
