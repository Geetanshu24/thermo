import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  runApp(const ThermographyApp());
}

class ThermographyApp extends StatelessWidget {
  const ThermographyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thermography Analysis Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B3A4),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1423),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF111E32),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3558)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3558)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00B3A4), width: 1.5),
          ),
        ),
      ),
      home: const ThermographyHome(),
    );
  }
}

class ThermographyHome extends StatefulWidget {
  const ThermographyHome({super.key});

  @override
  State<ThermographyHome> createState() => _ThermographyHomeState();
}

class _ThermographyHomeState extends State<ThermographyHome> {
  // Images
  Uint8List? thermalBytes;
  Uint8List? referenceBytes;

  // Controllers
  final recordNoCtrl = TextEditingController(text: 'FLIR1000033');
  final equipmentIdCtrl = TextEditingController(text: 'TG267');
  final locationCtrl = TextEditingController(text: 'Main panel');
  final sectionCtrl = TextEditingController(text: 'Main Incomer');

  final maxTempCtrl = TextEditingController(text: '20.6');
  final refPointTempCtrl = TextEditingController(text: '20.6');

  final inspectorCtrl = TextEditingController(text: 'Admin');
  final commentsCtrl = TextEditingController(
    text:
    'Thermal profile appears normal. The recorded temperature is within the expected ambient range. '
        'No thermal anomalies or hot spots were detected at the time of inspection. '
        'Continue with routine scheduled monitoring.',
  );

  // Status
  bool isInitial = true;

  // Loading
  bool generating = false;

  @override
  void dispose() {
    recordNoCtrl.dispose();
    equipmentIdCtrl.dispose();
    locationCtrl.dispose();
    sectionCtrl.dispose();
    maxTempCtrl.dispose();
    refPointTempCtrl.dispose();
    inspectorCtrl.dispose();
    commentsCtrl.dispose();
    super.dispose();
  }

  Future<void> pickThermalImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res?.files.isEmpty ?? true) return;
    final file = res!.files.first;
    if (file.bytes == null) return;
    setState(() => thermalBytes = file.bytes);
  }

  Future<void> pickReferenceImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res?.files.isEmpty ?? true) return;
    final file = res!.files.first;
    if (file.bytes == null) return;
    setState(() => referenceBytes = file.bytes);
  }

  Future<void> generatePdfReport() async {
    if (thermalBytes == null || referenceBytes == null) {
      _snack('Please upload both Thermal & Reference images.');
      return;
    }

    setState(() => generating = true);
    try {
      final pdf = pw.Document();

      final thermalImg = pw.MemoryImage(thermalBytes!);
      final refImg = pw.MemoryImage(referenceBytes!);

      final today = DateTime.now();
      final dateStr = '${today.month}/${today.day}/${today.year}';

      final statusText = isInitial ? 'Initial' : 'Follow-up';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (context) {
            return pw.Container(
              color: PdfColor.fromInt(0xFF0B0B0B),
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Top table header strip
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.white),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1.2),
                        1: const pw.FlexColumnWidth(1.6),
                        2: const pw.FlexColumnWidth(1.4),
                        3: const pw.FlexColumnWidth(2),
                      },
                      children: [
                        _pdfRow4(
                          'Rec. No.',
                          'Equipment ID',
                          'Initial/Follow-up',
                          'Recommendation Status',
                          bold: true,
                        ),
                        _pdfRow4(
                          recordNoCtrl.text.trim(),
                          'Flir${equipmentIdCtrl.text.trim()}',
                          statusText,
                          'Open',
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 10),

                    // Middle area: images + details
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left images column
                        pw.Expanded(
                          flex: 3,
                          child: pw.Column(
                            children: [
                              pw.Container(
                                height: 250,
                                width: double.infinity,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.white),
                                ),
                                child: pw.FittedBox(
                                  fit: pw.BoxFit.contain,
                                  child: pw.Image(thermalImg),
                                ),
                              ),
                              pw.SizedBox(height: 10),
                              pw.Container(
                                height: 250,
                                width: double.infinity,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.white),
                                ),
                                child: pw.FittedBox(
                                  fit: pw.BoxFit.contain,
                                  child: pw.Image(refImg),
                                ),
                              ),
                            ],
                          ),
                        ),

                        pw.SizedBox(width: 10),

                        // Right detail tables
                        pw.Expanded(
                          flex: 2,
                          child: pw.Column(
                            children: [
                              pw.Table(
                                border: pw.TableBorder.all(color: PdfColors.white),
                                columnWidths: {
                                  0: const pw.FlexColumnWidth(1.2),
                                  1: const pw.FlexColumnWidth(1.4),
                                },
                                children: [
                                  _pdfRow2('Location :', locationCtrl.text.trim()),
                                  _pdfRow2('Section :', sectionCtrl.text.trim()),
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              pw.Table(
                                border: pw.TableBorder.all(color: PdfColors.white),
                                columnWidths: {
                                  0: const pw.FlexColumnWidth(1.6),
                                  1: const pw.FlexColumnWidth(1.0),
                                },
                                children: [
                                  _pdfRow2(
                                    'Reference Point',
                                    '${refPointTempCtrl.text.trim()}°C',
                                    centerRight: true,
                                  ),
                                  _pdfRow2(
                                    'Max Temp',
                                    '${maxTempCtrl.text.trim()}°C',
                                    centerRight: true,
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              pw.Container(
                                width: double.infinity,
                                padding: const pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.white),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Inspection Details',
                                        style: pw.TextStyle(
                                          color: PdfColors.white,
                                          fontWeight: pw.FontWeight.bold,
                                        )),
                                    pw.SizedBox(height: 6),
                                    pw.Text('Date: $dateStr',
                                        style: const pw.TextStyle(color: PdfColors.white)),
                                    pw.Text('Inspector: ${inspectorCtrl.text.trim()}',
                                        style: const pw.TextStyle(color: PdfColors.white)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 14),

                    // Comments
                    pw.Text(
                      'Comments :',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      commentsCtrl.text.trim(),
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Save dialog (Windows)
      final suggestedName =
          'Thermal_Report_${equipmentIdCtrl.text.trim()}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report PDF',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (savePath == null) {
        _snack('Save cancelled.');
        return;
      }

      final file = File(savePath);
      await file.writeAsBytes(await pdf.save());

      // Auto-open
      await OpenFilex.open(file.path);

      _snack('Report generated & opened successfully ✅');
    } catch (e) {
      _snack('Failed to generate PDF: $e');
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.thermostat, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Thermography Analysis Pro',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
                  const SizedBox(width: 6),
                  const Text('Admin', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),

              const SizedBox(height: 12),

              // Main content
              Expanded(
                child: Row(
                  children: [
                    // Left: upload panels (2)
                    Expanded(
                      flex: 6,
                      child: Row(
                        children: [
                          Expanded(
                            child: _UploadCard(
                              title: 'Thermal Image',
                              bytes: thermalBytes,
                              primary: true,
                              onPick: pickThermalImage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _UploadCard(
                              title: 'Reference/Normal Image',
                              bytes: referenceBytes,
                              primary: false,
                              onPick: pickReferenceImage,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: side panel
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1B2E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E3558)),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('RECORD ID',
                                  style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: 1,
                                      color: Colors.white70)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: recordNoCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Auto-populated from filename',
                                ),
                              ),
                              const SizedBox(height: 12),

                              const Text('EQUIPMENT ID',
                                  style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: 1,
                                      color: Colors.white70)),
                              const SizedBox(height: 6),
                              TextField(controller: equipmentIdCtrl),

                              const SizedBox(height: 12),

                              const Text('STATUS',
                                  style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: 1,
                                      color: Colors.white70)),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Expanded(
                                    child: _StatusButton(
                                      selected: isInitial,
                                      text: 'Initial',
                                      onTap: () => setState(() => isInitial = true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _StatusButton(
                                      selected: !isInitial,
                                      text: 'Follow-up',
                                      onTap: () => setState(() => isInitial = false),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Temps
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: cs.primary),
                                  color: const Color(0xFF111E32),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.local_fire_department, color: cs.primary),
                                    const SizedBox(width: 8),
                                    const Text('MAX TEMPERATURE',
                                        style: TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: maxTempCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Max Temp (°C)',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: refPointTempCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Ref Point (°C)',
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: locationCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Location',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: sectionCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Section',
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              TextField(
                                controller: inspectorCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Inspector',
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextField(
                                controller: commentsCtrl,
                                minLines: 4,
                                maxLines: 8,
                                decoration: const InputDecoration(
                                  labelText: 'Comments',
                                ),
                              ),

                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: generating ? null : generatePdfReport,
                                  icon: generating
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : const Icon(Icons.picture_as_pdf),
                                  label: Text(
                                    generating ? 'Generating...' : 'Generate Report',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Bottom hint bar
              Container(
                height: 44,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1B2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E3558)),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  (thermalBytes == null || referenceBytes == null)
                      ? 'Upload thermal & reference image to continue'
                      : 'Ready to generate report ✅',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ UI Components ------------------

class _UploadCard extends StatelessWidget {
  final String title;
  final Uint8List? bytes;
  final bool primary;
  final VoidCallback onPick;

  const _UploadCard({
    required this.title,
    required this.bytes,
    required this.primary,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary ? cs.primary : const Color(0xFF1E3558),
          width: primary ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          Expanded(
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primary ? cs.primary : const Color(0xFF1E3558),
                    style: BorderStyle.solid,
                  ),
                ),
                child: bytes == null
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload,
                          size: 34,
                          color: primary ? cs.primary : Colors.white54),
                      const SizedBox(height: 10),
                      const Text('Drop image here',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      const Text('or click to browse',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    bytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final bool selected;
  final String text;
  final VoidCallback onTap;

  const _StatusButton({
    required this.selected,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? cs.primary : const Color(0xFF1E3558)),
          color: selected ? cs.primary : const Color(0xFF111E32),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }
}

// ------------------ PDF Helpers ------------------

pw.TableRow _pdfRow4(String a, String b, String c, String d, {bool bold = false}) {
  final style = pw.TextStyle(
    color: PdfColors.white,
    fontSize: 10,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );

  pw.Widget cell(String t) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(t, style: style),
  );

  return pw.TableRow(children: [cell(a), cell(b), cell(c), cell(d)]);
}

pw.TableRow _pdfRow2(String left, String right, {bool centerRight = false}) {
  final leftStyle = pw.TextStyle(
    color: PdfColors.white,
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
  );
  final rightStyle = const pw.TextStyle(
    color: PdfColors.white,
    fontSize: 10,
  );

  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(left, style: leftStyle),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Align(
          alignment: centerRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          child: pw.Text(right, style: rightStyle),
        ),
      ),
    ],
  );
}
