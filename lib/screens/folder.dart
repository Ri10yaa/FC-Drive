import 'package:fc_drive/utilities/FloatingButton.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/FolderProvider.dart'; // Path Provider for managing folder navigation
import '../providers/UserProvider.dart'; // User Provider for user data
import '../utilities/notifications.dart';
import 'FilePreview.dart';

class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<dynamic> folders = []; // Holds the list of folders
  List<dynamic> files = [];
  bool isLoading = true; // Tracks if data is still loading
  String errorMessage = ''; // Error message if API fails

  @override
  void initState() {
    super.initState();
    fetchFolders(context);
  }

  Future<void> fetchFolders(BuildContext context) async {
    try {
      final userId =
          Provider.of<UserProvider>(context, listen: false).user?.fId ?? '';
      final folderPath =
          Provider.of<FolderProvider>(context, listen: false).currentPath;
      final pathString = folderPath.isNotEmpty ? folderPath.join('/') : 'root';
      final String url = 'http://127.0.0.1:5000/folders/$userId/$pathString';
      print("URL : ${url}");
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['folders'] != null) {
          setState(() {
            folders = data['folders'];
            files = data['files'] ?? [];
            print(files);
            errorMessage = '';
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "No folders found!";
            folders = [];
            isLoading = false;
          });
        }
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          errorMessage = 'Error in fetching folders!';
          isLoading = false;
        });
        NotificationUtil.showInAppNotification(
          context: context,
          text: 'Failed to load folders: ${responseData['error']}',
          color: Colors.red,
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
      NotificationUtil.showInAppNotification(
        context: context,
        text: 'Error: ${e.toString()}',
        color: Colors.red,
      );
    }
  }

  Widget buildFolderAndFileList({
    required List<dynamic> folders,
    required List<dynamic> files,
    required Function(Map<String, dynamic>) onTapFolder,
  }) {
    final allItems = [
      ...folders.map((folder) => {'type': 'folder', 'data': folder}),
      ...files.map((file) => {'type': 'file', 'data': file}),
    ];

    return ListView.separated(
      itemCount: allItems.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade300,
        thickness: 1,
        height: 1,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final item = allItems[index];
        final type = item['type'];
        final data = item['data'];

        return ListTile(
          leading: Icon(
            type == 'folder' ? Icons.folder : Icons.insert_drive_file,
            color: type == 'folder' ? Colors.green : Color(0xFFBF9264),
          ),
          title: Text(
            type == 'folder'
                ? (data['folder_name'] ?? 'Untitled Folder')
                : (data['file_name'] ?? 'Untitled File'),
          ),
          subtitle: Text((data['created_at'] != null
              ? 'Created at: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(data['created_at']))}'
              : 'No creation date available')),
          onTap: () async {
            if (type == 'folder') {
              // If it's a folder, navigate inside
              final folderName = data['folder_name'] ?? 'Untitled Folder';
              Provider.of<FolderProvider>(context, listen: false)
                  .navigateToFolder(folderName);

              setState(() {
                isLoading = true;
              });

              await fetchFolders(context);
            } else {
              // If it's a file, maybe you can show file details or download it
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilePreviewScreen(fileKey: data['path']!),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context);

    return Scaffold(
        appBar: AppBar(
          title: Text('Folder Path: ${folderProvider.currentPath.join('/')}'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              Provider.of<FolderProvider>(context, listen: false)
                  .navigateBack();

              setState(() {
                isLoading = true;
              });

              await fetchFolders(context);
            },
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFFBF9264)))
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : Container(
                    padding: EdgeInsets.all(16.0),
                    margin: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: buildFolderAndFileList(
                      folders: folders,
                      files: files,
                      onTapFolder: (folder) async {
                        final folderName =
                            folder['folder_name'] ?? 'Untitled Folder';
                        Provider.of<FolderProvider>(context, listen: false)
                            .navigateToFolder(folderName);

                        setState(() {
                          isLoading = true;
                        });

                        await fetchFolders(context);
                      },
                    ),
                  ),
        floatingActionButton: const UploadFloatingButton());
  }
}
