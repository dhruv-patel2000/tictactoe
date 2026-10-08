import 'package:flutter/material.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';

// TextFormField validators used across auth/profile forms; each returns a
// localized error message or null when valid.
class Validator {
  static String? validateRequired(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('fieldRequired');
    }
    return null;
  }

  static String? validateEmail(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('emailRequired');
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return context.tr('enterValidEmail');
    }
    return null;
  }

  static String? validatePassword(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.tr('passwordRequired');
    }
    if (value.length < 8) {
      return context.tr('passwordMinLength');
    }
    return null;
  }

  static String? validatePhoneNumber(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('phoneRequired');
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return context.tr('enterValidPhone');
    }
    return null;
  }

  static String? validateLength(BuildContext context, String? value,
      {int min = 0, int max = 50}) {
    if (value == null || value.isEmpty) {
      return context.tr('fieldRequired');
    }
    if (value.length < min) {
      return context.tr('lengthMin', params: {'min': '$min'});
    }
    if (value.length > max) {
      return context.tr('lengthMax', params: {'max': '$max'});
    }
    return null;
  }

  static String? validateNumber(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.tr('fieldRequired');
    }
    final numberRegex = RegExp(r'^\d+$');
    if (!numberRegex.hasMatch(value)) {
      return context.tr('numbersOnly');
    }
    return null;
  }
}
