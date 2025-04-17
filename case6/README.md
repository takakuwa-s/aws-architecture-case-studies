# 異なるVPC上のEC2・ECS・EKSにおける分散トレーシングアーキテクチャ構築

## 概要

異なるVPC上に構築されたEC2、ECS、EKSを接続し、CloudWatch LogsとAWS X-Rayを使用してサービス間の通信を可視化・追跡できる分散マイクロサービスアーキテクチャを構築する。
また、以下の3種類のVPC間通信方式を**個別に有効/無効を切り替えながら**試せる構成とし、それぞれの方式によるネットワークトラフィックとトレーシングの違いも観察する

- **AWS Transit Gateway**
- **VPC Peering**
- **AWS PrivateLink**

どの通信方式を使うかは、Terraformの変数で切り替え可能にする。

---

## アーキテクチャ図
![Diagram](./aws_architecture.svg)

---

## 構成コンポーネント

### VPC構成

- **VPC A**：ECSクラスター用VPC
- **VPC B**：EKSクラスター用VPC
- **VPC C**：EC2用VPC

### サービス

- **Amazon ECS**（Fargate使用）：サービスA（例：フロントエンド/バックエンドAPI）をホスト
- **Amazon EKS**：サービスB（例：非同期処理や分析処理）をPodで実行
- **Amazon EC2**：サービスCをEC2で実行
- **AWS Transit Gateway**（任意）：VPC A と VPC B を接続
- **VPC Peering**（任意）：VPC A と VPC B 間のピア接続を提供
- **AWS PrivateLink**（任意）：VPC A ⇔ VPC B（PrivateLink）経由の接続を提供
- **Amazon CloudWatch Logs**：ECS/EKSからのログを収集
- **AWS X-Ray**：ECS/EKS間のリクエストをトレーシング

---

## ロギングとトレーシング

- **ECS**：FireLensを使用してCloudWatchにログ送信。X-Rayはサイドカーでトレース
- **EKS**：Fluent Bit DaemonSetでログ収集。X-RayはSDKとDaemonSetで連携

---

## Terraform モジュール構成

```
/terraform
├── vpc-a-ecs
├── vpc-b-eks
├── ecs
├── eks
├── privatelink
├── peering
├── transit-gateway
├── logging
├── iam
├── shared
└── variables.tf      <- 各接続方式の有効/無効を切り替える変数を定義
```

それぞれのモジュールは責務ごとに分かれており、`terraform_remote_state` を使って依存関係を連携します。接続方式（Transit Gateway / Peering / PrivateLink）は、変数（例：`enable_tgw = true`）で個別に有効/無効を切り替える設計とします。

---

## デプロイ手順

1. Terraformのバックエンド（S3 + DynamoDB）を構成
2. 以下の順でモジュールを適用：
   - `vpc-a-ecs`, `vpc-b-eks`, `vpc-c-privatelink`
   - `iam`
   - 通信方式に応じて `transit-gateway`, `peering`, `privatelink` を選択的に適用
   - `ecs`, `eks`
   - `logging`
3. 各通信パターンでECS⇔EKS通信を確認（Transit Gateway / Peering / PrivateLink）
4. CloudWatchやX-Rayにログ・トレースデータが表示されることを確認

---

## 考慮事項

- X-RayとCloudWatchにアクセスするIAMロールを正しく設定
- EKSではIRSA（IAM Roles for Service Accounts）を利用して最小権限アクセスを実現
- セキュリティグループとNACLで通信制御を厳格に
- ネットワークの可視化のためにVPC Flow Logsを有効化
- PrivateLinkはクライアントVPC⇔サービスVPC間の方向性制御に留意

---

## 今後の拡張案

- CI/CDパイプライン（CodePipeline + CodeBuild）の追加
- CloudWatch Insightsによる構造化ログの分析
- マルチリージョン災害対策構成への拡張
- 通信方式ごとのパフォーマンス比較レポート作成

