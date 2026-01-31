import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

import 'package:vipul/crop_page.dart';
import 'package:vipul/status_button.dart';
import 'package:vipul/upload_card.dart';

class ThermographyHome extends StatefulWidget {
  const ThermographyHome({super.key});

  @override
  State<ThermographyHome> createState() => _ThermographyHomeState();
}

class _ThermographyHomeState extends State<ThermographyHome> {
  Uint8List? thermalBytes;
  Uint8List? referenceBytes;

  final recordNoCtrl = TextEditingController(text: 'FLIR1000033');
  final equipmentIdCtrl = TextEditingController(text: 'TG267');
  final locationCtrl = TextEditingController(text: '');
  final sectionCtrl = TextEditingController(text: '');

  final maxTempCtrl = TextEditingController(text: '');
  final refPointTempCtrl = TextEditingController(text: '');
  final deltaTempCtrl = TextEditingController();
  final emissivityCtrl = TextEditingController(text: "0.95");

  final commentsCtrl = TextEditingController(
    text:
    'Thermal profile appears normal. The recorded temperature is within the expected ambient range. '
        'No thermal anomalies or hot spots were detected at the time of inspection. '
        'Continue with routine scheduled monitoring.',
  );

  bool isInitial = true;
  bool generating = false;

  @override
  void initState() {
    super.initState();

    maxTempCtrl.addListener(calculateDelta);
    refPointTempCtrl.addListener(calculateDelta);

    calculateDelta();
  }


  @override
  void dispose() {
    recordNoCtrl.dispose();
    equipmentIdCtrl.dispose();
    emissivityCtrl.dispose();
    locationCtrl.dispose();
    sectionCtrl.dispose();
    maxTempCtrl.dispose();
    refPointTempCtrl.dispose();
    commentsCtrl.dispose();
    super.dispose();
  }


  void calculateDelta() {
    final max = double.tryParse(maxTempCtrl.text) ?? 0;
    final ref = double.tryParse(refPointTempCtrl.text) ?? 0;

    final delta = max - ref;

    deltaTempCtrl.text = delta.toStringAsFixed(2);
  }

  Future<void> pickThermalImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    final bytes = await File(result.files.single.path!).readAsBytes();

    final cropped = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CropPage(imageBytes: bytes),
      ),
    );

    if (cropped != null) {
      setState(() {
        thermalBytes = cropped;
      });
    }
  }


  Future<void> pickReferenceImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result == null) return;

    final bytes = await File(result.files.single.path!).readAsBytes();

    final cropped = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CropPage(imageBytes: bytes),
      ),
    );

    if (cropped != null) {
      setState(() {
        referenceBytes = cropped;
      });
    }
  }
  Future<void> generatePdfReport() async {
    if (thermalBytes == null) {
      _snack('Please upload thermal image.');
      return;
    }

    setState(() => generating = true);

    try {
      final font = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      final ttf = pw.Font.ttf(font);

      final pdf = pw.Document();

      final thermalImg = pw.MemoryImage(thermalBytes!);
      final refImg =
      referenceBytes != null ? pw.MemoryImage(referenceBytes!) : null;

      final statusText = isInitial ? 'Initial' : 'Follow-up';

      pdf.addPage(
        pw.Page(
          theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [

                  /// ================= HEADER =================
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      _pdfRow4(
                          'Rec. No.', 'Equipment ID', 'Status', 'Emissivity',
                          bold: true),
                      _pdfRow4(recordNoCtrl.text, 'Flir${equipmentIdCtrl.text}',
                          statusText, emissivityCtrl.text),
                    ],
                  ),

                  pw.SizedBox(height: 20),

                  /// ================= THERMAL + RIGHT PANEL =================
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [

                      pw.Expanded(
                        flex: 3,
                        child: pw.Container(
                          width: 330,
                          height: 250,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.black),
                          ),
                          child: pw.FittedBox(
                            fit: pw.BoxFit.contain,
                            child: pw.Image(thermalImg),
                          ),
                        ),
                      ),

                      pw.SizedBox(width: 10),

                      /// Right panel
                      pw.SizedBox(
                        width: 200,
                        child: pw.Column(
                          children: [

                            /// Location + Section
                            pw.Table(
                              border: pw.TableBorder.all(),
                              columnWidths: {
                                0: const pw.FixedColumnWidth(80),
                                1: const pw.FlexColumnWidth(),
                              },
                              children: [
                                _pdfRow2('Location', locationCtrl.text),
                                _pdfRow2('Section', sectionCtrl.text),
                              ],
                            ),

                            /// 👉 Temps ALSO here if reference image NOT present
                            if (refImg == null) ...[
                              pw.SizedBox(height: 12),
                              pw.Table(
                                border: pw.TableBorder.all(),
                                children: [
                                  _pdfRow2(
                                      'Reference Temp',
                                      '${refPointTempCtrl.text}°C',
                                      centerRight: true),
                                  _pdfRow2(
                                      'Max Temp',
                                      '${maxTempCtrl.text}°C',
                                      centerRight: true),
                                  _pdfRow2(
                                      'ΔT',
                                      '${deltaTempCtrl.text}°C',
                                      centerRight: true),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  /// ================= REFERENCE BLOCK (ONLY IF EXISTS) =================
                  if (refImg != null) ...[
                    pw.SizedBox(height: 20),

                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Container(
                            width: 330,
                            height: 250,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.black),
                            ),
                            child: pw.FittedBox(
                              fit: pw.BoxFit.contain,
                              child: pw.Image(refImg),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.SizedBox(
                          width: 200,
                          child: pw.Table(
                            border: pw.TableBorder.all(),
                            children: [
                              _pdfRow2(
                                  'Reference Temp',
                                  '${refPointTempCtrl.text}°C',
                                  centerRight: true),
                              _pdfRow2(
                                  'Max Temp',
                                  '${maxTempCtrl.text}°C',
                                  centerRight: true),
                              _pdfRow2(
                                  'ΔT',
                                  '${deltaTempCtrl.text}°C',
                                  centerRight: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  pw.SizedBox(height: 25),

                  /// ================= COMMENTS =================
                  pw.Text('Comments:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Text(commentsCtrl.text,
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            );
          },
        ),
      );

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report PDF',
        fileName:
        'Thermal_Report_${equipmentIdCtrl.text}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (savePath == null) return;

      final file = File(savePath);
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);

      _snack('Report generated successfully ✅');
    } catch (e) {
      _snack('Failed: $e');
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
                            child: UploadCard(
                              title: 'Thermal Image',
                              bytes: thermalBytes,
                              primary: true,
                              onPick: pickThermalImage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: UploadCard(
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

                              const Text('EMISSIVITY',
                                  style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: 1,
                                      color: Colors.white70)),
                              const SizedBox(height: 6),
                              TextField(controller: emissivityCtrl),

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
                                    child: StatusButton(
                                      selected: isInitial,
                                      text: 'Initial',
                                      onTap: () => setState(() => isInitial = true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: StatusButton(
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
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child:
                                        TextField(
                                          controller: deltaTempCtrl,
                                          readOnly: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Delta Temp (°C)',
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

  pw.TableRow _pdfRow4(String a, String b, String c, String d, {bool bold = false}) {
    final style = pw.TextStyle(
      color: PdfColors.black,
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
      color: PdfColors.black,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final rightStyle = const pw.TextStyle(
      color: PdfColors.black,
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
}