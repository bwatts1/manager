import 'package:flutter/material.dart';
import 'database_helper.dart';

// Here we are using a global variable. You can use something like
// get_it in a production app.
final dbHelper = DatabaseHelper();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize the database
  await dbHelper.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQFlite Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _collectData();
  }

  void _collectData() async {
    final data = await dbHelper.getItemsAsList();
    setState(() {
      tasks = data;
    });
  }


  void _showAlert(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
  void _add() {
    showDialog(
      context: context,
      builder: (context) {
      TextEditingController textController = TextEditingController();
      return AlertDialog(
        title: Text('Enter Your Name'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(hintText: 'Type here'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              print('User Input: ${textController.text}');
              Navigator.of(context).pop();
            },
            child: Text('Submit'),
          ),
          ],
        );
      },
    );
  }

  void _insert() async {
    Map<String, dynamic> row = {
      DatabaseHelper.columnName: _nameController.text,
      DatabaseHelper.columnAge: int.parse(_ageController.text),
    };
    final id = await dbHelper.insert(row);
    debugPrint('inserted row id: $id');
    _showAlert('Insert', 'Inserted row id: $id');
  }

  void _query() async {
    final id = int.parse(_idController.text);
    final row = await dbHelper.queryById(id);
    debugPrint('query row: $row');
    _showAlert('Query', row != null ? row.toString() : 'No row found with ID $id');
  }

  void _update() async {
    Map<String, dynamic> row = {
      DatabaseHelper.columnId: int.parse(_idController.text),
      DatabaseHelper.columnName: _nameController.text,
      DatabaseHelper.columnAge: int.parse(_ageController.text),
    };
    final rowsAffected = await dbHelper.update(row);
    debugPrint('updated $rowsAffected row(s)');
    _showAlert('Update', 'Updated $rowsAffected row(s)');
  }

  void _delete() async {
    final id = int.parse(_idController.text);
    final rowsDeleted = await dbHelper.delete(id);
    debugPrint('deleted $rowsDeleted row(s): row $id');
    _showAlert('Delete', 'Deleted $rowsDeleted row(s): row $id');
  }
  void _deleteAllC() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete All'),
          content: Text('Are you sure you want to delete all records?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                _deleteAll(); // Call the delete all function
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  void _deleteAll() async {
    final rowsDeleted = await dbHelper.deleteAll();
    debugPrint('Deleted $rowsDeleted row(s)');
    _showAlert('Delete All', 'Deleted $rowsDeleted row(s)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('sqflite')),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final name = tasks[index]['name'];
          final age = tasks[index]['age'];
          return ListTile(
            title: Text(name),
            subtitle: Text('Age: $age'),
          );
        },
      ),
      
      floatingActionButton: Stack(
        children: [
          Positioned(
            left: 30,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _deleteAllC,
              tooltip: 'delete',
              child: Icon(Icons.delete),
            ),
          ), 
          Positioned(
            right: 0,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _add,
              tooltip: 'add',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}