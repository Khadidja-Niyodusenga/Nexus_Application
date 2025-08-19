import 'package:flutter/material.dart';

class DetailsScreen extends StatefulWidget {
  final int sdgNumber;
  final String sdgTitle;
  final String sdgDescription;

  const DetailsScreen({
    super.key,
    required this.sdgNumber,
    required this.sdgTitle,
    required this.sdgDescription,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final TextEditingController _answerController = TextEditingController();

  void _showThankYouDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thank you!"),
        content: const Text(
            "We appreciate your response and your commitment to learning about this SDG."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // Get the image path based on SDG number
  String getSdgImagePath() {
    // Ensure the number is between 1 and 17
    int number = widget.sdgNumber.clamp(1, 17);
    return "assets/photo$number.png"; // photo1.png, photo2.png, ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sdgTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.green[600],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              getSdgImagePath(), // Use local image based on SDG number
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 12),
            Text(
              widget.sdgTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.sdgDescription,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 16),
            const Text(
              "Question?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "What practical actions can you take or inspire others to take to support this goal in your community?",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                hintText: "Write your Answer here...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (_answerController.text.isNotEmpty) {
                  _showThankYouDialog();
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
