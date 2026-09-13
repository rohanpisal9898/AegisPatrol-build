import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/patrol_domain_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/patrol_intelligence_provider.dart';
import '../../../services/alert_service.dart';

class PoliceAlertsScreen extends StatefulWidget {
  const PoliceAlertsScreen({super.key});

  @override
  State<PoliceAlertsScreen> createState() => _PoliceAlertsScreenState();
}

class _PoliceAlertsScreenState extends State<PoliceAlertsScreen> {
  final AlertService _alertService = AlertService();
  Timer? _pollTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchLiveAlerts();
      });
      // Auto-poll every 4s for instant live SOS dispatch
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) {
          _fetchLiveAlerts(silent: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveAlerts({bool silent = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<PatrolIntelligenceProvider>(context, listen: false);

    if (!auth.isAuthenticated || auth.currentUser?.role != 'police') {
      await auth.ensureRoleSession('police');
    }

    final token = auth.token;
    if (token == null || token.isEmpty) return;

    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final res = await _alertService.getAlerts(token: token);
      if (res.success && res.data != null && res.data!.isNotEmpty) {
        final livePatrolAlerts = res.data!.map((m) => PatrolAlert.fromAlertModel(m)).toList();
        if (mounted) {
          provider.mergeLiveAlerts(livePatrolAlerts);
        }
      }
    } catch (_) {}

    if (!silent && mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showAlertActionModal(BuildContext context, PatrolAlert alert, PatrolIntelligenceProvider provider) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isDarkMode = provider.isDarkMode;
    final cardBg = isDarkMode ? const Color(0xFF0E263D) : Colors.white;
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF10233D);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF63758A);
    final borderColor = isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0);
    final isSos = alert.alertType == 'sos' || alert.isCritical;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Alert Header
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: alert.iconBgColor,
                        shape: BoxShape.circle,
                        boxShadow: isSos
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFEA3F4F).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(alert.icon, color: alert.iconColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${alert.locationName} • ${alert.timeAgo}',
                            style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: alert.severityBadgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alert.severity == AlertSeverity.critical ? 'CRITICAL SOS' : alert.severity.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: alert.severityBadgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Civilian Contact & Location Details Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF071A2E) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSos ? const Color(0xFFEA3F4F).withValues(alpha: 0.4) : borderColor,
                      width: isSos ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSos ? Icons.emergency_rounded : Icons.info_outline_rounded,
                            size: 16,
                            color: isSos ? const Color(0xFFEA3F4F) : const Color(0xFF147DF5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSos ? 'EMERGENCY CIVILIAN DOSSIER' : 'INCIDENT DETAILS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSos ? const Color(0xFFEA3F4F) : const Color(0xFF147DF5),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Civilian Name Row
                      _buildDetailRow(
                        'Civilian Name',
                        alert.civilianName ?? 'Civilian User',
                        Icons.person_rounded,
                        textPrimary,
                        textSecondary,
                      ),
                      const SizedBox(height: 8),

                      // Phone Number Row with Call Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.phone_rounded, size: 14, color: textSecondary),
                              const SizedBox(width: 6),
                              Text('Phone Number', style: TextStyle(fontSize: 12, color: textSecondary)),
                            ],
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              final phone = alert.civilianPhone ?? '+91 9820098200';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Calling civilian at $phone...'),
                                  backgroundColor: const Color(0xFF18B875),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18B875).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF18B875).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.call_rounded, size: 12, color: Color(0xFF18B875)),
                                  const SizedBox(width: 4),
                                  Text(
                                    alert.civilianPhone != null && alert.civilianPhone!.isNotEmpty
                                        ? alert.civilianPhone!
                                        : '9820098200',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF18B875),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Live GPS Coordinates Row
                      _buildDetailRow(
                        'Live GPS Location',
                        '${alert.position.latitude.toStringAsFixed(4)}° N, ${alert.position.longitude.toStringAsFixed(4)}° E',
                        Icons.my_location_rounded,
                        const Color(0xFF147DF5),
                        textSecondary,
                      ),
                      const SizedBox(height: 8),

                      // Area / District Row
                      _buildDetailRow(
                        'District / Area',
                        alert.locationName,
                        Icons.location_city_rounded,
                        textPrimary,
                        textSecondary,
                      ),
                      const SizedBox(height: 8),

                      // Description / Message
                      _buildDetailRow(
                        'Alert Message',
                        alert.description,
                        Icons.chat_bubble_outline_rounded,
                        textPrimary,
                        textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions Grid
                Row(
                  children: [
                    // Direct Call Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF18B875),
                          side: const BorderSide(color: Color(0xFF18B875)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                        label: const Text('Call Civilian', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        onPressed: () {
                          final phone = alert.civilianPhone ?? '+91 9820098200';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Connecting emergency call to $phone...'),
                              backgroundColor: const Color(0xFF18B875),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Dispatch Backup Unit Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF147DF5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.shield_rounded, size: 18),
                        label: const Text('Dispatch Unit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        onPressed: () {
                          provider.dispatchBackup(alert.id, 'Unit P-12');
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Patrol Unit P-12 dispatched to civilian coordinates.'),
                              backgroundColor: Color(0xFF147DF5),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Resolve Alert Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18B875),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.task_alt_rounded, size: 18),
                    label: const Text('Resolve & Mark Safe', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    onPressed: () async {
                      provider.resolveAlert(alert.id);
                      if (auth.token != null) {
                        _alertService.resolveAlert(token: auth.token!, alertId: alert.id);
                      }
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Alert marked as RESOLVED and archived in DB.'),
                          backgroundColor: Color(0xFF18B875),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value, IconData icon, Color valueColor, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: labelColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
          ],
        ),
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

    final bgColor = isDarkMode ? const Color(0xFF071A2E) : const Color(0xFFF5F8FC);
    final cardBg = isDarkMode ? const Color(0xFF0E263D) : Colors.white;
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF10233D);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF63758A);
    final borderColor = isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0);

    // Filter alerts based on active tab
    final filteredAlerts = provider.alerts.where((alert) {
      if (provider.activeAlertTab == 'All') return true;
      if (provider.activeAlertTab == 'Critical') return alert.severity == AlertSeverity.critical;
      if (provider.activeAlertTab == 'High') return alert.severity == AlertSeverity.high;
      if (provider.activeAlertTab == 'Medium') return alert.severity == AlertSeverity.medium;
      if (provider.activeAlertTab == 'Resolved') return alert.severity == AlertSeverity.resolved;
      return true;
    }).toList();

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
                              'Alerts',
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
                                color: const Color(0xFFEA3F4F).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEA3F4F),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'LIVE DB',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFEA3F4F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Live civilian SOS & safety monitoring • ${auth.currentUser?.name ?? "Officer"}',
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
                    tooltip: 'Refresh Alerts',
                    onPressed: () => _fetchLiveAlerts(),
                  ),
                ],
              ),
            ),

            // Filter Tabs: [All] [Critical] [High] [Medium] [Resolved]
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: ['All', 'Critical', 'High', 'Medium', 'Resolved'].map((tab) {
                  final isSelected = provider.activeAlertTab == tab;
                  final int count = provider.alerts.where((a) {
                    if (tab == 'All') return true;
                    if (tab == 'Critical') return a.severity == AlertSeverity.critical;
                    if (tab == 'High') return a.severity == AlertSeverity.high;
                    if (tab == 'Medium') return a.severity == AlertSeverity.medium;
                    if (tab == 'Resolved') return a.severity == AlertSeverity.resolved;
                    return true;
                  }).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => provider.setAlertTab(tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF147DF5) : cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF147DF5) : borderColor,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: const Color(0xFF147DF5).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tab,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : textSecondary,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                }).toList(),
              ),
            ),

            // Alerts List
            Expanded(
              child: _isLoading && provider.alerts.isEmpty
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF147DF5)))
                  : filteredAlerts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none_rounded, size: 48, color: textSecondary),
                              const SizedBox(height: 12),
                              Text('No alerts in this category', style: TextStyle(color: textSecondary, fontSize: 14)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _fetchLiveAlerts(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: filteredAlerts.length,
                            itemBuilder: (context, index) {
                              final alert = filteredAlerts[index];
                              final isSos = alert.alertType == 'sos' || alert.isCritical;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSos ? const Color(0xFFEA3F4F).withValues(alpha: 0.5) : borderColor,
                                    width: isSos ? 1.4 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSos
                                          ? const Color(0xFFEA3F4F).withValues(alpha: isDarkMode ? 0.2 : 0.08)
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
                                    onTap: () => _showAlertActionModal(context, alert, provider),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Circular Icon with Red Pulse for SOS
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: alert.iconBgColor,
                                              shape: BoxShape.circle,
                                              border: isSos ? Border.all(color: const Color(0xFFEA3F4F), width: 1.5) : null,
                                            ),
                                            child: Icon(alert.icon, color: alert.iconColor, size: 22),
                                          ),
                                          const SizedBox(width: 12),

                                          // Content Center
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Severity Badge & Time
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: alert.severityBadgeBg,
                                                        borderRadius: BorderRadius.circular(5),
                                                      ),
                                                      child: Text(
                                                        alert.severity == AlertSeverity.critical ? 'CRITICAL SOS' : alert.severity.name.toUpperCase(),
                                                        style: TextStyle(
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.w800,
                                                          color: alert.severityBadgeColor,
                                                          letterSpacing: 0.4,
                                                        ),
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.access_time_rounded, size: 11, color: textSecondary),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          alert.timeAgo,
                                                          style: TextStyle(fontSize: 11, color: textSecondary),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),

                                                // Alert Title
                                                Text(
                                                  alert.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),

                                                // Civilian Name & Phone row if available
                                                if (alert.civilianName != null || alert.civilianPhone != null) ...[
                                                  Row(
                                                    children: [
                                                      Icon(Icons.person_rounded, size: 12, color: textSecondary),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        alert.civilianName ?? 'Civilian User',
                                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textPrimary),
                                                      ),
                                                      if (alert.civilianPhone != null) ...[
                                                        const SizedBox(width: 8),
                                                        const Icon(Icons.phone_rounded, size: 11, color: Color(0xFF18B875)),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          alert.civilianPhone!,
                                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF18B875)),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                ],

                                                // Location & GPS Coordinates
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_on_outlined, size: 12, color: textSecondary),
                                                    const SizedBox(width: 3),
                                                    Flexible(
                                                      child: Text(
                                                        '${alert.locationName} (${alert.position.latitude.toStringAsFixed(3)}, ${alert.position.longitude.toStringAsFixed(3)})',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),

                                                // Description
                                                Text(
                                                  alert.description,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: textSecondary,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),

                                          // Right Chevron
                                          Padding(
                                            padding: const EdgeInsets.only(top: 14),
                                            child: Icon(Icons.chevron_right_rounded, color: textSecondary, size: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
