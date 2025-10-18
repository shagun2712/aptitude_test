import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// NOTE: Since external API key dependency has been removed,
// the following import is no longer strictly necessary for quiz logic,
// but kept for Firebase initialization structure.
import 'firebase_options.dart'; // ✅ Ensure you generate this file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initializing Firebase for Auth and Score History
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Handle Firebase initialization error (e.g., missing options)
    print("Firebase initialization error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AptiGenius',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        // Listen to the authentication state to decide which page to show
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return AuthPage();
        },
      ),
    );
  }
}

// ------------------ AUTH PAGE ------------------

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> handleAuth() async {
    setState(() => errorMessage = '');
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
      // StreamBuilder in MyApp handles navigation on success
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message ?? 'Authentication failed');
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: Center(
        // FIX: Wrap the inner content in a SingleChildScrollView to prevent overflow
        // when the keyboard is open or on small screens.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(30),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.quiz, color: Colors.purple, size: 80),
                const SizedBox(height: 20),
                Text(isLogin ? "Welcome Back" : "Create Account",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: handleAuth,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(isLogin ? 'Login' : 'Register', style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => setState(() {
                    isLogin = !isLogin;
                    errorMessage = ''; // Clear error when switching
                  }),
                  child: Text(isLogin
                      ? "Don't have an account? Register"
                      : "Already have an account? Login"),
                ),
                const SizedBox(height: 10),
                Text(errorMessage,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------ HOME PAGE ------------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AptiGenius Dashboard'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // StreamBuilder handles navigation
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, ${user.email}",
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _buildHomeButton(
              context,
              icon: Icons.lightbulb_outline,
              label: "Daily Aptitude Test (10 Qs)",
              onTap: () => Navigator.push(
                context,
                // Passing 'daily' as the quizKey
                MaterialPageRoute(
                    builder: (_) => const QuizPage(quizKey: 'daily')),
              ),
            ),
            const SizedBox(height: 20),
            _buildHomeButton(
              context,
              icon: Icons.book_outlined,
              label: "Subject-wise Test (Select Subject)",
              onTap: () => Navigator.push(
                context,
                // Navigate to SubjectSelectionPage
                MaterialPageRoute(builder: (_) => const SubjectSelectionPage()),
              ),
            ),
            const SizedBox(height: 20),
            _buildHomeButton(
              context,
              icon: Icons.show_chart,
              label: "View Score History",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScoreHistoryPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context,
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.purple.shade700),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ------------------ SUBJECT SELECTION PAGE ------------------

class SubjectSelectionPage extends StatelessWidget {
  const SubjectSelectionPage({super.key});

  // Keys must match the keys inside _QuizPageState._quizData['subjects']
  static const List<String> subjects = [
    'Quantitative Aptitude',
    'Verbal Reasoning',
    'Logical Reasoning',
    // Add more subjects here!
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Subject'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Choose a Subject for your 10-Question Test",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Use a Column for consistent spacing between buttons
              Column(
                children: subjects
                    .map((subject) => _buildSubjectButton(context, subject))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectButton(BuildContext context, String subject) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // Navigate to QuizPage, passing the subject name as the quiz key
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuizPage(quizKey: subject)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade50, // Lighter color for distinction
            foregroundColor: Colors.indigo.shade800,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            subject,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ------------------ QUIZ PAGE ------------------

class QuizPage extends StatefulWidget {
  // Renamed from 'type' to 'quizKey' to be more flexible (can be 'daily' or a subject name)
  final String quizKey;
  // FIX: Removed duplicated 'required'
  const QuizPage({super.key, required this.quizKey});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // --- Static Data for Local Quizzes (~40 Qs total, target 100+ for production) ---
  // Structure changed to allow nested subjects
  // FIX: Removed Dart interpolation ($) from string values to satisfy 'const' requirements.
  static const Map<String, dynamic> _quizData = {
    // 10 Daily Questions
    'daily': [
      {
        "question": "Which planet is known as the 'Red Planet'?",
        "options": ["Jupiter", "Mars", "Venus", "Saturn"],
        "answer": "Mars"
      },
      {
        "question": "Choose the synonym for 'Ephemeral'.",
        "options": ["Permanent", "Fleeting", "Eternal", "Important"],
        "answer": "Fleeting"
      },
      {
        "question": "What comes next in the sequence: 2, 6, 12, 20, 30, ...?",
        "options": ["40", "42", "44", "48"],
        "answer": "42"
      },
      {
        "question": "The primary component of the sun is:",
        "options": ["Oxygen", "Nitrogen", "Hydrogen", "Carbon Dioxide"],
        "answer": "Hydrogen"
      },
      {
        "question": "If all dogs are animals, and some animals are pets, which statement must be true?",
        "options": [
          "All animals are dogs",
          "All pets are dogs",
          "Some pets are animals",
          "Some dogs are pets"
        ],
        "answer": "Some pets are animals"
      },
      {
        "question": "Complete the analogy: Bird is to Nest as Bee is to...?",
        "options": ["Hive", "Flower", "Honey", "Wasp"],
        "answer": "Hive"
      },
      {
        "question": "Who was the first female Prime Minister of the United Kingdom?",
        "options": [
          "Theresa May",
          "Margaret Thatcher",
          "Angela Merkel",
          "Indira Gandhi"
        ],
        "answer": "Margaret Thatcher"
      },
      {
        "question": "If 'A' is the mother of 'B', 'B' is the father of 'C', how is 'A' related to 'C'?",
        "options": ["Sister", "Daughter", "Grandmother", "Aunt"],
        "answer": "Grandmother"
      },
      {
        "question": "What does the idiom 'Bite the bullet' mean?",
        "options": [
          "To chew slowly",
          "To avoid a difficult situation",
          "To endure a painful or difficult situation",
          "To speak harshly"
        ],
        "answer": "To endure a painful or difficult situation"
      },
      {
        "question": "Which country is bordered by the most other countries?",
        "options": ["Brazil", "China", "Russia", "India"],
        "answer": "China"
      },
    ],
    // Container for Subject-wise Tests (Expand these lists to reach 100+ total questions)
    'subjects': {
      'Quantitative Aptitude': [
        // 10 Quantitative Aptitude Questions
        {
          "question": "If 40% of a number is 200, what is 60% of that number?",
          "options": ["300", "350", "400", "450"],
          "answer": "300"
        },
        {
          "question": "A train passes a pole in 10 seconds and a platform 120m long in 20 seconds. What is the length of the train?",
          "options": ["100m", "120m", "150m", "180m"],
          "answer": "120m"
        },
        {
          "question": "The ratio of two numbers is 3:4. If their sum is 63, what is the smaller number?",
          "options": ["27", "36", "45", "18"],
          "answer": "27"
        },
        {
          "question": "What is the simple interest on \$5000 at 5% per annum for 4 years?",
          "options": ["\$1000", "\$800", "\$1200", "\$900"],
          "answer": "\$1000"
        },
        {
          "question": "Find the average of the first five prime numbers.",
          "options": ["5.6", "5.8", "5.2", "6.0"],
          "answer": "5.6"
        },
        // FIX: Replaced $x with plain x in strings
        {
          "question": "How many seconds are there in x hours?",
          "options": ["60x", "360x", "3600x", "24x"],
          "answer": "3600x"
        },
        // FIX: Replaced LaTeX notation with plain text/symbol
        {
          "question": "What is the area of a circle with a radius of 7cm? (Use π = 22/7)",
          "options": ["154 sq cm", "49 sq cm", "44 sq cm", "144 sq cm"],
          "answer": "154 sq cm"
        },
        // FIX: Replaced $A and $B with plain A and B in strings
        {
          "question": "If A = 2B and B = 3C, what is A:B:C?",
          "options": ["6:3:1", "1:2:3", "2:3:1", "6:3:2"],
          "answer": "6:3:1"
        },
        {
          "question": "A box contains 5 red and 4 green marbles. What is the probability of drawing one red marble?",
          "options": ["5/9", "4/9", "1/5", "1/4"],
          "answer": "5/9"
        },
        {
          "question": "A salesman gets a commission of 10% on all sales. If he sells goods worth \$2500, what is his commission?",
          "options": ["\$200", "\$250", "\$300", "\$150"],
          "answer": "\$250"
        },
      ],
      'Verbal Reasoning': [
        // 10 Verbal Reasoning Questions
        {
          "question": "Choose the synonym for 'Ephemeral'.",
          "options": ["Permanent", "Fleeting", "Eternal", "Important"],
          "answer": "Fleeting"
        },
        {
          "question": "Find the error: 'He insisted on me going to the party.'",
          "options": [
            "He insisted",
            "on me going",
            "to the party",
            "No error"
          ],
          "answer": "on me going"
        },
        {
          "question": "I prefer coffee _____ tea.",
          "options": ["than", "over", "to", "for"],
          "answer": "to"
        },
        {
          "question": "Which sentence is grammatically correct?",
          "options": [
            "She is more better than him.",
            "She is better than he.",
            "She is gooder than him.",
            "She is more better than he."
          ],
          "answer": "She is better than he."
        },
        {
          "question": "What does the idiom 'Bite the bullet' mean?",
          "options": [
            "To chew slowly",
            "To avoid a difficult situation",
            "To endure a painful or difficult situation",
            "To speak harshly"
          ],
          "answer": "To endure a painful or difficult situation"
        },
        {
          "question": "Choose the correct spelling:",
          "options": ["Concience", "Conscience", "Conciense", "Consience"],
          "answer": "Conscience"
        },
        {
          "question": "Antonym of 'Abundant':",
          "options": ["Ample", "Meager", "Plentiful", "Rich"],
          "answer": "Meager"
        },
        {
          "question": "A group of fish is called a:",
          "options": ["Herd", "Flock", "School", "Swarm"],
          "answer": "School"
        },
        {
          "question": "Fill in the blank: The painting was a perfect _____ of light and shadow.",
          "options": ["blend", "mixture", "combine", "fusion"],
          "answer": "blend"
        },
        {
          "question": "Identify the passive voice sentence:",
          "options": [
            "The dog chased the cat.",
            "The book was read by the student.",
            "The teacher praised him.",
            "She is writing a letter."
          ],
          "answer": "The book was read by the student."
        },
      ],
      'Logical Reasoning': [
        // 10 Logical Reasoning Questions
        {
          "question": "What comes next in the sequence: 2, 6, 12, 20, 30, ...?",
          "options": ["40", "42", "44", "48"],
          "answer": "42"
        },
        {
          "question": "If 'A' is the mother of 'B', 'B' is the father of 'C', how is 'A' related to 'C'?",
          "options": ["Sister", "Daughter", "Grandmother", "Aunt"],
          "answer": "Grandmother"
        },
        {
          "question": "If in a certain code 'CAT' is written as '3120', how is 'DOG' written?",
          "options": ["4157", "4157", "4157", "4157"],
          "answer": "4157"
        },
        {
          "question": "P is 15m to the West of Q. R is 15m to the North of Q. S is 15m to the West of R. What is the distance between S and P?",
          "options": ["0m", "15m", "30m", "10m"],
          "answer": "15m"
        },
        {
          "question": "Statement: All pens are pencils. All pencils are erasers. Conclusion: All pens are erasers.",
          "options": [
            "Conclusion Follows",
            "Conclusion Does Not Follow",
            "Cannot Be Determined",
            "Not Enough Information"
          ],
          "answer": "Conclusion Follows"
        },
        {
          "question": "Odd one out: Eagle, Sparrow, Bat, Parrot",
          "options": ["Eagle", "Sparrow", "Bat", "Parrot"],
          "answer": "Bat"
        },
        {
          "question": "If 'WATER' is coded as 'XBUFS', how is 'FIRE' coded?",
          "options": ["GJSH", "GJSF", "GISH", "GISF"],
          "answer": "GJSF"
        },
        {
          "question": "In a line, A is 10th from the left, and B is 9th from the right. If there are 20 people in the line, how many people are between A and B?",
          "options": ["1", "2", "3", "0"],
          "answer": "1"
        },
        {
          "question": "If Friday is the day after tomorrow, what was yesterday?",
          "options": ["Monday", "Tuesday", "Wednesday", "Thursday"],
          "answer": "Wednesday"
        },
        {
          "question": "Find the missing number: 1, 8, 27, 64, ?",
          "options": ["100", "125", "81", "144"],
          "answer": "125"
        },
      ]
    }
  };

  bool loading = true;
  List<dynamic> questions = [];
  Map<int, String> selectedAnswers = {};
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Start question selection immediately
    _selectRandomQuestions();
  }

  void _selectRandomQuestions() {
    List<Map<String, dynamic>>? sourceQuestions;

    // Logic to select questions based on whether the key is 'daily' or a subject name
    if (_quizData[widget.quizKey] is List) {
      // Case 1: Daily test (quizKey is 'daily')
      sourceQuestions = _quizData[widget.quizKey] as List<Map<String, dynamic>>?;
    } else if (_quizData['subjects'] is Map) {
      // Case 2: Subject test (quizKey is a subject name)
      final Map<String, dynamic> subjects =
      _quizData['subjects'] as Map<String, dynamic>;
      sourceQuestions =
      subjects[widget.quizKey] as List<Map<String, dynamic>>?;
    }

    // Check if the source data exists and is not empty
    if (sourceQuestions == null || sourceQuestions.isEmpty) {
      setState(() {
        loading = false;
        questions = [];
      });
      return;
    }

    // Create a mutable copy of the list and shuffle it
    final List<Map<String, dynamic>> shuffled = List.from(sourceQuestions)
      ..shuffle(_random);

    // Now drawing 10 questions randomly (or all if less than 10)
    const int quizSize = 10;
    final int count = min(quizSize, shuffled.length);

    setState(() {
      questions = shuffled.take(count).toList();
      loading = false; // Data is loaded instantly from memory
    });
  }

  void submitQuiz() async {
    if (selectedAnswers.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please answer all questions before submitting.")),
      );
      return;
    }

    int currentScore = 0;
    for (var i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i]['answer']) currentScore++;
    }

    final user = FirebaseAuth.instance.currentUser!;
    // Firestore uses 'scores' as the collection name
    await FirebaseFirestore.instance.collection('scores').add({
      'uid': user.uid,
      'email': user.email,
      // Storing the specific subject name or 'daily'
      'type': widget.quizKey,
      'score': currentScore,
      'total': questions.length,
      'timestamp': Timestamp.now(),
    });

    // Reset state for potential next quiz, but this dialog handles the exit
    setState(() {
      selectedAnswers.clear();
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Quiz Submitted"),
        content: Text("Your Score: $currentScore / ${questions.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to HomePage/SubjectSelectionPage
              if (widget.quizKey != 'daily') {
                Navigator.pop(
                    context); // Go back one more time if coming from subject selection
              }
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Loading Quiz'),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Quiz Error'),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                Text(
                    "Error: No questions found for subject: ${widget.quizKey}. Please ensure questions are added to the static quiz data.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizKey == 'daily'
            ? 'Daily Aptitude Test'
            : '${widget.quizKey} Test'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (int i = 0; i < questions.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${i + 1}. ${questions[i]['question']}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      // Display options using RadioListTile
                      for (var opt in questions[i]['options'])
                        RadioListTile<String>(
                          title: Text(opt),
                          value: opt,
                          groupValue: selectedAnswers[i],
                          onChanged: (val) {
                            setState(() => selectedAnswers[i] = val!);
                          },
                          dense: true,
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitQuiz,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child:
              const Text("Submit Answers (10 Qs)", style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}

// ------------------ SCORE HISTORY ------------------

class ScoreHistoryPage extends StatelessWidget {
  const ScoreHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    // Query scores for the current user.
    // NOTE: Removed .orderBy('timestamp', descending: true) to avoid Firestore Indexing error.
    final scores = FirebaseFirestore.instance
        .collection('scores')
        .where('uid', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Score History"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: scores,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Display a less intimidating error if fetching fails for other reasons
            return Center(
                child: Text("Error fetching history: ${snapshot.error}"));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No scores recorded yet."));
          }

          // FIX: Sort the documents in memory by timestamp descending (most recent first)
          // This avoids the Firestore composite index requirement.
          final sortedDocs = docs.toList()
            ..sort((a, b) {
              final aTime =
              (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
              final bTime =
              (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
              // Compare in reverse order (b before a) for descending sort
              return bTime.compareTo(aTime);
            });

          return ListView(
            children: sortedDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final DateTime date = data['timestamp'].toDate();
              final String formattedDate =
                  "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

              return Card(
                elevation: 1,
                margin:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.bar_chart, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    // Display the specific subject name (or DAILY)
                      "${data['type'].toString().toUpperCase()} Test (${data['score']} / ${data['total']})",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Completed on $formattedDate"),
                  trailing: Text(
                    data['score'] >= (data['total'] * 0.7) ? 'PASS' : 'FAIL',
                    style: TextStyle(
                      color: data['score'] >= (data['total'] * 0.7)
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
