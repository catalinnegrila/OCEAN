import Foundation
import ArgumentParser

struct SimulatorOptions: ParsableArguments {
    @Option(name: .shortAndLong, help: ArgumentHelp("Input .modraw file path.", valueName: "input.modraw"))
    var inputFilePath : String
    
    @Option(name: .shortAndLong, help: ArgumentHelp("Output .modraw file path.", valueName: "output.modraw"))
    var outputFilePath : String
    
    @Option(name: .shortAndLong, help: ArgumentHelp("Time multiplier.", valueName: "multiplier"))
    var speed = 1.0
    
    @Flag(name: .shortAndLong, help: "Show extra information.")
    var verbose = false

    mutating func validate() throws {
        guard speed > 0 else {
            throw ValidationError("The time multiplier needs to be a strictly positive number.")
        }
    }

    // Helpers
    var inputFileUrl : URL {
        get {
            return URL(fileURLWithPath: inputFilePath)
        }
    }

    var outputFileUrl : URL {
        get {
            return URL(fileURLWithPath: outputFilePath)
        }
    }
}
