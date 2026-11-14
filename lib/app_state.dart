import 'package:flutter/foundation.dart';

import 'engine/game_progress_manager.dart';
import 'theme/app_colors.dart';

/// One shared GameProgress for the whole app, so coins and solved puzzles
/// survive going back to the menu and opening a game again.
final GameProgress gameProgress = GameProgress();

/// The selected palette is shared by the app shell and the settings page.
final ValueNotifier<AppThemeOption> appTheme =
    ValueNotifier<AppThemeOption>(AppThemeOption.cyber);
