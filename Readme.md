# BanG-Dream Clearlamp Manager
## なにこれ
ゲームの中でミスカンとか自己べGr数とか見れないのどうなん。  
ってことで作った。

## なにができるの
* ランプ管理
* Great/Good/Bad/Missカウントの保存
* コメント保存

## URL
[https://arika0093.github.io/BanGDreamClearManager](https://arika0093.github.io/BanGDreamClearManager)

## 注意点
* データの保存にlocalStorageを使用しているため別端末での共有とかは現状できません。
* スマホで使うと大変なことになると思うので大人しくPCで使ってください。共有もできないし。

## データのexport方法
console開いて```localStorage.getItem("savedScore")```  
importも同様の要領でできます。

## todo
* データ共有(というかログイン機能)
	* github pageが使えなくなるので面倒なのが難点
	* DBも用意しないといけないし…

## 開発関連
Jade + SCSS + Riot.  
Riotお試しで作ったので普通にbad practiceがあるけど気にしない。  
ファイルは多くありますが、殆ど```client/riot/main.tag```に書いてあります。

## Special Thanks
曲データは[こちら](https://bangdream.blog.so-net.ne.jp/)からいただきました。  
ありがとうございます。
