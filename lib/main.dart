/*
 * Copyright 2020 Mike Sheldon <mike@mikeasoft.com>
 *
 * This file is part Myntan.
 *
 * Myntan is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Myntan is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:io';
import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

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
            debugShowCheckedModeBanner: false,
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
    List _ideas = new List();
    bool _syncAvailable = true;

    void _addMindMap() {

    }

    Future<void> _loadFiles() async {
        Directory storageDir = new Directory('/home/' + Platform.environment['LOGNAME'] + '/Dropbox/Apps/Mindly/fail');
        if (!storageDir.existsSync()) {
            _syncAvailable = false;
            if (Platform.environment.containsKey('XDG_DATA_HOME')) {
                storageDir = new Directory(Platform.environment['XDG_DATA_HOME'] + "/Myntan");
            } else {
                storageDir = new Directory(Platform.environment['HOME'] + "/Documents/Myntan");
            }
            storageDir = await storageDir.create(recursive: true);
        }
        _ideas = new List();
        var files = storageDir.listSync(recursive: false, followLinks: true);
        for (FileSystemEntity entity in files) {
            if (entity.path.endsWith(".mndl")) {
                var f = File(entity.path);
                var bytes = f.readAsBytesSync();
                var inflated = zlib.decode(bytes);
                var data = utf8.decode(inflated);
                _ideas.add(json.decode(data)['ideaDocumentDataObject']['idea']);
            }
        }
    }

    Future<void> _refresh() async {
        setState(() { });
    }

    Future<void> _showDialog() async {
        String snapMessage = "";
        if (Platform.environment.containsKey('SNAP')) {
            snapMessage = "\n\nTo give the Myntan snap permission to access your Dropbox folder, open a terminal and run:\n\nsnap connect dropbox-sync:myntan";
        }
        return showDialog<void>(
            context: context,
            builder: (BuildContext context) {
                return AlertDialog(
                    title: Text('Enable Synchronisation'),
                    content: SingleChildScrollView(
                        child: Text("To synchronise with Mindly first install the Dropbox client and then ensure you're synchronising the 'Apps/Mindly' folder." + snapMessage),
                    ),
                    actions: <Widget>[
                        FlatButton(
                            child: Text('Close'),
                            onPressed: () {
                                _loadFiles();
                                Navigator.of(context).pop();
                            },
                        ),
                    ],
                );
            },
        );
    }

    @override
    Widget build(BuildContext context) {
        _loadFiles();
        List<Widget> actions = new List();

        if (!_syncAvailable) {
            Widget warningBtn = new IconButton(
                        icon: Icon(Icons.warning),
                        tooltip: "Synchronisation disabled, click to enable",
                        onPressed: _showDialog,
            );
            actions.add(warningBtn);
        }

        return Scaffold(
            appBar: AppBar(
                title: Text(widget.title),
                actions: actions,
            ),
            body: RefreshIndicator(
                onRefresh: _refresh,
                child: GridView.count(
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    crossAxisCount: 2,
                    children: _ideas.map<Widget>((idea) {
                        return Idea(
                            idea: idea
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

class Idea extends StatelessWidget {
    Idea({
        Key key,
        @required this.idea,
    }) : super (key: key);

    var idea;

    @override
    Widget build(BuildContext context) {
        if (idea == null) {
            return GridTile(
                child: Text(""),
            );
        }
        String title = this.idea['text'];
        if (this.idea['iconImage'] != null) {
            if (this.idea['iconImage']['symbol'] != null) {
                title = this.idea['iconImage']['symbol'] + " " + title;
            } else if (this.idea['iconImage']['category'] != null) {
                title = "[" + this.idea['iconImage']['category'] + "] " + title;
            }
        }
        var displayChild;
        if (this.idea.containsKey('bigImageData')) {
            var bytes = base64.decode(this.idea['bigImageData'].replaceAll("\n", ""));
            displayChild = ClipOval(child: Image.memory(bytes));
        } else {
            displayChild = Text(title,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            );
        }
        return GridTile(
            child: Center (
                child: GestureDetector(
                    onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => IdeaPage(idea: this.idea)),
                        );
                    },
                    child: Container(
                        height: 128,
                        width: 128,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: strToColor(this.idea['color']),
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
                            child: displayChild,
                        ),
                    ),
                ),
            ),
        );
    }
}

class IdeaPage extends StatefulWidget {
    IdeaPage({Key key, this.idea}) : super(key: key);

    final idea;

    @override
    _IdeaPageState createState() => _IdeaPageState();
}

class _IdeaPageState extends State<IdeaPage> {

    @override
    Widget build(BuildContext context) {
        int gridSize = 3;
        List ideas = new List();
        List unsortedIdeas = new List();
        if (widget.idea.containsKey('ideas')) {
            if (widget.idea['ideas'].length > 8) {
                gridSize = 5;
            }
            unsortedIdeas = widget.idea['ideas'];
        }

        for (int i = 0; i < gridSize * gridSize; i++) {
            ideas.add(null);
        }

        for (int i = 0; i < unsortedIdeas.length; i++) {
            if(i % 2 == 0) {
                ideas[i] = unsortedIdeas[i];
            } else {
                ideas[ideas.length - i] = unsortedIdeas[i];
            }
        }

        if (gridSize == 3) {
            ideas[4] = widget.idea;
        } else if (gridSize == 5) {
            ideas[12] = widget.idea;
        }

        var appBar = AppBar(
            backgroundColor: strToColor(widget.idea['color']),
            title: Text(widget.idea['text']),
        );
        if (widget.idea.containsKey('bigImageData')) {
            var bytes = base64.decode(widget.idea['bigImageData'].replaceAll("\n", ""));
            appBar = AppBar(
                backgroundColor: strToColor(widget.idea['color']),
            );
        }
        return Scaffold(
            appBar: appBar,
            body: GridView.count(
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    crossAxisCount: gridSize,
                    children: ideas.map<Widget>((idea) {
                        return Idea(
                            idea: idea
                        );
                    }).toList(),
            )
        );
    }

}
