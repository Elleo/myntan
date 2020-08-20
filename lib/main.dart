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
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:dart_random_choice/dart_random_choice.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';

bool syncAvailable = true;

List<ColorSwatch<dynamic>> colorSet = [
    Colors.brown,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.yellow,
    Colors.blue,
    Colors.cyan,
    Colors.grey,
];

void main() {
    runApp(Myntan());
}

String datestr() {
    var now = new DateTime.now().toUtc();
    String y = now.year.toString().padLeft(4, '0');
    String m = now.month.toString().padLeft(2, '0');
    String d = now.day.toString().padLeft(2, '0');
    String h = now.hour.toString().padLeft(2, '0');
    String min = now.minute.toString().padLeft(2, '0');
    String sec = now.second.toString().padLeft(2, '0');
    return "$y-$m-$d $h:$min:$sec +0000";
}

Future<Directory> getStorageDir() async {
    Directory storageDir = new Directory('/home/' + Platform.environment['LOGNAME'] + '/Dropbox/Apps/Mindly');
    if (!storageDir.existsSync()) {
        syncAvailable = false;
        if (Platform.environment.containsKey('XDG_DATA_HOME')) {
            storageDir = new Directory(Platform.environment['XDG_DATA_HOME'] + "/Myntan");
        } else {
            storageDir = new Directory(Platform.environment['HOME'] + "/Documents/Myntan");
        }
        storageDir = await storageDir.create(recursive: true);
    }

    return storageDir;
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
    if (colorStr.startsWith("purple"))    return Colors.purple[variant];
    if (colorStr.startsWith("grey"))    return Colors.grey[variant];
    if (colorStr.startsWith("brown"))    return Colors.brown[variant];
    if (colorStr.startsWith("black"))   return Colors.black;
    if (colorStr.startsWith("white"))   return Colors.white;
    return Colors.white;
}

String colorToStr(Color color) {
    if (color == Colors.pink)       return "pink0";
    if (color == Colors.cyan)       return "cyan0";
    if (color == Colors.red)        return "red0";
    if (color == Colors.yellow)     return "yellow0";
    if (color == Colors.orange)     return "orange0";
    if (color == Colors.green)      return "green0";
    if (color == Colors.blue)       return "blue0";
    if (color == Colors.indigo)     return "indigo0";
    if (color == Colors.purple)     return "purple0";
    if (color == Colors.brown)     return "brown0";
    if (color == Colors.grey)     return "grey0";
    if (color == Colors.black)      return "black0";
    if (color == Colors.white)      return "white0";
    return "white0";
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
    List _docs = new List();
    bool _dirty = true;

    void _addMindMap() {
        final _controller = TextEditingController();
        Color _color = randomChoice(colorSet);

        Future<void> processInput() async {
            String id = Uuid().v1();
            var dateStr = datestr();

            var doc = {
                'ideaDocumentDataObject': {
                    'fileFormatVersion': 4,
                    'dateCreated': dateStr,
                    'dateModified': dateStr,
                    'idea': {
                        'ideaType': 1,
                        'text': _controller.text,
                        'identifier': id,
                        'note': '',
                        'color': colorToStr(_color),
                        'colorThemeType': 0,
                        'ideas': []
                    }
                }
            };

            Directory storageDir = await getStorageDir();

            var f = File(storageDir.path + "/" + id + ".mndl");
            var compressed = zlib.encode(utf8.encode(json.encode(doc)));
            f.writeAsBytes(compressed);
            var indexFile = File(storageDir.path + "/mindly.index");
            var index = json.decode(indexFile.readAsStringSync());
            var proxy = {
                'identifier': doc['identifier'],
                'text': doc['text'],
                'color': doc['color'],
                'hasNote': false,
                'hasWebLink': false,
                'dateCreated': dateStr,
                'dateModified': dateStr,
                'itemCount': 1,
                'filename': id + ".mndl",
            };
            index['proxies'].add(proxy);
            indexFile.writeAsString(json.encode(index));
            Navigator.of(context).pop();
            _dirty = true;
            _refresh();
        }

        showDialog(
            context: context,
            builder: (_) => new AlertDialog(
                contentPadding: const EdgeInsets.all(16.0),
                content: Container(height: 140, child: Wrap(
                    runSpacing: 20,
                    children: <Widget>[
                        TextField(
                            controller: _controller,
                            autofocus: true,
                            onSubmitted: (input) { processInput(); },
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "New Mind Map...",
                            ),
                        ),
                        Container(height: 120,
                                child: MaterialColorPicker(
                                        allowShades: false,
                                        selectedColor: _color,
                                        colors: colorSet,
                                        onMainColorChange: (Color color) {
                                            _color = color;
                                        },
                                ),
                        ),
                    ],
                )),
                actions: <Widget>[
                    FlatButton(
                        child: Text('Cancel'),
                        onPressed: () {
                            Navigator.of(context).pop();
                        },
                    ),
                    FlatButton(
                        child: Text('Create Mind Map'),
                        onPressed: processInput
                    ),
                ],
            ),
        );
    }

    Future<void> _loadFiles() async {
        Directory storageDir = await getStorageDir();
        List oldDocs = _docs;
        _docs = new List();
        var files = storageDir.listSync(recursive: false, followLinks: true);
        for (FileSystemEntity entity in files) {
            if (entity.path.endsWith(".mndl")) {
                var f = File(entity.path);
                var bytes = f.readAsBytesSync();
                var inflated = zlib.decode(bytes);
                var data = utf8.decode(inflated);
                var doc = json.decode(data);
                doc['filename'] = f.path;
                _docs.add(doc);
            }
        }

        if (_dirty) {
            _refresh();
            _dirty = false;
        }
    }

    Future<void> _refresh() async {
        setState(() { });
    }

    Future<void> _showDialog() async {
        return showDialog<void>(
            context: context,
            builder: (BuildContext context) {
                return AlertDialog(
                    title: Text('Enable Synchronisation'),
                    content: SingleChildScrollView(
                        child: Text("To synchronise with Mindly first install the Dropbox client and then ensure you're synchronising the 'Apps/Mindly' folder."),
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

        if (!syncAvailable) {
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
                onRefresh: () {
                    _dirty = true;
                    return _refresh();
                },
                child: Center(
                    child: AspectRatio(
                        aspectRatio: 1,
                        child: GridView.count(
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            crossAxisCount: 2,
                            children: _docs.map<Widget>((doc) {
                                return Idea(
                                    mindmap: doc,
                                    idea: doc['ideaDocumentDataObject']['idea'],
                                    center: false,
                                    large: true,
                                    parent: this,
                                );
                            }).toList(),
                        ),
                    ),
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
        @required this.mindmap,
        @required this.idea,
        this.center,
        this.large,
        this.parent,
    }) : super (key: key);

    var mindmap;
    var idea;
    bool center = false;
    bool large = false;
    var parent;

    Object getIdea(String searchId, var searchMap) {
        if (searchMap['identifier'] == searchId) {
            return searchMap;
        }
        if (searchMap.containsKey("ideas")) {
            for (Object idea in searchMap['ideas']) {
                var result = getIdea(searchId, idea);
                if (result != null) {
                    return result;
                }
            }
        }
        return null;
    }

    @override
    Widget build(BuildContext context) {
        if (this.idea == null) {
            return GridTile(
                child: Text(""),
            );
        }
        if (this.idea['ideaType'] == 4) {
            this.idea = this.getIdea(this.idea['linkedIdea'], this.mindmap['ideaDocumentDataObject']['idea']);
        }
        String title = this.idea['text'];
        if (this.idea['iconImage'] != null) {
            if (this.idea['iconImage']['symbol'] != null) {
                title = this.idea['iconImage']['symbol'] + " " + title;
            } else if (this.idea['iconImage']['category'] != null) {
                title = "[" + this.idea['iconImage']['category'] + "] " + title;
            }
        }
        if (this.idea['note'] != null && this.idea['note'] != "") {
            title = title += "\n\n📝";
        }
        var displayChild;
        if (this.idea.containsKey('bigImageData')) {
            var bytes = base64.decode(this.idea['bigImageData'].replaceAll("\n", ""));
            displayChild = ClipOval(child: Image.memory(bytes));
        } else {
            displayChild = Text(title,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'EmojiOne', fontSize: this.large ? 18 : 14),
                            );
        }
        return GridTile(
            child: GestureDetector(
                onTap: () {
                    if (!this.center) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => IdeaPage(mindmap: this.mindmap, idea: this.idea)),
                        ).then((value) {
                            parent.setState(() { });
                        });
                    }
                },
                child: Center(child: Container(
                    height: this.large ? 256 : 128,
                    width: this.large ? 256 : 128,
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
                ),),
            ),
        );
    }
}

class IdeaPage extends StatefulWidget {
    IdeaPage({Key key, this.mindmap, this.idea}) : super(key: key);

    final mindmap;
    final idea;

    @override
    _IdeaPageState createState() => _IdeaPageState();
}

class _IdeaPageState extends State<IdeaPage> {

    int _count(var idea) {
        int count = 1;
        if (idea.containsKey('ideas')) {
            for (var idea2 in idea['ideas']) {
                count += _count(idea2);
            }
        }
        return count;
    }

    void _save() {
        var f = File(widget.mindmap['filename']);
        widget.mindmap.remove('filename');
        var compressed = zlib.encode(utf8.encode(json.encode(widget.mindmap)));
        f.writeAsBytesSync(compressed);
        widget.mindmap['filename'] = f.path;
        var indexFile = File(f.parent.path + "/mindly.index");
        var index = json.decode(indexFile.readAsStringSync());
        bool found = false;
        var idea = widget.mindmap['ideaDocumentDataObject']['idea'];
        var itemCount = _count(idea);
        var dateStr = datestr();
        for(var proxy in index['proxies']) {
            if (proxy['identifier'] == idea['identifier']) {
                found = true;
                proxy['text'] = idea['text'];
                if (idea.containsKey('iconImage')) {
                    proxy['iconImage'] = idea['iconImage'];
                } else if (proxy.containsKey('iconImage')) {
                    proxy.remove('iconImage');
                }
                proxy['dateModified'] = dateStr;
                proxy['itemCount'] = itemCount;
            }
        }
        if (!found) {
            var proxy = {
                'identifier': idea['identifier'],
                'text': idea['text'],
                'color': idea['color'],
                'hasNote': idea['hasNote'],
                'hasWebLink': idea['hasWebLink'],
                'dateCreated': dateStr,
                'dateModified': dateStr,
                'itemCount': itemCount,
                'filename': f.path.split('/').last,
            };
            index['proxies'].add(proxy);
        }
        indexFile.writeAsStringSync(json.encode(index));
    }

    void _edit() {
        final _controller = TextEditingController();
        _controller.text = widget.idea['text'];

        void processInput() {
            widget.idea['text'] = _controller.text;
            _save();
            setState(() { });
            Navigator.of(context).pop();
        };

        showDialog(
            context: context,
            builder: (_) => new AlertDialog(
                contentPadding: const EdgeInsets.all(16.0),
                content: TextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (input) { processInput(); },
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Edit Idea...",
                    ),
                ),
                actions: <Widget>[
                    FlatButton(
                        child: Text('Cancel'),
                        onPressed: () {
                            Navigator.of(context).pop();
                        },
                    ),
                    FlatButton(
                        child: Text('Edit'),
                        onPressed: processInput,
                    ),
                ],
            ),
        );
    }

    void _addIdea() {
        final _controller = TextEditingController();

        void processInput() {
            var newIdea = {
                'identifier': Uuid().v1(),
                'text': _controller.text,
                'ideaType': 1,
                'color': widget.idea['color'],
                'colorThemeType': 1,
                'ideas': [],
            };
            if (widget.idea.containsKey('ideas')) {
                widget.idea['ideas'].add(newIdea);
            } else {
                widget.idea['ideas'] = [newIdea];
            }
            _save();
            setState(() { });
            Navigator.of(context).pop();
        };

        showDialog(
            context: context,
            builder: (_) => new AlertDialog(
                contentPadding: const EdgeInsets.all(16.0),
                content: TextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (input) { processInput(); },
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "New Idea...",
                    ),
                ),
                actions: <Widget>[
                    FlatButton(
                        child: Text('Cancel'),
                        onPressed: () {
                            Navigator.of(context).pop();
                        },
                    ),
                    FlatButton(
                        child: Text('Add Idea'),
                        onPressed: processInput,
                    ),
                ],
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        int gridSize = 3;
        List ideas = new List();
        List unsortedIdeas = new List();
        if (widget.idea.containsKey('ideas')) {
            if (widget.idea['ideas'].length > 4) {
                gridSize = 5;
            }
            if (widget.idea['ideas'].length > 12) {
                gridSize = 7;
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
        } else if (gridSize == 7) {
            ideas[24] = widget.idea;
        }

        var appBar = AppBar(
            backgroundColor: strToColor(widget.idea['color']),
            title: Text(widget.idea['text']),
            actions: [
                IconButton(
                        icon: Icon(Icons.edit),
                        tooltip: "Edit",
                        onPressed: _edit,
                ),
            ],
        );
        if (widget.idea.containsKey('bigImageData')) {
            var bytes = base64.decode(widget.idea['bigImageData'].replaceAll("\n", ""));
            appBar = AppBar(
                backgroundColor: strToColor(widget.idea['color']),
            );
        }
        return Scaffold(
            appBar: appBar,
            body: Center(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.count(
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        crossAxisCount: gridSize,
                        children: ideas.map<Widget>((idea) {
                            return Idea(
                                mindmap: widget.mindmap,
                                idea: idea,
                                center: idea == widget.idea,
                                large: idea == widget.idea,
                                parent: this,
                            );
                        }).toList(),
                    ),
                ),
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: _addIdea,
                tooltip: 'New Idea',
                child: Icon(Icons.add),
            )
        );
    }

}
