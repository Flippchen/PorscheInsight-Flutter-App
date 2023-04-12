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
      theme: ThemeData(primarySwatch: Colors.blue),
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
      body: jsonEncode({'image_data': base64Image, "model_name": "car_type"}),
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
                      color: Colors.grey[200],
                    ),
                    child: Center(child: Text('No image selected')),
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
              child: Text('Pick Image'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _classifyImage,
              child: Text('Classify Image'),
            ),
            SizedBox(height: 16),
            Text(
              'Result:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            _result.length > 0
                ? Row(
                    children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children:
                              _result.map((result) => Text(result[0])).toList(),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children:
                          _result.map((result) => Text(result[1].toString())).toList(),
                      )
                      ],
                    )
                : Text("Results will be displayed here"),
          ],
        ),
      ),
    );
  }
}
