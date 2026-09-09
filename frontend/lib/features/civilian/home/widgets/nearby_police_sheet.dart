import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/police_station_model.dart';
import '../../../../services/police_service.dart';
import '../../../../services/location_service.dart';

class NearbyPoliceSheet extends StatefulWidget {
  final String token;

  const NearbyPoliceSheet({super.key, required this.token});

  static Future<void> show(BuildContext context, {required String token}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NearbyPoliceSheet(token: token),
    );
  }

  @override
  State<NearbyPoliceSheet> createState() => _NearbyPoliceSheetState();
}

class _NearbyPoliceSheetState extends State<NearbyPoliceSheet> {
  final PoliceService _policeService = PoliceService();
  bool _isLoading = true;
  String? _errorMessage;
  LatLng? _userLocation;
  List<PoliceStationModel> _stations = [];
  PoliceStationModel? _selectedStation;

  @override
  void initState() {
    super.initState();
    _fetchNearbyPolice();
  }

  Future<void> _fetchNearbyPolice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final loc = await LocationService.getCurrentLocation();
    final LatLng pos = loc.position ?? const LatLng(19.0596, 72.8368); // fallback demo pos if simulator
    _userLocation = pos;

    final res = await _policeService.getNearbyPolice(
      token: widget.token,
      lat: pos.latitude,
      lon: pos.longitude,
      radiusKm: 12.0,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.data != null) {
          _stations = res.data!;
          if (_stations.isNotEmpty) _selectedStation = _stations.first;
        } else {
          _errorMessage = res.message ?? 'No police stations found nearby';
        }
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Copied $label ($text) to clipboard'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.civilianPinkLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_police_rounded, color: AppColors.civilianPink, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Nearby Police Stations',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.civilianPink),
              ),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchNearbyPolice,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.civilianPink),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Interactive Map showing police pins
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _userLocation ?? const LatLng(19.0596, 72.8368),
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.aegispatrol.safety',
                          tileProvider: NetworkTileProvider(),
                        ),
                        MarkerLayer(
                          markers: [
                            // User Location
                            if (_userLocation != null)
                              Marker(
                                point: _userLocation!,
                                width: 36,
                                height: 36,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                                    ],
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                                ),
                              ),
                            // Police Station Pins
                            ..._stations.map(
                              (s) => Marker(
                                point: s.coordinates,
                                width: 38,
                                height: 38,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedStation = s);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _selectedStation?.id == s.id ? AppColors.civilianPink : AppColors.civilianPink,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4),
                                      ],
                                    ),
                                    child: const Icon(Icons.local_police, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Stations List
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${_stations.length} ${_stations.length == 1 ? "Station" : "Stations"} Found Within 12 km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Sorted by distance', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _stations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final station = _stations[idx];
                        final isSelected = _selectedStation?.id == station.id;

                        return Material(
                          color: isSelected ? AppColors.civilianPinkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setState(() => _selectedStation = station),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isSelected ? AppColors.civilianPink : AppColors.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.civilianPink : AppColors.civilianPinkLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.shield_rounded,
                                      color: isSelected ? Colors.white : AppColors.civilianPink,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                station.name,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isSelected ? AppColors.civilianPinkLight : AppColors.background,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: isSelected ? AppColors.civilianPink : AppColors.border),
                                              ),
                                              child: Text(
                                                '${station.distanceKm?.toStringAsFixed(1) ?? '—'} km',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? AppColors.civilianPink : AppColors.textPrimary),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (station.address != null) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            station.address!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                        if (station.phone != null) ...[
                                          const SizedBox(height: 6),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(6),
                                            onTap: () => _copyToClipboard(station.phone!, station.name),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.phone_rounded, size: 13, color: AppColors.civilianPink),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      station.phone!,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.civilianPink,
                                                        fontWeight: FontWeight.w700,
                                                        decoration: TextDecoration.underline,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.copy_rounded, size: 12, color: AppColors.textMuted),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
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
                ],
              ),
            ),
        ],
      ),
    );
  }
}
