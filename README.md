# 🏎️ PorscheInsight-CarClassification-AI App
This project is a Flutter app that uses three machine learning models to predict images of Porsche models. The models were created by [Flippchen](https://github.com/Flippchen/PorscheInsight-CarClassification-AI) and are hosted on a server.

## Installation
To run this app, clone the repository from GitHub and install all dependencies. Then, start the app by running the main.dart file.

## Download the app
You can download the app from the [Google Play Store](https://play.google.com/store/apps/details?id=de.flippchen.porscheinsight).

## Usage
Once the app is running, select an image of a Porsche model from the gallery or take a picture with the camera. Then, select one of the available models to classify the image.

After selecting a model, click the "Classify Image" button to predict the model of the Porsche in the image. The results will be displayed as a list of possible models with their respective confidence levels.

## Code
The Flutter code for the app is provided in the main.dart file. It uses the http and image_picker packages to send image data to the server and retrieve the classification results.

The app also uses the flutter_image_compress package to compress the image before sending it to the server, in order to reduce network usage and improve performance.