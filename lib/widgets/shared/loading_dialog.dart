import 'package:flutter/material.dart';

/// A reusable blocking loading dialog used for long-running operations
/// (especially network calls like Google Drive backup/restore).
///
/// Prefer [LoadingDialog.run], which shows the dialog, runs the task, and
/// guarantees the dialog is dismissed afterwards — even if the task throws.
class LoadingDialog {
  const LoadingDialog._();

  /// Show a modal, non-dismissible loading dialog with a [message].
  ///
  /// Uses the root navigator so it sits above bottom sheets and other dialogs.
  static void show(BuildContext context, {String message = 'Memproses...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        // Block the system back button while the task is running.
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 28,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    child: Text(
                      message,
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Dismiss the loading dialog shown by [show].
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Show the loading dialog, run [task], and always dismiss the dialog after.
  ///
  /// Returns the task's result. Re-throws any error from [task] *after*
  /// dismissing the dialog, so callers can handle failures normally.
  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> Function() task,
    String message = 'Memproses...',
  }) async {
    show(context, message: message);
    try {
      return await task();
    } finally {
      if (context.mounted) hide(context);
    }
  }
}
