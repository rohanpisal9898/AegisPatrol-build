import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/journey_model.dart';
import '../../../models/police_journey_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/police_service.dart';
import '../../civilian/home/widgets/journey_map_view.dart';

class PoliceJourneysScreen extends StatefulWidget {
  const PoliceJourneysScreen({super.key});

  @override
  State<PoliceJourneysScreen> createState() => _PoliceJourneysScreenState();
}

class _PoliceJourneysScreenState extends State<PoliceJourneysScreen> {
  final PoliceService _policeService = PoliceService();
  bool _isLoading = true;
  String? _errorMessage;
  List<PoliceJourneyModel> _journeys = [];

  @override
  void initState() {
    super.initState();
    _fetchJourneys();
  }

  Future<void> _fetchJourneys() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _policeService.getPoliceJourneys(token: token);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _journeys = response.data!;
        } else {
          _errorMessage = response.message ?? 'Failed to load active journeys';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC), // Soft light-blue background
      body: SafeArea(
        child: Column(
          children: [
            // Top App Header matching reference
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journeys',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Live citizen journeys',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.policePrimary),
                    onPressed: _fetchJourneys,
                    tooltip: 'Refresh Active Journeys',
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: _buildBodyContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.policePrimary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.policePrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _fetchJourneys,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Zero-Mock Empty State
    if (_journeys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF), // Soft light-blue circle
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation_outlined,
                  size: 38,
                  color: AppColors.policePrimary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No active journeys',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'There are currently no active citizen journeys in your jurisdiction.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Live Journey Cards List
    return RefreshIndicator(
      onRefresh: _fetchJourneys,
      color: AppColors.policePrimary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _journeys.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final journey = _journeys[index];
          return _buildJourneyCard(context, journey);
        },
      ),
    );
  }

  Widget _buildJourneyCard(BuildContext context, PoliceJourneyModel journey) {
    // Generate initials for civilian avatar
    final nameParts = journey.civilianName.trim().split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : (journey.civilianName.isNotEmpty ? journey.civilianName[0].toUpperCase() : 'C');

    // Format start time string
    final startTimeStr = journey.startedAt != null
        ? DateFormat('h:mm a').format(journey.startedAt!)
        : '10:00 PM';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showJourneyDetailsModal(context, journey),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar / Profile Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF), // Soft blue tint
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.policePrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Center Column: Short ID, Name, Route
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Short ID & Name Row
                      Row(
                        children: [
                          Text(
                            journey.civilianId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              journey.civilianName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Route Location Row
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.policePrimary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${journey.startLocationName} → ${journey.destinationName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Right Column: Status Pill, Start Time & Duration, Chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusPill(journey),
                    const SizedBox(height: 6),
                    Text(
                      'Started $startTimeStr',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${journey.elapsedMinutes} min',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(PoliceJourneyModel journey) {
    Color bg;
    Color textColor;
    Color dotColor;
    String label;

    if (journey.riskLevel == RiskLevel.high || journey.status == JourneyStatus.safetyAlert) {
      bg = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
      dotColor = const Color(0xFFEF4444);
      label = 'High Risk';
    } else if (journey.riskLevel == RiskLevel.unusual || journey.status == JourneyStatus.unusualActivity) {
      bg = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
      dotColor = const Color(0xFFF59E0B);
      label = 'Unusual Stop';
    } else {
      bg = const Color(0xFFD1FAE5);
      textColor = const Color(0xFF059669);
      dotColor = const Color(0xFF10B981);
      label = 'On Track';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showJourneyDetailsModal(BuildContext context, PoliceJourneyModel journey) {
    final currentPos = (journey.currentLat != null && journey.currentLng != null)
        ? LatLng(journey.currentLat!, journey.currentLng!)
        : (journey.startLat != null && journey.startLng != null)
            ? LatLng(journey.startLat!, journey.startLng!)
            : const LatLng(19.0596, 72.8368);

    final destPos = (journey.destLat != null && journey.destLng != null)
        ? LatLng(journey.destLat!, journey.destLng!)
        : null;

    final routePoints = journey.routePoints.isNotEmpty
        ? journey.routePoints
        : [currentPos];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Journey ${journey.civilianId}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      _buildStatusPill(journey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.person_outline_rounded, 'Civilian Name', journey.civilianName),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.directions_walk_rounded, 'Travel Mode', journey.travelMode.name.toUpperCase()),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.trip_origin_rounded, 'Start Location', journey.startLocationName),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.location_on_rounded, 'Destination', journey.destinationName),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.timer_outlined, 'Elapsed / Expected', '${journey.elapsedMinutes} / ${journey.expectedDurationMinutes} min'),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.shield_outlined, 'Risk Assessment', 'Score: ${journey.riskScore.toStringAsFixed(1)} (${journey.riskLevel.name.toUpperCase()})'),
                  const SizedBox(height: 18),

                  // Live Tracking Map Header
                  const Text(
                    'Live Tracking Map',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),

                  // Map Container
                  JourneyMapView(
                    currentPosition: currentPos,
                    destinationPosition: destPos,
                    routePoints: routePoints,
                    journeyStatus: journey.status,
                    riskLevel: journey.riskLevel,
                    height: 240,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.policePrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.policePrimary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
