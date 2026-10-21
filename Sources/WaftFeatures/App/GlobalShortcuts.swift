package import WaftCore

package struct GlobalShortcuts {
    let modeCycle: any GlobalShortcut
    let translator: any GlobalShortcut
    let translateSelection: any GlobalShortcut
    let fixSelection: any GlobalShortcut

    package init(
        modeCycle: any GlobalShortcut,
        translator: any GlobalShortcut,
        translateSelection: any GlobalShortcut,
        fixSelection: any GlobalShortcut,
    ) {
        self.modeCycle = modeCycle
        self.translator = translator
        self.translateSelection = translateSelection
        self.fixSelection = fixSelection
    }
}
