import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_model.dart';

class TakeQuizScreen extends StatefulWidget {
  final Quiz quiz;

  const TakeQuizScreen({Key? key, required this.quiz}) : super(key: key);

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  late List<Question> _shuffledQuestions;
  late List<List<String>> _shuffledOptions;
  
  // Maps question index -> user's selected option text
  final Map<int, String?> _selectedAnswers = {};
  
  Timer? _timer;
  late int _timeLeft; // in seconds
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _initQuizData();
    _startTimer();
  }

  void _initQuizData() {
    // Clone and shuffle questions
    _shuffledQuestions = List<Question>.from(widget.quiz.questions)..shuffle();
    
    // Clone and shuffle options for each question
    _shuffledOptions = _shuffledQuestions.map((q) {
      return List<String>.from(q.options)..shuffle();
    }).toList();
    
    _timeLeft = widget.quiz.duration;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        _submitQuiz(autoSubmit: true);
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  void _submitQuiz({bool autoSubmit = false}) {
    if (_isSubmitted) return;
    
    _timer?.cancel();
    
    // Calculate Score
    int correctCount = 0;
    for (int i = 0; i < _shuffledQuestions.length; i++) {
      final userAns = _selectedAnswers[i];
      final correctAns = _shuffledQuestions[i].correctOption;
      if (userAns == correctAns) {
        correctCount++;
      }
    }
    
    final totalQuestions = _shuffledQuestions.length;
    final score = (correctCount / totalQuestions) * 10;
    final scoreFormatted = score.toStringAsFixed(1);

    // Show Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Text(
            autoSubmit ? 'Hết giờ làm bài!' : 'Kết quả làm bài',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6366F1), width: 3),
              ),
              child: Text(
                scoreFormatted,
                style: const TextStyle(
                  color: Color(0xFFEC4899),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Số câu đúng: $correctCount / $totalQuestions',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              correctCount == totalQuestions
                  ? 'Tuyệt vời! Bạn đã đạt điểm tối đa! 🎉'
                  : correctCount >= totalQuestions / 2
                      ? 'Làm tốt lắm! Tiếp tục cố gắng nhé! 👍'
                      : 'Đừng nản lòng, hãy ôn tập và thử lại! 💪',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ],
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 140,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  setState(() {
                    _isSubmitted = true; // Switch view to show correct/incorrect answers
                  });
                },
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Ask for confirmation before submitting
  void _confirmSubmit() {
    final unansweredCount = _shuffledQuestions.length - _selectedAnswers.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Nộp bài thi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          unansweredCount > 0
              ? 'Bạn còn $unansweredCount câu hỏi chưa trả lời. Bạn có chắc chắn muốn nộp bài ngay?'
              : 'Bạn đã trả lời hết các câu hỏi. Xác nhận nộp bài thi để xem điểm?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Close confirm dialog
              _submitQuiz();
            },
            child: const Text('Nộp bài'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.quiz.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              _isSubmitted ? 'Đã hoàn thành' : 'Đang làm bài',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (!_isSubmitted) {
              // Confirm quit
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: const Text('Hủy làm bài', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  content: const Text('Bạn có chắc chắn muốn thoát khỏi phòng thi? Kết quả làm bài sẽ không được lưu.', style: TextStyle(color: Color(0xFF94A3B8))),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy', style: TextStyle(color: Color(0xFF94A3B8))),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Exit screen
                      },
                      child: const Text('Thoát'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          // Timer Widget
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _isSubmitted
                  ? const Color(0xFF1E293B)
                  : (_timeLeft <= 30 ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF6366F1).withOpacity(0.2)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isSubmitted
                    ? const Color(0xFF334155)
                    : (_timeLeft <= 30 ? const Color(0xFFEF4444) : const Color(0xFF6366F1)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: _isSubmitted
                      ? const Color(0xFF94A3B8)
                      : (_timeLeft <= 30 ? const Color(0xFFEF4444) : const Color(0xFF6366F1)),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _isSubmitted ? '00:00' : _formatTime(_timeLeft),
                  style: TextStyle(
                    color: _isSubmitted
                        ? const Color(0xFF94A3B8)
                        : (_timeLeft <= 30 ? const Color(0xFFEF4444) : const Color(0xFF6366F1)),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: _shuffledQuestions.length,
                itemBuilder: (context, qIndex) {
                  final q = _shuffledQuestions[qIndex];
                  final options = _shuffledOptions[qIndex];
                  final userSelection = _selectedAnswers[qIndex];

                  Color cardBorderColor = const Color(0xFF334155);
                  double cardBorderWidth = 1.0;
                  if (_isSubmitted) {
                    if (userSelection == null) {
                      cardBorderColor = const Color(0xFFF59E0B).withOpacity(0.5);
                      cardBorderWidth = 1.5;
                    } else if (userSelection == q.correctOption) {
                      cardBorderColor = const Color(0xFF10B981).withOpacity(0.5);
                      cardBorderWidth = 1.5;
                    } else {
                      cardBorderColor = const Color(0xFFEF4444).withOpacity(0.5);
                      cardBorderWidth = 1.5;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorderColor, width: cardBorderWidth),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Header (Badges Row)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                              ),
                              child: Text(
                                'Câu ${qIndex + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (_isSubmitted) ...[
                              const SizedBox(width: 12),
                              if (userSelection == null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Bỏ qua / Chưa trả lời',
                                        style: TextStyle(
                                          color: Color(0xFFF59E0B),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (userSelection == q.correctOption)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Chính xác',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Sai',
                                        style: TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Question Text (Takes full card width)
                        Text(
                          q.questionText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Options Cards
                        ...options.map((option) {
                          final isSelected = userSelection == option;
                          final isCorrectAnswer = option == q.correctOption;

                          // Colors and borders based on submitted state
                          Color cardColor = const Color(0xFF0F172A);
                          Color borderColor = const Color(0xFF334155);
                          Color textColor = const Color(0xFF94A3B8);
                          double borderWidth = 1.0;
                          Widget? trailingIcon;

                          if (_isSubmitted) {
                            if (isCorrectAnswer) {
                              // Correct answer gets a green border (xanh lá cây) and optionally light green bg
                              cardColor = const Color(0xFF10B981).withOpacity(0.08);
                              borderColor = const Color(0xFF10B981);
                              textColor = const Color(0xFF10B981);
                              borderWidth = 2.0;
                              trailingIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20);
                            } else if (isSelected) {
                              // If selected answer is wrong, it gets red border (viền đỏ)
                              cardColor = const Color(0xFFEF4444).withOpacity(0.08);
                              borderColor = const Color(0xFFEF4444);
                              textColor = const Color(0xFFEF4444);
                              borderWidth = 2.0;
                              trailingIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20);
                            }
                          } else {
                            if (isSelected) {
                              cardColor = const Color(0xFF6366F1).withOpacity(0.1);
                              borderColor = const Color(0xFF6366F1);
                              textColor = Colors.white;
                              borderWidth = 1.5;
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: borderWidth),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: _isSubmitted
                                    ? null // disable clicks after submit
                                    : () {
                                        setState(() {
                                          _selectedAnswers[qIndex] = option;
                                        });
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                  child: Row(
                                    children: [
                                      // Custom indicator circle or letter
                                      Container(
                                        width: 24,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected && !_isSubmitted
                                              ? const Color(0xFF6366F1)
                                              : (_isSubmitted && isCorrectAnswer
                                                  ? const Color(0xFF10B981)
                                                  : (_isSubmitted && isSelected
                                                      ? const Color(0xFFEF4444)
                                                      : Colors.transparent)),
                                          border: Border.all(
                                            color: isSelected || (_isSubmitted && (isCorrectAnswer || isSelected))
                                                ? Colors.transparent
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                        child: isSelected || (_isSubmitted && (isCorrectAnswer || isSelected))
                                            ? Icon(
                                                _isSubmitted
                                                    ? (isCorrectAnswer ? Icons.check : Icons.close)
                                                    : Icons.check,
                                                color: Colors.white,
                                                size: 14,
                                              )
                                            : const SizedBox(),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: isSelected || (_isSubmitted && isCorrectAnswer)
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (trailingIcon != null) ...[
                                        const SizedBox(width: 8),
                                        trailingIcon,
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
                ),
              ),

            // Bottom Sticky Section
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSubmitted ? const Color(0xFF334155) : Colors.transparent,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSubmitted ? () => Navigator.pop(context) : _confirmSubmit,
                  child: Ink(
                    decoration: _isSubmitted
                        ? null
                        : BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        _isSubmitted ? 'Quay lại Trang Chủ' : 'Nộp Bài Thi',
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
    );
  }
}
