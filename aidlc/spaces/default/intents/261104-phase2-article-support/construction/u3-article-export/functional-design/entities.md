# U3 出力の値と所有

## Sources
inception/domain-design/components.md、contract-design/contract-summary.md C2/C3、requirements-analysis/requirements.md FR12〜18。記事正本はArticleWorkspace、編集状態はArticlePresentationの所有を維持する。

## Entity Model
```yaml
entities:
  - name: SavedExportInput
    description: 成功した保存結果と出力設定の固定コピー。ArticleDeliveryがジョブの入力として保持する。
    attributes:
      - {name: projectID, type: opaque_identifier, required: true, references: ArticleProject}
      - {name: savedRevision, type: nonnegative_integer, required: true}
      - {name: selectionRevision, type: nonnegative_integer, required: true}
      - {name: source, type: source_snapshot, required: true}
      - {name: content, type: article_content, required: true}
      - {name: fingerprint, type: deterministic_digest, required: true}
      - {name: settings, type: image_settings, required: true, default: sRGB_JPEG_quality0.9_longEdge2560_noUpscale}
    constraints: [保存成功結果のみ, 四つの異なる写真IDと本文の順序一致, 作成後不変, 正本への書戻しなし]
    relationships:
      - {target: ExportJob, cardinality: one_to_many, direction: input_to_jobs}
  - name: ExportJob
    description: ArticleDeliveryが所有する一回の出力。再出力は別ID。
    attributes:
      - {name: jobID, type: opaque_identifier, required: true, unique: true}
      - {name: inputSnapshot, type: SavedExportInput, required: true}
      - {name: rendered, type: rendered_article, required: true}
      - {name: destinationGrantID, type: opaque_identifier, required: true}
      - {name: state, type: enum, required: true, allowed: [preparing, acquiring, writing, validating, committing, succeeded, cancelled, failed, cleanupFailed, needsReconciliation]}
      - {name: completedImages, type: integer, required: true, default: 0, min: 0, max: 4}
      - {name: activeRequestID, type: optional_identifier, required: false}
      - {name: failure, type: optional_classified_failure, required: false}
    constraints: [同一IDの同時実行禁止, 単一終端, 同一ID異入力拒否, 記事本文と設定の変更禁止]
    relationships:
      - {target: ExportManifest, cardinality: one_to_zero_or_one, direction: job_to_manifest}
      - {target: OutputLocation, cardinality: one_to_one, direction: job_to_location}
      - {target: RecoveryRecord, cardinality: one_to_one, direction: job_to_record}
  - name: ExportManifest
    description: ArticleDeliveryが成果物内に出すローカル管理情報。
    attributes:
      - {name: manifestID, type: opaque_identifier, required: true, unique: true}
      - {name: schemaVersion, type: integer, required: true, allowed: [1]}
      - {name: jobID, type: opaque_identifier, required: true, references: ExportJob}
      - {name: projectID, type: opaque_identifier, required: true, references: ArticleProject}
      - {name: sourceSelectionID, type: opaque_identifier, required: true}
      - {name: selectionRevision, type: nonnegative_integer, required: true}
      - {name: savedRevision, type: nonnegative_integer, required: true}
      - {name: inputFingerprint, type: deterministic_digest, required: true}
      - {name: orderedAssetIDs, type: ordered_identifier_collection, required: true, constraints: exactly_four_distinct}
      - {name: relativeImagePaths, type: ordered_relative_path_collection, required: true, allowed: [images/01.jpg, images/02.jpg, images/03.jpg, images/04.jpg]}
      - {name: articleRelativePath, type: relative_path, required: true, allowed: [article.md]}
      - {name: createdAt, type: instant_with_offset, required: true}
    constraints: [固定入力と識別情報一致, 相対参照と実ファイルの一致, 本文コピーと外部送信の対象外]
    relationships: []
  - name: OutputLocation
    description: 一時物と完成物の別の位置。ArticleDeliveryがアクセス寿命を管理する。
    attributes:
      - {name: grantID, type: opaque_identifier, required: true}
      - {name: selectedParentIdentity, type: local_directory_identity, required: true}
      - {name: stagingIdentity, type: job_owned_directory_identity, required: true}
      - {name: finalName, type: generated_safe_name, required: true, unique: true}
      - {name: finalDirectory, type: optional_local_directory, required: false}
    constraints: [利用者選択の範囲内, 同じ親内で確定, 既存完成物を置換しない, 外部IDと記事名をパス化しない]
    relationships: []
  - name: RecoveryRecord
    description: 同じジョブの結果照合と当該一時物の識別に使うローカル記録。記事の別正本ではない。
    attributes:
      - {name: jobID, type: opaque_identifier, required: true, unique: true, references: ExportJob}
      - {name: immutableInput, type: SavedExportInput, required: true}
      - {name: fixedPlainText, type: string, required: true}
      - {name: ownershipToken, type: generated_opaque_token, required: true}
      - {name: outputIdentities, type: OutputLocation, required: true}
      - {name: phase, type: enum, required: true, allowed: [prepared, generating, publishing, completed, incomplete, cleanupFailed]}
      - {name: expectedArtifactDigests, type: path_digest_collection, required: false}
    constraints: [本文等はローカル限定で通常ログへ出さない, 外部変更や未知版は回復を停止, 再起動後の保存先アクセス権を仮定しない]
    relationships: []
```

## Summary
固定入力から複数回出力できるが、各回は別ジョブ・別フォルダ。ジョブ・manifest・回復記録は同じjobIDで結ぶ。完成物の表示位置は移動・削除で利用不能になり得るため、成功の記録とFinder表示成功を別に保持する。画像の要求とバッファはArticleImagesが所有し、一枚ずつ利用後に解放する。
