import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/chat_provider.dart';

class ChatView extends ConsumerStatefulWidget {
  final Map<String, dynamic>? trip;
  const ChatView({super.key, this.trip});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.isEmpty) return;
    
    _textController.clear();
    ref.read(chatProvider.notifier).sendMessage(text, contextData: widget.trip);
    
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final isTyping = ref.watch(chatProvider.notifier).isTyping;
    
    ref.listen(chatProvider, (previous, next) {
      if (next.length > (previous?.length ?? 0)) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          _buildHeader().animate().fade(duration: 400.ms).slideY(begin: -0.1, curve: Curves.easeOutQuart),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('AI is typing...', style: TextStyle(color: AppColors.gray400, fontStyle: FontStyle.italic)),
                  ).animate().fadeIn();
                }
                final msg = messages[index];
                return _ChatBubble(isAi: msg.isAi, text: msg.text)
                  .animate()
                  .fade(duration: 300.ms)
                  .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOutQuart);
              },
            ),
          ),
          _buildQuickReplies().animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
          _buildInputBar().animate().fade(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.g700, AppColors.g800]),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.g400, AppColors.g600]),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'AITP Assistant',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.white),
              ),
              Text(
                '🟢 Online · Powered by Gemini',
                style: TextStyle(fontSize: 10, color: AppColors.g300),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.more_vert, color: AppColors.white),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(onTap: () { _textController.text = '🌦️ Check weather for my trip'; _sendMessage(); }, child: const _QrChip(label: '🌦️ Check weather')),
          GestureDetector(onTap: () { _textController.text = '💰 How can I travel cheap?'; _sendMessage(); }, child: const _QrChip(label: '💰 Budget tips')),
          GestureDetector(onTap: () { _textController.text = '🏨 Recommend some hotels'; _sendMessage(); }, child: const _QrChip(label: '🏨 Best hotels')),
          GestureDetector(onTap: () { _textController.text = '📅 How do I change my dates?'; _sendMessage(); }, child: const _QrChip(label: '📅 Change dates')),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.gray200),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Ask anything about your trip...',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.gray400),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.g500, AppColors.g700]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: AppColors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isAi;
  final String text;
  const _ChatBubble({required this.isAi, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAi) _Avatar(isAi: true),
          const SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isAi ? AppColors.white : AppColors.g600,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isAi ? 4 : 16),
                bottomRight: Radius.circular(isAi ? 16 : 4),
              ),
              boxShadow: isAi ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isAi ? AppColors.gray800 : AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!isAi) _Avatar(isAi: false),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isAi;
  const _Avatar({required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isAi ? AppColors.g100 : AppColors.gray200,
        shape: BoxShape.circle,
      ),
      child: Center(child: Text(isAi ? '🤖' : '👤', style: const TextStyle(fontSize: 16))),
    );
  }
}

class _QrChip extends StatelessWidget {
  final String label;
  const _QrChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.g300),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.g700),
      ),
    );
  }
}
