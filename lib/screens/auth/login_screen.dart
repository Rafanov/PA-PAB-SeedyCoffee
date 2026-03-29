import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/brew_button.dart';
import '../../widgets/brew_snackbar.dart';
import '../../widgets/brew_text_field.dart';

enum _Mode { choose, login, register, otp, forgotPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _State();
}

class _State extends State<LoginScreen> with SingleTickerProviderStateMixin {
  _Mode _mode = _Mode.choose;
  bool _loading = false;
  String _pendingEmail = '';

  final _email     = TextEditingController();
  final _password  = TextEditingController();
  final _fullName  = TextEditingController();
  final _phone     = TextEditingController();
  final _otp       = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  final _loginKey  = GlobalKey<FormState>();

  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _anim, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _anim.forward();
  }

  @override
  void dispose() {
    for (final c in [_email, _password, _fullName, _phone, _otp]) c.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _setMode(_Mode m) {
    if (m == _Mode.choose) {
      _email.clear(); _password.clear();
      _fullName.clear(); _phone.clear(); _otp.clear();
    }
    setState(() => _mode = m);
    _anim..reset()..forward();
  }

  // ── Login ────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!(_loginKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final err = await context.read<AppProvider>().login(
        _email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      BrewSnackbar.show(context, err, isError: true);
    } else {
      _navigateByRole();
    }
  }

  // ── Register ─────────────────────────────────────────────────
  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final err = await context.read<AppProvider>().register(
        _email.text.trim(), _password.text,
        _fullName.text.trim(), _phone.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      BrewSnackbar.show(context, err, isError: true);
    } else {
      _pendingEmail = _email.text.trim();
      _setMode(_Mode.otp);
      BrewSnackbar.show(context, 'OTP sent to ${_pendingEmail}');
    }
  }

  // ── Verify OTP ───────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final code = _otp.text.trim();
    if (code.length != 6) {
      BrewSnackbar.show(context, 'Enter the 6-digit OTP code', isError: true);
      return;
    }
    setState(() => _loading = true);
    final err = await context.read<AppProvider>().verifyOtp(_pendingEmail, code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      BrewSnackbar.show(context, err, isError: true);
    } else {
      // Clear all form data after successful OTP
      _email.clear(); _password.clear();
      _fullName.clear(); _phone.clear(); _otp.clear();
      _navigateByRole();
    }
  }

  // ── Forgot Password ──────────────────────────────────────────
  Future<void> _sendResetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      BrewSnackbar.show(context, 'Enter your registered email', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppProvider>().sendPasswordReset(email);
      if (!mounted) return;
      BrewSnackbar.show(context,
          'Password reset link sent to $email. Check your inbox.');
      _setMode(_Mode.login);
    } catch (e) {
      if (!mounted) return;
      BrewSnackbar.show(context, e.toString(), isError: true);
    }
    setState(() => _loading = false);
  }

  void _navigateByRole() {
    final role = context.read<AppProvider>().currentUser?.role;
    if (role == UserRole.admin) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppConstants.routeAdmin, (_) => false);
    } else if (role == UserRole.cashier) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppConstants.routeKasir, (_) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, AppConstants.routeMain, (_) => false);
    }
  }

  // ── Emoji filter ─────────────────────────────────────────────
  static String _stripEmoji(String v) =>
      v.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}' 
          r'\u{1F300}-\u{1F5FF}'
          r'\u{1F680}-\u{1F6FF}'
          r'\u{2600}-\u{26FF}'
          r'\u{2700}-\u{27BF}]', unicode: true), '');

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.offWhite,
    body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(opacity: _fade, child: Column(children: [
        const SizedBox(height: 20),
        // Logo
        SizedBox(width: 100, height: 100,
          child: ClipRRect(borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/LogoSeedy.jpg',
                fit: BoxFit.cover))),
        const SizedBox(height: 16),
        Text(AppConstants.appName,
            style: AppTextStyles.displayMedium.copyWith(fontSize: 28)),
        const SizedBox(height: 6),
        Text(_modeSubtitle, style: AppTextStyles.bodySmall),
        const SizedBox(height: 32),
        _buildBody(),
      ])),
    )));

  String get _modeSubtitle => switch (_mode) {
    _Mode.choose       => 'Welcome back',
    _Mode.login        => 'Sign in to your account',
    _Mode.register     => 'Create your account',
    _Mode.otp          => 'Check your email',
    _Mode.forgotPassword => 'Reset your password',
  };

  Widget _buildBody() => switch (_mode) {
    _Mode.choose        => _choose(),
    _Mode.login         => _loginForm(),
    _Mode.register      => _registerForm(),
    _Mode.otp           => _otpForm(),
    _Mode.forgotPassword => _forgotForm(),
  };

  // ── Choose ───────────────────────────────────────────────────
  Widget _choose() => Column(children: [
    BrewButton(label: 'Login',
        onPressed: () => _setMode(_Mode.login)),
    const SizedBox(height: 12),
    BrewButton(label: 'Create Account',
        style: BrewButtonStyle.outline,
        onPressed: () => _setMode(_Mode.register)),
    const SizedBox(height: 28),
    // Demo accounts
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.silverGray)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Demo Accounts', style: AppTextStyles.labelMedium),
        const SizedBox(height: 10),
        _demoRow('Customer', 'customer@breworder.com'),
        _demoRow('Admin',    'admin@breworder.com'),
        _demoRow('Kasir',    'kasir@breworder.com'),
        const SizedBox(height: 6),
        Text('Password: Test123!', style: AppTextStyles.caption
            .copyWith(color: AppColors.midGray)),
      ])),
    const SizedBox(height: 16),
    TextButton(onPressed: () => Navigator.pop(context),
        child: Text('Back to Menu',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.midGray))),
  ]);

  Widget _demoRow(String role, String email) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      SizedBox(width: 70, child: Text(role,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700))),
      Expanded(child: Text(email,
          style: AppTextStyles.caption.copyWith(color: AppColors.midGray))),
    ]));

  // ── Login Form ───────────────────────────────────────────────
  Widget _loginForm() => Form(
    key: _loginKey,
    child: Column(children: [
      BrewTextField(label: 'Email', hint: 'your@email.com',
          controller: _email, keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined,
              color: AppColors.textMuted, size: 20),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          }),
      const SizedBox(height: 14),
      BrewTextField(label: 'Password', hint: 'Your password',
          controller: _password, isPassword: true,
          prefixIcon: const Icon(Icons.lock_outline,
              color: AppColors.textMuted, size: 20),
          validator: (v) => v == null || v.isEmpty
              ? 'Password is required' : null),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => _setMode(_Mode.forgotPassword),
          child: Text('Forgot Password?',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.black, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 16),
      BrewButton(label: 'Login',
          isLoading: _loading, onPressed: _login),
      const SizedBox(height: 12),
      TextButton(onPressed: () => _setMode(_Mode.choose),
          child: Text('Back',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.midGray))),
    ]));

  // ── Register Form ────────────────────────────────────────────
  Widget _registerForm() => Form(
    key: _formKey,
    child: Column(children: [
      BrewTextField(label: 'Full Name', hint: 'Your full name',
          controller: _fullName,
          prefixIcon: const Icon(Icons.person_outline,
              color: AppColors.textMuted, size: 20),
          inputFormatters: [
            FilteringTextInputFormatter.deny(
                RegExp(r'[^\x00-\xFF]'))],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Full name is required';
            if (v.trim().length < 2) return 'Name is too short';
            return null;
          }),
      const SizedBox(height: 14),
      BrewTextField(label: 'Email', hint: 'your@email.com',
          controller: _email, keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined,
              color: AppColors.textMuted, size: 20),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+')
                .hasMatch(v.trim())) return 'Enter a valid email';
            return null;
          }),
      const SizedBox(height: 14),
      BrewTextField(label: 'Phone (WhatsApp)', hint: '08xxxxxxxxxx',
          controller: _phone, keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined,
              color: AppColors.textMuted, size: 20),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\s]'))],
          validator: (v) {
            if (v == null || v.isEmpty) return 'Phone number is required';
            final digits = v.replaceAll(RegExp(r'[\s\-]'), '');
            if (!RegExp(r'^(\+62|62|0)[0-9]{7,12}').hasMatch(digits)) {
              return 'Format: 08xxxxxxxxxx atau +62xxxxxxxxxx';
            }
            return null;
          }),
      const SizedBox(height: 14),
      BrewTextField(label: 'Password', hint: 'Min. 6 characters',
          controller: _password, isPassword: true,
          prefixIcon: const Icon(Icons.lock_outline,
              color: AppColors.textMuted, size: 20),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 6) return 'Min. 6 characters';
            if (!v.contains(RegExp(r'[a-zA-Z]'))) return 'Must contain a letter';
            if (!v.contains(RegExp(r'[0-9!@#%^&*]'))) {
              return 'Add a number or symbol (!@#%^&*)';
            }
            return null;
          }),
      const SizedBox(height: 8),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _password,
        builder: (_, val, __) =>
            _PasswordStrength(password: val.text)),
      const SizedBox(height: 20),
      BrewButton(label: 'Create Account',
          isLoading: _loading, onPressed: _register),
      const SizedBox(height: 12),
      TextButton(onPressed: () => _setMode(_Mode.choose),
          child: Text('Back',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.midGray))),
    ]));

  // ── OTP Form ─────────────────────────────────────────────────
  Widget _otpForm() => Column(children: [
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.silverGray)),
      child: Column(children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 40, color: AppColors.black),
        const SizedBox(height: 12),
        Text('OTP sent to', style: AppTextStyles.bodySmall),
        const SizedBox(height: 4),
        Text(_pendingEmail, style: AppTextStyles.labelMedium,
            textAlign: TextAlign.center),
      ])),
    const SizedBox(height: 20),
    BrewTextField(label: 'Verification Code',
        hint: '0 0 0 0 0 0',
        controller: _otp,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        prefixIcon: const Icon(Icons.pin_outlined,
            color: AppColors.textMuted, size: 20)),
    const SizedBox(height: 6),
    Text('Check your inbox (and spam folder)',
        style: AppTextStyles.caption),
    const SizedBox(height: 20),
    BrewButton(label: 'Verify & Continue',
        isLoading: _loading, onPressed: _verifyOtp),
    const SizedBox(height: 12),
    BrewButton(label: 'Resend Code',
        style: BrewButtonStyle.outline,
        onPressed: _loading ? null : () async {
          setState(() => _loading = true);
          await context.read<AppProvider>().resendOtp(_pendingEmail);
          if (!mounted) return;
          setState(() => _loading = false);
          BrewSnackbar.show(context, 'OTP resent!');
        }),
    const SizedBox(height: 12),
    TextButton(onPressed: () => _setMode(_Mode.register),
        child: Text('Back to Register',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.midGray))),
  ]);

  // ── Forgot Password Form ──────────────────────────────────────
  Widget _forgotForm() => Column(children: [
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.silverGray)),
      child: Column(children: [
        const Icon(Icons.lock_reset_rounded,
            size: 40, color: AppColors.black),
        const SizedBox(height: 12),
        Text('Enter your registered email and we\'ll send a password reset link.',
            style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
      ])),
    const SizedBox(height: 20),
    BrewTextField(label: 'Email', hint: 'your@email.com',
        controller: _email, keyboardType: TextInputType.emailAddress,
        prefixIcon: const Icon(Icons.email_outlined,
            color: AppColors.textMuted, size: 20),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Email is required';
          if (!v.contains('@')) return 'Enter a valid email';
          return null;
        }),
    const SizedBox(height: 20),
    BrewButton(label: 'Send Reset Link',
        isLoading: _loading, onPressed: _sendResetPassword),
    const SizedBox(height: 12),
    TextButton(onPressed: () => _setMode(_Mode.login),
        child: Text('Back to Login',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.midGray))),
  ]);
}

// ── Password Strength ─────────────────────────────────────────────────────────
class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  int get _score {
    if (password.isEmpty) return 0;
    int s = 0;
    if (password.length >= 6)  s++;
    if (password.length >= 10) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#%^&*]'))) s++;
    return s;
  }

  String get _label => switch (_score) {
    0 => '', 1 => 'Weak', 2 => 'Fair',
    3 => 'Good', 4 => 'Strong', _ => 'Very Strong',
  };

  Color get _color => switch (_score) {
    0 => Colors.transparent,
    1 => const Color(0xFFE53935),
    2 => const Color(0xFFFB8C00),
    3 => const Color(0xFFFDD835),
    4 => const Color(0xFF43A047),
    _ => const Color(0xFF1B5E20),
  };

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Row(children: [
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _score / 5,
          backgroundColor: AppColors.silverGray,
          valueColor: AlwaysStoppedAnimation<Color>(_color),
          minHeight: 4))),
      const SizedBox(width: 10),
      Text(_label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
    ]);
  }
}
