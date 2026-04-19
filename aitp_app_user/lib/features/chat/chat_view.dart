import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_localization.dart';
import '../../core/chat_provider.dart';
import '../../core/theme.dart';

class ChatView extends ConsumerStatefulWidget {
  final Map<String, dynamic>? trip;

  const ChatView({super.key, this.trip});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool get _hasDraft => _textController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleComposerStateChange);
    _inputFocusNode.addListener(_handleComposerStateChange);
  }

  @override
  void dispose() {
    _textController.removeListener(_handleComposerStateChange);
    _inputFocusNode.removeListener(_handleComposerStateChange);
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _handleComposerStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

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
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    ref.read(chatProvider.notifier).sendMessage(text, contextData: widget.trip);
    _inputFocusNode.requestFocus();

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
      backgroundColor: context.appScaffoldColor,
      body: Column(
        children: [
          _buildHeader()
              .animate()
              .fade(duration: 400.ms)
              .slideY(begin: -0.1, curve: Curves.easeOutQuart),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      context.tr('chat.typing'),
                      style: TextStyle(
                        color: context.appMutedTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ).animate().fadeIn();
                }

                final message = messages[index];
                return _ChatBubble(isAi: message.isAi, text: message.text)
                    .animate()
                    .fade(duration: 300.ms)
                    .slideY(
                      begin: 0.1,
                      duration: 300.ms,
                      curve: Curves.easeOutQuart,
                    );
              },
            ),
          ),
          _buildQuickReplies()
              .animate()
              .fade(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutQuart),
          _buildInputBar()
              .animate()
              .fade(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutQuart),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.g400, AppColors.g600],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.24),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('chat.title'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              Text(
                context.tr('chat.statusReady'),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.g300,
                ),
              ),
            ],
          ),
          const Spacer(),
          PopupMenuButton<_ChatMenuAction>(
            icon: const Icon(Icons.more_vert, color: AppColors.white),
            color: context.appSurfaceColor,
            onSelected: (value) {
              switch (value) {
                case _ChatMenuAction.clear:
                  ref.read(chatProvider.notifier).resetConversation();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ChatMenuAction.clear,
                child: Row(
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.g700,
                    ),
                    const SizedBox(width: 10),
                    Text(context.tr('chat.menu.clear')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    final quickReplies = [
      (
        label: context.tr('chat.quick.weather'),
        prompt: context.tr('chat.quick.weatherPrompt'),
      ),
      (
        label: context.tr('chat.quick.budget'),
        prompt: context.tr('chat.quick.budgetPrompt'),
      ),
      (
        label: context.tr('chat.quick.hotels'),
        prompt: context.tr('chat.quick.hotelsPrompt'),
      ),
      (
        label: context.tr('chat.quick.dates'),
        prompt: context.tr('chat.quick.datesPrompt'),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: quickReplies.map((item) {
          return GestureDetector(
            onTap: () {
              _textController.text = item.prompt;
              _sendMessage();
            },
            child: _QrChip(label: item.label),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    final isFocused = _inputFocusNode.hasFocus;
    final borderColor = isFocused
        ? (context.isDarkMode ? AppColors.g400 : AppColors.g500)
        : context.appBorderStrongColor;
    final inputDirection = context.appLanguage.isRtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final inputAlign = context.appLanguage.isRtl
        ? TextAlign.right
        : TextAlign.left;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.appBorderColor)),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.appSurfaceAltColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: borderColor,
                      width: isFocused ? 1.4 : 1,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      focusNode: _inputFocusNode,
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      textAlign: inputAlign,
                      textDirection: inputDirection,
                      decoration: InputDecoration(
                        hintText: context.tr('chat.askHint'),
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.appMutedTextColor,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.appTextColor,
                        height: 1.4,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: _hasDraft ? AppColors.g600 : context.appSurfaceAltColor,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _hasDraft ? _sendMessage : null,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.send_rounded,
                      color: _hasDraft
                          ? AppColors.white
                          : context.appMutedTextColor,
                      size: 20,
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

class _ChatBubble extends StatelessWidget {
  final bool isAi;
  final String text;

  const _ChatBubble({required this.isAi, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isAi
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAi) const _Avatar(isAi: true),
          const SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isAi ? context.appSurfaceColor : null,
              gradient: isAi
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.g500, AppColors.g700],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isAi ? 4 : 16),
                bottomRight: Radius.circular(isAi ? 16 : 4),
              ),
              border: isAi ? Border.all(color: context.appBorderColor) : null,
              boxShadow: [
                BoxShadow(
                  color: isAi
                      ? Colors.black.withValues(alpha: 0.05)
                      : AppColors.g700.withValues(alpha: 0.16),
                  blurRadius: isAi ? 8 : 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              text.replaceAll('**', ''),
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isAi ? context.appTextColor : AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!isAi) const _Avatar(isAi: false),
        ],
      ),
    );
  }
}

enum _ChatMenuAction { clear }

class _Avatar extends StatelessWidget {
  final bool isAi;

  const _Avatar({required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isAi
            ? (context.isDarkMode ? AppColors.g700 : AppColors.g100)
            : (context.isDarkMode
                  ? AppColors.white.withValues(alpha: 0.12)
                  : AppColors.gray200),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isAi ? Icons.smart_toy_rounded : Icons.person_rounded,
          size: 16,
          color: isAi
              ? (context.isDarkMode ? AppColors.white : AppColors.g700)
              : (context.isDarkMode ? AppColors.white : AppColors.gray700),
        ),
      ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDarkMode
              ? [const Color(0xff16211d), const Color(0xff101916)]
              : [AppColors.white, const Color(0xfff3fbf6)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: context.isDarkMode
              ? AppColors.g700.withValues(alpha: 0.55)
              : AppColors.g200,
        ),
        boxShadow: [
          BoxShadow(
            color: context.appShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: context.isDarkMode ? AppColors.g200 : AppColors.g700,
          ),
        ),
      ),
    );
  }
}
