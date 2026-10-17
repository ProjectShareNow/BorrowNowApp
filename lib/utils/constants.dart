import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'BorrowNow';
  static const String appTagline = 'Smart College Item Borrowing & Lending';
  static const String appVersion = '1.0.0';

  // Item Categories
  static const List<String> categories = [
    'All',
    'Books',
    'Calculators',
    'Chargers',
    'Power banks',
    'Umbrellas',
    'Stationery',
    'Lab equipment',
    'Electronics',
    'Sports equipment',
    'Other',
  ];

  // Predefined Campus Pickup Locations
  static const List<String> campusPickupLocations = [
    'College Library',
    'Near CSE Department',
    'Central Computing Facility',
    'Near CSE Computer Lab',
    'Project Lab – CSE Block',
    'College Canteen',
    'Main Block Entrance',
    'Near Seminar Hall',
    'College Main Gate',
    'College Ground',
  ];

  // Item conditions
  static const List<String> itemConditions = [
    'Brand New',
    'Like New',
    'Good',
    'Fair',
  ];

  // Item availability statuses
  static const String statusAvailable = 'available';
  static const String statusReserved = 'reserved';
  static const String statusBorrowed = 'borrowed';
  static const String statusInactive = 'inactive';

  // Request statuses
  static const String requestPending = 'pending';
  static const String requestApproved = 'approved';
  static const String requestRejected = 'rejected';
  static const String requestCancelled = 'cancelled';
  static const String requestActive = 'active';
  static const String requestReturnRequested = 'return_requested';
  static const String requestReturned = 'returned';

  // Admin Authorized Emails
  static const List<String> adminEmails = ['admin@college.edu'];

  // Verification statuses
  static const String verificationPending = 'pending';
  static const String verificationVerified = 'verified';
  static const String verificationRejected = 'rejected';

  // Department / Course options (Registration)
  static const List<String> departmentCourses = [
    'Computer Science and Engineering (CSE)',
    'Information Technology (IT)',
    'Electronics and Communication Engineering (ECE)',
    'Electronics and Computer Science (ECSc)',
    'Electrical and Electronics Engineering (EEE)',
    'Civil Engineering (CE)',
    'Mechanical Engineering (ME)',
    'Master of Computer Applications (MCA)',
    'Master of Business Administration (MBA)',
    'Other',
  ];

  // Student Academic years (Registration)
  static const List<String> studentAcademicYears = [
    'First Year',
    'Second Year',
    'Third Year',
    'Fourth Year',
  ];

  // Student Semesters (Registration)
  static const List<String> studentSemesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  // Academic years (Legacy / General)
  static const List<String> academicYears = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'Postgraduate',
  ];

  // Common departments
  static const List<String> departments = [
    'Computer Science & Engineering',
    'Information Technology',
    'Electronics & Communication',
    'Electrical & Electronics',
    'Mechanical Engineering',
    'Civil Engineering',
    'Biotechnology',
    'Chemical Engineering',
    'Business Administration',
    'Science & Humanities',
    'Other',
  ];

  // Report Reasons
  static const List<String> reportReasons = [
    'Damaged items',
    'Item not returned',
    'Misconduct',
    'Incorrect listings',
    'Other issues',
  ];

  // Category Icons mapping
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Books':
        return Icons.menu_book_rounded;
      case 'Calculators':
        return Icons.calculate_rounded;
      case 'Chargers':
        return Icons.electrical_services_rounded;
      case 'Power banks':
        return Icons.battery_charging_full_rounded;
      case 'Umbrellas':
        return Icons.umbrella_rounded;
      case 'Stationery':
        return Icons.edit_note_rounded;
      case 'Lab equipment':
        return Icons.science_rounded;
      case 'Electronics':
        return Icons.devices_other_rounded;
      case 'Sports equipment':
        return Icons.sports_basketball_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
