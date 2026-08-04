import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:wms/admin/features/trigger_logs/services/trigger_log_models.dart';
import 'package:wms/shared/utils/app_date_time_formatter.dart';

class TriggerLogPdfService {
  static Future<void> generateAndPrintPdf(List<TriggerLog> logs) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Trigger Logs Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            context: context,
            data: <List<String>>[
              <String>['Log ID', 'ESP ID', 'Component', 'Action', 'Status', 'Type', 'Date/Time'],
              ...logs.map((log) => [
                    log.logId.toString(),
                    log.espId,
                    '${log.componentName} (Id: ${log.componentId})',
                    log.action,
                    log.status,
                    log.triggerType.value,
                    AppDateTimeFormatter.formatDateTime(log.triggeredAt),
                  ]),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'trigger_logs_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }
}
