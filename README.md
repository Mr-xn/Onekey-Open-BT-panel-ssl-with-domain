# Onekey-Open-BT-panel-ssl-with-domain
宝塔(bt.cn)面板开启域名登录并且使用域名证书,解决浏览器信任证书问题,强迫症福音@_@

### 注意：
#### 目前使用此shell需要你在宝塔后台面板里面建一个需要绑定到面板的域名网站，最好申请Let's SSL证书，当然，shell也支持自定义证书路径。
#### 只测试了建立网站后的，没有测试过不用建立网站，直接解析域名到服务器（这种未来会支持的，使用 [acme.sh](https://github.com/Neilpang/acme.sh) 来申请SSL证书或者是自定义证书都可以）

###### 推荐一个可以检查shell语法的网站,超级好用.也可以安装到自己的机器上:  [shellcheck](https://www.shellcheck.net/)

![pic](https://raw.githubusercontent.com/Mr-xn/Onekey-Open-BT-panel-ssl-with-domain/shotpic_2018-08-22_12-54-16.png)