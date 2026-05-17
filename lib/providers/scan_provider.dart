import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../data/models/scan_result_model.dart';
import '../data/models/chat_message_model.dart';
import '../data/models/user_profile_model.dart';
import '../services/ai/gemma_local_service.dart';
import '../services/ai/gemma_remote_service.dart';
import '../core/constants/prompt_constants.dart';

enum AnalysisMode { local, remote }

class ScanProvider extends ChangeNotifier {
  final GemmaLocalService _local = GemmaLocalService();
  final GemmaRemoteService _remote = GemmaRemoteService();
  final ImagePicker _picker = ImagePicker();

  static const String _historyKey = 'scan_history';

  File? _selectedImage;
  ScanResult? _result;
  bool _isAnalyzing = false;
  bool _isStreaming = false;
  bool _isSendingFollowUp = false;
  bool _isConvertingPdf = false;
  String? _error;
  String _documentType = 'prescription';
  String _progressMessage = '';
  int _pdfCurrentPage = 0;
  int _pdfTotalPages = 0;
  bool _isPdf = false;
  List<String> _pdfPagePaths = [];
  List<ScanResult> _history = [];

  File? get selectedImage => _selectedImage;
  ScanResult? get result => _result;
  bool get isAnalyzing => _isAnalyzing;
  bool get isStreaming => _isStreaming;
  bool get isConvertingPdf => _isConvertingPdf;
  bool get isSendingFollowUp => _isSendingFollowUp;
  String? get error => _error;
  String get documentType => _documentType;
  String get progressMessage => _progressMessage;
  int get pdfCurrentPage => _pdfCurrentPage;
  int get pdfTotalPages => _pdfTotalPages;
  bool get isPdf => _isPdf;
  List<ScanResult> get history => List.unmodifiable(_history);

  Future<void> init() async {
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _history = list
            .map((e) => ScanResult.fromJson(e as Map<String, dynamic>))
            .where((s) =>
        s.imagePath.isEmpty || File(s.imagePath).existsSync())
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_history.map((s) => s.toJson()).toList());
      await prefs.setString(_historyKey, raw);
    } catch (_) {}
  }

  void setDocumentType(String type) {
    _documentType = type;
    notifyListeners();
  }

  Future<void> pickFromCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      _selectedImage = File(image.path);
      _isPdf = false;
      _pdfPagePaths = [];
      _result = null;
      _error = null;
      notifyListeners();
    }
  }

  Future<void> pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      _selectedImage = File(image.path);
      _isPdf = false;
      _pdfPagePaths = [];
      _result = null;
      _error = null;
      notifyListeners();
    }
  }

  Future<void> pickPdf() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked != null && picked.files.single.path != null) {
      _selectedImage = File(picked.files.single.path!);
      _isPdf = true;
      _pdfPagePaths = [];
      _result = null;
      _error = null;
      notifyListeners();
    }
  }

  Future<List<String>> _convertPdfToImages(String pdfPath) async {
    final tempDir = await getTemporaryDirectory();
    final pdfDocument = await PdfDocument.openFile(pdfPath);
    final pageCount = pdfDocument.pagesCount;

    _pdfTotalPages = pageCount;
    _pdfCurrentPage = 0;
    final imagePaths = <String>[];

    for (int i = 1; i <= pageCount; i++) {
      _pdfCurrentPage = i;
      _progressMessage = 'Converting page $i of $pageCount...';
      notifyListeners();

      final page = await pdfDocument.getPage(i);
      final pageImage = await page.render(
        width: page.width,
        height: page.height,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      await page.close();

      if (pageImage != null) {
        final imgPath =
            '${tempDir.path}/pdf_page_${DateTime.now().millisecondsSinceEpoch}_$i.png';
        await File(imgPath).writeAsBytes(pageImage.bytes);
        imagePaths.add(imgPath);
      }
    }

    await pdfDocument.close();
    return imagePaths;
  }

  Future<String> _extractTextFromImage(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await textRecognizer.processImage(inputImage);
      return recognized.text;
    } catch (_) {
      return '';
    } finally {
      await textRecognizer.close();
    }
  }

  Future<void> analyze({
    UserProfile? profile,
    AnalysisMode mode = AnalysisMode.local,
  }) async {
    if (_selectedImage == null) return;

    _error = null;
    _result = null;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final prompt = PromptConstants.scanPrompt(_documentType, profile: profile);

    if (_isPdf) {
      await _analyzePdf(id: id, prompt: prompt, profile: profile, mode: mode);
    } else {
      await _analyzeImage(id: id, imagePath: _selectedImage!.path, prompt: prompt, mode: mode);
    }
  }

  Future<void> _analyzeImage({
    required String id,
    required String imagePath,
    required String prompt,
    AnalysisMode mode = AnalysisMode.local,
  }) async {
    _isAnalyzing = false;
    _isStreaming = true;
    _progressMessage = mode == AnalysisMode.remote
        ? 'Sending to cloud model...'
        : 'Analyzing document...';

    _result = ScanResult(
      id: id,
      documentType: _documentTypeLabel(_documentType),
      imagePath: imagePath,
      summary: '',
      keyFindings: '',
      medicines: '',
      sideEffects: '',
      questionsToAsk: '',
      scannedAt: DateTime.now(),
      followUpMessages: [],
    );
    notifyListeners();

    try {
      if (mode == AnalysisMode.remote) {
        print('[SCAN] Remote image analysis...');
        final bytes = await File(imagePath).readAsBytes();
        final base64Image = base64Encode(bytes);
        final ext = imagePath.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        final response = await _remote.analyzeImage(
          systemPrompt: prompt,
          base64Image: base64Image,
          mimeType: mimeType,
        );
        print('[SCAN] Remote image done: ${response.length} chars');
        _result = _result!.copyWith(summary: response);
        _isStreaming = false;
        _progressMessage = '';
        _history.insert(0, _result!);
        _saveHistory();
        notifyListeners();
      } else {
        await _local.imageStreaming(
          prompt: prompt,
          imagePath: imagePath,
          onToken: (token) {
            _result = _result!.copyWith(summary: _result!.summary + token);
            notifyListeners();
          },
          onDone: () {
            _isStreaming = false;
            _progressMessage = '';
            _history.insert(0, _result!);
            _saveHistory();
            notifyListeners();
          },
          onError: (err) {
            _isStreaming = false;
            _progressMessage = '';
            _error = 'Analysis failed: $err';
            _result = null;
            notifyListeners();
          },
        );
      }
    } catch (e) {
      _isStreaming = false;
      _progressMessage = '';
      _error = 'Analysis failed: ${e.toString()}';
      _result = null;
      notifyListeners();
    }
  }

  Future<void> _analyzePdf({
    required String id,
    required String prompt,
    required AnalysisMode mode,
    UserProfile? profile,
  }) async {
    // Step 1: Convert PDF pages to images
    _isConvertingPdf = true;
    _progressMessage = 'Preparing PDF...';
    notifyListeners();

    List<String> pagePaths;
    try {
      pagePaths = await _convertPdfToImages(_selectedImage!.path);
      _pdfPagePaths = pagePaths;
    } catch (e) {
      _isConvertingPdf = false;
      _progressMessage = '';
      _error = 'Failed to read PDF: ${e.toString()}';
      notifyListeners();
      return;
    }

    _isConvertingPdf = false;

    if (pagePaths.isEmpty) {
      _error = 'Could not extract pages from PDF.';
      notifyListeners();
      return;
    }

    final totalPages = pagePaths.length;

    _result = ScanResult(
      id: id,
      documentType: _documentTypeLabel(_documentType),
      imagePath: pagePaths.first,
      summary: '',
      keyFindings: '',
      medicines: '',
      sideEffects: '',
      questionsToAsk: '',
      scannedAt: DateTime.now(),
      followUpMessages: [],
    );

    // Step 2: OCR all pages with ML Kit
    _isAnalyzing = true;
    final pageTexts = <String>[];

    for (int i = 0; i < pagePaths.length; i++) {
      final pageNum = i + 1;
      _pdfCurrentPage = pageNum;
      _progressMessage = 'Reading page $pageNum of $totalPages...';
      notifyListeners();

      final text = await _extractTextFromImage(pagePaths[i]);
      if (text.trim().length > 20) {
        pageTexts.add('Page $pageNum:\n$text');
      }
    }

    // Step 3: Rolling summarization per page to compress content
    if (pageTexts.isNotEmpty) {
      _progressMessage = 'Summarizing content...';
      notifyListeners();

      if (mode == AnalysisMode.remote) {
        // Remote: send ALL pages in one call — cloud has no token limit issues
        _progressMessage = 'Sending to cloud model...';
        notifyListeners();

        final allPagesContent = pageTexts.join('\n\n---\n\n');
        const extractPrompt =
            'Extract ONLY the medically relevant facts from this entire document: '
            'medicines, dosages, test values, diagnoses, dates, doctor names, '
            'findings, abnormal results. Be thorough but concise.';

        try {
          print('[SCAN] Sending to remote model...');
          print('[SCAN] Model: ${_remote.runtimeType}');
          final summary = await _remote.chat(
            systemPrompt: extractPrompt,
            messages: [
              {'role': 'user', 'content': allPagesContent}
            ],
          );
          print('[SCAN] Remote response received: ${summary.length} chars');
          pageTexts.clear();
          if (summary.trim().isNotEmpty) {
            pageTexts.add(summary);
          }
        } catch (e) {
          print('[SCAN] Remote call FAILED: $e');
          // Keep raw pageTexts as fallback
        }
      } else {
        // Local: one fresh conversation per page
        // Unique system prompt per page forces new KV cache — prevents native crash
        final pageSummaries = <String>[];
        const baseExtractPrompt =
            'Extract ONLY the medically relevant facts: '
            'medicines, dosages, test values, diagnoses, dates, doctor names, '
            'findings, abnormal results. Max 3 lines. Skip headers and normal ranges.';

        for (int i = 0; i < pageTexts.length; i++) {
          _pdfCurrentPage = i + 1;
          _progressMessage = 'Summarizing page \${i + 1} of \${pageTexts.length}...';
          notifyListeners();

          try {
            final buffer = StringBuffer();
            await _local.chatStreaming(
              systemPrompt: '\$baseExtractPrompt [p\${i + 1}]',
              messages: [
                {'role': 'user', 'content': pageTexts[i]}
              ],
              onToken: (t) => buffer.write(t),
              onDone: () {},
              onError: (_) {},
            );
            final summary = buffer.toString();
            if (summary.trim().isNotEmpty) {
              pageSummaries.add('Page \${i + 1}: \$summary');
            }
          } catch (_) {
            // Skip failed pages
          }
        }

        pageTexts.clear();
        pageTexts.addAll(pageSummaries);
      }
    }

    _isAnalyzing = false;

    // Fallback: scanned PDF with no OCR text — vision on first page
    if (pageTexts.isEmpty) {
      _progressMessage = 'Using vision analysis...';
      _isStreaming = true;
      notifyListeners();

      try {
        await _local.imageStreaming(
          prompt: prompt,
          imagePath: pagePaths.first,
          onToken: (token) {
            _result = _result!.copyWith(summary: _result!.summary + token);
            notifyListeners();
          },
          onDone: () {
            _isStreaming = false;
            _progressMessage = '';
            _history.insert(0, _result!);
            _saveHistory();
            notifyListeners();
          },
          onError: (err) {
            _isStreaming = false;
            _progressMessage = '';
            _error = 'Analysis failed: $err';
            _result = null;
            notifyListeners();
          },
        );
      } catch (e) {
        _isStreaming = false;
        _progressMessage = '';
        _error = 'Analysis failed: ${e.toString()}';
        _result = null;
        notifyListeners();
      }
      return;
    }

    // Step 4: Final streaming analysis from compressed summaries
    _isStreaming = true;
    _progressMessage = 'Generating analysis...';
    notifyListeners();

    final raw = pageTexts.join('\n\n');
    final combinedSummaries = raw.length > 6000 ? raw.substring(0, 6000) : raw;
    final systemPrompt =
        'You are GemmaCare Medical Document Analyzer. '
        'Analyze the provided document content thoroughly.'
        '${PromptConstants.profileSection(profile)}';

    final userMessage = '''
$prompt

Here is the summarized content extracted from all $totalPages pages:

$combinedSummaries

Based on the above, provide your complete structured analysis.
''';

    try {
      if (mode == AnalysisMode.remote) {
        print('[SCAN] PDF final analysis (streaming)...');
        await for (final token in _remote.chatStream(
          systemPrompt: systemPrompt,
          messages: [{'role': 'user', 'content': userMessage}],
        )) {
          _result = _result!.copyWith(summary: _result!.summary + token);
          notifyListeners();
        }
        print('[SCAN] PDF streaming done');
        _isStreaming = false;
        _progressMessage = '';
        _history.insert(0, _result!);
        _saveHistory();
        notifyListeners();
      } else {
        await _local.chatStreaming(
          systemPrompt: systemPrompt,
          messages: [
            {'role': 'user', 'content': userMessage}
          ],
          onToken: (token) {
            _result = _result!.copyWith(summary: _result!.summary + token);
            notifyListeners();
          },
          onDone: () {
            _isStreaming = false;
            _progressMessage = '';
            _history.insert(0, _result!);
            _saveHistory();
            notifyListeners();
          },
          onError: (err) {
            _isStreaming = false;
            _progressMessage = '';
            _error = 'Analysis failed: $err';
            _result = null;
            notifyListeners();
          },
        );
      }
    } catch (e) {
      _isStreaming = false;
      _progressMessage = '';
      _error = 'Analysis failed: ${e.toString()}';
      _result = null;
      notifyListeners();
    }
  }

  Future<void> sendFollowUp(String text, {UserProfile? profile}) async {
    final currentResult = _result;
    if (currentResult == null || text.trim().isEmpty) return;

    _isSendingFollowUp = true;
    _error = null;

    final userMsg = ChatMessage.user(text);
    final assistantMsg = ChatMessage.assistant('');
    final updatedMessages = [
      ...currentResult.followUpMessages,
      userMsg,
      assistantMsg,
    ];

    _result = currentResult.copyWith(followUpMessages: updatedMessages);
    notifyListeners();

    try {
      final profilePart = PromptConstants.profileSection(profile);
      final systemPrompt = '''
You are GemmaCare Medical Assistant. You previously analyzed a ${currentResult.documentType} and provided this analysis:

${currentResult.summary}

Now answer follow-up questions about this document. Be concise and helpful.
Always recommend consulting a qualified healthcare professional for medical decisions.$profilePart
''';

      final messages = _result!.followUpMessages
          .where((m) => !m.isLoading)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      await _local.chatStreaming(
        systemPrompt: systemPrompt,
        messages: messages,
        onToken: (token) {
          final msgs = _result!.followUpMessages;
          final last = msgs.last;
          final updated = [
            ...msgs.sublist(0, msgs.length - 1),
            last.copyWith(content: last.content + token),
          ];
          _result = _result!.copyWith(followUpMessages: updated);
          notifyListeners();
        },
        onDone: () {
          _isSendingFollowUp = false;
          final idx = _history.indexWhere((s) => s.id == _result!.id);
          if (idx != -1) _history[idx] = _result!;
          _saveHistory();
          notifyListeners();
        },
        onError: (err) {
          _isSendingFollowUp = false;
          _error = err;
          notifyListeners();
        },
      );
    } catch (e) {
      _isSendingFollowUp = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  void loadResult(ScanResult result) {
    _result = result;
    _selectedImage =
    result.imagePath.isNotEmpty ? File(result.imagePath) : null;
    _error = null;
    _isPdf = false;
    notifyListeners();
  }

  Future<void> deleteScan(String id) async {
    _history.removeWhere((s) => s.id == id);
    if (_result?.id == id) {
      _result = null;
      _selectedImage = null;
    }
    await _saveHistory();
    notifyListeners();
  }

  String _documentTypeLabel(String type) {
    switch (type) {
      case 'prescription':      return 'Prescription';
      case 'xray':              return 'X-Ray';
      case 'blood_report':      return 'Blood Report';
      case 'discharge_summary': return 'Discharge Summary';
      default:                  return 'Medical Document';
    }
  }

  void clearSelection() {
    _selectedImage = null;
    _result = null;
    _error = null;
    _isPdf = false;
    _pdfPagePaths = [];
    _progressMessage = '';
    _pdfCurrentPage = 0;
    _pdfTotalPages = 0;
    notifyListeners();
  }
}