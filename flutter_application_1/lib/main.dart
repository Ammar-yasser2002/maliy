import 'mini_main.dart' as mini;

/// Delegate to `mini_main.dart` so we can keep this file while using the
/// `MiniMaliApp` entrypoint. This is safer than deleting `main.dart`.
void main() => mini.main();

 