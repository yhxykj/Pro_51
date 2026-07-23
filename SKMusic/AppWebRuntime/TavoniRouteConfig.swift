import Foundation

struct TavoniRouteConfig {
    struct RouteMap {
        let auroraProbe = "opi/v1/lqravme/qavrno"
        let tapSigninRoute = "opi/v1/novqale/qavrnl"
        let storeReceiptGate = "opi/v1/vemquar/qavrnp"
        let checkoutPulse = "opi/v1/qalmire/qavrnj"
        let canvasTiming = "opi/v1/renqiva/qavrnt"
    }

    struct HeaderMap {
        let firstHeaderName = "mqrta"
        let firstHeaderValue = "plven"
        let secondHeaderName = "xodre"
        let secondHeaderValue = "nuvak"
    }

    let clientMark = "78645321"
    let cipherSeed = "siu1v6lba0kvtvfs"
    let cipherVector = "dj0nlr0tw8cp8nv4"
    
    let splashAsset = "launch_background"
    let signinAsset = "HNSo7SkaMAE19-e"
    let traceSwitch = true
    let adjustBundleToken = "z1qr64z7alts"
    let adjustFirstSignal = "w69fw8"
    let adjustPaidSignal = "vmuilr"

    let gatewayRoot = "https://opi.qwlx9ko4.link"

    static let activeConfig = TavoniRouteConfig()
    static let routeMap = RouteMap()
    static let coverHeaders = HeaderMap()

    static let pushCacheSlot = "qavrn_push"
    static let installPulseSlot = "mivtau==="
    static let sessionTokenSlot = "qavrntk"
    static let secretSlot = "qavrndk"
    static let deviceStampSlot = "qavrndev"
    static let fallbackDeviceMark = "qavrn-device"
}
