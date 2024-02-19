extension StringExtension on String {
    String capitalizeFirst() {
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}