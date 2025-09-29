import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants/palette.dart';

final aiMessagesProvider = StateNotifierProvider<AiViewModel, List<AiMessage>>((ref) {
  return AiViewModel(
    initial: <AiMessage>[
      AiMessage(role: MessageRole.assistant, text: "Hello there! I'm here to help you stay safe during wildfires. What can I assist you with today?"),
      AiMessage(role: MessageRole.assistant, text: "You can ask me questions like:\n- What should I pack if a fire is nearby?\n- How do I breathe through smoke?\n- What are the evacuation routes?"),
    ],
  );
});

class AiViewModel extends StateNotifier<List<AiMessage>> {
  AiViewModel({List<AiMessage>? initial}) : super(initial ?? <AiMessage>[]);

  void send(String text) {
    if (text.trim().isEmpty) return;
    state = [...state, AiMessage(role: MessageRole.user, text: text)];
    // Placeholder assistant echo. Later integrate Gemini.
    state = [...state, AiMessage(role: MessageRole.assistant, text: 'Thanks, I\'ll get back with guidance.')];
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

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiMessagesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Companion'),
        backgroundColor: AppPalette.backgroundDarker,
      ),
      backgroundColor: AppPalette.screenBackground,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                final isUser = m.role == MessageRole.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isUser ? AppPalette.orange : AppPalette.mediumGray,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(color: isUser ? AppPalette.white : AppPalette.white, fontSize: 15),
                    ),
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

  void _onSubmit(String value) {
    ref.read(aiMessagesProvider.notifier).send(value);
    _controller.clear();
  }
}


