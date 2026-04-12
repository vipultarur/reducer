import 'package:flutter/material.dart';
import 'package:reducer/core/theme/app_colors.dart';

class ClearHistoryDialog extends StatelessWidget {
  final VoidCallback onClear;

  const ClearHistoryDialog({
    super.key,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Clear History?'),
      content: const Text('This will remove all past edits from history. This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            onClear();
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Clear'),
        ),
      ],
    );
  }
}
