import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const CommonAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: onBackPressed ?? () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  try {
                    context.pop();
                  } catch (_) {
                    context.go('/home');
                  }
                }
              },
            )
          : null,
      title: Text(title),
      actions: actions,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.dark,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
