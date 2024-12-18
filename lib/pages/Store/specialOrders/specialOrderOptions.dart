import 'package:flutter/material.dart';
import '../../../configuration/config.dart';
import 'EditSpecialOrderFormPage.dart';

class SpecialOrdersOverviewPage extends StatefulWidget {
  const SpecialOrdersOverviewPage({super.key});

  @override
  _SpecialOrdersOverviewPageState createState() =>
      _SpecialOrdersOverviewPageState();
}

class _SpecialOrdersOverviewPageState extends State<SpecialOrdersOverviewPage> {
  final List<String> specialOrderOptions = [
    'Custom-Made Cake',
    'Large Orders',
  ]; // List of special order options

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: myColor,
        elevation: 0,
        toolbarHeight: appBarHeight,
        title: const Text(
          'Special Orders Option',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Image with Opacity
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/pastry.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: specialOrderOptions.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.125, // Set the height to be proportional
                  child: Card(
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    child: ListTile(
                      title: Text(
                        specialOrderOptions[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: myColor,
                          fontSize: 20,
                        ),
                      ),
                      trailing: const Icon(Icons.edit, color: myColor),
                      onTap: () {
                        // Navigate to Edit Form Page for the selected option
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditSpecialOrderFormPage(
                              orderOption: specialOrderOptions[index],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
