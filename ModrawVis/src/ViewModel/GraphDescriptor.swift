import SwiftUI

struct GraphDescriptor {
    let label: String
    var visible: Bool
    let renderer: (GraphRenderer) -> Void
    fileprivate let presetValues: [Bool]

    fileprivate static let presetNames = ["EPSI", "FCTD"]
    init(_ label: String, _ presetValues: [Bool], _ renderer: @escaping (GraphRenderer)->Void) {
        self.label = label
        self.renderer = renderer
        self.visible = true
        self.presetValues = presetValues

        assert(presetValues.count == GraphDescriptor.presetNames.count)
        for i in 0..<presetValues.count {
            let presetName = GraphDescriptor.presetNames[i]
            if getUserDefaultValueFor(presetName) == nil {
                setUserDefaultValueFor(presetName, presetValues[i])
            }
        }
    }
    fileprivate func getUserDefaultIdFor(_ preset: String) -> String {
        return "Preset\(preset).\(label)"
    }
    fileprivate func getUserDefaultValueFor(_ preset: String) -> Bool? {
        let id = getUserDefaultIdFor(preset)
        return UserDefaults.standard.object(forKey: id) as? Bool
    }
    fileprivate func setUserDefaultValueFor(_ preset: String, _ visible: Bool) {
        let id = getUserDefaultIdFor(preset)
        UserDefaults.standard.set(visible, forKey: id)
    }
    mutating func resetToUserDefaultFor(preset: String) {
        let i = GraphDescriptor.presetNames.firstIndex(of: preset)!
        setUserDefaultValueFor(preset, presetValues[i])
        visible = presetValues[i]
    }
    mutating func resetVisibleFromUserDefaultFor(preset: String) {
        visible = getUserDefaultValueFor(preset) ?? true
    }
    mutating func setVisibleFor(preset: String, visible: Bool) {
        self.visible = visible
        setUserDefaultValueFor(preset, visible)
    }
}

