# U3 出力の安全性・収束設計

## Sources
同UnitのNFR要件（performance-requirements.mdを含む）と機能設計、inception/contract-design/contract-summary.md C2/C3を基準とする。数値は設計目標で、未実装・未測定。既存のArticleDirectoryと一枚検証の構造を読んだが、一枚の成功を四枚の実証とは扱わない。

具体的な入力は../nfr-requirements/security-requirements.md、../nfr-requirements/tech-stack-decisions.md、../nfr-requirements/performance-requirements.md、../functional-design/functional-spec.mdである。library種別の成果物選択によりscalability-requirements.md・reliability-requirements.md・observability-requirements.mdは独立作成対象外であり、存在を仮定しない。対応する一件並行・回復・診断の条件はsecurity-requirements.mdとperformance-requirements.mdから引き継ぐ。

## D1 固定入力と一式の検証
DeliveryはSavedExportInputとRenderedArticleを値として受け、記事ID・元選択と保存版・順序・設定・指紋を検証する。指紋の正本はU2の共通規則で、Deliveryが独自の本文正規化を追加しない。MarkdownとplainTextは同じ固定投影から受け取る。画像参照はimages/01.jpg〜04.jpgの四つだけを許し、参照の絶対化・親参照・symlinkを拒否する。

生成ごとにJPEGの型/寸法とC2の設定・要求ID/assetIDを確認し、受領した一枚を書込後に解放する。完成前に四枚の存在と型、順序、本文・manifestのID/版/指紋、全生成バイトのdigestを照合する。manifest版1の既知必須項目を検証し、未知版を自動上書きしない。本文コピーにmanifestやパスを混ぜない。

## D2 保存先と原子的な公開
既存の標準選択境界を使い、選んだ親をcreate=falseで開く。親を開いたdescriptorと実体識別をジョブ中保持し、固定した単一成分だけで相対操作する。新規一時領域は排他的に作成し、0700・新規ファイル0600を基準に、nofollow・通常ファイル検査・既存のサイズ制限を維持する。外部ID/記事名をファイル名へ流用しない。

一時名はジョブ識別に基づく生成名、完成名も別の安全な生成名とする。同じ親・同じvolume内で一式を構築し、全ファイルのwrite完了と同期、imagesディレクトリと一時親の同期を確認してから、既存ArticleDirectory.moveExclusive相当のRENAME_EXCLで一括公開する。同名時に上書きrenameやcopy/deleteへフォールバックしない。非対応volumeや同期不能は失敗/不確定を返す。

一式検証時に一時ディレクトリを開いたまま保持し、その実体識別（volume/deviceとfile ID/inode等）と期待する全一式のdigestを記録する。公開直前には、親descriptorからnofollowで解決した一時名が、その検証済み実体と一致することを確認する。名前が一致するだけでは公開対象と認めない。検査とrenameの間の差替えも考慮し、直前検査だけを安全性の証明にしない。

rename後は、完成名を親descriptorからnofollowで開き直し、検証済み一時ディレクトリと同一実体であること、固定入力・manifest・本文・四枚と期待digestが一致することを再照合する。親の同期も成功した場合だけ通常実行の成功結果を採用する。公開前後の実体不一致・一式不一致・照合不能は成功にせず、衝突/照合待ちとして記録する。所有不明の置換物は、一時名・完成名のどちらにあっても自動削除・巻戻し移動・上書きをしない。

rename後の同期失敗・応答喪失はuncertainResult/照合待ちで、完成先を削除せず同IDで検証する。再照合でも検証済み実体と期待一式が一致し必要な同期を確認できた場合だけ成功へ収束する。公開成功を単なるjournal更新失敗で取り消さない。電源断や任意保存先の永続性を絶対保証しない。

Appleは[volumeSupportsExclusiveRenaming](https://developer.apple.com/documentation/foundation/urlresourcevalues/volumesupportsexclusiverenaming)を排他的rename対応の能力として示す。事前能力確認だけで成功とせず、実操作の結果を判定する。[fsyncの資料](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/fsync.2.html)は機器内部の書込とF_FULLFSYNCを区別するため、既存のファイル同期方針を維持し、未成立を成功にしない。

## D3 ローカル記録と再起動照合
記事保存と一枚検証の記録とは分離したExportJobs領域に、版付きの固定入力・固定本文・親実体・生成名・所有識別・段階・期待digestを保存する。OS排他と期待旧bytes照合付きの原子的レコード更新を使い、未知版・破損・外部変更は保護する。一つのactive記録で開始を直列化し、終端の記録をjobID別へ保管してからactiveを更新する。二つのファイルを同時確定できると仮定せず、両方残る場合は同IDを照合し、欠損/不整合なら開始を拒否する。

生成前に入力と予定一時名を記録し、一時領域を作ったら実体識別と所有receiptを記録する。所有を証明する前の異常終了物は、名前が一致するだけでは削除せず残存を案内する。完成前は所有receiptまたは検証済みmanifest/digestと記録済み実体の組合せで当該一時物だけを識別する。完成物には不要な内部receiptを残さない。receipt除去後の中断は、生成完了済みmanifestと期待digestによる照合へ進む。

起動時はローカル記録を列挙し、本文やJPEGを一括常駐させない。未完は案内し、照合時に同じ保存先を本人が再選択する。親実体、検証時に記録した出力ディレクトリの実体、jobID、所有と版、全一式のdigestを再確認する。実体識別が取得不能・再利用の疑いがある場合も、名前やdigestだけで同一と断定しない。公開済み完全一式は成功として復元できるが、外部変更/欠落/不明は自動成功にしない。完成物・別ジョブ・無関係なファイルを自動削除しない。片付け失敗の記録も残し、既知の未確定状態を新IDで盲目的に再生成しない。

## D4 権限寿命とOS操作
保存先grantはプロセス内のジョブ寿命だけ。永続bookmarkや広範囲の権限を追加しない。既存のscope取得が成功した場合だけ対応する解放を一回行い、選択パネルが与えたアクセスと追加scope取得の戻り値を混同しない。画像/実I/Oの収束前にgrantを解放しない。Finder再表示も必要なアクセス確認を経て実行し、保存先URLだけを権限の証明にしない。[AppleのSandbox資料](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)と[scope寿命](https://developer.apple.com/documentation/foundation/url/startaccessingsecurityscopedresource())を基準とする。

コピー境界は渡された文脈とplainTextだけを使い、成功/clipboardFailureを返す。OSクリップボードの他アプリによる変更や失敗時の旧内容の復元は保証せず、記事入力・dirtyを守る。Finder境界は完成結果の場所の存在とOS操作結果を確認し、削除/移動/表示失敗を出力成功から分離する。実際のnote貼付けと画像配置は本人確認のままにする。

## D5 資源・期限・取消
Deliveryの制御actorと専用の直列I/O実行部を分離する。I/OをUI/MainActor上で行わず、無応答時に新しいworkerを無制限に増やさない。一枚ごとにC2の共有予算を予約し、表示/出力を合わせ直接256MiB・プロセス増分512MiB、変換一件の条件を維持する。拒否はcapacityとして入力を保持する。

単調な絶対期限をジョブ登録時と各画像工程で発行し、画像30秒・一枚工程40秒・全体180秒を各工程の開始/結果採用/確定直前で比較する。期限後に新しい確定を始めない。取消受付は制御側で0.5秒以内の表示を目標とし、画像の論理終端2秒を維持する。確定の許可と取消は直列化し、確定呼出し開始済みなら成否が判明するまで保留し、成功なら成功結果を返す。

停止要求後は次の工程を起動せず、実I/Oと要求の収束を待ってから一時物を片付ける。OS I/Oが返らない場合は取消/照合待ちを表示し、取消完了とはしない。保留workerがある間は同じジョブの再開始や片付けとの競合を許さず、grantと必要な資源を保持する。正常ローカル保存先の片付けp95≤5秒は別に測る。片付け失敗は元原因分類も保持してcleanupFailureを返し、残存場所は本人向けにのみ示す。

## D6 画面接続と診断
activeJobIDと段階をUIへ投影し、古い進捗/終端を破棄する。対象の編集/保存/切替と重複開始だけを制御し、無関係なUIを同期I/Oで塞がない。未完の照合待ちを終端と偽らず、終端時に元操作へ焦点を戻す。コピー・Finder・保存・出力の成功表示を別にする。

全主要操作を640×560と境界幅959/960/961・1200、名称200文字/本文各10000文字、Tab/Shift+Tabで確認する。これは入力上限ではない。通常ログは段階/分類/写真番号/匿名な所要時間だけとし、私的文字を含むOS例外を無加工で出さない。ローカル回復記録とmanifestは通常ログやCIへ送らない。

## D7 実証と未確認の管理
各層のTDD、同ID反復/異入力、保存取消、四枚の対応、sync前後/rename前後/終端記録前後の障害、別volume/非対応rename、外部変更、symlink、片付け失敗を注入する。未実行をRed/Greenにしない。完成候補の全機能と全製品80%は既存正式--functional/CIで確認し、限定成功を全体に代えない。

公開対象の差替えは、検証後・公開直前照合後・rename後の各位置で障害注入する。検証した一時領域を別名へ移し、元の一時名へ別ディレクトリまたはsymlinkを置くケース、完成名の差替え、同一実体の内容改変を含める。いずれも未検証物を成功扱いせず、所有不明物・別ジョブ・旧完成物を削除/上書きしないことを確認する。正常系は同じ実体と期待一式の公開成功を確認する。これはコード生成時に実装する試験条件であり、現段階で試験済みとはしない。

性能の実測は本人Macで各要件の30試行、基準5秒以上・実サンプリング間隔50ms以下を検証する。CIは決定論的な期限/予算・契約/回復の検証を行い、実時間/実メモリの性能合否に使わない。実写真の編集/色/回転/GPS除去、Sandbox、Finder、note、OS/Xcode/署名/戻し方は別の日本語本人確認として記録する。コード計画で成立未確認を列挙し、達成済みとは扱わない。

## Assumptions & Open Questions
設計は既存のローカル正常volumeを基準とする。非対応の保存先は安全に失敗させ、移動によるURL失効やOS停止を成功と誤認しない。具体APIの可用性と障害時の成立性は実装前の計画とテストで確認する。別サーバー・アカウント・直接投稿・VoiceOver追加は導入しない。

## Requirement References
対応表の詳細IDを設計本文にも明示する。内容の正本は各D節であり、次の構成設計へ条件を欠落なく引き継ぐ。

| 要件 | 設計 |
|---|---|
| NFR1.30 | D1 画像用途と通信禁止、D7境界検査 |
| NFR1.31 | D1 JPEG設定検証、D7実写真確認 |
| NFR2.30 | D1 固定入力、D3登録と照合 |
| NFR2.31 | D2 公開前後の実体/一式照合と非置換公開、D7差替え障害注入 |
| NFR2.32 | D3 回復と所有識別 |
| NFR2.33 | D2 親descriptorと公開対象の実体照合、D4権限寿命 |
| NFR3.30 | D5 共有予算と一件変換 |
| NFR3.31 | D5 単調期限と確定許可 |
| NFR3.32 | D5 取消受付と実処理の収束 |
| NFR3.33 | D7 本人Macの30試行 |
| NFR4.30 | D6 幅とキー到達 |
| NFR4.31 | D4 OS結果、D6焦点と状態 |
| NFR5.30 | D7 層別TDDと全製品coverage/CI |
| NFR6.30 | D3 ローカル記録、D6診断 |
| NFR6.31 | D1 本文投影、D4コピー |
| NFR7.30 | D7 日本語の本人確認 |
