# Libvirt Container 再実装プラン

## Context

Libvirt-container は、開発用途の使い捨て仮想化基盤を Docker コンテナとして提供するプロジェクト。旧実装（CentOS 7 + supervisord + BATS）をゼロから再実装する。新仕様では Debian 13 + SystemD + Ansible/Molecule に刷新される。

成果物はアプリケーションではなく IaC 構築支援ツールであり、ソースコードだけでは挙動を予測しきれないため、各フェーズで実際に動作確認しながら進める。コミットはフェーズ単位。

### Libvirt デーモン構成

実装時の調査により、Debian 13 の `libvirt-daemon` パッケージはモノリシックな `libvirtd` を提供していることが判明した（モジュラーデーモン `virtqemud` 等は別パッケージ）。

- `libvirtd.socket` による Socket Activation 方式で動作
- `libvirtd.service` は socket 経由でオンデマンド起動される
- polkit 無効化は `/etc/libvirt/libvirtd.conf` に `access_drivers = [ "none" ]` を設定
- ボリュームマウント (`/etc/libvirt`) のため、Dockerfile ではなくエントリポイントスクリプトで設定する必要がある

## Phase 1: コンテナ基盤（Dockerfile + docker-compose.yml + Makefile）

**目標**: SystemD が PID 1 として起動するコンテナを構築・起動できる

### 作成ファイル
- `Dockerfile` — Debian 13 ベース、パッケージインストール、SystemD エントリポイント
- `docker-compose.yml` — 仕様通りのサービス定義
- `Makefile` — build / up / down / exec / clean / test / all ターゲット
- `.dockerignore`

### Dockerfile 設計
- `FROM debian:trixie`
- パッケージ: libvirt-daemon-system, qemu-system-x86, openssh-server, sudo, virt-install, libvirt-clients, qemu-utils, curl, genisoimage
- `COPY docker-entrypoint.sh` + `COPY docker-entrypoint.d/`
- `STOPSIGNAL SIGRTMIN+3` (SystemD graceful shutdown)
- `ENTRYPOINT ["/docker-entrypoint.sh"]`

### docker-compose.yml
- 仕様書の定義をそのまま使用
- `SSH_PORT` 変数でポート設定可能（デフォルト 2222）

### Makefile
- `SSH_AUTHORIZED_KEYS` は `~/.ssh/id_rsa.pub` をデフォルトで読み込む
- `exec` は `docker compose exec` でアプリケーションユーザーのシェルを開く

### 動作確認
- `make build` → イメージビルド成功
- `make up` → コンテナ起動、`systemctl` が応答する
- `virsh --connect=qemu:///system list` で接続テスト（Socket Activation トリガー）
- `make down` / `make exec` が動作する

## Phase 2: 初期化スクリプト（エントリポイント方式）

**目標**: コンテナ起動時にユーザー作成・SSH 設定が自動で行われ、その後 SystemD に引き継がれる

### 設計方針
旧実装や Docker 公式 NGINX コンテナと同様のエントリポイント方式を採用する。
- `docker-entrypoint.sh` が `/docker-entrypoint.d/` 内のスクリプトを名前順に実行
- 全スクリプト実行後に `exec /sbin/init` で SystemD に制御を引き渡す
- スクリプトの実行順序はファイル名の番号プレフィックスで明示（見通しが良い）
- カスタマイズ時はスクリプトファイルの追加・削除だけで対応可能

### 作成ファイル

| ファイル | 内容 |
|---|---|
| `docker-entrypoint.sh` | `/docker-entrypoint.d/*.sh` を名前順に実行後、`exec /sbin/init` |
| `docker-entrypoint.d/05-libvirt-polkit.sh` | polkit 無効化（ボリューム対応） |
| `docker-entrypoint.d/10-ssh-hostkeys.sh` | `ssh-keygen -A` |
| `docker-entrypoint.d/20-healthcheck-user.sh` | healthcheck ユーザー作成、SSH 鍵生成、libvirt URI 設定 |
| `docker-entrypoint.d/30-libvirt-user.sh` | アプリケーションユーザー作成（env: LIBVIRT_USER, UID, GID） |
| `docker-entrypoint.d/40-libvirt-user-password.sh` | パスワード設定（LIBVIRT_USER_PASSWORD が設定されている場合のみ） |
| `docker-entrypoint.d/50-libvirt-user-sudo.sh` | passwordless sudo 設定 |
| `docker-entrypoint.d/60-libvirt-user-ssh.sh` | authorized_keys 設定（SSH_AUTHORIZED_KEYS が設定されている場合のみ） |

### 動作確認
- `make up` + `make exec` でコンテナに入り:
  - `id healthcheck` / `id libvirt-user` → ユーザー存在確認
  - `systemctl status sshd` → SSH 起動済み
  - `virsh --connect=qemu:///system list` → libvirt 接続成功（Socket Activation 経由）

## Phase 3: ヘルスチェック + SSH アクセス

**目標**: ヘルスチェック healthy、外部から SSH 接続可能

### 追加内容
- Dockerfile に `HEALTHCHECK CMD su healthcheck -c 'virsh connect'`
- 環境変数 `LIBVIRT_USER_PASSWORD` 設定時にパスワードログイン動作確認

### 動作確認
- `docker inspect` で healthy 確認
- `ssh -p 2222 libvirt-user@127.0.0.1` でログイン成功
- `virsh --connect=qemu+ssh://libvirt-user@127.0.0.1:2222/system list` 成功

## Phase 4: Molecule テスト基盤

**目標**: テストランナーから libvirt コンテナに対して E2E テストを実行する基盤

### 構成方針
- **別途 docker-compose でテスト環境を構築** し、Molecule はテスト実行のみ担当
- libvirt コンテナ（SUT）とテストランナーコンテナの2台構成
- テストランナー: Ansible, Molecule, SSH ツール, libvirt-clients 入り
- Molecule の default ドライバ (unmanaged) を使用

### 作成ファイル
- `molecule/default/molecule.yml`
- `molecule/default/converge.yml`
- `molecule/default/verify.yml`
- `molecule/default/docker-compose.yml` — テスト用 Compose（libvirt + test-runner）
- `molecule/default/Dockerfile` — テストランナーコンテナ

### 動作確認
- `make test` → Molecule 起動、最低限の SSH 接続テスト通過

## Phase 5: E2E テストシナリオ実装

**目標**: 仕様書 (docs/test-spec.md) の全テストシナリオが自動実行される

### 5-1. SSH Connectivity
- SSH ポート到達待ち（30秒）、パスワード認証、公開鍵登録、公開鍵認証

### 5-2. Libvirt Connectivity
- `virsh connect` 成功

### 5-3. Disk Image Management
- Debian 13 クラウドイメージダウンロード、バッキングイメージ作成、cloud-init ISO 作成

### 5-4. Network Management
- NAT ネットワーク定義、autostart 有効化、起動

### 5-5. VM Domain Management
- ドメイン定義（512MB, 1vCPU, 2NIC）、autostart、起動（300秒）、guest VM に SSH

### 実装時の知見

- **マシンタイプ**: `--os-variant=debian12` は Q35 マシンタイプを選択するが、Debian 13 cloud image のカーネルブートに失敗する。`--os-variant=generic --machine=pc` (i440fx) で解決。
- **cloud-init ISO**: `genisoimage -volid cidata -joliet -rock` でファイル名が正しく保持される。
- **guest SSH 待ち時間**: cloud-init の初期化に約50秒かかるため、適切なリトライ設定が必要。

### 動作確認
- `make test` で全シナリオ通過

## ファイル構成（最終形）

```
.
├── .dockerignore
├── Dockerfile
├── Makefile
├── docker-compose.yml
├── docs/
│   ├── architecture.md
│   ├── container-spec.md
│   ├── implementation-plan.md
│   └── test-spec.md
├── docker-entrypoint.sh
├── docker-entrypoint.d/
│   ├── 05-libvirt-polkit.sh
│   ├── 10-ssh-hostkeys.sh
│   ├── 20-healthcheck-user.sh
│   ├── 30-libvirt-user.sh
│   ├── 40-libvirt-user-password.sh
│   ├── 50-libvirt-user-sudo.sh
│   └── 60-libvirt-user-ssh.sh
└── molecule/default/
    ├── molecule.yml
    ├── docker-compose.yml
    ├── Dockerfile
    ├── converge.yml
    └── verify.yml
```
