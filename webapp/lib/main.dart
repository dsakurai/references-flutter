import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;
import 'package:references_models/models/reference_item.dart';
import 'dart:convert';
import 'login_app.dart';

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
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: const LoginApp.LoginWidget(),
    );
  }
}

// ReferenceItem and LazyByteData are defined in the shared references_models package

class ReferenceItemWidget extends StatefulWidget {

  final ReferenceItem referenceItem;
  final Function onCancelButtonPressed;
  final Function onSaveButtonPressed;

  const ReferenceItemWidget({
    super.key,
    required this.referenceItem,
    required this.onCancelButtonPressed,
    required this.onSaveButtonPressed,
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
            icon: Icon(Icons.arrow_back),
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
            Row( children: [
                Text("ID: "),
                Text( widget.referenceItem.id.value.toString())
              ],
            ),
            Row(
              children: [
                Text("Title: "),
                Expanded(child: TextFormField(
                    initialValue: widget.referenceItem.title.value,
                    onChanged: (value) {
                      setState(() {
                        widget.referenceItem.title.value = value;
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
                    initialValue: widget.referenceItem.authors.value,
                    onChanged: (value) {
                      setState(() {
                        widget.referenceItem.authors.value = value;
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
                  var pdf = LazyRecord<ByteData?>.withValue("document", data);
                  // print('hasChanged: ${pdf.hasChanged()}');

                  ByteData? dataLoaded = await pdf.value;
                  assert(dataLoaded != null);
                  Uint8List bytes = dataLoaded!.buffer.asUint8List();


                  final blob = web.Blob( [bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf') );

                  // Works only for the web app
                  final url = web.URL.createObjectURL(blob);
                  
                  if (false) {
                    // Open as blob in new tab
                    web.window.open(url, "_blank"); // Open in new tab
                  } else {
                    // Download the file

                    // Attempt to open in new tab/window.
                    final fileName = '_blank';

                    // Fallback: create an anchor element and force a download.
                    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
                    anchor.href = url;
                    anchor.download = fileName;
                    anchor.style.display = 'none';
                    web.document.body?.append(anchor);
                    anchor.click();
                    anchor.remove();
                  }

                  // Revoke URL on microtask (lets the browser use it first)
                  Future.microtask(() => web.URL.revokeObjectURL(url));
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

class _ExplorerWidget extends StatefulWidget {

  final List<ReferenceItem> allItems;

  const _ExplorerWidget({
    super.key,
    required this.allItems
  });

  @override
  _ExplorerState createState() => _ExplorerState();
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
  ReferenceItem itemEdited,
  context) async {

  if (itemEdited.hasChanged()) {
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
  Function? onSave, // Designed for adding a new item
  }) {

  var itemForEdit = ReferenceItem.from(itemOriginal);

  return Navigator.push(
    context,
    MaterialPageRoute(builder: 
      (context) =>
      PopScope(
        canPop: false, // Disable the back button from the system

        // Back is clicked, instead of save!
        // Before throwing away data,
        // get user confirmation to pop this widget

        child: ReferenceItemWidget(
          referenceItem: itemForEdit,
          onCancelButtonPressed: () {
            _popIfFine(itemForEdit, context);
            // ^ This also navigates back to the page before if the user confirms it.
          },
          onSaveButtonPressed: () async {
            final response = await http.get(Uri.parse('http://localhost:8080/api'));
            if (response.statusCode == 200) {
              print('Success: ${response.body}');
            } else {
              print('Error: ${response.statusCode}');
            }
          },
          )
      )
    )
  );
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
        return item.title.value.toLowerCase().contains(query.toLowerCase());
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
                  title: Text(_filteredItems[index].title.value),
                  trailing:
                    ElevatedButton(
                      onPressed: () {
                        _navigateEditRoute(
                          itemOriginal: _filteredItems[index],
                          context: context,
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
      0,
      title: "Test Title",
      authors: "Test Author",
    ),
    ReferenceItem(
      1,
      title: "Test Title 01",
      authors: "Test Author 01",
    ),
    ReferenceItem(
      2,
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
        _ExplorerWidget(allItems: _allItems,),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var newReference = ReferenceItem(
              // new id
              await () async {
                final response = await http.get(Uri.parse('http://localhost:8080/api/new'));
                if (response.statusCode == 200) {
                  final id = int.tryParse(response.body.trim());
                  if (id != null) return id;
                }
                throw StateError('Failed to fetch new ID');
              }(),
            );
          _navigateEditRoute( // go to another page
            itemOriginal: newReference,
            context: context,
            onSave: () { _allItems.add(newReference); }
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
