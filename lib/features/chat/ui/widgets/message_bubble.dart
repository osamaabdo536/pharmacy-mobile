import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;

  const MessageBubble({
    required this.message,
    this.isStreaming = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final direction = _detectDirection(message.text);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Sender label + timestamp
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/Dawak_Icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Medo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (!isStreaming)
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                if (isUser) ...[
                  const SizedBox(width: 6),
                  const Text(
                    'You',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: isUser
                ? Text(
                    message.text,
                    textDirection: direction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  )
                : Directionality(
                    textDirection: direction,
                    child: MarkdownBody(
                      data: isStreaming
                          ? _cleanPartialMarkdown(message.text)
                          : message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.4,
                        ),
                        strong: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        em: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquote: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        listBullet: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        code: TextStyle(
                          backgroundColor: AppColors.border,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Detects text direction based on first strong character.
  TextDirection _detectDirection(String text) {
    for (final char in text.runes) {
      if ((char >= 0x0600 && char <= 0x06FF) ||
          (char >= 0x0750 && char <= 0x077F) ||
          (char >= 0xFB50 && char <= 0xFDFF) ||
          (char >= 0xFE70 && char <= 0xFEFF)) {
        return TextDirection.rtl;
      }
      if ((char >= 0x0041 && char <= 0x007A)) {
        return TextDirection.ltr;
      }
    }
    return TextDirection.rtl;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _cleanPartialMarkdown(String text) {
    final boldCount = '**'.allMatches(text).length;
    String result = text;
    if (boldCount.isOdd) result += '**';
    final cleaned = result.replaceAll('**', '');
    final italicCount = '*'.allMatches(cleaned).length;
    if (italicCount.isOdd) result += '*';
    return result;
  }
}
