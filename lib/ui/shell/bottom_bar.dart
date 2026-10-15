import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class BottomBarItem {
  const BottomBarItem(this.icon, this.selectedIcon, this.label);

  final IconData icon, selectedIcon;
  final String label;
}

/// Three always-labelled destinations, no selection pill.
class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<BottomBarItem> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return Material(
      color: cc.bg.withValues(alpha: 0.94),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: CcDims.bottomBarHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    label: items[i].label,
                    child: InkWell(
                      onTap: () => onSelect(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            i == selected
                                ? items[i].selectedIcon
                                : items[i].icon,
                            size: 24,
                            color: i == selected ? cc.text : cc.textMuted,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: i == selected ? cc.text : cc.textMuted,
                            ),
                          ),
                        ],
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
