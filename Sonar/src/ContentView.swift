//
//  ContentView.swift
//  Sonar
//
//  Created by Catalin Negrila on 3/29/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Grid {
            GridRow {
                Text("Sonar Display").bold()
                // Top sliders
                HStack {
                    
                }
                .frame(maxWidth: 1024)
                SliderView(slider: CustomSlider(start: 10, end: 100))
            }
            GridRow {
                HStack {
                    // Plotting Panel
                    VStack {
                        VStack {
                            Text("Plotting")
                        }
                        Button {
                        } label: {
                            Text("live")
                        }
                    }
                    .frame(width: 100)
                    // Content
                    VStack {
                        Image(systemName: "globe")
                            .imageScale(.large)
                            .foregroundStyle(.tint)
                        Text("Hello, world!")
                    }
                    .frame(maxWidth: 1024, maxHeight: 1024)
                }
            }
        }
        .frame(minWidth: 300, minHeight: 300)
        //.padding()
    }
}

#Preview {
    ContentView()
}
