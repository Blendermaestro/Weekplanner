import 'package:flutter/material.dart';
import '../models/shift_data.dart';

class ShiftGrid extends StatelessWidget {
  final List<Worker> workers;
  final List<HousingUnit> housingUnits;
  final List<MasterClass> masterClasses;
  final Function(int) onEditWorker;
  final Function(int) onDeleteWorker;

  const ShiftGrid({
    super.key,
    required this.workers,
    required this.housingUnits,
    required this.masterClasses,
    required this.onEditWorker,
    required this.onDeleteWorker,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(),
              ...workers.asMap().entries.map((entry) {
                final index = entry.key;
                final worker = entry.value;
                return _buildWorkerRow(context, worker, index);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        // Worker info column
        Container(
          width: 250,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            border: Border.all(color: Colors.grey),
          ),
          child: const Center(
            child: Text(
              'Worker / Profession',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Day headers
        ...Constants.weekDays.map((day) => Container(
              width: 120,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                border: Border.all(color: Colors.grey),
              ),
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildWorkerRow(BuildContext context, Worker worker, int workerIndex) {
    return Row(
      children: [
        // Worker info cell
        Container(
          width: 250,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  iconSize: 16,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEditWorker(workerIndex);
                    } else if (value == 'delete') {
                      onDeleteWorker(workerIndex);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        // Day cells - now just repeat the same assignment across all days
        ..._buildWeekCells(worker),
      ],
    );
  }

  List<Widget> _buildWeekCells(Worker worker) {
    // Since shift and housing are now for the whole week, create one merged cell spanning all 7 days
    final shiftType = _getWorkerShiftType(worker);
    final displayText = _getWorkerDisplayText(worker, shiftType);
    
    return [
      _buildShiftCell(
        displayText,
        _getShiftColor(shiftType),
        7, // Span all 7 days
      )
    ];
  }

  ShiftType _getWorkerShiftType(Worker worker) {
    if (worker.masterClassId == null) return ShiftType.off;
    final masterClass = masterClasses.firstWhere(
      (mc) => mc.id == worker.masterClassId,
      orElse: () => MasterClass(id: '', displayName: '', shiftType: ShiftType.off),
    );
    return masterClass.shiftType;
  }

  String _getWorkerDisplayText(Worker worker, ShiftType shiftType) {
    if (worker.masterClassId == null) {
      return '';
    } else if (worker.housingId != null) {
      final housing = housingUnits.firstWhere(
        (unit) => unit.id == worker.housingId,
        orElse: () => HousingUnit(id: '', displayName: 'Unknown', shiftType: ShiftType.off, maxCapacity: 0),
      );
      return '${worker.profession}\n${shiftType.displayName} - ${housing.displayName}';
    } else {
      return '${worker.profession}\n${shiftType.displayName} - Class ${worker.masterClassId}';
    }
  }

  Widget _buildShiftCell(String displayText, Color color, int spanDays) {
    final width = 120.0 * spanDays;
    
    return Container(
      width: width,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.grey),
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
            color: _getTextColor(color),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Color _getShiftColor(ShiftType shiftType) {
    switch (shiftType) {
      case ShiftType.day:
        return Colors.blue.shade100;
      case ShiftType.night:
        return Colors.grey.shade700;
      case ShiftType.off:
        return Colors.grey.shade200;
    }
  }

  Color _getTextColor(Color backgroundColor) {
    // Return white text for dark backgrounds, black for light backgrounds
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
} 