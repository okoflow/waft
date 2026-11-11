@MainActor
package protocol DayChangeMonitor: AnyObject {
    var dayChanges: AsyncStream<Void> { get }
}
