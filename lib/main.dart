import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          accentColor: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Porsche Classifier'),
        ),
        body: ImageClassifier(),
      ),
    );
  }
}

class ImageClassifier extends StatefulWidget {
  @override
  _ImageClassifierState createState() => _ImageClassifierState();
}

class _ImageClassifierState extends State<ImageClassifier> {
  String _selectedModel = 'car_type';
  // List of available models
  Map<String, String> _modelMap = {
    'car_type': 'Car Type',
    'specific_model_variants': 'Car Series',
    'all_specific_model_variants': 'All Model Variants',
  };

  String _csrfToken = '';
  String model = "";
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  List<dynamic> _result = [];
  bool _isloading = false;

  @override
  void initState() {
    super.initState();
    _fetchCsrfToken();
  }

  Future<void> _pickImage() async {
    try {
      final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _image = pickedImage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: ${e.toString()}")),
      );
    }
  }

  Future<void> _pickImageCamera() async {
    try {
      final pickedImage = await _picker.pickImage(source: ImageSource.camera);
      if (pickedImage != null) {
        setState(() {
          _image = pickedImage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error taking picture: ${e.toString()}")),
      );
    }
  }

  Future<void> _fetchCsrfToken() async {
    try {
      final response = await http.get(
        Uri.parse('https://classify.autos/classify'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _csrfToken =
          response.headers['set-cookie']!.split(';')[0].split('=')[1];
        });
      } else {
        throw Exception(
            "Error fetching CSRF token. Status code: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching CSRF token: ${e.toString()}")),
      );
    }
  }


  Future<void> _classifyImage() async {
    if (_image == null) {
      return;
    }
    setState(() {
      _isloading = true;
    });
    final imageBytes = await _image!.readAsBytes();
    final double imageSizeInKB = imageBytes.length / 1024;

    Uint8List processedImageBytes;
    debugPrint('Image size: $imageSizeInKB KB');
    if (imageSizeInKB > 500) {
      processedImageBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 300,
        minWidth: 300,
        quality: 70,
      );
    } else {
      processedImageBytes = imageBytes;
    }
    final base64Image = base64Encode(processedImageBytes);
    print(_csrfToken);
    try {
      final response = await http.post(
        Uri.parse('https://classify.autos/classify_image/'),
        headers: {
          'Content-Type': 'application/json',
          'cookie': "csrftoken=$_csrfToken",
          "Referer": "https://classify.autos/classify",
          "x-csrftoken": _csrfToken
        },
        body: jsonEncode(
            {'image_data': base64Image, "model_name": _selectedModel}),
      );
      setState(() {
        _isloading = false;
      });
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          print(result);
          print(result.runtimeType);
          _result = result;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error classifying image: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _image == null
                ? Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[900],
                      ),
                      child: Center(
                        child: Text(
                          'No image selected',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_image!.path),
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.image),
                  SizedBox(width: 8),
                  Text(
                    'Pick Image',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImageCamera,
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text(
                    "Take a picture",
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Model:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            DropdownButton<String>(
              value: _selectedModel,
              icon: const Icon(Icons.arrow_downward),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedModel = newValue!;
                });
              },
              items: _modelMap.entries
                  .map<DropdownMenuItem<String>>((MapEntry<String, String> entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: _isloading ? null : _classifyImage,
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.directions_car),
                  SizedBox(width: 8),
                  Text(
                    'Classify Image',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Result:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            _isloading
                ? Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: const CircularProgressIndicator(),
                    ),
                  )
                : _result.length > 0
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _result.map<Widget>((result) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${result[0]} (${(result[1]).toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: result[1] / 100,
                                      minHeight: 10,
                                      backgroundColor: Colors.grey[700],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : Text(
                        "Results will be displayed here",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[400],
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
