import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark, accentColor: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Image Classifier'),
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
    // Add more models if needed
  };

  String _csrfToken = '';
  String model = "";
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  List<dynamic> _result = [];

  @override
  void initState() {
    super.initState();
    _fetchCsrfToken();
  }

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }
  Future<void> _pickImageCamera() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }

  Future<void> _fetchCsrfToken() async {
    final response = await http.get(
      Uri.parse('https://porsche.bene.photos/classify'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _csrfToken =
            response.headers['set-cookie']!.split(';')[0].split('=')[1];
      });
    }
  }

  Future<void> _classifyImage() async {
    if (_image == null) {
      return;
    }

    final imageBytes = await _image!.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    print(_csrfToken);
    final response = await http.post(
      Uri.parse('https://porsche.bene.photos/classify_image/'),
      headers: {
        'Content-Type': 'application/json',
        'cookie': "csrftoken=$_csrfToken",
        "Referer": "https://porsche.bene.photos/classify",
        "x-csrftoken": _csrfToken
      },
      body: jsonEncode({'image_data': base64Image, "model_name": _selectedModel}),
    );
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setState(() {
        print(result);
        print(result.runtimeType);
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _image == null
                ? Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[900],
              ),
              child: Center(
                  child: Text(
                    'No image selected',
                    style: TextStyle(color: Colors.grey[400]),
                  )),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(_image!.path),
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image),
                  SizedBox(width: 8),
                  Text('Pick Image'),
                ],
              ),
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).accentColor,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImageCamera,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text("Take a picture"),
                ],
              ),
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).accentColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
                'Model:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            DropdownButton<String>(
              value: _selectedModel,
              icon: Icon(Icons.arrow_downward),
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
              onPressed: _classifyImage,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car),
                  SizedBox(width: 8),
                  Text('Classify Image'),
                ],
              ),
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).accentColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Result:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            _result.length > 0
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _result.map<Widget>((result) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result[0]} (${(result[1]).toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).accentColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: result[1] /100,
                            minHeight: 10,
                            backgroundColor: Colors.grey[700],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).accentColor),
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
