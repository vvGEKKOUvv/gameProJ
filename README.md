# まどろみの庭 / The Garden Between Dreams

森のベッドで目覚める、三人称視点のドリームコア探索ゲームです。ミントグリーン、淡いピンク、クリーム色の古い遊園地と、苔や花に囲まれた森を組み合わせたオリジナルのローポリゴン試作品です。

## 起動

Godot 4 の通常版で `project.godot` をインポートし、F5 で実行します。Godot 4.6.3 で検証しています。

```sh
godot --path .
```

最初はうさぎが森のベッドに横たわっています。E / Enter で起き上がると、キャラクターの少し後ろ・右側からの視点で探索できます。

## 操作

| キー | 操作 |
| --- | --- |
| WASD / 矢印 | 移動 |
| マウス | 周囲を見回す |
| E / Enter | 照準を合わせた近くの物を調べる・会話を閉じる |
| Esc | 会話を閉じる／探索中はマウスを解除 |
| 左クリック | マウスを再捕捉 |
| M | 音の切替 |
| R | エンディング後に最初から再開 |

ベッド脇の手紙を読み、森に置き去りにされた電話、苔の鏡、ティーカップのオルゴールを調べて、帰りの鍵を見つけます。画面右上に次の目的が表示されます。カメラは障害物に近づくと手前に寄ります。

## 検証

```sh
godot --headless --path . --script res://tests/smoke.gd
```

50項目で、ベッドでの目覚め、三人称への切替、手がかりの順序、対象への照準、鍵と扉、再開、移動・衝突、カメラ、UI を確認します。描画やOSのマウス捕捉は別途グラフィカル環境で確認します。

クラウドでホームに書き込めない場合:

```sh
mkdir -p /workspace/.runtime/{data,config,cache}
export XDG_DATA_HOME=/workspace/.runtime/data
export XDG_CONFIG_HOME=/workspace/.runtime/config
export XDG_CACHE_HOME=/workspace/.runtime/cache
godot --headless --path . --script res://tests/smoke.gd
```

## 画面

![森のベッドで目覚める](docs/dream-waking.png)

![三人称で森を探索](docs/dream-forest.png)

![忘れられたティーカップ遊具](docs/dream-pavilion.png)

## 素材

モデル、花柄、苔のテクスチャ、音はコードで生成しています。参考写真や他作品の素材は含みません。Godot プロジェクト形式の配布で、単独実行ファイルは含みません。
