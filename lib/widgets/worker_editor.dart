import 'package:flutter/material.dart';
import '../models/shift_data.dart';

class WorkerEditorDialog extends StatefulWidget {
  final Worker? worker;
  final String? presetName;
  final List<HousingUnit> housingUnits;
  final List<MasterClass> masterClasses;
  final List<ProfessionCapacity> professionCapacities;
  final List<String> availableProfessions;
  final Function(Worker) onSave;

  const WorkerEditorDialog({
    super.key,
    this.worker,
    this.presetName,
    required this.housingUnits,
    required this.masterClasses,
    required this.professionCapacities,
    required this.availableProfessions,
    required this.onSave,
  });

  @override
  State<WorkerEditorDialog> createState() => _WorkerEditorDialogState();
}

class _WorkerEditorDialogState extends State<WorkerEditorDialog> {
  late TextEditingController nameController;
  late String selectedProfession;
  String? selectedMasterClassId;
  String? selectedHousingId;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.worker?.name ?? widget.presetName ?? ''
    );
    selectedProfession = widget.worker?.profession ?? widget.availableProfessions.first;
    selectedMasterClassId = widget.worker?.masterClassId;
    selectedHousingId = widget.worker?.housingId;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 400,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.worker == null ? 'Add Worker' : 'Edit Worker',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Name text input
            Row(
              children: [
                const SizedBox(width: 80, child: Text('Name:')),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter worker name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Profession dropdown
            Row(
              children: [
                const SizedBox(width: 80, child: Text('Role:')),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedProfession,
                    isExpanded: true,
                    items: widget.availableProfessions.map((profession) {
                      return DropdownMenuItem(
                        value: profession,
                        child: Text(profession),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedProfession = value;
                          // Reset master class if profession doesn't support current shift
                          if (selectedMasterClassId != null) {
                            final masterClass = widget.masterClasses.firstWhere(
                              (mc) => mc.id == selectedMasterClassId,
                              orElse: () => MasterClass(id: '', displayName: '', shiftType: ShiftType.off),
                            );
                            final profCapacity = Constants.getProfessionCapacity(value, widget.professionCapacities);
                            if (masterClass.shiftType == ShiftType.night && 
                                profCapacity != null && !profCapacity.availableAtNight) {
                              selectedMasterClassId = null;
                              selectedHousingId = null;
                            }
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Master class dropdown
            Row(
              children: [
                const SizedBox(width: 80, child: Text('Class:')),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedMasterClassId,
                    isExpanded: true,
                    hint: const Text('Select master class'),
                    items: _getAvailableMasterClasses().map((masterClass) {
                      return DropdownMenuItem(
                        value: masterClass.id,
                        child: Text('${masterClass.displayName} (${masterClass.shiftType.displayName})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMasterClassId = value;
                        // Reset housing selection when master class changes
                        selectedHousingId = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Housing dropdown (only when master class is selected)
            if (selectedMasterClassId != null) ...[
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('Housing:')),
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedHousingId,
                      isExpanded: true,
                      hint: const Text('Select housing'),
                      items: _getAvailableHousing().map((unit) {
                        return DropdownMenuItem(
                          value: unit.id,
                          child: Text(unit.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedHousingId = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            const Spacer(),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveWorker,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<MasterClass> _getAvailableMasterClasses() {
    final profCapacity = Constants.getProfessionCapacity(selectedProfession, widget.professionCapacities);
    if (profCapacity == null || profCapacity.availableAtNight) {
      return widget.masterClasses; // All classes available
    } else {
      // Only day shift classes available
      return widget.masterClasses
          .where((mc) => mc.shiftType == ShiftType.day)
          .toList();
    }
  }

  List<HousingUnit> _getAvailableHousing() {
    if (selectedMasterClassId == null) return [];
    
    final masterClass = widget.masterClasses.firstWhere(
      (mc) => mc.id == selectedMasterClassId,
      orElse: () => MasterClass(id: '', displayName: '', shiftType: ShiftType.off),
    );
    
    return widget.housingUnits
        .where((unit) => unit.shiftType == masterClass.shiftType)
        .toList();
  }

  void _saveWorker() {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a worker name')),
      );
      return;
    }

    final worker = Worker(
      name: nameController.text.trim(),
      profession: selectedProfession,
      masterClassId: selectedMasterClassId,
      housingId: selectedMasterClassId == null ? null : selectedHousingId,
    );
    
    widget.onSave(worker);
    Navigator.of(context).pop();
  }
} 