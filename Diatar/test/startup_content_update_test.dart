import 'package:diatar_app/src/controllers/diatar_main_controller.dart';
import 'package:diatar_app/src/services/dtx_download_service.dart';
import 'package:diatar_app/src/services/dtz_download_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finds only non-excluded installed DTX updates at startup', () {
    final DtxDownloadItem update = DtxDownloadItem(
      fileName: 'book.dtx',
      timestamp: '20260916100000',
      size: 1,
      group: '',
      order: 0,
      longName: 'Book',
      shortName: 'Book',
      isInstalled: true,
      updateAvailable: true,
    );

    expect(
      DiatarMainController.hasEligibleStartupDtxUpdate(<DtxManageItem>[
        DtxManageItem(item: update, excluded: true),
      ]),
      isFalse,
    );
    expect(
      DiatarMainController.hasEligibleStartupDtxUpdate(<DtxManageItem>[
        DtxManageItem(item: update, excluded: false),
      ]),
      isTrue,
    );
  });

  test('finds only non-excluded installed score and music updates at startup', () {
    final DtzDownloadItem update = DtzDownloadItem(
      fileName: 'song.dtz',
      timestamp: '20260916100000',
      size: 1,
      title: 'Song',
      zips: const <String>[],
      isInstalled: true,
      updateAvailable: true,
    );

    expect(
      DiatarMainController.hasEligibleStartupDtzUpdate(<DtzManageItem>[
        DtzManageItem(item: update, excluded: true),
      ]),
      isFalse,
    );
    expect(
      DiatarMainController.hasEligibleStartupDtzUpdate(<DtzManageItem>[
        DtzManageItem(item: update, excluded: false),
      ]),
      isTrue,
    );
  });
}
