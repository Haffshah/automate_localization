import 'dart:ui';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:archive/archive.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automate Localization',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFFEC4899),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class LanguageStatus {
  final String code;
  final String name;
  String status; // 'idle', 'translating', 'done', 'error'
  Map<String, dynamic>? resultData;

  LanguageStatus({
    required this.code,
    required this.name,
    this.status = 'idle',
    this.resultData,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String> _languages = {};

  // New State Management
  final List<LanguageStatus> _processingList = [];
  Map<String, dynamic>? _previewData;
  PlatformFile? _selectedFile;
  int _totalStrings = 0;

  bool _isLoadingLanguages = false;
  bool _isProcessing = false;
  double _progress = 0.0;
  String? _errorMessage;
  String? _estimatedRemainingTime;

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  // ... (existing _fetchLanguages method)

  Future<void> _fetchLanguages() async {
    setState(() => _isLoadingLanguages = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/languages'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _languages = Map<String, String>.from(data);
        });
      } else {
        setState(
          () => _errorMessage = 'Failed to load languages. Is backend running?',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLanguages = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = result.files.first;
      String content = utf8.decode(file.bytes!);
      try {
        final data = json.decode(content);
        setState(() {
          _selectedFile = file;
          _previewData = data;
          _totalStrings = data.length;
          _errorMessage = null;
          // Clear previous selection/results on new file
          _processingList.clear();
          _progress = 0.0;
        });
      } catch (e) {
        setState(() => _errorMessage = 'Invalid JSON file');
      }
    }
  }

  void _updateLanguageSelection(String code, bool selected) {
    setState(() {
      if (selected) {
        if (!_processingList.any((l) => l.code == code)) {
          _processingList.add(
            LanguageStatus(code: code, name: _languages[code]!),
          );
        }
      } else {
        _processingList.removeWhere(
          (l) => l.code == code && l.status == 'idle',
        );
      }
    });
  }

  void _selectAll(bool select) {
    setState(() {
      _processingList.clear();
      if (select) {
        _languages.forEach((code, name) {
          _processingList.add(LanguageStatus(code: code, name: name));
        });
      }
    });
  }

  Future<void> _startProcess() async {
    if (_selectedFile == null) return;
    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _estimatedRemainingTime = 'Calculating time...';
    });

    // Filter only idle ones (or should we re-process errors? Let's process idle & error)
    final toProcess = _processingList
        .where((l) => l.status == 'idle' || l.status == 'error')
        .toList();

    int completedCount = 0;
    final stopwatch = Stopwatch()..start();

    for (var lang in toProcess) {
      if (!mounted) break;

      setState(() {
        lang.status = 'translating';
      });

      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://127.0.0.1:5000/api/translate_single'),
        );
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedFile!.bytes!,
            filename: _selectedFile!.name,
            contentType: MediaType('application', 'json'),
          ),
        );
        request.fields['language'] = lang.code;

        var response = await request.send();
        if (response.statusCode == 200) {
          final respStr = await response.stream.bytesToString();
          lang.resultData = json.decode(respStr);
          setState(() {
            lang.status = 'done';
          });
        } else {
          setState(() {
            lang.status = 'error';
          });
        }
      } catch (e) {
        setState(() {
          lang.status = 'error';
        });
      }

      completedCount++;

      // Calculate Estimate
      final elapsedMs = stopwatch.elapsedMilliseconds;
      final avgTimePerLang = elapsedMs / completedCount;
      final remainingLangs = toProcess.length - completedCount;
      final remainingMs = avgTimePerLang * remainingLangs;
      final remainingDuration = Duration(milliseconds: remainingMs.toInt());

      String timeStr;
      if (remainingDuration.inMinutes > 0) {
        timeStr =
            '${remainingDuration.inMinutes}m ${remainingDuration.inSeconds % 60}s remaining';
      } else {
        timeStr = '${remainingDuration.inSeconds}s remaining';
      }

      setState(() {
        _progress = completedCount / toProcess.length;
        _estimatedRemainingTime = (remainingLangs == 0)
            ? 'Almost done...'
            : 'Approx. $timeStr';
      });
    }

    setState(() {
      _isProcessing = false;
      _estimatedRemainingTime = null;
    });
  }

  void _downloadSingle(LanguageStatus lang) {
    if (lang.resultData == null) return;
    final jsonStr = const JsonEncoder.withIndent('  ').convert(lang.resultData);
    final bytes = utf8.encode(jsonStr);
    _saveFile(bytes, '${lang.code}.json');
  }

  void _downloadZip() {
    final archive = Archive();

    // Add completed files
    for (var lang in _processingList) {
      if (lang.status == 'done' && lang.resultData != null) {
        final jsonStr = const JsonEncoder.withIndent(
          '  ',
        ).convert(lang.resultData);
        final bytes = utf8.encode(jsonStr);
        archive.addFile(ArchiveFile('${lang.code}.json', bytes.length, bytes));
      }
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      _saveFile(zipData, 'translations.zip');
    }
  }

  void _saveFile(List<int> bytes, String name) {
    final blob = html.Blob([Uint8List.fromList(bytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", name)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AnimatedBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    Text(
                      'Globalize Your App',
                      style: GoogleFonts.outfit(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn().moveY(begin: 20, end: 0),
                    const SizedBox(height: 48),

                    _GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionHeader(
                            number: '1',
                            title: 'Upload & Preview',
                          ),
                          const SizedBox(height: 16),
                          _FileUploadArea(
                            selectedFile: _selectedFile,
                            stringCount: _totalStrings,
                            onTap: _pickFile,
                          ),

                          if (_previewData != null) ...[
                            const SizedBox(height: 16),
                            _PreviewWindow(data: _previewData!),
                          ],

                          const SizedBox(height: 32),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionHeader(
                                number: '2',
                                title: 'Select Targets',
                              ),
                              Row(
                                children: [
                                  _TextBtn(
                                    label: 'None',
                                    onTap: () => _selectAll(false),
                                  ),
                                  const SizedBox(width: 8),
                                  _TextBtn(
                                    label: 'All',
                                    onTap: () => _selectAll(true),
                                    isPrimary: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_isLoadingLanguages)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            _LanguageSelector(
                              languages: _languages,
                              processingList: _processingList,
                              onToggle: _updateLanguageSelection,
                            ),

                          const SizedBox(height: 32),

                          if (_processingList.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SectionHeader(
                                  number: '3',
                                  title: 'Process & Download',
                                ),
                                if (_isProcessing)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${(_progress * 100).toInt()}%',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (_estimatedRemainingTime != null)
                                        Text(
                                          _estimatedRemainingTime!,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                            if (_isProcessing) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: Colors.white10,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ],
                            const SizedBox(height: 16),
                            _ProcessingList(
                              list: _processingList,
                              totalStringCount: _totalStrings,
                              onDownload: _downloadSingle,
                            ),
                            const SizedBox(height: 20),
                          ],

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PrimaryButton(
                                label: _isProcessing
                                    ? 'Processing...'
                                    : 'Start Translation',
                                icon: Icons.auto_awesome,
                                isLoading: _isProcessing,
                                onPressed:
                                    (_selectedFile != null &&
                                        _processingList.any(
                                          (l) =>
                                              l.status == 'idle' ||
                                              l.status == 'error',
                                        ))
                                    ? _startProcess
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              if (_processingList.any(
                                (l) => l.status == 'done',
                              ))
                                _PrimaryButton(
                                  // Download Zip Button
                                  label: 'Download ZIP',
                                  icon: Icons.folder_zip,
                                  isLoading: false,
                                  onPressed: _downloadZip,
                                  isSecondary: true,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- New Components ---

class _PreviewWindow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PreviewWindow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.builder(
          itemCount: data.length,
          itemBuilder: (c, i) {
            final key = data.keys.elementAt(i);
            final val = data.values.elementAt(i);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: const TextStyle(
                      color: Color(0xFFEC4899),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$val',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProcessingList extends StatelessWidget {
  final List<LanguageStatus> list;
  final int totalStringCount;
  final Function(LanguageStatus) onDownload;
  const _ProcessingList({
    required this.list,
    required this.totalStringCount,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (c, i) {
          final item = list[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    item.code.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (item.status == 'translating')
                        Text(
                          'Translating $totalStringCount strings...',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                        )
                      else if (item.status == 'done')
                        Text(
                          'Success ($totalStringCount strings)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.greenAccent,
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.status == 'idle')
                  const Text(
                    'Queued',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                if (item.status == 'error')
                  const Text(
                    'Failed',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                if (item.status == 'translating')
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (item.status == 'done')
                  TextButton.icon(
                    onPressed: () => onDownload(item),
                    icon: const Icon(
                      Icons.download,
                      size: 16,
                      color: Colors.greenAccent,
                    ),
                    label: const Text(
                      'Save',
                      style: TextStyle(color: Colors.greenAccent),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 30),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final Map<String, String> languages;
  final List<LanguageStatus> processingList;
  final Function(String, bool) onToggle;

  const _LanguageSelector({
    required this.languages,
    required this.processingList,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: RawScrollbar(
        thumbVisibility: true,
        thumbColor: Colors.white24,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: languages.entries.map((e) {
              final isSelected = processingList.any((l) => l.code == e.key);
              return FilterChip(
                label: Text(e.value),
                selected: isSelected,
                onSelected: (v) => onToggle(e.key, v),
                selectedColor: const Color(0xFF8B5CF6).withAlpha(77),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 13,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// --- Reused/Styles Components (Same as before, simplified for length) ---

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
              top: -150,
              left: -100,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(77),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.2, duration: 6.seconds),
        Positioned(
              bottom: -100,
              right: -50,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -30, duration: 5.seconds),
      ],
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  const _GlassContainer({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withAlpha(153),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(26)),
          ),
          padding: const EdgeInsets.all(32),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;
  const _SectionHeader({required this.number, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _FileUploadArea extends StatelessWidget {
  final PlatformFile? selectedFile;
  final int stringCount;
  final VoidCallback onTap;
  const _FileUploadArea({
    required this.selectedFile,
    this.stringCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedFile != null
                ? const Color(0xFF8B5CF6)
                : Colors.white24,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selectedFile != null ? Icons.check_circle : Icons.upload_file,
              color: selectedFile != null
                  ? const Color(0xFF8B5CF6)
                  : Colors.white54,
            ),
            const SizedBox(height: 8),
            Text(
              selectedFile?.name ?? 'Click to upload en.json',
              style: const TextStyle(color: Colors.white70),
            ),
            if (selectedFile != null && stringCount > 0)
              Text(
                '$stringCount Strings Detected',
                style: const TextStyle(
                  color: Color(0xFFEC4899),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  const _TextBtn({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? const Color(0xFF8B5CF6) : Colors.white60,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isSecondary;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
    this.isSecondary = false,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child:
          AnimatedContainer(
                duration: 200.ms,
                height: widget.isSecondary ? 50 : 60,
                constraints: BoxConstraints(
                  minWidth: widget.isSecondary ? 0 : 220,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: (isDisabled || widget.isSecondary)
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: widget.isSecondary
                      ? Colors.white.withAlpha(26)
                      : (isDisabled ? Colors.white.withAlpha(13) : null),
                  border: widget.isSecondary
                      ? Border.all(color: Colors.white24, width: 1.5)
                      : null,
                  boxShadow: (!isDisabled && !widget.isSecondary && _isHovering)
                      ? [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withAlpha(128),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: widget.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.icon,
                              size: 22,
                              color: isDisabled ? Colors.white38 : Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDisabled
                                    ? Colors.white38
                                    : Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              )
              .animate(target: _isHovering ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                curve: Curves.easeOutCubic,
              ),
    );
  }
}
