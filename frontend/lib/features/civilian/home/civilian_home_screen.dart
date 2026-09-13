import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/journey_model.dart';
import '../../../providers/auth_provider.dart';
import 'civilian_home_controller.dart';
import 'widgets/journey_map_view.dart';
import 'widgets/sos_dialog.dart';
import 'widgets/nearby_police_sheet.dart';
import 'widgets/helpline_sheet.dart';
import '../../../../services/demo_simulation_service.dart';
import '../../../../services/sos_tracking_manager.dart';

class CivilianHomeScreen extends StatelessWidget {
  const CivilianHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CivilianHomeController(),
      child: const _CivilianHomeContent(),
    );
  }
}

class _CivilianHomeContent extends StatefulWidget {
  const _CivilianHomeContent();

  @override
  State<_CivilianHomeContent> createState() => _CivilianHomeContentState();
}

class _CivilianHomeContentState extends State<_CivilianHomeContent> {
  final TextEditingController _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final controller = Provider.of<CivilianHomeController>(context, listen: false);
      if (auth.token != null && auth.token!.isNotEmpty) {
        controller.checkAndRestoreActiveJourney(token: auth.token!);
      }
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final controller = Provider.of<CivilianHomeController>(context);
    final userName = auth.currentUser?.name ?? 'Ananya';
    final district = auth.currentUser?.district ?? 'Mumbai Suburban';
    final token = auth.token ?? '';

    return Scaffold(
      backgroundColor: AppColors.civilianPinkSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopBar(context, userName, district),

            // Live SOS Broadcasting Status Banner
            ListenableBuilder(
              listenable: SosTrackingManager(),
              builder: (context, _) {
                final sosMgr = SosTrackingManager();
                if (!sosMgr.isSosActive) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🚨 SOS BROADCAST ACTIVE',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sosMgr.currentPosition != null
                                  ? 'Live GPS (${sosMgr.currentPosition!.latitude.toStringAsFixed(4)}, ${sosMgr.currentPosition!.longitude.toStringAsFixed(4)}) streaming to Police'
                                  : 'Streaming live GPS location to Police Patrol...',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          sosMgr.stopTracking(callBackendResolve: true, note: 'Civilian marked safe');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('SOS resolved. Live tracking turned off.'),
                              backgroundColor: Color(0xFF16A34A),
                            ),
                          );
                        },
                        child: const Text('I am Safe', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Development / Demo Simulation Toolbar (kDebugMode only)
            if (kDebugMode) _buildDebugDemoBar(context, controller, token),

            // Main Scrollable State View
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: _buildStateContent(context, controller, token, district),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TOP BAR ---
  Widget _buildTopBar(BuildContext context, String userName, String district) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Hello, $userName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.civilianPink,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    district,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- DEBUG DEMO TOOLBAR ---
  Widget _buildDebugDemoBar(BuildContext context, CivilianHomeController controller, String token) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.civilianPinkLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.civilianPink.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_rounded, color: AppColors.civilianPink, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.isDemoMode
                  ? 'Demo Simulation: Step ${controller.demoStepIndex + 1}/${DemoSimulationService.demoSteps.length}'
                  : 'Demo Simulation (${DemoSimulationService.demoSteps.length} Steps)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.civilianPinkDark,
              ),
            ),
          ),
          if (!controller.isDemoMode)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                backgroundColor: AppColors.civilianPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => controller.startDemoSimulation(token: token),
              child: const Text('Start Demo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            )
          else ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.chevron_left_rounded, size: 24, color: AppColors.civilianPink),
              onPressed: () => controller.prevDemoStep(token: token),
            ),
            const SizedBox(width: 6),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.civilianPink),
              onPressed: () => controller.nextDemoStep(token: token),
            ),
            const SizedBox(width: 6),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
              onPressed: () => controller.resetToHome(),
            ),
          ],
        ],
      ),
    );
  }

  // --- STATE ROUTER ---
  Widget _buildStateContent(BuildContext context, CivilianHomeController controller, String token, String district) {
    switch (controller.journeyState) {
      case JourneyStatus.planning:
        return _buildPlanningState(context, controller, token, district);
      case JourneyStatus.active:
      case JourneyStatus.unusualActivity:
        return _buildActiveState(context, controller, token, district);
      case JourneyStatus.safetyAlert:
        return _buildSafetyAlertState(context, controller, token);
      case JourneyStatus.completed:
        return _buildCompletedState(context, controller, token);
      case JourneyStatus.notStarted:
      case JourneyStatus.cancelled:
        return _buildNotStartedState(context, controller, token, district);
    }
  }

  // ==========================================
  // 1. HOME (NOT STARTED)
  // ==========================================
  Widget _buildNotStartedState(BuildContext context, CivilianHomeController controller, String token, String district) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Hero Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Illustration / Badge
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.civilianPinkLight,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.directions_walk_rounded,
                    size: 48,
                    color: Color(0xFF4F46E5), // Indigo — contrasts beautifully on pink
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Start Your Safe Journey',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Let us watch over you while you travel.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.civilianPink,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => controller.openPlanning(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Safe Journey',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),

        // Quick Actions Section
        _buildQuickActionsHeader(),
        const SizedBox(height: 14),
        _buildQuickActionsGrid(context, token, null, controller.currentPosition, district),

        const SizedBox(height: 24),

        // Bottom Info Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.civilianPinkLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.civilianPink, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Travel safer, together.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Plan your journey and let us keep you informed.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. PLAN YOUR JOURNEY
  // ==========================================
  Widget _buildPlanningState(BuildContext context, CivilianHomeController controller, String token, String district) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Your Journey',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Choose your destination and travel mode.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
              onPressed: () {
                _destinationController.clear();
                controller.cancelPlanning();
              },
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Destination Search Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: controller.destinationPosition != null
                  ? AppColors.civilianPink
                  : AppColors.border,
              width: controller.destinationPosition != null ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: controller.destinationPosition != null
                    ? AppColors.civilianPink
                    : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    hintText: 'Search destination (e.g. Shivaji Park, Dadar)',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) {
                    controller.searchDestinationPlaces(val);
                  },
                ),
              ),
              if (controller.isSearchingPlaces)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.civilianPink),
                )
              else if (_destinationController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  onPressed: () {
                    _destinationController.clear();
                    controller.setDestination('', null);
                    controller.searchDestinationPlaces('');
                  },
                ),
            ],
          ),
        ),

        // Autocomplete Place Suggestions Dropdown
        if (controller.placeSuggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.placeSuggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, idx) {
                final suggestion = controller.placeSuggestions[idx];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      _destinationController.text = suggestion.displayName;
                      _destinationController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _destinationController.text.length),
                      );
                      FocusScope.of(context).unfocus();
                      controller.selectPlaceSuggestion(suggestion);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded, size: 18, color: AppColors.civilianPink),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.shortName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  suggestion.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.north_west_rounded, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // Selected Destination Confirmation Pill
        if (controller.destinationPosition != null && controller.destinationText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.civilianPinkLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.civilianPink.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.civilianPink),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Destination selected (${controller.destinationPosition!.latitude.toStringAsFixed(3)}, ${controller.destinationPosition!.longitude.toStringAsFixed(3)})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.civilianPink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Travel Mode Selector
        const Text(
          'Travel Mode',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildModeChip(controller, TravelMode.walk, Icons.directions_walk_rounded, 'Walk'),
            const SizedBox(width: 10),
            _buildModeChip(controller, TravelMode.auto, Icons.electric_rickshaw_rounded, 'Auto'),
            const SizedBox(width: 10),
            _buildModeChip(controller, TravelMode.bus, Icons.directions_bus_rounded, 'Bus'),
            const SizedBox(width: 10),
            _buildModeChip(controller, TravelMode.cab, Icons.local_taxi_rounded, 'Cab'),
          ],
        ),
        const SizedBox(height: 20),

        // Share Until Selector (Dropdown)
        const Text(
          'Share Until',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: [60, 120, 180, 240, 300].contains(controller.selectedDurationMinutes)
                  ? controller.selectedDurationMinutes
                  : 60,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.civilianPink),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(14),
              items: const [
                DropdownMenuItem<int>(
                  value: 60,
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 20, color: AppColors.civilianPink),
                      SizedBox(width: 10),
                      Text(
                        '1 hour',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 120,
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 20, color: AppColors.civilianPink),
                      SizedBox(width: 10),
                      Text(
                        '2 hours',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 180,
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 20, color: AppColors.civilianPink),
                      SizedBox(width: 10),
                      Text(
                        '3 hours',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 240,
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 20, color: AppColors.civilianPink),
                      SizedBox(width: 10),
                      Text(
                        '4 hours',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem<int>(
                  value: 300,
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 20, color: AppColors.civilianPink),
                      SizedBox(width: 10),
                      Text(
                        '5 hours',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (int? newMinutes) {
                if (newMinutes != null) {
                  controller.setExpectedDuration(newMinutes);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Start Journey Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.civilianPink,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: controller.isLoading
              ? null
              : () async {
                  await controller.startJourney(token: token, startDistrict: district);
                },
          child: controller.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Start Journey', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildModeChip(CivilianHomeController controller, TravelMode mode, IconData icon, String label) {
    final isSelected = controller.selectedTravelMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setTravelMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.civilianPinkLight : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.civilianPink : AppColors.border,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.civilianPink : AppColors.textSecondary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.civilianPink : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. HOME (JOURNEY ACTIVE)
  // ==========================================
  Widget _buildActiveState(BuildContext context, CivilianHomeController controller, String token, String district) {
    final pos = controller.currentPosition ?? const LatLng(19.0596, 72.8368);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active Status Header
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.civilianPink,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Journey Active',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'We’re monitoring your journey in real-time.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),

        // Interactive Map
        JourneyMapView(
          currentPosition: pos,
          destinationPosition: controller.destinationPosition,
          routePoints: controller.routePoints,
          journeyStatus: controller.journeyState,
          riskLevel: controller.currentRiskLevel,
        ),
        const SizedBox(height: 14),

        // Metrics Summary Card (ETA, Distance, Time Remaining)
        _buildStatsRow(controller),
        const SizedBox(height: 14),

        // Safety Status & Risk Message Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: controller.currentRiskLevel == RiskLevel.normal
                      ? AppColors.civilianPinkLight
                      : (controller.currentRiskLevel == RiskLevel.unusual ? AppColors.riskUnusualBg : AppColors.riskHighBg),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  controller.currentRiskLevel == RiskLevel.normal
                      ? Icons.shield_rounded
                      : (controller.currentRiskLevel == RiskLevel.unusual ? Icons.warning_amber_rounded : Icons.crisis_alert_rounded),
                  color: controller.currentRiskLevel == RiskLevel.normal
                      ? AppColors.civilianPink
                      : (controller.currentRiskLevel == RiskLevel.unusual ? AppColors.riskUnusual : AppColors.riskHigh),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.currentRiskLevel == RiskLevel.normal
                          ? 'You’re on a safe route'
                          : (controller.currentRiskLevel == RiskLevel.unusual ? 'Unusual activity detected' : 'Safety check triggered'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.statusMessage,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // End Journey Button
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => controller.endJourney(token: token),
          child: const Text('End Safe Journey', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 20),

        // Quick Actions
        _buildQuickActionsHeader(),
        const SizedBox(height: 12),
        _buildQuickActionsGrid(context, token, controller.activeJourney?.id, controller.currentPosition, district),
      ],
    );
  }

  // ==========================================
  // 4. HOME (SAFETY CHECK-IN / PROMPT)
  // ==========================================
  Widget _buildSafetyAlertState(BuildContext context, CivilianHomeController controller, String token) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),

        // Alert Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.riskHighBg),
            boxShadow: [
              BoxShadow(
                color: AppColors.riskHigh.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.riskHighBg,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.security_rounded,
                    size: 38,
                    color: AppColors.riskHigh,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you safe?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'We noticed a possible risk near your location.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),

              // Button 1: "I'm Safe" (Pink)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.civilianPink,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => controller.markUserSafe(token: token),
                child: const Text(
                  'I’m Safe',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),

              // Button 2: "I Need Help" (Red)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.riskHigh,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => controller.requestEmergencyHelp(token: token),
                child: const Text(
                  'I Need Help',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick Actions
        _buildQuickActionsHeader(),
        const SizedBox(height: 12),
        _buildQuickActionsGrid(context, token, controller.activeJourney?.id),
      ],
    );
  }

  // ==========================================
  // 6. HOME (JOURNEY COMPLETE)
  // ==========================================
  Widget _buildCompletedState(BuildContext context, CivilianHomeController controller, String token) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),

        // Completion Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Pink Checkmark Icon in Circle
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.civilianPink,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Journey Complete!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You’ve reached safely.\nThank you for using AegisPatrol.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 20),

              // Summary Stats Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat(
                      'Total Duration',
                      '${controller.completedDurationMinutes.toStringAsFixed(0)} min',
                    ),
                    Container(width: 1, height: 32, color: AppColors.border),
                    _buildSummaryStat(
                      'Distance',
                      '${controller.completedDistanceKm.toStringAsFixed(1)} km',
                    ),
                    Container(width: 1, height: 32, color: AppColors.border),
                    _buildSummaryStat(
                      'Safe Route',
                      controller.safeRoute ? 'Yes' : 'Alert Resolved',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // CTA Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.civilianPink,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => controller.resetToHome(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Back to Home',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick Actions
        _buildQuickActionsHeader(),
        const SizedBox(height: 12),
        _buildQuickActionsGrid(context, token, null),
      ],
    );
  }

  // --- STATS ROW WIDGET ---
  Widget _buildStatsRow(CivilianHomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('ETA', controller.eta),
          Container(width: 1, height: 28, color: AppColors.border),
          _buildStatItem('Distance', '${controller.distanceKm.toStringAsFixed(1)} km'),
          Container(width: 1, height: 28, color: AppColors.border),
          _buildStatItem('Time Left', '${controller.timeRemainingMinutes} min'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  // --- QUICK ACTIONS SECTION ---
  Widget _buildQuickActionsHeader() {
    return const Text(
      'Quick Actions',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildQuickActionsGrid(
    BuildContext context,
    String token,
    String? journeyId, [
    LatLng? currentPos,
    String? district,
  ]) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            label: 'SOS',
            sublabel: 'Get help\ninstantly',
            bgColor: AppColors.quickActionSosBg,
            iconColor: AppColors.quickActionSosIcon,
            icon: Icons.emergency_rounded,
            onTap: () {
              SosDialog.show(
                context,
                token: token,
                journeyId: journeyId,
                currentPos: currentPos,
                district: district,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            label: 'Nearby Police',
            sublabel: 'Find police\nstations',
            bgColor: const Color(0xFFEDE9FE), // Soft indigo
            iconColor: const Color(0xFF4F46E5), // Indigo
            icon: Icons.local_police_rounded,
            onTap: () {
              NearbyPoliceSheet.show(context, token: token);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            label: 'Helpline',
            sublabel: 'Emergency\nnumbers',
            bgColor: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF9333EA),
            icon: Icons.phone_in_talk_rounded,
            onTap: () {
              HelplineSheet.show(context);
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label,
    required this.sublabel,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
