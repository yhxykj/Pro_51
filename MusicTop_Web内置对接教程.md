# MusicTop Web 内置对接教程

这份教程说明如何把当前 `TavoniFlowCenter` 这一套 Web 数据能力接到一个 iOS App 里。目标是让接入方不依赖外部 SDK、不复制生成库，直接把 Swift 代码放进宿主 App 工程，并在 App 启动后接管启动、登录、WebView、推送、内购和事件上报流程。

本文按当前工程实现编写，核心代码目录是：

```text
SKMusic/AppWebRuntime/
```

## 对接前必读：哪些必须换，哪些不能改

接新包时先看这一段。不要一边改一边猜，最容易出错的就是把“可混淆命名”和“后端 / H5 固定协议字段”搞反。

### A. 可以改，而且每个包必须改

```text
1. Swift 自定义类型名
   自己写的 class / struct / enum 名都可以改，而且每个包必须改。
   例如 TavoniRouteConfig、TavoniFlowCenter、TavoniPostClient、TavoniCanvasController。

2. Swift 自定义方法名
   自己写的 func 名都可以改，而且每个包必须改。
   例如 ignite、beginTapSignin、requestAuroraProbe、showBoundCanvas。

3. Swift 自定义常量名 / 变量名 / 属性名
   自己写的 let / var / static let 都可以改，而且每个包必须改。
   例如 clientMark、cipherSeed、routeMap、coverWindow、entryPortal、sessionTokenSlot。

4. 文件名
   文件名跟主类型名建议一起改。
   例如 TavoniRouteConfig.swift、TavoniFlowCenter.swift。

5. 接口属性名
   RouteMap 里的属性名可以改，而且每个包必须改。
   例如 auroraProbe、tapSigninRoute、storeReceiptGate、canvasTiming。

6. 接口路径里的可变段
   例如 opi/v1/lqravme/qavrno 中间的 lqravme 可以改，而且每个包必须改。
   最后的业务后缀字母要保留，例如 qavrno 最后的 o 保留。

7. 接口参数 key 的前缀
   例如 qavrnt 可以改成任意字母 + t。
   qavrn 这段前缀要换，最后一个业务字母 t 不能换。

8. 本地存储 key
   例如 qavrntk、qavrndk、qavrndev、qavrn_push 可以改，而且建议每个包必须改。
   改完后读写同一个值的地方必须用同一个 key。

9. 自定义 header
   firstHeaderName / firstHeaderValue 这类属于当前包自己加的字段。
   可以改名、改值、增减，但 TavoniPostClient 里读取的调用点要同步。

10. 业务值
   AppId、AES Key、AES IV、图片名、Adjust token、API Base URL 都按当前包实际配置填写。
```

### B. 不能改，除非后端 / H5 / Apple 系统一起改

```text
1. HTTP 固定 header 字段名
   Content-Type
   Accept
   deviceNo
   pushToken
   appVersion
   appId
   loginToken

2. H5 / Native Bridge 名称
   Close
   rechargePay
   openBrowser
   handleSkipStore

3. H5 传给 Native 的字段
   batchNo
   orderCode
   url

4. Native 回调 H5 的事件和字段
   nativeOpenState
   state
   success
   failed

5. 后端响应字段
   result
   loginFlag
   openValue
   locationFlag
   token
   password

6. Web URL 参数名
   openParams
   appId

7. StoreKit / Apple 系统 API 名称和方法签名
   UIApplication、WKWebView、SKPaymentQueue、URLSession、productsRequest、paymentQueue。
   这些不是自己定义的命名，不能为了混淆乱改。

8. 加密规则
   AES-128-CBC、PKCS7Padding、小写 hex、result 加密响应结构不能改。

9. 统计约定字段
   ta_distinct_id、Purchase、USD 一般不要改。
   除非统计后台、Adjust / Facebook 配置一起确认要改。
```

重点区分：

```text
Swift 属性名 clientMark
  可以每个包换名。

HTTP header 里的 appId
  不能改，它是后端协议字段。

Web URL query 里的 appId
  不能改，它是 H5 / 后端协议字段。
```

容易搞错的例子：

```text
clientMark
  Swift 属性名，可以改。

"appId"
  HTTP header 字段名 / Web URL 参数名，不能改。

orderMarkText
  Swift 变量名，可以改。

"orderCode"
  H5 入参字段 / receipt 参数 JSON 字段，不能改。

sessionToken
  Swift 属性名，可以改。

"token"
  后端响应字段 / openParams 明文字段，不能改。

coverWindow
  Swift 变量名，可以改。

UIWindow
  Apple 系统类型名，不能改。
```

## 1. 对接目标

接入完成后，App 会具备这些能力：

```text
App 启动后显示启动覆盖层
等待系统网络可用后请求启动接口
根据 loginFlag / openValue / locationFlag 决定显示登录页、进入 Web 页或关闭覆盖层
登录页支持一键登录接口
统一加密 POST 请求
统一请求头
保存 pushToken、deviceId、loginToken、password
WKWebView 支持 JS Bridge
支持 H5 触发 StoreKit 内购
内购成功后提交 receipt 给后端校验
receipt 校验成功后才 finishTransaction
支持外部浏览器 / 第三方 App 跳转，并回调 H5
支持 Web 页面加载耗时上报
Web 内容放进 secure textfield 容器，按参考实现处理截屏保护
```

## 2. 文件清单

把下面文件加入宿主 App 工程，建议保持同一个目录，方便维护：

```text
AppWebRuntime/
  TavoniRouteConfig.swift
  TavoniFlowCenter.swift
  TavoniPostClient.swift
  TavoniCipherBox.swift
  TavoniLocalVault.swift
  TavoniCanvasController.swift
  TavoniOrderBridge.swift
  TavoniSignalBridges.swift
  TavoniWaitHUD.swift
  TavoniShieldView.swift
```

每个文件职责如下：

```text
TavoniRouteConfig.swift
  保存业务参数、接口路径、自定义请求头、本地存储 key。

TavoniFlowCenter.swift
  启动入口和主流程控制，包括启动覆盖层、网络等待、启动接口、登录接口、Web 跳转、推送授权。

TavoniPostClient.swift
  统一网络请求封装，负责请求头、AES 加密 body、解密响应 result。

TavoniCipherBox.swift
  AES-128-CBC-PKCS7 加密解密，输出小写 hex。

TavoniLocalVault.swift
  Keychain / UserDefaults 存储，设备号、token、pushToken、网络环境辅助方法。

TavoniCanvasController.swift
  安全 Web 容器，WKWebView，JS Bridge，URL scheme 拦截，页面耗时上报。

TavoniOrderBridge.swift
  StoreKit 商品查询、支付监听、receipt 读取、后端校验、finishTransaction。

TavoniSignalBridges.swift
  Adjust / Facebook 事件出口，以及后端 Purchase 事件上报。

TavoniWaitHUD.swift
  loading 和 toast。

TavoniShieldView.swift
  secure textfield 截屏保护容器。
```

### 2.1 Swift 自定义命名规则

当前工程里的 `Tavoni` 前缀、各类 `let / var / func / class / struct / enum` 名称，都只是当前包示例。接新包时，自己定义的命名不要继续照抄同一套。

必须按包更换的 Swift 自定义命名包括：

```text
文件里的主类型名
  例如 TavoniRouteConfig、TavoniFlowCenter、TavoniPostClient。

自己定义的常量名
  例如 clientMark、cipherSeed、cipherVector、auroraProbe、tapSigninRoute、storeReceiptGate。

自己定义的变量名
  例如 entryPortal、coverWindow、runningOrderCode、runningProductID。

自己定义的 static 属性名
  例如 activeConfig、routeMap、coverHeaders、sessionTokenSlot、deviceStampSlot。

自己定义的方法名
  例如 beginTapSignin、requestAuroraProbe、submitTapSignin、showBoundCanvas。

自己定义的辅助类型名
  例如 TavoniLocalVault、TavoniDeviceProbe、TavoniJSONCodec。
```

更换要求：

```text
同一个包内调用点必须全部同步改。
每个包不要复用上一包的自定义命名。
业务含义必须靠注释保留，防止换名后开发搞混字段。
建议文件名跟主类型名一起换，方便维护。
```

不能为了混淆去改的系统命名：

```text
Apple 框架类型名
  UIApplication、UIWindow、WKWebView、SKPaymentQueue、URLSession。

Apple 协议方法签名
  application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
  scene(_:willConnectTo:options:)
  webView(_:didFinish:)
  userContentController(_:didReceive:)
  paymentQueue(_:updatedTransactions:)

H5 / 后端协议字段
  这些在后面的固定字段清单里单独列出。
```

## 3. 配置参数

配置写在 `TavoniRouteConfig.swift`，当前实现是直接写 Swift 常量，不走 `Info.plist`。

当前公共参数。下面只是当前包的示例属性名和示例值：

```swift
let clientMark = "11111111" // AppId
let cipherSeed = "9986sdff5s4f1123" // Key
let cipherVector = "9986sdff5s4y456a" // IV
let splashAsset = "launch_background" // Launch image
let signinAsset = "HNSo7SkaMAE19-e" // Login image
let traceSwitch = true // Debug
let adjustBundleToken = "z1qr64z7alts" // Adjust app token
let adjustFirstSignal = "w69fw8" // Adjust install event token
let adjustPaidSignal = "vmuilr" // Adjust purchase event token

let gatewayRoot = "https://opi.cphub.link" // API base URL
```

重要：

```text
clientMark、cipherSeed、cipherVector、splashAsset、signinAsset、traceSwitch、
adjustBundleToken、adjustFirstSignal、adjustPaidSignal、gatewayRoot
这些 Swift 属性名每个包也要改。

不要所有 App 都保留同一套公共配置命名，防止代码结构关联。
```

接入新 App 时，需要同时替换：

```text
1. 属性名
2. 属性值
3. 所有读取这些属性的调用点
```

例如不要每次都写：

```swift
let clientMark = "11111111" // AppId
let cipherSeed = "9986sdff5s4f1123" // Key
let cipherVector = "9986sdff5s4y456a" // IV
let splashAsset = "launch_background" // Launch image
let signinAsset = "HNSo7SkaMAE19-e" // Login image
let traceSwitch = true // Debug
let adjustBundleToken = "z1qr64z7alts" // Adjust app token
let adjustFirstSignal = "w69fw8" // Adjust install event token
let adjustPaidSignal = "vmuilr" // Adjust purchase event token
let gatewayRoot = "https://opi.cphub.link" // API base URL
```

新包可以改成该包自己的命名：

```swift
let rhythmClientCode = "11111111" // AppId
let rhythmCipherSeed = "9986sdff5s4f1123" // Key
let rhythmCipherVector = "9986sdff5s4y456a" // IV
let rhythmLaunchAsset = "launch_background" // Launch image
let rhythmLoginAsset = "HNSo7SkaMAE19-e" // Login image
let rhythmTraceEnabled = false // Debug
let rhythmAttributionApp = "z1qr64z7alts" // Adjust app token
let rhythmInstallSignal = "w69fw8" // Adjust install event token
let rhythmPurchaseSignal = "vmuilr" // Adjust purchase event token
let rhythmGatewayURL = "https://opi.cphub.link" // API base URL
```

同时调用点也要同步改，例如：

```swift
request.setValue(routeConfig.rhythmClientCode, forHTTPHeaderField: "appId")
let encryptedText = try? TavoniCipherBox.encryptHexText(payloadText, routeConfig: routeConfig)
let controller = TavoniSigninPanelController(assetName: routeConfig.rhythmLoginAsset)
```

注意区分：

```text
Swift 属性名 clientMark 要每个包改。
HTTP header 字段 appId 不能改，它是后端协议字段。
Web URL 参数 appId 不能改，它是 H5 / 后端协议字段。
```

注意：

```text
AES key 和 AES IV 对应的值必须都是 16 位 UTF-8 字符串。
API base URL 当前完整写死为 https://opi.cphub.link。
启动图和登录图对应的值必须能在 Assets.xcassets 中找到。
debug 开关上线前建议改成 false。
```

## 4. 接口路径

接口路径集中在 `TavoniRouteConfig.RouteMap`。下面只是当前包的示例命名和示例路径：

```swift
let auroraProbe = "opi/v1/lqravme/qavrno"
let tapSigninRoute = "opi/v1/novqale/qavrnl"
let storeReceiptGate = "opi/v1/vemquar/qavrnp"
let checkoutPulse = "opi/v1/qalmire/qavrnj"
let canvasTiming = "opi/v1/renqiva/qavrnt"
```

重要：

```text
auroraProbe、tapSigninRoute、storeReceiptGate、checkoutPulse、canvasTiming 这些属性名也要每个包都改。
不要所有 App 都保留同一套公共命名，防止代码结构关联。
```

例如启动接口不要每次都写：

```swift
let auroraProbe = "opi/v1/lqravme/qavrno"
```

新包可以改成该包自己的命名：

```swift
let musicEntryCheck = "opi/v1/abcd/qwero"
```

改属性名后，所有调用点也要同步改：

```swift
TavoniRouteConfig.routeMap.musicEntryCheck
```

路径本身也不是固定字符串，而是固定模板：

```text
opi/v1/****/****o
```

规则：

```text
opi/v1/
  固定前缀。

****/****
  可变路径段，每个包都要换，可以是任意字母或多级路径。

最后一个字母
  固定功能后缀，不能改。
```

功能后缀：

```text
o
  startup / 启动状态接口。

l
  login / 一键登录接口。

p
  receiptVerify / 苹果 receipt 校验接口。

j
  purchaseEvent / Purchase 事件上报接口。

t
  pageLoadTime / Web 页面耗时上报接口。
```

也就是说，当前值：

```text
opi/v1/lqravme/qavrno
```

只属于当前包。接新包时，中间路径段要换，属性名 `auroraProbe` 也要换，但最后的功能后缀 `o` 要保留。

本文后面出现的 `auroraProbe`、`tapSigninRoute`、`storeReceiptGate` 等词，只表示业务类型，不能理解成每个包都固定使用的代码属性名。

### 4.1 接口参数 key 规则

每个接口里的参数 key 也不是固定字符串。例如：

```text
qavrnt
```

它只是当前包的示例 key。接新包时要按下面规则改：

```text
*****t
```

规则：

```text
前面的 *****
  可以随便换，每个包都要换，防止关联。

最后一个字母
  表示当前接口内的参数业务含义，不能改。
```

例如当前包：

```swift
"qavrnt": TimeZone.current.identifier // Timezone, key suffix t
```

新包可以改成：

```swift
"rhymeqt": TimeZone.current.identifier // Timezone, key suffix t
```

注意：

```text
变量名、接口路径、参数 key 的前缀都要按包换。
但参数 key 最后一个业务字母不能换。
参数 key 后缀的含义以当前接口为准；不同接口里同一个后缀可能表示不同字段。
每行代码后面都要用注释标明这个 key 是什么业务含义。
```

当前已主动调用的接口：

```text
当前启动状态接口属性
当前一键登录接口属性
当前 receipt 校验接口属性
当前 Purchase 事件接口属性
当前页面耗时接口属性
```

## 5. 自定义请求头

自定义 header 写在 `TavoniRouteConfig.HeaderMap`：

```swift
let firstHeaderName = "mqrta" // Custom header field 1
let firstHeaderValue = "plven" // Custom header value 1
let secondHeaderName = "xodre" // Custom header field 2
let secondHeaderValue = "nuvak" // Custom header value 2
```

这些自定义 header 不是固定协议字段，属于每个包自己加的字段。接新包时可以：

```text
改字段名
改字段值
增加更多组
减少组数
全部换成当前包自己的命名
```

例如当前包带：

```text
mqrta: plven
xodre: nuvak
```

新包可以换成：

```swift
let toneHeaderName = "abcdx" // Custom header field 1
let toneHeaderValue = "lmnoq" // Custom header value 1
let waveHeaderName = "qazws" // Custom header field 2
let waveHeaderValue = "plmok" // Custom header value 2
```

改自定义 header 属性名后，`TavoniPostClient` 里读取这些属性的地方也要同步改。

统一请求必须自动带这些固定 header：

```text
Content-Type: application/json
Accept: application/json
deviceNo
pushToken
appVersion
appId
loginToken
```

固定 header 字段不要改名：

```text
deviceNo
pushToken
appVersion
appId
loginToken
```

## 6. App 启动入口

启动入口放在 `SceneDelegate.scene(_:willConnectTo:options:)`，必须等宿主 App 的主 window 创建并 `makeKeyAndVisible()` 后再调用。

当前接法：

```swift
let window = UIWindow(windowScene: windowScene)
window.rootViewController = navigationController
self.window = window
window.makeKeyAndVisible()

TavoniFlowCenter.prime.ignite(in: windowScene)
```

为什么要放在这里：

```text
这套逻辑会创建 coverWindow。
coverWindow 需要依附 UIWindowScene。
如果太早调用，可能没有 scene 或主 window，覆盖层显示不稳定。
```

## 7. 推送 token 对接

在 `AppDelegate` 里接系统推送回调：

```swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    TavoniFlowCenter.prime.absorbPushToken(deviceToken)
}

func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
) {
    TavoniFlowCenter.prime.notePushTokenFailure(error)
}
```

保存规则：

```text
deviceToken 转小写十六进制字符串
保存到 UserDefaults
key = qavrn_push
```

通知权限请求时机：

```text
不要 App 一启动就弹通知权限。
必须等 startup 接口成功后，再 requestAuthorization。
用户拒绝通知权限不影响登录和 Web 流程。
```

当前代码中，通知权限由 `TavoniFlowCenter.askNotificationAfterProbe()` 触发。

## 8. 启动主流程

入口方法：

```swift
TavoniFlowCenter.prime.ignite(in: windowScene)
```

内部流程：

```text
1. 防止重复启动
2. 初始化事件上报出口
3. 创建 coverWindow
4. 显示启动图
5. 启动 StoreKit transaction observer
6. 显示 loading
7. 使用 NWPathMonitor 等待网络可用
8. 网络 satisfied 后只请求一次 startup 接口
9. 根据 startup 返回决定后续页面
```

网络等待规则：

```text
path.status == .satisfied 才请求 startup
path.status != .satisfied 时停留在启动覆盖层等待
didStartAfterNetworkReady 防止重复请求
```

## 9. 启动接口

调用位置：

```text
TavoniFlowCenter.requestAuroraProbe(...)
```

接口：

```text
POST <当前API base URL>/<当前启动状态接口路径>
```

请求参数：

```swift
[
    "qavrnt": TimeZone.current.identifier, // Timezone, key suffix t
    "qavrnk": TavoniDeviceProbe.keyboardMarks, // Input languages, key suffix k
    "qavrng": routeConfig.<当前debug开关属性> ? 1 : 0, // Debug flag, key suffix g
    "qavrnd": TavoniDeviceProbe.hasCarrierSignal() ? 1 : 0, // Cellular flag, key suffix d
    "qavrnn": TavoniDeviceProbe.isTunnelActive() ? 1 : 0 // VPN flag, key suffix n
]
```

参数含义：

```text
qavrnt -> *****t
  当前时区。

qavrnk -> *****k
  当前系统输入法语言数组。

qavrng -> *****g
  debug 标记，当前包 debug 开关为 true 时传 1，否则传 0。

qavrnd -> *****d
  是否有蜂窝网络服务，有则 1，否则 0。

qavrnn -> *****n
  是否检测到 VPN，有则 1，否则 0。
```

返回字段：

```text
loginFlag
openValue
locationFlag
```

处理规则：

```text
loginFlag == 0
  保存 openValue。
  如果 locationFlag == 0，显示登录页。
  如果 locationFlag != 0，关闭 coverWindow，回到宿主 App。

loginFlag == 1
  保存 openValue。
  如果本地有 loginToken，进入 Web 页。
  如果本地没有 loginToken，显示登录页。

其它情况
  关闭 coverWindow 或结束当前覆盖流程。
```

## 10. 登录页

登录页由 `TavoniSigninPanelController` 实现。

页面要求：

```text
黑色背景
全屏显示当前登录图配置对应的图片
底部 Log In 按钮
进入页面时重置 isSigninBusy
进入页面时隐藏 loading
```

按钮点击：

```swift
TavoniFlowCenter.prime.beginTapSignin()
```

重复点击保护：

```text
isSigninBusy == true 时直接 return。
登录失败后重置为 false。
登录成功进入 Web 后也重置为 false。
```

## 11. 登录接口

调用链：

```text
TavoniSigninPanelController.signinTapped()
TavoniFlowCenter.prime.beginTapSignin()
TavoniFlowCenter.prime.submitTapSignin(adid:)
TavoniPostClient.tunnel.post(path: TavoniRouteConfig.routeMap.<当前登录接口属性>, ...)
```

接口：

```text
POST <当前API base URL>/<当前一键登录接口路径>
```

请求参数：

```swift
[
    "qavrna": adid, // Adjust adid, key suffix a
    "qavrnd": TavoniLocalVault.sessionToken ?? "", // Existing login token, key suffix d
    "qavrnn": TavoniLocalVault.deviceStamp // Device id, key suffix n
]
```

参数含义：

```text
qavrna -> *****a
  Adjust adid。当前包已接入 AdjustSdk，等待 Adjust 回调后再继续登录请求；SDK 回调为空时才传空字符串。

qavrnd -> *****d
  本地已有 loginToken，没有则传空字符串。

qavrnn -> *****n
  本机 deviceId。
```

成功返回：

```text
token
password
```

保存位置：

```text
token    -> Keychain, key = qavrntk
password -> Keychain, key = qavrndk
```

成功后处理：

```text
如果已有 openValue，直接进入 Web 页。
如果没有 openValue，重新请求 startup。
```

## 12. Web 地址拼接

进入 Web 页前必须有：

```text
loginToken
openValue
appId
cipherSeed
cipherVector
```

构造 openParams：

```swift
let payload: [String: Any] = [
    "token": sessionText,
    "timestamp": String(Int(Date().timeIntervalSince1970 * 1000))
]
```

将 `payload` 转 JSON 后 AES 加密成小写 hex。

最终 URL：

```text
<openValue>/?openParams=<encryptedText>&appId=<appId>
```

当前代码：

```swift
let urlString = "\(entryPortal)/?openParams=\(encryptedText)&appId=\(routeConfig.<当前AppId属性>)"
```

## 13. 网络加密规则

统一请求由 `TavoniPostClient.tunnel.post(...)` 处理。

请求规则：

```text
POST
Content-Type: application/json
Accept: application/json
body 为 AES 加密后的 hex 字符串
```

body 处理：

```text
1. parameters 字典转 JSON 字符串
2. AES-128-CBC-PKCS7 加密
3. 加密 bytes 转小写 hex
4. hex 字符串作为 HTTP body
```

响应处理：

```text
1. 先解析响应 JSON
2. 如果有 result 字段，按 AES hex 解密 result
3. 解密结果再解析为字典
4. 如果没有 result，只有 allowsPlainResponse == true 的接口允许直接使用原始字典
```

允许 plain response 的接口：

```text
receiptVerify
purchaseEvent
```

AES 要求：

```text
算法：AES-128-CBC
填充：PKCS7Padding
key：16 位 UTF-8 字符串
iv：16 位 UTF-8 字符串
输出：小写 hex
```

## 14. 本地存储

`TavoniLocalVault` 负责本地存储。

Keychain：

```text
loginToken -> qavrntk  // Login token key
password   -> qavrndk  // Password key
deviceId   -> qavrndev // Device id key
```

UserDefaults：

```text
pushToken                -> qavrn_push // Push token storage key
installEventReportedFlag -> mivtau===   // Install event flag key
```

这些本地存储 key 也是当前包示例，接新包时建议一起换掉，防止不同包之间留下相同存储命名痕迹。

换名规则：

```text
key 的完整字符串可以换。
业务用途不能搞混。
每个 key 后面必须保留注释，标明它存什么。
代码里读写同一个值的地方必须用同一个 key。
```

例如：

```swift
static let vocalSessionKey = "abcxtk" // Login token key
static let vocalSecretKey = "plmokd" // Password key
static let vocalDeviceKey = "qwerdev" // Device id key
static let vocalPushKey = "zxcv_push" // Push token storage key
static let vocalInstallFlag = "mnbv===" // Install event flag key
```

退出登录时：

```text
只删除 loginToken。
保留 deviceId、pushToken、installEventReportedFlag。
```

设备号规则：

```text
优先读 Keychain 里的 deviceId。
如果没有，用 UIDevice.current.identifierForVendor?.uuidString。
如果还没有，用 qavrn-device 兜底。
生成后保存到 Keychain。
```

## 15. WebView 对接

Web 页由 `TavoniCanvasController` 实现。

WKWebView 配置：

```swift
configuration.allowsInlineMediaPlayback = true
configuration.mediaTypesRequiringUserActionForPlayback = []
webView.scrollView.contentInsetAdjustmentBehavior = .never
webView.scrollView.bounces = false
webView.allowsBackForwardNavigationGestures = true
```

页面加载：

```text
loadInitialPage() 开始加载 initialURLString。
加载前显示当前登录图配置对应的遮罩和页面 loading。
didFinish 后隐藏 loading，移除遮罩，并上报页面耗时。
didFail / didFailProvisionalNavigation 后隐藏 loading，保留遮罩。
```

页面耗时上报：

```text
接口：<当前页面耗时接口路径>
参数：qavrno -> *****o = 页面加载毫秒耗时
失败不影响 Web 使用。
```

## 16. JS Bridge

必须注册这些 bridge 名称：

```text
Close
rechargePay
openBrowser
```

当前还按参考注册了：

```text
handleSkipStore
```

### Close

H5 调用：

```text
window.webkit.messageHandlers.Close.postMessage(...)
```

Native 行为：

```text
删除本地 loginToken
重置登录防重复状态
隐藏 loading
回到登录页
```

### rechargePay

H5 传参：

```json
{
  "batchNo": "<苹果商品 id>",
  "orderCode": "<后端订单号>"
}
```

Native 行为：

```text
batchNo 作为 StoreKit productID。
orderCode 写入 payment.applicationUsername。
进入苹果内购流程。
```

### openBrowser

H5 传参：

```json
{
  "url": "<要打开的外部链接>"
}
```

Native 行为：

```text
UIApplication.shared.open(url)
```

回调 H5：

```javascript
window.dispatchEvent(new CustomEvent('nativeOpenState', {
  detail: {
    state: 'success',
    url: '<原始 URL>'
  }
}));
```

失败时：

```javascript
window.dispatchEvent(new CustomEvent('nativeOpenState', {
  detail: {
    state: 'failed',
    url: '<原始 URL>'
  }
}));
```

注意：

```text
success 只表示系统成功打开了外部 URL，不代表第三方支付成功。
```

## 17. URL Scheme 拦截

允许 WebView 正常加载的 scheme：

```text
http
https
file
chrome
data
javascript
about
```

其它 scheme：

```text
调用 UIApplication.shared.open
派发 nativeOpenState 给 H5
取消当前 WebView 跳转
```

App Store 链接：

```text
https://apps.apple.com/
itms-apps://
```

处理规则：

```text
直接交给系统打开，不在 WebView 里加载。
```

## 18. 防截屏安全容器

当前实现按参考方式放在 `TavoniShieldView.swift`。

结构：

```text
TavoniCanvasController.view
  capturePlaceholderView
    当前登录图配置对应的图片
  TavoniShieldView
    secureTextField
      secure canvas
        contentView
          WKWebView
          launchImageView
          pageLoadingIndicator
```

`secureTextField` 设置：

```swift
secureTextField.isSecureTextEntry = true
secureTextField.backgroundColor = .clear
secureTextField.textColor = .clear
secureTextField.tintColor = .clear
secureTextField.borderStyle = .none
secureTextField.clipsToBounds = true
```

安全 canvas 查找规则：

```text
遍历 secureTextField.subviews
找到类名包含 CanvasView / LayoutCanvasView / TextLayoutCanvasView 的 view
把 contentView 添加进去
```

`TavoniSilentField` 只做参考里的处理：

```swift
override var canBecomeFirstResponder: Bool { false }
override func caretRect(for position: UITextPosition) -> CGRect { .zero }
override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] { [] }
```

不要额外加：

```text
UIScreen.isCaptured 黑遮罩
录屏全屏遮罩
把 secureTextField.isUserInteractionEnabled 设为 false
textRect/editingRect 返回 .zero
canPerformAction 全关
becomeFirstResponder 强行 false
```

原因：

```text
WebView 是挂在 secure canvas 里的。
如果父级禁用交互，WebView 会无法点击。
如果把 textfield 布局区域压成 zero，可能导致安全 canvas 显示异常。
如果用 UIScreen.isCaptured 黑遮罩，模拟器、投屏、桌面预览时容易整屏黑。
```

## 19. 苹果内购

支付入口：

```text
H5 调 rechargePay
TavoniCanvasController.beginStoreOrder(storeProductId:orderMarkText:)
TavoniOrderBridge.beginOrder(storeProductID:orderMarkText:)
```

流程：

```text
1. 检查 SKPaymentQueue.canMakePayments()
2. 使用 batchNo 创建 SKProductsRequest
3. 拿到 SKProduct 后记录 price 和 currency
4. 上报 Facebook initiated checkout
5. 创建 SKMutablePayment
6. payment.applicationUsername = orderCode
7. SKPaymentQueue.default().add(payment)
8. purchased 后读取 App Store receipt
9. 提交 receipt 给后端校验
10. 后端成功后上报 purchase 事件
11. 后端成功后 finishTransaction
```

receipt 校验接口：

```text
POST <当前API base URL>/<当前receipt校验接口路径>
```

参数：

```swift
[
    "qavrnt": transactionID, // Transaction id, key suffix t
    "qavrnp": receiptBase64, // Receipt base64, key suffix p
    "qavrnc": "{\"orderCode\":\"<orderCode>\"}" // Order code JSON, key suffix c
]
```

参数 key 规则：

```text
qavrnt -> *****t
  transactionId。

qavrnp -> *****p
  receiptBase64。

qavrnc -> *****c
  orderCode JSON 字符串。
```

关键规则：

```text
receiptVerify 成功才 finishTransaction。
receiptVerify 失败不要 finishTransaction。
没有 orderCode 的交易不由 Web 支付协调器处理，避免误处理原生充值页交易。
```

当前 Web 支付协调器判断交易是否属于 Web：

```text
优先读取 transaction.payment.applicationUsername。
如果为空，再判断 productIdentifier 是否等于当前 runningProductID 且 runningOrderCode 不为空。
```

## 20. 事件上报

文件：

```text
TavoniSignalBridges.swift
```

Adjust：

```text
当前实现直接接入 AdjustSdk。
工程必须保留 AdjustSdk 依赖，否则会编译失败。
登录 adid、归因 JSON、安装事件、支付事件都通过 AdjustSdk 获取或上报。
```

Adjust 初始化：

```text
appToken = z1qr64z7alts
environment = production
logLevel = suppress
全局 callback 参数 ta_distinct_id = deviceId
安装事件只上报一次
```

Adjust 支付：

```text
purchaseEventToken = vmuilr
price > 0 时上报 revenue
transactionId 存在时带 transactionId
```

后端 Purchase 事件：

```text
接口：<当前Purchase事件接口路径>
参数：
  qavrnt -> *****t = attribution JSON 字符串，Adjust 回调为空时为 {}
  qavrne -> *****e = Purchase
  qavrnd -> *****d = deviceId
  qavrna -> *****a = adid，Adjust 回调为空时为空字符串
```

Facebook：

```text
当前实现直接接入 FacebookCore。
工程必须保留 FacebookCore 依赖，否则会编译失败。
支付发起和支付成功会真实调用 AppEvents。
```

Facebook 事件：

```text
发起支付：fb_mobile_initiated_checkout
支付成功：logPurchase
默认币种：USD
```

## 21. 图片资源

当前配置依赖两个图片资源：

```text
launch_background
HNSo7SkaMAE19-e
```

接入时需要确保 `Assets.xcassets` 中存在同名 imageset。

用途：

```text
launch_background
  App 启动覆盖层背景。

HNSo7SkaMAE19-e
  登录页背景、Web 加载遮罩、截图占位图。
```

如果图片名不存在：

```text
UIImage(named:) 返回 nil。
界面会显示黑色背景，看起来像黑屏。
```

## 22. 宿主 App 原有页面关系

这套 Web 逻辑使用 `coverWindow`，不会直接替换宿主 App 的主 window。

表现：

```text
startup 判断需要显示 Web / 登录页时，coverWindow 盖在宿主 App 上。
startup 判断不需要显示时，coverWindow 隐藏并释放，用户回到原生 App。
```

注意：

```text
coverWindow.windowLevel = .normal + 1
```

因此它会盖住原生页面。如果启动接口失败或网络一直不可用，用户会停留在启动覆盖层。

## 23. 接入步骤汇总

按顺序接：

```text
1. 把 AppWebRuntime 目录加入工程。
2. 确认 TavoniRouteConfig 中当前包的 AppId、AES、API base URL、图片名、事件 token 属性名和值都正确。
3. 确认 Assets.xcassets 里有当前启动图和当前登录图配置对应的 imageset。
4. 在 SceneDelegate 的 window.makeKeyAndVisible() 后调用 TavoniFlowCenter.prime.ignite(in: windowScene)。
5. 在 AppDelegate 接 didRegisterForRemoteNotificationsWithDeviceToken 并调用 absorbPushToken。
6. 确认 StoreKit 商品 id 与 H5 下发 batchNo 一致。
7. 确认 H5 按约定调用 Close / rechargePay / openBrowser。
8. 确认后端接口支持 AES body 和 result 解密。
9. 如需要真实 Adjust，上工程依赖 AdjustSdk。
10. 如需要真实 Facebook 事件，上工程依赖 FacebookCore。
```

## 24. H5 对接约定

H5 需要调用的 Native bridge：

```text
Close
rechargePay
openBrowser
```

关闭登录态：

```javascript
window.webkit.messageHandlers.Close.postMessage({});
```

拉起内购：

```javascript
window.webkit.messageHandlers.rechargePay.postMessage({
  batchNo: "apple_product_id",
  orderCode: "backend_order_code"
});
```

打开外部链接：

```javascript
window.webkit.messageHandlers.openBrowser.postMessage({
  url: "https://example.com"
});
```

监听外部打开结果：

```javascript
window.addEventListener('nativeOpenState', function (event) {
  console.log(event.detail.state);
  console.log(event.detail.url);
});
```

## 25. 后端对接约定

后端需要支持：

```text
请求 body 是 AES 加密后的 hex 字符串。
响应 JSON 中 result 是 AES 加密后的 hex 字符串。
receipt 校验和 purchase event 可允许 plain response。
```

startup 返回示例：

```json
{
  "result": "<encrypted-json-hex>"
}
```

解密后：

```json
{
  "loginFlag": 0,
  "openValue": "https://example-web-entry.com",
  "locationFlag": 0
}
```

login 解密后返回：

```json
{
  "token": "login-token",
  "password": "password-from-backend"
}
```

receipt 校验接口成功时：

```text
返回可带 result，也可以 plain JSON。
只要 Native 收到 success result，就会 finishTransaction。
```

## 26. 验收清单

接完后至少检查：

```text
App 启动后出现 launch_background 覆盖层。
无网络时不请求 startup，只等待网络。
网络恢复后 startup 只请求一次。
startup 成功后才弹通知权限。
拒绝通知权限不影响登录页和 Web 页。
loginFlag == 0 且 locationFlag == 0 时显示登录页。
登录页按钮第一次点击有效，重复点击不会重复请求。
登录失败后按钮可再次点击。
登录成功后 token/password 保存到 Keychain。
loginFlag == 1 且本地有 token 时进入 Web。
Web URL 带 openParams 和 appId。
Web 加载完成后上报 pageLoadTime。
Close 能清 loginToken 并回登录页。
rechargePay 能用 batchNo 拉起苹果内购。
payment.applicationUsername 等于 orderCode。
receipt 校验成功后才 finishTransaction。
receipt 校验失败不 finishTransaction。
openBrowser 能打开外部 URL。
非 http/https 等 scheme 能交给系统打开并回调 nativeOpenState。
App Store 链接交给系统打开。
Web 内容在 secure textfield 容器中显示，正常点击不受影响。
图片名不存在时不会误判接口问题，应先检查 Assets。
```

## 27. 常见问题

### 启动后黑屏

先查：

```text
当前启动图配置对应的图片是否存在。
当前登录图配置对应的图片是否存在。
startup 接口是否失败。
当前是否无网络导致停在启动覆盖层。
secure canvas 是否被改坏。
```

不要用：

```text
UIScreen.isCaptured 全屏黑遮罩
```

模拟器、投屏、桌面预览环境下可能被系统判定为 captured，导致整屏黑。

### WebView 点不了

检查：

```text
不要把 secureTextField.isUserInteractionEnabled 设为 false。
不要把 secure canvas 的 isUserInteractionEnabled 设为 false。
不要在 WebView 上层加可交互遮罩。
```

### 登录接口没有调用

登录接口只在用户点击登录页底部 `Log In` 后调用。

调用链：

```text
TavoniSigninPanelController.signinTapped()
TavoniFlowCenter.prime.beginTapSignin()
TavoniFlowCenter.prime.submitTapSignin(adid:)
TavoniPostClient.tunnel.post(path: TavoniRouteConfig.routeMap.<当前登录接口属性>)
```

### 支付完成但没有到账

检查：

```text
H5 传的 batchNo 是否是苹果商品 id。
H5 传的 orderCode 是否非空。
receiptVerify 是否返回成功。
receiptVerify 失败时 Native 不会 finishTransaction。
```

### 原生充值页和 Web 支付互相影响

当前 Web 支付只处理带 `applicationUsername / orderCode` 的交易。

原生充值页如果没有设置 `applicationUsername`，不会被 Web 支付协调器误处理。

### Adjust 没有上报

检查：

```text
工程是否真的接入 AdjustSdk。
当前代码直接 import AdjustSdk。
没有 AdjustSdk 会编译失败，不会进入运行时降级。
```

### Facebook 没有上报

检查：

```text
工程是否真的接入 FacebookCore。
当前代码直接 import FacebookCore。
没有 FacebookCore 会编译失败，不会进入运行时降级。
```

## 28. 不能改和必须改的最终清单

这一节作为最后检查用。接包时按这里核一遍，不能改的不要动，必须换的不要漏。

### 28.0 先看结论

可以改、而且每个包必须改：

```text
自己定义的 Swift 类型名
自己定义的 Swift 方法名
自己定义的 Swift 常量名 / 变量名 / 属性名
自己定义的文件名
RouteMap 里的接口属性名
接口路径里的可变段
接口参数 key 的前缀
Keychain / UserDefaults 本地存储 key
自定义 header 的字段名和值
当前包业务值：AppId、AES、图片名、Adjust token、API base URL
```

不能改：

```text
Apple / iOS 系统 API 和协议方法签名
HTTP 固定 header 字段名
H5 Bridge message 名称
H5 入参字段
Native 回调 H5 的事件名和字段
后端响应字段
Web URL 固定参数名
AES 加密规则
StoreKit 系统字段和方法名
```

### 28.1 不能改：后端协议字段

下面这些是 Native 和后端约定好的字段名。除非后端接口一起改，否则不要改：

```text
result
loginFlag
openValue
locationFlag
token
password
```

### 28.2 不能改：固定请求头字段

下面这些 HTTP header 字段名不要改：

```text
Content-Type
Accept
deviceNo
pushToken
appVersion
appId
loginToken
```

注意：

```text
Swift 代码里的 clientMark 属性名可以每个包换。
HTTP header 里的 appId 字段名不能换。
```

### 28.3 不能改：H5 / Native Bridge 协议

下面这些 JS message 名称不要改，H5 会按这些名字调用 Native：

```text
Close
rechargePay
openBrowser
handleSkipStore
```

下面这些 H5 入参字段不要改：

```text
batchNo
orderCode
url
```

下面这些 Native 回调 H5 的事件名和字段不要改：

```text
nativeOpenState
state
success
failed
```

### 28.4 不能改：Web URL 参数名

进入 Web 时，URL query 参数名不要改：

```text
openParams
appId
```

注意：

```text
Swift 代码里的 clientMark 属性名可以每个包换。
Web URL query 里的 appId 参数名不能换。
```

### 28.5 不能改：加密规则

请求和响应的加密规则不要改，否则后端无法解密：

```text
AES-128-CBC
PKCS7Padding
key 长度 16 位 UTF-8 字符串
iv 长度 16 位 UTF-8 字符串
密文使用小写 hex
请求 body 直接放加密后的 hex 字符串
响应 result 里放加密后的 hex 字符串
```

### 28.6 一般不要改：统计约定

下面这些属于统计约定。只有统计后台、Adjust / Facebook 配置一起确认要改时，才能改：

```text
ta_distinct_id
Purchase
USD
```

### 28.7 必须改：每个包的混淆命名

下面这些不能所有包复用同一套名字，接新包时要换：

```text
Swift 自定义类型名
Swift 自定义方法名
Swift 自定义常量名
Swift 自定义变量名
Swift 配置属性名
Swift 文件名
接口属性名
接口路径中间段
接口参数 key 前缀
本地存储 key
自定义 header 字段和值
```

这里说的 Swift 自定义命名，指自己写的 `class / struct / enum / func / let / var / static let`。不是 Apple 系统 API，也不是 H5 / 后端协议字段。

当前包示例：

```text
TavoniRouteConfig
TavoniFlowCenter
TavoniPostClient
TavoniLocalVault
TavoniCanvasController
ignite
beginTapSignin
requestAuroraProbe
clientMark
cipherSeed
entryPortal
coverWindow
sessionTokenSlot
```

这些都是自己定义的命名，接新包时要换。

这些接口参数 key 的完整字符串不要跨包复用。接新包时前缀要换，但最后一个业务字母必须保持：

```text
qavrnt -> *****t
qavrnk -> *****k
qavrng -> *****g
qavrnd -> *****d
qavrnn -> *****n
qavrna -> *****a
qavrnp -> *****p
qavrnc -> *****c
qavrne -> *****e
qavrno -> *****o
```

注意：

```text
最后一个字母只表示当前接口里这个参数的业务含义。
不同接口里同一个最后字母，可能代表不同字段。
所以每个参数后面都要保留注释，写清楚它是什么。
```

## 29. 当前实现与完整 SDK 的差异

当前工程是 App 内置实现，不是 SDK 打包实现。

已实现主链路：

```text
启动
登录
WebView
JS Bridge
推送 token
加密网络
StoreKit 支付
receipt 后端校验
页面耗时上报
后端 Purchase 事件
secure textfield 截屏保护
```

当前必须保留这些工程依赖：

```text
AdjustSdk
FacebookCore
```

宿主工程必须接入这些依赖。当前代码直接调用第三方 SDK，没有依赖会编译失败。

## 30. 最小接入代码示例

`SceneDelegate`：

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let rootViewController = UIViewController()
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = rootViewController
    self.window = window
    window.makeKeyAndVisible()

    TavoniFlowCenter.prime.ignite(in: windowScene)
}
```

`AppDelegate`：

```swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    TavoniFlowCenter.prime.absorbPushToken(deviceToken)
}

func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
) {
    TavoniFlowCenter.prime.notePushTokenFailure(error)
}
```

配置：

```swift
struct TavoniRouteConfig {
    let rhythmClientCode = "11111111" // AppId
    let rhythmCipherSeed = "9986sdff5s4f1123" // Key
    let rhythmCipherVector = "9986sdff5s4y456a" // IV
    let rhythmLaunchAsset = "launch_background" // Launch image
    let rhythmLoginAsset = "HNSo7SkaMAE19-e" // Login image
    let rhythmTraceEnabled = false // Debug
    let rhythmAttributionApp = "z1qr64z7alts" // Adjust app token
    let rhythmInstallSignal = "w69fw8" // Adjust install event token
    let rhythmPurchaseSignal = "vmuilr" // Adjust purchase event token
    let rhythmGatewayURL = "https://opi.cphub.link" // API base URL
}
```

接完这三处后，再按上面的章节补齐 AppWebRuntime 目录文件、图片资源、StoreKit 商品、H5 bridge 和后端接口即可。
