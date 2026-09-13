import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../../models/patrol_domain_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/patrol_intelligence_provider.dart';
import '../../../services/police_service.dart';

class PoliceJourneysScreen extends StatefulWidget {
  const PoliceJourneysScreen({super.key});

  @override
  State<PoliceJourneysScreen> createState() => _PoliceJourneysScreenState();
}

class _PoliceJourneysScreenState extends State<PoliceJourneysScreen> {
  final PoliceService _policeService = PoliceService();
  Timer? _pollTimer;
  bool _isLoading = true;
  String? _errorMessage;
  List<SafeJourneyItem> _liveJourneys = [];
  String _selectedDistrict = 'All'; // Default to "All" as requested by user

  @override
  void initState() {
    super.initState();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchJourneys();
      });
      // Auto-poll every 4 seconds so journeys created on civilian side appear in real-time
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) {
          _fetchJourneys(silent: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchJourneys({bool silent = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final patrolProvider = Provider.of<PatrolIntelligenceProvider>(context, listen: false);

    // If unauthenticated, ensure a valid police session is active
    if (!auth.isAuthenticated || auth.currentUser?.role != 'police') {
      await auth.ensureRoleSession('police');
    }

    final token = auth.token;
    if (token == null || token.isEmpty) {
      if (!silent && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication required to monitor citizen journeys.';
        });
      }
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _policeService.getPoliceJourneys(token: token);

      if (mounted) {
        if (response.success && response.data != null) {
          final mapped = response.data!.map((m) => SafeJourneyItem.fromPoliceJourneyModel(m)).toList();
          setState(() {
            _liveJourneys = mapped;
            _isLoading = false;
            _errorMessage = null;
          });
          // Also sync to PatrolIntelligenceProvider so dashboard/maps are aware of real journeys
          if (mapped.isNotEmpty) {
            patrolProvider.setSafeJourneys(mapped);
          }
        } else {
          if (!silent) {
            setState(() {
              _isLoading = false;
              _errorMessage = response.message ?? 'Failed to retrieve active journeys';
            });
          }
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Connection error. Retrying in background...';
        });
      }
    }
  }

  List<String> _getAvailableDistricts(String officerDistrict) {
    final Set<String> districts = {'All'};
    if (officerDistrict.isNotEmpty && officerDistrict != 'All') {
      districts.add(officerDistrict);
    }
    for (final j in _liveJourneys) {
      if (j.district != null && j.district!.isNotEmpty) {
        districts.add(j.district!);
      }
    }
    // Standard key districts
    districts.addAll(['Mumbai Suburban', 'Kolhapur', 'Thane', 'Mumbai City']);
    return districts.toList();
  }

  List<SafeJourneyItem> _getFilteredJourneys() {
    if (_selectedDistrict == 'All') {
      return _liveJourneys;
    }
    final target = _selectedDistrict.toLowerCase().trim();
    return _liveJourneys.where((j) {
      final d = (j.district ?? '').toLowerCase();
      final s = j.startLocation.toLowerCase();
      final dest = j.destination.toLowerCase();
      return d.contains(target) || s.contains(target) || dest.contains(target);
    }).toList();
  }

  void _showJourneyDetailSheet(BuildContext context, SafeJourneyItem journey, PatrolIntelligenceProvider provider) {
    final isDarkMode = provider.isDarkMode;
    final cardBg = isDarkMode ? const Color(0xFF0E263D) : Colors.white;
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF10233D);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF63758A);
    final borderColor = isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journey.id,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 14, color: textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                journey.civilianName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                              ),
                            ),
                            if (journey.district != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF147DF5).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  journey.district!,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF147DF5)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: journey.statusBadgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      journey.status == SafeJourneyStatus.highRisk
                          ? 'High Risk'
                          : (journey.status == SafeJourneyStatus.attention ? 'Attention' : 'Normal'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: journey.statusBadgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Scrollable Details (Map + Metadata Info Card)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Live Tracking Map
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: journey.currentPos,
                            initialZoom: 12.5,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: isDarkMode
                                  ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.aegispatrol.safety',
                            ),
                            if (journey.routePoints.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: journey.routePoints,
                                    strokeWidth: 4.5,
                                    color: journey.status == SafeJourneyStatus.highRisk
                                        ? const Color(0xFFEA3F4F)
                                        : const Color(0xFF147DF5),
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                // Origin marker
                                if (journey.routePoints.isNotEmpty)
                                  Marker(
                                    point: journey.routePoints.first,
                                    width: 26,
                                    height: 26,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.trip_origin_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                // Current GPS location marker
                                Marker(
                                  point: journey.currentPos,
                                  width: 36,
                                  height: 36,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: journey.statusBadgeColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: journey.statusBadgeColor.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(journey.travelModeIcon, color: Colors.white, size: 18),
                                  ),
                                ),
                                // Destination marker
                                Marker(
                                  point: journey.destPos,
                                  width: 30,
                                  height: 30,
                                  child: const Icon(Icons.location_on_rounded, color: Color(0xFFEA3F4F), size: 30),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Journey Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF071A2E) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            _buildModalRow('Origin', journey.startLocation, textPrimary, textSecondary),
                            const SizedBox(height: 6),
                            _buildModalRow('Destination', journey.destination, textPrimary, textSecondary),
                            const SizedBox(height: 6),
                            _buildModalRow('Mode & Duration', '${journey.travelMode} • ${journey.durationMinutes} min total', textPrimary, textSecondary),
                            const SizedBox(height: 6),
                            _buildModalRow('Elapsed / ETA', '${journey.elapsedMinutes} min elapsed • ETA ${journey.eta}', textPrimary, textSecondary),
                            const SizedBox(height: 6),
                            _buildModalRow('Status Reason', journey.statusReason, journey.statusBadgeColor, textSecondary),
                            const SizedBox(height: 6),
                            _buildModalRow('Risk Assessment', '${journey.riskScore.toStringAsFixed(1)} / 10.0', textPrimary, textSecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Actions Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 17),
                      label: const Text('Contact User', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling civilian: ${journey.civilianName}')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA3F4F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.emergency_rounded, size: 17),
                      label: const Text('Escalate SOS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      onPressed: () {
                        provider.escalateSafeJourney(journey.id);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SOS Escalated! Nearest patrol unit intercepted journey.'),
                            backgroundColor: Color(0xFFEA3F4F),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18B875),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    provider.resolveSafeJourney(journey.id);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Safe journey verified and closed.'),
                        backgroundColor: Color(0xFF18B875),
                      ),
                    );
                  },
                  child: const Text('Mark Journey Safe & Resolved', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildModalRow(String label, String value, Color valueColor, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: valueColor),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatrolIntelligenceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDarkMode = provider.isDarkMode;

    final officerDistrict = auth.currentUser != null && auth.currentUser!.district.isNotEmpty
        ? auth.currentUser!.district.split(',')[0].trim()
        : 'Mumbai Suburban';
    final availableDistricts = _getAvailableDistricts(officerDistrict);
    final filteredJourneys = _getFilteredJourneys();

    final bgColor = isDarkMode ? const Color(0xFF071A2E) : const Color(0xFFF5F8FC);
    final cardBg = isDarkMode ? const Color(0xFF0E263D) : Colors.white;
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF10233D);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF63758A);
    final borderColor = isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0);

    // Dynamic counts based on filtered list
    final totalActive = filteredJourneys.length;
    final normalCount = filteredJourneys.where((j) => j.status == SafeJourneyStatus.normal).length;
    final attentionCount = filteredJourneys.where((j) => j.status == SafeJourneyStatus.attention).length;
    final highRiskCount = filteredJourneys.where((j) => j.status == SafeJourneyStatus.highRisk).length;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Safe Journeys',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18B875).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF18B875),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'LIVE DB',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF18B875),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Live MongoDB civilian tracking • Officer: ${auth.currentUser?.name ?? 'Patrol Unit'}",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: textSecondary, size: 22),
                    tooltip: 'Refresh Active Journeys',
                    onPressed: () => _fetchJourneys(),
                  ),
                ],
              ),
            ),

            // District Filter Slider / Horizontal Chips (User Requested)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: availableDistricts.length,
                  itemBuilder: (context, index) {
                    final d = availableDistricts[index];
                    final isSelected = _selectedDistrict.toLowerCase() == d.toLowerCase();
                    final int count = d == 'All'
                        ? _liveJourneys.length
                        : _liveJourneys.where((j) {
                            final target = d.toLowerCase();
                            return (j.district ?? '').toLowerCase().contains(target) ||
                                j.startLocation.toLowerCase().contains(target) ||
                                j.destination.toLowerCase().contains(target);
                          }).length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            _selectedDistrict = d;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF147DF5)
                                : (isDarkMode ? const Color(0xFF0E263D) : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF147DF5) : borderColor,
                              width: 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF147DF5).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                d == 'All'
                                    ? Icons.public_rounded
                                    : (d == officerDistrict ? Icons.near_me_rounded : Icons.location_on_rounded),
                                size: 14,
                                color: isSelected ? Colors.white : textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                d == 'All' ? 'All Tracking' : (d == officerDistrict ? 'My District ($d)' : d),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : (isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Metric Counters Header Card (Responsive Expanded Distribution)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Total Active
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.groups_rounded, size: 13, color: textSecondary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'Active',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$totalActive',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 26, color: borderColor),

                    // Normal
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF18B875), shape: BoxShape.circle)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'Normal',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$normalCount',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF18B875)),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 26, color: borderColor),

                    // Attention
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFF4A51C), shape: BoxShape.circle)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'Attention',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$attentionCount',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFF4A51C)),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 26, color: borderColor),

                    // High Risk
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFEA3F4F), shape: BoxShape.circle)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'High Risk',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$highRiskCount',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFEA3F4F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Journey Cards List or Empty State
            Expanded(
              child: _buildJourneyList(context, filteredJourneys, provider, cardBg, textPrimary, textSecondary, borderColor, isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyList(
    BuildContext context,
    List<SafeJourneyItem> journeys,
    PatrolIntelligenceProvider provider,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    bool isDarkMode,
  ) {
    if (_isLoading && _liveJourneys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF147DF5)),
            const SizedBox(height: 12),
            Text(
              'Connecting to live MongoDB Atlas journeys...',
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _liveJourneys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFFEA3F4F)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF147DF5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Connection'),
                onPressed: () => _fetchJourneys(),
              ),
            ],
          ),
        ),
      );
    }

    if (journeys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 48, color: textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'No Active Journeys in $_selectedDistrict',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedDistrict == 'All'
                    ? 'No civilian journeys are currently in progress.'
                    : 'All citizens in this district are safely at their destinations. Switch to "All Tracking" to see active citizens across other districts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: textSecondary),
              ),
              if (_selectedDistrict != 'All') ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF147DF5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.public_rounded, size: 16),
                  label: const Text('Show All Districts'),
                  onPressed: () => setState(() => _selectedDistrict = 'All'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: journeys.length,
      itemBuilder: (context, index) {
        final journey = journeys[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: journey.status == SafeJourneyStatus.highRisk
                  ? const Color(0xFFEA3F4F)
                  : borderColor,
              width: journey.status == SafeJourneyStatus.highRisk ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: journey.status == SafeJourneyStatus.highRisk
                    ? const Color(0xFFEA3F4F).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showJourneyDetailSheet(context, journey, provider),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Avatar icon, Civilian Name, District badge, Status Badge, Chevron
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: journey.statusBadgeBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_rounded, color: journey.statusBadgeColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      journey.civilianName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    journey.id,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (journey.district != null)
                                Row(
                                  children: [
                                    Icon(Icons.location_city_rounded, size: 12, color: textSecondary),
                                    const SizedBox(width: 3),
                                    Text(
                                      journey.district!,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: journey.statusBadgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            journey.status == SafeJourneyStatus.highRisk
                                ? 'High Risk'
                                : (journey.status == SafeJourneyStatus.attention ? 'Attention' : 'Normal'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: journey.statusBadgeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: textSecondary, size: 18),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Origin -> Destination
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${journey.startLocation}  ➔  ${journey.destination}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ETA & Transport Mode
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'ETA ${journey.eta}  •  ${journey.elapsedMinutes}m elapsed',
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                        ),
                        const Spacer(),
                        Icon(journey.travelModeIcon, size: 14, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          journey.travelMode,
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

