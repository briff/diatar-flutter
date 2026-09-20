import 'package:diatar_common/diatar_common.dart';

class ProjectionGlobalsPolicy {
  const ProjectionGlobalsPolicy();

  ProjectionGlobals fromSettings(
    AppSettings settings, {
    required bool projecting,
    required bool hasBackgroundImage,
  }) {
    return const ProjectionGlobals().copyWith(
      bkColor: settings.bkColor,
      txtColor: settings.txtColor,
      blankColor: settings.blankColor,
      hiColor: settings.hiColor,
      isBlankPic: hasBackgroundImage,
      showBlankPic: hasBackgroundImage && settings.projShowBackgroundImage,
      projecting: projecting,
      fontSize: settings.projFontSize,
      titleSize: settings.projTitleSize,
      leftIndent: settings.projLeftIndent,
      borderL: settings.projBorderL,
      borderT: settings.projBorderT,
      borderR: settings.projBorderR,
      borderB: settings.projBorderB,
      spacing100: 100 + settings.projSpacingStep * 10,
      autoResize: settings.projAutoSize,
      hCenter: settings.projHCenter,
      vCenter: settings.projVCenter,
      useAkkord: settings.projUseAkkord,
      useKotta: settings.projUseKotta,
      inverzKotta: settings.projInverseKotta,
      hideTitle: !settings.projUseTitle,
      kottaArany: settings.projKottaArany,
      akkordArany: settings.projAkkordArany,
      bgMode: settings.projBgMode,
      backTrans: settings.projBackTrans,
      blankTrans: settings.projBlankTrans,
      boldText: settings.projBoldText,
    );
  }
}
