import "package:flutter/material.dart";
import 'package:fireguard/utils/constants/palette.dart';
class TDropdownTheme {
  TDropdownTheme._();
  static DropdownMenuThemeData lightdropdownTheme = DropdownMenuThemeData(
    menuStyle: MenuStyle(
      
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              )),
              
              backgroundColor: WidgetStateProperty.all(Colors.white),
            ),
            inputDecorationTheme: InputDecorationTheme(
                     
                     
                      enabledBorder: OutlineInputBorder(
                      
                        borderSide: BorderSide(color: AppPalette.border),
                        borderRadius: BorderRadius.circular(12),  
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
           
  );
}
