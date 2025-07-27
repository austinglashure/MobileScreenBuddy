import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

/* ========================== THEME & CONSTANTS ========================== */

const kDarkSurface = Color(0xFF2b343d);
const kScaffold = Color(0xFF34404B);
const kAccent = Color(0xFFE75A7C);
const kFont = 'Fredoka';

TextStyle titleStyle = const TextStyle(
  fontFamily: kFont,
  fontWeight: FontWeight.bold,
  fontSize: 22,
  color: kAccent,
);
TextStyle buttonTextStyle = const TextStyle(
  fontFamily: kFont,
  fontWeight: FontWeight.bold,
  fontSize: 16,
  color: Colors.white,
);
TextStyle bodyWhite = const TextStyle(
  fontFamily: kFont,
  fontWeight: FontWeight.w400,
  fontSize: 14,
  color: Colors.white,
);

class MyApp extends StatelessWidget {
  final AppState state = AppState();
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScreenBuddy Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: kScaffold,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAccent,
          primary: kAccent,
          secondary: kAccent,
          brightness: Brightness.dark,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: kAccent,
          selectionHandleColor: kAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kDarkSurface,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: TextStyle(
            fontFamily: kFont,
            fontWeight: FontWeight.w400,
            fontSize: 20,
            color: kAccent,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: kAccent,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            textStyle: buttonTextStyle,
          ),
        ),
      ),
      home: AuthScreen(state: state),
    );
  }
}

/* =============================== STATE ================================= */

class AppState {
  bool loggedIn = false;
  int coins = 150;
  String? pendingEmailCode;

  final List<AvatarItem> owned = [
    AvatarItem(
      assetPath: 'assets/buddies/triangle/triangleRed.png',
      name: "Buddy",
      id: 0,
    ),
  ];

  final List<AvatarItem> shop = [
    AvatarItem(
      assetPath: 'assets/buddies/triangle/triangleGreen.png',
      name: "Green Buddy",
      id: 1,
      price: 50,
    ),
    AvatarItem(
      assetPath: 'assets/buddies/triangle/triangleBlue.png',
      name: "Blue Buddy",
      id: 2,
      price: 75,
    ),
    AvatarItem(
      assetPath: 'assets/buddies/triangle/triangleOrange.png',
      name: "Orange Buddy",
      id: 3,
      price: 100,
    ),
  ];

  int equippedId = 0;

  TimeOfDay start = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 12, minute: 0);

  final List<int> dailyMinutes = List.generate(
    7,
    (_) => 90 + Random().nextInt(120),
  );
  final List<int> goalsMetPerWeek = List.generate(
    6,
    (_) => Random().nextInt(7),
  );

  void equip(int id) => equippedId = id;
  AvatarItem byId(int id) => owned.firstWhere((e) => e.id == id);
  bool buy(AvatarItem item) {
    if (coins >= item.price && shop.contains(item)) {
      coins -= item.price;
      owned.add(item);
      shop.remove(item);
      return true;
    }
    return false;
  }
}

class AvatarItem {
  final String assetPath;
  final String name;
  final int id;
  final int price;
  AvatarItem({
    required this.assetPath,
    required this.name,
    required this.id,
    this.price = 0,
  });
}

/* ============================ AUTH SCREEN ============================== */

class AuthScreen extends StatefulWidget {
  final AppState state;
  const AuthScreen({super.key, required this.state});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool showLogin = true;
  final _formKey = GlobalKey<FormState>();
  String email = "";
  String password = "";

  InputDecoration _fieldDec(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white, fontFamily: kFont),
    prefixIcon: Icon(icon, color: Colors.white),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white, width: 2),
    ),
  );

  void _handleSubmit() {
    _formKey.currentState?.save();
    if (showLogin) {
      widget.state.loggedIn = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainView(state: widget.state)),
      );
    } else {
      widget.state.pendingEmailCode = _generateCode();
      // TODO: API call to send widget.state.pendingEmailCode to the user's email
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyPinScreen(state: widget.state, email: email),
        ),
      );
    }
  }

  String _generateCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome to ScreenBuddy',
          style: const TextStyle(
            color: kAccent,
            fontFamily: kFont,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // Login/Register title
                Text(
                  showLogin ? 'Welcome Back!' : 'Sign Up!',
                  style: const TextStyle(
                    color: kAccent,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: kFont,
                  ),
                ),
                const SizedBox(height: 24),

                // Dark background container around form
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: kFont,
                          ),
                          cursorColor: Colors.white,
                          decoration: _fieldDec('Email', Icons.person),
                          onSaved: (v) => email = v ?? '',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: kFont,
                          ),
                          cursorColor: Colors.white,
                          obscureText: true,
                          decoration: _fieldDec('Password', Icons.lock),
                          onSaved: (v) => password = v ?? '',
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _handleSubmit,
                          child: Text(showLogin ? 'Login' : 'Register'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => showLogin = !showLogin),
                  child: Text(
                    showLogin
                        ? "Don't have an account? Register"
                        : "Have an account? Login",
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: kFont,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Image.asset(
                  'assets/buddies/triangle/triangleRed.png',
                  width: 100.0,
                  height: 100.0,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================= VERIFY PIN SCREEN =========================== */

class VerifyPinScreen extends StatefulWidget {
  final AppState state;
  final String email;
  const VerifyPinScreen({super.key, required this.state, required this.email});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final _pinController = TextEditingController();

  InputDecoration _pinDec() => const InputDecoration(
    labelText: '6-digit Code',
    labelStyle: TextStyle(color: Colors.white, fontFamily: kFont),
    prefixIcon: Icon(Icons.lock_open, color: Colors.white),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white, width: 2),
    ),
  );

  void _verify() {
    if (_pinController.text == widget.state.pendingEmailCode) {
      widget.state.loggedIn = true;
      widget.state.pendingEmailCode = null;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainView(state: widget.state)),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid code. Try again.")));
    }
  }

  void _resend() {
    widget.state.pendingEmailCode = _generateCode();
    // TODO: API call to re-send code to widget.email
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Verification code re-sent.")));
  }

  String _generateCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email Verification"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 85),
                Text(
                  "Enter the 6-digit code sent to\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: bodyWhite.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: kFont,
                    letterSpacing: 4,
                  ),
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  cursorColor: Colors.white,
                  decoration: _pinDec(),
                ),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _verify, child: const Text("Verify")),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _resend,
                  child: const Text(
                    "Resend Code",
                    style: TextStyle(color: Colors.white, fontFamily: kFont),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(state: widget.state),
                      ),
                      (_) => false,
                    );
                  },
                  child: const Text(
                    "Back to Login/Register",
                    style: TextStyle(color: Colors.white, fontFamily: kFont),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================== MAIN VIEW ============================== */

class MainView extends StatefulWidget {
  final AppState state;
  const MainView({super.key, required this.state});
  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int? selectedInventoryId;

  void _logout() {
    widget.state.loggedIn = false;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen(state: widget.state)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final equipped = widget.state.byId(widget.state.equippedId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main'),
        leading: IconButton(
          icon: const Icon(Icons.bar_chart),
          tooltip: "Goals & Statistics",
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GoalsStatsView(state: widget.state),
            ),
          ).then((_) => setState(() {})),
        ),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.store, color: kAccent),
              tooltip: "Shop",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShopView(state: widget.state),
                ),
              ).then((_) => setState(() {})),
            ),
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, -110),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: kDarkSurface,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.black12,
                      backgroundImage: AssetImage(equipped.assetPath),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(equipped.name, style: titleStyle),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: InventoryBar(
              state: widget.state,
              selected: selectedInventoryId,
              onSelect: (id) => setState(() => selectedInventoryId = id),
              onEquip: () {
                if (selectedInventoryId != null) {
                  setState(() => widget.state.equip(selectedInventoryId!));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ========================== INVENTORY BAR ============================= */

class InventoryBar extends StatelessWidget {
  final AppState state;
  final int? selected;
  final VoidCallback onEquip;
  final ValueChanged<int> onSelect;

  const InventoryBar({
    super.key,
    required this.state,
    required this.selected,
    required this.onEquip,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      color: kDarkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Inventory", style: titleStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.owned.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final item = state.owned[i];
                  final equipped = state.equippedId == item.id;
                  final isSelected = selected == item.id;
                  return GestureDetector(
                    onTap: () => onSelect(item.id),
                    child: Stack(
                      children: [
                        Container(
                          width: 70,
                          decoration: BoxDecoration(
                            color: kScaffold,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? kAccent : Colors.white24,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              item.assetPath,
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        if (equipped)
                          const Positioned(
                            right: 2,
                            top: 2,
                            child: Icon(
                              Icons.check_circle,
                              size: 18,
                              color: kAccent,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEquip,
                    child: const Text('Equip'),
                  ),
                ),
                const SizedBox(width: 12),
                Text("Coins: ${state.coins}", style: bodyWhite),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ======================== GOALS & STATISTICS VIEW ====================== */

class GoalsStatsView extends StatefulWidget {
  final AppState state;
  const GoalsStatsView({super.key, required this.state});
  
  @override
  State<GoalsStatsView> createState() => _GoalsStatsViewState();
}

class _GoalsStatsViewState extends State<GoalsStatsView> {
  TimeOfDay? newStart;
  TimeOfDay? newEnd;

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.state.start,
    );
    if (picked != null) setState(() => newStart = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.state.end,
    );
    if (picked != null) setState(() => newEnd = picked);
  }

  void _updateGoal() {
    setState(() {
      widget.state.start = newStart ?? widget.state.start;
      widget.state.end = newEnd ?? widget.state.end;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Goal updated")));
  }

  void _logout() {
    widget.state.loggedIn = false;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen(state: widget.state)),
      (_) => false,
    );
  }

  String _fmt(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Goals & Statistics"),
        leading: const BackButton(),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Goals", style: titleStyle),
          const SizedBox(height: 8),
          Card(
            color: kDarkSurface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Current Goal: ${_fmt(widget.state.start)} - ${_fmt(widget.state.end)}",
                    style: bodyWhite.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _pickStart,
                          child: Text(
                            "Start: ${_fmt(newStart ?? widget.state.start)}",
                            style: bodyWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _pickEnd,
                          child: Text(
                            "End: ${_fmt(newEnd ?? widget.state.end)}",
                            style: bodyWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _updateGoal,
                    child: const Text("Update Goal"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text("Statistics", style: titleStyle),
          const SizedBox(height: 8),
          Card(
            color: kDarkSurface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              height: 200,
              child: CustomPaint(
                painter: LineChartPainter(widget.state.dailyMinutes),
                child: const Center(

                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: kDarkSurface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: BarChart(data: widget.state.goalsMetPerWeek),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =============================== SHOP VIEW ============================= */

class ShopView extends StatefulWidget {
  final AppState state;
  const ShopView({super.key, required this.state});
  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  void _logout() {
    widget.state.loggedIn = false;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen(state: widget.state)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop"),
        leading: const BackButton(),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.state.shop.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: .9,
        ),
        itemBuilder: (_, i) {
          final item = widget.state.shop[i];
          return Card(
            color: kDarkSurface,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                final ok = widget.state.buy(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? "Purchased ${item.name}!" : "Not enough coins.",
                    ),
                  ),
                );
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 85),
                    Image.asset(
                      item.assetPath,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: kFont,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text("${item.price} coins", style: bodyWhite),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ========================== SIMPLE CHARTS ============================== */

class LineChartPainter extends CustomPainter {
  final List<int> data;
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // 5 hours and 16 minutes is the average for all Americans (316 mins)
  final List<int> averageDailyMinutes = List.generate(7, (_) => 316);
  // 2 hours is the limit on "healthy" usage according to Psychologists (120 mins)
  final List<int> healthyDailyMinutes = List.generate(7, (_) => 120);

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 24.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    final labelStyle = const TextStyle(color: Colors.white70, fontSize: 10);
    final double dyStep = 120.0; // Every 2 hours (120 minutes)

    /*-------------------Paint Colors-------------------------------------*/

    final axisPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1;

    final averageMinutesColor = Paint()
      ..color = const Color.fromARGB(255, 255, 0, 0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final healthyMinutesColor = Paint()
      ..color = const Color.fromARGB(255, 72, 255, 0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final userMinutesColor = Paint()
      ..color = const Color.fromARGB(255, 0, 0, 0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    /*---------------------Draw Empty Graph-------------------------------*/

    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );

    /*--------------------Determining the bounds---------------------------*/

    final defaultMaxVal = 600.0;

    final double maxVal = data.isNotEmpty
        ? max(defaultMaxVal, data.reduce(max).toDouble())
        : defaultMaxVal;

    final dx = chartWidth / (averageDailyMinutes.length - 1);

    /*-----------------------Draw axis tick lines and labels---------------------*/

    // Y labels
    for (double yVal = 0; yVal <= maxVal; yVal += dyStep) {
      final y = size.height - padding - (yVal / maxVal) * chartHeight;
      canvas.drawLine(Offset(padding - 4, y), Offset(size.width - padding, y), axisPaint);

      final tp = TextPainter(
        text: TextSpan(text: yVal.toInt().toString(), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padding - tp.width - 8, y - tp.height / 2));
    }

    // X labels
    for (int i = 0; i < days.length; i++) {
      final x = padding + i * dx;
      final tp = TextPainter(
        text: TextSpan(text: days[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - padding + 4));
    }

    // X and Y lines
    canvas.drawLine(Offset(padding, padding), Offset(padding, size.height - padding), axisPaint);
    canvas.drawLine(Offset(padding, size.height - padding), Offset(size.width - padding, size.height - padding), axisPaint);


    // Title
    
    final titleTp = TextPainter(
      text: TextSpan(
        text: 'User Screen Time (mins)',
        style: titleStyle.copyWith(color: Colors.white, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    titleTp.paint(canvas, Offset(
      (size.width - titleTp.width) / 2,
      padding / 2 - titleTp.height / 2,
    ));

    /*-----------------------Drawing the Default Lines---------------------*/


    final averageMinutesPath = Path();
    for (int i = 0; i < averageDailyMinutes.length; i++) {
      final x = padding + i * dx;
      final y =
          size.height -
          padding -
          (averageDailyMinutes[i] / maxVal) * chartHeight;
      if (i == 0) {
        averageMinutesPath.moveTo(x, y);
      } else {
        averageMinutesPath.lineTo(x, y);
      }
    }

    final healthyMinutesPath = Path();
    for (int i = 0; i < healthyDailyMinutes.length; i++) {
      final x = padding + i * dx;
      final y =
          size.height -
          padding -
          (healthyDailyMinutes[i] / maxVal) * chartHeight;
      if (i == 0) {
        healthyMinutesPath.moveTo(x, y);
      } else {
        healthyMinutesPath.lineTo(x, y);
      }
    }

    canvas.drawPath(averageMinutesPath, averageMinutesColor);
    canvas.drawPath(healthyMinutesPath, healthyMinutesColor);

    if (data.isEmpty) return;

    /*------------------Drawing User Data Line-----------------------------*/

    final userMinutesPath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = padding + i * dx;
      final y = size.height - padding - (data[i] / maxVal) * chartHeight;
      if (i == 0) {
        userMinutesPath.moveTo(x, y);
      } else {
        userMinutesPath.lineTo(x, y);
      }
    }
    canvas.drawPath(userMinutesPath, userMinutesColor);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

class BarChart extends StatelessWidget {
  final List<int> data;
  const BarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty ? 1 : data.reduce(max);
    const barHeight = 100.0;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: barHeight + 30, // extra room to prevent overflow
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "Goals Completed",
                style: titleStyle.copyWith(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                final height = maxVal == 0 ? 0 : (data[i] / maxVal) * barHeight;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height.toDouble(),
                          decoration: BoxDecoration(
                            color: kAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                "${data[i]}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(data.length, (i) {
              return Expanded(
                child: Center(
                  child: Text(
                    days[i],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
