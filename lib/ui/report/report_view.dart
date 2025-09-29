import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants/palette.dart';

class ReportState {
  final String description;
  const ReportState({this.description = ''});
  ReportState copyWith({String? description}) => ReportState(description: description ?? this.description);
}

class ReportViewModel extends StateNotifier<ReportState> {
  ReportViewModel() : super(const ReportState());
  void setDescription(String v) => state = state.copyWith(description: v);
  Future<void> submit() async {
    // Placeholder: connect to backend later
  }
}

final reportProvider = StateNotifierProvider<ReportViewModel, ReportState>((ref) => ReportViewModel());

class ReportView extends ConsumerWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(reportProvider);
    final controller = TextEditingController(text: s.description);
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Smoke'),
        backgroundColor: AppPalette.backgroundDarker,
      ),
      backgroundColor: AppPalette.screenBackground,
      body: Stack(
        children: [
          // Map placeholder
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE9E4DA),
              child: const Center(
                child: Text('Map Placeholder', style: TextStyle(color: Colors.black54)),
              ),
            ),
          ),
          // Right-side controls
          Positioned(
            right: 12,
            top: 80,
            child: Column(
              children: [
                _RoundControl(child: const Icon(Icons.add, color: AppPalette.white)),
                const SizedBox(height: 10),
                _RoundControl(child: const Icon(Icons.remove, color: AppPalette.white)),
                const SizedBox(height: 10),
                _RoundControl(child: const Icon(Icons.my_location, color: AppPalette.white)),
              ],
            ),
          ),
          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: AppPalette.backgroundDarker,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      onPressed: () => ref.read(reportProvider.notifier).submit(),
                      child: const Text('Report Smoke Here', style: TextStyle(color: AppPalette.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppPalette.mediumGray,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note, color: AppPalette.lightGrayLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLines: 1,
                            onChanged: (v) => ref.read(reportProvider.notifier).setDescription(v),
                            style: const TextStyle(color: AppPalette.white),
                            decoration: const InputDecoration(
                              hintText: 'Describe what you see (optional)',
                              hintStyle: TextStyle(color: AppPalette.placeholderText),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final Widget child;
  const _RoundControl({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppPalette.mediumGray,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: Center(child: child),
    );
  }
}


