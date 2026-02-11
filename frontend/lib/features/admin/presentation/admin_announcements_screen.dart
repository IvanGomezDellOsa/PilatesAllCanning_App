import 'dart:io';
import '../../../core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Add import
import '../../../core/theme/app_theme.dart';
import '../../../models/announcement.dart';
import '../../../core/providers/providers.dart';
import '../../shared/widgets/common_widgets.dart';

class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends ConsumerState<AdminAnnouncementsScreen> {
  final int _currentNavIndex = 2;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.push('/admin/users');
        break;
      case 2:
        // Ya estamos en Novedades
        break;
      case 3:
        context.push('/admin/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Novedades',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
      ),
      body: announcementsAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No hay novedades publicadas',
              subtitle: 'Toca el botón + para crear una',
              action: ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Crear Novedad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA67777),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(announcementsProvider);
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    return _AnnouncementCard(
                      announcement: announcements[index],
                      onDelete: () => _confirmDelete(
                        context,
                        announcements[index],
                      ),
                      isFirst: index == 0,
                    );
                  },
                ),
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Cargando novedades...'),
        error: (error, _) => ErrorView(
          message: 'Error al cargar novedades',
          onRetry: () => ref.invalidate(announcementsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: const Color(0xFFA67777),
        elevation: 6,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Nueva Novedad',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentNavIndex,
            onDestinationSelected: _onNavTap,
            elevation: 0,
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: AppColors.surface,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Agenda',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Usuarios',
              ),
              NavigationDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: 'Novedades',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Ajustes',
              ),
            ],
          )),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateAnnouncementDialog(),
    );
  }

  void _confirmDelete(BuildContext context, Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar Novedad',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        content: Text(
          '¿Deseas eliminar "${announcement.title}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Llamamos al Provider para eliminar
                await ref
                    .read(announcementsProvider.notifier)
                    .deleteAnnouncement(announcement.id);

                if (context.mounted) {
                  Navigator.pop(context); // Cerrar diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Novedad eliminada',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== ANNOUNCEMENT CARD ==========

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onDelete;
  final bool isFirst;

  const _AnnouncementCard({
    required this.announcement,
    required this.onDelete,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired =
        announcement.expiresAt != null && announcement.expiresAt!.isBefore(now);

    return Container(
      margin: EdgeInsets.only(bottom: 18, top: isFirst ? 0 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isExpired
                ? AppColors.error.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Contenido principal
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isExpired
                      ? AppColors.error.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview de Media
                  if (announcement.imageUrl != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: Image.network(
                            announcement.imageUrl!.startsWith('http')
                                ? announcement.imageUrl!
                                : '${AppConstants.apiBaseUrl}${announcement.imageUrl}',
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.2),
                                      AppColors.accent.withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Overlay sutil
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Placeholder si no hay imagen
                  if (announcement.imageUrl == null)
                    Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isExpired
                              ? [
                                  AppColors.error.withValues(alpha: 0.1),
                                  AppColors.error.withValues(alpha: 0.05),
                                ]
                              : [
                                  AppColors.primary.withValues(alpha: 0.15),
                                  AppColors.accent.withValues(alpha: 0.2),
                                ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isExpired
                                ? Icons.schedule_outlined
                                : Icons.campaign_outlined,
                            size: 28,
                            color:
                                isExpired ? AppColors.error : AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                  // Contenido
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Solo mostrar título si existe
                            if (announcement.title != null &&
                                announcement.title!.isNotEmpty)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isExpired
                                            ? AppColors.error
                                                .withValues(alpha: 0.4)
                                            : AppColors.primary
                                                .withValues(alpha: 0.3),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    announcement.title!.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      height: 1.2,
                                      letterSpacing: 0.8,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            // Spacer si no hay título
                            if (announcement.title == null ||
                                announcement.title!.isEmpty)
                              const Spacer(),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                onPressed: onDelete,
                                icon: const Icon(Icons.delete_outline),
                                color: AppColors.error,
                                tooltip: 'Eliminar',
                                iconSize: 20,
                              ),
                            ),
                          ],
                        ),
                        if (announcement.title != null &&
                            announcement.title!.isNotEmpty)
                          const SizedBox(height: 14),
                        if (announcement.content != null &&
                            announcement.content!.isNotEmpty)
                          Text(
                            announcement.content!,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 16),

                        // Footer colorido
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            // Badge de fecha
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.1),
                                    AppColors.accent.withValues(alpha: 0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: AppColors.primaryDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('dd/MM/yyyy')
                                        .format(announcement.createdAt),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Badge de expiración
                            if (announcement.expiresAt != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isExpired
                                      ? AppColors.error.withValues(alpha: 0.15)
                                      : AppColors.warning
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isExpired
                                        ? AppColors.error.withValues(alpha: 0.4)
                                        : AppColors.warning
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isExpired
                                          ? Icons.event_busy
                                          : Icons.event,
                                      size: 14,
                                      color: isExpired
                                          ? AppColors.error
                                          : AppColors.warning,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isExpired
                                          ? 'Expirada'
                                          : 'Expira ${DateFormat('dd/MM').format(announcement.expiresAt!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isExpired
                                            ? AppColors.error
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Barra de color lateral
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isExpired
                        ? [
                            AppColors.error,
                            AppColors.error.withValues(alpha: 0.6)
                          ]
                        : [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== CREATE ANNOUNCEMENT DIALOG ==========

class _CreateAnnouncementDialog extends ConsumerStatefulWidget {
  const _CreateAnnouncementDialog();

  @override
  ConsumerState<_CreateAnnouncementDialog> createState() =>
      _CreateAnnouncementDialogState();
}

class _CreateAnnouncementDialogState
    extends ConsumerState<_CreateAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _sendPush = false;

  DateTime? _expiresAt;
  String _mediaType = 'none'; // 'none' or 'image'
  PlatformFile? _selectedImage;
  String? _imageError;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Importante para web
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;

        // Validación de tamaño (aprox, file.size está en bytes)
        const maxSize = 8 * 1024 * 1024; // 8MB

        if (file.size > maxSize) {
          setState(() {
            _imageError = 'La imagen debe pesar menos de 8MB';
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = file;
            _imageError = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  // Helper widget para mostrar preview
  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();

    if (kIsWeb) {
      // En web usamos bytes
      if (_selectedImage!.bytes != null) {
        return Image.memory(
          _selectedImage!.bytes!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
      return const Text('Error: No image data');
    } else {
      // En móvil/desktop usamos path (si existe)
      if (_selectedImage!.path != null) {
        return Image.file(
          File(_selectedImage!.path!),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
      return const Text('Error: No image path');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Nueva Novedad',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título (opcional)',
                    prefixIcon: Icon(Icons.title),
                  ),
                  // Sin validator - campo opcional
                ),
                const SizedBox(height: 16),

                // Contenido
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Contenido (opcional)',
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  // Sin validator - campo opcional
                ),
                const SizedBox(height: 16),

                // Fecha de expiración
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _expiresAt ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFFA67777),
                              onPrimary: Colors.white,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => _expiresAt = date);
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Fecha de Expiración (Opcional)',
                        prefixIcon: const Icon(Icons.event),
                        suffixIcon: _expiresAt != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setState(() => _expiresAt = null),
                              )
                            : const Icon(Icons.arrow_drop_down),
                        hintText: _expiresAt != null
                            ? DateFormat('dd/MM/yyyy').format(_expiresAt!)
                            : 'Sin expiración',
                      ),
                      controller: TextEditingController(
                        text: _expiresAt != null
                            ? DateFormat('dd/MM/yyyy').format(_expiresAt!)
                            : '',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Selector de tipo de media
                const Text(
                  'Multimedia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Sin Imagen'),
                        selected: _mediaType == 'none',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _mediaType = 'none';
                              _selectedImage = null;
                              _imageError = null;
                            });
                          }
                        },
                        selectedColor:
                            const Color(0xFFA67777).withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Con Imagen'),
                        selected: _mediaType == 'image',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _mediaType = 'image';
                            });
                          }
                        },
                        selectedColor:
                            const Color(0xFFA67777).withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Imagen
                if (_mediaType == 'image') ...[
                  if (_selectedImage == null) ...[
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Seleccionar Imagen'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    if (_imageError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _imageError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ] else ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImagePreview(),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.6),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tamaño: ${(_selectedImage!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 20),
                const Divider(),
                // Swith de Notificación Push
                SwitchListTile(
                  title: const Text(
                    'Enviar notificación push',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Notificar a todos los usuarios móviles',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: _sendPush,
                  activeTrackColor: const Color(0xFFA67777),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() {
                      _sendPush = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Llamar al Controller
              ref.read(announcementsProvider.notifier).createAnnouncement(
                    title: _titleController.text,
                    content: _contentController.text,
                    imageFile: _selectedImage,
                    expiresAt: _expiresAt,
                    sendPush: _sendPush,
                  );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Novedad creada',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA67777),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
