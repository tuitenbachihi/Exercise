class Question {
  final String? id;
  final String questionText;
  final List<String> options;
  final String correctOption;

  Question({
    this.id,
    required this.questionText,
    required this.options,
    required this.correctOption,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] as String?,
      questionText: json['questionText'] as String,
      options: List<String>.from(json['options'] as List),
      correctOption: json['correctOption'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'questionText': questionText,
      'options': options,
      'correctOption': correctOption,
    };
  }
}

class Quiz {
  final String? id;
  final String title;
  final int duration; // in seconds
  final List<Question> questions;

  Quiz({
    this.id,
    required this.title,
    required this.duration,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['_id'] as String?,
      title: json['title'] as String,
      duration: json['duration'] as int,
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'duration': duration,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
