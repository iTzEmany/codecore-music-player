import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import 'tracks_tab.dart';

/// Favourites as a page of its own (rebuilt with a header in 11.11).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.navFavorites)),
        body: const TracksTab(favoritesOnly: true),
      );
}
