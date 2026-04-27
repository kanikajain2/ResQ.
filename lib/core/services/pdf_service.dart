import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../../core/models/incident_model.dart';

class PdfService {
  Future<File> generateIncidentReport(IncidentModel incident) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("ResQ Incident Report")),
              pw.SizedBox(height: 20),
              pw.Text("Incident ID: ${incident.id}"),
              pw.Text("Room Number: ${incident.roomNumber}"),
              pw.Text("Type: ${incident.type}"),
              pw.Text("Severity: ${incident.severity}"),
              pw.SizedBox(height: 20),
              pw.Text("AI Triage Summary:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(incident.aiSummary ?? "None"),
              pw.SizedBox(height: 20),
              pw.Text("Post-Incident Report:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(incident.postIncidentReport ?? "Pending"),
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.Text("Generated on: ${DateTime.now()}"),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/incident_${incident.id}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
