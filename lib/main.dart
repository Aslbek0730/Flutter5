import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:mysql1/mysql1.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CSV/Excel'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _pickFile(),
          child: Text('Upload File'),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileExtension = result.files.single.extension!;

      if (fileExtension == 'csv') {
        _loadCsv(file);
      } else if (fileExtension == 'xlsx') {
        _loadExcel(file);
      } else {
        _showMessage('Unsupported file format.');
      }
    } else {
      _showMessage('No file selected.');
    }
  }

  Future<void> _loadCsv(File file) async {
    String fileContent = await file.readAsString();
    List<List<dynamic>> csvTable = CsvToListConverter().convert(fileContent);

    await _uploadDataToMySQL(csvTable);
  }

  Future<void> _loadExcel(File file) async {
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    List<List<dynamic>> excelTable = [];
    for (var table in excel.tables.keys) {
      excel.tables[table]?.rows.forEach((row) {
        excelTable.add(row);
      });
    }

    await _uploadDataToMySQL(excelTable);
  }

  Future<void> _uploadDataToMySQL(List<List<dynamic>> data) async {
    final conn = await MySqlConnection.connect(ConnectionSettings(
      host: 'predator.com',
      port: 3306,
      user: 'Aslbek',
      db: 'students',
      password: 'qweqweqwe',
    ));

    for (var row in data) {
      if (row.isNotEmpty && row.length >= 4) {
        var result = await conn.query(
            'INSERT INTO students (id, first_name, last_name, age) VALUES (?, ?, ?, ?)',
            [row[0], row[1], row[2], row[3]]
        );
        print('Inserted row id=${result.insertId}'); // Konsolga yozish
      }
    }

    await conn.close();
    _showMessage('Data uploaded successfully.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
