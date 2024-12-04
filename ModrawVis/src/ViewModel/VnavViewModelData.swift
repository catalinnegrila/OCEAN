import SwiftUI

class VnavViewModelData: VnavModelData {

    func render3(gr: GraphRenderer, base: Int, labels: [(Color, String)]) {
        let range = rangeUnion(channels[base].range(), channels[base+1].range(), channels[base+2].range())
        let yAxis = rangeToYAxis(range: range)
        
        gr.renderGrid(td: self, yAxis: yAxis, leftLabels: true, format: "%.2f")
        gr.renderTimeSeries(td: self, data: channels[base], range: range, color: labels[0].0)
        gr.renderTimeSeries(td: self, data: channels[base+1], range: range, color: labels[1].0)
        gr.renderTimeSeries(td: self, data: channels[base+2], range: range, color: labels[2].0)
        if !channels[base].isEmpty {
            gr.drawDataLabels(labels: labels)
        }
    }
    func renderCompass(gr: GraphRenderer) {
        render3(gr: gr, base: 0, labels: [
            (.red, "x"),
            (.green, "y"),
            (.blue, "z")])
    }
    func renderAcceleration(gr: GraphRenderer) {
        render3(gr: gr, base: 3, labels: [
            (.red, "x"),
            (.green, "y"),
            (.blue, "z")])
    }
    func renderGyro(gr: GraphRenderer) {
        render3(gr: gr, base: 6, labels: [
            (.red, "x"),
            (.green, "y"),
            (.blue, "z")])
    }
    func renderYawPitchRoll(gr: GraphRenderer) {
        render3(gr: gr, base: 0, labels: [
            (.red, "Yaw"),
            (.green, "Pitch"),
            (.blue, "Roll")])
    }
}
