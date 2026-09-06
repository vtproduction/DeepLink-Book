import 'package:flutter/material.dart';

class AppRootTopBar extends StatefulWidget implements PreferredSizeWidget {
  const AppRootTopBar({
    super.key,
    required this.title,
    required this.searchQuery,
    required this.isSearching,
    required this.onSearchPressed,
    required this.onSearchQueryChanged,
    required this.onSearchClose,
    required this.onSettingsPressed,
    this.eyebrow,
    this.leading,
    this.actions = const [],
  });

  final String title;
  final String searchQuery;
  final bool isSearching;
  final VoidCallback onSearchPressed;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onSearchClose;
  final VoidCallback onSettingsPressed;
  final String? eyebrow;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<AppRootTopBar> createState() => _AppRootTopBarState();
}

class _AppRootTopBarState extends State<AppRootTopBar> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _searchFocusNode = FocusNode();

    if (widget.isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppRootTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }

    if (widget.isSearching && !oldWidget.isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSearching) {
      return AppBar(
        leading: IconButton(
          tooltip: 'Close search',
          onPressed: _closeSearch,
          icon: const Icon(Icons.arrow_back),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onChanged: widget.onSearchQueryChanged,
        ),
        actions: [
          IconButton(
            tooltip: 'Clear search',
            onPressed: _closeSearch,
            icon: const Icon(Icons.close),
          ),
        ],
      );
    }

    return AppBar(
      titleSpacing: widget.leading == null ? null : 0,
      leadingWidth: widget.leading == null ? null : 72,
      leading: widget.leading == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: widget.leading,
            ),
      title: _TopBarTitle(title: widget.title, eyebrow: widget.eyebrow),
      actions: [
        ...widget.actions,
        IconButton(
          tooltip: 'Search ${widget.title}',
          onPressed: widget.onSearchPressed,
          icon: const Icon(Icons.search),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: widget.onSettingsPressed,
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    widget.onSearchClose();
  }
}

class _TopBarTitle extends StatelessWidget {
  const _TopBarTitle({required this.title, this.eyebrow});

  final String title;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final eyebrow = this.eyebrow;

    if (eyebrow == null) {
      return Text(title);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
