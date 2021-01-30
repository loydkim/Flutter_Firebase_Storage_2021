import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Storage',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Storage'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            return Center(child: Text('Firebase Init Error'));
          }
          // Once complete, show your application
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Flexible(
                    child: _buildBody(context),
                  ),
                ],
              ),
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takeImage,
        child: Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<firebase_storage.ListResult>(
      stream: Stream.fromFuture(firebase_storage.FirebaseStorage.instance.ref('images').listAll()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        if (snapshot.connectionState == ConnectionState.done) {
          if(snapshot.data.items.isEmpty) return Text("Please Add Image",style: Theme.of(context).textTheme.headline6,);
          return _buildList(context, snapshot.data);
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildList(BuildContext context, firebase_storage.ListResult snapshot) {
    return ListView(
        padding: const EdgeInsets.only(top: 20.0),
        children: snapshot.items.map((data) => _buildListItem(context, data)).toList()
    );
  }

  Widget _buildListItem(BuildContext context, firebase_storage.Reference data) {
    return FutureBuilder(
      future: data.getDownloadURL(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot){
        if(!snapshot.hasData) return Container();
        return Padding(
          key: ValueKey(data.name),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: ListTile(
              title: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data.name,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        IconButton(icon: Icon(Icons.delete), onPressed: (){
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text("Do you want to delete this image?"),
                                  actions: [
                                    FlatButton(onPressed: () {
                                      Navigator.pop(context);
                                    }, child: Text("No",style: TextStyle(color: Colors.grey),)),
                                    FlatButton(onPressed: () async{
                                      await firebase_storage.FirebaseStorage.instance.ref(data.fullPath).delete();
                                      Navigator.pop(context);
                                      setState(() { });
                                    }, child: Text("Yes"))
                                  ],
                                );
                              }
                          );
                        })
                      ],
                    ),
                  ),
                  Image.network(snapshot.data),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Future _takeImage() async {
    // Get image from gallery.
    var pickedFile = await picker.getImage(source: ImageSource.gallery);
    final File imageFile = File(pickedFile.path);
    _uploadImageToFirebase(imageFile);
  }

  Future<void> _uploadImageToFirebase(File imageFile) async {
    try {
      // Make random image name.
      int randomNumber = Random().nextInt(100000);
      String imageLocation = 'images/image$randomNumber.jpg';

      // Upload image to firebase.
      await firebase_storage.FirebaseStorage.instance
          .ref(imageLocation)
          .putFile(imageFile);
      setState(() { });
    }on FirebaseException catch (e) {
      print(e.code);
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(e.code),
            );
          }
      );
    }catch(e){
      print(e.message);
    }
  }
}