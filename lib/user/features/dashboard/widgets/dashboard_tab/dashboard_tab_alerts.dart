part of 'dashboard_tab_view.dart';

class _AlertMarquee extends StatefulWidget {
  const _AlertMarquee({required this.message});

  final String message;

  @override
  State<_AlertMarquee> createState() => _AlertMarqueeState();
}

class _AlertMarqueeState extends State<_AlertMarquee> {
  final ScrollController _scrollController = ScrollController();
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runMarquee();
    });
  }

  Future<void> _runMarquee() async {
    while (mounted && _active) {
      if (!_scrollController.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        continue;
      }

      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        continue;
      }

      await _scrollController.animateTo(
        maxExtent,
        duration: const Duration(seconds: 8),
        curve: Curves.linear,
      );

      if (!mounted || !_active) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _scrollController.jumpTo(0);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  @override
  void dispose() {
    _active = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF4A7A7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
