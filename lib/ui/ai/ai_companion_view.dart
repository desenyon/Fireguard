import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants/palette.dart';
import 'package:flutter/services.dart';
import '../../services/gemini_service.dart';
import '../menu/menu_view.dart';

final aiMessagesProvider = StateNotifierProvider<AiViewModel, List<AiMessage>>((ref) {
  return AiViewModel(
    initial: <AiMessage>[
      AiMessage(role: MessageRole.assistant, text: "Hello there! I'm here to help you stay safe during wildfires. What can I assist you with today?"),
      AiMessage(role: MessageRole.assistant, text: "⚠️ Important: AI responses may contain errors. Always verify critical safety information with official sources and emergency services."),
      AiMessage(role: MessageRole.assistant, text: "You can ask me questions like:\n- What should I pack if a fire is nearby?\n- How do I breathe through smoke?\n- What are the evacuation routes?"),
    ],
  );
});

class AiViewModel extends StateNotifier<List<AiMessage>> {
  AiViewModel({List<AiMessage>? initial}) : super(initial ?? <AiMessage>[]);

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    
    // Add user message
    state = [...state, AiMessage(role: MessageRole.user, text: text)];
    
    // Check if the message is fire safety related
    if (false) {
      state = [...state, AiMessage(
        role: MessageRole.assistant, 
        text: "I'm specialized in fire safety and emergency preparedness. I can help you with questions about wildfires, evacuation planning, breathing through smoke, emergency supplies, and other fire safety topics. What fire safety question can I help you with?"
      )];
      return;
    }
    
    // Add loading message
    state = [...state, AiMessage(role: MessageRole.assistant, text: 'Thinking about your fire safety question...')];
    
    try {
      // Get response from Gemini
      final response = await GeminiService.generateResponse(text);
      
      // Remove loading message and add actual response
      state = state.take(state.length - 1).toList();
      state = [...state, AiMessage(role: MessageRole.assistant, text: response)];
    } catch (e) {
      // Remove loading message and add error response
      state = state.take(state.length - 1).toList();
      state = [...state, AiMessage(
        role: MessageRole.assistant, 
        text: "I'm having trouble connecting right now. Please try again in a moment. I'm here to help with fire safety questions when I'm back online."
      )];
    }
  }
}

enum MessageRole { user, assistant }

class AiMessage {
  final MessageRole role;
  final String text;
  AiMessage({required this.role, required this.text});
}

class AiCompanionView extends ConsumerStatefulWidget {
  const AiCompanionView({super.key});

  @override
  ConsumerState<AiCompanionView> createState() => _AiCompanionViewState();
}

class _AiCompanionViewState extends ConsumerState<AiCompanionView> {
  final TextEditingController _controller = TextEditingController();
  bool _disclaimerDismissed = false;
  bool _hasInteracted = false;

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiMessagesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Companion'),
        backgroundColor: AppPalette.backgroundDarker,
        actions: [
          IconButton(
            onPressed: _showDisclaimerDialog,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Show AI Disclaimer',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MenuView(),
                ),
              );
            },
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      backgroundColor: AppPalette.screenBackground,
      body: Column(
        children: [
          // AI Disclaimer Banner
          if (!_disclaimerDismissed)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppPalette.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppPalette.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Disclaimer',
                          style: TextStyle(
                            color: AppPalette.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'AI responses may contain errors. Always verify critical safety information with official sources and emergency services.',
                          style: TextStyle(
                            color: AppPalette.white,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _disclaimerDismissed = true;
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      color: AppPalette.orange,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                final isUser = m.role == MessageRole.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: !isUser ? [
                      CircleAvatar(child: Text('U')),
                      const SizedBox(width: 8),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: AppPalette.mediumGray,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m.text,
                          style: const TextStyle(color: AppPalette.white, fontSize: 15),
                        ),
                      ),
                    ] : [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: AppPalette.orange,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m.text,
                          style: const TextStyle(color: AppPalette.white, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(child: Text('A')),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(color: AppPalette.backgroundDarker, boxShadow: []),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppPalette.mediumGray,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: AppPalette.white),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: AppPalette.placeholderText),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _onSubmit,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: AppPalette.orange,
                    heroTag: null,
                    onPressed: () => _onSubmit(_controller.text),
                    child: const Icon(Icons.arrow_upward, color: AppPalette.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSubmit(String value) async {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _controller.clear();
    
    // Show disclaimer dialog on first interaction
    if (!_hasInteracted) {
      _hasInteracted = true;
      await _showDisclaimerDialog();
    }
    
    await ref.read(aiMessagesProvider.notifier).send(value);
  }

  Future<void> _showDisclaimerDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppPalette.backgroundDarker,
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppPalette.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Disclaimer',
                style: TextStyle(
                  color: AppPalette.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Important Safety Notice',
                  style: TextStyle(
                    color: AppPalette.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'This AI assistant is designed to provide general fire safety guidance, but:',
                  style: TextStyle(
                    color: AppPalette.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• AI responses may contain errors or outdated information\n'
                  '• Always verify critical safety information with official sources\n'
                  '• Contact emergency services (911) for immediate threats\n'
                  '• Follow official evacuation orders and local authorities\n'
                  '• Use this as supplementary guidance only',
                  style: TextStyle(
                    color: AppPalette.lightGrayLight,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Your safety is our priority. When in doubt, trust official emergency services.',
                  style: TextStyle(
                    color: AppPalette.greenBright,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'I Understand',
                style: TextStyle(
                  color: AppPalette.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


