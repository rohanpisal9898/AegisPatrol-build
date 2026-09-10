import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/patrol_intelligence_provider.dart';

class IncidentReportingSheet extends StatefulWidget {
  const IncidentReportingSheet({super.key});

  @override
  State<IncidentReportingSheet> createState() => _IncidentReportingSheetState();
}

class _IncidentReportingSheetState extends State<IncidentReportingSheet> {
  String _selectedCategory = 'Theft';
  String _selectedSeverity = 'High';
  String _selectedSectorId = 'hex_andheri_east';
  final TextEditingController _descController = TextEditingController();

  final List<String> _categories = [
    'Theft',
    'Women Safety',
    'Road Accident',
    'CCTV Anomaly',
    'Public Disturbance',
    'Traffic Hazard',
  ];

  final List<String> _severities = ['Critical', 'High', 'Medium', 'Low'];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PatrolIntelligenceProvider>(context);
    final isDarkMode = provider.isDarkMode;

    final bgColor = isDarkMode ? const Color(0xFF071A2E) : Colors.white;
    final cardBg = isDarkMode ? const Color(0xFF0E263D) : const Color(0xFFF8FAFC);
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF10233D);
    final textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF63758A);
    final borderColor = isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report Patrol Incident',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF147DF5).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'FIELD DISPATCH',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF147DF5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Incident Category Chips
            Text('Incident Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: const Color(0xFF147DF5),
                  backgroundColor: cardBg,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : textSecondary,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Target Sector / Location Dropdown
            Text('Patrol Sector Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSectorId,
                  isExpanded: true,
                  dropdownColor: cardBg,
                  items: provider.hexCells.map((hex) {
                    return DropdownMenuItem(
                      value: hex.id,
                      child: Text(
                        '${hex.name} (Risk: ${hex.displayScore10})',
                        style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSectorId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Severity Level Row
            Text('Severity Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: _severities.map((sev) {
                final isSelected = _selectedSeverity == sev;
                Color chipColor;
                if (sev == 'Critical') {
                  chipColor = const Color(0xFFEA3F4F);
                } else if (sev == 'High') {
                  chipColor = const Color(0xFFF95738);
                } else if (sev == 'Medium') {
                  chipColor = const Color(0xFFF4A51C);
                } else {
                  chipColor = const Color(0xFF18B875);
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSeverity = sev),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? chipColor : cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? chipColor : borderColor),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          sev,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Short Description
            Text('Incident Observation Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: TextStyle(color: textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Describe incident details, suspect traits, or hazard location...',
                hintStyle: TextStyle(color: textSecondary, fontSize: 12),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Submit Incident Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF147DF5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final targetHex = provider.hexCells.firstWhere((h) => h.id == _selectedSectorId);
                  final desc = _descController.text.trim().isNotEmpty
                      ? _descController.text.trim()
                      : 'Field officer patrol report filed for ${targetHex.name}.';

                  provider.reportIncident(
                    category: _selectedCategory,
                    locationName: targetHex.name,
                    severity: _selectedSeverity,
                    description: desc,
                    position: targetHex.center,
                    sectorId: targetHex.id,
                  );

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Incident reported! ${targetHex.shortCode} risk score increased, alerts updated.'),
                      backgroundColor: const Color(0xFF18B875),
                    ),
                  );
                },
                child: const Text(
                  'Submit & Transmit Dispatch',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
