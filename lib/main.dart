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
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  String _result = '';

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }

  Future<void> _classifyImage() async {
    if (_image == null) {
      return;
    }

    final imageBytes = await _image!.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final response = await http.post(
      Uri.parse('https://porsche.bene.photos/classify_image'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'image_data': base64Image}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setState(() {
        _result = result.join(', ');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _image == null
              ? Text('No image selected')
              : Image.file(File(_image!.path)),
          TextButton(
            onPressed: _pickImage,
            child: Text('Pick Image'),
          ),
          TextButton(
            onPressed: _classifyImage,
            child: Text('Classify Image'),
          ),
          Text('Result: $_result'),
        ],
      ),
    );
  }
}
