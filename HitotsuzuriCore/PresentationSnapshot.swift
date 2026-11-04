import Foundation

public struct PresentationSnapshot: Equatable, Sendable {
    public let statusText: String
    public let countText: String
    public let slotIDs: [String?]
    public let canConfirm: Bool
    public let confirmTitle:String
    @MainActor public init(_ workflow: SelectionWorkflow) {
        let selected=workflow.selection.orderedIDs
        countText="\(selected.count) / 4枚"; slotIDs=(0..<4).map { $0<selected.count ? selected[$0] : nil }; canConfirm=workflow.canConfirm
        if case .failed=workflow.selectionSaveState {confirmTitle="保存を再試行"} else {confirmTitle="4枚を確定して保存"}
        let main:String
        if workflow.authorization == .notDetermined {main="写真ライブラリの参照を許可してください。"}
        else if workflow.authorization != .authorized {
            main=(workflow.selectionSaveState == .saved ? "4枚を保存しました。 " : "")+PickerFailure.authorization.message
        }
        else if workflow.restoreState.isBusy {main="前回の保存内容を確認して復元しています…"}
        else if let error=workflow.error {
            if error == .corruptData,workflow.settingsReadFailure == nil {
                main="保存データを読み取れません。改めて4枚を選んで確定すると、破損原本を退避して保存します。"
            } else {main=error.message}
        }
        else if workflow.isLoading {main="読み込んでいます…"}
        else if !workflow.notice.isEmpty {main=workflow.notice}
        else if workflow.targetFolders.isEmpty {main="対象フォルダを選択してください。Commandキーで複数選べます。"}
        else if workflow.activeAlbum == nil {main="アルバムを1つ選択してください。"}
        else if workflow.assets.isEmpty {main="このアルバムに写真はありません。"}
        else {main=workflow.isDirty ? "未保存：写真を4枚選んで確定してください。" : "保存済み"}
        let settings:String
        if let failure=workflow.settingsReadFailure {
            settings="設定を読み取れません。原本を保護しています。"+(failure == .unsupportedVersion ? "対応するアプリをご確認ください。" : "手動復旧手順を確認してください。")
        } else if case .failed(let failure)=workflow.settingsSaveState {
            settings="設定を保存できませんでした。"+failure.message
        } else {settings=""}
        statusText=settings.isEmpty ? main : main+" "+settings
    }
}

