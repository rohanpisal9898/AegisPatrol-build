import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/alert_service.dart';
import '../../../../services/location_service.dart';
import '../../../../services/sos_tracking_manager.dart';

class SosDialog extends StatefulWidget {
  final String token;
  final String? journeyId;
  final LatLng? currentPos;
  final String? district;

  const SosDialog({
    super.key,
    required this.token,
    this.journeyId,
    this.currentPos,
    this.district,
  });

  static Future<void> show(
    BuildContext context, {
    required String token,
    String? journeyId,
    LatLng? currentPos,
    String? district,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => SosDialog(
        token: token,
        journeyId: journeyId,
        currentPos: currentPos,
        district: district,
      ),
    );
  }

  @override
  State<SosDialog> createState() => _SosDialogState();
}

class _SosDialogState extends State<SosDialog> {
  bool _isSending = false;
  bool _sentSuccess = false;
  String? _errorMessage;

  Future<void> _handleConfirmSos() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    double lat = widget.currentPos?.latitude ?? 19.0596;
    double lon = widget.currentPos?.longitude ?? 72.8368;

    try {
      final locResult = await LocationService.getCurrentLocation();
      if (locResult.position != null) {
        lat = locResult.position!.latitude;
        lon = locResult.position!.longitude;
      }
    } catch (_) {}

    final alertService = AlertService();
    final res = await alertService.createAlert(
      token: widget.token,
      journeyId: widget.journeyId,
      district: widget.district,
      lat: lat,
      lon: lon,
      alertType: 'sos',
      message: 'Civilian triggered instant SOS emergency button',
      riskScore: 10.0,
    );

    if (mounted) {
      if (res.success && res.data != null) {
        SosTrackingManager().startTracking(
          token: widget.token,
          alertId: res.data!.id,
          message: 'Civilian triggered instant SOS emergency button',
          initialPos: LatLng(lat, lon),
        );
        setState(() {
          _isSending = false;
          _sentSuccess = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        setState(() {
          _isSending = false;
          _errorMessage = res.message ?? 'Failed to send SOS';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sentSuccess) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'SOS Sent Successfully',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your emergency coordinates have been recorded and shared with AegisPatrol response center.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.quickActionSosBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency_rounded, color: AppColors.quickActionSosIcon, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Send SOS?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your live emergency location will be shared immediately with AegisPatrol safety monitoring.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                    ),
                    onPressed: _isSending ? null : _handleConfirmSos,
                    child: _isSending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Send SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
