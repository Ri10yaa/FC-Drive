import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'notifications.dart'; // replace with actual import
import '../providers/FolderProvider.dart'; // replace with actual import
import '../providers/UserProvider.dart'; // replace with actual import

class UploadFloatingButton extends StatelessWidget {
  const UploadFloatingButton({super.key});

  void _showOptionsMenu(BuildContext context) {
    final userId =
        Provider.of<UserProvider>(context, listen: false).user?.fId ?? '';

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.green),
              title: const Text('Upload File'),
              onTap: () {
                Navigator.pop(context);
                _showFileUploadPopup(context, userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder, color: Colors.green),
              title: const Text('Create Folder'),
              onTap: () {
                Navigator.pop(context);
                _showFolderCreationPopup(context, userId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFileUploadPopup(BuildContext context, String userId) {
    final TextEditingController fileNameController = TextEditingController();
    PlatformFile? selectedFile;

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: fileNameController,
              decoration: const InputDecoration(
                labelText: 'File Name',
                labelStyle: TextStyle(color: Color(0xFF27391C)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFF67AE6E),
                    width: 2.0,
                  ),
                ),
              ),
              cursorColor: Color(0xFF27391C),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      selectedFile = result.files.first;
                      fileNameController.text = selectedFile!.name;
                    } else {
                      NotificationUtil.showInAppNotification(
                        context: context,
                        text: 'No file selected',
                        color: Colors.yellowAccent,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF67AE6E),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Pick File'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (selectedFile != null) {
                      _uploadFile(
                        context,
                        userId,
                        selectedFile!,
                        fileNameController.text.trim(),
                      );
                    } else {
                      NotificationUtil.showInAppNotification(
                        context: context,
                        text: 'No file selected for upload',
                        color: Colors.yellowAccent,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF67AE6E),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Submit File'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderCreationPopup(BuildContext context, String userId) {
    final TextEditingController folderNameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: folderNameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                labelStyle: TextStyle(color: Color(0xFF27391C)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _createFolder(
                  context,
                  userId,
                  folderNameController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF67AE6E),
                foregroundColor: Colors.black,
              ),
              child: const Text('Create Folder'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile(
      BuildContext context,
      String userId,
      PlatformFile file,
      String fileName,
      ) async {
    final folderPath =
        Provider.of<FolderProvider>(context, listen: false).currentPath;
    final url = Uri.parse('${dotenv.env['API_URL']}/files/upload');
    print("Uploading to : ${folderPath}");
    try {

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
        const Center(child: CircularProgressIndicator(color: Color(0xFFBF9264))),
      );

      var request = http.MultipartRequest('POST', url)
        ..files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name))
        ..fields['metadata'] = jsonEncode({
          "firebase_id": userId,
          "file_name": fileName,
          "folder_hiearchy": folderPath,
          "file_size": file.size,
          "file_type": file.extension ?? 'application/octet-stream',
        });

      final response = await request.send();

      Navigator.pop(context); // Close loader
      Navigator.pop(context); // Close popup

      if (response.statusCode == 200) {
        NotificationUtil.showInAppNotification(
          context: context,
          text: 'File uploaded successfully',
          color: Colors.green,
        );
      } else {
        NotificationUtil.showInAppNotification(
          context: context,
          text: 'Failed to upload file: ${response.reasonPhrase}',
          color: Colors.red,
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loader
      NotificationUtil.showInAppNotification(
        context: context,
        text: 'Upload error: $e',
        color: Colors.red,
      );
    }
  }

  Future<void> _createFolder(
      BuildContext context,
      String userId,
      String folderName,
      ) async {
    final folderPath =
        Provider.of<FolderProvider>(context, listen: false).currentPath;
    final url = Uri.parse('${dotenv.env['API_URL']}/folders/create');
    print("Uploading to : ${folderPath}");
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
        const Center(child: CircularProgressIndicator(color: Color(0xFFBF9264))),
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "firebase_id": userId,
          "folder_name": folderName,
          "folder_hiearchy": folderPath,
        }),
      );

      Navigator.pop(context); // Close loader

      if (response.statusCode == 200) {
        NotificationUtil.showInAppNotification(
          context: context,
          text: 'Folder created successfully',
          color: Colors.green,
        );
      } else {
        NotificationUtil.showInAppNotification(
          context: context,
          text: 'Failed to create folder: ${response.body}',
          color: Colors.red,
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loader
      NotificationUtil.showInAppNotification(
        context: context,
        text: 'Creation error: $e',
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showOptionsMenu(context),
      backgroundColor: const Color(0xFFBF9264),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}
