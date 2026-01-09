import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/trainer_dashboard.dart';
import '../screens/children/children_list_screen.dart';
import '../screens/children/add_child_screen.dart';
import '../screens/children/child_profile_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/categories/category_words_screen.dart';
import '../screens/words/add_word_screen.dart';
import '../screens/words/word_practice_screen.dart';
import '../screens/recording/recording_screen.dart';
import '../screens/recording/recordings_list_screen.dart';
import '../screens/evaluation/evaluation_screen.dart';
import '../screens/evaluation/comparison_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/reports/export_report_screen.dart';
import '../screens/admin/admin_panel_screen.dart';
import '../screens/profile/profile_edit_screen.dart';
import '../models/word_model.dart';
import '../models/child_model.dart';

/// App Route Names
class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String children = '/children';
  static const String addChild = '/children/add';
  static const String editChild = '/children/edit';
  static const String childProfile = '/children/profile';
  static const String categories = '/categories';
  static const String categoryWords = '/category-words';
  static const String addWord = '/add-word';
  static const String wordPractice = '/word-practice';
  static const String recording = '/recording';
  static const String recordingsList = '/recordings';
  static const String evaluation = '/evaluation';
  static const String comparison = '/comparison';
  static const String reports = '/reports';
  static const String exportReport = '/reports/export';
  static const String adminPanel = '/admin';
  static const String profileEdit = '/profile/edit';
}

/// App Route Generator
class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
    // Auth Routes
      case '/':
      case Routes.login:
        return _buildRoute(const LoginScreen(), settings);

      case Routes.register:
        return _buildRoute(const RegisterScreen(), settings);

    // Dashboard
      case Routes.dashboard:
        return _buildRoute(const TrainerDashboard(), settings);

    // Children Routes
      case Routes.children:
        return _buildRoute(const ChildrenListScreen(), settings);

      case Routes.addChild:
        return _buildRoute(const AddChildScreen(), settings);

      case Routes.childProfile:
        if (args is String) {
          return _buildRoute(ChildProfileScreen(childId: args), settings);
        }
        return _errorRoute('Child ID is required');

    // Categories Routes
      case Routes.categories:
        return _buildRoute(const CategoriesScreen(), settings);

      case Routes.categoryWords:
        if (args is Map<String, dynamic>) {
          return _buildRoute(
            CategoryWordsScreen(
              categoryId: args['categoryId'],
              categoryName: args['categoryName'],
            ),
            settings,
          );
        }
        return _errorRoute('Category data is required');

    // Words Routes
      case Routes.addWord:
        if (args is Map<String, dynamic>) {
          return _buildRoute(
            AddWordScreen(categoryId: args['categoryId']),
            settings,
          );
        }
        return _buildRoute(const AddWordScreen(), settings);

      case Routes.wordPractice:
        if (args is Map<String, dynamic>) {
          return _buildRoute(
            WordPracticeScreen(
              word: args['word'] as WordModel,
              categoryName: args['categoryName'] as String,
            ),
            settings,
          );
        }
        return _errorRoute('Word data required');

    // Recording Routes
      case Routes.recording:
        if (args is Map<String, dynamic>) {
          return _buildRoute(
            RecordingScreen(
              word: args['word'] as WordModel,
              categoryName: args['categoryName'] as String,
            ),
            settings,
          );
        }
        return _errorRoute('Recording data required');

      case Routes.recordingsList:
        if (args is String?) {
          return _buildRoute(RecordingsListScreen(childId: args), settings);
        }
        return _buildRoute(const RecordingsListScreen(), settings);

    // Evaluation Routes
      case Routes.evaluation:
        if (args is Map<String, dynamic>) {
          return _buildRoute(
            EvaluationScreen(
              word: args['word'] as WordModel,
              child: args['child'] as ChildModel,
              recordingPath: args['recordingPath'] as String,
              categoryName: args['categoryName'] as String,
              transcription: args['transcription'] as String?,
            ),
            settings,
          );
        }
        return _errorRoute('Evaluation data required');

      case Routes.comparison:
        if (args is Map<String, dynamic>) {
          return _buildRoute(
            ComparisonScreen(
              childId: args['childId'],
              wordId: args['wordId'],
            ),
            settings,
          );
        }
        return _errorRoute('Comparison data required');

    // Reports Routes
      case Routes.reports:
        if (args is String?) {
          return _buildRoute(ReportsScreen(childId: args), settings);
        }
        return _buildRoute(const ReportsScreen(), settings);

      case Routes.exportReport:
        if (args is Map<String, dynamic>) {
          return _buildRoute(
            ExportReportScreen(
              childId: args['childId'],
              reportType: args['reportType'],
            ),
            settings,
          );
        }
        return _errorRoute('Export data required');

    // Admin Routes
      case Routes.adminPanel:
        return _buildRoute(const AdminPanelScreen(), settings);

    // Profile Routes
      case Routes.profileEdit:
        return _buildRoute(const ProfileEditScreen(), settings);

      default:
        return _errorRoute('Page not found');
    }
  }

  static Route<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation Helper Extension
extension NavigationExtension on BuildContext {
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(this, routeName, arguments: arguments);
  }

  Future<T?> navigateReplace<T>(String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, dynamic>(
      this,
      routeName,
      arguments: arguments,
    );
  }

  Future<T?> navigateClearStack<T>(String routeName, {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      this,
      routeName,
          (route) => false,
      arguments: arguments,
    );
  }

  void goBack<T>([T? result]) {
    Navigator.pop<T>(this, result);
  }
}