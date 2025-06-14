import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String currentCalculatorType = 'Standard';
  final List<String> calculatorTypes = ['Standard', 'Scientific', 'Programmer', 'BMI'];
  List<String> calculations = [];

  CalculatorScreenState? calculatorScreenState;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      calculations = prefs.getStringList('calculations') ?? [];
    });
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('calculations', calculations);
  }

  void addCalculation(String calculation) {
    setState(() {
      calculations.insert(0, calculation);
      if (calculations.length > 100) {
        calculations.removeLast();
      }
      saveHistory();
    });
  }

  void clearHistory() {
    setState(() {
      calculations.clear();
      saveHistory();
    });
  }

  void restoreCalculation(String calculation) {
    setState(() {
      _selectedIndex = 0; // Pindah ke halaman kalkulator
    });
    calculatorScreenState?.restoreCalculation(calculation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        color: Colors.white, // Ganti background jadi putih
        // Hapus decoration: BoxDecoration(...)
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: IndexedStack(
            key: ValueKey<int>(_selectedIndex),
            index: _selectedIndex,
            children: [
              CalculatorScreen(
                calculationType: currentCalculatorType,
                onCalculation: addCalculation,
                onStateCreated: (state) {
                  calculatorScreenState = state;
                },
              ),
              HistoryScreen(
                calculations: calculations,
                onClear: clearHistory,
                onRestore: restoreCalculation,
              ),
              ProfileScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: CircleAvatar(
              backgroundColor: Colors.white70,
              child: Icon(Icons.calculate, color: Colors.black),
            ),
            label: 'Calculator',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              backgroundColor: Colors.white70,
              child: Icon(Icons.history, color: Colors.black),
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              backgroundColor: Colors.white70,
              child: Icon(Icons.person, color: Colors.black),
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}



class CalculatorScreen extends StatefulWidget {
  final String calculationType;
  final Function(String) onCalculation;
  final Function(CalculatorScreenState)? onStateCreated;

  const CalculatorScreen({
    super.key,
    required this.calculationType,
    required this.onCalculation,
    this.onStateCreated,
  });

  @override
  CalculatorScreenState createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen> {
  String expression = "";
  String result = "0";
  bool newInput = false;

  @override
  void initState() {
    super.initState();
    if (widget.onStateCreated != null) {
      widget.onStateCreated!(this);
    }
  }

  void restoreCalculation(String calculation) {
    setState(() {
      expression = calculation.split(' = ')[0];
      result = calculation.split(' = ')[1];
      newInput = true; // Menandakan bahwa hasil sebelumnya akan digunakan
    });
  }

  void onButtonPressed(String value) {
    setState(() {
      if (value == "C") {
        expression = "";
        result = "0";
      } else if (value == "⌫") {
        if (expression.isNotEmpty) {
          expression = expression.substring(0, expression.length - 1);
        }
      } else if (value == "=") {
        calculateResult();
      } else if (value == "+/-") {
        if (expression.isNotEmpty && double.tryParse(expression) != null) {
          double number = double.parse(expression);
          expression = (-number).toString();
        }
      } else {
        if (newInput && (value == "+" || value == "-" || value == "×" || value == "÷")) {
          // Gunakan hasil sebelumnya sebagai bagian dari ekspresi baru
          expression = result + value;
          newInput = false;
        } else if (newInput) {
          // Jika input baru dimulai, ganti ekspresi dengan input baru
          expression = value;
          result = "0";
          newInput = false;
        } else {
          // Tambahkan input ke ekspresi
          expression += value;
        }
      }
    });
  }

  void calculateResult() {
    try {
      Parser p = Parser();
      Expression exp = p.parse(expression.replaceAll('×', '*').replaceAll('÷', '/'));
      ContextModel cm = ContextModel();
      result = exp.evaluate(EvaluationType.REAL, cm).toString();
      newInput = true;

      // Tambahkan hasil ke history hanya setelah "=" ditekan
      widget.onCalculation("$expression = $result");
    } catch (e) {
      result = "Error";
    }
  }

  List<String> getButtons() {
    if (widget.calculationType == 'Scientific') {
      return [
        "C", "⌫", "sin", "cos",
        "7", "8", "9", "tan",
        "4", "5", "6", "log",
        "1", "2", "3", "=",
        "0", ".", "+/-",
      ];
    } else if (widget.calculationType == 'Programmer') {
      return [
        "C", "⌫", "AND", "OR",
        "7", "8", "9", "XOR",
        "4", "5", "6", "NOT",
        "1", "2", "3", "=",
        "0", ".", "+/-",
      ];
    } else if (widget.calculationType == 'BMI') {
      return [
        "C", "⌫", "Height", "Weight",
        "7", "8", "9", "=",
        "4", "5", "6", "",
        "1", "2", "3", "",
        "0", ".", "+/-",
      ];
    } else {
      // Default to Standard
      return [
        "C", "⌫", "÷", "×",
        "7", "8", "9", "-",
        "4", "5", "6", "+",
        "1", "2", "3", "=",
        "0", ".", "+/-",
      ];
    }
  }

  Widget buildButton(String label) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.all(20),
        ),
        onPressed: () => onButtonPressed(label),
        child: Text(
          label,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }







  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          AppBar(
            title: const Text("Calculator"),
            centerTitle: true,
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  minWidth: 300,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.bottomRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            expression.isEmpty ? "0" : expression,
                            style: const TextStyle(fontSize: 32, color: Colors.black), // dari Colors.white ke Colors.black
                          ),
                          const SizedBox(height: 10),
                          Text(
                            result.isEmpty ? "" : "= $result",
                            style: TextStyle(fontSize: 24, color: Colors.grey[700]), // dari Colors.grey ke Colors.grey[700]
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          childAspectRatio: 1.3,
                          children: getButtons()
                              .map((label) => buildButton(label))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}








class HistoryScreen extends StatelessWidget {
  final List<String> calculations;
  final VoidCallback onClear;
  final Function(String) onRestore;

  const HistoryScreen({
    super.key,
    required this.calculations,
    required this.onClear,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Calculation History'),
        backgroundColor: Colors.black, // dari Colors.deepPurple ke Colors.black
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onClear,
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // dari BoxDecoration gradient ke warna putih polos
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: calculations.isEmpty
              ? const Center(
                  child: Text(
                    'No calculations yet',
                    style: TextStyle(color: Colors.black), // dari Colors.white ke Colors.black
                  ),
                )
              : ListView.separated(
                  itemCount: calculations.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.black12),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        calculations[index],
                        style: const TextStyle(fontSize: 18, color: Colors.black), // dari Colors.white ke Colors.black
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.black12,
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.black)),
                      ),
                      onTap: () => onRestore(calculations[index]),
                    );
                  },
                ),
        ),
      ),
    );
  }
}








class OptionsScreen extends StatelessWidget {
  final List<String> calculatorTypes;
  final String currentType;
  final Function(String) onTypeSelected;

  const OptionsScreen({
    super.key,
    required this.calculatorTypes,
    required this.currentType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Calculator Options'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white, // dari BoxDecoration gradient ke warna putih polos
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
            itemCount: calculatorTypes.length,
            itemBuilder: (context, index) {
              final type = calculatorTypes[index];
              return ListTile(
                title: Text(
                  type,
                  style: const TextStyle(color: Colors.black), // dari Colors.white ke Colors.black
                ),
                leading: const Icon(Icons.calculate, color: Colors.black),
                trailing: type == currentType
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  onTypeSelected(type);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
















class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: Colors.black, // dari Colors.deepPurple ke Colors.black
        elevation: 0,
      ),
      body: Container(
        color: Colors.white, // dari BoxDecoration gradient ke warna putih polos
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.black12,
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.black, // dari Colors.deepPurple ke Colors.black
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Fitrah Nur Ivanto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _profileInfo(Icons.person_outline, 'Username', '@ivanzz'),
                  _profileInfo(Icons.email_outlined, 'Email', 'fitrahnurivanto@gmail.com'),
                  _profileInfo(Icons.location_on_outlined, 'Lokasi', 'Pandak, Bantul'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileInfo(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black), // ganti warna ikon jadi hitam
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black, // pastikan judul hitam
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

