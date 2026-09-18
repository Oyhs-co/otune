import 'package:flutter/material.dart';

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.message,
    required this.buttonText,
    required this.onButtonPressed,
    this.icon = Icons.music_note,
  });

  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (buttonText.isNotEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.folder_open),
                label: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
