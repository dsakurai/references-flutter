import 'package:flutter/material.dart';

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

class _ExplorerWidget extends StatefulWidget {

  @override
  _ExplorerState createState() => _ExplorerState();
}

class _ExplorerState extends State<_ExplorerWidget> {

  List<String> _allItems = ["Test", "Test 00", "Test 01"];
  List<String> _filteredItems = [];

  // TODO remove this
  @override
  void initState() {
    super.initState();
    _filterItems("");
  }

  void _filterItems(String query) {

    List<String> results = [];

    if (query.isEmpty) {
      results = _allItems;
    } else {
      results = _allItems
      .where((item) => item.toLowerCase().contains(query.toLowerCase()))
      .toList();
    }

    setState(() {
      _filteredItems = results;
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
                      return Text(_filteredItems[index]);
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

class ReferenceItem {
  String? title;
  String? authors;
}

class ReferenceItemWidget extends StatefulWidget {

  @override
  ReferenceItemWidgetState createState() => ReferenceItemWidgetState();
}

class ReferenceItemWidgetState extends State<ReferenceItemWidget> {
  ReferenceItem item = ReferenceItem();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add A New Reference"),
      ),
      body: Center(
        child: Column(
          children: [
            // Title
            TextFormField(
              initialValue: item.title,
              onChanged: (value) {
                setState(() {
                  item.title = value;
                });
              },
            ),
            TextFormField(
              initialValue: item.authors,
              onChanged: (value) {
                setState(() {
                  item.authors = value;
                });
              },
            ),
          ]
        )
      )
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {

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
        _ExplorerWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReferenceItemWidget()),
          );
        },
        tooltip: 'Add a new reference',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
