import SwiftUI

struct SliderView: View {
    @ObservedObject var slider: CustomSlider
    
    var body: some View {
        RoundedRectangle(cornerRadius: slider.lineWidth)
            .fill(Color.gray.opacity(0.2))
            .frame(width: slider.width, height: slider.lineWidth)
            .overlay(
                ZStack {
                    //Path between both handles
                    SliderPathBetweenView(slider: slider)
                    
                    //Low Handle
                    SliderHandleView(handle: slider.lowHandle)
                        .highPriorityGesture(slider.lowHandle.sliderDragGesture)
                    
                    //High Handle
                    SliderHandleView(handle: slider.highHandle)
                        .highPriorityGesture(slider.highHandle.sliderDragGesture)
                }
            )
    }
}

struct SliderHandleView: View {
    @ObservedObject var handle: SliderHandle
    
    var body: some View {
        Circle()
            .frame(width: handle.diameter, height: handle.diameter)
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 0)
            .scaleEffect(handle.onDrag ? 1.3 : 1)
            .contentShape(Rectangle())
            .position(x: handle.currentLocation.x, y: handle.currentLocation.y)
    }
}

struct SliderPathBetweenView: View {
    @ObservedObject var slider: CustomSlider
    
    var body: some View {
        Path { path in
            path.move(to: slider.lowHandle.currentLocation)
            path.addLine(to: slider.highHandle.currentLocation)
        }
        .stroke(Color.green, lineWidth: slider.lineWidth)
    }
}
