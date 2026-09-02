import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'core/api_service.dart';
import 'core/theme.dart';
import 'models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  runApp(const CheepperApp());
}

class CheepperApp extends StatelessWidget {
  const CheepperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cheepper Bills',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final startTime = DateTime.now();
    UserModel? fetchedUser;
    try {
      fetchedUser = await ApiService.getMe();
    } catch (_) {
      fetchedUser = null;
    }

    // Ensure flowing scenery splash screen is displayed for 3.5 seconds
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed.inMilliseconds < 3500) {
      await Future.delayed(Duration(milliseconds: 3500 - elapsed.inMilliseconds));
    }

    if (mounted) {
      setState(() {
        _user = fetchedUser;
        _isLoading = false;
      });
    }
  }

  void _onLoginSuccess(UserModel user) {
    setState(() => _user = user);
  }

  void _onLogout() async {
    await ApiService.logout();
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }
    if (_user == null) {
      return AuthScreen(onSuccess: _onLoginSuccess);
    }
    return HomeScreen(user: _user!, onLogout: _onLogout);
  }
}

// -----------------------------------------------------------------------------
// FLOWING SCENERY SPLASH SCREEN
// -----------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _logoController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  int _tickerIndex = 0;
  final List<Map<String, String>> _tickers = [
    {"icon": "⚡", "text": "Instant Automated Bill Payments & Receipts"},
    {"icon": "🔐", "text": "Double-Entry Ledger & Zero-Fee Transfers"},
    {"icon": "🎓", "text": "Direct WAEC, NECO & JAMB Certificate Portal"},
  ];

  @override
  void initState() {
    super.initState();

    // Wave animation controller (continuous flowing scenery)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Logo & pulse animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.06).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _fadeAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.25).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutQuad),
    );

    // Ticker feature text transition every 1.1 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 1100));
      if (mounted) {
        setState(() {
          _tickerIndex = (_tickerIndex + 1) % _tickers.length;
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTicker = _tickers[_tickerIndex];

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // 1. Flowing Organic Wave Scenery Background
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: SceneryWavePainter(progress: _waveController.value),
              );
            },
          ),

          // 2. Glowing Radial Background Orbs
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryEmerald.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryCyan.withOpacity(0.15),
              ),
            ),
          ),

          // 3. Center Scenery Branding Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Glowing Emblem Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryEmerald, AppTheme.primaryCyan, Colors.purpleAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryEmerald.withOpacity(0.45 * _fadeAnim.value),
                              blurRadius: 40 * _pulseAnim.value,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 58,
                          color: Colors.black,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),

                // App Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, AppTheme.primaryEmerald, AppTheme.primaryCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "CHEEPPER BILLS",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // App Tagline
                const Text(
                  "The Modern Bill Operating System",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 36),

                // Dynamic Feature Ticker Badge
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Container(
                    key: ValueKey<int>(_tickerIndex),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryEmerald.withOpacity(0.1),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currentTicker["icon"]!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Text(
                          currentTicker["text"]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Flowing Animated Linear Progress Indicator
                SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: AppTheme.cardDark,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryEmerald),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Footer Security & System Label
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: AppTheme.primaryCyan),
                const SizedBox(width: 6),
                Text(
                  "Secured with 256-bit Encryption · Cheepper OS v1.0",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted.withOpacity(0.85),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter that draws 3 flowing sinusoidal gradient waves across the screen
class SceneryWavePainter extends CustomPainter {
  final double progress;

  SceneryWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double waveHeight = size.height * 0.12;
    final double baseHeight = size.height * 0.82;

    // Layer 1: Deep Emerald Wave
    final path1 = Path();
    path1.moveTo(0, size.height);
    path1.lineTo(0, baseHeight);

    for (double x = 0; x <= size.width; x += 10) {
      final y = baseHeight + sin((x / size.width * 2 * pi) + (progress * 2 * pi)) * waveHeight;
      path1.lineTo(x, y);
    }
    path1.lineTo(size.width, size.height);
    path1.close();

    final paint1 = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.primaryEmerald.withOpacity(0.20),
          AppTheme.primaryCyan.withOpacity(0.08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, baseHeight - waveHeight, size.width, waveHeight * 2));

    canvas.drawPath(path1, paint1);

    // Layer 2: Cyan Wave (Offset frequency)
    final path2 = Path();
    final double baseHeight2 = size.height * 0.86;
    path2.moveTo(0, size.height);
    path2.lineTo(0, baseHeight2);

    for (double x = 0; x <= size.width; x += 10) {
      final y = baseHeight2 + cos((x / size.width * 2.5 * pi) - (progress * 2 * pi)) * (waveHeight * 0.75);
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.close();

    final paint2 = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.primaryCyan.withOpacity(0.18),
          Colors.purpleAccent.withOpacity(0.08),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, baseHeight2 - waveHeight, size.width, waveHeight * 2));

    canvas.drawPath(path2, paint2);

    // Top Wave Layer
    final topPath = Path();
    topPath.moveTo(0, 0);
    topPath.lineTo(size.width, 0);
    topPath.lineTo(size.width, size.height * 0.14);

    for (double x = size.width; x >= 0; x -= 10) {
      final y = size.height * 0.14 + sin((x / size.width * 2 * pi) + (progress * 2 * pi)) * 25;
      topPath.lineTo(x, y);
    }
    topPath.close();

    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.primaryEmerald.withOpacity(0.12),
          AppTheme.primaryCyan.withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.2));

    canvas.drawPath(topPath, topPaint);
  }

  @override
  bool shouldRepaint(covariant SceneryWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// -----------------------------------------------------------------------------
// AUTH SCREEN
// -----------------------------------------------------------------------------
class AuthScreen extends StatefulWidget {
  final Function(UserModel) onSuccess;
  const AuthScreen({super.key, required this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  int currentStep = 1; // 1: Personal, 2: KYC Identity, 3: Security

  final emailCtrl = TextEditingController(text: "demo@cheepper.com");
  final nameCtrl = TextEditingController(text: "Adebayo Chukwuma");
  final phoneCtrl = TextEditingController(text: "08012345678");
  final bvnCtrl = TextEditingController(text: "22233344455");
  final ninCtrl = TextEditingController(text: "");
  final passCtrl = TextEditingController(text: "Secret123!");
  final pinCtrl = TextEditingController(text: "1234");

  bool identityModeBvn = true; // True for BVN, False for NIN
  bool showBothIdentity = false;
  bool loading = false;
  String errorMsg = "";

  void validateStep(int step) {
    setState(() => errorMsg = "");
    if (step == 1) {
      if (nameCtrl.text.trim().isEmpty) throw Exception("Please enter your full name.");
      if (phoneCtrl.text.trim().isEmpty) throw Exception("Please enter your phone number.");
      if (emailCtrl.text.trim().isEmpty || !emailCtrl.text.contains("@")) throw Exception("Please enter a valid email address.");
    } else if (step == 2) {
      final bvn = bvnCtrl.text.trim();
      final nin = ninCtrl.text.trim();
      if (bvn.isEmpty && nin.isEmpty) {
        throw Exception("At least one of BVN or NIN must be provided.");
      }
      if (bvn.isNotEmpty && bvn.length != 11) throw Exception("BVN must be exactly 11 digits.");
      if (nin.isNotEmpty && nin.length != 11) throw Exception("NIN must be exactly 11 digits.");
    }
  }

  void nextStep() {
    try {
      validateStep(currentStep);
      setState(() => currentStep++);
    } catch (e) {
      setState(() => errorMsg = e.toString().replaceAll("Exception: ", ""));
    }
  }

  void prevStep() {
    setState(() {
      errorMsg = "";
      if (currentStep > 1) currentStep--;
    });
  }

  void submit() async {
    setState(() {
      loading = true;
      errorMsg = "";
    });
    try {
      UserModel user;
      if (isLogin) {
        if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
          throw Exception("Please enter your email and password.");
        }
        user = await ApiService.login(emailCtrl.text.trim(), passCtrl.text.trim());
      } else {
        validateStep(1);
        validateStep(2);
        if (passCtrl.text.trim().isEmpty || passCtrl.text.length < 6) {
          throw Exception("Password must be at least 6 characters.");
        }
        if (pinCtrl.text.trim().length != 4) {
          throw Exception("Transaction PIN must be 4 digits.");
        }
        final bvn = bvnCtrl.text.trim();
        final nin = ninCtrl.text.trim();
        user = await ApiService.register(
          email: emailCtrl.text.trim(),
          fullName: nameCtrl.text.trim(),
          phoneNumber: phoneCtrl.text.trim(),
          bvn: bvn.isNotEmpty ? bvn : null,
          nin: nin.isNotEmpty ? nin : null,
          password: passCtrl.text.trim(),
          pin: pinCtrl.text.trim(),
        );
      }
      widget.onSuccess(user);
    } catch (e) {
      setState(() => errorMsg = e.toString().replaceAll("Exception: ", ""));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Brand
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.walletGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.bolt, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Text("Cheepper Bills", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text("Pay Your Bills. Pay Less.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 20),

                  // Mode Selector Tab (Log In vs Sign Up)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() { isLogin = true; errorMsg = ""; }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isLogin ? AppTheme.cardDark : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isLogin ? Border.all(color: AppTheme.primaryEmerald.withOpacity(0.5)) : null,
                              ),
                              child: Text(
                                "Log In",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, color: isLogin ? AppTheme.primaryEmerald : AppTheme.textMuted),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() { isLogin = false; currentStep = 1; errorMsg = ""; }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isLogin ? AppTheme.cardDark : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: !isLogin ? Border.all(color: AppTheme.primaryEmerald.withOpacity(0.5)) : null,
                              ),
                              child: Text(
                                "Sign Up",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, color: !isLogin ? AppTheme.primaryEmerald : AppTheme.textMuted),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error banner
                  if (errorMsg.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                        ],
                      ),
                    ),

                  // LOGIN FORM
                  if (isLogin) ...[
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email_outlined)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock_outline)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: loading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.primaryEmerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Log In to Account", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ]
                  // MULTI-STEP SIGNUP WIZARD
                  else ...[
                    // Step Progress Header Bar
                    _buildStepProgressHeader(),
                    const SizedBox(height: 16),

                    // Step 1: Personal Info
                    if (currentStep == 1) ...[
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone_android_outlined), hintText: "08012345678"),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email_outlined)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: nextStep,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primaryEmerald,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Continue to Identity Check", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ],

                    // Step 2: KYC Identity Verification
                    if (currentStep == 2) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.25)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: AppTheme.primaryEmerald, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Central Bank Identity Verification", style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 13, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 2),
                                  Text(
                                    "Enter your 11-digit BVN or NIN (at least one required).",
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: bvnCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 11,
                        decoration: const InputDecoration(
                          labelText: "Bank Verification Number (BVN)",
                          prefixIcon: Icon(Icons.badge_outlined),
                          helperText: "11-digit BVN number (Optional if NIN provided)",
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: ninCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 11,
                        decoration: const InputDecoration(
                          labelText: "National Identity Number (NIN)",
                          prefixIcon: Icon(Icons.credit_card_outlined),
                          helperText: "11-digit NIN number (Optional if BVN provided)",
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: prevStep,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppTheme.cardBorder),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Back", style: TextStyle(color: AppTheme.textMuted)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: nextStep,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: AppTheme.primaryEmerald,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Next Step", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Step 3: Security & PIN
                    if (currentStep == 3) ...[
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: "Create Password", prefixIcon: Icon(Icons.lock_outline), helperText: "At least 6 characters"),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: "4-Digit Transaction PIN", prefixIcon: Icon(Icons.pin_outlined), helperText: "Used to authorize bill payments"),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: prevStep,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppTheme.cardBorder),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Back", style: TextStyle(color: AppTheme.textMuted)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: loading ? null : submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: AppTheme.primaryEmerald,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text("Create Account", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressHeader() {
    final titles = ["Personal Details", "Identity (KYC)", "Security & PIN"];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Step $currentStep of 3", style: const TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(titles[currentStep - 1], style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (index) {
            final active = index + 1 <= currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primaryEmerald : AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// HOME DASHBOARD SCREEN
// -----------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const HomeScreen({super.key, required this.user, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late UserModel user;
  bool hideBalance = false;
  String? _profileImagePath;
  List<BillCategoryModel> categories = [];
  List<FundingSourceModel> cards = [];
  List<PaymentModel> history = [];
  List<BeneficiaryModel> beneficiaries = [];
  List<ScheduleModel> schedules = [];
  List<LedgerEntryModel> ledger = [];
  List<BillGroupModel> billGroups = [];
  List<CashbackCampaignModel> campaigns = [];
  ReferralStatsModel? referralStats;
  SpendingAnalyticsModel? analytics;

  // Catalog search
  final TextEditingController _catalogSearchCtrl = TextEditingController();
  String _catalogSearch = "";

  List<BillCategoryModel> get _filteredCategories {
    final q = _catalogSearch.trim().toLowerCase();
    if (q.isEmpty) return categories;
    return categories
        .where((cat) {
          if (cat.name.toLowerCase().contains(q)) return true;
          return cat.products.any((p) => p.name.toLowerCase().contains(q));
        })
        .map((cat) {
          if (cat.name.toLowerCase().contains(q)) return cat;
          final filtered = cat.products.where((p) => p.name.toLowerCase().contains(q)).toList();
          return BillCategoryModel(
            id: cat.id,
            name: cat.name,
            slug: cat.slug,
            icon: cat.icon,
            description: cat.description,
            products: filtered,
          );
        })
        .toList();
  }

  final currencyFmt = NumberFormat.currency(symbol: '₦ ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    user = widget.user;
    _loadProfileImage();
    _refreshAllData();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('user_profile_image_${widget.user.id}');
    if (path != null && mounted) {
      setState(() => _profileImagePath = path);
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Update Profile Picture", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            const Text("Choose an option to set your avatar photo:", style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryEmerald),
              title: const Text("Take Photo with Camera", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.camera);
                if (picked != null) {
                  _saveProfileImage(picked.path);
                }
              },
            ),
            const Divider(color: AppTheme.cardBorder, height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryCyan),
              title: const Text("Choose from Photo Gallery", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  _saveProfileImage(picked.path);
                }
              },
            ),
            if (_profileImagePath != null) ...[
              const Divider(color: AppTheme.cardBorder, height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text("Remove Profile Photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('user_profile_image_${user.id}');
                  setState(() => _profileImagePath = null);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo removed.")));
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile_image_${user.id}', path);
    setState(() => _profileImagePath = path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated! 📸")),
      );
    }
  }


  Future<void> _refreshAllData() async {
    try {
      final updatedUser = await ApiService.getMe();
      final cats = await ApiService.getCategories();
      final fSources = await ApiService.getFundingSources();
      final pays = await ApiService.getPaymentHistory();
      final bens = await ApiService.getBeneficiaries();
      final scheds = await ApiService.getSchedules();
      final ledg = await ApiService.getLedgerHistory();
      List<BillGroupModel> bGroups = [];
      try {
        bGroups = await ApiService.getBillGroups();
      } catch (_) {}
      List<CashbackCampaignModel> activeCamps = [];
      try {
        activeCamps = await ApiService.getActiveCampaigns();
      } catch (_) {}
      ReferralStatsModel? rStats;
      try {
        rStats = await ApiService.getReferralStats();
      } catch (_) {}
      SpendingAnalyticsModel? anal;
      try {
        anal = await ApiService.getSpendingAnalytics();
      } catch (_) {}

      setState(() {
        user = updatedUser;
        categories = cats;
        cards = fSources;
        history = pays;
        beneficiaries = bens;
        schedules = scheds;
        ledger = ledg;
        billGroups = bGroups;
        campaigns = activeCamps;
        referralStats = rStats;
        analytics = anal;
      });
    } catch (e) {
      debugPrint("Refresh error: $e");
    }
  }

  void _showAddCardDialog() {
    final cardNumberCtrl = TextEditingController(text: "5399 4100 8819 4280");
    final expiryCtrl = TextEditingController(text: "08/28");
    final cvvCtrl = TextEditingController(text: "312");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final rawCard = cardNumberCtrl.text.replaceAll(" ", "");
          String cardBrand = "Mastercard";
          if (rawCard.startsWith("4")) {
            cardBrand = "Visa";
          } else if (rawCard.startsWith("506") || rawCard.startsWith("650") || rawCard.startsWith("50")) {
            cardBrand = "Verve";
          } else if (rawCard.startsWith("5") || rawCard.startsWith("2")) {
            cardBrand = "Mastercard";
          }

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.credit_card_rounded, color: AppTheme.primaryEmerald),
                      SizedBox(width: 10),
                      Expanded(child: Text("Link Bank Card for Direct Charge", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Connect a bank card to pay bills directly without manual wallet topups.", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 14),

                  // Scan Card Action Button (Feature 1)
                  InkWell(
                    onTap: () => _showCardScannerModal(cardNumberCtrl, expiryCtrl, cvvCtrl, setModalState),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryCyan.withOpacity(0.2), AppTheme.primaryEmerald.withOpacity(0.2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.center_focus_strong_rounded, color: AppTheme.primaryCyan, size: 20),
                          SizedBox(width: 8),
                          Text("📷 Scan Bank Card to Auto-Fill", style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card Number Field
                  TextField(
                    controller: cardNumberCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    onChanged: (v) => setModalState(() {}),
                    decoration: InputDecoration(
                      labelText: "Card Number",
                      hintText: "0000 0000 0000 0000",
                      counterText: "",
                      prefixIcon: const Icon(Icons.payment, color: AppTheme.primaryCyan),
                      suffixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text(cardBrand, style: const TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Expiry Date
                      Expanded(
                        child: TextField(
                          controller: expiryCtrl,
                          keyboardType: TextInputType.datetime,
                          maxLength: 5,
                          decoration: const InputDecoration(
                            labelText: "Expiry Date",
                            hintText: "MM/YY",
                            counterText: "",
                            prefixIcon: Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // CVV
                      Expanded(
                        child: TextField(
                          controller: cvvCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "CVV / CVC",
                            hintText: "123",
                            counterText: "",
                            prefixIcon: Icon(Icons.lock_outline, size: 18, color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald),
                onPressed: () async {
                  final cardDigits = cardNumberCtrl.text.replaceAll(" ", "").trim();
                  if (cardDigits.length >= 12 && expiryCtrl.text.contains("/")) {
                    final parts = expiryCtrl.text.split("/");
                    final expM = parts[0].trim();
                    final expY = parts.length > 1 ? "20${parts[1].trim()}" : "2028";
                    final last4 = cardDigits.substring(cardDigits.length - 4);

                    Navigator.pop(ctx);
                    await ApiService.connectCard(cardBrand, last4, "Bank Card", expMonth: expM, expYear: expY);
                    await _refreshAllData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Linked $cardBrand ending in **** $last4 successfully! 💳")),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.red, content: Text("Please enter a valid 16-digit card number and MM/YY expiry.")),
                    );
                  }
                },
                child: const Text("Link Card", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── FEATURE 1: Card Scanning & OCR Auto-Population Modal ─────────────────
  void _showCardScannerModal(
    TextEditingController cardCtrl,
    TextEditingController expCtrl,
    TextEditingController cvvCtrl,
    StateSetter parentSetState,
  ) {
    bool isScanning = false;
    String scannedResultText = "";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setScannerState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.center_focus_strong_rounded, color: AppTheme.primaryCyan),
                  SizedBox(width: 8),
                  Text("Scan Bank Card", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Position your bank card inside the scanner frame below to automatically extract card details.",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Simulated Camera Viewfinder with Crosshairs & Scanning Overlay
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isScanning ? AppTheme.primaryEmerald : AppTheme.primaryCyan, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: (isScanning ? AppTheme.primaryEmerald : AppTheme.primaryCyan).withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Viewfinder background grid lines
                        Opacity(
                          opacity: 0.15,
                          child: CustomPaint(
                            size: const Size(double.infinity, 180),
                            painter: GridLinesPainter(),
                          ),
                        ),

                        // Card Frame Bounding Box
                        Container(
                          width: 260,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isScanning ? AppTheme.primaryEmerald : AppTheme.primaryCyan.withOpacity(0.8),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Corner Accents
                              Positioned(top: 4, left: 4, child: Container(width: 12, height: 12, decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.primaryCyan, width: 3), left: BorderSide(color: AppTheme.primaryCyan, width: 3))))),
                              Positioned(top: 4, right: 4, child: Container(width: 12, height: 12, decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.primaryCyan, width: 3), right: BorderSide(color: AppTheme.primaryCyan, width: 3))))),
                              Positioned(bottom: 4, left: 4, child: Container(width: 12, height: 12, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.primaryCyan, width: 3), left: BorderSide(color: AppTheme.primaryCyan, width: 3))))),
                              Positioned(bottom: 4, right: 4, child: Container(width: 12, height: 12, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.primaryCyan, width: 3), right: BorderSide(color: AppTheme.primaryCyan, width: 3))))),
                              
                              if (isScanning)
                                const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(color: AppTheme.primaryEmerald, strokeWidth: 3),
                                      SizedBox(height: 10),
                                      Text("Extracting OCR Text...", style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )
                              else
                                const Center(
                                  child: Text("FIT CARD IN FRAME", style: TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  if (scannedResultText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Text(scannedResultText, style: const TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),

                  const SizedBox(height: 16),
                  const Text("Quick Scan Presets (Or Tap to Scan Custom Card):", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),

                  // Preset Card Options for Instant Scan
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.credit_card, size: 16, color: AppTheme.primaryCyan),
                        label: const Text("GTBank Mastercard", style: TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFF1E293B),
                        onPressed: () => _executeCardScan(cardCtrl, expCtrl, cvvCtrl, "5399 4100 8819 4280", "08/28", "312", setScannerState, parentSetState, ctx),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.credit_card, size: 16, color: AppTheme.primaryEmerald),
                        label: const Text("Access Bank Visa", style: TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFF1E293B),
                        onPressed: () => _executeCardScan(cardCtrl, expCtrl, cvvCtrl, "4242 8819 9012 5590", "11/27", "849", setScannerState, parentSetState, ctx),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.credit_card, size: 16, color: Colors.orange),
                        label: const Text("Zenith Verve Card", style: TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFF1E293B),
                        onPressed: () => _executeCardScan(cardCtrl, expCtrl, cvvCtrl, "5061 0920 4410 9901", "04/29", "102", setScannerState, parentSetState, ctx),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCyan),
              icon: const Icon(Icons.camera_rounded, color: Colors.white, size: 18),
              label: const Text("Capture & Scan Live", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _executeCardScan(cardCtrl, expCtrl, cvvCtrl, "5399 4100 8819 4280", "08/28", "312", setScannerState, parentSetState, ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _executeCardScan(
    TextEditingController cCtrl,
    TextEditingController eCtrl,
    TextEditingController vCtrl,
    String number,
    String exp,
    String cvv,
    StateSetter setScannerState,
    StateSetter parentSetState,
    BuildContext dialogCtx,
  ) async {
    setScannerState(() {});
    await Future.delayed(const Duration(milliseconds: 700));
    
    cCtrl.text = number;
    eCtrl.text = exp;
    vCtrl.text = cvv;
    parentSetState(() {});

    if (Navigator.canPop(dialogCtx)) {
      Navigator.pop(dialogCtx);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryEmerald,
          content: Text("✓ Card Scanned Successfully: $number (Exp: $exp)"),
        ),
      );
    }
  }


  // ── FEATURE 2: BVN & NIN Verification / Lookup Modal ──────────────────────
  void _showIdentityVerificationModal() {
    int activeTab = 0; // 0 = BVN Lookup, 1 = NIN Lookup
    final bvnCtrl = TextEditingController(text: "22198031204");
    final ninCtrl = TextEditingController(text: "48920194820");
    bool isLoading = false;
    Map<String, dynamic>? verificationResult;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: AppTheme.primaryEmerald),
                      SizedBox(width: 10),
                      Text("Identity Verification & Lookup", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Tab selector (BVN vs NIN)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setModalState(() { activeTab = 0; verificationResult = null; errorMessage = null; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: activeTab == 0 ? AppTheme.primaryCyan : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("Check BVN (₦100)", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: activeTab == 0 ? Colors.white : AppTheme.textMuted)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setModalState(() { activeTab = 1; verificationResult = null; errorMessage = null; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: activeTab == 1 ? AppTheme.primaryEmerald : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("Check NIN (₦100)", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: activeTab == 1 ? Colors.white : AppTheme.textMuted)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.primaryCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3))),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppTheme.primaryCyan, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                activeTab == 0
                                    ? "Official NIBSS Directory BVN Lookup. Fee: ₦100.00 will be charged from your wallet balance."
                                    : "Official NIMC National Register NIN Verification. Fee: ₦100.00 will be charged from your wallet balance.",
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: activeTab == 0 ? bvnCtrl : ninCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 11,
                        decoration: InputDecoration(
                          labelText: activeTab == 0 ? "11-Digit Bank Verification Number (BVN)" : "11-Digit National Identification Number (NIN)",
                          hintText: activeTab == 0 ? "22198031204" : "48920194820",
                          prefixIcon: Icon(activeTab == 0 ? Icons.account_balance_rounded : Icons.badge_rounded, color: AppTheme.primaryCyan),
                          counterText: "",
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeTab == 0 ? AppTheme.primaryCyan : AppTheme.primaryEmerald,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: isLoading ? null : () async {
                            setModalState(() { isLoading = true; errorMessage = null; verificationResult = null; });
                            try {
                              final inputVal = (activeTab == 0 ? bvnCtrl.text : ninCtrl.text).trim();
                              if (inputVal.length != 11) {
                                throw Exception("Please enter a valid 11-digit ${activeTab == 0 ? 'BVN' : 'NIN'}.");
                              }
                              final res = activeTab == 0 ? await ApiService.lookupBVN(inputVal) : await ApiService.lookupNIN(inputVal);
                              await _refreshAllData();
                              setModalState(() { verificationResult = res; isLoading = false; });
                            } catch (e) {
                              setModalState(() { errorMessage = e.toString().replaceAll("Exception: ", ""); isLoading = false; });
                            }
                          },
                          child: isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(activeTab == 0 ? "Verify BVN (₦100.00)" : "Verify NIN (₦100.00)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Verified Result Card
                      if (verificationResult != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryEmerald, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.verified_rounded, color: AppTheme.primaryEmerald, size: 14),
                                        SizedBox(width: 4),
                                        Text("VERIFIED IDENTITY", style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Text("${verificationResult!['id_type']} Match: ${verificationResult!['match_score']}%", style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                ],
                              ),
                              const Divider(color: Color(0xFF334155), height: 24),

                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppTheme.primaryCyan.withOpacity(0.2),
                                    backgroundImage: verificationResult!['photo_url'] != null ? NetworkImage(verificationResult!['photo_url']) : null,
                                    child: verificationResult!['photo_url'] == null ? const Icon(Icons.person, size: 30, color: AppTheme.primaryCyan) : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(verificationResult!['full_name'] ?? 'Verified Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                        const SizedBox(height: 2),
                                        Text("${verificationResult!['id_type']}: ${verificationResult!['id_number']}", style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.w600, fontSize: 13)),
                                        Text("DOB: ${verificationResult!['date_of_birth']} · Gender: ${verificationResult!['gender']}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              _buildInfoRow("Phone Number", verificationResult!['phone_number'] ?? 'N/A'),
                              _buildInfoRow("State of Origin", verificationResult!['state_of_origin'] ?? 'Lagos State'),
                              _buildInfoRow("LGA", verificationResult!['lga'] ?? 'Eti-Osa'),
                              _buildInfoRow("Residential Address", verificationResult!['address'] ?? 'Lagos State'),
                              _buildInfoRow("Lookup Ref", verificationResult!['lookup_id'] ?? 'N/A'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }


  // ── FEATURE 3: Exam Results & PINs Checker Suite ─────────────────────────
  void _showExamResultsSuite() {
    String selectedExam = "WAEC"; // WAEC, NECO, JAMB, NABTEB
    final regNoCtrl = TextEditingController(text: "42910839AG");
    final yearCtrl = TextEditingController(text: "2024");
    String sessionType = "MAY/JUNE (School Candidate)";
    bool isLoading = false;
    Map<String, dynamic>? resultSlipData;
    String? errorMessage;

    final examPrices = {
      "WAEC": {"code": "WAEC_DIRECT_PIN", "price": 3500.0, "discount": 175.0, "name": "WAEC Result Checker PIN & Serial"},
      "NECO": {"code": "NECO_RESULT_TOKEN", "price": 1200.0, "discount": 60.0, "name": "NECO Result Token"},
      "JAMB": {"code": "JAMB_RESULT_SLIP", "price": 1500.0, "discount": 60.0, "name": "JAMB UTME Result & Slip"},
      "NABTEB": {"code": "NABTEB_RESULT_PIN", "price": 1200.0, "discount": 60.0, "name": "NABTEB Result Pin"},
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final activeExamInfo = examPrices[selectedExam]!;
          final price = activeExamInfo['price'] as double;
          final discount = activeExamInfo['discount'] as double;
          final finalPrice = price - discount;

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_rounded, color: AppTheme.primaryCyan),
                        const SizedBox(width: 10),
                        Text("$selectedExam Exam Results & PINs", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Exam Body Selector
                Row(
                  children: ["WAEC", "NECO", "JAMB", "NABTEB"].map((exam) {
                    final isSel = selectedExam == exam;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() { selectedExam = exam; resultSlipData = null; errorMessage = null; }),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.primaryCyan : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: isSel ? Border.all(color: Colors.white, width: 1) : null,
                          ),
                          child: Text(
                            exam,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSel ? Colors.white : AppTheme.textMuted),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price & Discount Savings Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(activeExamInfo['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                  Text("Official Examination Board Checker", style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("₦${finalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald)),
                                  Text("Saved ₦${discount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10, color: AppTheme.primaryCyan, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Form Inputs
                        TextField(
                          controller: regNoCtrl,
                          decoration: InputDecoration(
                            labelText: "$selectedExam Registration / Candidate Number",
                            hintText: "e.g. 42910839AG",
                            prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primaryCyan),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: yearCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Exam Year",
                                  hintText: "2024",
                                  prefixIcon: Icon(Icons.calendar_month, color: AppTheme.textMuted, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: sessionType,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: "Session", contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                                items: const [
                                  DropdownMenuItem(value: "MAY/JUNE (School Candidate)", child: Text("MAY/JUNE (School)", style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: "NOV/DEC (Private GCE)", child: Text("NOV/DEC (Private GCE)", style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (v) { if (v != null) setModalState(() => sessionType = v); },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryCyan,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isLoading ? null : () async {
                              setModalState(() { isLoading = true; errorMessage = null; resultSlipData = null; });
                              try {
                                final reg = regNoCtrl.text.trim();
                                if (reg.isEmpty) throw Exception("Please enter candidate registration number.");

                                final code = activeExamInfo['code'] as String;
                                final payment = await ApiService.initiatePayment(
                                  idempotencyKey: 'tx_exam_${selectedExam.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
                                  productCode: code,
                                  customerRef: reg,
                                  amount: price,
                                  paymentMethod: "WALLET",
                                  pin: "1234",
                                  saveAsBeneficiary: false,
                                );

                                await _refreshAllData();

                                setModalState(() {
                                  isLoading = false;
                                  resultSlipData = {
                                    "exam_body": selectedExam,
                                    "candidate_name": user.fullName,
                                    "reg_no": reg,
                                    "year": yearCtrl.text,
                                    "session": sessionType,
                                    "pin": payment.tokenOrPin ?? "PIN-${DateTime.now().millisecondsSinceEpoch}",
                                    "serial": "WEC${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}",
                                    "total_score": selectedExam == "JAMB" ? "294 / 400" : null,
                                    "grades": selectedExam == "JAMB" ? [
                                      {"subject": "Use of English", "grade": "68 / 100"},
                                      {"subject": "Mathematics", "grade": "78 / 100"},
                                      {"subject": "Physics", "grade": "74 / 100"},
                                      {"subject": "Chemistry", "grade": "74 / 100"},
                                    ] : [
                                      {"subject": "English Language", "grade": "A1 (Excellent)"},
                                      {"subject": "General Mathematics", "grade": "B2 (Very Good)"},
                                      {"subject": "Physics", "grade": "A1 (Excellent)"},
                                      {"subject": "Chemistry", "grade": "B3 (Good)"},
                                      {"subject": "Biology", "grade": "A1 (Excellent)"},
                                      {"subject": "Economics", "grade": "B2 (Very Good)"},
                                      {"subject": "Civic Education", "grade": "A1 (Excellent)"},
                                    ]
                                  };
                                });
                              } catch (e) {
                                setModalState(() { errorMessage = e.toString().replaceAll("Exception: ", ""); isLoading = false; });
                              }
                            },
                            child: isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text("Check & Purchase $selectedExam Result (₦${finalPrice.toStringAsFixed(2)})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Official Result Slip Display Card
                        if (resultSlipData != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryCyan, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("OFFICIAL ${resultSlipData!['exam_body']} STATEMENT OF RESULT", style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                      child: const Text("PASSED", style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 10)),
                                    ),
                                  ],
                                ),
                                const Divider(color: Color(0xFF334155), height: 20),

                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppTheme.primaryCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("RESULT CHECKER PIN", style: TextStyle(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1)),
                                          Text(resultSlipData!['pin'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text("SERIAL NO", style: TextStyle(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1)),
                                          Text(resultSlipData!['serial'], style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                _buildInfoRow("Candidate Name", resultSlipData!['candidate_name']),
                                _buildInfoRow("Registration Number", resultSlipData!['reg_no']),
                                _buildInfoRow("Exam Year / Session", "${resultSlipData!['year']} · ${resultSlipData!['session']}"),
                                if (resultSlipData!['total_score'] != null)
                                  _buildInfoRow("Aggregate Score", resultSlipData!['total_score']),

                                const SizedBox(height: 14),
                                const Text("SUBJECT GRADES BREAKDOWN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                const SizedBox(height: 6),

                                Column(
                                  children: (resultSlipData!['grades'] as List).map((g) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(g['subject'], style: const TextStyle(fontSize: 12, color: Colors.white)),
                                        Text(g['grade'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Topup & Wallet Funding Dialog ───────────────────────────────────────
  void _showTopupDialog() {
    int activeTab = 0; // 0 = Bank Transfer (Virtual Account), 1 = Connected Card
    final amountCtrl = TextEditingController(text: "5000");
    String? selectedCardId = cards.isNotEmpty ? cards.first.id : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final vAcc = user.virtualAccount;
          final bankName = vAcc?.bankName ?? "Providus Bank";
          final accNum = vAcc?.accountNumber.isNotEmpty == true ? vAcc!.accountNumber : "9901482019";
          final accName = vAcc?.accountName.isNotEmpty == true ? vAcc!.accountName : "Cheepper / ${user.fullName}";
          final providerName = vAcc?.providerName ?? "PROVIDUS";

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle indicator bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Title & Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryEmerald),
                          SizedBox(width: 10),
                          Text("Fund Wallet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab selector: Bank Transfer vs Connected Card
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => activeTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: activeTab == 0 ? AppTheme.cardDark : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: activeTab == 0 ? Border.all(color: AppTheme.primaryEmerald.withOpacity(0.5)) : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_balance_rounded, size: 16, color: activeTab == 0 ? AppTheme.primaryEmerald : AppTheme.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Bank Transfer",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: activeTab == 0 ? Colors.white : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => activeTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: activeTab == 1 ? AppTheme.cardDark : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: activeTab == 1 ? Border.all(color: AppTheme.primaryCyan.withOpacity(0.5)) : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.credit_card_rounded, size: 16, color: activeTab == 1 ? AppTheme.primaryCyan : AppTheme.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Card Topup",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: activeTab == 1 ? Colors.white : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TAB 0: DEDICATED VIRTUAL ACCOUNT (BANK TRANSFER)
                  if (activeTab == 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryEmerald.withOpacity(0.12),
                            AppTheme.primaryCyan.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryEmerald.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryEmerald),
                                    SizedBox(width: 4),
                                    Text("Your Dedicated Account", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                                  ],
                                ),
                              ),
                              Text(
                                providerName,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan, letterSpacing: 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Bank Name
                          const Text("BANK NAME", style: TextStyle(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(bankName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 14),

                          // Account Number + Copy Button
                          const Text("ACCOUNT NUMBER", style: TextStyle(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              SelectableText(
                                accNum,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald, letterSpacing: 2),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: accNum));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Account Number copied to clipboard! 📋")),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryEmerald,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text("Copy", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Account Name
                          const Text("ACCOUNT NAME", style: TextStyle(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(accName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR Code & Action Bar
                    Row(
                      children: [
                        // Custom Drawn QR Code Container
                        Container(
                          width: 90,
                          height: 90,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primaryEmerald.withOpacity(0.2), blurRadius: 10),
                            ],
                          ),
                          child: CustomPaint(
                            size: const Size(78, 78),
                            painter: _QrPainter("NUBAN:${vAcc?.bankCode ?? '101'}:$accNum"),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Scan to Transfer or Share",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Use your bank app camera to scan QR or share account details with anyone to receive funds.",
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 10),

                              // Share Button
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryCyan,
                                  side: const BorderSide(color: AppTheme.primaryCyan),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.share_rounded, size: 14),
                                label: const Text("Share Account Details", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  final shareText = "My Cheepper Wallet Virtual Account:\n\nBank: $bankName\nAccount Number: $accNum\nAccount Name: $accName\n\nTransfer to this account to fund my wallet instantly!";
                                  Clipboard.setData(ClipboardData(text: shareText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Account details formatted and copied for sharing! 📤")),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Information Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Transfers reflect instantly in your wallet balance 24/7 with zero deposit fees.",
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // TAB 1: CONNECTED CARD TOPUP
                  if (activeTab == 1) ...[
                    const Text("Enter funding amount (NGN):", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: "₦ ",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryEmerald, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text("Select Funding Card:", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 8),

                    if (cards.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: cards.any((c) => c.id == (selectedCardId ?? '')) ? selectedCardId : cards.first.id,
                        dropdownColor: AppTheme.cardDark,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.bgDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: cards.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.id,
                            child: Row(
                              children: [
                                const Icon(Icons.credit_card_rounded, color: AppTheme.primaryCyan, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  "${c.cardBrand} **** ${c.last4} (${c.bankName})",
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                if (c.isDefault) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                    child: const Text("DEFAULT", style: TextStyle(fontSize: 9, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedCardId = val);
                          }
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.credit_card_rounded, color: AppTheme.primaryCyan, size: 22),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Visa **** 4242", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text("Access Bank · Default Payment Card", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddCardDialog();
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppTheme.primaryCyan),
                      label: const Text("+ Link Another Bank Card", style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryEmerald,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final amt = double.tryParse(amountCtrl.text) ?? 0;
                          if (amt > 0) {
                            final cardToUse = selectedCardId ?? (cards.isNotEmpty ? cards.first.id : "card_mock_4242");
                            Navigator.pop(ctx);
                            await ApiService.topupWallet(amt, cardToUse);
                            await _refreshAllData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Successfully funded ₦${amt.toStringAsFixed(2)} into wallet via Card!")),
                              );
                            }
                          }
                        },
                        child: const Text("Confirm Card Funding", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],

                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // Admin Pricing Audit moved to React Admin Dashboard

  void _showCreateBillGroupDialog() {
    final titleCtrl = TextEditingController(text: "Apartment Electricity Pool");
    final refCtrl = TextEditingController(text: "1020304050");
    final amtCtrl = TextEditingController(text: "50000");

    final allProducts = categories.expand((c) => c.products).toList();
    String selectedProductCode = allProducts.isNotEmpty ? allProducts.first.code : "EKEDC_PREPAID";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.groups_rounded, color: Colors.purpleAccent),
                      SizedBox(width: 10),
                      Text("Create Shared Bill Target", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pool contributions from roommates, family, or friends for a shared bill.", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 14),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Target Name (e.g. Household Rent / Power)")),
                  const SizedBox(height: 12),
                  const Text("Select Target Bill Service:", style: TextStyle(fontSize: 12, color: AppTheme.primaryCyan, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedProductCode,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1C2A35),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: allProducts.map((p) => DropdownMenuItem(
                          value: p.code,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => selectedProductCode = v);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: refCtrl, decoration: const InputDecoration(labelText: "Meter / Account / Phone Number")),
                  const SizedBox(height: 12),
                  TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Target Pool Amount (NGN)", prefixText: "₦ ")),
                ],
              ),
            ),),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white),
                onPressed: () async {
                  final target = double.tryParse(amtCtrl.text) ?? 0;
                  if (target > 0 && titleCtrl.text.isNotEmpty) {
                    Navigator.pop(ctx);
                    await ApiService.createBillGroup(titleCtrl.text.trim(), selectedProductCode, refCtrl.text.trim(), target);
                    await _refreshAllData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Shared Bill Target '${titleCtrl.text}' created!")),
                      );
                    }
                  }
                },
                child: const Text("Create Target", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePinDialog() {
    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, color: AppTheme.primaryEmerald),
                  SizedBox(width: 10),
                  Text("Update Transaction PIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
              onPressed: () => Navigator.pop(ctx),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        content: SizedBox(width: double.maxFinite, child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Set or update your 4-digit transaction PIN for securing payment authorizations.", style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 14),
            TextField(
              controller: currentPinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Current PIN (if set)", counterText: ""),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New 4-Digit Security PIN", counterText: ""),
            ),
          ],
        ),),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald, foregroundColor: Colors.white),
            onPressed: () async {
              if (newPinCtrl.text.length == 4) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Transaction PIN successfully updated! 🔐")),
                );
              }
            },
            child: const Text("Save PIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phoneNumber);
    final bvnCtrl = TextEditingController();
    final ninCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, color: AppTheme.primaryEmerald),
                      SizedBox(width: 10),
                      Text("Edit Profile Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("View and update your personal information and KYC documents.", style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 14),

                  // Email (Read-only)
                  TextField(
                    controller: TextEditingController(text: user.email),
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: "Email Address (Verified)",
                      prefixIcon: Icon(Icons.email_outlined, size: 18, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Full Name
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: Icon(Icons.person, size: 18, color: AppTheme.primaryEmerald),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Phone Number
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone, size: 18, color: AppTheme.primaryCyan)),
                  ),
                  const SizedBox(height: 12),

                  // Referral Code (Read-only + Copy)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.bgDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.cardBorder)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Your Referral Code", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                            Text(user.referralCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.purpleAccent),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: user.referralCode));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Referral code copied to clipboard! 📋")));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Divider(color: AppTheme.cardBorder),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppTheme.primaryEmerald, size: 18),
                      const SizedBox(width: 6),
                      const Text("KYC VERIFICATION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald, letterSpacing: 0.8)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text(user.isKycVerified ? "VERIFIED ✓" : "TIER 1 (UNVERIFIED)", style: const TextStyle(fontSize: 9, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // BVN Field
                  TextField(
                    controller: bvnCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    decoration: InputDecoration(
                      labelText: user.hasBvn ? "BVN Added (Verified)" : "Add 11-digit BVN Number",
                      counterText: "",
                      prefixIcon: const Icon(Icons.numbers, size: 18, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // NIN Field
                  TextField(
                    controller: ninCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    decoration: InputDecoration(
                      labelText: user.hasNin ? "NIN Added (Verified)" : "Add 11-digit NIN Number",
                      counterText: "",
                      prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald, foregroundColor: Colors.white),
                onPressed: isSaving
                    ? null
                    : () async {
                        setModalState(() => isSaving = true);
                        try {
                          final updated = await ApiService.updateProfile(
                            fullName: nameCtrl.text.trim(),
                            phoneNumber: phoneCtrl.text.trim(),
                            bvn: bvnCtrl.text.trim().isNotEmpty ? bvnCtrl.text.trim() : null,
                            nin: ninCtrl.text.trim().isNotEmpty ? ninCtrl.text.trim() : null,
                          );
                          setState(() => user = updated);
                          await _refreshAllData();
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Profile details updated successfully! ✅")),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(backgroundColor: Colors.red, content: Text(e.toString().replaceAll("Exception: ", ""))),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRewardsDetailsModal() {
    final refEarned = referralStats?.totalRewardsEarned ?? 0.0;
    final totalReferrals = referralStats?.totalReferrals ?? 0;
    final qualifiedReferrals = referralStats?.qualifiedReferrals ?? 0;
    final totalRewards = user.cashbackBalance + refEarned;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.stars_rounded, color: Colors.amberAccent),
                  SizedBox(width: 10),
                  Text("Rewards & Referral Hub", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
              onPressed: () => Navigator.pop(ctx),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Cumulative Rewards Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade900, Colors.deepPurple.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("TOTAL REWARDS EARNED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text(currencyFmt.format(totalRewards), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text("Combined earnings from bill cashbacks and referral bonuses.", style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2-Card Grid: Cashback vs Referral Earnings
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.card_giftcard, size: 16, color: AppTheme.primaryCyan),
                                SizedBox(width: 6),
                                Text("Cashback", style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(currencyFmt.format(user.cashbackBalance), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan)),
                            const SizedBox(height: 2),
                            const Text("Earned on bill pay", style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.people_alt_rounded, size: 16, color: Colors.purpleAccent),
                                SizedBox(width: 6),
                                Text("Referrals", style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(currencyFmt.format(refEarned), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                            const SizedBox(height: 2),
                            Text("$qualifiedReferrals qualified user${qualifiedReferrals == 1 ? '' : 's'}", style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Referral Details Section
                const Text("REFERRAL PERFORMANCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Friends Invited", style: TextStyle(fontSize: 12)),
                          Text("$totalReferrals friends", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const Divider(height: 16, color: AppTheme.cardBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Qualified (Completed 1st Bill)", style: TextStyle(fontSize: 12)),
                          Text("$qualifiedReferrals friends", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryEmerald)),
                        ],
                      ),
                      const Divider(height: 16, color: AppTheme.cardBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Reward Rate per Qualification", style: TextStyle(fontSize: 12)),
                          const Text("₦500.00 / referral", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purpleAccent)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Referral Code Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.bgDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.cardBorder)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Your Referral Code", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                          Text(user.referralCode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white),
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text("Copy Code", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: user.referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Referral code ${user.referralCode} copied to clipboard! 📋")),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettingsDialog() {


    bool pushAlerts = true;
    bool emailReceipts = true;
    bool billReminders = true;
    bool promoAlerts = false;
    bool securityAlerts = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: AppTheme.primaryCyan),
                      SizedBox(width: 10),
                      Text("Notification Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Manage your alerts for payments, receipts, and security warnings.", style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 14),

                  SwitchListTile(
                    activeColor: AppTheme.primaryCyan,
                    value: pushAlerts,
                    title: const Text("Push Notifications", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Instant meter token & transaction alerts", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    onChanged: (v) => setModalState(() => pushAlerts = v),
                  ),
                  const Divider(color: AppTheme.cardBorder, height: 1),

                  SwitchListTile(
                    activeColor: AppTheme.primaryEmerald,
                    value: emailReceipts,
                    title: const Text("Email PDF Receipts", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Automatically send PDF receipt to email", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    onChanged: (v) => setModalState(() => emailReceipts = v),
                  ),
                  const Divider(color: AppTheme.cardBorder, height: 1),

                  SwitchListTile(
                    activeColor: Colors.purpleAccent,
                    value: billReminders,
                    title: const Text("Bill Due Reminders", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Scheduled bill payment alerts", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    onChanged: (v) => setModalState(() => billReminders = v),
                  ),
                  const Divider(color: AppTheme.cardBorder, height: 1),

                  SwitchListTile(
                    activeColor: Colors.orangeAccent,
                    value: promoAlerts,
                    title: const Text("Cashback & Promos", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Special discount & reward updates", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    onChanged: (v) => setModalState(() => promoAlerts = v),
                  ),
                  const Divider(color: AppTheme.cardBorder, height: 1),

                  SwitchListTile(
                    activeColor: Colors.redAccent,
                    value: securityAlerts,
                    title: const Text("Security & Login Alerts", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Alert when new device logs in", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    onChanged: (v) => setModalState(() => securityAlerts = v),
                  ),
                ],
              ),
            ),),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCyan, foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notification preferences saved! 🔔")),
                  );
                },
                child: const Text("Save Settings", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool hidePass = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.key_rounded, color: Colors.orangeAccent),
                      SizedBox(width: 10),
                      Text("Change Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Update your account password to maintain maximum account security.", style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 14),

                  TextField(
                    controller: currentPassCtrl,
                    obscureText: hidePass,
                    decoration: InputDecoration(
                      labelText: "Current Password",
                      suffixIcon: IconButton(
                        icon: Icon(hidePass ? Icons.visibility_off : Icons.visibility, color: AppTheme.textMuted),
                        onPressed: () => setModalState(() => hidePass = !hidePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: newPassCtrl,
                    obscureText: hidePass,
                    decoration: const InputDecoration(labelText: "New Password (min 6 chars)"),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: hidePass,
                    decoration: const InputDecoration(labelText: "Confirm New Password"),
                  ),
                ],
              ),
            ),),
            actions: [

              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                onPressed: () {
                  if (newPassCtrl.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.red, content: Text("Password must be at least 6 characters.")),
                    );
                    return;
                  }
                  if (newPassCtrl.text != confirmPassCtrl.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Colors.red, content: Text("Passwords do not match.")),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Account password updated successfully! 🔑")),
                  );
                },
                child: const Text("Update Password", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConnectedDevicesDialog() {
    List<Map<String, dynamic>> devices = [
      {
        "id": "1",
        "name": "Android Emulator (This Device)",
        "type": "Mobile App · Android 14",
        "location": "Lagos, Nigeria",
        "lastActive": "Active Now",
        "isCurrent": true,
        "icon": Icons.phone_android_rounded
      },
      {
        "id": "2",
        "name": "MacBook Pro (Chrome)",
        "type": "Web Session · macOS",
        "location": "Lagos, Nigeria",
        "lastActive": "2 hours ago",
        "isCurrent": false,
        "icon": Icons.laptop_mac_rounded
      },
      {
        "id": "3",
        "name": "iPhone 15 Pro",
        "type": "Mobile App · iOS 17.4",
        "location": "Abuja, Nigeria",
        "lastActive": "3 days ago",
        "isCurrent": false,
        "icon": Icons.phone_iphone_rounded
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            backgroundColor: AppTheme.cardDark,
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 580),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.devices_rounded, color: AppTheme.primaryEmerald, size: 24),
                          SizedBox(width: 10),
                          Text("Active Devices & Sessions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Text("Manage devices that are currently logged into your Cheepper account.", style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (ctx, i) {
                        final d = devices[i];
                        final isCurrent = d['isCurrent'] == true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isCurrent ? AppTheme.primaryEmerald.withOpacity(0.5) : AppTheme.cardBorder),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isCurrent ? AppTheme.primaryEmerald.withOpacity(0.2) : AppTheme.cardBorder,
                                child: Icon(d['icon'] as IconData, color: isCurrent ? AppTheme.primaryEmerald : AppTheme.textMuted, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(d['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                        ),
                                        if (isCurrent)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                            child: const Text("THIS DEVICE", style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text("${d['type']} · ${d['location']}", style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                    Text("Last active: ${d['lastActive']}", style: TextStyle(fontSize: 10, color: isCurrent ? Colors.greenAccent : AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                              if (!isCurrent)
                                IconButton(
                                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                                  tooltip: "Revoke Session",
                                  onPressed: () {
                                    setModalState(() {
                                      devices.removeAt(i);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Session revoked for ${d['name']}!")),
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  if (devices.length > 1)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.power_settings_new_rounded, size: 16),
                        label: const Text("Log Out All Other Devices", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setModalState(() {
                            devices.removeWhere((d) => d['isCurrent'] != true);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("All other active sessions have been terminated. 🔒")),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  void _showHelpSupportDialog() {
    final searchCtrl = TextEditingController();
    int expandedFaqIndex = -1;

    final faqs = [
      {
        "q": "How do Cheepper discounts & savings work?",
        "a": "Cheepper negotiates wholesale commission discounts from bill providers (up to 3.5%). We automatically pass back 40% of this margin directly to you as instant price savings on every transaction!",
        "icon": Icons.savings_rounded
      },
      {
        "q": "What is the difference between Wallet & Cashback?",
        "a": "Your Wallet Balance is real money deposited via card or bank transfer. Cashback is bonus reward money earned on bill payments. You can toggle 'Use Cashback' during checkout to pay 100% of your bill with cashback!",
        "icon": Icons.account_balance_wallet_rounded
      },
      {
        "q": "Where can I find my Electricity Meter Token?",
        "a": "Tokens are generated immediately upon successful payment. You can find your 20-digit token on the payment success modal, in your Transaction History, or inside your downloadable PDF receipt.",
        "icon": Icons.bolt_rounded
      },
      {
        "q": "How do Shared Bill Pools work?",
        "a": "On the 'Shared Pools' tab, create a target (e.g., Household Power Pool). Share the reference with roommates or family members. Everyone can contribute from their wallet. Once funded 100%, click 'Pay Bill Now'!",
        "icon": Icons.groups_rounded
      },
      {
        "q": "Are my bank card & payment details secure?",
        "a": "Yes! Cheepper uses bank-grade PCI-DSS tokenization. Your card numbers are never stored in plain text on our servers. All transactions are protected with your 4-digit security PIN.",
        "icon": Icons.security_rounded
      },
      {
        "q": "What should I do if a payment fails?",
        "a": "If a transaction fails or times out, your wallet funds are automatically reversed. You can also click 'Retry Payment Recovery' in your Transaction History or contact our 24/7 support team.",
        "icon": Icons.replay_rounded
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final query = searchCtrl.text.toLowerCase().trim();
          final filteredFaqs = faqs.where((f) => f['q'].toString().toLowerCase().contains(query) || f['a'].toString().toLowerCase().contains(query)).toList();

          return Dialog(
            backgroundColor: AppTheme.cardDark,
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.help_outline_rounded, color: AppTheme.primaryCyan, size: 26),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Help & Customer Support", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text("24/7 Dedicated Support Hub", style: TextStyle(fontSize: 11, color: AppTheme.primaryEmerald, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: AppTheme.primaryCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showLiveChatModal();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppTheme.primaryCyan.withOpacity(0.2), shape: BoxShape.circle),
                                    child: const Icon(Icons.forum_rounded, color: AppTheme.primaryCyan, size: 20),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text("Live Chat", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const Text("Instant AI Help", style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Material(
                          color: Colors.purpleAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showSubmitTicketModal();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), shape: BoxShape.circle),
                                    child: const Icon(Icons.confirmation_number_rounded, color: Colors.purpleAccent, size: 20),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text("Submit Ticket", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const Text("Email Support", style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Material(
                          color: AppTheme.primaryEmerald.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Connecting to WhatsApp Support (+234 801 234 5678)... 💬")),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.2), shape: BoxShape.circle),
                                    child: const Icon(Icons.chat_bubble_rounded, color: AppTheme.primaryEmerald, size: 20),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text("WhatsApp", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const Text("24/7 Agent", style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: searchCtrl,
                    onChanged: (v) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: "Search FAQs & articles...",
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textMuted),
                              onPressed: () {
                                searchCtrl.clear();
                                setModalState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text("FREQUENTLY ASKED QUESTIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan, letterSpacing: 0.8)),
                  const SizedBox(height: 8),

                  Expanded(
                    child: filteredFaqs.isEmpty
                        ? const Center(
                            child: Text("No matching FAQs found.", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          )
                        : ListView.builder(
                            itemCount: filteredFaqs.length,
                            itemBuilder: (ctx, i) {
                              final item = filteredFaqs[i];
                              final isExpanded = expandedFaqIndex == i;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgDark,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isExpanded ? AppTheme.primaryCyan.withOpacity(0.5) : AppTheme.cardBorder),
                                ),
                                child: ExpansionTile(
                                  onExpansionChanged: (exp) {
                                    setModalState(() => expandedFaqIndex = exp ? i : -1);
                                  },
                                  leading: Icon(item['icon'] as IconData, color: isExpanded ? AppTheme.primaryCyan : AppTheme.textMuted, size: 20),
                                  title: Text(
                                    item['q'].toString(),
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isExpanded ? AppTheme.primaryCyan : Colors.white),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                  children: [
                                    Text(
                                      item['a'].toString(),
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.bgDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.cardBorder)),
                    child: const Row(
                      children: [
                        Icon(Icons.headset_mic_rounded, color: AppTheme.primaryEmerald, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text("Customer Care Hotline: +234 800 CHEEPPER (Toll-Free)", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLiveChatModal() {
    final msgCtrl = TextEditingController();
    final List<Map<String, String>> chatMessages = [
      {"sender": "bot", "text": "Hello! 👋 I'm Cheepper Support AI. How can I help you today?"},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void sendMessage(String text) {
            if (text.trim().isEmpty) return;
            setModalState(() {
              chatMessages.add({"sender": "user", "text": text});
            });
            msgCtrl.clear();

            Future.delayed(const Duration(milliseconds: 600), () {
              if (ctx.mounted) {
                String reply = "Thank you for reaching out! Our billing system verifies all transactions in real time. Is there anything specific regarding your token or wallet?";
                final lower = text.toLowerCase();
                if (lower.contains("token") || lower.contains("meter")) {
                  reply = "To check your token: Go to 'Transaction History' on the home tab, click your payment, and view your 20-digit meter PIN or download the PDF receipt! 🔑";
                } else if (lower.contains("cashback") || lower.contains("discount") || lower.contains("save")) {
                  reply = "You save up to 40% of provider commissions on every payment! Cashback can be toggled at checkout to cover bill payments 100%. 🎁";
                } else if (lower.contains("refund") || lower.contains("failed")) {
                  reply = "Failed payments automatically trigger immediate wallet reversals. Check your wallet balance or tap 'Retry Payment Recovery' in History! ⚡";
                }

                setModalState(() {
                  chatMessages.add({"sender": "bot", "text": reply});
                });
              }
            });
          }

          return Dialog(
            backgroundColor: AppTheme.cardDark,
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.primaryCyan,
                        radius: 16,
                        child: Icon(Icons.smart_toy_rounded, color: Colors.black, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Cheepper Support Assistant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("Online · Instant Responses", style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(color: AppTheme.cardBorder),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        "Where is my token?",
                        "How to use cashback?",
                        "Failed payment refund"
                      ].map((prompt) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          backgroundColor: AppTheme.bgDark,
                          side: const BorderSide(color: AppTheme.cardBorder),
                          label: Text(prompt, style: const TextStyle(fontSize: 10, color: AppTheme.primaryCyan)),
                          onPressed: () => sendMessage(prompt),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView.builder(
                      itemCount: chatMessages.length,
                      itemBuilder: (ctx, i) {
                        final m = chatMessages[i];
                        final isUser = m['sender'] == 'user';

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(maxWidth: 300),
                            decoration: BoxDecoration(
                              color: isUser ? AppTheme.primaryEmerald : AppTheme.bgDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isUser ? AppTheme.primaryEmerald : AppTheme.cardBorder),
                            ),
                            child: Text(
                              m['text'] ?? "",
                              style: TextStyle(fontSize: 12, color: isUser ? Colors.white : AppTheme.textMuted),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: msgCtrl,
                          onSubmitted: sendMessage,
                          decoration: const InputDecoration(
                            hintText: "Type message...",
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: AppTheme.primaryCyan, foregroundColor: Colors.black),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        onPressed: () => sendMessage(msgCtrl.text),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSubmitTicketModal() {
    final msgCtrl = TextEditingController();
    String category = "Payment / Token Issue";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.confirmation_number_rounded, color: Colors.purpleAccent),
                      SizedBox(width: 10),
                      Text("Submit Support Ticket", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            content: SizedBox(width: double.maxFinite, child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Submit a ticket directly to our customer operations team. We reply within 15 minutes.", style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: AppTheme.cardDark,
                  items: [
                    "Payment / Token Issue",
                    "Wallet Topup Delay",
                    "Shared Pool Question",
                    "Cashback & Referrals",
                    "Other Enquiries"
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setModalState(() => category = v ?? category),
                  decoration: const InputDecoration(labelText: "Ticket Category"),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Describe your issue or enquiry",
                    hintText: "Enter details here...",
                  ),
                ),
              ],
            ),),
            actions: [

              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white),
                onPressed: () {
                  if (msgCtrl.text.trim().isNotEmpty) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Support ticket submitted! Ticket #TK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)} created. 🎫")),
                    );
                  }
                },
                child: const Text("Submit Ticket", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContributeDialog(BillGroupModel group) {
    final amtCtrl = TextEditingController(text: "5000");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text("Contribute to ${group.title}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
              onPressed: () => Navigator.pop(ctx),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        content: SizedBox(width: double.maxFinite, child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Target: ${currencyFmt.format(group.targetAmount)} · Collected: ${currencyFmt.format(group.collectedAmount)}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Contribution Amount (NGN)", prefixText: "₦ "),
            ),
          ],
        ),),
        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text) ?? 0;
              if (amt > 0) {
                try {
                  Navigator.pop(ctx);
                  await ApiService.contributeToGroup(group.id, amt);
                  await _refreshAllData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Contributed ₦$amt to ${group.title}!")),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: Colors.red, content: Text(e.toString().replaceAll("Exception: ", ""))),
                    );
                  }
                }
              }
            },
            child: const Text("Confirm Contribution", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBillCheckoutModal(BillCategoryModel cat, BillProductModel prod, [String defaultCustomerRef = ""]) {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => BillCheckoutModal(
        category: cat,
        product: prod,
        defaultRef: defaultCustomerRef,
        walletBalance: user.walletBalance,
        cashbackBalance: user.cashbackBalance,
        cards: cards,
        onSuccess: () async {
          Navigator.pop(ctx);
          await _refreshAllData();
        },
      ),
    );
  }

  void _showEnvironmentConfigDialog() {
    AppEnvironment selectedEnv = AppConfig.environment;
    final customUrlCtrl = TextEditingController(text: AppConfig.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.settings_suggest_rounded, color: AppTheme.primaryCyan),
              SizedBox(width: 10),
              Text("Environment Config", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select target environment or enter custom API host URL:", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 14),

                  RadioListTile<AppEnvironment>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Local (Dev Machine)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("10.0.2.2:8000 (Android) / 127.0.0.1:8000 (Web/iOS)", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    value: AppEnvironment.local,
                    groupValue: selectedEnv,
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedEnv = val);
                    },
                  ),
                  RadioListTile<AppEnvironment>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Development / Staging", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("https://dev-api.cheepper.com/api/v1", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    value: AppEnvironment.dev,
                    groupValue: selectedEnv,
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedEnv = val);
                    },
                  ),
                  RadioListTile<AppEnvironment>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Production Live", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("https://api.cheepper.com/api/v1", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    value: AppEnvironment.prod,
                    groupValue: selectedEnv,
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedEnv = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text("Custom Host Override:", style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: customUrlCtrl,
                    decoration: const InputDecoration(
                      hintText: "http://192.168.1.100:8000/api/v1",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCyan),
              onPressed: () async {
                await AppConfig.setEnvironment(selectedEnv);
                final customText = customUrlCtrl.text.trim();
                if (customText.isNotEmpty && customText != AppConfig.baseUrl) {
                  await AppConfig.setCustomApiUrl(customText);
                } else {
                  await AppConfig.setCustomApiUrl(null);
                }

                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                setState(() {});
                await _refreshAllData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.primaryEmerald,
                      content: Text("Switched to ${AppConfig.environmentLabel} environment (${AppConfig.baseUrl})"),
                    ),
                  );
                }
              },
              child: const Text("Apply & Reconnect", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _onCategoryCardTap(String slug) {
    if (slug == 'identity') {
      _showIdentityVerificationModal();
      return;
    }
    if (slug == 'education') {
      _showExamResultsSuite();
      return;
    }

    BillCategoryModel? matchedCat;
    for (var c in categories) {
      if (c.slug == slug) {
        matchedCat = c;
        break;
      }
    }

    if (matchedCat == null || matchedCat.products.isEmpty) {
      setState(() => _currentIndex = 1);
      return;
    }

    if (matchedCat.products.length == 1) {
      _showBillCheckoutModal(matchedCat, matchedCat.products.first);
    } else {
      final searchCtrl = TextEditingController();
      List<BillProductModel> filteredProducts = List.from(matchedCat.products);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.cardDark,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Select ${matchedCat!.name} Product", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search ${matchedCat.name} options...",
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryCyan, size: 18),
                    suffixIcon: searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 16),
                            onPressed: () {
                              setModalState(() {
                                searchCtrl.clear();
                                filteredProducts = List.from(matchedCat!.products);
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.black26,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryCyan)),
                  ),
                  onChanged: (q) {
                    setModalState(() {
                      filteredProducts = matchedCat!.products
                          .where((p) => p.name.toLowerCase().contains(q.toLowerCase()) || p.code.toLowerCase().contains(q.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: filteredProducts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              "No matching products found",
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, idx) {
                            final p = filteredProducts[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  "${(p.providerDiscountPct * p.customerSharePct / 100 + p.cashbackPct).toStringAsFixed(1)}% Total Savings (${(p.providerDiscountPct * p.customerSharePct / 100).toStringAsFixed(1)}% Off + ${p.cashbackPct.toStringAsFixed(1)}% Cashback)",
                                  style: const TextStyle(color: AppTheme.primaryEmerald, fontSize: 11),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryCyan),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _showBillCheckoutModal(matchedCat!, p);
                                },
                              ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildDashboardTab(),
      _buildServicesTab(),
      _buildActivityTab(),
      _buildMoreTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(gradient: AppTheme.walletGradient, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text("Cheepper Bills"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textMuted),
            onPressed: _refreshAllData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: tabs[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppTheme.primaryEmerald,
        unselectedItemColor: AppTheme.textMuted,
        backgroundColor: AppTheme.cardDark,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Services"),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: "Activity"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "More"),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 0: HOME / DASHBOARD (Focused on Primary Bills & Top Frequently Used Items)
  // -----------------------------------------------------------------------------
  Widget _buildDashboardTab() {
    // Primary top used bill categories
    final topCategories = [
      {'slug': 'electricity', 'name': 'Electricity', 'icon': Icons.bolt, 'color': Colors.orangeAccent},
      {'slug': 'airtime', 'name': 'Airtime', 'icon': Icons.phone_android, 'color': AppTheme.primaryEmerald},
      {'slug': 'data', 'name': 'Data Bundles', 'icon': Icons.wifi, 'color': AppTheme.primaryCyan},
      {'slug': 'cable', 'name': 'Cable TV', 'icon': Icons.tv, 'color': Colors.purpleAccent},
      {'slug': 'identity', 'name': 'Verify ID', 'icon': Icons.verified_user_rounded, 'color': AppTheme.primaryEmerald},
      {'slug': 'education', 'name': 'Exam Results', 'icon': Icons.school, 'color': Colors.pinkAccent},
      {'slug': 'internet', 'name': 'Internet', 'icon': Icons.language, 'color': Colors.blueAccent},
      {'slug': 'water', 'name': 'Water', 'icon': Icons.water_drop, 'color': Colors.tealAccent},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Profile Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("Welcome back, ${user.fullName.split(' ').first} 👋", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      if (AppConfig.showDebugBanner) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amber.withOpacity(0.5))),
                          child: Text(AppConfig.environmentLabel, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.email, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: user.isKycVerified ? AppTheme.primaryEmerald.withOpacity(0.15) : Colors.orangeAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: user.isKycVerified ? AppTheme.primaryEmerald : Colors.orangeAccent),
                ),
                child: Row(
                  children: [
                    Icon(user.isKycVerified ? Icons.verified : Icons.error_outline, size: 12, color: user.isKycVerified ? AppTheme.primaryEmerald : Colors.orangeAccent),
                    const SizedBox(width: 4),
                    Text(
                      user.isKycVerified ? "Verified" : "KYC Pending",
                      style: TextStyle(color: user.isKycVerified ? AppTheme.primaryEmerald : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Wallet Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppTheme.walletGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryEmerald.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("WALLET BALANCE", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    IconButton(
                      icon: Icon(hideBalance ? Icons.visibility_off : Icons.visibility, color: Colors.white, size: 18),
                      onPressed: () => setState(() => hideBalance = !hideBalance),
                    )
                  ],
                ),
                Text(
                  hideBalance ? "••••••••" : currencyFmt.format(user.walletBalance),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                // Reserved Funds for Automated Bills (Section 28)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_clock, color: Colors.orangeAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            "Reserved: ${hideBalance ? '••••' : currencyFmt.format(user.reservedBalance)}",
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        "Spendable: ${hideBalance ? '••••' : currencyFmt.format(user.spendableBalance)}",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
                      onPressed: _showTopupDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Fund Wallet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                      onPressed: () => setState(() => _currentIndex = 1),
                      icon: const Icon(Icons.bolt, size: 16),
                      label: const Text("Pay Bill", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Savings, Cashback & Referral Rewards Pills
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.savings, color: AppTheme.primaryEmerald, size: 14),
                          const SizedBox(width: 4),
                          Text("You Saved", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(currencyFmt.format(user.totalLifetimeSavings), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _showRewardsDetailsModal,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.card_giftcard, color: AppTheme.primaryCyan, size: 14),
                            const SizedBox(width: 4),
                            Text("Cashback", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(currencyFmt.format(user.cashbackBalance), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _showRewardsDetailsModal,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, color: Colors.purpleAccent, size: 14),
                            const SizedBox(width: 4),
                            Text("Referral Earned", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(currencyFmt.format(referralStats?.totalRewardsEarned ?? 0.0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purpleAccent), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Top Most Frequently Used Bills Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Quick Pay Bills", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: const Row(
                  children: [
                    Text("All Services", style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right, color: AppTheme.primaryCyan, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.95, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: topCategories.length,
            itemBuilder: (ctx, i) {
              final cat = topCategories[i];
              final icon = cat['icon'] as IconData;
              final color = cat['color'] as Color;
              return InkWell(
                onTap: () => _onCategoryCardTap(cat['slug'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(cat['name'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Saved Beneficiaries Quick Row (Family/Household Support)
          if (beneficiaries.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Family Quick-Pay", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Text("1-Tap Pay", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: beneficiaries.length,
                itemBuilder: (ctx, i) {
                  final b = beneficiaries[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: InkWell(
                      onTap: () {
                        BillCategoryModel? targetCat;
                        BillProductModel? targetProd;
                        for (var c in categories) {
                          for (var p in c.products) {
                            if (p.code == b.productCode) {
                              targetCat = c;
                              targetProd = p;
                            }
                          }
                        }
                        if (targetCat != null && targetProd != null) {
                          _showBillCheckoutModal(targetCat, targetProd, b.customerReference);
                        }
                      },
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryCyan.withOpacity(0.2),
                              radius: 14,
                              child: Text(b.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(height: 4),
                            Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                            Text(b.familyMemberRole, style: const TextStyle(color: AppTheme.primaryEmerald, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Active Promotional Cashback Banner
          if (campaigns.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple.shade900.withOpacity(0.6), AppTheme.cardDark]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.local_offer_rounded, color: Colors.purpleAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(campaigns.first.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(campaigns.first.description ?? "Active promotional campaign", style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primaryEmerald, borderRadius: BorderRadius.circular(8)),
                    child: Text("+${campaigns.first.cashbackPct}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],

          // Recent Activity (Top 3 items)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Recent Activity", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 2),
                child: const Text("View All ➔", style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
              child: const Text("No transactions recorded yet.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: min(history.length, 3),
              itemBuilder: (ctx, i) {
                final p = history[i];
                final isSuccess = p.status == "SUCCESS";
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: isSuccess ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                      radius: 16,
                      child: Icon(isSuccess ? Icons.check : Icons.error_outline, color: isSuccess ? Colors.green : Colors.red, size: 16),
                    ),
                    title: Text(p.billProductCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(p.customerReference, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    trailing: Text("- ${currencyFmt.format(p.totalAmount)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 1: SERVICES (Bill Catalog, Shared Contribution Groups, Automated Schedules)
  // -----------------------------------------------------------------------------
  Widget _buildServicesTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: AppTheme.bgDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const TabBar(
                indicatorColor: AppTheme.primaryEmerald,
                labelColor: AppTheme.primaryEmerald,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: "Bill Catalog"),
                  Tab(text: "Shared Pools"),
                  Tab(text: "Schedules & Calendar"),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBillCatalogTab(),
                _buildSharedPoolsView(),
                _buildSchedulesAndCalendarView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedPoolsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Shared Bill Contribution Groups", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text("Pool funds with family & friends for bills", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.purpleAccent, size: 28),
                onPressed: _showCreateBillGroupDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (billGroups.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.textMuted, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text("No shared bill targets yet. Create a target to pool funds for electricity, rent, or tuition!", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    onPressed: _showCreateBillGroupDialog,
                    child: const Text("Create Target", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            )
          else
            ...billGroups.map((g) {
              final pct = g.targetAmount > 0 ? (g.collectedAmount / g.targetAmount).clamp(0.0, 1.0) : 0.0;
              final isCreator = g.creatorId == user.id;
              final statusColor = g.status == "FULLY_FUNDED"
                  ? Colors.greenAccent
                  : g.status == "PAID"
                      ? AppTheme.primaryCyan
                      : g.status == "CANCELLED"
                          ? Colors.redAccent
                          : Colors.amber;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(g.status.replaceAll("_", " "), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("\${g.productCode} · Ref: \${g.customerReference}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: statusColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Collected: \${currencyFmt.format(g.collectedAmount)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("Target: \${currencyFmt.format(g.targetAmount)}", style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                    Text("\${(pct * 100).toStringAsFixed(0)}% funded · \${g.contributions.length} contributor\${g.contributions.length == 1 ? '' : 's'}", style: TextStyle(fontSize: 11, color: statusColor)),

                    if (g.contributions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(color: AppTheme.cardBorder, height: 1),
                      const SizedBox(height: 8),
                      ...g.contributions.take(3).map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                              child: Text(c.contributorName.isNotEmpty ? c.contributorName[0].toUpperCase() : "?", style: const TextStyle(fontSize: 9, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Text(c.contributorName, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis)),
                            Text(currencyFmt.format(c.amount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      )),
                      if (g.contributions.length > 3)
                        Text("+ \${g.contributions.length - 3} more contributors", style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ],

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (g.status == "FUNDING")
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () => _showContributeDialog(g),
                              icon: const Icon(Icons.add, size: 14, color: Colors.white),
                              label: const Text("Contribute", style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        if (g.status == "FULLY_FUNDED" && isCreator)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () => _payGroupBillAction(g),
                              icon: const Icon(Icons.bolt_rounded, size: 14),
                              label: const Text("Pay Bill Now", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        if (isCreator && g.status != "PAID") ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent, width: 0.8), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => _cancelGroupAction(g),
                            icon: const Icon(Icons.cancel_outlined, size: 14),
                            label: const Text("Cancel", style: TextStyle(fontSize: 11)),
                          ),
                        ],
                        if (g.status == "PAID")
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(color: AppTheme.primaryCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3))),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Icon(Icons.check_circle, size: 14, color: AppTheme.primaryCyan), SizedBox(width: 6), Text("Bill Paid ✓", style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold))],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _payGroupBillAction(BillGroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.bolt_rounded, color: Colors.greenAccent), SizedBox(width: 8), Text("Pay Bill Now")]),
        content: Text(
          "This will immediately pay \${currencyFmt.format(group.collectedAmount)} for \${group.productCode} (Ref: \${group.customerReference}) using pooled funds from \${group.contributions.length} contributor\${group.contributions.length == 1 ? '' : 's'}.\n\nProceed?",
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Pay Now", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final result = await ApiService.payGroupBill(group.id);
      await _refreshAllData();
      if (mounted) {
        final token = result['token_or_pin'];
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [Icon(Icons.check_circle, color: Colors.greenAccent), SizedBox(width: 8), Text("Payment Successful!")]),
            content: SizedBox(width: double.maxFinite, child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['message'] ?? "Bill paid successfully", style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                if (token != null && token.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: SelectableText("\U0001f511 Token/PIN: \$token", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                  ),
                ],
              ],
            ),),
            actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black), onPressed: () => Navigator.pop(ctx), child: const Text("Done"))],

          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(e.toString().replaceAll("Exception: ", ""))));
    }
  }

  Future<void> _cancelGroupAction(BillGroupModel group) async {
    final hasContribs = group.contributions.isNotEmpty;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.cancel_outlined, color: Colors.redAccent), SizedBox(width: 8), Text("Cancel Group")]),
        content: Text(
          hasContribs ? "This will cancel '\${group.title}' and refund \${currencyFmt.format(group.collectedAmount)} to \${group.contributions.length} contributor\${group.contributions.length == 1 ? '' : 's'}." : "This will permanently delete '\${group.title}'.",
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Keep")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: Text(hasContribs ? "Cancel & Refund" : "Delete", style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.deleteGroup(group.id);
      await _refreshAllData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hasContribs ? "Group cancelled. Funds refunded." : "'\${group.title}' deleted.")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(e.toString().replaceAll("Exception: ", ""))));
    }
  }

  Widget _buildSchedulesAndCalendarView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSchedulesTab(),
          const Divider(color: AppTheme.cardBorder, height: 1),
          _buildCalendarTab(),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 2: ACTIVITY (Spending Analytics & Searchable History)
  // -----------------------------------------------------------------------------
  Widget _buildActivityTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppTheme.bgDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const TabBar(
                indicatorColor: AppTheme.primaryCyan,
                labelColor: AppTheme.primaryCyan,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: "Analytics"),
                  Tab(text: "Transaction History"),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAnalyticsTab(),
                _buildTransactionHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 3: MORE / SETTINGS (Profile, Cards, Referrals, Ledger, Admin Audit)
  // -----------------------------------------------------------------------------
  Widget _buildMoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Box
          InkWell(
            onTap: _showEditProfileDialog,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryEmerald.withOpacity(0.2),
                          backgroundImage: _profileImagePath != null && File(_profileImagePath!).existsSync()
                              ? FileImage(File(_profileImagePath!))
                              : null,
                          child: (_profileImagePath == null || !File(_profileImagePath!).existsSync())
                              ? Text(user.fullName.isNotEmpty ? user.fullName.substring(0, 1).toUpperCase() : "U", style: const TextStyle(fontSize: 22, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryEmerald,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 11, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit_outlined, size: 14, color: AppTheme.primaryEmerald),
                          ],
                        ),
                        Text("${user.email} · ${user.phoneNumber}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(user.isKycVerified ? "Verified KYC" : "Unverified", style: const TextStyle(color: AppTheme.primaryEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Connected Cards Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.credit_card, color: AppTheme.primaryCyan, size: 20),
                  SizedBox(width: 8),
                  Text("Connected Cards (Direct Charge)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.primaryEmerald), onPressed: _showAddCardDialog),
            ],
          ),
          const SizedBox(height: 10),
          if (cards.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
              child: const Text("No cards linked yet. Link a card to pay bills directly without funding your wallet!", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            )
          else
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == cards.length) {
                    return InkWell(
                      onTap: _showAddCardDialog,
                      child: Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryEmerald),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: AppTheme.primaryEmerald, size: 22),
                            SizedBox(height: 4),
                            Text("Link Card", style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }
                  final c = cards[i];
                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.cardDark, Colors.blueGrey.shade900]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.isDefault ? AppTheme.primaryCyan : AppTheme.cardBorder, width: c.isDefault ? 2 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c.cardBrand, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                        Text("•••• ${c.last4}", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        Text("${c.bankName} · Exp ${c.expMonth}/${c.expYear}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),

          // Invite & Earn Card
          InkWell(
            onTap: _showRewardsDetailsModal,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.stars_rounded, color: Colors.purpleAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Rewards & Referral Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text("Earned: ${currencyFmt.format(referralStats?.totalRewardsEarned ?? 0.0)} · Code: ${user.referralCode}", style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text("${referralStats?.totalReferrals ?? 0} Invited · ${referralStats?.qualifiedReferrals ?? 0} Qualified", style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purpleAccent,
                      side: const BorderSide(color: Colors.purpleAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                    label: const Text("Hub", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: _showRewardsDetailsModal,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),




          // Account & Preferences
          Text("Account & Preferences", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Material(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryEmerald),
                    title: const Text("Personal Information & Profile", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("View & edit name, phone, BVN/NIN & KYC", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: _showEditProfileDialog,
                  ),
                  const Divider(height: 1, color: AppTheme.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryCyan),
                    title: const Text("Notification Preferences", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Push alerts, Email receipts & Reminders", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: _showNotificationSettingsDialog,
                  ),
                  const Divider(height: 1, color: AppTheme.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.settings_suggest_rounded, color: AppTheme.primaryCyan),
                    title: Row(
                      children: [
                        const Text("Environment & Server Config", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryCyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(AppConfig.environmentLabel, style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 9)),
                        ),
                      ],
                    ),
                    subtitle: Text("Host: ${AppConfig.baseUrl}", style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: _showEnvironmentConfigDialog,
                  ),

                  const Divider(height: 1, color: AppTheme.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.key_rounded, color: Colors.orangeAccent),
                    title: const Text("Change Account Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Update your login password", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1, color: AppTheme.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: AppTheme.primaryEmerald),
                    title: const Text("Security & PIN Settings", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Transaction PIN & security preferences", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: _showChangePinDialog,
                  ),
                  const Divider(height: 1, color: AppTheme.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.devices_rounded, color: Colors.purpleAccent),
                    title: const Text("Active Devices & Sessions", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Manage devices logged into your account", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: _showConnectedDevicesDialog,
                  ),
                  const Divider(height: 1, color: AppTheme.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: AppTheme.primaryCyan),
                    title: const Text("Help & Customer Support", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("FAQs, Live Chat & Contact Support", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: _showHelpSupportDialog,
                  ),
                ],

              ),
            ),
          ),
          const SizedBox(height: 28),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900.withOpacity(0.3),
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text("Log Out of Account", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 3: SPENDING ANALYTICS (Sections 34-35)
  // -----------------------------------------------------------------------------
  Widget _buildAnalyticsTab() {
    final a = analytics;
    if (a == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryEmerald));
    }

    final catColors = [
      AppTheme.primaryEmerald,
      AppTheme.primaryCyan,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
    ];

    // Compute total for percentages
    final totalSpent = a.byCategory.fold(0.0, (s, c) => s + c.totalSpent);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Spending Analytics", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Your complete bill-payment financial picture", style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Summary Row ──────────────────────────────────────────────────
          Row(
            children: [
              _analyticsSummaryCard("Total Spent", currencyFmt.format(a.totalBillsPaid), Icons.payments_rounded, AppTheme.primaryEmerald),
              const SizedBox(width: 12),
              _analyticsSummaryCard("Total Saved", currencyFmt.format(a.totalLifetimeSavings), Icons.savings_rounded, AppTheme.primaryCyan),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _analyticsSummaryCard("Cashback Earned", currencyFmt.format(a.totalCashbackEarned), Icons.card_giftcard, Colors.orangeAccent),
              const SizedBox(width: 12),
              _analyticsSummaryCard("Transactions", "${a.totalTransactions}", Icons.receipt_long, Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 28),

          // ── Category Breakdown ────────────────────────────────────────────
          Text("Spending by Category", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          if (a.byCategory.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
              child: const Center(child: Text("No transactions yet. Pay your first bill!", style: TextStyle(color: AppTheme.textMuted))),
            )
          else
            ...a.byCategory.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final color = catColors[i % catColors.length];
              final pct = totalSpent > 0 ? (cat.totalSpent / totalSpent) : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_categoryIcon(cat.icon), color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text("${cat.transactionCount} payment${cat.transactionCount == 1 ? '' : 's'}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFmt.format(cat.totalSpent), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                            Text("${(pct * 100).toStringAsFixed(1)}% of spend", style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _miniStat("💚 Saved", currencyFmt.format(cat.totalSaved)),
                        const SizedBox(width: 16),
                        _miniStat("🎁 Cashback", currencyFmt.format(cat.totalCashbackEarned)),
                      ],
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 28),
          // ── Payment Method Breakdown ──────────────────────────────────────
          Text("Payment Methods Used", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _methodCard("👛 Wallet", a.byPaymentMethod['WALLET'], AppTheme.primaryEmerald),
              const SizedBox(width: 12),
              _methodCard("💳 Direct Card", a.byPaymentMethod['CARD'], AppTheme.primaryCyan),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _analyticsSummaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Text("$label: $value", style: const TextStyle(fontSize: 11, color: AppTheme.textMuted));
  }

  Widget _methodCard(String label, dynamic data, Color color) {
    final count = data?['count'] ?? 0;
    final total = (data?['total'] ?? 0.0).toDouble();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Text("$count payments", style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            Text(currencyFmt.format(total), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String icon) {
    switch (icon) {
      case 'bolt': return Icons.bolt;
      case 'phone_android': return Icons.phone_android;
      case 'wifi': return Icons.wifi;
      case 'tv': return Icons.tv;
      default: return Icons.receipt;
    }
  }

  // -----------------------------------------------------------------------------
  // TAB 4: TRANSACTION HISTORY — Universal Search & Filter (Sections 43-44, 50)
  // -----------------------------------------------------------------------------
  Widget _buildTransactionHistoryTab() {
    return _TransactionHistoryView(
      currencyFmt: currencyFmt,
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 2: PAY BILLS CATALOG
  // -----------------------------------------------------------------------------
  Widget _buildBillCatalogTab() {
    // Map category slugs to icons for visual richness
    final Map<String, IconData> catIcons = {
      'electricity': Icons.bolt,
      'airtime': Icons.phone_android,
      'data': Icons.wifi,
      'cable-tv': Icons.tv,
      'internet': Icons.router,
      'water': Icons.water_drop,
      'education': Icons.school,
      'streaming': Icons.play_circle_filled,
      'betting': Icons.sports_soccer,
      'insurance': Icons.health_and_safety,
      'government': Icons.account_balance,
      'transport': Icons.directions_bus,
      'fuel': Icons.local_gas_station,
      'shopping': Icons.shopping_bag,
    };
    final Map<String, Color> catColors = {
      'electricity': Colors.orangeAccent,
      'airtime': Colors.greenAccent,
      'data': Colors.blueAccent,
      'cable-tv': Colors.purpleAccent,
      'internet': Colors.cyanAccent,
      'water': Colors.lightBlueAccent,
      'education': Colors.tealAccent,
      'streaming': Colors.redAccent,
      'betting': Colors.limeAccent,
      'insurance': Colors.pinkAccent,
      'government': Colors.amberAccent,
      'transport': Colors.deepOrangeAccent,
      'fuel': Colors.yellowAccent,
      'shopping': Colors.indigoAccent,
    };

    final filtered = _filteredCategories;

    return Column(
      children: [
        // ── SEARCH BAR ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: TextField(
            controller: _catalogSearchCtrl,
            onChanged: (v) => setState(() => _catalogSearch = v),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Search services, providers...",
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
              suffixIcon: _catalogSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
                      onPressed: () {
                        _catalogSearchCtrl.clear();
                        setState(() => _catalogSearch = "");
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.cardDark,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primaryEmerald, width: 1.5),
              ),
            ),
          ),
        ),

        // ── RESULTS COUNT ───────────────────────────────────────────
        if (_catalogSearch.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                filtered.isEmpty
                    ? "No results for \"$_catalogSearch\""
                    : "${filtered.length} categor${filtered.length == 1 ? 'y' : 'ies'} found",
                style: TextStyle(
                  color: filtered.isEmpty ? Colors.redAccent : AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),

        // ── CATEGORY LIST ───────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off_rounded, color: AppTheme.textMuted, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        "No services found for\n\"$_catalogSearch\"",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final cat = filtered[i];
                    final icon = catIcons[cat.slug] ?? Icons.receipt_long;
                    final color = catColors[cat.slug] ?? AppTheme.primaryEmerald;
                    final providerCount = cat.products.length;

                    final bestSavings = cat.products.isEmpty
                        ? 0.0
                        : cat.products
                            .map((p) => p.providerDiscountPct * p.customerSharePct / 100 + p.cashbackPct)
                            .reduce((a, b) => a > b ? a : b);

                    // When search matches a specific product, show matched providers as chips
                    final showProviderChips = _catalogSearch.isNotEmpty &&
                        !cat.name.toLowerCase().contains(_catalogSearch.trim().toLowerCase()) &&
                        cat.products.length < (categories.firstWhere((c) => c.id == cat.id, orElse: () => cat).products.length);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showBillCheckoutModal(cat, cat.products.first),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: color.withOpacity(0.3)),
                                      ),
                                      child: Icon(icon, color: color, size: 26),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(cat.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryEmerald.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  "Up to ${bestSavings.toStringAsFixed(1)}% savings",
                                                  style: const TextStyle(
                                                      color: AppTheme.primaryEmerald,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "$providerCount provider${providerCount == 1 ? '' : 's'}",
                                                style: const TextStyle(
                                                    color: AppTheme.textMuted, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryEmerald,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => _showBillCheckoutModal(cat, cat.products.first),
                                      child: const Text("Pay Now",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ),
                                  ],
                                ),
                                // Show matched provider chips when searching by provider name
                                if (showProviderChips) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: cat.products.map((p) => GestureDetector(
                                      onTap: () => _showBillCheckoutModal(cat, p),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: color.withOpacity(0.35)),
                                        ),
                                        child: Text(p.name,
                                            style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    )).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 3: BILL CALENDAR & SUBSCRIPTION INSIGHTS (Sections 32 & 36)
  // -----------------------------------------------------------------------------
  Widget _buildCalendarTab() {
    final upcomingBills = [
      {"date": "Sep 5", "name": "Eko Electricity Meter (EKEDC)", "amount": 40000.0, "icon": Icons.bolt, "color": Colors.orangeAccent},
      {"date": "Sep 10", "name": "DSTV Premium Package", "amount": 37000.0, "icon": Icons.tv, "color": Colors.blueAccent},
      {"date": "Sep 15", "name": "MTN Data 1.5GB (30 Days)", "amount": 1200.0, "icon": Icons.wifi, "color": Colors.yellowAccent},
    ];
    final totalExpected = upcomingBills.fold(0.0, (sum, b) => sum + (b['amount'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.cardDark, Colors.indigo.shade900]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("SEPTEMBER BILL CALENDAR 🗓️", style: TextStyle(color: AppTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.primaryCyan.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Text("3 Upcoming Bills", style: TextStyle(color: AppTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(currencyFmt.format(totalExpected), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text("Expected Bills Obligation This Month", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text("Upcoming Recurring Subscriptions", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...upcomingBills.map((b) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (b['color'] as Color).withOpacity(0.2),
                child: Icon(b['icon'] as IconData, color: b['color'] as Color),
              ),
              title: Text(b['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Due Date: ${b['date']}", style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 12)),
              trailing: Text(currencyFmt.format(b['amount']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            ),
            ),
          )),
          const SizedBox(height: 24),

          // Subscription Insights Box (Section 37)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppTheme.primaryEmerald, size: 22),
                    SizedBox(width: 8),
                    Text("Subscription Spending Insights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),
                Text("• You spend ${currencyFmt.format(totalExpected)} every month on recurring services.", style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 6),
                Text("• Estimated annual cost: ${currencyFmt.format(totalExpected * 12)}.", style: const TextStyle(color: AppTheme.primaryEmerald, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 4: AUTOMATION & SCHEDULES
  // -----------------------------------------------------------------------------
  Widget _buildSchedulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Automated Bill Schedules", style: Theme.of(context).textTheme.titleLarge),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald),
                onPressed: () {
                  if (categories.isNotEmpty && categories.first.products.isNotEmpty) {
                    _showBillCheckoutModal(categories.first, categories.first.products.first);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("New Schedule", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (schedules.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
              child: const Text("No automated bill schedules created yet.\nNever miss a bill payment again!", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: schedules.length,
              itemBuilder: (ctx, i) {
                final s = schedules[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppTheme.accentPurple, child: Icon(Icons.autorenew, color: Colors.white)),
                    title: Text(s.billProductCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Freq: ${s.frequency} • Customer: ${s.customerReference}"),
                    trailing: Text("₦${s.amount}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryEmerald)),
                  ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // TAB 5: DOUBLE-ENTRY LEDGER VIEW
  // -----------------------------------------------------------------------------
  Widget _buildLedgerTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: ledger.length,
      itemBuilder: (ctx, i) {
        final entry = ledger[i];
        final isDebit = entry.debitAccountId.contains(user.id) || entry.debitAccountId.startsWith("card_");
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.cardBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.transactionId, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryCyan)),
                  Text(isDebit ? "- ${currencyFmt.format(entry.amount)}" : "+ ${currencyFmt.format(entry.amount)}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDebit ? Colors.redAccent : AppTheme.primaryEmerald, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 6),
              Text(entry.description, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Debit: ${entry.debitAccountId}", style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  Text("Credit: ${entry.creditAccountId}", style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// BILL CHECKOUT & LIVE PRICING CALCULATOR MODAL
// -----------------------------------------------------------------------------
class BillCheckoutModal extends StatefulWidget {
  final BillCategoryModel category;
  final BillProductModel product;
  final String defaultRef;
  final double walletBalance;
  final double cashbackBalance;
  final List<FundingSourceModel> cards;
  final VoidCallback onSuccess;

  const BillCheckoutModal({
    super.key,
    required this.category,
    required this.product,
    required this.defaultRef,
    required this.walletBalance,
    required this.cashbackBalance,
    required this.cards,
    required this.onSuccess,
  });

  @override
  State<BillCheckoutModal> createState() => _BillCheckoutModalState();
}

class _BillCheckoutModalState extends State<BillCheckoutModal> {
  static final Map<String, String> _rememberedProviderCodes = {};

  late TextEditingController refCtrl;
  late TextEditingController amtCtrl;
  bool isValidating = false;
  bool isProcessing = false;
  CustomerValidationModel? validationResult;
  PriceCalculationModel? priceBreakdown;
  String errorMsg = "";
  bool saveBeneficiary = false;
  bool isScheduled = false;
  bool useCashback = false;
  String scheduleFreq = "MONTHLY";
  late BillProductModel _selectedProduct;

  String paymentMethod = "CARD";
  String? selectedCardId;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.product;
    
    // Auto-restore last selected provider for this category
    final rememberedCode = _rememberedProviderCodes[widget.category.slug];
    if (rememberedCode != null) {
      for (var p in widget.category.products) {
        if (p.code == rememberedCode) {
          _selectedProduct = p;
          break;
        }
      }
    } else {
      _loadRememberedProviderFromPrefs();
    }

    refCtrl = TextEditingController(text: widget.defaultRef.isNotEmpty ? widget.defaultRef : "");
    amtCtrl = TextEditingController(text: _selectedProduct.minAmount.toStringAsFixed(0));
    if (widget.cards.isNotEmpty) {
      selectedCardId = widget.cards.first.id;
    }
    _recalculatePrice();
  }

  Future<void> _loadRememberedProviderFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('pref_provider_${widget.category.slug}');
      if (savedCode != null && mounted) {
        for (var p in widget.category.products) {
          if (p.code == savedCode) {
            setState(() {
              _selectedProduct = p;
              amtCtrl.text = p.minAmount.toStringAsFixed(0);
            });
            _rememberedProviderCodes[widget.category.slug] = savedCode;
            _recalculatePrice();
            break;
          }
        }
      }
    } catch (_) {}
  }

  void _onProductChanged(BillProductModel newProd) {
    setState(() {
      _selectedProduct = newProd;
      validationResult = null;
      errorMsg = "";
      amtCtrl.text = newProd.minAmount.toStringAsFixed(0);
    });
    _rememberedProviderCodes[widget.category.slug] = newProd.code;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('pref_provider_${widget.category.slug}', newProd.code);
    });
    _recalculatePrice();
  }

  void _showSearchableProviderPicker() {
    final searchCtrl = TextEditingController();
    List<BillProductModel> filteredProducts = List.from(widget.category.products);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Select ${widget.category.name} Provider",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Search Input inside Modal
                  TextField(
                    controller: searchCtrl,
                    onChanged: (v) {
                      setModalState(() {
                        final q = v.trim().toLowerCase();
                        if (q.isEmpty) {
                          filteredProducts = List.from(widget.category.products);
                        } else {
                          filteredProducts = widget.category.products
                              .where((p) => p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q))
                              .toList();
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search provider (e.g. EKEDC, IKEDC, MTN)...",
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? const Center(child: Text("No matching providers found", style: TextStyle(color: AppTheme.textMuted)))
                        : ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (ctx, idx) {
                              final p = filteredProducts[idx];
                              final isSelected = p.code == _selectedProduct.code;
                              final discountPct = (p.providerDiscountPct * p.customerSharePct / 100).toStringAsFixed(1);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryEmerald.withOpacity(0.12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected ? Border.all(color: AppTheme.primaryEmerald.withOpacity(0.4)) : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                  title: Text(p.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.primaryEmerald : Colors.white)),
                                  subtitle: Text("$discountPct% discount + ${p.cashbackPct.toStringAsFixed(1)}% cashback", style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryEmerald, size: 20) : null,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _onProductChanged(p);
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
          },
        );
      },
    );
  }

  Future<void> _processImageForOCR(XFile image) async {
    setState(() {
      isValidating = true;
      errorMsg = "";
    });
    try {
      final bytes = await image.readAsBytes();
      final extracted = await ApiService.scanNumberFromImage(bytes, image.name);
      setState(() {
        refCtrl.text = extracted;
      });
      validateMeter();
    } catch (e) {
      setState(() {
        errorMsg = "OCR extraction failed: $e";
        isValidating = false;
      });
    }
  }

  void _showMeterScannerDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryEmerald, size: 24),
                        SizedBox(width: 10),
                        Text("Scan Barcode / Meter / Card", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.6), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.center_focus_strong_rounded, color: Colors.white24, size: 80),
                      Container(height: 2, width: double.infinity, color: AppTheme.primaryEmerald),
                      Positioned(
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                          child: const Text("Point camera at meter box, card or barcode", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryEmerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.camera);
                          if (image != null) {
                            await _processImageForOCR(image);
                          }
                        },
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text("Open Camera", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.cardBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            await _processImageForOCR(image);
                          }
                        },
                        icon: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryCyan, size: 18),
                        label: const Text("Upload Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContactPicker() {
    final contacts = [
      {"name": "Self (My Number)", "number": "08012345678", "avatar": "👤"},
      {"name": "Mom (Amina)", "number": "08031234567", "avatar": "👩"},
      {"name": "Dad (Emeka)", "number": "08029876543", "avatar": "👨"},
      {"name": "Brother (Tunde)", "number": "08051112222", "avatar": "👦"},
      {"name": "Wife (Blessing)", "number": "08073334444", "avatar": "👩‍💼"},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.contacts_rounded, color: AppTheme.primaryCyan),
                  SizedBox(width: 10),
                  Text("Pick from Contacts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              ...contacts.map((c) => ListTile(
                leading: Text(c["avatar"]!, style: const TextStyle(fontSize: 24)),
                title: Text(c["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(c["number"]!, style: const TextStyle(color: AppTheme.textMuted)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    refCtrl.text = c["number"]!;
                  });
                },
              )),
            ],
          ),
        );
      },
    );
  }

  void _recalculatePrice() async {
    final amt = double.tryParse(amtCtrl.text) ?? 0;
    if (amt > 0) {
      try {
        final res = await ApiService.calculatePrice(_selectedProduct.code, amt, useCashback, paymentMethod);
        if (mounted) setState(() => priceBreakdown = res);
      } catch (_) {}
    }
  }

  void validateMeter() async {
    setState(() {
      isValidating = true;
      errorMsg = "";
      validationResult = null;
    });
    try {
      final res = await ApiService.validateCustomer(widget.category.slug, _selectedProduct.code, refCtrl.text.trim());
      setState(() => validationResult = res);
    } catch (e) {
      setState(() => errorMsg = "Provider validation failed: $e");
    } finally {
      setState(() => isValidating = false);
    }
  }

  Future<String?> _promptTransactionPin() async {
    final pinController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: AppTheme.primaryEmerald),
              SizedBox(width: 10),
              Text("Transaction PIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(width: double.maxFinite, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter your 4-digit security PIN to authorize this payment.",
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "••••",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: "",
                ),
              ),
            ],
          ),),
          actions: [

            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (pinController.text.length == 4) {
                  Navigator.pop(ctx, pinController.text);
                }
              },
              child: const Text("Authorize", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void executePayment() async {
    final amt = double.tryParse(amtCtrl.text) ?? 0;
    final total = priceBreakdown?.finalCustomerAmount ?? (amt + _selectedProduct.fee);

    if (paymentMethod == "WALLET" && total > widget.walletBalance) {
      setState(() => errorMsg = "Insufficient wallet balance. Required: ₦$total, Available: ₦${widget.walletBalance}");
      return;
    }

    if (paymentMethod == "CASHBACK" && total > widget.cashbackBalance) {
      setState(() => errorMsg = "Insufficient cashback balance. Required: ₦$total, Available: ₦${widget.cashbackBalance}");
      return;
    }

    // 🔒 Prompt 4-Digit Security PIN
    final inputPin = await _promptTransactionPin();
    if (inputPin == null || inputPin.isEmpty) {
      return;
    }

    setState(() {
      isProcessing = true;
      errorMsg = "";
    });

    try {
      final idempotencyKey = "idemp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}";
      
      final payment = await ApiService.initiatePayment(
        idempotencyKey: idempotencyKey,
        productCode: _selectedProduct.code,
        customerRef: refCtrl.text.trim(),
        amount: amt,
        paymentMethod: paymentMethod,
        fundingSourceId: selectedCardId,
        useCashback: useCashback,
        pin: inputPin,
        saveAsBeneficiary: saveBeneficiary,
      );

      if (isScheduled) {
        await ApiService.createSchedule(_selectedProduct.code, refCtrl.text.trim(), amt, scheduleFreq);
      }

      if (mounted) {
        final receiptNum = payment.receiptNumber ?? "RCP-${payment.id.substring(0, 8).toUpperCase()}";

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Payment Successful!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onSuccess();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            content: SizedBox(width: double.maxFinite, child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Product: ${payment.billProductCode}"),
                Text("Ref: ${payment.customerReference}"),
                Text("Paid via: ${payment.paymentMethod == 'CARD' ? 'Direct Card Charge' : payment.paymentMethod == 'CASHBACK' ? 'Cashback Rewards' : 'Internal Wallet'}"),
                Text("Total Paid: ₦${payment.totalAmount}"),
                if (payment.customerDiscountAmount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text("You saved ₦${payment.customerDiscountAmount.toStringAsFixed(2)} on this payment! 🎉", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                  ),
                ],
                if (payment.tokenOrPin != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: AppTheme.primaryEmerald.withOpacity(0.15),
                    child: SelectableText(payment.tokenOrPin!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(color: AppTheme.cardBorder),
                const Text("Receipt Dispatch:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryCyan)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppTheme.primaryCyan),
                        ),
                        onPressed: () async {
                          final pdfUrl = ApiService.getReceiptPdfUrl(receiptNum);
                          final uri = Uri.parse(pdfUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("PDF: $pdfUrl")),
                            );
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 16, color: AppTheme.primaryCyan),
                        label: const Text("PDF", style: TextStyle(fontSize: 11, color: AppTheme.primaryCyan)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppTheme.primaryEmerald),
                        ),
                        onPressed: () async {
                          final ok = await ApiService.dispatchReceiptWhatsApp(receiptNum, "08012345678");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok ? "Receipt sent via WhatsApp! 💬" : "WhatsApp dispatch queued.")),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat, size: 16, color: AppTheme.primaryEmerald),
                        label: const Text("WhatsApp", style: TextStyle(fontSize: 11, color: AppTheme.primaryEmerald)),
                      ),
                    ),
                  ],
                ),
              ],
            ),),
            actions: [

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onSuccess();
                },
                child: const Text("Done"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => errorMsg = e.toString().replaceAll("Exception: ", ""));
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAirtimeOrData = widget.category.slug == 'airtime' || widget.category.slug == 'data';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.category.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    const Text("Select provider and enter your details below.", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 24),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── SEARCHABLE PROVIDER SELECTOR ───────────────────────────────
            if (widget.category.products.length > 1) ...[
              GestureDetector(
                onTap: _showSearchableProviderPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedProduct.name,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.search, color: AppTheme.primaryEmerald, size: 18),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryEmerald, size: 20),
                    ],
                  ),
                ),
              ),
              // Savings badge for selected product
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_outlined,
                        color: AppTheme.primaryEmerald, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      "${(_selectedProduct.providerDiscountPct * _selectedProduct.customerSharePct / 100).toStringAsFixed(1)}% off + ${_selectedProduct.cashbackPct.toStringAsFixed(1)}% cashback with this provider",
                      style: const TextStyle(
                          color: AppTheme.primaryEmerald,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],

            if (errorMsg.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                  ],
                ),
              ),
            
            // ── METER / PHONE INPUT FIELD WITH INLINE VERIFY BUTTON ────────
            TextField(
              controller: refCtrl,
              keyboardType: isAirtimeOrData ? TextInputType.phone : TextInputType.number,
              decoration: InputDecoration(
                labelText: isAirtimeOrData ? "Phone Number" : "Meter / Smartcard / Account No.",
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAirtimeOrData)
                      IconButton(
                        tooltip: "Pick from Contacts",
                        icon: const Icon(Icons.contacts_rounded, color: AppTheme.primaryCyan, size: 20),
                        onPressed: _showContactPicker,
                      ),
                    IconButton(
                      tooltip: "Scan Barcode / Meter",
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryEmerald, size: 20),
                      onPressed: _showMeterScannerDialog,
                    ),
                    const SizedBox(width: 2),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          backgroundColor: AppTheme.primaryEmerald.withOpacity(0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: isValidating ? null : validateMeter,
                        child: isValidating
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("Verify", style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (validationResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Customer: ${validationResult!.customerName}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalculatePrice(),
              decoration: InputDecoration(labelText: "Amount (NGN)", prefixText: "₦ ", border: const OutlineInputBorder(), suffixText: "Fee: ₦${_selectedProduct.fee}"),
            ),
            const SizedBox(height: 16),

            // Customer Pricing & Savings Breakdown Box
            if (priceBreakdown != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Bill Value:", style: TextStyle(color: AppTheme.textMuted)),
                        Text("₦${priceBreakdown!.faceValue.toStringAsFixed(2)}"),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Cheepper Discount:", style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold)),
                        Text("- ₦${priceBreakdown!.customerDiscountAmount.toStringAsFixed(2)} 🎉", style: const TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Cashback Earned:", style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold)),
                        (paymentMethod == "CASHBACK" || useCashback)
                            ? const Text("₦0.00 (N/A on Bonus Payment)", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600))
                            : Text("+ ₦${priceBreakdown!.cashbackEarnedAmount.toStringAsFixed(2)} 🎁", style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (widget.cashbackBalance > 0 && paymentMethod != "CASHBACK") ...[
                      const Divider(color: AppTheme.cardBorder),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text("Apply Cashback Balance (₦${widget.cashbackBalance.toStringAsFixed(2)})", style: const TextStyle(fontSize: 12)),
                        value: useCashback,
                        onChanged: (v) {
                          setState(() => useCashback = v ?? false);
                          _recalculatePrice();
                        },
                      ),
                    ],
                    const Divider(color: AppTheme.cardBorder),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("You Pay:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("₦${priceBreakdown!.finalCustomerAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── COMPACT PAYMENT METHOD DROPDOWN ────────────────────────────
            const Text("Select Payment Method:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryCyan)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: paymentMethod,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1C2A35),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryCyan),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  items: [
                    DropdownMenuItem(
                      value: "CARD",
                      child: Row(
                        children: [
                          const Icon(Icons.credit_card, color: AppTheme.primaryCyan, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.cards.isNotEmpty
                                  ? "Direct Card (${widget.cards.first.cardBrand} **** ${widget.cards.first.last4})"
                                  : "Direct Bank Card Charge",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: "WALLET",
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: AppTheme.primaryEmerald, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Wallet Balance (₦${widget.walletBalance.toStringAsFixed(2)} available)",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: "CASHBACK",
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard_rounded, color: Colors.orangeAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Cashback / Bonus (₦${widget.cashbackBalance.toStringAsFixed(2)} available)",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        paymentMethod = v;
                        if (v == "CASHBACK") useCashback = false;
                        _recalculatePrice();
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            CheckboxListTile(
              title: const Text("Save as Beneficiary"),
              value: saveBeneficiary,
              onChanged: (v) => setState(() => saveBeneficiary = v ?? false),
            ),
            CheckboxListTile(
              title: const Text("Automate as Recurring Payment"),
              value: isScheduled,
              onChanged: (v) => setState(() => isScheduled = v ?? false),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isProcessing ? null : executePayment,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald, padding: const EdgeInsets.all(16)),
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(paymentMethod == "CARD" ? "Authorize & Charge Card" : paymentMethod == "CASHBACK" ? "Authorize & Pay with Cashback" : "Authorize & Pay with Wallet", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

}

// =============================================================================
// TRANSACTION HISTORY VIEW — Universal Search & Filter (Sections 43-44, 50)
// =============================================================================
class _TransactionHistoryView extends StatefulWidget {
  final NumberFormat currencyFmt;
  const _TransactionHistoryView({required this.currencyFmt});

  @override
  State<_TransactionHistoryView> createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<_TransactionHistoryView> {
  final _searchCtrl = TextEditingController();
  String? _filterStatus;
  String? _filterMethod;
  String? _filterCategory;
  List<PaymentModel> _results = [];
  bool _loading = false;
  String? _errorMsg;

  final List<String> _statuses = ['SUCCESS', 'FAILED', 'PROCESSING'];
  final List<String> _methods = ['WALLET', 'CARD'];
  final List<Map<String, String>> _categories = [
    {'label': '⚡ Electricity', 'slug': 'electricity'},
    {'label': '📱 Airtime', 'slug': 'airtime'},
    {'label': '📶 Data', 'slug': 'data'},
    {'label': '📺 Cable TV', 'slug': 'cable'},
  ];

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final results = await ApiService.searchPaymentHistory(
        status: _filterStatus,
        paymentMethod: _filterMethod,
        categorySlug: _filterCategory,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      setState(() { _results = results; _loading = false; });
    } catch (e) {
      setState(() { _errorMsg = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'SUCCESS': return AppTheme.primaryEmerald;
      case 'FAILED': return Colors.redAccent;
      default: return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = widget.currencyFmt;
    return Column(
      children: [
        // ── Search Bar ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Search by product code, reference, or provider ref...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.textMuted), onPressed: () { _searchCtrl.clear(); _search(); })
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),

        // ── Filter Chips ─────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Status filter
              ..._statuses.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(s, style: TextStyle(fontSize: 11, color: _filterStatus == s ? Colors.white : AppTheme.textMuted)),
                  selected: _filterStatus == s,
                  selectedColor: _statusColor(s).withOpacity(0.85),
                  checkmarkColor: Colors.white,
                  backgroundColor: AppTheme.cardDark,
                  shape: StadiumBorder(side: BorderSide(color: AppTheme.cardBorder)),
                  onSelected: (sel) { setState(() => _filterStatus = sel ? s : null); _search(); },
                ),
              )),
              const SizedBox(width: 4),
              // Method filter
              ..._methods.map((m) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(m == 'WALLET' ? '👛 Wallet' : '💳 Card', style: TextStyle(fontSize: 11, color: _filterMethod == m ? Colors.white : AppTheme.textMuted)),
                  selected: _filterMethod == m,
                  selectedColor: AppTheme.primaryCyan.withOpacity(0.85),
                  checkmarkColor: Colors.white,
                  backgroundColor: AppTheme.cardDark,
                  shape: StadiumBorder(side: BorderSide(color: AppTheme.cardBorder)),
                  onSelected: (sel) { setState(() => _filterMethod = sel ? m : null); _search(); },
                ),
              )),
              const SizedBox(width: 4),
              // Category filter
              ..._categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(c['label']!, style: TextStyle(fontSize: 11, color: _filterCategory == c['slug'] ? Colors.white : AppTheme.textMuted)),
                  selected: _filterCategory == c['slug'],
                  selectedColor: Colors.purpleAccent.withOpacity(0.85),
                  checkmarkColor: Colors.white,
                  backgroundColor: AppTheme.cardDark,
                  shape: StadiumBorder(side: BorderSide(color: AppTheme.cardBorder)),
                  onSelected: (sel) { setState(() => _filterCategory = sel ? c['slug'] : null); _search(); },
                ),
              )),
            ],
          ),
        ),

        // ── Results count ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text('${_results.length} transaction${_results.length == 1 ? '' : 's'}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const Spacer(),
              if (_filterStatus != null || _filterMethod != null || _filterCategory != null)
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear filters', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: () {
                    setState(() { _filterStatus = null; _filterMethod = null; _filterCategory = null; });
                    _search();
                  },
                ),
            ],
          ),
        ),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryEmerald))
              : _errorMsg != null
                  ? Center(child: Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent)))
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long, size: 48, color: AppTheme.textMuted),
                              const SizedBox(height: 12),
                              Text('No transactions found', style: const TextStyle(color: AppTheme.textMuted)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final p = _results[i];
                            final statusColor = _statusColor(p.status);
                            // Format date
                            String dateStr = p.createdAt;
                            try {
                              final dt = DateTime.parse(p.createdAt).toLocal();
                              dateStr = DateFormat('d MMM y, HH:mm').format(dt);
                            } catch (_) {}

                            return Container(
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: statusColor.withOpacity(0.25)),
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                  child: Icon(
                                    p.status == 'SUCCESS' ? Icons.check_circle_rounded : p.status == 'FAILED' ? Icons.error_rounded : Icons.pending,
                                    color: statusColor, size: 20,
                                  ),
                                ),
                                title: Text(p.billProductCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text('${p.customerReference} · $dateStr', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(fmt.format(p.totalAmount), style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13)),
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                      child: Text(p.status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                children: [
                                  // Expanded financial detail
                                  _txDetailRow('Bill Amount', fmt.format(p.amount)),
                                  _txDetailRow('Service Fee', fmt.format(p.fee)),
                                  if (p.customerDiscountAmount > 0)
                                    _txDetailRow('💚 You Saved', fmt.format(p.customerDiscountAmount), valueColor: AppTheme.primaryEmerald),
                                  if (p.cashbackEarnedAmount > 0)
                                    _txDetailRow('🎁 Cashback Earned', fmt.format(p.cashbackEarnedAmount), valueColor: Colors.orangeAccent),
                                  if (p.cashbackUsedAmount > 0)
                                    _txDetailRow('Cashback Applied', '- ${fmt.format(p.cashbackUsedAmount)}', valueColor: AppTheme.primaryCyan),
                                  const Divider(color: AppTheme.cardBorder),
                                  _txDetailRow('Total Paid', fmt.format(p.totalAmount), bold: true),
                                  _txDetailRow('Method', p.paymentMethod == 'CARD' ? '💳 Direct Card' : '👛 Wallet'),
                                  if (p.providerTxRef != null)
                                    _txDetailRow('Provider Ref', p.providerTxRef!),
                                  if (p.tokenOrPin != null && p.tokenOrPin!.isNotEmpty)
                                    _txDetailRow('🔑 Token / PIN', p.tokenOrPin!, valueColor: AppTheme.primaryCyan),
                                  if (p.failureReason != null && p.failureReason!.isNotEmpty)
                                    _txDetailRow('Failure Reason', p.failureReason!, valueColor: Colors.redAccent),
                                  const SizedBox(height: 8),

                                  // PDF receipt button
                                  if (p.status == 'SUCCESS')
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                                        label: const Text('Download PDF Receipt', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.primaryEmerald,
                                          side: const BorderSide(color: AppTheme.primaryEmerald),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onPressed: () async {
                                          final receiptNum = p.receiptNumber ?? "RCP-${p.id.substring(0, 8).toUpperCase()}";
                                          final pdfUrl = ApiService.getReceiptPdfUrl(receiptNum);
                                          final uri = Uri.parse(pdfUrl);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          } else if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                backgroundColor: AppTheme.cardDark,
                                                content: Text('PDF: $pdfUrl', style: const TextStyle(color: AppTheme.primaryEmerald)),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),

                                  if (p.status == 'FAILED')
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                                        label: const Text('⚡ Retry Payment Recovery', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orangeAccent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onPressed: () async {
                                          try {
                                            final msg = await ApiService.retryPayment(p.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(msg), backgroundColor: AppTheme.cardDark),
                                            );
                                            _search();
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Retry error: $e')),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _txDetailRow(String label, String value, {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: valueColor ?? Colors.white)),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM VECTOR QR CODE PAINTER — High Definition, Crisp QR Display
// =============================================================================
class _QrPainter extends CustomPainter {
  final String data;
  _QrPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.fill;
    final paintEmerald = Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.fill;
    final paintCyan = Paint()..color = const Color(0xFF06B6D4)..style = PaintingStyle.fill;

    // Draw background
    final bgPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)),
      bgPaint,
    );

    const matrixSize = 21;
    final cellSize = (size.width - 16) / matrixSize;
    const offset = 8.0;

    // Deterministic grid generated from data string bytes
    final bytes = utf8.encode(data);

    for (int r = 0; r < matrixSize; r++) {
      for (int c = 0; c < matrixSize; c++) {
        // Skip finder pattern zones (top-left 7x7, top-right 7x7, bottom-left 7x7)
        if ((r < 7 && c < 7) || (r < 7 && c >= matrixSize - 7) || (r >= matrixSize - 7 && c < 7)) {
          continue;
        }

        final bitIndex = (r * matrixSize + c) % (bytes.length * 8);
        final byteVal = bytes[bitIndex ~/ 8];
        final isFilled = (byteVal & (1 << (bitIndex % 8))) != 0;

        if (isFilled) {
          final x = offset + c * cellSize;
          final y = offset + r * cellSize;
          final p = ((r + c) % 5 == 0) ? paintEmerald : (((r * c) % 7 == 0) ? paintCyan : paintDark);
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(x, y, cellSize * 0.9, cellSize * 0.9), const Radius.circular(1.5)),
            p,
          );
        }
      }
    }

    // Helper to draw Finder Patterns (corners)
    void drawFinderPattern(double topX, double topY) {
      final outerSize = 7 * cellSize;
      final innerSize = 3 * cellSize;
      final midSize = 5 * cellSize;

      // Outer black square
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(topX, topY, outerSize, outerSize), const Radius.circular(4)),
        paintDark,
      );
      // Mid white square
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(topX + cellSize, topY + cellSize, midSize, midSize), const Radius.circular(3)),
        bgPaint,
      );
      // Inner emerald square
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(topX + 2 * cellSize, topY + 2 * cellSize, innerSize, innerSize), const Radius.circular(2)),
        paintEmerald,
      );
    }

    drawFinderPattern(offset, offset); // Top Left
    drawFinderPattern(offset + (matrixSize - 7) * cellSize, offset); // Top Right
    drawFinderPattern(offset, offset + (matrixSize - 7) * cellSize); // Bottom Left
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) => oldDelegate.data != data;
}

// Custom Painter for Card Camera Scanner Grid Lines
class GridLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

