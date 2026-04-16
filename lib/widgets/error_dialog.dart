import 'package:flutter/material.dart';

/// Custom error dialog with user-friendly messaging
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final IconData icon;
  final Color iconColor;

  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.actionLabel,
    this.onRetry,
    this.onDismiss,
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      actions: [
        if (onDismiss != null)
          TextButton(
            onPressed: onDismiss,
            child: const Text('Dismiss'),
          )
        else
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        if (onRetry != null && actionLabel != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }

  /// Show error dialog
  static Future<void> show(
    BuildContext context, {
    String title = 'Error',
    required String message,
    String? actionLabel,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    IconData icon = Icons.error_outline,
    Color iconColor = Colors.red,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        actionLabel: actionLabel,
        onRetry: onRetry,
        onDismiss: onDismiss,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }
}

/// Validation error dialog - specifically for form validation errors
class ValidationErrorDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ValidationErrorDialog({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDialog(
      title: 'Validation Error',
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.orange,
      onDismiss: onDismiss,
    );
  }

  /// Show validation error dialog
  static Future<void> show(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ValidationErrorDialog(
        message: message,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// Network error dialog
class NetworkErrorDialog extends StatelessWidget {
  final String? customMessage;
  final VoidCallback? onRetry;

  const NetworkErrorDialog({
    super.key,
    this.customMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDialog(
      title: 'Connection Error',
      message: customMessage ??
          'Unable to connect to the server. Please check your internet connection and try again.',
      actionLabel: 'Retry',
      onRetry: onRetry,
      icon: Icons.wifi_off,
      iconColor: Colors.red,
    );
  }

  /// Show network error dialog
  static Future<void> show(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => NetworkErrorDialog(
        customMessage: customMessage,
        onRetry: onRetry,
      ),
    );
  }
}

/// Success dialog (for confirmations)
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onDismiss;

  const SuccessDialog({
    super.key,
    this.title = 'Success',
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorDialog(
      title: title,
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      onDismiss: onDismiss,
    );
  }

  /// Show success dialog
  static Future<void> show(
    BuildContext context, {
    String title = 'Success',
    required String message,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// Confirmation dialog (for destructive actions)
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color confirmColor;

  const ConfirmDialog({
    super.key,
    this.title = 'Confirm',
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.confirmColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.help_outline,
              color: Colors.orange,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  /// Show confirmation dialog
  static Future<bool> show(
    BuildContext context, {
    String title = 'Confirm',
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Color confirmColor = Colors.red,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmColor: confirmColor,
      ),
    );
    return result ?? false;
  }
}
