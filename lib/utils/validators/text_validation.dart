class TextValidation {
  static String? validateText(String text) {
    if (text.isEmpty || text.trim().isEmpty) {
      return "This field is required";
    }
    return null;
  }
}
