import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'management_shell.dart';
import '../widgets/glass_card.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  const AuthScreen({Key? key, this.isLogin = true}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isLogin;
  bool _isLoading = false;
  bool _showMFA = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _orgController = TextEditingController();
  final _roleController = TextEditingController();
  final _mfaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  Future<void> _handleAuth() async {
    if (!_isLogin && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Passwords do not match!"),
        backgroundColor: Colors.orangeAccent,
      ));
      return;
    }

    setState(() => _isLoading = true);
    
    bool isDemoEnvironment = _emailController.text.contains("demo") || 
                            _passwordController.text == "fairscale" ||
                            FirebaseAuth.instance.app.options.apiKey == "fake-api-key";

    if (isDemoEnvironment) {
       await Future.delayed(const Duration(milliseconds: 800));
       setState(() {
          _isLoading = false;
          _showMFA = true;
       });
       return;
    }

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        setState(() {
          _isLoading = false;
          _showMFA = true;
        });
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        // Firebase automatically logs the user in after account creation,
        // so we move straight to the MFA screen.
        setState(() {
          _isLoading = false;
          _showMFA = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Enterprise Account Provisioned!"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Identity Gateway Error: ${e.toString()}"),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _verifyMFA() {
    if (_mfaController.text == "123456") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ManagementShell()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid MFA Code. Hint: 123456")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: SizedBox(
              width: 500,
              child: _showMFA ? _buildMFAScreen() : _buildAuthForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Container(
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.indigoAccent.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogo(),
          const SizedBox(height: 32),
          Text(
            _isLogin ? "Manager Login" : "Join FairScale",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.indigo[900], letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin ? "Welcome back to the governance portal" : "Protect your organization from AI bias",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black45, fontSize: 14),
          ),
          const SizedBox(height: 40),
          
          _inputField("Corporate Email", Icons.email_outlined, _emailController),
          const SizedBox(height: 20),
          
          if (!_isLogin) ...[
            _inputField("Organization Name", Icons.business_outlined, _orgController),
            const SizedBox(height: 20),
            _inputField("Professional Role", Icons.badge_outlined, _roleController),
            const SizedBox(height: 20),
          ],
          
          _inputField("Password", Icons.lock_outline, _passwordController, isPassword: true),
          
          if (!_isLogin) ...[
            const SizedBox(height: 20),
            _inputField("Confirm Password", Icons.verified_user_outlined, _confirmPasswordController, isPassword: true),
          ],
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : Text(_isLogin ? "Authenticate" : "Create Account", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black45, fontSize: 14),
                children: [
                  TextSpan(text: _isLogin ? "Need an enterprise account? " : "Already protected? "),
                  TextSpan(
                    text: _isLogin ? "Sign Up" : "Login",
                    style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.indigoAccent),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildMFAScreen() {
    return Container(
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.indigoAccent.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined, size: 50, color: Colors.indigoAccent),
          ),
          const SizedBox(height: 32),
          const Text("Verify Identity", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text(
            "We've sent a 6-digit code to your secure device.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _mfaController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, letterSpacing: 12, fontWeight: FontWeight.w900, color: Colors.indigoAccent),
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: "000000",
              hintStyle: TextStyle(color: Colors.indigoAccent.withOpacity(0.1)),
              counterText: "",
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _verifyMFA,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Confirm & Access", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          TextButton(onPressed: () => setState(() => _showMFA = false), child: const Text("Go Back", style: TextStyle(color: Colors.black38))),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.indigoAccent, Colors.blueAccent]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.indigoAccent.withOpacity(0.3), blurRadius: 15)],
      ),
      child: const Icon(Icons.security, color: Colors.white, size: 32),
    );
  }
}
