import Foundation

class StreamingModel: Model{
    var epsiModrawParser: EpsiModrawParser?
    let time_window_length = 20.0 // seconds

    override func getTimeWindow() -> (Double, Double)
    {
        let epsi_time_end = epsi_blocks.isEmpty ? 0.0 : epsi_blocks.last!.time_s.last!
        let ctd_time_end = ctd_blocks.isEmpty ? 0.0 : ctd_blocks.last!.time_s.last!
        let time_window_start = max(epsi_time_end, ctd_time_end) - time_window_length
        // Round time to pixel increments for consistent sampling
        //if (pixel_width > 0) {
        //    let time_per_pixel = time_window_length / Double(pixel_width)
        //    time_window.0 = floor(model.time_window.0 / time_per_pixel) * time_per_pixel
        //}
        return (time_window_start, time_window_start + time_window_length)
    }
}
