import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class DeleteAccountInfoScreen extends StatelessWidget {
  const DeleteAccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Eliminación de Cuenta'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.delete_forever_rounded,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Solicitud de Eliminación de Cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Respetamos tu privacidad. Al solicitar la eliminación de tu cuenta, procederemos a borrar de forma segura los siguientes datos personales:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Información de Perfil (Nombre, DNI, Foto)'),
                          Text('• Datos de Contacto (Email, Teléfono)'),
                          Text('• Certificados Médicos subidos'),
                          Text('• Credenciales de Acceso (Token Google/Apple)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tu historial de clases se conservará de forma anónima exclusivamente para fines estadísticos del estudio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    const _OptionTile(
                      number: '1',
                      title: 'Desde la Aplicación',
                      description:
                          '• Usuarios: Ve a tu Perfil y baja hasta el final.\n• Administradores: Ve a Ajustes > Sesión.\n\nEn ambos casos encontrarás el botón "Eliminar Cuenta".',
                    ),
                    const SizedBox(height: 20),
                    const _OptionTile(
                      number: '2',
                      title: 'Solicitud Manual',
                      description:
                          'Si no puedes acceder a la app, envíanos un correo. Responderemos a tu solicitud para procesar la baja manual.',
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _launchEmail(),
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Enviar Correo de Solicitud'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Volver al Inicio'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path:
          'admin@example.com', // Email real removido para versión pública del repositorio
      queryParameters: {
        'subject': 'Solicitud de Baja de Cuenta - Pilates All Canning',
        'body':
            'Hola, solicito eliminar mi cuenta asociada a este correo. Mis datos son: ...',
      },
    );

    if (!await launchUrl(emailLaunchUri)) {
      // Manejar error
    }
  }
}

class _OptionTile extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _OptionTile({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
