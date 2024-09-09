import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Model Selector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select a Model'),
      ),
      body: Center(
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(20.0),
          children: List.generate(4, (index) {
            return GestureDetector(
              onTap: () {
                _showInputDialog(context, index + 1);
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.model_training,
                        size: 50,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Model ${index + 1}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showInputDialog(BuildContext context, int model) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ModelInputDialog(model: model);
      },
    );
  }
}

class ModelInputDialog extends StatefulWidget {
  final int model;

  ModelInputDialog({required this.model});

  @override
  _ModelInputDialogState createState() => _ModelInputDialogState();
}

class _ModelInputDialogState extends State<ModelInputDialog> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController lambdaRateController = TextEditingController();
  TextEditingController muRateController = TextEditingController();
  TextEditingController sController = TextEditingController();
  TextEditingController nController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Input Data for Model ${widget.model}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _getInputFields(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _submitData();
            }
          },
          child: Text('Submit'),
        ),
      ],
    );
  }

  List<Widget> _getInputFields() {
    List<Widget> fields = [
      TextFormField(
        controller: lambdaRateController,
        decoration: InputDecoration(labelText: 'Lambda Rate'),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter lambda rate';
          }
          return null;
        },
      ),
      TextFormField(
        controller: muRateController,
        decoration: InputDecoration(labelText: 'Mu Rate'),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter mu rate';
          }
          return null;
        },
      ),
    ];

    if (widget.model == 3 || widget.model == 4) {
      fields.add(TextFormField(
        controller: sController,
        decoration: InputDecoration(labelText: 'S'),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter S value';
          }
          return null;
        },
      ));
    }

    if (widget.model == 2 || widget.model == 4) {
      fields.add(TextFormField(
        controller: nController,
        decoration: InputDecoration(labelText: 'N'),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter N value';
          }
          return null;
        },
      ));
    }

    return fields;
  }

  void _submitData() async {
    Map<String, dynamic> data = {
      'lambda_rate': lambdaRateController.text,
      'mu_rate': muRateController.text,
    };

    if (widget.model == 3 || widget.model == 4) {
      data['s'] = sController.text;
    }

    if (widget.model == 2 || widget.model == 4) {
      data['n'] = nController.text;
    }

    String url = 'https://hakirmubarmaj.pythonanywhere.com/model_${widget.model}';
    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(result: json.decode(response.body), model: widget.model),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> result;
  final int model;

  ResultPage({required this.result, required this.model});

  @override
  Widget build(BuildContext context) {
    String imagePath = model == 1 || model == 2 ? 'assets/model_1.png' : 'assets/model_2.png';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Result for Model $model'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Image.asset(imagePath),
            SizedBox(height: 20),
            const Text(
              'Queue Information:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildResultList(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResultList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: result.entries.map((entry) {
        return Text('${entry.key}: ${entry.value}');
      }).toList(),
    );
  }
}
