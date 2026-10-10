# かえりの鍵 / The Borrowed Room

Godot 4 で動く、約 2～5 分の短編オリジナルホラーゲームです。借りた部屋を調べ、帰るための鍵を探してください。部屋の 3D モデルと音はゲーム内で生成し、外部アセットを使用していません。

現在は Godot プロジェクトとして配布するプロトタイプです。実行ファイルは同梱していません。

## 起動

Godot 4 でこのフォルダーを開いて実行します。動作確認には Godot 4.6.3 を使用しています。コマンドラインからは次のように起動できます。

```sh
godot --path .
```

## 操作

| キー | 操作 |
| --- | --- |
| WASD / 矢印キー | 移動 |
| E / Enter | 調べる・決定する |
| Esc | 表示中のメッセージを閉じる |
| M | 音のオン・オフ |
| R | エンディング後に最初からやり直す |

部屋の中を歩き、気になるものに近づいて調べてください。調べた内容が、次に進むための手がかりになります。

## 動作確認

ヘッドレスのスモークテストでは、手がかりの順序、扉の施錠、エンディング、再開、移動を確認できます。

```sh
godot --headless --path . --script res://tests/smoke.gd
```

クラウド環境などでホームディレクトリーに書き込めない場合は、作業領域内に Godot の実行時ディレクトリーを指定します。

```sh
mkdir -p /workspace/.runtime/{data,config,cache}
XDG_DATA_HOME=/workspace/.runtime/data \
XDG_CONFIG_HOME=/workspace/.runtime/config \
XDG_CACHE_HOME=/workspace/.runtime/cache \
godot --headless --path . --script res://tests/smoke.gd
```

ゲームの起動時も同じ 3 つの `XDG_*_HOME` 指定を `godot --path .` の前に付けてください。
