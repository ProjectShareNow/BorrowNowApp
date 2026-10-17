import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../models/transaction_model.dart';

// Screens
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/verification_pending_screen.dart';
import '../screens/auth/account_rejected_screen.dart';
import '../screens/auth/account_disabled_screen.dart';

import '../screens/home/main_navigation_screen.dart';
import '../screens/items/item_details_screen.dart';
import '../screens/items/add_item_screen.dart';
import '../screens/items/edit_item_screen.dart';
import '../screens/items/my_listed_items_screen.dart';
import '../screens/items/search_filter_screen.dart';

import '../screens/requests/borrow_request_form_screen.dart';
import '../screens/requests/my_requests_screen.dart';

import '../screens/transactions/active_borrowings_screen.dart';
import '../screens/transactions/borrowing_details_screen.dart';

import '../screens/chat/conversation_list_screen.dart';
import '../screens/chat/chat_screen.dart';

import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/user_public_profile_screen.dart';
import '../screens/ratings/feedback_screen.dart';

import '../screens/reports/submit_report_screen.dart';
import '../screens/reports/my_reports_screen.dart';

import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_verifications_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/admin/admin_leaderboard_screen.dart';
import '../screens/admin/admin_items_transactions_screen.dart';
import '../screens/admin/admin_items_screen.dart';
import '../screens/admin/admin_borrow_requests_screen.dart';
import '../screens/admin/admin_transactions_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verificationPending = '/verification-pending';
  static const String accountRejected = '/account-rejected';
  static const String accountDisabled = '/account-disabled';

  static const String home = '/home';
  static const String search = '/search';
  static const String itemDetails = '/item-details';
  static const String addItem = '/add-item';
  static const String editItem = '/edit-item';
  static const String myListedItems = '/my-listed-items';

  static const String borrowRequestForm = '/borrow-request-form';
  static const String myRequests = '/my-requests';

  static const String activeBorrowings = '/active-borrowings';
  static const String borrowingDetails = '/borrowing-details';

  static const String conversations = '/conversations';
  static const String chat = '/chat';

  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String userPublicProfile = '/user-public-profile';
  static const String feedback = '/feedback';

  static const String submitReport = '/submit-report';
  static const String myReports = '/my-reports';

  static const String adminDashboard = '/admin-dashboard';
  static const String adminVerifications = '/admin-verifications';
  static const String adminUsers = '/admin-users';
  static const String adminReports = '/admin-reports';
  static const String adminLeaderboard = '/admin-leaderboard';
  static const String adminItemsTransactions = '/admin-items-transactions';
  static const String adminItems = '/admin-items';
  static const String adminBorrowRequests = '/admin-borrow-requests';
  static const String adminTransactions = '/admin-transactions';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case welcome:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case verificationPending:
        return MaterialPageRoute(
          builder: (_) => const VerificationPendingScreen(),
        );
      case accountRejected:
        return MaterialPageRoute(builder: (_) => const AccountRejectedScreen());
      case accountDisabled:
        return MaterialPageRoute(builder: (_) => const AccountDisabledScreen());

      case home:
        final initialIndex = settings.arguments as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => MainNavigationScreen(initialIndex: initialIndex),
        );
      case search:
        return MaterialPageRoute(builder: (_) => const SearchFilterScreen());
      case itemDetails:
        final item = settings.arguments as ItemModel;
        return MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item));
      case addItem:
        return MaterialPageRoute(builder: (_) => const AddItemScreen());
      case editItem:
        final item = settings.arguments as ItemModel;
        return MaterialPageRoute(builder: (_) => EditItemScreen(item: item));
      case myListedItems:
        return MaterialPageRoute(builder: (_) => const MyListedItemsScreen());

      case borrowRequestForm:
        final item = settings.arguments as ItemModel?;
        return MaterialPageRoute(
          builder: (_) => BorrowRequestFormScreen(item: item),
        );
      case myRequests:
        return MaterialPageRoute(builder: (_) => const MyRequestsScreen());

      case activeBorrowings:
        return MaterialPageRoute(
          builder: (_) => const ActiveBorrowingsScreen(),
        );
      case borrowingDetails:
        final txn = settings.arguments as TransactionModel;
        return MaterialPageRoute(
          builder: (_) => BorrowingDetailsScreen(transaction: txn),
        );

      case conversations:
        return MaterialPageRoute(
          builder: (_) => const ConversationListScreen(),
        );
      case chat:
        String chatId = '';
        if (settings.arguments is String) {
          chatId = settings.arguments as String;
        } else if (settings.arguments is Map) {
          chatId = (settings.arguments as Map)['chatId']?.toString() ?? '';
        }
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            key: ValueKey('chat_screen_$chatId'),
            chatId: chatId,
          ),
        );

      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case userPublicProfile:
        final userId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => UserPublicProfileScreen(userId: userId),
        );
      case feedback:
        if (settings.arguments is TransactionModel) {
          return MaterialPageRoute(
            builder: (_) => FeedbackScreen(
              transaction: settings.arguments as TransactionModel,
            ),
          );
        } else if (settings.arguments is String) {
          return MaterialPageRoute(
            builder: (_) => FeedbackScreen(
              transactionId: settings.arguments as String,
            ),
          );
        } else if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (_) => FeedbackScreen(
              transaction: map['transaction'] as TransactionModel?,
              transactionId: map['transactionId']?.toString(),
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const FeedbackScreen());

      case submitReport:
        final initialData = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SubmitReportScreen(initialData: initialData),
        );
      case myReports:
        return MaterialPageRoute(builder: (_) => const MyReportsScreen());

      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case adminVerifications:
        return MaterialPageRoute(
          builder: (_) => const AdminVerificationsScreen(),
        );
      case adminUsers:
        return MaterialPageRoute(builder: (_) => const AdminUsersScreen());
      case adminReports:
        return MaterialPageRoute(builder: (_) => const AdminReportsScreen());
      case adminLeaderboard:
        return MaterialPageRoute(
          builder: (_) => const AdminLeaderboardScreen(),
        );
      case adminItemsTransactions:
        final initialIndex = settings.arguments as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) =>
              AdminItemsTransactionsScreen(initialTabIndex: initialIndex),
        );
      case adminItems:
        return MaterialPageRoute(builder: (_) => const AdminItemsScreen());
      case adminBorrowRequests:
        return MaterialPageRoute(
          builder: (_) => const AdminBorrowRequestsScreen(),
        );
      case adminTransactions:
        return MaterialPageRoute(
          builder: (_) => const AdminTransactionsScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
