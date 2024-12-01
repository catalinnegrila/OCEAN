import Foundation

class StreamingModelProducer: ModelProducer {
    var epsiModrawParser: EpsiModrawParser?
    let time_window_length = 20.0 // seconds

    override func getTimeWindow(model: Model) -> (Double, Double)
    {
        let time_window_start = model.getEndTime() - time_window_length
        // Round time to pixel increments for consistent sampling
        //if (pixel_width > 0) {
        //    let time_per_pixel = time_window_length / Double(pixel_width)
        //    time_window.0 = floor(model.time_window.0 / time_per_pixel) * time_per_pixel
        //}
        return (time_window_start, time_window_start + time_window_length)
    }
}
