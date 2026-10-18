import Testing
import WaftCore

struct RunningAppTests {
    @Test(arguments: [("Safari", "Safari"), (nil, "com.apple.Safari")] as [(String?, String)])
    func `describes an activated app by its name or else its bundle identifier`(name: String?, shownName: String) {
        let app = RunningApp.trackable(bundleIdentifier: "com.apple.Safari", name: name)

        #expect(app == RunningApp(bundleIdentifier: "com.apple.Safari", name: shownName))
    }

    @Test(arguments: [AppIdentity.bundleIdentifier, nil])
    func `ignores Waft and apps without a bundle identifier`(bundleIdentifier: String?) {
        #expect(RunningApp.trackable(bundleIdentifier: bundleIdentifier, name: "Waft") == nil)
    }
}
