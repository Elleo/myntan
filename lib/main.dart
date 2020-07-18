import 'dart:io';
import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
    runApp(Myntan());
}

Color strToColor(String colorStr) {
    RegExp exp = new RegExp(r"[a-z]+([0-9]+)");
    int variant = 500;
    if (exp.hasMatch(colorStr)) {
        variant = 800 - int.parse(exp.firstMatch(colorStr).group(1)) * 100;
    }
    if (colorStr.startsWith("pink"))    return Colors.pink[variant];
    if (colorStr.startsWith("cyan"))    return Colors.cyan[variant];
    if (colorStr.startsWith("red"))     return Colors.red[variant];
    if (colorStr.startsWith("yellow"))  return Colors.yellow[variant];
    if (colorStr.startsWith("orange"))  return Colors.orange[variant];
    if (colorStr.startsWith("green"))   return Colors.green[variant];
    if (colorStr.startsWith("blue"))    return Colors.blue[variant];
    if (colorStr.startsWith("indigo")
      || colorStr.startsWith("violet")) return Colors.indigo[variant];
    if (colorStr.startsWith("black"))   return Colors.black;
    if (colorStr.startsWith("white"))   return Colors.white;
    return Colors.white;
}

class Myntan extends StatelessWidget {
    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Myntan',
            theme: ThemeData(
                primarySwatch: Colors.blueGrey,
                visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: MenuPage(title: 'Myntan'),
        );
    }
}

class MenuPage extends StatefulWidget {
    MenuPage({Key key, this.title}) : super(key: key);

    final String title;

    @override
    _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
    List _items;

    void _addMindMap() {

    }

    Future<void> _loadFiles() async {
        Directory storageDir = new Directory(Platform.environment['HOME'] + '/Dropbox/Apps/Mindly/');
        if (!storageDir.existsSync()) {
            Directory docDir = await getApplicationDocumentsDirectory();
            storageDir = new Directory(docDir.path + "/Myntan");
            storageDir = await storageDir.create(recursive: true);
        }
        _items = new List();
        var files = storageDir.listSync(recursive: false, followLinks: true);
        for (FileSystemEntity entity in files) {
            if (entity.path.endsWith(".mndl")) {
                var f = File(entity.path);
                var bytes = f.readAsBytesSync();
                var inflated = zlib.decode(bytes);
                var data = utf8.decode(inflated);
                _items.add(json.decode(data));
            }
        }
    }

    Future<void> _refresh() async {
        setState(() { });
    }

    @override
    Widget build(BuildContext context) {
        _loadFiles();
        return Scaffold(
            appBar: AppBar(
                title: Text(widget.title),
            ),
            body: RefreshIndicator(
                onRefresh: _refresh,
                child: GridView.count(
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    crossAxisCount: 2,
                    children: _items.map<Widget>((mindmap) {
                        return MindMapSummary(
                            mindmap: mindmap
                        );
                    }).toList(),
                ),
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: _addMindMap,
                tooltip: 'New Mind Map',
                child: Icon(Icons.add),
            ),
        );
    }
}

class MindMapSummary extends StatelessWidget {
    MindMapSummary({
        Key key,
        @required this.mindmap,
    }) : super (key: key);

    var mindmap;

    @override
    Widget build(BuildContext context) {
        String title = this.mindmap['ideaDocumentDataObject']['idea']['text'];
        if (this.mindmap['ideaDocumentDataObject']['idea']['iconImage'] != null) {
            if (this.mindmap['ideaDocumentDataObject']['idea']['iconImage']['symbol'] != null) {
                title = this.mindmap['ideaDocumentDataObject']['idea']['iconImage']['symbol'] + " " + title;
            } else if (this.mindmap['ideaDocumentDataObject']['idea']['iconImage']['category'] != null) {
                title = "[" + this.mindmap['ideaDocumentDataObject']['idea']['iconImage']['category'] + "] " + title;
            }
        }
        return GridTile(
            child: Center (
                child: GestureDetector(
                    onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MindMapPage(mindmap: this.mindmap)),
                        );
                    },
                    child: Container(
                        height: 128,
                        width: 128,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: strToColor(this.mindmap['ideaDocumentDataObject']['idea']['color']),
                            boxShadow: [
                                BoxShadow(
                                    color: Colors.grey[400],
                                    blurRadius: 15.0,
                                    offset: Offset(5.0, 5.0),
                                    spreadRadius: 5.0
                                ),
                            ],
                        ),
                        child: Center(
                            child: Text(title,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                        ),
                    ),
                ),
            ),
        );
    }
}

class MindMapPage extends StatefulWidget {
    MindMapPage({Key key, this.mindmap}) : super(key: key);

    final mindmap;

    @override
    _MindMapPageState createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {

    @override
    Widget build(BuildContext context) {
         return Scaffold(
            appBar: AppBar(
                backgroundColor: strToColor(widget.mindmap['ideaDocumentDataObject']['idea']['color']),
                title: Text(widget.mindmap['ideaDocumentDataObject']['idea']['text']),
            ),
            body: Center(
            ),
        );
    }

}
