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
            Marker(degrees: 0, label: "N")
            //,
//            Marker(degrees: 30),
//            Marker(degrees: 60),
//            Marker(degrees: 90),
//            Marker(degrees: 120),
//            Marker(degrees: 150),
//            Marker(degrees: 180),
//            Marker(degrees: 210),
//            Marker(degrees: 240),
//            Marker(degrees: 270),
//            Marker(degrees: 300),
//            Marker(degrees: 330)
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
                .font(.system(size: 10))
            
            Capsule()
                .frame(width: self.capsuleWidth(),
                       height: self.capsuleHeight())
                .foregroundColor(self.capsuleColor())
                .padding(.bottom, 60)

        }.rotationEffect(Angle(degrees: marker.degrees))
        
        
        
    }
    
    private func capsuleWidth() -> CGFloat {
        return self.marker.degrees == 0 ? 1 : 1
    }

    private func capsuleHeight() -> CGFloat {
        return self.marker.degrees == 0 ? 60 : 3
    }

    private func capsuleColor() -> Color {
        return self.marker.degrees == 0 ? .white : .gray
    }

    private func textAngle() -> Angle {
        return Angle(degrees: -self.compassDegress - self.marker.degrees)
    }
}




struct Arrow: Shape {
    var spread : Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var _start: Double
        var _end: Double

        //self.spread = self.compassHeading.accuracy;
        

        print("spread: \(self.spread)")


        let thickness = 15.0;

        let r = 70.0 + thickness * 0.5;

        //        _start = -90.0 - self.spread;
        //        _end = -90.0 + self.spread;

        _start =  -self.spread / 2.0 - 90.0;
        _end = self.spread / 2.0 - 90.0;

        path.move(to: CGPoint(x: 250, y: 250))
        path.addArc(center: CGPoint(x:250,y:250), radius: r, startAngle: Angle(degrees:_start), endAngle: Angle(degrees:_end), clockwise: false)
        path.closeSubpath()

        return path
    }

}

struct Circle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 35, y: 35))

        path.addEllipse(in: CGRect(x: 0, y: 0, width: 70, height: 70))
        path.closeSubpath()
        

        
        return path
    }

}

struct ContentView : View {
    @ObservedObject var compassHeading = CompassHeading()
    //@ObservedObject private var connectivityManager = WatchSessionManager.shared
    
    var body: some View {

        ZStack {
            ZStack {
        
                

                //pointer
                Arrow(spread: self.compassHeading.bearingAccuracy)
                    .fill(.yellow)
                    //.stroke(lineWidth: 40)
                    //.fill(style: noFill)
                    .frame(width: 500, height: 500)
                    .rotationEffect(Angle(degrees: self.compassHeading.bearing))

                //compass
                ForEach(Marker.markers(), id: \.self) { marker in
                    CompassMarkerView(marker: marker,
                                      compassDegress: self.compassHeading.heading)
                }



            }
            .frame(width: 500,
                   height: 500)
            .rotationEffect(Angle(degrees: self.compassHeading.heading))
                    

        ZStack {
            
            //distance background
            Circle()
                .fill(.cyan)
                .frame(width: 70, height: 70)
                .onTapGesture {
                        self.compassHeading.unitsMetric = !self.compassHeading.unitsMetric
                   
                }

            
            //distance
            Text(self.compassHeading.distanceText)
                .font(.system(size: 20))
                .frame(width:300)
                .monospacedDigit()
            
            
            
            //units
            Text(self.compassHeading.unitText)
                .baselineOffset(-30)
                    .font(.system(size: 10))
                    .frame(width:60)
                    .monospacedDigit()
            
        }.frame(width: 500,
                height: 500)
            
            ZStack {
                
                //targetname
                Text(self.compassHeading.targetName)
                    .font(.system(size: 16))
                    .frame(width:280)
                    .monospacedDigit()
                    
                
            }.frame(width: 500,
                    height: 500)
            .offset(x:0, y: 90)
        
        }
    }
        
}






struct Previews_ContentView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
