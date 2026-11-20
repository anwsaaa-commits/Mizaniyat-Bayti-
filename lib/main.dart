import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
Future<void> main() async {WidgetsFlutterBinding.ensureInitialized();await initializeDateFormatting('ar');runApp(const MizaniyatBaytiApp());}
class MizaniyatBaytiApp extends StatelessWidget{const MizaniyatBaytiApp({super.key});@override Widget build(BuildContext context)=>MaterialApp(title:AppConstants.appName,debugShowCheckedModeBanner:false,locale:const Locale('ar'),supportedLocales:const[Locale('ar'),Locale('en')],localizationsDelegates:const[GlobalMaterialLocalizations.delegate,GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate],theme:AppTheme.light,darkTheme:AppTheme.dark,themeMode:ThemeMode.system,home:const Directionality(textDirection:TextDirection.rtl,child:HomeScreen()));}
