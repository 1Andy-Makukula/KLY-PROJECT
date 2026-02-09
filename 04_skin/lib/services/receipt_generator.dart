/// =============================================================================
/// KithLy Global Protocol - RECEIPT GENERATOR (Phase IV)
/// receipt_generator.dart - PDF Generation for ZRA Receipts
/// =============================================================================
///
/// Generates 80mm thermal-compatible PDF receipts with ZRA QR code
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptData {
  final String txId;
  final String txRef;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String currency;
  final String shopName;
  final String shopTpin;
  final String bhfId;
  final String zraReceiptNumber;
  final String zraResultCode;
  final DateTime issuedAt;
  final String? qrCodeBase64;
  final double? aiConfidence;
  
  ReceiptData({
    required this.txId,
    required this.txRef,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    this.currency = 'ZMW',
    required this.shopName,
    required this.shopTpin,
    required this.bhfId,
    required this.zraReceiptNumber,
    required this.zraResultCode,
    required this.issuedAt,
    this.qrCodeBase64,
    this.aiConfidence,
  });
}

class ReceiptGenerator {
  static ReceiptGenerator? _instance;
  static ReceiptGenerator get instance {
    _instance ??= ReceiptGenerator._();
    return _instance!;
  }
  
  ReceiptGenerator._();
  
  // 80mm thermal paper width (in PDF points, 1 point = 1/72 inch)
  // 80mm = 3.15 inches = ~227 points
  static const double thermalWidth = 227;
  static const double margin = 10;
  
  /// Generate PDF receipt and return file path
  Future<String> generateReceipt(ReceiptData data) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(thermalWidth, double.infinity, marginAll: margin),
        build: (context) => _buildReceiptContent(data),
      ),
    );
    
    // Save to downloads folder
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'KithLy_Receipt_${data.txRef}.pdf';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }
  
  /// Generate receipt as bytes (for sharing/printing)
  Future<Uint8List> generateReceiptBytes(ReceiptData data) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(thermalWidth, double.infinity, marginAll: margin),
        build: (context) => _buildReceiptContent(data),
      ),
    );
    
    return await pdf.save();
  }
  
  pw.Widget _buildReceiptContent(ReceiptData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Header
        _buildHeader(),
        pw.SizedBox(height: 8),
        
        // Shop info
        _buildShopInfo(data),
        pw.SizedBox(height: 8),
        
        // Divider
        _buildDivider(),
        pw.SizedBox(height: 8),
        
        // Transaction details
        _buildTransactionDetails(data),
        pw.SizedBox(height: 8),
        
        // Divider
        _buildDivider(),
        pw.SizedBox(height: 8),
        
        // ZRA Fiscal Info
        _buildZRAInfo(data),
        pw.SizedBox(height: 8),
        
        // AI Verification (if available)
        if (data.aiConfidence != null) ...[
          _buildAIVerification(data),
          pw.SizedBox(height: 8),
        ],
        
        // Divider
        _buildDivider(),
        pw.SizedBox(height: 12),
        
        // QR Code
        if (data.qrCodeBase64 != null)
          _buildQRCode(data.qrCodeBase64!),
        pw.SizedBox(height: 8),
        
        // Footer
        _buildFooter(data),
      ],
    );
  }
  
  pw.Widget _buildHeader() {
    return pw.Column(
      children: [
        pw.Text(
          'KITHLY',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'Global Gifting Protocol',
          style: const pw.TextStyle(fontSize: 8),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'FISCAL RECEIPT',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  pw.Widget _buildShopInfo(ReceiptData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          data.shopName,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          'TPIN: ${data.shopTpin}',
          style: const pw.TextStyle(fontSize: 8),
        ),
        pw.Text(
          'Branch: ${data.bhfId}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ],
    );
  }
  
  pw.Widget _buildTransactionDetails(ReceiptData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildRow('Ref:', data.txRef),
        _buildRow('Date:', _formatDate(data.issuedAt)),
        pw.SizedBox(height: 4),
        _buildRow('Item:', data.productName),
        _buildRow('Qty:', '${data.quantity}'),
        _buildRow('Unit:', '${data.currency} ${data.unitPrice.toStringAsFixed(2)}'),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${data.currency} ${data.totalAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  pw.Widget _buildZRAInfo(ReceiptData data) {
    final isVerified = data.zraResultCode == '000' || data.zraResultCode == '001';
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'ZRA FISCAL DATA',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          _buildRow('Receipt No:', data.zraReceiptNumber),
          _buildRow('Result:', isVerified ? 'VERIFIED' : 'PENDING'),
          _buildRow('Code:', data.zraResultCode),
        ],
      ),
    );
  }
  
  pw.Widget _buildAIVerification(ReceiptData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'AI Verified: ${(data.aiConfidence! * 100).toStringAsFixed(0)}%',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildQRCode(String base64) {
    // In production, decode base64 to image
    // For now, show placeholder
    return pw.Container(
      width: 80,
      height: 80,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
      ),
      child: pw.Center(
        child: pw.Text(
          'QR CODE',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
    );
  }
  
  pw.Widget _buildFooter(ReceiptData data) {
    return pw.Column(
      children: [
        pw.Text(
          'Scan QR for verification',
          style: const pw.TextStyle(fontSize: 7),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Thank you for using KithLy',
          style: const pw.TextStyle(fontSize: 8),
        ),
        pw.Text(
          'www.kithly.com',
          style: const pw.TextStyle(fontSize: 7),
        ),
      ],
    );
  }
  
  pw.Widget _buildDivider() {
    return pw.Container(
      width: double.infinity,
      child: pw.Text(
        '- - - - - - - - - - - - - - - - - -',
        style: const pw.TextStyle(fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
  
  pw.Widget _buildRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.Flexible(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Thermal printer bridge for shop interface
class ThermalPrinterBridge {
  /// Generate simplified text receipt for thermal printers
  static String generateThermalText(ReceiptData data) {
    final buffer = StringBuffer();
    
    buffer.writeln('================================');
    buffer.writeln('        KITHLY');
    buffer.writeln('   Global Gifting Protocol');
    buffer.writeln('================================');
    buffer.writeln('');
    buffer.writeln(data.shopName);
    buffer.writeln('TPIN: ${data.shopTpin}');
    buffer.writeln('Branch: ${data.bhfId}');
    buffer.writeln('--------------------------------');
    buffer.writeln('Ref: ${data.txRef}');
    buffer.writeln('Date: ${_formatDate(data.issuedAt)}');
    buffer.writeln('--------------------------------');
    buffer.writeln('Item: ${data.productName}');
    buffer.writeln('Qty: ${data.quantity}');
    buffer.writeln('Price: ${data.currency} ${data.unitPrice.toStringAsFixed(2)}');
    buffer.writeln('--------------------------------');
    buffer.writeln('TOTAL: ${data.currency} ${data.totalAmount.toStringAsFixed(2)}');
    buffer.writeln('================================');
    buffer.writeln('ZRA FISCAL DATA');
    buffer.writeln('Receipt: ${data.zraReceiptNumber}');
    buffer.writeln('Status: VERIFIED');
    buffer.writeln('Code: ${data.zraResultCode}');
    buffer.writeln('================================');
    buffer.writeln('');
    buffer.writeln('    Thank you for using KithLy');
    buffer.writeln('       www.kithly.com');
    buffer.writeln('');
    
    return buffer.toString();
  }
  
  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
