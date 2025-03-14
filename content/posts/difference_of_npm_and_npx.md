---
title: "npxとは？（npmとの違い）"
date: 2025-03-15
draft: false
categories:
  - プログラミング
tags:
  - プログラミング
cover:
  image:
  alt: "cover image"
---

## npm & npxとは
npm (Node Package Manager)はNode.jsをinstallした際に付属でインストールするパッケージマネージャ
npxは、npmに付属するコマンドラインツール

## npxの使用例
```sh
npx create-react-app my-app
npm tsc
```

## npmではなくnpxを使うメリット:
- 時的な実行が可能
- グローバルインストールが不要
- ディスク容量の節約
- 常に最新バージョンを使用可能


## npxのパスの解決
node_modules/.binのパスを自動で解決
package.jsonのscriptsブロックの外でも実行可能

## npxのバージョン管理
異なるバージョンのツールを実行可能
```sh
npx typescript@4.8.0 tsc
npx typescript@latest tsc
```

## npxの探索順序
1. カレントプロジェクトのnode_modules/.binディレクトリ
  - プロジェクトにローカルインストールされたパッケージを最初に探索
```
   プロジェクト/
   ├── node_modules/
   │   └── .bin/  <- ここを最初に確認
   └── package.json
```
2. 親ディレクトリのnode_modules/.bin
  - カレントディレクトリに見つからない場合、親ディレクトリを順に探索
```
   親ディレクトリ/
   ├── node_modules/
   │   └── .bin/  <- 次にここを確認
   └── プロジェクト/
       └── package.json
```
3. グローバルのnode_modules
- システムにグローバルインストールされたパッケージを探索
- グローバルインストールされたパッケージ探索で便利なコマンド
```sh
npm root -g --depth=0
npm list -g
npm list -g | grep パッケージ名
```

## 実際の例
```sh
npm install --save-dev typescript
tree node_modules/.bin/
node_modules/.bin/
├── tsc -> ../typescript/bin/tsc
```
tscの中身
```js
#!/usr/bin/env node
require('../lib/tsc.js')
```
npxでtscを実行。tscconfig.jsonが作成される。
```sh
npx tsc --init
```
