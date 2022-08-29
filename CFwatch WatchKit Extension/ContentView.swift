//
//  ContentView.swift
//  CFwatch WatchKit Extension
//

//  original source: https://medium.com/@darrenleak1/build-a-compass-app-with-swiftui-f9b7faa78098
//  Created by Che-Wei Wang on 8/26/22.
//  Copyright © 2022 CWandT. All rights reserved.
//
import Foundation
import SwiftUI

struct Marker: Hashable {
    let degrees: Double
    let label: String

    init(degrees: Double, label: String = "") {
        self.degrees = degrees
        self.label = label
    }

    func degreeText() -> String {
        return String(format: "%.0f", self.degrees)
    }

    static func markers() -> [Marker] {
        return [
            Marker(degrees: 0, label: "N"),
            Marker(degrees: 30),
            Marker(degrees: 60),
            Marker(degrees: 90),
            Marker(degrees: 120),
            Marker(degrees: 150),
            Marker(degrees: 180),
            Marker(degrees: 210),
            Marker(degrees: 240),
            Marker(degrees: 270),
            Marker(degrees: 300),
            Marker(degrees: 330)
        ]
    }
}

struct CompassMarkerView: View {
    let marker: Marker
    let compassDegress: Double

    var body: some View {
        VStack {

            Text(marker.label)
                .fontWeight(.light)
                //.rotationEffect(self.textAngle())
                .foregroundColor(.red)
            
            Capsule()
                .frame(width: self.capsuleWidth(),
                       height: self.capsuleHeight())
                .foregroundColor(self.capsuleColor())
                .padding(.bottom, 60)

 
            
//            Text(marker.label)
//                .fontWeight(.bold)
//                .rotationEffect(self.textAngle())
//                .padding(.bottom, 130)
        }.rotationEffect(Angle(degrees: marker.degrees))
        
        
        
    }
    
    private func capsuleWidth() -> CGFloat {
        return self.marker.degrees == 0 ? 1 : 1
    }

    private func capsuleHeight() -> CGFloat {
        return self.marker.degrees == 0 ? 30 : 3
    }

    private func capsuleColor() -> Color {
        return self.marker.degrees == 0 ? .white : .gray
    }

    private func textAngle() -> Angle {
        return Angle(degrees: -self.compassDegress - self.marker.degrees)
    }
}



struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 150, y: 150))
        path.addLine(to: CGPoint(x: -40.0, y: 80.0))
        path.addLine(to: CGPoint(x: 40.0, y: 80.0))
        
        path.closeSubpath()
        
        
        
        return path
    }
    
}

struct ContentView : View {
    @ObservedObject var compassHeading = CompassHeading()
    

    var body: some View {
        VStack {

            ZStack {
                
                //compass
            
                ForEach(Marker.markers(), id: \.self) { marker in
                    CompassMarkerView(marker: marker,
                                      compassDegress: self.compassHeading.degrees)
                }
                //pointer

                Triangle()
                    .fill(.yellow)
                    .frame(width: 300, height: 300)

                
            }
            .frame(width: 350,
                   height: 350)
            .rotationEffect(Angle(degrees: self.compassHeading.degrees))
            

            }
            

            
        }
        
        



    
}

struct Previews_ContentView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
