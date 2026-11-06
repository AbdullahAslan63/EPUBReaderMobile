import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

/// Modern sol fihrist — süzme + genişleyen bölüm ağacı.
class FihristDrawer extends StatefulWidget {
  const FihristDrawer({
    super.key,
    required this.chapters,
    required this.onChapterSelected,
    this.activeHref,
  });

  final List<EpubChapter> chapters;
  final ValueChanged<EpubChapter> onChapterSelected;
  final String? activeHref;

  @override
  State<FihristDrawer> createState() => _FihristDrawerState();
}

class _FihristDrawerState extends State<FihristDrawer> {
  final _filterController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<EpubChapter> _filter(List<EpubChapter> chapters) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return chapters;

    List<EpubChapter> filterNode(EpubChapter chapter) {
      final children = <EpubChapter>[];
      for (final sub in chapter.subitems) {
        children.addAll(filterNode(sub));
      }
      final selfMatch = chapter.title.toLowerCase().contains(q);
      if (selfMatch || children.isNotEmpty) {
        return [
          EpubChapter(
            title: chapter.title,
            href: chapter.href,
            id: chapter.id,
            subitems: children,
          ),
        ];
      }
      return const [];
    }

    final out = <EpubChapter>[];
    for (final c in chapters) {
      out.addAll(filterNode(c));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.78;
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filter(widget.chapters);

    return Drawer(
      width: width,
      backgroundColor: scheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fihrist',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SearchBar(
                controller: _filterController,
                hintText: 'Süz',
                leading: const Icon(Icons.filter_list),
                trailing: [
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _filterController.clear();
                        setState(() => _query = '');
                      },
                    ),
                ],
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: widget.chapters.isEmpty
                  ? const Center(child: Text('Bölümler yükleniyor…'))
                  : filtered.isEmpty
                      ? const Center(child: Text('Sonuç yok'))
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            for (final chapter in filtered)
                              _ChapterNode(
                                chapter: chapter,
                                depth: 0,
                                activeHref: widget.activeHref,
                                forceExpanded: _query.isNotEmpty,
                                onSelected: widget.onChapterSelected,
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterNode extends StatelessWidget {
  const _ChapterNode({
    required this.chapter,
    required this.depth,
    required this.onSelected,
    this.activeHref,
    this.forceExpanded = false,
  });

  final EpubChapter chapter;
  final int depth;
  final String? activeHref;
  final bool forceExpanded;
  final ValueChanged<EpubChapter> onSelected;

  bool get _isActive =>
      activeHref != null &&
      activeHref!.isNotEmpty &&
      chapter.href == activeHref;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasChildren = chapter.subitems.isNotEmpty;
    final title = chapter.title.isEmpty ? 'Bölüm' : chapter.title;
    final titleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: _isActive ? scheme.primary : null,
          fontWeight: _isActive || depth == 0 ? FontWeight.w600 : FontWeight.w400,
          fontSize: depth == 0 ? 16 : 14,
        );

    if (!hasChildren) {
      return ListTile(
        contentPadding: EdgeInsets.only(left: 16.0 + depth * 12, right: 16),
        title: Text(title, style: titleStyle),
        onTap: () => onSelected(chapter),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: forceExpanded || depth == 0,
        tilePadding: EdgeInsets.only(left: 8.0 + depth * 8, right: 8),
        childrenPadding: EdgeInsets.zero,
        title: Text(title, style: titleStyle),
        onExpansionChanged: (_) {},
        children: [
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.only(left: 28.0 + depth * 12, right: 16),
            title: Text(
              'Bölüme git',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                  ),
            ),
            onTap: () => onSelected(chapter),
          ),
          for (final sub in chapter.subitems)
            _ChapterNode(
              chapter: sub,
              depth: depth + 1,
              activeHref: activeHref,
              forceExpanded: forceExpanded,
              onSelected: onSelected,
            ),
        ],
      ),
    );
  }
}
