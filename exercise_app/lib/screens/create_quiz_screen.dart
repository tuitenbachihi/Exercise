import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/api_service.dart';

class CreateQuizScreen extends StatefulWidget {
  final Quiz? quizToEdit;

  const CreateQuizScreen({Key? key, this.quizToEdit}) : super(key: key);

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();

  final List<Question> _questions = [];

  @override
  void initState() {
    super.initState();
    if (widget.quizToEdit != null) {
      _titleController.text = widget.quizToEdit!.title;
      _durationController.text = (widget.quizToEdit!.duration ~/ 60).toString();
      _questions.addAll(widget.quizToEdit!.questions);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addQuestion(Question question) {
    setState(() {
      _questions.add(question);
    });
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  // Opens a beautiful bottom sheet to add a new question
  void _showAddQuestionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddQuestionForm(
            onAdd: (Question newQuestion) {
              _addQuestion(newQuestion);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<void> _submitQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_questions.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Thiếu câu hỏi', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          content: const Text('Vui lòng thêm ít nhất một câu hỏi trước khi tạo đề thi.', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đồng ý', style: TextStyle(color: Color(0xFF6366F1))),
            ),
          ],
        ),
      );
      return;
    }

    final durationInMinutes = int.tryParse(_durationController.text);
    if (durationInMinutes == null || durationInMinutes <= 0) {
      return;
    }

    final quiz = Quiz(
      title: _titleController.text.trim(),
      duration: durationInMinutes * 60, // convert minutes to seconds
      questions: _questions,
    );

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );

      if (widget.quizToEdit != null) {
        await ApiService.updateQuiz(widget.quizToEdit!.id!, quiz);
      } else {
        await ApiService.createQuiz(quiz);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quizToEdit != null ? 'Cập nhật đề thi thành công!' : 'Tạo đề thi thành công!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true); // Return back to home and trigger refresh
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text(widget.quizToEdit != null ? 'Lỗi khi sửa đề' : 'Lỗi khi tạo đề', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng', style: TextStyle(color: Color(0xFF6366F1))),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(widget.quizToEdit != null ? 'Sửa Đề Thi' : 'Tạo Đề Thi Mới', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Form Details (Title and Time)
                    SliverPadding(
                      padding: const EdgeInsets.all(24.0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin đề thi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Quiz Title Input
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Tên đề thi',
                                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                hintText: 'Nhập tên đề thi trắc nghiệm',
                                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                                fillColor: const Color(0xFF1E293B),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF334155)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF334155)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tên đề thi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Duration Input
                            TextFormField(
                              controller: _durationController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Thời gian làm bài (phút)',
                                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                hintText: 'Nhập số phút (ví dụ: 15)',
                                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                                fillColor: const Color(0xFF1E293B),
                                filled: true,
                                suffixIcon: const Icon(Icons.timer_outlined, color: Color(0xFF94A3B8)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF334155)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF334155)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập thời gian làm bài';
                                }
                                final n = int.tryParse(value);
                                if (n == null || n <= 0) {
                                  return 'Thời gian làm bài phải là số nguyên dương';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Câu hỏi (${_questions.length})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _showAddQuestionBottomSheet,
                                  icon: const Icon(Icons.add_rounded, color: Color(0xFFEC4899), size: 20),
                                  label: const Text(
                                    'Thêm câu hỏi',
                                    style: TextStyle(
                                      color: Color(0xFFEC4899),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Questions List
                    if (_questions.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF334155), style: BorderStyle.solid),
                            ),
                            child: const Center(
                              child: Text(
                                'Chưa có câu hỏi nào được thêm.\nHãy nhấn "Thêm câu hỏi" để bổ sung.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final q = _questions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF334155)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Câu ${index + 1}: ${q.questionText}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                          onPressed: () => _deleteQuestion(index),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ...q.options.map((option) {
                                      final isCorrect = option == q.correctOption;
                                      return Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isCorrect 
                                              ? const Color(0xFF10B981).withOpacity(0.1) 
                                              : Colors.black.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isCorrect 
                                                ? const Color(0xFF10B981).withOpacity(0.5) 
                                                : const Color(0xFF334155),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                              color: isCorrect ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  color: isCorrect ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              );
                            },
                            childCount: _questions.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                ),
              ),

              // Bottom Button Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitQuiz,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          widget.quizToEdit != null ? 'Cập nhật Đề Thi' : 'Tạo Đề Thi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for the form to add a single question
class AddQuestionForm extends StatefulWidget {
  final Function(Question) onAdd;

  const AddQuestionForm({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<AddQuestionForm> createState() => _AddQuestionFormState();
}

class _AddQuestionFormState extends State<AddQuestionForm> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  final _quickInputController = TextEditingController();
  int _selectedOptionIndex = 0; // default to first option A

  @override
  void dispose() {
    _questionController.dispose();
    _quickInputController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _parseQuickInput(String text) {
    if (text.trim().isEmpty) return;

    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return;

    String parsedQuestion = "";
    String? optionA;
    String? optionB;
    String? optionC;
    String? optionD;

    final regexA = RegExp(r'^[aA][\.\:\-\)\s]+(.*)$');
    final regexB = RegExp(r'^[bB][\.\:\-\)\s]+(.*)$');
    final regexC = RegExp(r'^[cC][\.\:\-\)\s]+(.*)$');
    final regexD = RegExp(r'^[dD][\.\:\-\)\s]+(.*)$');

    List<String> questionParts = [];

    for (var line in lines) {
      if (regexA.hasMatch(line)) {
        optionA = regexA.firstMatch(line)?.group(1)?.trim();
      } else if (regexB.hasMatch(line)) {
        optionB = regexB.firstMatch(line)?.group(1)?.trim();
      } else if (regexC.hasMatch(line)) {
        optionC = regexC.firstMatch(line)?.group(1)?.trim();
      } else if (regexD.hasMatch(line)) {
        optionD = regexD.firstMatch(line)?.group(1)?.trim();
      } else {
        if (optionA == null && optionB == null && optionC == null && optionD == null) {
          questionParts.add(line);
        }
      }
    }

    if (questionParts.isNotEmpty) {
      String rawQuestion = questionParts.join(' ');
      final questionRegex = RegExp(r'^Câu\s+\d+[\.\:\-\)\s]*(.*)$', caseSensitive: false);
      if (questionRegex.hasMatch(rawQuestion)) {
        parsedQuestion = questionRegex.firstMatch(rawQuestion)?.group(1)?.trim() ?? rawQuestion;
      } else {
        parsedQuestion = rawQuestion;
      }
    }

    setState(() {
      if (parsedQuestion.isNotEmpty) {
        _questionController.text = parsedQuestion;
      }
      if (optionA != null) _optionControllers[0].text = optionA;
      if (optionB != null) _optionControllers[1].text = optionB;
      if (optionC != null) _optionControllers[2].text = optionC;
      if (optionD != null) _optionControllers[3].text = optionD;
    });
  }

  void _submitQuestion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final questionText = _questionController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).toList();
    final correctOption = options[_selectedOptionIndex];

    final newQuestion = Question(
      questionText: questionText,
      options: options,
      correctOption: correctOption,
    );

    widget.onAdd(newQuestion);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thêm câu hỏi mới',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              // Quick Input Box for pasting whole question
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2), width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flash_on_rounded, color: Color(0xFFEC4899), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Nhập nhanh câu hỏi & đáp án (Auto-parse)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _quickInputController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Dán toàn bộ câu hỏi và 4 đáp án A B C D vào đây...\nHệ thống sẽ tự động phân tích và chia vào các ô bên dưới!',
                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        fillColor: const Color(0xFF0F172A),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF6366F1)),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                          onPressed: () {
                            _quickInputController.clear();
                          },
                        ),
                      ),
                      onChanged: _parseQuickInput,
                    ),
                  ],
                ),
              ),

              // Question Text Input
              TextFormField(
                controller: _questionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Câu hỏi',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  hintText: 'Nhập nội dung câu hỏi...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  fillColor: const Color(0xFF0F172A),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập nội dung câu hỏi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Nhập 4 đáp án và tích chọn đáp án ĐÚNG:',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Options Inputs
              ...List.generate(4, (index) {
                final label = String.fromCharCode(65 + index); // A, B, C, D
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Radio button to select correct option
                      Theme(
                        data: Theme.of(context).copyWith(
                          unselectedWidgetColor: const Color(0xFF64748B),
                        ),
                        child: Radio<int>(
                          value: index,
                          groupValue: _selectedOptionIndex,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedOptionIndex = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Text input for options
                      Expanded(
                        child: TextFormField(
                          controller: _optionControllers[index],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Đáp án $label',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            hintText: 'Nhập nội dung đáp án $label',
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            fillColor: const Color(0xFF0F172A),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF6366F1)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nhập đáp án $label';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Button to add question
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _submitQuestion,
                  child: const Text('Thêm Vào Danh Sách', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
