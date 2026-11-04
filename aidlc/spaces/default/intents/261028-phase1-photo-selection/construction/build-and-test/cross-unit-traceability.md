# 単位横断の追跡確認

## 判定

2026-11-04の最新実行もpass=false、未被覆NFR2/NFR4/NFR5。機能要件FR1〜FR8と記録上の全ACの被覆は維持。速度は実測でNot Met、資源10往復はMetとなったが、旧単位のDeferredを独断で書き換えない。

| 未被覆ID | 所有 | 機械上の未実装/繰延詳細 | 対象ファイル |
|---|---|---|---|
| NFR2 | U1記録、最終実測はU3/Build and Test | NFR2.1、NFR2.5 | construction/u1-integrated-selection/code-generation/traceability.json、verification/real-library-measurement-20261104.md |
| NFR4 | U1記録、最終操作確認はU3 | NFR4.1 | construction/u1-integrated-selection/code-generation/traceability.json、construction/build-and-test/manual-acceptance.md |
| NFR5 | U1記録 | NFR5.4、NFR5.5 | construction/u1-integrated-selection/code-generation/traceability.json、construction/build-and-test/manual-acceptance.md |

これらを承認確認時の所見として提示する。本人の速度受入を、追跡記録の完全性や他の未確認条件の承認とは扱わない。

FAIL。機械検証はNFR2/NFR4/NFR5を未被覆と報告。以前の単位に残るDeferred記載が含まれるため、U3の現在の対応があっても自動的に旧記載を成功へ書き換えない。実機未確認とP-MEASUREも残る。これは機能がすべて未実装という意味ではない。

## IDごとの結果

| ID | 機械上の被覆 | 所有と対象ファイル/根拠 |
|---|---|---|
| FR1 | 記録上被覆 | AC1.1.1、AC1.1.2、AC1.1.3 |
| FR2 | 記録上被覆 | AC1.2.1、AC1.2.2、AC1.2.3、AC1.2.4 |
| FR3 | 記録上被覆 | AC1.3.1、AC1.3.2、AC1.3.3、AC1.3.4、AC1.3.5 |
| FR4 | 記録上被覆 | AC1.4.1、AC1.4.2、AC1.4.3、AC1.4.4、AC1.4.5 |
| FR5 | 記録上被覆 | AC1.5.1、AC1.5.2、AC1.5.3、AC1.5.4 |
| FR6 | 記録上被覆 | AC1.6.1、AC1.6.2、AC1.6.3、AC1.6.4、AC1.6.5 |
| FR7 | 記録上被覆 | AC1.7.1、AC1.7.2、AC1.7.3、AC1.7.4 |
| FR8 | 記録上被覆 | AC1.8.1、AC1.8.2、AC1.8.3、AC1.8.4 |
| NFR1 | 記録上被覆 | u1-integrated-selection: NFR1.1、u1-integrated-selection: NFR1.2、u1-integrated-selection: NFR1.3、u1-integrated-selection: NFR1.4 |
| NFR2 | 未被覆 | u1-integrated-selection: NFR2.1、u1-integrated-selection: NFR2.2、u1-integrated-selection: NFR2.3、u1-integrated-selection: NFR2.4、u1-integrated-selection: NFR2.5、u1-integrated-selection: NFR2.6、u1-integrated-selection: NFR2.7、u1-integrated-selection: NFR2.8、u1-integrated-selection: NFR2.9、u2-session-reliability: NFR2.21、u2-session-reliability: NFR2.22、u2-session-reliability: NFR2.23、u2-session-reliability: NFR2.24、u3-native-experience: NFR2.31、u3-native-experience: NFR2.32、u3-native-experience: NFR2.33、u3-native-experience: NFR2.34 |
| NFR3 | 記録上被覆 | u1-integrated-selection: NFR3.1、u1-integrated-selection: NFR3.2、u1-integrated-selection: NFR3.3、u1-integrated-selection: NFR3.4、u1-integrated-selection: NFR3.5、u1-integrated-selection: NFR3.6、u1-integrated-selection: NFR3.7、u1-integrated-selection: NFR3.8、u1-integrated-selection: NFR3.9、u2-session-reliability: NFR3.21、u2-session-reliability: NFR3.22、u2-session-reliability: NFR3.23、u2-session-reliability: NFR3.24、u2-session-reliability: NFR3.25、u2-session-reliability: NFR3.26、u2-session-reliability: NFR3.27、u3-native-experience: NFR3.31、u3-native-experience: NFR3.32、u3-native-experience: NFR3.33 |
| NFR4 | 未被覆 | u1-integrated-selection: NFR4.1、u2-session-reliability: NFR4.21、u3-native-experience: NFR4.31、u3-native-experience: NFR4.32、u3-native-experience: NFR4.33、u3-native-experience: NFR4.34 |
| NFR5 | 未被覆 | u1-integrated-selection: NFR5.1、u1-integrated-selection: NFR5.2、u1-integrated-selection: NFR5.3、u1-integrated-selection: NFR5.4、u1-integrated-selection: NFR5.5、u1-integrated-selection: NFR5.6、u1-integrated-selection: NFR5.7、u3-native-experience: NFR5.31 |
| AC1.1.1 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/PhotoLibraryAccess.swift、u2-session-reliability: HitotsuzuriU2Tests/U2RestoreTests.swift、u3-native-experience: HitotsuzuriCore/PickerContent.swift |
| AC1.1.2 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/PhotoLibraryAccess.swift、u2-session-reliability: HitotsuzuriU2Tests/U2RestoreTests.swift、u3-native-experience: HitotsuzuriCore/PickerContent.swift |
| AC1.1.3 | 記録上被覆 | u3-native-experience: HitotsuzuriCore/PickerContent.swift |
| AC1.2.1 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/PhotoLibraryAccess.swift、u3-native-experience: HitotsuzuriU3Tests/U3LayoutTests.swift |
| AC1.2.2 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/PhotoLibraryAccess.swift、u3-native-experience: HitotsuzuriU3Tests/U3LayoutTests.swift |
| AC1.2.3 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/PhotoLibraryAccess.swift、u3-native-experience: HitotsuzuriU3Tests/U3LayoutTests.swift |
| AC1.2.4 | 記録上被覆 | u3-native-experience: HitotsuzuriU3Tests/U3LayoutTests.swift |
| AC1.3.1 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/LocalImageAccess.swift、u3-native-experience: HitotsuzuriCore/PickerContent.swift |
| AC1.3.2 | 記録上被覆 | u3-native-experience: HitotsuzuriCore/PickerContent.swift |
| AC1.3.3 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/LocalImageAccess.swift、u2-session-reliability: HitotsuzuriU2Tests/U2PresentationTests.swift、u3-native-experience: HitotsuzuriCore/PickerContent.swift |
| AC1.3.4 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/LocalImageAccess.swift、u2-session-reliability: HitotsuzuriU2Tests/U2PresentationTests.swift、u3-native-experience: HitotsuzuriCore/PickerContent.swift |
| AC1.3.5 | 記録上被覆 | u3-native-experience: HitotsuzuriCore/PickerContent.swift |
| AC1.4.1 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/SelectionWorkflow.swift、u3-native-experience: HitotsuzuriU3Tests/U3AccessibilityTests.swift |
| AC1.4.2 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/SelectionWorkflow.swift、u3-native-experience: HitotsuzuriU3Tests/U3AccessibilityTests.swift |
| AC1.4.3 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/SelectionWorkflow.swift、u3-native-experience: HitotsuzuriU3Tests/U3AccessibilityTests.swift |
| AC1.4.4 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/SelectionWorkflow.swift、u3-native-experience: HitotsuzuriU3Tests/U3AccessibilityTests.swift |
| AC1.4.5 | 記録上被覆 | u3-native-experience: HitotsuzuriU3Tests/U3AccessibilityTests.swift |
| AC1.5.1 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/SelectionWorkflow.swift、u2-session-reliability: HitotsuzuriCore/SelectionWorkflow.swift、u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |
| AC1.5.2 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/SelectionWorkflow.swift、u2-session-reliability: HitotsuzuriCore/SelectionWorkflow.swift、u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |
| AC1.5.3 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/SelectionWorkflow.swift、u2-session-reliability: HitotsuzuriCore/SelectionWorkflow.swift、u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |
| AC1.5.4 | 記録上被覆 | u2-session-reliability: HitotsuzuriU2Tests/U2IntegrationTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |
| AC1.6.1 | 記録上被覆 | u1-integrated-selection: HitotsuzuriU1Tests/U1IntegrationTests.swift、u2-session-reliability: HitotsuzuriU2Tests/U2RecoveryTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3SaveCompletionTests.swift |
| AC1.6.2 | 記録上被覆 | u1-integrated-selection: HitotsuzuriU1Tests/U1IntegrationTests.swift、u2-session-reliability: HitotsuzuriU2Tests/U2RecoveryTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3SaveCompletionTests.swift |
| AC1.6.3 | 記録上被覆 | u1-integrated-selection: HitotsuzuriU1Tests/U1IntegrationTests.swift、u2-session-reliability: HitotsuzuriU2Tests/U2RecoveryTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3SaveCompletionTests.swift |
| AC1.6.4 | 記録上被覆 | u1-integrated-selection: HitotsuzuriU1Tests/U1IntegrationTests.swift、u2-session-reliability: HitotsuzuriU2Tests/U2RecoveryTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3SaveCompletionTests.swift |
| AC1.6.5 | 記録上被覆 | u1-integrated-selection: HitotsuzuriU1Tests/U1IntegrationTests.swift、u2-session-reliability: HitotsuzuriU2Tests/U2RecoveryTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3SaveCompletionTests.swift |
| AC1.7.1 | 記録上被覆 | u2-session-reliability: HitotsuzuriU2Tests/U2RestoreTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |
| AC1.7.2 | 記録上被覆 | u2-session-reliability: HitotsuzuriU2Tests/U2RestoreTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |
| AC1.7.3 | 記録上被覆 | u2-session-reliability: HitotsuzuriU2Tests/U2RestoreTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |
| AC1.7.4 | 記録上被覆 | u2-session-reliability: HitotsuzuriU2Tests/U2RestoreTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |
| AC1.8.1 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/SelectionWorkflow.swift、u2-session-reliability: HitotsuzuriU2Tests/U2RecoveryTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |
| AC1.8.2 | 記録上被覆 | u1-integrated-selection: HitotsuzuriCore/SelectionWorkflow.swift、u2-session-reliability: HitotsuzuriU2Tests/U2PresentationTests.swift、u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |
| AC1.8.3 | 記録上被覆 | u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |
| AC1.8.4 | 記録上被覆 | u1-integrated-selection: scripts/check-coverage.swift、u2-session-reliability: scripts/verify-phase1.sh、u3-native-experience: HitotsuzuriU3Tests/U3IntegrationTests.swift |

## 未被覆

NFR2、NFR4、NFR5。実機合格とは区別し、最終の判断時に残件を提示する。

