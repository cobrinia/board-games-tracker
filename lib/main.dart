import 'package:flutter/material.dart';

//import 'package:flutter/rendering.dart'; //файли для дебагу

void main() {
  //debugPaintSizeEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Каталог настільних ігор',
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: const Color.fromARGB(255, 170, 7, 56),
        ),
      ),
      home: const MyHomePage(title: 'Каталог настільних ігор'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text('Каталог appBar'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text(
              'Вітаємо у додатку обліку настільних ігор!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Image.asset('assets/images/icon1.jpg', width: 200, height: 200),
            const SizedBox(height: 20),

            Text('Тут буде вестися облік партій та учасників настільних ігор.'),
          ],
        ),
      ),
    );
  }
}
