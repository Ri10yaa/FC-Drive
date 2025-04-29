import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html; // For Web Blob usage

import '../providers/UserProvider.dart';

class FilePreviewScreen extends StatefulWidget {
  final String fileKey;

  const FilePreviewScreen({Key? key, required this.fileKey}) : super(key: key);

  @override
  _FilePreviewScreenState createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  Uint8List? fileBytes;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchFile();
  }

  Future<void> fetchFile() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).user?.fId ?? '';
      final url = Uri.parse('http://127.0.0.1:5000/files/$userId/get-file/${widget.fileKey}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          fileBytes = response.bodyBytes;
          isLoading = false;
        });

        // Special handling for PDF on Web
        if (kIsWeb && getFileExtension(widget.fileKey) == 'pdf') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            openPdfInNewTab(fileBytes!);
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load file: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void openPdfInNewTab(Uint8List bytes) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
  }

  String getFileExtension(String fileName) {
    if (!fileName.contains('.')) return '';
    return fileName.split('.').last.toLowerCase();
  }

  Widget buildFilePreview() {
    if (fileBytes == null || fileBytes!.isEmpty) {
      return const Center(child: Text('File is empty or could not be loaded'));
    }

    final ext = getFileExtension(widget.fileKey);

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      return Image.memory(fileBytes!);
    } else if (ext == 'pdf') {
      if (kIsWeb) {
        return const Center(child: Text('Opening PDF in new tab...'));
      } else {
        return SfPdfViewer.memory(fileBytes!);
      }
    } else if (['txt', 'json', 'dart', 'py', 'js', 'html', 'css', 'java'].contains(ext)) {
      try {
        final text = utf8.decode(fileBytes!);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(child: SelectableText(text)),
        );
      } catch (e) {
        return const Center(child: Text('Could not decode text file.'));
      }
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 80),
            const SizedBox(height: 16),
            Text(widget.fileKey, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text('No preview available for this file type.'),
            ElevatedButton(
              onPressed: () {
                downloadFile(fileBytes!, widget.fileKey);
              },
              child: const Text('Download'),
            ),
          ],
        ),
      );
    }
  }

  void downloadFile(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Preview'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBF9264)))
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : buildFilePreview(),
    );
  }
}
