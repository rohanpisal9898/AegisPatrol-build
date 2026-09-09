import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/journey_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/journey_service.dart';

final GlobalKey<CivilianJourneysScreenState> civilianJourneysKey = GlobalKey<CivilianJourneysScreenState>();

class CivilianJourneysScreen extends StatefulWidget {
  const CivilianJourneysScreen({super.key});

  @override
  State<CivilianJourneysScreen> createState() => CivilianJourneysScreenState();
}

class CivilianJourneysScreenState extends State<CivilianJourneysScreen> {
  final JourneyService _journeyService = JourneyService();
  bool _isLoading = true;
  String? _errorMessage;
  List<JourneyModel> _journeys = [];

  @override
  void initState() {
    super.initState();
    loadJourneys();
  }

  Future<void> loadJourneys() async {
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

    final res = await _journeyService.listJourneys(token: token);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.data != null) {
          _journeys = res.data!;
        } else {
          _errorMessage = res.message ?? 'Failed to load journeys';
        }
      });
    }
  }

  void _showJourneyDetails(JourneyModel journey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
                const Text(
                  'Journey Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.civilianPinkLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    journey.status == JourneyStatus.completed ? 'Completed' : 'Active',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.civilianPink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Mode', journey.travelMode.label),
            _buildDetailRow('Destination', journey.destinationName ?? 'Safe Route'),
            _buildDetailRow('Distance', '${journey.distanceKm.toStringAsFixed(1)} km'),
            _buildDetailRow(
              'Duration',
              journey.actualDurationMinutes != null
                  ? '${journey.actualDurationMinutes!.toStringAsFixed(0)} min'
                  : '${journey.expectedDurationMinutes} min (est.)',
            ),
            if (journey.startedAt != null)
              _buildDetailRow('Started At', DateFormat('MMM d, yyyy • h:mm a').format(journey.startedAt!.toLocal())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.civilianPink,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.civilianPinkSurface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Journey History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.civilianPink,
        onRefresh: loadJourneys,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.civilianPink));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loadJourneys,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.civilianPink),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final completedJourneys = _journeys.where((j) => j.status == JourneyStatus.completed).toList();

    if (completedJourneys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.civilianPinkLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.route_outlined, size: 36, color: AppColors.civilianPink),
              ),
              const SizedBox(height: 16),
              const Text(
                'No journeys yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your completed journeys and safety analytics will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: completedJourneys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final journey = completedJourneys[idx];
        final dateStr = journey.createdAt != null
            ? DateFormat('EEE, MMM d, yyyy').format(journey.createdAt!.toLocal())
            : 'Recent';

        final durationStr = journey.actualDurationMinutes != null
            ? '${journey.actualDurationMinutes!.toStringAsFixed(0)} min'
            : '${journey.expectedDurationMinutes} min';

        final distStr = '${journey.distanceKm.toStringAsFixed(1)} km';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => _showJourneyDetails(journey),
            leading: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.civilianPinkLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_walk_rounded, color: AppColors.civilianPink, size: 24),
            ),
            title: Text(
              dateStr,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  journey.destinationName ?? 'Safe Destination',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '$durationStr · $distStr',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.civilianPinkLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Completed Safely',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.civilianPink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ),
        );
      },
    );
  }
}
