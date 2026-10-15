import '../../../l10n/app_localizations.dart';
import '../../../services/share/offers.dart';

String offerStatusLabel(AppLocalizations l, OfferStatus s) => switch (s) {
  OfferStatus.pending => l.offerPending,
  OfferStatus.accepted => l.offerAccepted,
  OfferStatus.declined => l.offerDeclined,
  OfferStatus.cancelled => l.offerCancelled,
  OfferStatus.expired => l.offerExpired,
  OfferStatus.done => l.offerDone,
  OfferStatus.failed => l.offerFailed,
};
