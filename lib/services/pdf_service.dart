import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/shift_data.dart';

class PdfService {
  static Future<String?> generateShiftPlannerPdf({
    required List<Worker> workers,
    required List<HousingUnit> housingUnits,
    required List<MasterClass> masterClasses,
    required List<ProfessionCapacity> professionCapacities,
  }) async {
    final pdf = pw.Document();

    // Get profession counts for capacity display
    final professionCounts = _getProfessionCounts(workers, masterClasses);
    final housingOccupancy = _getHousingOccupancy(workers);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text(
                'Weekly Shift Planner',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Shift Grid
            _buildShiftGrid(workers, housingUnits, masterClasses),
            pw.SizedBox(height: 20),

            // Legend
            _buildLegend(),
            pw.SizedBox(height: 20),

            // Profession Capacity
            pw.Text(
              'Profession Capacity',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildProfessionCapacity(professionCapacities, professionCounts),
            pw.SizedBox(height: 20),

            // Housing Capacity
            pw.Text(
              'Housing Capacity',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildHousingCapacity(housingUnits, housingOccupancy),
          ];
        },
      ),
    );

    // Save the PDF to Downloads folder, overwriting the old one
    try {
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/shift_planner.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      // Fallback: use share dialog
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'shift_planner.pdf',
      );
      return null;
    }
  }

  static Future<void> printShiftPlannerPdf({
    required List<Worker> workers,
    required List<HousingUnit> housingUnits,
    required List<MasterClass> masterClasses,
    required List<ProfessionCapacity> professionCapacities,
  }) async {
    final pdf = pw.Document();

    // Get profession counts for capacity display
    final professionCounts = _getProfessionCounts(workers, masterClasses);
    final housingOccupancy = _getHousingOccupancy(workers);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text(
                'Weekly Shift Planner',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Shift Grid
            _buildShiftGrid(workers, housingUnits, masterClasses),
            pw.SizedBox(height: 20),

            // Legend
            _buildLegend(),
            pw.SizedBox(height: 20),

            // Profession Capacity
            pw.Text(
              'Profession Capacity',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildProfessionCapacity(professionCapacities, professionCounts),
            pw.SizedBox(height: 20),

            // Housing Capacity
            pw.Text(
              'Housing Capacity',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildHousingCapacity(housingUnits, housingOccupancy),
          ];
        },
      ),
    );

    // Print the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildShiftGrid(
    List<Worker> workers,
    List<HousingUnit> housingUnits,
    List<MasterClass> masterClasses,
  ) {
    const days = ['Ti', 'Ke', 'To', 'Pe', 'La', 'Su', 'Ma'];
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: const pw.FixedColumnWidth(120), // Worker info column
        1: const pw.FixedColumnWidth(420), // Merged cell spanning all 7 days (60*7)
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Worker',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: days.map((day) => pw.Expanded(
                  child: pw.Text(
                    day,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
        // Worker rows
        ...workers.map((worker) {
          final housing = housingUnits.firstWhere(
            (h) => h.id == worker.housingId,
            orElse: () => HousingUnit(
              id: '',
              displayName: 'No Housing',
              shiftType: ShiftType.off,
              maxCapacity: 0,
            ),
          );
          
          final masterClass = masterClasses.firstWhere(
            (mc) => mc.id == worker.masterClassId,
            orElse: () => MasterClass(
              id: '',
              displayName: '',
              shiftType: ShiftType.off,
            ),
          );

          final shiftCode = _getShiftCode(masterClass.shiftType);
          final cellColor = _getShiftColor(masterClass.shiftType);
          final displayText = _getWorkerDisplayText(worker, masterClass.shiftType, housing);

          return pw.TableRow(
            children: [
              // Worker info - just name now
              pw.Container(
                height: 35,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      worker.name,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ),
              ),
              // Merged cell spanning all 7 days with profession and housing
              pw.Container(
                height: 35,
                decoration: pw.BoxDecoration(color: cellColor),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      displayText,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: masterClass.shiftType == ShiftType.night 
                            ? PdfColors.white 
                            : PdfColors.black,
                        fontSize: 9,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildLegend() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('P', 'Päivä', PdfColors.blue100),
        _buildLegendItem('Y', 'Yö', PdfColors.grey700),
        _buildLegendItem('', 'Vapaa', PdfColors.grey200),
      ],
    );
  }

  static pw.Widget _buildLegendItem(String code, String label, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          width: 30,
          height: 30,
          decoration: pw.BoxDecoration(
            color: color,
            border: pw.Border.all(color: PdfColors.grey),
          ),
          child: pw.Center(
            child: pw.Text(
              code,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: color == PdfColors.grey700 ? PdfColors.white : PdfColors.black,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildProfessionCapacity(
    List<ProfessionCapacity> professionCapacities,
    Map<String, Map<String, int>> counts,
  ) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: professionCapacities.map((profCap) {
        final dayCount = counts[profCap.profession]?['day'] ?? 0;
        final nightCount = counts[profCap.profession]?['night'] ?? 0;
        
        final isDayUnlimited = profCap.maxDayCapacity < 0;
        final isNightUnlimited = profCap.maxNightCapacity < 0;
        
        final isDayOver = !isDayUnlimited && dayCount > profCap.maxDayCapacity;
        final isNightOver = !isNightUnlimited && nightCount > profCap.maxNightCapacity;
        
        final dayNeedsPopulation = dayCount == 0 && profCap.maxDayCapacity > 0;
        final nightNeedsPopulation = profCap.availableAtNight && nightCount == 0 && profCap.maxNightCapacity > 0;
        
        PdfColor backgroundColor;
        if (dayNeedsPopulation || nightNeedsPopulation) {
          backgroundColor = PdfColors.orange100;
        } else if (isDayOver || isNightOver) {
          backgroundColor = PdfColors.red100;
        } else {
          backgroundColor = PdfColors.green50;
        }
        
        return pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: backgroundColor,
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                profCap.profession,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              pw.Text(
                'D: ${isDayUnlimited ? '$dayCount/inf' : '$dayCount/${profCap.maxDayCapacity}'}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              if (profCap.availableAtNight)
                pw.Text(
                  'N: ${isNightUnlimited ? '$nightCount/inf' : '$nightCount/${profCap.maxNightCapacity}'}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildHousingCapacity(
    List<HousingUnit> housingUnits,
    Map<String, int> occupancy,
  ) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: housingUnits.map((unit) {
        final current = occupancy[unit.id] ?? 0;
        final isOver = current > unit.maxCapacity;
        
        return pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: isOver ? PdfColors.red100 : PdfColors.blue50,
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                unit.displayName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              pw.Text(
                unit.shiftType.displayName,
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                '$current/${unit.maxCapacity}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static String _getShiftCode(ShiftType shiftType) {
    switch (shiftType) {
      case ShiftType.day:
        return 'P';
      case ShiftType.night:
        return 'Y';
      case ShiftType.off:
        return '';
    }
  }

  static PdfColor _getShiftColor(ShiftType shiftType) {
    switch (shiftType) {
      case ShiftType.day:
        return PdfColors.blue100;
      case ShiftType.night:
        return PdfColors.grey700;
      case ShiftType.off:
        return PdfColors.grey200;
    }
  }

  static Map<String, Map<String, int>> _getProfessionCounts(
    List<Worker> workers,
    List<MasterClass> masterClasses,
  ) {
    Map<String, Map<String, int>> counts = {};
    
    for (var worker in workers) {
      if (worker.masterClassId != null) {
        final masterClass = masterClasses.firstWhere(
          (mc) => mc.id == worker.masterClassId,
          orElse: () => MasterClass(id: '', displayName: '', shiftType: ShiftType.off),
        );
        final shiftKey = masterClass.shiftType == ShiftType.day ? 'day' : 'night';
        
        if (counts[worker.profession] == null) {
          counts[worker.profession] = {'day': 0, 'night': 0};
        }
        counts[worker.profession]![shiftKey] = (counts[worker.profession]![shiftKey] ?? 0) + 1;
      }
    }
    return counts;
  }

  static Map<String, int> _getHousingOccupancy(List<Worker> workers) {
    Map<String, int> occupancy = {};
    for (var worker in workers) {
      if (worker.housingId != null) {
        occupancy[worker.housingId!] = (occupancy[worker.housingId!] ?? 0) + 1;
      }
    }
    return occupancy;
  }

  static String _getWorkerDisplayText(Worker worker, ShiftType shiftType, HousingUnit housing) {
    if (worker.masterClassId == null) {
      return '';
    } else if (worker.housingId != null) {
      return '${worker.profession}\n${shiftType.displayName} - ${housing.displayName}';
    } else {
      return '${worker.profession}\n${shiftType.displayName} - Class ${worker.masterClassId}';
    }
  }
} 