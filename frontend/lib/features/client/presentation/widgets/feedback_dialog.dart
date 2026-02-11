import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/providers.dart';

class FeedbackDialog extends ConsumerStatefulWidget {
  const FeedbackDialog({super.key});

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  // Estado: 'initial', 'happy', 'sad'
  String _state = 'initial';
  final _feedbackController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback(String sentiment, {String? message}) async {
    setState(() => _isLoading = true);
    try {
      // Llamada al backend a través del repositorio
      await ref.read(userRepositoryProvider).sendFeedback(
            sentiment,
            message,
          );

      // Refrescar usuario para actualizar hasGivenFeedback
      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      Navigator.of(context).pop();

      // Mostrar agradecimiento sin importar el sentimiento
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sentiment == 'positive'
              ? '¡Gracias por tu respuesta!'
              : '¡Gracias por tu opinión! Nos ayuda a mejorar.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar feedback: $e')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_state == 'initial') ...[
              Text(
                '¿Cómo es tu experiencia usando la app?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _EmojiButton(
                    emoji: '😢',
                    label: 'Podría mejorar',
                    onTap: () => setState(() => _state = 'sad'),
                  ),
                  _EmojiButton(
                    emoji: '😃',
                    label: 'Me gustó',
                    onTap: () => _submitFeedback('positive'),
                  ),
                ],
              ),
            ] else if (_state == 'sad') ...[
              const Icon(Icons.sentiment_dissatisfied,
                  size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Lamentamos escuchar eso',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Contanos qué pasó (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () => _submitFeedback('negative',
                      message: _feedbackController.text),
                  child: const Text('Enviar'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
