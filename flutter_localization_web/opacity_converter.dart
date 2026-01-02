// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> args) async {
  print('🔄 Flutter Opacity to Alpha Converter (lib folder only)');
  print('=====================================================');

  // Get the target directory from command line args or use current directory
  String baseDir = args.isNotEmpty ? args[0] : '.';
  String targetDir = '$baseDir/lib';

  if (!Directory(baseDir).existsSync()) {
    print('❌ Directory "$baseDir" does not exist');
    exit(1);
  }

  if (!Directory(targetDir).existsSync()) {
    print('❌ Flutter lib directory "$targetDir" does not exist');
    print('ℹ️  Make sure you\'re running this in a Flutter project root directory');
    exit(1);
  }

  print('📁 Scanning Flutter lib directory: $targetDir');

  // Find all Dart files recursively in lib folder
  List<File> dartFiles = await findDartFilesInLib(targetDir);

  if (dartFiles.isEmpty) {
    print('ℹ️  No Dart files found in the lib directory');
    return;
  }

  print('📄 Found ${dartFiles.length} Dart files in lib directory');

  int totalReplacements = 0;
  int modifiedFiles = 0;

  // Process each Dart file
  for (File file in dartFiles) {
    int replacements = await processFile(file);
    if (replacements > 0) {
      modifiedFiles++;
      totalReplacements += replacements;
      print('✅ ${file.path}: $replacements replacements');
    }
  }

  print('\n🎉 Conversion completed!');
  print('📊 Summary:');
  print('   - Files processed: ${dartFiles.length}');
  print('   - Files modified: $modifiedFiles');
  print('   - Total replacements: $totalReplacements');
}

/// Find all Dart files recursively in the Flutter lib directory
Future<List<File>> findDartFilesInLib(String libDirPath) async {
  List<File> dartFiles = [];
  Directory libDir = Directory(libDirPath);

  if (!libDir.existsSync()) {
    return dartFiles;
  }

  await for (FileSystemEntity entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Skip generated files but keep all other files in lib
      if (!entity.path.contains('.g.dart') &&
          !entity.path.contains('.freezed.dart') &&
          !entity.path.contains('.gr.dart') &&
          !entity.path.contains('.config.dart') &&
          !entity.path.contains('.chopper.dart')) {
        dartFiles.add(entity);
      }
    }
  }

  return dartFiles;
}

/// Find all Dart files recursively in the given directory (legacy function)
Future<List<File>> findDartFiles(String dirPath) async {
  // This function is kept for backward compatibility with backup functionality
  return findDartFilesInLib(dirPath);
}

/// Process a single Dart file and replace .withOpacity() with .withAlpha()
Future<int> processFile(File file) async {
  try {
    String content = await file.readAsString();
    String originalContent = content;

    // Regular expression to match .withOpacity(value) calls
    // This handles various formats: .withOpacity(0.5), .withOpacity(opacity), etc.
    RegExp opacityRegex = RegExp(
      r'\.withOpacity\s*\(\s*([^)]+)\s*\)',
      multiLine: true,
    );

    int replacementCount = 0;

    // Replace all matches
    content = content.replaceAllMapped(opacityRegex, (Match match) {
      String opacityValue = match.group(1)!.trim();
      String alphaValue = convertOpacityToAlpha(opacityValue);
      replacementCount++;
      return '.withAlpha($alphaValue)';
    });

    // Write back to file if changes were made
    if (content != originalContent) {
      await file.writeAsString(content);
    }

    return replacementCount;
  } catch (e) {
    print('❌ Error processing ${file.path}: $e');
    return 0;
  }
}

/// Convert opacity value (0.0-1.0) to alpha value (0-255)
String convertOpacityToAlpha(String opacityValue) {
  // Handle different types of opacity values

  // Check if it's a direct numeric value (e.g., "0.5", "1.0", "0")
  double? directValue = double.tryParse(opacityValue);
  if (directValue != null) {
    int alphaValue = (directValue * 255).round();
    return alphaValue.toString();
  }

  // Check for common opacity constants and convert them
  Map<String, String> commonOpacities = {
    '0.0': '0',
    '0.1': '26',
    '0.2': '51',
    '0.3': '77',
    '0.4': '102',
    '0.5': '128',
    '0.6': '153',
    '0.7': '179',
    '0.8': '204',
    '0.9': '230',
    '1.0': '255',
  };

  if (commonOpacities.containsKey(opacityValue)) {
    return commonOpacities[opacityValue]!;
  }

  // For variables or expressions, wrap them in a conversion formula
  // This handles cases like: .withOpacity(opacity) -> .withAlpha((opacity * 255).round())
  return '(($opacityValue) * 255).round()';
}

/// Utility function to create a backup of lib files before modification
Future<void> createBackup(String baseDir) async {
  String libDir = '$baseDir/lib';
  String backupDir = '$baseDir/backup_lib_${DateTime.now().millisecondsSinceEpoch}';
  Directory(backupDir).createSync(recursive: true);

  List<File> dartFiles = await findDartFilesInLib(libDir);

  for (File file in dartFiles) {
    String relativePath = file.path.replaceFirst('$libDir/', '');
    String backupPath = '$backupDir/$relativePath';

    // Create directory structure in backup
    Directory(backupPath).parent.createSync(recursive: true);

    // Copy file to backup
    await file.copy(backupPath);
  }

  print('📋 Backup of lib directory created at: $backupDir');
}

/// Preview mode - shows what would be changed without actually modifying files
Future<void> previewChanges(String baseDir) async {
  print('👀 Preview Mode - No files will be modified');
  print('==========================================');

  String libDir = '$baseDir/lib';
  List<File> dartFiles = await findDartFilesInLib(libDir);

  for (File file in dartFiles) {
    String content = await file.readAsString();
    RegExp opacityRegex = RegExp(
      r'\.withOpacity\s*\(\s*([^)]+)\s*\)',
      multiLine: true,
    );

    Iterable<RegExpMatch> matches = opacityRegex.allMatches(content);

    if (matches.isNotEmpty) {
      print('\n📄 ${file.path}:');
      for (RegExpMatch match in matches) {
        String opacityValue = match.group(1)!.trim();
        String alphaValue = convertOpacityToAlpha(opacityValue);
        print('   .withOpacity($opacityValue) → .withAlpha($alphaValue)');
      }
    }
  }
}
