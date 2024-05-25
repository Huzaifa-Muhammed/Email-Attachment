import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> attachment = [];

  @override
  void initState() {
    super.initState();
  }

  final _recipientController = TextEditingController();

  final _subjectController = TextEditingController(text: 'The subject');

  final _bodyController = TextEditingController(text: 'Mail body.',);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> send() async {
    final Email email = Email(
      body: _bodyController.text,
      subject: _subjectController.text,
      recipients: [_recipientController.text],
      attachmentPaths: attachment,
    );

    String platformResponse;

    try {
      await FlutterEmailSender.send(email);
      platformResponse = 'success';
    } catch (error) {
      platformResponse = error.toString();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(platformResponse),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Send Email Attachment'),
        actions: <Widget>[
          IconButton(
            onPressed: send,
            icon: const Icon(Icons.send),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _recipientController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Recipient',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Subject',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _bodyController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                        labelText: 'Body', border: OutlineInputBorder()),
                  ),
                ),
                buildAttachmentPreview(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.attach_file),
        label: const Text('Add Attachment'),
        onPressed: _openAttachmentPicker,
      ),
    );
  }

  void _openAttachmentPicker() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        attachment.add(result.files.single.path!);
      });
    }
  }

  Widget buildAttachmentPreview() {
    return Column(
      children: attachment.map((filePath) {
        final fileExtension = filePath.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
          return Image.file(File(filePath), height: 100, width: 100);
        } else if (['mp4', 'mov', 'avi'].contains(fileExtension)) {
          return FutureBuilder<String?>(
            future: VideoThumbnail.thumbnailFile(
              video: filePath,
              imageFormat: ImageFormat.PNG,
              maxWidth: 128,
              quality: 25,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                return Image.file(File(snapshot.data!), height: 100, width: 100);
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                return Icon(Icons.broken_image, size: 100);
              }
            },
          );
        } else {
          return Icon(Icons.insert_drive_file, size: 100);
        }
      }).toList(),
    );
  }
}
