import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MizaniyatBaytiApp());
}

class MizaniyatBaytiApp extends StatelessWidget {
  const MizaniyatBaytiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.appName),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.forest, AppTheme.forestLight],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: AppTheme.gold, size: 38),
                    SizedBox(height: 16),
                    Text(
                      'تحكّم في مصروف بيتك',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'سجّل دخلك ومشترياتك وتابع ميزانيتك بسهولة.',
                      style: TextStyle(color: Colors.white70, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _ComingSoonTile(
                icon: Icons.add_shopping_cart,
                title: 'إضافة مصروف',
                subtitle: 'تسجيل المصروفات اليومية',
              ),
              const _ComingSoonTile(
                icon: Icons.receipt_long,
                title: 'فاتورة مشتريات',
                subtitle: 'فاتورة واحدة تحتوي على عدة أصناف',
              ),
              const _ComingSoonTile(
                icon: Icons.savings_outlined,
                title: 'الميزانية الشهرية',
                subtitle: 'متابعة المصروف والمتبقي',
              ),
              const _ComingSoonTile(
                icon: Icons.bar_chart,
                title: 'التقارير والإحصائيات',
                subtitle: 'ملخصات يومية وشهرية',
              ),
              const SizedBox(height: 16),
              const Text(
                'النسخة التأسيسية 1.0.0 — يجري بناء الوظائف واختبارها على مراحل.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.gold.withValues(alpha: 0.18),
          child: Icon(icon, color: AppTheme.forest),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.lock_outline, size: 18),
      ),
    );
  }
}
