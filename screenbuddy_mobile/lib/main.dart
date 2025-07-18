import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Defines the current authentication mode for the application.
enum AuthMode {
  /// Represents the login view.
  login,

  /// Represents the registration view.
  register,
}

/// The data model for authentication, managing the current authentication mode
/// and post-action success messages.
class AuthModel extends ChangeNotifier {
  AuthMode _authMode;
  String? _successMessage;
  bool _isAuthenticated;
  String? _loggedInUsername;

  /// Gets the current authentication mode.
  AuthMode get authMode => _authMode;

  /// Gets the success message after a login or registration action.
  String? get successMessage => _successMessage;

  /// Checks if a user is currently authenticated.
  bool get isAuthenticated => _isAuthenticated;

  /// Gets the username of the currently logged-in user.
  String? get loggedInUsername => _loggedInUsername;

  /// Initializes the AuthModel.
  AuthModel()
    : _authMode = AuthMode.login,
      _isAuthenticated = false,
      _loggedInUsername = null,
      _successMessage = null;

  /// Toggles the authentication mode between login and register.
  void toggleAuthMode() {
    _authMode = _authMode == AuthMode.login
        ? AuthMode.register
        : AuthMode.login;
    notifyListeners();
  }

  /// Simulates a login operation and sets authentication state.
  void login(String username) {
    _isAuthenticated = true;
    _loggedInUsername = username;
    _successMessage = 'Welcome $username!';
    notifyListeners();
  }

  /// Simulates a registration operation and sets authentication state.
  void register(String username, String email) {
    _isAuthenticated = true;
    _loggedInUsername =
        username; // Log in the user after successful registration
    _successMessage = 'Check your email ($email) for verification!';
    notifyListeners();
  }

  /// Resets the authentication state, clearing any success messages and
  /// returning to the login view.
  void resetState() {
    _successMessage = null;
    _authMode = AuthMode.login;
    _isAuthenticated = false;
    _loggedInUsername = null;
    notifyListeners();
  }
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScreenBuddy',
      theme: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: Color(0xFFE75A7C), // background when text is selected
          selectionHandleColor: Color(0xFFE75A7C), // drag handles
        ),
        scaffoldBackgroundColor: const Color(0xFF34404B), // Set background color
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
      home: ChangeNotifierProvider<AuthModel>(
        create: (BuildContext context) => AuthModel(),
        builder: (BuildContext context, Widget? child) => const AuthWrapper(),
      ),
    );
  }
}


/// A wrapper widget that decides which screen to display based on the
/// authentication model's state (AuthScreen or MainScreen).
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthModel>(
      builder: (BuildContext context, AuthModel authModel, Widget? child) {
        if (authModel.isAuthenticated) {
          return MainScreen(username: authModel.loggedInUsername);
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}

/// The main screen for authentication, allowing users to switch between
/// login and registration forms.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(
    'Welcome to ScreenBuddy',
          style: TextStyle(color: Color(0xFFE75A7C), fontFamily: 'Fredoka', fontWeight: FontWeight.w400),
            // text color
        ),
        backgroundColor: Color(0xFF2b343d),  // background color of the bar
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<AuthModel>(
              builder:
                  (BuildContext context, AuthModel authModel, Widget? child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(height: 20),
                        authModel.authMode == AuthMode.login
                            ? const LoginCard()
                            : const RegisterCard(),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            authModel.toggleAuthMode();
                          },
                          child: Text(
                            authModel.authMode == AuthMode.login
                                ? 'Don\'t have an account? Register'
                                : 'Already have an account? Login',
                            style: TextStyle(
                              color: Color(0xFFE75A7C),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
            ),
          ),
        ),
      ),
    );
  }
}

/// A card widget containing the login form.
class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2b343d),
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Login',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w400, fontFamily: 'Fredoka', color: Color(0xFFE75A7C)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(  
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white), // label color
                  prefixIcon: Icon(Icons.person, color: Colors.white), // icon color
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username.';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters.';
                  }
                  return null;
                },
                onSaved: (String? value) {
                  _username = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white), // label color
                  prefixIcon: Icon(Icons.lock, color: Colors.white), // icon color
                                    enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                obscureText: true,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
                onSaved: (String? value) {
                  _password = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE75A7C), // pink background
                  foregroundColor: Colors.white,     // white text
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Provider.of<AuthModel>(
                      context,
                      listen: false,
                    ).login(_username);
                  }
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card widget containing the registration form.
class RegisterCard extends StatefulWidget {
  const RegisterCard({super.key});

  @override
  State<RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<RegisterCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _username = '';
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2b343d),
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Register',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Fredoka',
                  color: Color(0xFFE75A7C),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white),
                  prefixIcon: Icon(Icons.person, color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username.';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters.';
                  }
                  if (value == "alas1") {
                    return 'Username "alas1" already taken';
                  }
                  return null;
                },
                onSaved: (String? value) {
                  _username = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  prefixIcon: Icon(Icons.email, color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email.';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
                onSaved: (String? value) {
                  _email = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                  prefixIcon: Icon(Icons.lock, color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                obscureText: true,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
                onSaved: (String? value) {
                  _password = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE75A7C), // pink background
                  foregroundColor: Colors.white,     // white text
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Provider.of<AuthModel>(
                      context,
                      listen: false,
                    ).register(_username, _email);
                  }
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// The main application screen displayed after successful authentication.
class MainScreen extends StatelessWidget {
  final String? username;
  const MainScreen({super.key, this.username});

  static const String _placeholderImageUrl =
      'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg';

  @override
  Widget build(BuildContext context) {
    final AuthModel authModel = Provider.of<AuthModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2b343d),
        title: const Text('ScreenBuddy Home', style: TextStyle(
          color: Color(0xFFE75A7C),
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w400,
        ), // text color and font
        ),
        leading: IconButton(
          icon: const Icon(Icons.assignment, color: Color(0xFFE75A7C)),
          tooltip: 'Goals',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const GoalsPage(),
              ),
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.analytics, color: Color(0xFFE75A7C)),
            tooltip: 'Statistics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const StatsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag, color: Color(0xFFE75A7C)),
            tooltip: 'Shop',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const ShopPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFE75A7C)),
            tooltip: 'Logout',
            onPressed: () {
              authModel.resetState();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            const Spacer(),
            CircleAvatar(
              radius: 60,
              backgroundImage: const NetworkImage(_placeholderImageUrl),
              backgroundColor: Colors.transparent, // In case image fails
            ),
            const SizedBox(height: 16),
            Text(
              username != null ? 'Hello, $username!' : 'Hello!',
              style: const TextStyle(            fontSize: 28,
              fontWeight: FontWeight.w400,
              fontFamily: 'Fredoka',
              color: Color(0xFFE75A7C)),
            ),
            const Spacer(flex: 2),
            // Arbitrary values in the bottom third
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const <Widget>[
                      Text('Level:', style: TextStyle(fontSize: 18)),
                      Text(
                        '10',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const <Widget>[
                      Text('Coins:', style: TextStyle(fontSize: 18)),
                      Text(
                        '500',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const <Widget>[
                      Text('Last Login:', style: TextStyle(fontSize: 18)),
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// A page for setting and viewing goals.
class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  String? _selectedGoal;
  final List<String> _availableGoals = <String>[
    'Complete daily challenge',
    'Achieve new rank',
    'Collect 1000 coins',
    'Customize avatar',
    'Explore new area',
  ];

  @override
  void initState() {
    super.initState();
    if (_availableGoals.isNotEmpty) {
      _selectedGoal = _availableGoals.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Your Goals'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Statistics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const StatsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Select a Goal:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGoal,
              decoration: const InputDecoration(
                labelText: 'Goal',
                border: OutlineInputBorder(),
              ),
              items: _availableGoals.map<DropdownMenuItem<String>>((
                String goal,
              ) {
                return DropdownMenuItem<String>(value: goal, child: Text(goal));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGoal = newValue;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_selectedGoal != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Goal "$_selectedGoal" set successfully!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Set Goal'),
            ),
            const Spacer(),
            const Text(
              'Current Goal:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedGoal ?? 'No goal selected',
              style: const TextStyle(fontSize: 20),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

/// A widget that displays a grid of shop items.
class _ShopItemGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _ShopItemGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 0.75, // Adjust as needed for card content
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> item = items[index];
        final bool isAd = item['isAd'] == true;

        return Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: InkWell(
            onTap: () {
              if (isAd) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Watching ad... ${item['actionText'] as String}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Attempting to buy ${item['name'] as String} for ${item['price'] as String}',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: isAd
                        ? Icon(
                            item['iconData'] as IconData,
                            size: 60,
                            color: Theme.of(context).primaryColor,
                          )
                        : Image.network(
                            item['image']! as String,
                            fit: BoxFit.contain,
                            loadingBuilder:
                                (
                                  BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress
                                              .cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!,
                                    ),
                                  );
                                },
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                  );
                                },
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['name']! as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    isAd
                        ? item['actionText']! as String
                        : item['price']! as String,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A page simulating an in-app shop with different sections.
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const String _placeholderItemImageUrl =
      'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg';

  final List<Map<String, dynamic>> _coinsShopItems =
      const <Map<String, dynamic>>[
        {
          'name': 'Cool Hat',
          'price': '100 Coins',
          'image': _placeholderItemImageUrl,
        },
        {
          'name': 'Stylish Shirt',
          'price': '150 Coins',
          'image': _placeholderItemImageUrl,
        },
        {
          'name': 'Awesome Shoes',
          'price': '120 Coins',
          'image': _placeholderItemImageUrl,
        },
        {
          'name': 'Fancy Glasses',
          'price': '80 Coins',
          'image': _placeholderItemImageUrl,
        },
        {
          'name': 'Backpack',
          'price': '200 Coins',
          'image': _placeholderItemImageUrl,
        },
        {
          'name': 'Magic Wand',
          'price': '300 Coins',
          'image': _placeholderItemImageUrl,
        },
      ];

  final List<Map<String, dynamic>> _premiumShopItems = <Map<String, dynamic>>[
    {
      'name': 'Premium Pass',
      'price': '\$9.99',
      'image': _placeholderItemImageUrl,
    },
    {
      'name': 'Exclusive Skin',
      'price': '\$4.99',
      'image': _placeholderItemImageUrl,
    },
    {
      'name': 'Gem Pack (Small)',
      'price': '\$1.99',
      'image': _placeholderItemImageUrl,
    },
    {
      'name': 'Gem Pack (Medium)',
      'price': '\$4.99',
      'image': _placeholderItemImageUrl,
    },
    {
      'name': 'Gem Pack (Large)',
      'price': '\$9.99',
      'image': _placeholderItemImageUrl,
    },
    {
      'name': 'Watch Ad',
      'actionText': 'Get 50 Coins',
      'iconData': Icons.play_circle_outline,
      'isAd': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Tab>[
            Tab(text: 'Coins Shop', icon: Icon(Icons.monetization_on)),
            Tab(text: 'Premium Shop', icon: Icon(Icons.workspace_premium)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _ShopItemGrid(items: _coinsShopItems),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _ShopItemGrid(items: _premiumShopItems),
          ),
        ],
      ),
    );
  }
}

/// A page for displaying user statistics related to goals and coins.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Statistics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Goals Progress',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              title: 'Goals Completed',
              value: '12',
              icon: Icons.check_circle_outline,
              chart: _buildBarChart(context, <double>[0.8, 0.6, 0.9, 0.7, 0.5]),
              description: 'Progress on your last 5 goals.',
            ),
            const SizedBox(height: 24),
            Text(
              'Coin Economy',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              title: 'Total Coins Earned',
              value: '2500',
              icon: Icons.monetization_on,
              chart: _buildLineChart(context, <double>[
                100,
                150,
                120,
                200,
                180,
                250,
              ]),
              description: 'Coins earned over the last 6 days.',
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              title: 'Coins Spent',
              value: '1800',
              icon: Icons.shopping_cart,
              chart: _buildLineChart(context, <double>[
                50,
                80,
                60,
                100,
                90,
                70,
              ], color: Colors.red),
              description: 'Coins spent on items.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Widget chart,
    required String description,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 30, color: Theme.of(context).primaryColor),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 100, width: double.infinity, child: chart),
            const SizedBox(height: 10),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<double> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map<Widget>((double value) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Container(
              height: value * 100, // Scale to max height of 100
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChart(
    BuildContext context,
    List<double> data, {
    Color? color,
  }) {
    final double maxVal = data.reduce(
      (double curr, double next) => curr > next ? curr : next,
    );
    final double scale = 100 / maxVal; // Scale to max height of 100

    return CustomPaint(
      painter: _LineChartPainter(
        data.map((double e) => e * scale).toList(),
        Theme.of(context).primaryColor,
      ),
      child: Container(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  _LineChartPainter(this.data, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    if (data.isNotEmpty) {
      final double stepX = size.width / (data.length - 1);
      path.moveTo(0, size.height - data[0]);

      for (int i = 1; i < data.length; i++) {
        path.lineTo(i * stepX, size.height - data[i]);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _LineChartPainter) {
      return oldDelegate.data != data || oldDelegate.lineColor != lineColor;
    }
    return true;
  }
}

void main() {
  runApp(const MyApp());
}
