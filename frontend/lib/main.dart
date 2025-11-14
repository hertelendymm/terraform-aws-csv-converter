import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:file_picker/file_picker.dart';

const String apiEndpointUrl = String.fromEnvironment('API_ENDPOINT_URL');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSV to JSON Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _outputText = "Your JSON output will appear here...";
  bool _isJsonReady = false;

  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  List<String> _fileHistory = [];
  bool _isHistoryLoading = false;

  bool _isDragOver = false;

  @override
  void initState() {
    super.initState();
    _fetchFileHistory();
  }

  Future<void> _fetchFileHistory() async {
    setState(() {
      _isHistoryLoading = true;
    });

    try {
      final getFilesUrl = Uri.parse('$apiEndpointUrl/files');
      final getFilesResponse = await http.get(getFilesUrl);

      if (getFilesResponse.statusCode == 200) {
        final List<dynamic> fileList = json.decode(getFilesResponse.body);
        setState(() {
          _fileHistory = fileList.cast<String>();
          _isHistoryLoading = false;
        });
      } else {
        throw Exception('Failed to load file history');
      }
    } catch (e) {
      print("Error fetching file history: $e");
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  Future<void> _handleConvertToJson() async {
    try {
      final getUploadUrl = Uri.parse(
        '$apiEndpointUrl/files/$_selectedFileName/upload',
      );
      final getResponse = await http.get(getUploadUrl);

      if (getResponse.statusCode != 200) {
        throw Exception('Error getting upload URL: ${getResponse.body}');
      }

      final getResponseData = json.decode(getResponse.body);
      final String presignedUploadUrl = getResponseData['uploadUrl'];

      setState(() {
        _isLoading = true;
        _outputText = "Uploading file...";
        _isJsonReady = false;
      });

      final putResponse = await http.put(
        Uri.parse(presignedUploadUrl),
        body: _selectedFileBytes,
        headers: {'Content-Type': 'text/csv'},
      );

      if (putResponse.statusCode != 200) {
        throw Exception('Error uploading file: ${putResponse.body}');
      }

      setState(() {
        _outputText = "File uploaded successfully. Awaiting processing...";
      });

      final String sourceFileName = _selectedFileName!;
      final String expectedJsonFileName =
          '${sourceFileName.substring(0, sourceFileName.lastIndexOf('.'))}.json';

      Timer.periodic(const Duration(seconds: 3), (timer) async {
        try {
          final getFilesUrl = Uri.parse('$apiEndpointUrl/files');
          final getFilesResponse = await http.get(getFilesUrl);

          if (getFilesResponse.statusCode != 200) {
            print('Polling failed, will retry: ${getFilesResponse.body}');
            return;
          }

          final List<dynamic> fileList = json.decode(getFilesResponse.body);
          setState(() {
            _fileHistory = fileList.cast<String>();
          });

          if (fileList.contains(expectedJsonFileName)) {
            timer.cancel();
            setState(() {
              _outputText = "File converted! Downloading result...";
            });

            final getDownloadUrl = Uri.parse(
              '$apiEndpointUrl/files/$expectedJsonFileName/download',
            );
            final getDownloadResponse = await http.get(getDownloadUrl);

            if (getDownloadResponse.statusCode != 200) {
              throw Exception(
                'Error getting download URL: ${getDownloadResponse.body}',
              );
            }

            final String presignedDownloadUrl = json.decode(
              getDownloadResponse.body,
            )['downloadUrl'];
            final getContentResponse = await http.get(
              Uri.parse(presignedDownloadUrl),
            );

            if (getContentResponse.statusCode != 200) {
              throw Exception(
                'Error downloading file content: ${getContentResponse.body}',
              );
            }

            final jsonContent = json.decode(getContentResponse.body);
            const JsonEncoder encoder = JsonEncoder.withIndent('  ');
            final String prettyJson = encoder.convert(jsonContent);

            setState(() {
              _outputText = prettyJson;
              _isLoading = false;
              _isJsonReady = true;
            });
          } else {
            print("Polling: File not found yet.");
          }
        } catch (e) {
          timer.cancel();
          setState(() {
            _outputText = "An error occurred after upload: $e";
            _isLoading = false;
            _isJsonReady = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _outputText = "An error occurred: $e";
        _isLoading = false;
        _isJsonReady = false;
      });
    }
  }

  void _downloadJson() {
    final String jsonText = _outputText;

    final String downloadFileName = _selectedFileName != null
        ? '${_selectedFileName!.substring(0, _selectedFileName!.lastIndexOf('.'))}.json'
        : 'converted.json';

    final bytes = utf8.encode(jsonText);

    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json;charset=utf-8'),
    );

    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = downloadFileName;

    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _outputText));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('JSON copied to clipboard!')));
  }

  Future<void> _handleHistoryFileTap(String fileName) async {
    setState(() {
      _outputText = "Fetching $fileName...";
      _isLoading = true;
      _isJsonReady = false;
    });

    try {
      final getDownloadUrl = Uri.parse(
        '$apiEndpointUrl/files/$fileName/download',
      );
      final getDownloadResponse = await http.get(getDownloadUrl);

      if (getDownloadResponse.statusCode != 200) {
        throw Exception(
          'Error getting download URL: ${getDownloadResponse.body}',
        );
      }

      final String presignedDownloadUrl = json.decode(
        getDownloadResponse.body,
      )['downloadUrl'];
      final getContentResponse = await http.get(
        Uri.parse(presignedDownloadUrl),
      );

      if (getContentResponse.statusCode != 200) {
        throw Exception(
          'Error downloading file content: ${getContentResponse.body}',
        );
      }

      final jsonContent = json.decode(getContentResponse.body);
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final String prettyJson = encoder.convert(jsonContent);

      setState(() {
        _outputText = prettyJson;
        _isLoading = false;
        _isJsonReady = true;

        _selectedFileName = fileName.replaceAll('.json', '.csv');
      });
    } catch (e) {
      setState(() {
        _outputText = "An error occurred: $e";
        _isLoading = false;
        _isJsonReady = false;
      });
    }
  }

  Future<void> _downloadHistoryFile(String fileName) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting download for $fileName...')),
    );

    try {
      final getDownloadUrl = Uri.parse(
        '$apiEndpointUrl/files/$fileName/download',
      );
      final getDownloadResponse = await http.get(getDownloadUrl);

      if (getDownloadResponse.statusCode != 200) {
        throw Exception(
          'Error getting download URL: ${getDownloadResponse.body}',
        );
      }

      final String presignedDownloadUrl = json.decode(
        getDownloadResponse.body,
      )['downloadUrl'];
      final getContentResponse = await http.get(
        Uri.parse(presignedDownloadUrl),
      );

      if (getContentResponse.statusCode != 200) {
        throw Exception(
          'Error downloading file content: ${getContentResponse.body}',
        );
      }

      final bytes = getContentResponse.bodyBytes;
      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: 'application/json;charset=utf-8'),
      );

      final url = web.URL.createObjectURL(blob);

      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = fileName;

      web.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(url);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error downloading file: $e')));
    }
  }

  Future<void> _handleUploadCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
      withData: true, 
    );

    if (result != null && result.files.isNotEmpty) {
      final platformFile = result.files.first;

      if (platformFile.bytes != null) {
        setState(() {
          _selectedFileName = platformFile.name;
          _selectedFileBytes = platformFile.bytes;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff101922),
      appBar: AppBar(
        title: const Text('hertelendymm'),
        backgroundColor: Color(0xff101922),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.light_mode),
          //   onPressed: () {
          //     /// TODO: I could add light/dark mode togle later
          //   },
          // ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [const Text(
                'CSV to JSON Convert',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Text(
                'A simple and free tool to convert your CSV data into JSON format.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              DropTarget(
                onDragDone: (detail) async {
                  final file = detail.files.first;

                  final bytes = await file.readAsBytes();

                  setState(() {
                    _selectedFileName = file.name;
                    _selectedFileBytes = bytes;
                  });
                },
                onDragEntered: (detail) => setState(() => _isDragOver = true),
                onDragExited: (detail) => setState(() => _isDragOver = false),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: DottedBorder(
                    options: RectDottedBorderOptions(
                      color: _isDragOver ? Colors.blue : Color(0xff324d67),
                      strokeWidth: 6,
                      dashPattern: const [8.0, 4.0],
                    ),

                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: _isDragOver
                          ? Colors.blue.shade700
                          : Color(0xff101922),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.upload_file,
                              size: 40,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Drag & drop your CSV file here or',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _selectedFileName ?? 'No file selected',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedFileName != null
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: _selectedFileName != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // ElevatedButton(
                            //   onPressed:  _handleUploadCsv,
                            //   // () {
                            //   ///   TODO: I should add a file picker later OR remove/hide the button
                            //   // },
                            //   style: ElevatedButton.styleFrom(
                            //     elevation: 0.0,
                            //     shadowColor: Colors.transparent,
                            //     shape: RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(8.0),
                            //     ),
                            //     backgroundColor: Color(0xff233648),
                            //   ),
                            //   child: Text(
                            //     'Upload CSV',
                            //     style: TextStyle(
                            //       color: Colors.white,
                            //       fontWeight: FontWeight.bold,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 0.0,
                  shadowColor: Colors.transparent,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),

                onPressed: (_isLoading || _selectedFileBytes == null)
                    ? null
                    : _handleConvertToJson,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Convert to JSON',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: TextEditingController(text: _outputText),
                maxLines: 10,
                readOnly: true,
                decoration: InputDecoration(
                  // labelStyle: TextStyle(fontSize: 2, color: Colors.red),
                  border: const OutlineInputBorder(),
                  hintText: 'Your JSON output will appear here...',
                  suffixIcon: Column(
                    mainAxisSize: MainAxisSize.min,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: _isJsonReady ? _downloadJson : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _isJsonReady ? _copyToClipboard : null,
                      ),
                    ],
                  ),
                ),
              ),
              // TextField(),

              const SizedBox(height: 40),

              Text(
                // 'File Listings',
                'History',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _isHistoryLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _fileHistory.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xff233648),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('No converted files found.'),
                      ),
                    )
                  : Container(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _fileHistory.length,
                        itemBuilder: (context, index) {
                          final fileName = _fileHistory[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              tileColor: const Color(0xff233648),
                              title: Text(fileName),
                              trailing: IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () {
                                  _downloadHistoryFile(fileName);
                                },
                              ),
                              onTap: () {
                                _handleHistoryFileTap(fileName);
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
