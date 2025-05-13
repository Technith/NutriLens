import 'package:flutter/material.dart';

//centralized class for managing global theme colors
class ThemeColor {
  //these static variables hold the active theme colors
  static late Color primary;        
  static late Color secondary;      
  static late Color background;     
  static late Color textPrimary;    
  static late Color textSecondary;  

  //apply light theme values
  static void setLightTheme() {
    primary = Colors.green;               
    secondary = const Color(0xFF90C67C);        
    background = Colors.white;            
    textPrimary = Colors.black;           
    textSecondary = Colors.grey[800]!;    
  }

  //apply dark theme values
  static void setDarkTheme() {
    primary = Colors.green;               
    secondary = Color(0xFF1E5128);        
    background = Color(0xFF191A19);       
    textPrimary = Colors.white;           
    textSecondary = Colors.white;
  }

  //apply warm theme values
  static void setWarmTheme() {
    primary = Colors.green;                   
    secondary = const Color(0xFFFFA726);      
    background = const Color(0xFFFFF3E0);     
    textPrimary = const Color(0xFF4E342E); 
    textSecondary = const Color(0xFF6D4C41);
  }

  //apply green nature theme (healthy look)
  static void setNatureTheme() {
    primary = Color(0xFF328E6E);
    secondary = const Color(0xFF90C67C);
    background = const Color(0xFFF1F8E9);
    textPrimary = const Color(0xFF4E342E);
    textSecondary = const Color(0xFF6D4C41);

  }
}