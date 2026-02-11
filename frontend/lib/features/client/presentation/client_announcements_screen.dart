import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/announcement.dart';
import '../../../core/providers/providers.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';

class ClientAnnouncementsScreen extends ConsumerStatefulWidget {
  const ClientAnnouncementsScreen({super.key});

  @override
  ConsumerState<ClientAnnouncementsScreen> createState() =>
      _ClientAnnouncementsScreenState();
}

class _ClientAnnouncementsScreenState
    extends ConsumerState<ClientAnnouncementsScreen> {
  final int _currentNavIndex = 3;

  @override
  void initState() {
    super.initState();
    // Refrescar datos al entrar (Esto disparará el build -> data -> markWithList)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(announcementsProvider);
    });
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 0:
        context.go('/client');
        break;
      case 1:
        context.push('/client/my-classes');
        break;
      case 2:
        context.push('/client/profile');
        break;
      case 3:
        // Ya estamos en Novedades
        break;
      case 4:
        context.push('/client/info');
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
        data: (allAnnouncements) {
          // Filtrar solo novedades activas (no expiradas)
          final now = DateTime.now();
          final activeAnnouncements = allAnnouncements
              .where((a) => a.expiresAt == null || a.expiresAt!.isAfter(now))
              .toList();

          if (activeAnnouncements.isEmpty) {
            return const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No hay novedades',
              subtitle: 'Cuando haya anuncios importantes aparecerán aquí',
            );
          }

          // Auto-mark as read when data is loaded/viewed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(unreadAnnouncementsProvider.notifier)
                .markWithList(activeAnnouncements);
          });

          return RefreshIndicator(
            onRefresh: () async {
              return ref
                  .read(announcementsProvider.notifier)
                  .loadAnnouncements();
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                  itemCount: activeAnnouncements.length,
                  itemBuilder: (context, index) {
                    return _AnnouncementCard(
                      announcement: activeAnnouncements[index],
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
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Reservar',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note_rounded),
              label: 'Mis Clases',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: 'Novedades',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info_rounded),
              label: 'Info',
            ),
          ],
        ),
      ),
    );
  }

  // Dialog removed - now showing full content inline
}

// ========== ANNOUNCEMENT CARD (CLIENTE - REDISEÑADA) ==========

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final bool isFirst;

  const _AnnouncementCard({
    required this.announcement,
    this.isFirst = false,
  });

  bool get _isRecent {
    final difference = DateTime.now().difference(announcement.createdAt);
    return difference.inHours < 24; // "Nuevo" si tiene menos de 24 horas
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 24, top: isFirst ? 0 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Fondo base
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== IMAGEN CON OVERLAY GRADIENTE =====
                  if (announcement.imageUrl != null)
                    Stack(
                      children: [
                        Image.network(
                          announcement.imageUrl!.startsWith('http')
                              ? announcement.imageUrl!
                              : '${AppConstants.apiBaseUrl}${announcement.imageUrl}',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.3),
                                    AppColors.accent.withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.image_outlined,
                                    size: 48, color: AppColors.textSecondary),
                              ),
                            );
                          },
                        ),
                        // Overlay gradiente sutil en la parte inferior
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // ===== PLACEHOLDER SI NO HAY IMAGEN =====
                  if (announcement.imageUrl == null)
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.accent.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Patrón decorativo
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            bottom: 10,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          // Icono central
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.campaign_outlined,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ===== CONTENIDO =====
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título PROMINENTE
                        if (announcement.title != null &&
                            announcement.title!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              announcement.title!.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                height: 1.2,
                                letterSpacing: 1.2,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),

                        if (announcement.title != null &&
                            announcement.title!.isNotEmpty)
                          const SizedBox(height: 20),

                        // Contenido con tipografía destacada
                        if (announcement.content != null &&
                            announcement.content!.isNotEmpty)
                          Text(
                            announcement.content!,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),

                        const SizedBox(height: 20),

                        // ===== FOOTER CON FECHA (COLORIDO) =====
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.1),
                                AppColors.accent.withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat("d 'de' MMMM, yyyy", 'es')
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ===== BADGE "NUEVO" =====
            if (_isRecent)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'NUEVO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ===== BARRA DE COLOR EN EL BORDE IZQUIERDO =====
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.accent,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
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
