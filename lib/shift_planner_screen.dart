import 'package:flutter/material.dart';
import 'models/shift_data.dart';
import 'widgets/shift_grid.dart';
import 'widgets/worker_editor.dart';
import 'services/pdf_service.dart';

class ShiftPlannerScreen extends StatefulWidget {
  const ShiftPlannerScreen({super.key});

  @override
  State<ShiftPlannerScreen> createState() => _ShiftPlannerScreenState();
}

class _ShiftPlannerScreenState extends State<ShiftPlannerScreen> {
  List<Worker> workers = [];
  List<HousingUnit> housingUnits = [];
  List<MasterClass> masterClasses = [];
  List<ProfessionCapacity> professionCapacities = [];

  @override
  void initState() {
    super.initState();
    housingUnits = Constants.getDefaultHousingUnits();
    masterClasses = Constants.getDefaultMasterClasses();
    professionCapacities = Constants.getDefaultProfessionCapacities();
    _initializeExampleData();
  }

  void _initializeExampleData() {
    // Create example workers with different master class assignments
    workers = [
      Worker(
        name: 'Mika Kumpulainen',
        profession: 'Työnjohtaja',
        masterClassId: 'A',
        housingId: 'eta-a-day',
      ),
      Worker(
        name: 'Eetu Savunen',
        profession: 'Pasta 1',
        masterClassId: 'B',
        housingId: 'eta-a-night',
      ),
      Worker(
        name: 'Tomi Peltoniemi',
        profession: 'Huoltomies',
        masterClassId: 'A',  // Huoltomies only works day shifts
        housingId: 'eta-a-day',
      ),
    ];
    _sortWorkers();
  }

  void _sortWorkers() {
    workers.sort((a, b) {
      // First sort by shift type (day vs night)
      final shiftTypeA = _getWorkerShiftType(a);
      final shiftTypeB = _getWorkerShiftType(b);
      final shiftComparison = shiftTypeA.index.compareTo(shiftTypeB.index);
      
      if (shiftComparison != 0) return shiftComparison;
      
      // Then sort by profession order from profession capacities
      final professionOrder = <String, int>{};
      for (int i = 0; i < professionCapacities.length; i++) {
        professionOrder[professionCapacities[i].profession] = i;
      }
      
      final orderA = professionOrder[a.profession] ?? 999;
      final orderB = professionOrder[b.profession] ?? 999;
      
      return orderA.compareTo(orderB);
    });
  }

  ShiftType _getWorkerShiftType(Worker worker) {
    if (worker.masterClassId == null) return ShiftType.off;
    final masterClass = masterClasses.firstWhere(
      (mc) => mc.id == worker.masterClassId,
      orElse: () => MasterClass(id: '', displayName: '', shiftType: ShiftType.off),
    );
    return masterClass.shiftType;
  }

  Map<String, Map<String, int>> _getProfessionCounts() {
    Map<String, Map<String, int>> counts = {};
    
    for (var worker in workers) {
      if (worker.masterClassId != null) {
        final shiftType = _getWorkerShiftType(worker);
        final shiftKey = shiftType == ShiftType.day ? 'day' : 'night';
        
        if (counts[worker.profession] == null) {
          counts[worker.profession] = {'day': 0, 'night': 0};
        }
        counts[worker.profession]![shiftKey] = (counts[worker.profession]![shiftKey] ?? 0) + 1;
      }
    }
    return counts;
  }



  void _addWorker() {
    showDialog(
      context: context,
      builder: (context) => WorkerEditorDialog(
        housingUnits: housingUnits,
        masterClasses: masterClasses,
        professionCapacities: professionCapacities,
        availableProfessions: professionCapacities.map((p) => p.profession).toList(),
        onSave: (worker) {
          setState(() {
            workers.add(worker);
            _sortWorkers();
          });
        },
      ),
    );
  }

  void _editWorker(int index) {
    showDialog(
      context: context,
      builder: (context) => WorkerEditorDialog(
        worker: workers[index],
        housingUnits: housingUnits,
        masterClasses: masterClasses,
        professionCapacities: professionCapacities,
        availableProfessions: professionCapacities.map((p) => p.profession).toList(),
        onSave: (worker) {
          setState(() {
            workers[index] = worker;
            _sortWorkers();
          });
        },
      ),
    );
  }

  void _deleteWorker(int index) {
    setState(() {
      workers.removeAt(index);
    });
  }

  void _showAddWorkerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Worker',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Custom Name'),
              subtitle: const Text('Enter a custom name'),
              onTap: () {
                Navigator.pop(context);
                _addWorker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('From Name Database'),
              subtitle: const Text('Choose from predefined names'),
              onTap: () {
                Navigator.pop(context);
                _showNamePicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNamePicker() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Select Name',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: Constants.peopleNames.length,
                  itemBuilder: (context, index) {
                    final name = Constants.peopleNames[index];
                    return ListTile(
                      title: Text(name),
                      onTap: () {
                        Navigator.pop(context);
                        _addWorkerWithName(name);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addWorkerWithName(String name) {
    showDialog(
      context: context,
      builder: (context) => WorkerEditorDialog(
        presetName: name,
        housingUnits: housingUnits,
        masterClasses: masterClasses,
        professionCapacities: professionCapacities,
        availableProfessions: professionCapacities.map((p) => p.profession).toList(),
        onSave: (worker) {
          setState(() {
            workers.add(worker);
            _sortWorkers();
          });
        },
      ),
    );
  }

  void _manageProfessionCapacities() {
    showDialog(
      context: context,
      builder: (context) => _ProfessionCapacityDialog(
        professionCapacities: professionCapacities,
        onSave: (capacities) {
          setState(() {
            professionCapacities = capacities;
          });
        },
      ),
    );
  }

  void _manageMasterClasses() {
    showDialog(
      context: context,
      builder: (context) => _MasterClassDialog(
        masterClasses: masterClasses,
        onSave: (classes) {
          setState(() {
            masterClasses = classes;
          });
        },
      ),
    );
  }

  void _manageHousingCapacity() {
    showDialog(
      context: context,
      builder: (context) => _HousingCapacityDialog(
        housingUnits: housingUnits,
        onSave: (units) {
          setState(() {
            housingUnits = units;
          });
        },
      ),
    );
  }

  Map<String, int> _getHousingOccupancy() {
    Map<String, int> occupancy = {};
    for (var worker in workers) {
      if (worker.housingId != null) {
        occupancy[worker.housingId!] = (occupancy[worker.housingId!] ?? 0) + 1;
      }
    }
    return occupancy;
  }

  Future<void> _exportToPdf() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export PDF'),
        content: const Text('Choose how you want to export the shift planner:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final filePath = await PdfService.generateShiftPlannerPdf(
                  workers: workers,
                  housingUnits: housingUnits,
                  masterClasses: masterClasses,
                  professionCapacities: professionCapacities,
                );
                if (mounted) {
                  if (filePath != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PDF saved successfully!\nLocation: $filePath'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDF shared successfully!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving PDF: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Save/Download'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await PdfService.printShiftPlannerPdf(
                  workers: workers,
                  housingUnits: housingUnits,
                  masterClasses: masterClasses,
                  professionCapacities: professionCapacities,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error printing PDF: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Shift Planner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.work),
            onPressed: _manageProfessionCapacities,
            tooltip: 'Manage Profession Capacities',
          ),
          IconButton(
            icon: const Icon(Icons.class_),
            onPressed: _manageMasterClasses,
            tooltip: 'Manage Master Classes',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _manageHousingCapacity,
            tooltip: 'Manage Housing',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWorkerMenu,
            tooltip: 'Add Worker',
          ),
        ],
      ),
      body: workers.isEmpty
          ? const Center(
              child: Text(
                'No workers added yet.\nTap + to add a worker.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ShiftGrid(
                    workers: workers,
                    housingUnits: housingUnits,
                    masterClasses: masterClasses,
                    onEditWorker: _editWorker,
                    onDeleteWorker: _deleteWorker,
                  ),
                ),
                // Profession capacity display
                Container(
                  constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Profession Capacity',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: _buildProfessionCapacity(),
                      ),
                    ],
                  ),
                ),
                // Housing capacity display
                Container(
                  constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Housing Capacity',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: _buildHousingCapacity(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem('P', 'Päivä', Colors.blue.shade100),
                        _buildLegendItem('Y', 'Yö', Colors.grey.shade700),
                        _buildLegendItem('', 'Vapaa', Colors.grey.shade200),
                      ],
                    ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWorkerMenu,
        tooltip: 'Add Worker',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLegendItem(String code, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
          ),
          child: Center(
            child: Text(
              code,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color == Colors.grey.shade700 ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProfessionCapacity() {
    final counts = _getProfessionCounts();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: professionCapacities.map((profCap) {
          final dayCount = counts[profCap.profession]?['day'] ?? 0;
          final nightCount = counts[profCap.profession]?['night'] ?? 0;
          
          final isDayUnlimited = profCap.maxDayCapacity < 0;
          final isNightUnlimited = profCap.maxNightCapacity < 0;
          
          final isDayOver = !isDayUnlimited && dayCount > profCap.maxDayCapacity;
          final isNightOver = !isNightUnlimited && nightCount > profCap.maxNightCapacity;
          
          final dayNeedsPopulation = dayCount == 0 && profCap.maxDayCapacity > 0;
          final nightNeedsPopulation = profCap.availableAtNight && nightCount == 0 && profCap.maxNightCapacity > 0;
          
          Color backgroundColor;
          Color borderColor;
          if (dayNeedsPopulation || nightNeedsPopulation) {
            backgroundColor = Colors.orange.shade100;
            borderColor = Colors.orange;
          } else if (isDayOver || isNightOver) {
            backgroundColor = Colors.red.shade100;
            borderColor = Colors.red;
          } else {
            backgroundColor = Colors.green.shade50;
            borderColor = Colors.green;
          }
          
          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profCap.profession,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Day count
                Text(
                  'D: ${isDayUnlimited ? '$dayCount/inf' : '$dayCount/${profCap.maxDayCapacity}'}',
                  style: TextStyle(
                    fontSize: 8,
                    color: dayNeedsPopulation || isDayOver ? 
                      (dayNeedsPopulation ? Colors.orange.shade800 : Colors.red) : 
                      Colors.black,
                  ),
                ),
                // Night count (if available)
                if (profCap.availableAtNight)
                  Text(
                    'N: ${isNightUnlimited ? '$nightCount/inf' : '$nightCount/${profCap.maxNightCapacity}'}',
                    style: TextStyle(
                      fontSize: 8,
                      color: nightNeedsPopulation || isNightOver ? 
                        (nightNeedsPopulation ? Colors.orange.shade800 : Colors.red) : 
                        Colors.black,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHousingCapacity() {
    final occupancy = _getHousingOccupancy();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: housingUnits.map((unit) {
          final current = occupancy[unit.id] ?? 0;
          final isOver = current > unit.maxCapacity;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isOver ? Colors.red.shade100 : Colors.blue.shade50,
              border: Border.all(
                color: isOver ? Colors.red : Colors.blue,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  unit.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  unit.shiftType.displayName,
                  style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  '$current/${unit.maxCapacity}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOver ? Colors.red : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HousingCapacityDialog extends StatefulWidget {
  final List<HousingUnit> housingUnits;
  final Function(List<HousingUnit>) onSave;

  const _HousingCapacityDialog({
    required this.housingUnits,
    required this.onSave,
  });

  @override
  State<_HousingCapacityDialog> createState() => _HousingCapacityDialogState();
}

class _HousingCapacityDialogState extends State<_HousingCapacityDialog> {
  late List<HousingUnit> units;

  @override
  void initState() {
    super.initState();
    units = widget.housingUnits.map((unit) => HousingUnit(
      id: unit.id,
      displayName: unit.displayName,
      shiftType: unit.shiftType,
      maxCapacity: unit.maxCapacity,
    )).toList();
  }

  void _addNewHousing() {
    showDialog(
      context: context,
      builder: (context) {
        String newHousingName = '';
        ShiftType selectedShiftType = ShiftType.day;
        int maxCapacity = 4;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Housing Unit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Housing Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => newHousingName = value,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ShiftType>(
                    value: selectedShiftType,
                    decoration: const InputDecoration(
                      labelText: 'Shift Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [ShiftType.day, ShiftType.night].map((shiftType) {
                      return DropdownMenuItem(
                        value: shiftType,
                        child: Text(shiftType.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedShiftType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Max Capacity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      if (intValue != null && intValue > 0) {
                        maxCapacity = intValue;
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (newHousingName.trim().isNotEmpty) {
                      setState(() {
                        final newId = '${newHousingName.toLowerCase().replaceAll(' ', '_')}_${selectedShiftType.name}';
                        units.add(HousingUnit(
                          id: newId,
                          displayName: newHousingName.trim(),
                          shiftType: selectedShiftType,
                          maxCapacity: maxCapacity,
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteHousing(int index) {
    setState(() {
      units.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Housing Capacity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addNewHousing,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Housing'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  unit.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  unit.shiftType.displayName,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: unit.maxCapacity.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              onChanged: (value) {
                                final intValue = int.tryParse(value);
                                if (intValue != null && intValue > 0) {
                                  unit.maxCapacity = intValue;
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteHousing(index),
                            tooltip: 'Delete Housing',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onSave(units);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterClassDialog extends StatefulWidget {
  final List<MasterClass> masterClasses;
  final Function(List<MasterClass>) onSave;

  const _MasterClassDialog({
    required this.masterClasses,
    required this.onSave,
  });

  @override
  State<_MasterClassDialog> createState() => _MasterClassDialogState();
}

class _MasterClassDialogState extends State<_MasterClassDialog> {
  late List<MasterClass> classes;

  @override
  void initState() {
    super.initState();
    classes = widget.masterClasses.map((mc) => MasterClass(
      id: mc.id,
      displayName: mc.displayName,
      shiftType: mc.shiftType,
    )).toList();
  }

  void _toggleShiftType(String classId) {
    setState(() {
      final classIndex = classes.indexWhere((mc) => mc.id == classId);
      if (classIndex >= 0) {
        final currentClass = classes[classIndex];
        final newShiftType = currentClass.shiftType == ShiftType.day 
            ? ShiftType.night 
            : ShiftType.day;
        
        // Ensure only one class in each pair (A/B or C/D) can be night
        if (newShiftType == ShiftType.night) {
          if (classId == 'A' || classId == 'B') {
            // If setting A or B to night, set the other to day
            final otherClassId = classId == 'A' ? 'B' : 'A';
            final otherIndex = classes.indexWhere((mc) => mc.id == otherClassId);
            if (otherIndex >= 0) {
              classes[otherIndex].shiftType = ShiftType.day;
            }
          } else if (classId == 'C' || classId == 'D') {
            // If setting C or D to night, set the other to day
            final otherClassId = classId == 'C' ? 'D' : 'C';
            final otherIndex = classes.indexWhere((mc) => mc.id == otherClassId);
            if (otherIndex >= 0) {
              classes[otherIndex].shiftType = ShiftType.day;
            }
          }
        }
        
        classes[classIndex].shiftType = newShiftType;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 350,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Master Class Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'A/B pair and C/D pair. Only one in each pair can be night shift.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildClassCard('A')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildClassCard('B')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildClassCard('C')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildClassCard('D')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onSave(classes);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(String classId) {
    final masterClass = classes.firstWhere((mc) => mc.id == classId);
    final isNight = masterClass.shiftType == ShiftType.night;
    
    return GestureDetector(
      onTap: () => _toggleShiftType(classId),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isNight ? Colors.grey.shade700 : Colors.blue.shade100,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Class $classId',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isNight ? Colors.white : Colors.black,
              ),
            ),
            Text(
              masterClass.shiftType.displayName,
              style: TextStyle(
                fontSize: 14,
                color: isNight ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessionCapacityDialog extends StatefulWidget {
  final List<ProfessionCapacity> professionCapacities;
  final Function(List<ProfessionCapacity>) onSave;

  const _ProfessionCapacityDialog({
    required this.professionCapacities,
    required this.onSave,
  });

  @override
  State<_ProfessionCapacityDialog> createState() => _ProfessionCapacityDialogState();
}

class _ProfessionCapacityDialogState extends State<_ProfessionCapacityDialog> {
  late List<ProfessionCapacity> capacities;

  @override
  void initState() {
    super.initState();
    capacities = widget.professionCapacities.map((cap) => ProfessionCapacity(
      profession: cap.profession,
      maxDayCapacity: cap.maxDayCapacity,
      maxNightCapacity: cap.maxNightCapacity,
      availableAtNight: cap.availableAtNight,
    )).toList();
  }

  void _addNewProfession() {
    showDialog(
      context: context,
      builder: (context) {
        String newProfessionName = '';
        return AlertDialog(
          title: const Text('Add New Profession'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Profession Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => newProfessionName = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newProfessionName.trim().isNotEmpty) {
                  setState(() {
                    capacities.add(ProfessionCapacity(
                      profession: newProfessionName.trim(),
                      maxDayCapacity: 2,
                      maxNightCapacity: 2,
                      availableAtNight: true,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteProfession(int index) {
    setState(() {
      capacities.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Profession Capacities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addNewProfession,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Profession'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: capacities.length,
                itemBuilder: (context, index) {
                  final capacity = capacities[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                capacity.profession,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteProfession(index),
                                tooltip: 'Delete Profession',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Day Capacity', style: TextStyle(fontSize: 12)),
                                    TextFormField(
                                      initialValue: capacity.maxDayCapacity < 0 ? '∞' : capacity.maxDayCapacity.toString(),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      onChanged: (value) {
                                        if (value == '∞' || value.toLowerCase() == 'inf') {
                                          capacity.maxDayCapacity = -1;
                                        } else {
                                          final intValue = int.tryParse(value);
                                          if (intValue != null && intValue >= 0) {
                                            capacity.maxDayCapacity = intValue;
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Night Capacity', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 8),
                                        Checkbox(
                                          value: capacity.availableAtNight,
                                          onChanged: (value) {
                                            setState(() {
                                              capacity.availableAtNight = value ?? false;
                                              if (!capacity.availableAtNight) {
                                                capacity.maxNightCapacity = 0;
                                              }
                                            });
                                          },
                                        ),
                                        const Text('Available', style: TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                    TextFormField(
                                      initialValue: capacity.maxNightCapacity < 0 ? '∞' : capacity.maxNightCapacity.toString(),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      onChanged: (value) {
                                        if (value == '∞' || value.toLowerCase() == 'inf') {
                                          capacity.maxNightCapacity = -1;
                                        } else {
                                          final intValue = int.tryParse(value);
                                          if (intValue != null && intValue >= 0) {
                                            capacity.maxNightCapacity = intValue;
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onSave(capacities);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 