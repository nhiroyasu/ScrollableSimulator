import Foundation

var APP_NAME: String {
    if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
        return appName
    } else if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
        return appName
    } else {
        return ""
    }
}

var APP_URL: URL! {
    return Bundle.main.bundleURL
}
