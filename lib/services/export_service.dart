import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExportService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _exportPDF(BuildContext context) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/reports/export-pdf'),
      headers: headers,
      body: json.encode({}), // Add any required body params if needed
    );

    if (response.statusCode == 200) {
      // Assume response is the file content
      final fileName = 'revenue_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await _saveFile(response.bodyBytes, fileName);
      _showDownloadSuccessDialog(context, 'PDF', filePath);
    } else {
      throw Exception('Failed to export PDF');
    }
  }

  Future<void> _exportExcel(BuildContext context) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/reports/export-excel'),
      headers: headers,
      body: json.encode({}), // Add any required body params if needed
    );

    if (response.statusCode == 200) {
      // Assume response is the file content
      final fileName = 'revenue_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = await _saveFile(response.bodyBytes, fileName);
      _showDownloadSuccessDialog(context, 'Excel', filePath);
    } else {
      throw Exception('Failed to export Excel');
    }
  }

  Future<String> _saveFile(List<int> bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  void _showDownloadSuccessDialog(BuildContext context, String type, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type Export Successful'),
        content: Text('Your $type report has been saved to:\n$filePath'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Public methods to call from UI
  Future<void> exportPDF(BuildContext context) async {
    try {
      await _exportPDF(context);
    } catch (e) {
      _showErrorDialog(context, 'PDF Export Failed', e.toString());
    }
  }

  Future<void> exportExcel(BuildContext context) async {
    try {
      await _exportExcel(context);
    } catch (e) {
      _showErrorDialog(context, 'Excel Export Failed', e.toString());
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}