const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Atlas Connection
const mongoURI = process.env.MONGODB_URI;

if (!mongoURI || mongoURI.includes('<username>')) {
  console.warn('⚠️ WARNING: MONGODB_URI is not configured with your real credentials in the .env file!');
}

mongoose.connect(mongoURI)
  .then(() => console.log('✅ Connected to MongoDB Atlas successfully!'))
  .catch((err) => {
    console.error('❌ Connection error to MongoDB Atlas:', err.message);
    console.log('💡 TIP: Check if your IP is whitelisted in MongoDB Atlas and if your username/password are correct.');
  });

// Schema definition
const questionSchema = new mongoose.Schema({
  questionText: { type: String, required: true },
  options: [{ type: String, required: true }], // array of 4 answers
  correctOption: { type: String, required: true } // correct option value (must match one of the options)
});

const quizSchema = new mongoose.Schema({
  title: { type: String, required: true },
  duration: { type: Number, required: true }, // duration in seconds
  questions: [questionSchema]
}, { timestamps: true });

const Quiz = mongoose.model('Quiz', quizSchema);

// Base route
app.get('/', (req, res) => {
  res.send('🏠 Quiz App API is running! Available endpoints: GET /api/quizzes, GET /api/quizzes/:id, POST /api/quizzes');
});

// GET /api/quizzes - Get all quizzes
app.get('/api/quizzes', async (req, res) => {
  try {
    const quizzes = await Quiz.find().select('-__v');
    res.json(quizzes);
  } catch (error) {
    res.status(500).json({ message: 'Error retrieving quizzes', error: error.message });
  }
});

// GET /api/quizzes/:id - Get a specific quiz
app.get('/api/quizzes/:id', async (req, res) => {
  try {
    const quiz = await Quiz.findById(req.params.id);
    if (!quiz) {
      return res.status(404).json({ message: 'Quiz not found' });
    }
    res.json(quiz);
  } catch (error) {
    res.status(500).json({ message: 'Error retrieving quiz', error: error.message });
  }
});

// POST /api/quizzes - Create a new quiz
app.post('/api/quizzes', async (req, res) => {
  try {
    const { title, duration, questions } = req.body;
    
    // Simple validation
    if (!title || !duration || !questions || !Array.isArray(questions) || questions.length === 0) {
      return res.status(400).json({ message: 'Missing required fields. Title, duration, and at least one question are required.' });
    }

    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      if (!q.questionText || !q.options || !Array.isArray(q.options) || q.options.length !== 4 || !q.correctOption) {
        return res.status(400).json({ 
          message: `Question ${i + 1} is invalid. Each question must have questionText, exactly 4 options, and a correctOption.` 
        });
      }
      if (!q.options.includes(q.correctOption)) {
        return res.status(400).json({
          message: `Question ${i + 1} has a correctOption '${q.correctOption}' that does not exist in options array: [${q.options.join(', ')}].`
        });
      }
    }

    const newQuiz = new Quiz({
      title,
      duration: parseInt(duration),
      questions
    });

    const savedQuiz = await newQuiz.save();
    res.status(201).json(savedQuiz);
  } catch (error) {
    res.status(500).json({ message: 'Error creating quiz', error: error.message });
  }
});

// PUT /api/quizzes/:id - Update an existing quiz
app.put('/api/quizzes/:id', async (req, res) => {
  try {
    const { title, duration, questions } = req.body;
    
    // Simple validation
    if (!title || !duration || !questions || !Array.isArray(questions) || questions.length === 0) {
      return res.status(400).json({ message: 'Missing required fields. Title, duration, and at least one question are required.' });
    }

    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      if (!q.questionText || !q.options || !Array.isArray(q.options) || q.options.length !== 4 || !q.correctOption) {
        return res.status(400).json({ 
          message: `Question ${i + 1} is invalid. Each question must have questionText, exactly 4 options, and a correctOption.` 
        });
      }
      if (!q.options.includes(q.correctOption)) {
        return res.status(400).json({
          message: `Question ${i + 1} has a correctOption '${q.correctOption}' that does not exist in options array: [${q.options.join(', ')}].`
        });
      }
    }

    const updatedQuiz = await Quiz.findByIdAndUpdate(
      req.params.id,
      {
        title,
        duration: parseInt(duration),
        questions
      },
      { new: true, runValidators: true }
    );

    if (!updatedQuiz) {
      return res.status(404).json({ message: 'Quiz not found' });
    }

    res.json(updatedQuiz);
  } catch (error) {
    res.status(500).json({ message: 'Error updating quiz', error: error.message });
  }
});

// DELETE /api/quizzes/:id - Delete a specific quiz (for convenience)
app.delete('/api/quizzes/:id', async (req, res) => {
  try {
    const quiz = await Quiz.findByIdAndDelete(req.params.id);
    if (!quiz) {
      return res.status(404).json({ message: 'Quiz not found' });
    }
    res.json({ message: 'Quiz deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting quiz', error: error.message });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
