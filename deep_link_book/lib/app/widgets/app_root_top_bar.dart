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
    this.actions = const [],
  });

  final String title;
  final String searchQuery;
  final bool isSearching;
  final VoidCallback onSearchPressed;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onSearchClose;
  final VoidCallback onSettingsPressed;
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
      title: Text(widget.title),
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
