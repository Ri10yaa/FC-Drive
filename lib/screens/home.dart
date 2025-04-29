import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import "package:file_picker/file_picker.dart";
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

import '../providers/FolderProvider.dart';
import '../providers/UserProvider.dart';
import '../utilities/notifications.dart';
import 'FilePreview.dart';
import '../utilities/FloatingButton.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _notificationText = "";

  bool _showNotification = false;
  // In-app notification visibility
  Color _notificationColor = Colors.red;

  Future<List<Map<String, String>>> fetchRecentFiles(String userId) async {
    final String url = 'http://127.0.0.1:5000/files/recent/$userId';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> files = responseData['files'] ?? [];
        print(files);

        return files.map<Map<String, String>>((file) {
          return {
            "file_name": file["file_name"] ?? "",
            "file_type": file["file_type"] ?? "",
            "file_size": file["file_size"]?.toString() ??
                "", // Convert file_size to String
            "path": file["path"] ?? "",
            "accessed_at":
                file["accessed_at"] ?? "", // Expect ISO-formatted date
          };
        }).toList();
      } else if (response.statusCode == 404) {
        print('No recent files found');
        return [];
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
    BuildContext context,
  ) async {
    final String url = 'http://127.0.0.1:5000/files/upload';
    final folderHierarchy =
        Provider.of<FolderProvider>(context, listen: false).currentPath;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xFFBF9264)));
        },
      );
      print(userId);
      print(fileName);
      print(folderHierarchy);
      final int fileSize = selectedFile.size;
      final String? fileType =
          selectedFile.extension ?? 'application/octet-stream';
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
        "file_size": fileSize,
        "file_type": fileType
      });

      var response = await request.send();

      Navigator.pop(context); // Remove loading indicator
      Navigator.pop(context); // remove the menu options

      if (response.statusCode == 200) {
        print('File uploaded successfully');
        NotificationUtil.showInAppNotification(
          context: context,
          text: 'File uploaded successfully',
          color: Colors.green,
        );
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text('File uploaded successfully')));
      } else {
        print('Failed to upload file: ${response.reasonPhrase}');
        NotificationUtil.showInAppNotification(
          context: context,
          text: 'Failed to upload file: ${response.reasonPhrase}',
          color: Colors.red,
        );
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text('Failed to upload file')));
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading indicator
      print('Error while uploading file: $e');
      NotificationUtil.showInAppNotification(
        context: context,
        text: 'Error while uploading file: $e',
        color: Colors.red,
      );
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text('Error while uploading file')));
    }
  }

  Future<void> createFolder(
    String userId,
    String folderName,
    BuildContext context,
  ) async {
    final String url = 'http://127.0.0.1:5000/folders/create';
    final folderHierarchy =
        Provider.of<FolderProvider>(context, listen: false).currentPath;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xFFBF9264)));
        },
      );
      print(userId);
      print(folderName);
      print(folderHierarchy);

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
        NotificationUtil.showInAppNotification(
          context: context,
          text: 'Folder created successfully',
          color: Colors.green,
        );
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text('Folder created successfully')));
      } else {
        print('Failed to create folder: ${response.body}');
        NotificationUtil.showInAppNotification(
          context: context,
          text: 'Failed to create folder: ${response.body}',
          color: Colors.red,
        );
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text('Failed to create folder')));
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading indicator
      print('Error while creating folder: $e');
      NotificationUtil.showInAppNotification(
        context: context,
        text: 'Error while creating folder: $e',
        color: Colors.red,
      );
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text('Error while creating folder')));
    }
  }

  void _showFileUploadPopup(BuildContext context, String userId) {
    final TextEditingController fileNameController = TextEditingController();

    PlatformFile? selectedFile; // To store the selected file

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: fileNameController,
                decoration: InputDecoration(
                  labelText: 'File Name',
                  labelStyle: TextStyle(
                    color: Color(0xFF27391C),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(
                        0xFF67AE6E,
                      ), // Change this to your desired color
                      width: 2.0, // Adjust the width of the border
                    ),
                  ),
                ),
                cursorColor: Color(0xFF27391C),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();

                      if (result != null) {
                        selectedFile =
                            result.files.first; // Store selected file
                        fileNameController.text =
                            selectedFile!.name; // Auto-fill filename
                      } else {
                        NotificationUtil.showInAppNotification(
                          context: context,
                          text: 'No file selected',
                          color: Colors.yellowAccent,
                        );
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(content: Text('No file selected')),
                        // );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF67AE6E),
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Pick File',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedFile != null) {
                        uploadFile(
                          userId,
                          selectedFile!,
                          fileNameController.text.trim(),
                          context,
                        );
                      } else {
                        NotificationUtil.showInAppNotification(
                          context: context,
                          text: 'No file selected for upload',
                          color: Colors.yellowAccent,
                        );
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //       content: Text('No file selected for upload')),
                        // );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF67AE6E),
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Submit File',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
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
                decoration: InputDecoration(
                  labelText: 'Folder Name',
                  labelStyle: TextStyle(
                    color: Color(0xFF27391C),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  createFolder(
                    userId,
                    folderNameController.text.trim(),
                    context,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF67AE6E),
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  'Create Folder',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

  // void _showInAppNotification(String text, Color color) {
  //   setState(() {
  //     _notificationText = text;
  //     _notificationColor = color;
  //     _showNotification = true;
  //   });
  //
  //   Future.delayed(Duration(seconds: 3), () {
  //     setState(() {
  //       _showNotification = false;
  //     });
  //   });
  // }

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
                          subtitle: Text(
                            'Last opened: ${DateFormat('dd/MM/yyyy hh:mm').format(DateTime.parse(file['accessed_at']!))}',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FilePreviewScreen(fileKey: file['path']!),
                              ),
                            );

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
      floatingActionButton: const UploadFloatingButton()
    );
  }
}
