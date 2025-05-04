import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_service.dart';
import 'package:page_transition/page_transition.dart';
import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA9n9SGM9jEAvfXtln1fFiuuw0MT1qS6QU",
      authDomain: "fluutersecurity-app.firebaseapp.com",
      databaseURL: "https://fluutersecurity-app-default-rtdb.firebaseio.com",
      projectId: "fluutersecurity-app",
      storageBucket: "fluutersecurity-app.appspot.com",
      messagingSenderId: "530615100105",
      appId: "1:530615100105:web:a1490b321af2866e2d6318",
      measurementId: "G-ZGF6KKTME7"
    ),
  );

  // Initialize Firebase Storage with extended timeouts
  FirebaseStorage.instance.setMaxUploadRetryTime(const Duration(seconds: 30));
  FirebaseStorage.instance.setMaxOperationRetryTime(const Duration(seconds: 30));

  // Configure Firebase Storage for web platform
  if (kIsWeb) {
    // Web-specific configuration
    print('Configuring Firebase Storage for web platform');

    // The actual CORS configuration is handled in the web/index.html file
    // and through Firebase Storage CORS configuration on the server
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Security App Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C3D9C),
          primary: const Color(0xFF5C3D9C),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
            TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
            TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return PageTransition(
              type: PageTransitionType.fade,
              duration: const Duration(milliseconds: 300),
              child: const LoginPage(),
            );
          case '/dashboard':
            return PageTransition(
              type: PageTransitionType.fade,
              duration: const Duration(milliseconds: 300),
              child: const DashboardPage(),
            );
          default:
            return null;
        }
      },
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the entered email and password
      final email = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // Use FirebaseService to verify credentials
      final isValid = await _firebaseService.verifyAdminCredentials(email, password);

      if (!mounted) return;

      if (isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Successful!'),
          backgroundColor: Colors.green,
        ),
      );

        // Navigate to dashboard page with animation
        Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials!'),
          backgroundColor: Colors.red,
        ),
      );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
                Color(0xFF5C3D9C),
                Color(0xFF7953E8),
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPatternPainter(),
                ),
              ),

              // Login card
              Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0.9, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
            child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                            // Logo and Header
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C3D9C).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                size: 40,
                                color: Color(0xFF5C3D9C),
                              ),
                  ),
                            const SizedBox(height: 24),
                  const Text(
                              'Security App',
                    style: TextStyle(
                                fontSize: 28,
                      fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                    ),
                  ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter your credentials to log in to the admin panel',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Email Input
                  TextField(
                    controller: _usernameController,
                              keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFF5C3D9C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                      ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                  ),
                  const SizedBox(height: 20),

                            // Password Input
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF5C3D9C)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                    color: const Color(0xFF5C3D9C),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                floatingLabelBehavior: FloatingLabelBehavior.never,
                              ),
                              onSubmitted: (_) => _handleLogin(),
                            ),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // Forgot password functionality could be added here
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF5C3D9C),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  child: const Text('Forgot Password?'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 300),
                              tween: Tween<double>(begin: 0.95, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: SizedBox(
                    width: double.infinity,
                                height: 56,
                    child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5C3D9C),
                        foregroundColor: Colors.white,
                                    elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                        'Login',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5C3D9C).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.security_rounded,
                                    color: Color(0xFF5C3D9C),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Secure Login Enabled',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                    ),
                  ),
                ],
              ),
                          ],
            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  }

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gridSize = 50.0;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
  }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}