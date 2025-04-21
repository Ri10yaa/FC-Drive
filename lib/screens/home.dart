import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import "package:file_picker/file_picker.dart";

import '../UserProvider.dart';

class HomeScreen extends StatelessWidget {
  Future<List<Map<String, String>>> fetchRecentFiles(String userId) async {
    final String url = 'http://127.0.0.1:5000/files/recent/$userId';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> files = responseData['files'] ?? [];

        return files.map<Map<String, String>>((file) {
          return {
            "file_name": file["file_name"] ?? "",
            "file_type": file["file_type"] ?? "",
            "file_size": file["file_size"]?.toString() ?? "",
            "path": file["path"] ?? "",
            "accessed_at": file["accessed_at"] ?? "",
          };
        }).toList();
      } else {
        print('Failed to fetch files: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error while fetching files: $e');
      return [];
    }
  }

  Future<void> uploadFile(
    String userId,
    PlatformFile selectedFile,
    String fileName,
    List<String> folderHierarchy,
    BuildContext context,
  ) async {
    final String url = 'http://127.0.0.1:5000/files/upload';

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      // Prepare request body and metadata
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          selectedFile.bytes!,
          filename: selectedFile.name,
        ),
      );
      request.fields['metadata'] = jsonEncode({
        "firebase_id": userId,
        "file_name": fileName,
        "folder_hiearchy": folderHierarchy,
      });

      var response = await request.send();

      Navigator.pop(context); // Remove loading indicator

      if (response.statusCode == 200) {
        print('File uploaded successfully');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File uploaded successfully')));
      } else {
        print('Failed to upload file: ${response.reasonPhrase}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload file')));
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading indicator
      print('Error while uploading file: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error while uploading file')));
    }
  }

  Future<void> createFolder(
    String userId,
    String folderName,
    List<String> folderHierarchy,
    BuildContext context,
  ) async {
    final String url = 'http://127.0.0.1:5000/folders/create';

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "firebase_id": userId,
          "folder_name": folderName,
          "folder_hiearchy": folderHierarchy,
        }),
      );

      Navigator.pop(context); // Remove loading indicator

      if (response.statusCode == 200) {
        print('Folder created successfully');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Folder created successfully')));
      } else {
        print('Failed to create folder: ${response.body}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create folder')));
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading indicator
      print('Error while creating folder: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error while creating folder')));
    }
  }

  void _showFileUploadPopup(BuildContext context, String userId) {
    final TextEditingController fileNameController = TextEditingController();
    final TextEditingController folderHierarchyController =
        TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: fileNameController,
                decoration: InputDecoration(labelText: 'File Name'),
              ),
              TextField(
                controller: folderHierarchyController,
                decoration: InputDecoration(
                  labelText: 'Folder Hierarchy (comma separated)',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();

                  if (result != null) {
                    PlatformFile selectedFile = result.files.first;
                    uploadFile(
                      userId,
                      selectedFile,
                      fileNameController.text.trim(),
                      folderHierarchyController.text
                          .split(',')
                          .map((e) => e.trim())
                          .toList(),
                      context,
                    );
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('No file selected')));
                  }
                },
                child: Text('Pick and Upload File'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFolderCreationPopup(BuildContext context, String userId) {
    final TextEditingController folderNameController = TextEditingController();
    final TextEditingController folderHierarchyController =
        TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: folderNameController,
                decoration: InputDecoration(labelText: 'Folder Name'),
              ),
              TextField(
                controller: folderHierarchyController,
                decoration: InputDecoration(
                  labelText: 'Folder Hierarchy (comma separated)',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  createFolder(
                    userId,
                    folderNameController.text.trim(),
                    folderHierarchyController.text
                        .split(',')
                        .map((e) => e.trim())
                        .toList(),
                    context,
                  );
                },
                child: Text('Create Folder'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final userId =
        Provider.of<UserProvider>(context, listen: false).user?.fId ?? '';

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.upload_file, color: Colors.green),
                title: Text('Upload File'),
                onTap: () {
                  Navigator.pop(context);
                  _showFileUploadPopup(context, userId);
                },
              ),
              ListTile(
                leading: Icon(Icons.create_new_folder, color: Colors.green),
                title: Text('Create Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _showFolderCreationPopup(context, userId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search files...',
                  suffixIcon: Icon(Icons.search, color: Colors.green),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),
          // Container for Recent Files
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: FutureBuilder<List<Map<String, String>>>(
                future: fetchRecentFiles(user?.fId ?? ''), // Pass user ID
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final file = snapshot.data![index];
                        return ListTile(
                          leading: Icon(
                            Icons.insert_drive_file,
                            color: Colors.green,
                          ),
                          title: Text(file['file_name'] ?? ""),
                          subtitle: Text('Last opened: ${file['accessed_at']}'),
                          onTap: () {
                            print('File ${file['file_name']} tapped');
                          },
                        );
                      },
                    );
                  } else {
                    return Center(child: Text('No recent files available'));
                  }
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOptionsMenu(context),
        backgroundColor: Color(0xFFBF9264),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
