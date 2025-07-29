import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:usage_stats/usage_stats.dart';
// import 'package:shared_preferences/shared_preferences.dart';

import 'shop.dart';
import 'screentime.dart';

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
  int coins = 1500;
  String? pendingEmailCode;
  int goalMinutes = 0;

  List<Map<String, dynamic>> allGoals = [];
  Map<String, dynamic> currentGoal = {
    "targetMinutes": 1,
    "completedMinutes": 0,
    "title": "False Goal",
  };
  String currentGoalId = "";
  Map<String, dynamic> user = {};

  String? token;

  final List<AvatarItem> owned = [
    AvatarItem(
      assetPath: 'assets/buddies/triangle/triangleRed.png',
      name: "Red Triangle",
      id: 0,
    ),
  ];
  final List<AvatarItem> shop = shopList;

  int equippedId = 0;

  // set on loading of the app
  List<int> lastWeekMinutes = List.filled(7, 0);
  List<int> lastWeekGoals = List.filled(7, 0);

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

  // polled for state setup, subject to change
  Future<int> getCoins() async {
    final response = await http.get(
      Uri.parse('https://cometcontacts4331.com/api/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      print("Login failed by status code: ${response.statusCode}");
      return 0;
    }

    final body = response.body;
    if (body.isEmpty) {
      print("Login failed: Empty response body");
      return 0;
    }

    final responseData = jsonDecode(body);
    if (responseData['user'] == null) {
      print("Login failed: No user data found");
      return 0;
    }

    // coins = responseData['user']['coins'] ?? 0;
    return responseData['user']['coins'] ?? 0;
  }

  Future<int> getCurrentGoalMinutes() async {
    final response = await http.get(
      Uri.parse('https://cometcontacts4331.com/api/goals/active'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      print("Failed to fetch current goal minutes: ${response.statusCode}");
      return 0;
    }

    final body = response.body;
    if (body.isEmpty) {
      print("Failed to fetch current goal minutes: Empty response body");
      return 0;
    }

    final responseData = jsonDecode(body);
    if (responseData['goal'] == null) {
      print("Failed to fetch current goal minutes: No goal data found");
      return 0;
    }

    return responseData['goal']['targetMinutes'] ?? 0;
  }
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
  String username = "";

  @override
  void initState() {
    super.initState();
    // fire the UsageStats permission dialog once the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UsageStats.grantUsagePermission();
    });
  }

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

  Future<bool> tryRegister() async {
    final response = await http.post(
      Uri.parse('https://cometcontacts4331.com/api/register'),
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      print("Registration failed by status code: ${response.statusCode}");
      return false;
    }

    final result = jsonDecode(response.body);
    if (result['user'] == null) {
      print("Registration failed: No user data found");
      return false;
    }

    widget.state.user = result['user'];
    return true;
  }

  Future<void> _handleSubmit() async {
    _formKey.currentState?.save();
    if (showLogin) {
      final response = await http.post(
        Uri.parse('https://cometcontacts4331.com/api/login'),
        body: jsonEncode({'username': username, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print("Login failed by status code: ${response.statusCode}");
        return;
      }

      final body = response.body;
      if (body.isEmpty) {
        print("Login failed: Empty response body");
        return;
      }

      final responseData = jsonDecode(body);
      if (responseData['user'] == null) {
        print("Login failed: No user data found");
        return;
      }

      widget.state.token = responseData['token'];
      widget.state.loggedIn = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainView(state: widget.state)),
      );
    } else {
      final registered = await tryRegister();
      if (registered) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyPinScreen(state: widget.state, email: email),
          ),
        );
      }
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
      body: SafeArea(
        child: Center(
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
                          showLogin
                              ? const SizedBox.shrink()
                              : Column(
                                  children: [
                                    TextFormField(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: kFont,
                                      ),
                                      cursorColor: Colors.white,
                                      decoration: _fieldDec(
                                        'Email',
                                        Icons.person_pin,
                                      ),
                                      onSaved: (v) => email = v ?? '',
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                          TextFormField(
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: kFont,
                            ),
                            cursorColor: Colors.white,
                            decoration: _fieldDec('Username', Icons.person),
                            onSaved: (v) => username = v ?? '',
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

  Future<bool> tryVerifyEmail(String code) async {
    final response = await http.post(
      Uri.parse('https://cometcontacts4331.com/api/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': widget.email, 'code': code}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      print("Email verification failed by status code: ${response.statusCode}");
      return false;
    }

    final result = jsonDecode(response.body);
    if (result['message'] != 'Email has been verified.') {
      print("Email verification failed: ${result['message']}");
      return false;
    }

    return true;
  }

  void _verify() async {
    final verifyResult = await tryVerifyEmail(_pinController.text);
    if (verifyResult) {
      widget.state.loggedIn = true;
      widget.state.pendingEmailCode = null;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen(state: widget.state)),
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
      body: SafeArea(
        child: Center(
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
                  ElevatedButton(
                    onPressed: _verify,
                    child: const Text("Verify"),
                  ),
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

  Future<void> _loadUsageAndSetState() async {
    try {
      UsageStats.grantUsagePermission();

      // Dates
      DateTime today = new DateTime.now();
      DateTime minusOneDays = today.subtract(Duration(days: 1));
      DateTime minusTwoDays = today.subtract(Duration(days: 2));
      DateTime minusThreeDays = today.subtract(Duration(days: 3));
      DateTime minusFourDays = today.subtract(Duration(days: 4));
      DateTime minusFiveDays = today.subtract(Duration(days: 5));
      DateTime minusSixDays = today.subtract(Duration(days: 6));
      DateTime minusSevenDays = today.subtract(Duration(days: 7));

      // Event Blocks
      List<EventUsageInfo> blockMinusZero = await getScreenActions(
        minusOneDays,
        today,
      );
      List<EventUsageInfo> blockMinusOne = await getScreenActions(
        minusTwoDays,
        minusOneDays,
      );
      List<EventUsageInfo> blockMinusTwo = await getScreenActions(
        minusThreeDays,
        minusTwoDays,
      );
      List<EventUsageInfo> blockMinusThree = await getScreenActions(
        minusFourDays,
        minusThreeDays,
      );
      List<EventUsageInfo> blockMinusFour = await getScreenActions(
        minusFiveDays,
        minusFourDays,
      );
      List<EventUsageInfo> blockMinusFive = await getScreenActions(
        minusSixDays,
        minusFiveDays,
      );
      List<EventUsageInfo> blockMinusSix = await UsageStats.queryEvents(
        minusSevenDays,
        minusSixDays,
      );

      // Minute Counts
      int minutesMinusZero = calculateTotalScreenTimeMinutes(blockMinusZero);
      int minutesMinusOne = calculateTotalScreenTimeMinutes(blockMinusOne);
      int minutesMinusTwo = calculateTotalScreenTimeMinutes(blockMinusTwo);
      int minutesMinusThree = calculateTotalScreenTimeMinutes(blockMinusThree);
      int minutesMinusFour = calculateTotalScreenTimeMinutes(blockMinusFour);
      int minutesMinusFive = calculateTotalScreenTimeMinutes(blockMinusFive);
      int minutesMinusSix = calculateTotalScreenTimeMinutes(blockMinusSix);

      // Setting State for Graphs
      this.setState(() {
        widget.state.lastWeekMinutes = [
          minutesMinusSix,
          minutesMinusFive,
          minutesMinusFour,
          minutesMinusThree,
          minutesMinusTwo,
          minutesMinusOne,
          minutesMinusZero,
        ];
      });
    } catch (err) {
      print(err);
    }
  }

  // init state and call widget.state.getDailyMinutes
  @override
  void initState() {
    super.initState();

    widget.state.getCurrentGoalMinutes().then((value) {
      setState(() {
        widget.state.goalMinutes = value;
      });
    });

    widget.state.getCoins().then((value) {
      setState(() {
        widget.state.coins = value;
      });
    });

    _loadUsageAndSetState();
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
      body: SafeArea(
        child: Stack(
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
    return FutureBuilder(
      future: state.getCoins(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          state.coins = snapshot.data!;
        } else if (snapshot.hasError) {
          print("Error fetching coins: ${snapshot.error}");
          state.coins = 0; // Fallback if error occurs
        }

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
      },
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
  late int _tempGoalMinutes;

  @override
  void initState() {
    super.initState();
    _tempGoalMinutes = widget.state.goalMinutes;
  }

  void _updateGoal() {
    // Goal Counts
    List<int> tempGoals = decideGoals(
      widget.state.goalMinutes,
      widget.state.lastWeekMinutes,
    );

    int numTimesGoalMet = tempGoals.reduce((a, b) => a + b);

    setState(() {
      widget.state.goalMinutes = _tempGoalMinutes;
      widget.state.lastWeekMinutes = tempGoals;
      widget.state.coins += numTimesGoalMet * 100;
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

  String _formatGoal(int minutes) {
    final h = minutes ~/ 60;
    print("hours: $h");
    final m = minutes % 60;
    print("minutes: $m");
    return "${h}h ${m.toString().padLeft(2, '0')}m";
  }

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
      body: SafeArea(
        child: ListView(
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
                    const SizedBox(height: 12),
                    Text(
                      "Current Goal: ${_formatGoal(widget.state.goalMinutes)}",
                      style: bodyWhite.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      min: 0,
                      max: 1440,
                      value: (_tempGoalMinutes).toDouble(),
                      divisions: 144, // steps of 10 minutes
                      label: _formatGoal(_tempGoalMinutes),
                      activeColor: kAccent,
                      inactiveColor: Colors.white24,
                      onChanged: (v) =>
                          setState(() => _tempGoalMinutes = v.toInt()),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("0 m", style: bodyWhite),
                        Text("24 h", style: bodyWhite),
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
                  painter: LineChartPainter(widget.state.lastWeekMinutes),
                  child: const Center(),
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
                  child: BarChart(data: widget.state.lastWeekGoals),
                ),
              ),
            ),
          ],
        ),
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
      body: SafeArea(
        child: GridView.builder(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 110,
                        child: Image.asset(item.assetPath, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: kFont,
                        ),
                      ),
                      const SizedBox(height: 4), // smaller spacing under name
                      Text(
                        "${item.price} coins",
                        style: bodyWhite,
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(), // pushes everything slightly up
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/* ========================== SIMPLE CHARTS ============================== */

class LineChartPainter extends CustomPainter {
  final List<int> data;
  final List<String> days = [
    '-6 Days',
    '-5 Days',
    '-4 Days',
    '-3 Days',
    '-2 Days',
    '-1 Days',
    'Today',
  ];

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
      canvas.drawLine(
        Offset(padding - 4, y),
        Offset(size.width - padding, y),
        axisPaint,
      );

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
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );

    // Title

    final titleTp = TextPainter(
      text: TextSpan(
        text: 'User Screen Time (mins)',
        style: titleStyle.copyWith(color: Colors.white, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    titleTp.paint(
      canvas,
      Offset(
        (size.width - titleTp.width) / 2,
        padding / 2 - titleTp.height / 2,
      ),
    );

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

    // Middle of average line
    final avgMidIndex = (averageDailyMinutes.length / 2).floor();
    final avgMidX = padding + avgMidIndex * dx;
    final avgMidY =
        size.height -
        padding -
        (averageDailyMinutes[avgMidIndex] / maxVal) * chartHeight;

    final avgLabel = TextPainter(
      text: const TextSpan(
        text: "Avg",
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    avgLabel.paint(canvas, Offset(avgMidX - avgLabel.width / 2, avgMidY - 14));

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

    // Middle of healthy line
    final healthyMidIndex = (healthyDailyMinutes.length / 2).floor();
    final healthyMidX = padding + healthyMidIndex * dx;
    final healthyMidY =
        size.height -
        padding -
        (healthyDailyMinutes[healthyMidIndex] / maxVal) * chartHeight;

    final healthyLabel = TextPainter(
      text: const TextSpan(
        text: "Healthy",
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    healthyLabel.paint(
      canvas,
      Offset(healthyMidX - healthyLabel.width / 2, healthyMidY - 14),
    );

    canvas.drawPath(averageMinutesPath, averageMinutesColor);
    canvas.drawPath(healthyMinutesPath, healthyMinutesColor);

    print("Line Chart Data: ${jsonEncode(data)}");
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

    final userX = padding + (data.length - 1) * dx;
    final userY = size.height - padding - (data.last / maxVal) * chartHeight;

    final userLabel = TextPainter(
      text: const TextSpan(
        text: "You",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    userLabel.paint(canvas, Offset(userX + 4, userY - 6));
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
    final List<String> days = [
      '-6 Days',
      '-5 Days',
      '-4 Days',
      '-3 Days',
      '-2 Days',
      '-1 Days',
      'Today',
    ];
    print("Bar Chart Data: ${jsonEncode(data)}");

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
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
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
