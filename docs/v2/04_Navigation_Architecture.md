# Navigation Architecture

The application uses standard named routing to transition between authentication interfaces and the primary dashboard.

## Named Routes Configuration

Routes are defined inside [MyApp.build](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/main.dart#L28):

```dart
routes: {
  '/dashboard': (context) => const HomePage(),
  '/register': (context) => const RegisterScreen(),
  '/login': (context) => const LoginScreen(),
}
```

## Route Transitions

1.  **Start Route:** Configured via `home: const LoginScreen()`.
2.  **To Register Screen:** Triggered from `LoginScreen` using `Navigator.pushNamed(context, '/register')`.
3.  **On Successful Login:** Bypasses back button tracking using `Navigator.pushReplacementNamed(context, '/dashboard')`.
4.  **Registration Complete:** Returns to the login flow using `Navigator.pop(context)`.
