import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/patrol_domain_models.dart';
import '../../../providers/patrol_intelligence_provider.dart';

class PoliceAlertsScreen extends StatelessWidget {
  const PoliceAlertsScreen({super.key});

  void _showAlertActionModal(BuildContext context, PatrolAlert alert, PatrolIntelligenceProvider provider) {
    final isDarkMode = provider.isDarkMode;
    final cardBg = isDarkMode ? const Color(0xFF0E263D) : Colors.white;
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF10233D);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF63758A);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0))),
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
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: alert.iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(alert.icon, color: alert.iconColor, size: 22),
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
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: alert.severityBadgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    alert.severity.name.toUpperCase(),
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: alert.severityBadgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              alert.description,
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Actions Grid
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Acknowledge'),
                    onPressed: () {
                      provider.acknowledgeAlert(alert.id);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alert acknowledged by Patrol Unit')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF147DF5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.shield_rounded, size: 18),
                    label: const Text('Dispatch Backup'),
                    onPressed: () {
                      provider.dispatchBackup(alert.id, 'Unit P-12');
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unit P-12 dispatched to intercept location.'),
                          backgroundColor: Color(0xFF147DF5),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                label: const Text('Resolve Alert', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  provider.resolveAlert(alert.id);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alert marked as RESOLVED and archived.'),
                      backgroundColor: Color(0xFF18B875),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatrolIntelligenceProvider>(context);
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
            // Top App Bar matching Reference B Screen 3
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
                        Text(
                          'Alerts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Incidents and events requiring attention',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.tune_rounded, color: textSecondary, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Filter Tabs: [All] [Critical] [High] [Medium] [Resolved] (Reference B Screen 3)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: ['All', 'Critical', 'High', 'Medium', 'Resolved'].map((tab) {
                  final isSelected = provider.activeAlertTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => provider.setAlertTab(tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Alerts List
            Expanded(
              child: filteredAlerts.isEmpty
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
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filteredAlerts.length,
                      itemBuilder: (context, index) {
                        final alert = filteredAlerts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                    // Circular Icon
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: alert.iconBgColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(alert.icon, color: alert.iconColor, size: 20),
                                    ),
                                    const SizedBox(width: 14),

                                    // Content Center
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Severity Badge
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: alert.severityBadgeBg,
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  alert.severity.name.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: alert.severityBadgeColor,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),

                                          // Alert Title
                                          Text(
                                            alert.title,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          // Location & Time
                                          Row(
                                            children: [
                                              Icon(Icons.location_on_outlined, size: 12, color: textSecondary),
                                              const SizedBox(width: 3),
                                              Text(
                                                alert.locationName,
                                                style: TextStyle(fontSize: 11.5, color: textSecondary, fontWeight: FontWeight.w500),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.access_time_rounded, size: 11, color: textSecondary),
                                              const SizedBox(width: 3),
                                              Text(
                                                alert.timeAgo,
                                                style: TextStyle(fontSize: 11.5, color: textSecondary),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),

                                          // Description
                                          Text(
                                            alert.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Right Chevron
                                    Padding(
                                      padding: const EdgeInsets.only(top: 18),
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
          ],
        ),
      ),
    );
  }
}
