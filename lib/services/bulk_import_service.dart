import 'dart:typed_data';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';

/// Data class representing a parsed student record from bulk import.
class StudentImportRecord {
  final String name;
  final String department;
  final String email;
  final String digitalId;

  StudentImportRecord({
    required this.name,
    required this.department,
    required this.email,
    required this.digitalId,
  });

  @override
  String toString() =>
      'StudentImportRecord(name: $name, dept: $department, email: $email, id: $digitalId)';
}

/// Service to parse XLSX and PDF files for bulk student import.
class BulkImportService {
  BulkImportService._();
  static final BulkImportService instance = BulkImportService._();

  // ─────────── XLSX PARSING ───────────

  List<StudentImportRecord> parseXlsx(Uint8List bytes) {
    // ── Step 1: Decode Excel and extract raw string grid ──
    final List<List<String>> rawData = _excelToStringGrid(bytes);

    if (rawData.isEmpty) {
      throw Exception('No data found in the Excel file.');
    }

    debugPrint('Extracted ${rawData.length} rows from Excel');

    // ── Step 2: Find header row and map columns ──
    int headerRowIdx = -1;
    int nameCol = -1, deptCol = -1, emailCol = -1, idCol = -1;

    for (int r = 0; r < rawData.length && r < 15; r++) {
      final row = rawData[r];
      bool hasName = false, hasEmailOrId = false;

      for (final val in row) {
        final lv = val.toLowerCase();
        if (_isNameHeader(lv)) hasName = true;
        if (_isEmailHeader(lv) || _isIdHeader(lv)) hasEmailOrId = true;
      }

      if (hasName && hasEmailOrId) {
        headerRowIdx = r;
        for (int c = 0; c < row.length; c++) {
          final lv = row[c].toLowerCase();
          if (lv.isEmpty) continue;
          if (nameCol == -1 && _isNameHeader(lv)) {
            nameCol = c;
          } else if (deptCol == -1 && _isDeptHeader(lv)) {
            deptCol = c;
          } else if (emailCol == -1 && _isEmailHeader(lv)) {
            emailCol = c;
          } else if (idCol == -1 && _isIdHeader(lv)) {
            idCol = c;
          }
        }
        break;
      }
    }

    if (headerRowIdx == -1) headerRowIdx = 0;

    // Fallback positional mapping
    final used = <int>{};
    if (nameCol >= 0) used.add(nameCol);
    if (deptCol >= 0) used.add(deptCol);
    if (emailCol >= 0) used.add(emailCol);
    if (idCol >= 0) used.add(idCol);

    final maxC = rawData.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    int nextFree() {
      for (int c = 0; c < maxC; c++) {
        if (!used.contains(c)) {
          used.add(c);
          return c;
        }
      }
      return -1;
    }

    if (nameCol == -1) nameCol = nextFree();
    if (emailCol == -1) emailCol = nextFree();
    if (deptCol == -1) deptCol = nextFree();
    if (idCol == -1) idCol = nextFree();

    debugPrint(
      'Header row=$headerRowIdx | name=$nameCol dept=$deptCol email=$emailCol id=$idCol',
    );

    // ── Step 3: Parse data rows ──
    final records = <StudentImportRecord>[];
    for (int r = headerRowIdx + 1; r < rawData.length; r++) {
      final row = rawData[r];
      if (row.every((c) => c.isEmpty)) continue;

      final name = _col(row, nameCol);
      final dept = _col(row, deptCol);
      final email = _col(row, emailCol);
      final id = _col(row, idCol);

      if (name.isEmpty && email.isEmpty) continue;

      records.add(
        StudentImportRecord(
          name: name,
          department: dept,
          email: email,
          digitalId: id,
        ),
      );
    }

    debugPrint('Parsed ${records.length} student records');
    return records;
  }

  /// Decode xlsx bytes into a plain List<List<String>>.
  /// First tries the `excel` package; if that fails, falls back to
  /// manual ZIP+XML parsing (handles SharePoint / strict OOXML files).
  List<List<String>> _excelToStringGrid(Uint8List bytes) {
    // ── Attempt 1: Use the `excel` package ──
    try {
      final grid = _excelPackageParse(bytes);
      if (grid.isNotEmpty) {
        debugPrint('excel package parsed ${grid.length} rows');
        return grid;
      }
    } catch (e) {
      debugPrint('excel package failed: $e — trying raw XML fallback');
    }

    // ── Attempt 2: Manual ZIP + XML parsing ──
    try {
      final grid = _rawXmlParse(bytes);
      if (grid.isNotEmpty) {
        debugPrint('Raw XML fallback parsed ${grid.length} rows');
        return grid;
      }
    } catch (e) {
      debugPrint('Raw XML fallback also failed: $e');
    }

    throw Exception(
      'Cannot read this Excel file. Please try re-saving it as a new .xlsx file '
      'from Microsoft Excel or Google Sheets and upload again.',
    );
  }

  /// Parse using the `excel` Dart package.
  List<List<String>> _excelPackageParse(Uint8List bytes) {
    final List<List<String>> grid = [];

    final excel = Excel.decodeBytes(bytes);

    final sheetNames = excel.tables.keys.toList();
    if (sheetNames.isEmpty) return grid;

    for (final sheetName in sheetNames) {
      grid.clear();

      List<List<Data?>> rows;
      try {
        final sheet = excel.tables[sheetName];
        if (sheet == null) continue;
        rows = sheet.rows;
      } catch (e) {
        debugPrint('Error accessing rows of sheet "$sheetName": $e');
        continue;
      }

      if (rows.isEmpty) continue;

      for (int r = 0; r < rows.length; r++) {
        final List<String> stringRow = [];
        try {
          final row = rows[r];
          for (int c = 0; c < row.length; c++) {
            stringRow.add(_cellToString(row, c));
          }
        } catch (e) {
          debugPrint('Error reading row $r: $e');
        }
        if (stringRow.isNotEmpty) {
          grid.add(stringRow);
        }
      }

      if (grid.isNotEmpty) break;
    }

    return grid;
  }

  /// Fallback: Manually unzip the XLSX and parse the XML inside.
  /// An XLSX file is a ZIP containing:
  ///   - xl/sharedStrings.xml (lookup table of string values)
  ///   - xl/worksheets/sheet1.xml (the actual cell data)
  List<List<String>> _rawXmlParse(Uint8List bytes) {
    final List<List<String>> grid = [];

    // Decode ZIP archive
    final archive = ZipDecoder().decodeBytes(bytes);

    // ── 1. Load shared strings (string lookup table) ──
    final List<String> sharedStrings = [];
    final ssFile = archive.findFile('xl/sharedStrings.xml');
    if (ssFile != null) {
      final ssContent = ssFile.content as List<int>;
      final ssXml = XmlDocument.parse(utf8.decode(ssContent));
      // Each <si> element contains one shared string
      for (final si in ssXml.findAllElements('si')) {
        // Could have <t> directly or <r><t>...</t></r> runs
        final buffer = StringBuffer();
        for (final t in si.findAllElements('t')) {
          buffer.write(t.innerText);
        }
        sharedStrings.add(buffer.toString());
      }
      debugPrint('Loaded ${sharedStrings.length} shared strings');
    }

    // ── 2. Find worksheet files ──
    final sheetFiles = archive.files
        .where(
          (f) =>
              f.name.startsWith('xl/worksheets/sheet') &&
              f.name.endsWith('.xml'),
        )
        .toList();

    if (sheetFiles.isEmpty) {
      throw Exception('No worksheet XML found in the XLSX archive.');
    }

    // Sort so sheet1 comes first
    sheetFiles.sort((a, b) => a.name.compareTo(b.name));

    // ── 3. Parse the first sheet with data ──
    for (final sheetFile in sheetFiles) {
      grid.clear();

      final sheetContent = sheetFile.content as List<int>;
      final sheetXml = XmlDocument.parse(utf8.decode(sheetContent));

      // Each <row> has <c> (cell) elements
      for (final rowEl in sheetXml.findAllElements('row')) {
        final List<String> rowData = [];

        for (final cellEl in rowEl.findAllElements('c')) {
          final type = cellEl.getAttribute(
            't',
          ); // s=shared string, n=number, etc.
          final ref = cellEl.getAttribute('r') ?? ''; // e.g. A1, B2

          // Fill gaps with empty strings based on column reference
          final colIdx = _colRefToIndex(ref);
          while (rowData.length < colIdx) {
            rowData.add('');
          }

          // Get the <v> (value) element
          final vEl = cellEl.findElements('v').isEmpty
              ? null
              : cellEl.findElements('v').first;
          final rawValue = vEl?.innerText ?? '';

          String cellValue;
          if (type == 's' && rawValue.isNotEmpty) {
            // Shared string reference
            final idx = int.tryParse(rawValue) ?? -1;
            cellValue = (idx >= 0 && idx < sharedStrings.length)
                ? sharedStrings[idx]
                : rawValue;
          } else if (type == 'inlineStr') {
            // Inline string: look for <is><t> element
            final isEl = cellEl.findElements('is').isEmpty
                ? null
                : cellEl.findElements('is').first;
            cellValue =
                isEl?.findAllElements('t').map((t) => t.innerText).join() ??
                rawValue;
          } else {
            cellValue = rawValue;
          }

          rowData.add(cellValue.trim());
        }

        if (rowData.isNotEmpty && rowData.any((c) => c.isNotEmpty)) {
          grid.add(rowData);
        }
      }

      if (grid.isNotEmpty) {
        debugPrint(
          'Raw XML: sheet "${sheetFile.name}" yielded ${grid.length} rows',
        );
        break;
      }
    }

    return grid;
  }

  /// Convert a column reference like "A", "B", "AA" to a 0-based index.
  int _colRefToIndex(String ref) {
    // Extract letters from ref (e.g. "AB12" -> "AB")
    final letters = ref.replaceAll(RegExp(r'[0-9]'), '').toUpperCase();
    if (letters.isEmpty) return 0;

    int index = 0;
    for (int i = 0; i < letters.length; i++) {
      index = index * 26 + (letters.codeUnitAt(i) - 'A'.codeUnitAt(0) + 1);
    }
    return index - 1; // 0-based
  }

  /// Convert a single cell to String. Triple-wrapped for safety.
  String _cellToString(List<Data?> row, int c) {
    try {
      if (c < 0 || c >= row.length) return '';
      final cell = row[c];
      if (cell == null) return '';
      final v = cell.value;
      if (v == null) return '';
      return v.toString().trim();
    } catch (_) {
      return '';
    }
  }

  String _col(List<String> row, int i) =>
      (i >= 0 && i < row.length) ? row[i] : '';

  // ─────────── PDF PARSING ───────────

  List<StudentImportRecord> parsePdf(Uint8List bytes) {
    final records = <StudentImportRecord>[];

    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String fullText = PdfTextExtractor(document).extractText();
      document.dispose();

      if (fullText.trim().isEmpty) return records;

      final lines = fullText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.isEmpty) return records;

      int headerIdx = -1;
      for (int i = 0; i < lines.length && i < 10; i++) {
        final lower = lines[i].toLowerCase();
        if ((lower.contains('name') && lower.contains('email')) ||
            (lower.contains('name') && lower.contains('department')) ||
            (lower.contains('name') && lower.contains('id'))) {
          headerIdx = i;
          break;
        }
      }

      final startIdx = headerIdx == -1 ? 0 : headerIdx + 1;
      for (int i = startIdx; i < lines.length; i++) {
        final record = _parseDelimitedLine(lines[i]);
        if (record != null) records.add(record);
      }
    } catch (e) {
      debugPrint('PDF parse error: $e');
      throw Exception('Failed to parse PDF: $e');
    }

    return records;
  }

  // ─────────── HEADER MATCHERS ───────────

  bool _isNameHeader(String val) {
    return (val.contains('name') || val.contains('student')) &&
        !val.contains('mess') &&
        !val.contains('file') &&
        !val.contains('sheet');
  }

  bool _isDeptHeader(String val) {
    return val.contains('dept') ||
        val.contains('department') ||
        val.contains('branch') ||
        val.contains('programme') ||
        val.contains('program');
  }

  bool _isEmailHeader(String val) {
    return val.contains('email') ||
        val.contains('mail') ||
        val.contains('e-mail') ||
        val == 'email id';
  }

  bool _isIdHeader(String val) {
    return val.contains('digital') ||
        val.contains('roll') ||
        val.contains('reg') ||
        val.contains('enrollment') ||
        val.contains('admission') ||
        val == 'id' ||
        val.contains('id no') ||
        val.contains('id.') ||
        val.contains('digital id') ||
        val.contains('register number');
  }

  // ─────────── PDF LINE PARSER ───────────

  StudentImportRecord? _parseDelimitedLine(String line) {
    List<String> parts = line.split('\t').map((s) => s.trim()).toList();
    if (parts.length < 3) {
      parts = line.split(',').map((s) => s.trim()).toList();
    }
    if (parts.length < 3) {
      parts = line.split(RegExp(r'\s{2,}')).map((s) => s.trim()).toList();
    }
    if (parts.length < 3) return null;

    final firstLower = parts[0].toLowerCase();
    if (firstLower == 'name' ||
        firstLower == 's.no' ||
        firstLower == 'sl.no' ||
        firstLower == 'sno' ||
        firstLower.startsWith('#')) {
      return null;
    }

    int offset = 0;
    if (parts.length >= 4 && _isSerialNumber(parts[0])) {
      offset = 1;
    }

    final name = parts.length > offset ? parts[offset] : '';
    final dept = parts.length > offset + 1 ? parts[offset + 1] : '';
    final email = parts.length > offset + 2 ? parts[offset + 2] : '';
    final id = parts.length > offset + 3 ? parts[offset + 3] : '';

    if (name.isEmpty && email.isEmpty) return null;

    return StudentImportRecord(
      name: name,
      department: dept,
      email: email,
      digitalId: id,
    );
  }

  bool _isSerialNumber(String s) {
    return int.tryParse(s.replaceAll('.', '')) != null;
  }
}
