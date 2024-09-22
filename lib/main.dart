import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:html' as html;

import 'ReferenceItem.dart'; // TODO Make it available for desktop? Works only for the web right now.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class ReferenceItemWidget extends StatefulWidget {

  final ReferenceItem referenceItem;
  final Function onCancelButtonPressed;
  final Function onSaveButtonPressed;
  final Function? onDeleteButtonPressed;

  const ReferenceItemWidget({
    super.key,
    required this.referenceItem,
    required this.onCancelButtonPressed,
    required this.onSaveButtonPressed,
    this.onDeleteButtonPressed,
  });

  @override
  ReferenceItemWidgetState createState() => ReferenceItemWidgetState();
}

class ReferenceItemWidgetState extends State<ReferenceItemWidget> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add A New Reference"),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            widget.onCancelButtonPressed();

            // Navigation is done inside the function above
            // because the async code is simpler.
            // This is not allowed without await above and some additional async code I haven't investigated yet..:
            // Navigator.of(context).pop(); // Navigate back to the page before
          }
          )
      ),
      body: Center(
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                widget.onSaveButtonPressed(); // save reference item
              },
              child: Text("Save")
            ),
            // Delete button if requested
            if (widget.onDeleteButtonPressed case var onDeleteButtonPressed?)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: (){
                  onDeleteButtonPressed();
                }, 
              ),
            Row(
              children: [
                Text("Title: "),
                Expanded(child: TextFormField(
                    initialValue: widget.referenceItem.title,
                    onChanged: (value) {
                      setState(() {
                        widget.referenceItem.title = value;
                      });
                    },
                ))
              ],
              // TextFormField(initialValue: "test",),
            ),
            // Title
            Row(
              children: [
                Text("Authors: "),
                  Expanded(child: TextFormField(
                    initialValue: widget.referenceItem.authors,
                    onChanged: (value) {
                      setState(() {
                        widget.referenceItem.authors = value;
                      });
                    },
                  ))
              ]
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Load PDF
                  ByteData data = await rootBundle.load("assets/sample.pdf");
                  Uint8List bytes = data.buffer.asUint8List();

                  // Works only for the web app

                  final blob = html.Blob([bytes], 'application/pdf');
                  final url  = html.Url.createObjectUrlFromBlob(blob);

                  html.window.open(url, "_blank"); // Open in new tab

                  html.Url.revokeObjectUrl(url); // Free the memory
                } catch (e) {
                  print("Error loading PDF: $e");
                }
              },
              child: Text("Show PDF")
            )
          ]
        )
      )
    );
  }
}

Future<bool?> _popConfirmationDialog (BuildContext context) async {

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title:   Text('Abandon Edit?'),
        content: Text('Do you really want to abandon the edit?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('Stay safe')
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Abandon edit')
          ),
        ]
      );
    }
  );
}

void _popIfFine(
  ReferenceItem itemOriginal,
  ReferenceItem itemEdited,
  context) async {

  if (! itemEdited.matches(itemOriginal)) {
    // user edited this reference => ask the user

    bool? doAbandon = await _popConfirmationDialog(context); // Abandon the edit? 

    if (!context.mounted) {return;} // Dialog failed => do nothing

    if (doAbandon != true) {return;} // Don't abandon edit
  }

  Navigator.of(context).pop(); // Abandon edit (i.e. close the child widget)
}

Future<Navigator?> _navigateEditRoute({
  required ReferenceItem itemOriginal,
  required BuildContext context,
  required Function deleteItem, // Delete a new item
  Function? onSave, // Designed for adding a new item
  }) {

  var itemForEdit   = itemOriginal.clone();

  return Navigator.push(
    context,
    MaterialPageRoute(builder: 
      (context) =>
      PopScope(
        canPop: false, // Take control of the "back" feature managed by the system, like Android back button, iOS back swipe, etc.

        // Back is clicked, instead of save!
        // Before throwing away data, get user confirmation.

        child: ReferenceItemWidget(
          referenceItem: itemForEdit,
          onCancelButtonPressed: () {
            _popIfFine(itemOriginal, itemForEdit, context);
            // ^ This also navigates back to the page before if the user confirms it.
          },
          onSaveButtonPressed: (){
            itemOriginal.copyPropertiesFrom(itemForEdit);
            if (onSave != null) {onSave();}
            Navigator.of(context).pop(); // Navigate back to the page before
          },
          onDeleteButtonPressed:
            () async {
              final bool? doDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete This Item?'),
                  actions: [
                    TextButton(
                      onPressed: () {Navigator.of(context).pop(false);},
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {Navigator.of(context).pop(true);},
                      child: Text('Delete'),
                    ),
                  ]
                )
              );
              if (!context.mounted) {return;}

              if (doDelete ?? false) {
                Navigator.of(context).pop(); // Navigate back to the page before
                deleteItem(itemOriginal);
              }
            }
        )
      )
    )
  );
}

class _ExplorerWidget extends StatefulWidget {

  final List<ReferenceItem> allItems;
  final Function deleteItem;

  const _ExplorerWidget({
    super.key,
    required this.allItems,
    required this.deleteItem,
  });

  @override
  _ExplorerState createState() => _ExplorerState();
}

class _ExplorerState extends State<_ExplorerWidget> {

  List<ReferenceItem> _filteredItems = [];

  // TODO remove this
  @override
  void initState() {
    super.initState();
    _filterItems("");
  }

  void _filterItems(String query) {

    List<ReferenceItem> items = widget.allItems;

    if (query.isNotEmpty) {
      // Filter items
      items = items.where((item) {
        return item.title.toLowerCase().contains(query.toLowerCase());
      })
      .toList();
    }

    setState(() {
      _filteredItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(

      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[

        TextField(
          onChanged: (text) {
            _filterItems(text); // Perform search on text change
          },
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),

        Expanded (
          child:
            ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_filteredItems[index].title),
                  trailing:
                    ElevatedButton(
                      onPressed: () {
                        _navigateEditRoute(
                          itemOriginal: _filteredItems[index],
                          context: context,
                          deleteItem: widget.deleteItem
                          ).then(
                          (_){setState(() { });} // reload this page after coming back from the page
                        );
                      },
                      child: Text("Go"))
                );
              },
            )
        )
    ],);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<ReferenceItem> _allItems = [
    ReferenceItem(
      title: "Test Title",
      authors: "Test Author",
    ),
    ReferenceItem(
      title: "Test Title 01",
      authors: "Test Author 01",
    ),
    ReferenceItem(
      title: "Test Title 02",
      authors: "Test Author",
    ),
  ];


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body:
        _ExplorerWidget(
          allItems: _allItems,
          deleteItem: (item) {
            _allItems.remove(item);
            
            setState(() { }); // TODO is this fine?
          }
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          var newItem = ReferenceItem();
          _navigateEditRoute( // go to another page
            itemOriginal: newItem,
            context: context,
            onSave: () { _allItems.add(newItem); },
            deleteItem: (item){} // no modification to _allItems is needed
          ).then(
            (_){setState((){});} // reload this page after coming back from the page
          );
        },
        tooltip: 'Add a new reference',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
