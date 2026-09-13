import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/patrol_intelligence_provider.dart';
import '../home/widgets/hexagon_risk_detail_sheet.dart';

class PoliceAssignmentsScreen extends StatefulWidget {
  const PoliceAssignmentsScreen({super.key});

  @override
  State<PoliceAssignmentsScreen> createState() => _PoliceAssignmentsScreenState();
}

class _PoliceAssignmentsScreenState extends State<PoliceAssignmentsScreen> {
  final Set<int> _expandedRanks = {1, 2, 3, 4}; // Expand reasons by default matching screenshot

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatrolIntelligenceProvider>(context);
    final isDarkMode = provider.isDarkMode;
    final assignments = provider.assignments;

    final bgColor = isDarkMode ? const Color(0xFF071A2E) : const Color(0xFFF5F8FC);
    final cardBg = isDarkMode ? const Color(0xFF0E263D) : Colors.white;
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF10233D);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF63758A);
    final borderColor = isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar matching Reference B Screen 2
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
                          'Assignments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Priority areas for patrol deployment',
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filter assignments by jurisdiction/beat')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tab Bar: [Priority List] vs [Recent Updates] (Reference B Screen 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0E263D) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => provider.setAssignmentsTab('Priority List'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: provider.assignmentsTab == 'Priority List'
                                ? const Color(0xFF147DF5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.format_list_bulleted_rounded,
                                size: 16,
                                color: provider.assignmentsTab == 'Priority List' ? Colors.white : textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Priority List',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: provider.assignmentsTab == 'Priority List' ? Colors.white : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => provider.setAssignmentsTab('Recent Updates'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: provider.assignmentsTab == 'Recent Updates'
                                ? const Color(0xFF147DF5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Recent Updates',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: provider.assignmentsTab == 'Recent Updates' ? Colors.white : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Informational Banner Card (Reference B Screen 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0A223B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF147DF5).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_rounded, color: Color(0xFF147DF5), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Priorities are dynamically updated based on live risk, current coverage and ongoing incidents.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF1E40AF),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Last updated 09:41 PM',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Assignments List Content
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final item = assignments[index];
                  final isExpanded = _expandedRanks.contains(item.rank);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.04),
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
                        onTap: () {
                          // Find matching hex and open detail sheet
                          final hex = provider.hexCells.firstWhere(
                            (h) => h.id == item.hexId,
                            orElse: () => provider.hexCells.first,
                          );
                          provider.selectHexCell(hex);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => HexagonRiskDetailSheet(
                              cell: hex,
                              isDarkMode: isDarkMode,
                              onViewNearbyIncidents: () {
                                provider.setAlertTab('All');
                              },
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Rank Circle, Name/District, Risk Badge, Chevron
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: item.rankCircleColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${item.rank}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.sectorName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 12, color: textSecondary),
                                            const SizedBox(width: 3),
                                            Flexible(
                                              child: Text(
                                                item.districtName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 11.5, color: textSecondary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item.riskBadgeBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Risk ${item.riskScore}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: item.riskBadgeColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded, color: textSecondary, size: 18),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Coverage & Recommendation Row (Reference B Screen 2)
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Coverage', style: TextStyle(fontSize: 11, color: textSecondary)),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(color: item.coverageColor, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            item.coverage,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF147DF5)),
                                            const SizedBox(width: 4),
                                            Text('Recommended', style: TextStyle(fontSize: 11, color: textSecondary)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.recommendation,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Expandable "Why is this a priority?" Sub-card (Reference B Screen 2)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedRanks.remove(item.rank);
                                    } else {
                                      _expandedRanks.add(item.rank);
                                    }
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? const Color(0xFF0A223B) : const Color(0xFFFFFBF0),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? const Color(0xFF1E3A5F)
                                          : const Color(0xFFFDE68A).withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                size: 14,
                                                color: item.rank == 4 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Why is this a priority?',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDarkMode ? Colors.white : const Color(0xFF92400E),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Icon(
                                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                            size: 16,
                                            color: textSecondary,
                                          ),
                                        ],
                                      ),
                                      if (isExpanded) ...[
                                        const SizedBox(height: 6),
                                        ...item.whyReasons.map(
                                          (reason) => Padding(
                                            padding: const EdgeInsets.only(bottom: 2),
                                            child: Text(
                                              '• $reason',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF78350F),
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
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
