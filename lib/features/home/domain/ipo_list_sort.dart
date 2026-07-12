import 'package:untitled_poi/features/home/domain/ipo_model.dart';

/// Display order for the Current IPO tab: open → closed → upcoming.
int currentIpoStatusOrder(IpoStatus status) {
  switch (status) {
    case IpoStatus.open:
      return 0;
    case IpoStatus.closed:
      return 1;
    case IpoStatus.upcoming:
      return 2;
    case IpoStatus.listed:
      return 3;
  }
}

/// Sort current (non-listed) IPOs: open first, then closed, then upcoming.
void sortCurrentIpos(List<IpoModel> ipos) {
  ipos.sort((a, b) {
    final statusCmp =
        currentIpoStatusOrder(a.status).compareTo(currentIpoStatusOrder(b.status));
    if (statusCmp != 0) return statusCmp;

    final aDate = a.openDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.openDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (a.status == IpoStatus.upcoming) {
      return aDate.compareTo(bDate);
    }
    return bDate.compareTo(aDate);
  });
}

/// Sort listed IPOs by listing date (newest first).
void sortListedIpos(List<IpoModel> ipos) {
  ipos.sort((a, b) {
    final aDate = a.listingDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.listingDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });
}
