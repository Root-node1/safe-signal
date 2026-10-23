// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get language => 'Lugha';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSwahili => 'Kiswahili';

  @override
  String get homeTitle => 'Ripoti tukio';

  @override
  String get homeIntro =>
      'SafeSignal huwasaidia abiria wa matatu na boda-boda nchini Kenya kuandika tukio la usalama. Huhitaji akaunti, na kila maelezo isipokuwa kilichotokea ni hiari.';

  @override
  String get homeReport => 'Ripoti tukio';

  @override
  String get homeReportNow => 'Ripoti kinachotokea sasa';

  @override
  String get prototypeTitle => 'Toleo la majaribio';

  @override
  String get prototypeBody =>
      'Ripoti yako hutumwa kwa SafeSignal tu unapobonyeza Tuma kwenye hatua ya mwisho, na hakuna kinachohifadhiwa kwenye simu yako. Katika toleo hili la majaribio, ripoti huhifadhiwa kwa muda na zinaweza kufutwa.';

  @override
  String get notEmergencyTitle => 'Si huduma ya dharura';

  @override
  String get notEmergencyBody =>
      'SafeSignal haiwasiliani na polisi wala mtu mwingine yeyote, na haifuatilii njia wala kuthibitisha ripoti. Ukiwa katika hatari ya haraka, piga 999 au 112.';

  @override
  String stepOf(int current, int total) {
    return 'Hatua ya $current kati ya $total';
  }

  @override
  String get whatHappenedTitle => 'Nini kilitokea?';

  @override
  String get timingNow => 'Inatokea sasa';

  @override
  String get timingAfter => 'Ilishatokea';

  @override
  String get dangerNote =>
      'Ukiwa katika hatari ya haraka, piga 999 au 112. SafeSignal haiwezi kutuma msaada.';

  @override
  String get chooseIncidentError => 'Chagua kilichotokea ili kuendelea.';

  @override
  String get detailsTitle => 'Maelezo (hiari)';

  @override
  String get detailsHint =>
      'Ongeza tu ulichokiona. Tafadhali usiandike majina wala namba za simu.';

  @override
  String get fieldRoute => 'Njia au barabara';

  @override
  String get hintRoute => 'k.m. Ruiru hadi CBD';

  @override
  String get fieldVehicle => 'Namba ya usajili au jina la matatu';

  @override
  String get hintVehicle => 'k.m. KDA 123A';

  @override
  String get fieldSacco => 'SACCO au mwendeshaji';

  @override
  String get hintSacco => 'k.m. Super Metro';

  @override
  String get fieldArea => 'Ilitokea wapi?';

  @override
  String get hintArea => 'k.m. karibu na stendi ya Githurai 45';

  @override
  String get actionContinue => 'Endelea';

  @override
  String get actionBack => 'Rudi';

  @override
  String get incidentHarassmentLabel => 'Mtu ananinyanyasa';

  @override
  String get incidentHarassmentDesc =>
      'Maneno ya kudhalilisha yanayorudiwa, vitisho, au tabia ya ukali.';

  @override
  String get incidentThreatsLabel => 'Mtu ananitishia';

  @override
  String get incidentThreatsDesc =>
      'Vitisho vya moja kwa moja vya maneno au vya kimwili vya kudhuru au kulazimisha kutoa pesa.';

  @override
  String get incidentTouchingLabel => 'Kuguswa bila ridhaa yangu';

  @override
  String get incidentTouchingDesc =>
      'Kuguswa mwilini bila ridhaa, kusongamana, au kuvamiwa nafasi yako.';

  @override
  String get incidentFollowedLabel => 'Nadhani ninafuatwa';

  @override
  String get incidentFollowedDesc =>
      'Mtu anakufuata kwenye stendi, kituo, au baada ya kushuka.';

  @override
  String get incidentDrivingLabel => 'Dereva anaendesha kwa hatari';

  @override
  String get incidentDrivingDesc =>
      'Mwendo kasi kupita kiasi, kuovateki kwa hatari, kuendesha kizembe, au kuendesha akiwa amelewa au hayuko katika hali nzuri.';

  @override
  String get incidentUnsureLabel => 'Kitu kingine / sina uhakika';

  @override
  String get incidentUnsureDesc =>
      'Usumbufu usio wa kawaida, wizi, kuchezea mizigo, au wasiwasi mwingine wa usalama.';

  @override
  String get supportHeading => 'Nini kingesaidia zaidi?';

  @override
  String get supportIntro =>
      'Chagua chaguo. Hakuna kinachotumwa hadi utakapotuma kwenye hatua ya mwisho.';

  @override
  String get supportPrivateTitle => 'Tuma bila kuwasiliana na mtu yeyote';

  @override
  String get supportPrivateHint =>
      'Ripoti yako huenda kwa SafeSignal pekee. Hakuna mtu mwingine anayewasiliana naye.';

  @override
  String get supportNumbersTitle =>
      'Onyesha namba za simu za dharura na msaada';

  @override
  String get supportNumbersHint =>
      'Inaonyesha namba rasmi za msaada za kitaifa ili upige mwenyewe. SafeSignal haipigi simu kwa niaba yako.';

  @override
  String get supportTrustedTitle => 'Mjulishe mtu ninayemwamini';

  @override
  String get supportTrustedHint =>
      'SMS ya kiotomatiki kwa mtu uliyemchagua inatengenezwa na bado haipatikani.';

  @override
  String get supportCheckInTitle => 'Omba ufuatiliaji wa mshirika';

  @override
  String get supportCheckInHint =>
      'Simu za ufuatiliaji wa usalama kutoka kwa shirika mshirika zinatengenezwa na bado hazipatikani.';

  @override
  String get unavailableTag => 'Haipatikani · Inatengenezwa';

  @override
  String get unavailableSemantics => 'Haipatikani, inatengenezwa.';

  @override
  String get chooseSupportError =>
      'Chagua chaguo linalopatikana ili kuendelea.';

  @override
  String get actionReview => 'Kagua';

  @override
  String get reviewTitle => 'Kagua maelezo yako';

  @override
  String get reviewIntro =>
      'Bado hakuna kilichotumwa. Bonyeza Tuma ripoti ili kutuma hii kwa SafeSignal. SafeSignal si huduma ya dharura.';

  @override
  String get reviewRowWhen => 'Lini';

  @override
  String get reviewRowWhat => 'Kilichotokea';

  @override
  String get reviewRowSupport => 'Kinachosaidia zaidi';

  @override
  String get notProvided => 'Haijatolewa';

  @override
  String get actionSubmit => 'Tuma ripoti';

  @override
  String get submitting => 'Inatuma…';

  @override
  String get submittingSemantics => 'Inatuma ripoti yako';

  @override
  String get actionEdit => 'Hariri maelezo';

  @override
  String get errValidation =>
      'Seva haikuweza kupokea baadhi ya maelezo. Bonyeza Hariri maelezo ili kuyakagua, kisha ujaribu tena.';

  @override
  String get errTimeout =>
      'Seva ilichukua muda mrefu kujibu. Ripoti yako inaweza kuwa imefika au haijafika. Unaweza kubonyeza Tuma ripoti tena: kujaribu tena ripoti ile ile hakutaunda nakala mbili seva ikiendelea kufanya kazi.';

  @override
  String get errOffline =>
      'Imeshindikana kuwasiliana na SafeSignal. Angalia muunganisho wako wa intaneti na ubonyeze Tuma ripoti kujaribu tena. Maelezo yako bado yapo hapa.';

  @override
  String errRateLimited(String wait) {
    return 'Ripoti nyingi sana kutoka kwenye muunganisho huu. Tafadhali subiri $wait kisha ujaribu tena.';
  }

  @override
  String get errUnexpected =>
      'Hitilafu imetokea kwenye seva. Ripoti yako haijathibitishwa kupokelewa. Tafadhali jaribu tena baadaye.';

  @override
  String get errNotConfigured =>
      'Toleo hili la programu halijaunganishwa na seva ya SafeSignal, kwa hivyo hakuna kilichotumwa.';

  @override
  String waitSeconds(int n) {
    return 'sekunde $n';
  }

  @override
  String waitMinutes(int n) {
    return 'dakika $n';
  }

  @override
  String get waitAWhile => 'muda kidogo';

  @override
  String get confirmTitle => 'Ripoti imepokelewa';

  @override
  String get confirmBody =>
      'Seva ya SafeSignal imekubali ripoti yako. Katika toleo hili la majaribio, ripoti huhifadhiwa kwa muda na zinaweza kufutwa.';

  @override
  String get refCode => 'Namba ya kumbukumbu';

  @override
  String get copyCode => 'Nakili namba';

  @override
  String get codeNote =>
      'Bado huwezi kutafuta namba hii, na inaweza kuacha kufanya kazi.';

  @override
  String get screenshotNote =>
      'Picha za skrini na viideo vya skrini hufutwa kwenye skrini hii kwa faragha yako. Tumia Nakili namba ili kuhifadhi namba yako ya kumbukumbu.';

  @override
  String get confirmNotice =>
      'Hakuna mtu aliyewasiliwa. Ripoti hii haijathibitishwa, kukaguliwa, wala kupelekwa kwingine, na hakuna kinachohifadhiwa kwenye simu yako. SafeSignal si huduma ya dharura. Ukiwa katika hatari ya haraka, piga 999 au 112.';

  @override
  String get helplinesTitle => 'Namba za dharura na msaada';

  @override
  String get helplinesIntro =>
      'Piga namba hizi mwenyewe. SafeSignal haipigi simu.';

  @override
  String get helplinePoliceName => 'Polisi na dharura';

  @override
  String get helplinePoliceDetail => 'Ukiwa katika hatari ya haraka';

  @override
  String get helplineMobileName => 'Dharura (simu ya mkononi)';

  @override
  String get helplineMobileDetail =>
      'Hufanya kazi kwenye mtandao wowote wa simu';

  @override
  String get helplineGbvName =>
      'Simu ya msaada ya kitaifa ya ukatili wa kijinsia (GBV)';

  @override
  String get helplineGbvDetail => 'Msaada baada ya ukatili au unyanyasaji';

  @override
  String get actionDone => 'Nimemaliza';

  @override
  String get quickExitLabel => 'Toka';

  @override
  String get quickExitSemantics =>
      'Kutoka haraka. Hufuta ripoti hii na kufunga SafeSignal.';

  @override
  String get restoreTitle => 'Tumaini ya ripoti';

  @override
  String get restoreIntro => 'Una ripoti iliyopotekwa.';

  @override
  String get restoreHasNotBeenSubmitted => 'Hii ripoti haijatolewa.';

  @override
  String restoreSavedAt(String date) {
    return 'Iliyopotekwa tarehe $date';
  }

  @override
  String get restoreExpiredIntro => 'Ripoti yako iliyopotekwa ilifutwa.';

  @override
  String get startANewReport => 'Tuma ripoti mpya';

  @override
  String get restore => 'Tumaini';

  @override
  String get keepSaved => 'Wezeleza';

  @override
  String get restoreCorruptIntro =>
      'Ripoti yako iliyopotekwa haikuwezeshwa kusomwa na ilifutwa.';

  @override
  String get restoreUnavailableIntro =>
      'Haukuweza kusoma ripoti yako iliyopotekwa.';

  @override
  String get restoreDeleteFailedIntro =>
      'Ripoti yako iliyopotekwa haifutwa kwa kutokufanikiwa.';

  @override
  String get restoreDeleteFailedBody =>
      'Ripoti bado imehifadhiwa kwenye simu yako.';

  @override
  String get discardAction => 'Futa ripoti iliyopotekwa';

  @override
  String get discardConfirmTitle => 'Futa ripoti iliyopotekwa?';

  @override
  String get discardConfirmBody =>
      'Hii inafuta ripoti iliyopotekwa kwenye simu yako. Haifutika tena.';

  @override
  String get discardConfirmDelete => 'Futa';

  @override
  String get discardCancel => 'Ghairi';

  @override
  String get discardFailedTitle => 'Haukuweza kufuta ripoti iliyopotekwa.';

  @override
  String get discardFailedBody => 'Ripoti bado imehifadhiwa kwenye simu yako.';

  @override
  String get restoredEditedNotice =>
      'Umebadilisha ripoti iliyopotekwa, kwa hiyo itatumwa kama ripoti mpya.';

  @override
  String get recordRetainedTitle => 'Ripoti yako bado iko hifadhiwa';

  @override
  String get recordRetainedBody =>
      'Seva ilikubali ripoti yako, lakini SafeSignal haikuweza kufuta nakili iliyohifadhiwa kwenye simu yako. Hakuna nakala nyingine itatumwa, lakini ripoti bado iko kwenye seva hivi karibu itakaposafiri.';

  @override
  String get deleteSavedReport => 'Futa ripoti iliyopotekwa';

  @override
  String get recordStillRetained =>
      'Ripoti bado imehifadhiwa kwenye simu yako.';

  @override
  String get errKeyConflict =>
      'Seva imekuta jarzamo na uficho wa ripoti hii. Ufumio mpya utatumika katika jaribu kipya, kwa hiyo itatumwa kama ripoti mpya.';

  @override
  String get errUnknownOutcome =>
      'Matokeo ya ripoti yako hayajajulikani. Inaweza kufika au kutokafika. Ripoti bado imehifadhiwa kwenye simu yako. Kubonya Tuma ripoti tena ni salama: ripoti hiyo haijatumiwa tena mara wakati seva inaendelea kufanya kazi.';

  @override
  String get quickExitRecordRetainedTitle => 'Ripoti yako bado iko hifadhiwa';

  @override
  String get quickExitRecordRetainedBody =>
      'SafeSignal haikuweza kufuta ripoti iliyopotekwa kwenye simu yako kabla ya kutoka. Programu itafunga bado, lakini ripoti bado iko kwenye seva hivi karibu itakaposafiri.';

  @override
  String get quickExitExitAnyway => 'Toka hata hivyo';

  @override
  String get quickExitTryAgain => 'Jaribu tena';
}
