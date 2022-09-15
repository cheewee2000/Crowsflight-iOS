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
import WatchKit


class Home: WKInterfaceController {
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        print("awake")
        //var compassHeading = CompassHeading()
        //compassHeading.loadDictionary()
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        print("will Activate")
        
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        print("didDeactivate")
        
        super.didDeactivate()
    }
    
    
}




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
        
        //        print("spread: \(self.spread)")
        
        
        let thickness = 15.0;
        
        let r = 70.0 + thickness * 0.5;
        
        _start =  -self.spread / 2.0 - 90.0;
        _end = self.spread / 2.0 - 90.0;
        
        path.move(to: CGPoint(x: 250, y: 250))
        path.addArc(center: CGPoint(x:250,y:250), radius: r, startAngle: Angle(degrees:_start), endAngle: Angle(degrees:_end), clockwise: false)
        path.closeSubpath()
        
        return path
    }
    
}


struct ProgressArc: Shape {
    
    var arcLength : Double
    
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var _start: Double
        var _end: Double
        
        
        
        let r = 45.0
        
        _start =  270.0;
        _end = _start - arcLength;
        
        path.move(to: CGPoint(x: 50, y: 50))
        path.addArc(center: CGPoint(x:50,y:50), radius: r, startAngle: Angle(degrees:_start), endAngle: Angle(degrees:_end), clockwise: true)
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


//let tabs = tabViews()

struct ContentView : View {
    //@StateObject private var viewModel = DynamicTabViewModel()
    //@ObservedObject var delagate = ExtensionDelegate()
    //var locationManager = LocationManager()
    //@ObservedObject var targets = CompassHeading().targetList
    @ObservedObject var viewModel = LocationManager()

    init() {

    }
    var body: some View {
        NavigationView {
            //tabViews()
            
            TabView {
                //if(self.target.targetList.count>0){
                //                ForEach(( 0...self.target.targetList.count-1 ), id: \.self) {i in
                //                    CFTabView(targetIndex:i)
                //                }
                
                
                ForEach((0...viewModel.targetMax-1), id: \.self) {i in
                    CFTabView(targetIndex:i)
                }
                
                //}
                TabView{
                    VStack{
                        Text("add locations on iPhone app")
                        Button("Load Locations") {
                            //self.target.loadData()
                            //self.target.loadDictionary()
                            //tabs.removeFromSuperview()
                        }.buttonStyle(BorderedButtonStyle(tint: .blue))
                    }
                }
            }
            
        }.onAppear(perform: viewAppeared)
    }
}

func viewAppeared(){
    print("main view Appeared")
}

//struct tabViews : View {
//    //@StateObject private var viewModel = DynamicTabViewModel()
//
//    //let target = Target()
//    var body: some View {
//
//    }
//
//}

struct CFTabView : View {
    //var index = 0;
    @ObservedObject var target = Target()
    //@ObservedObject var locationManager = LocationManager()
    //@ObservedObject var locationManager = locationInstance
    
    
    init(targetIndex : Int) {
        self.target.targetIndex = targetIndex
        //index = tIndex
    }
    
    var body: some View {
        
        NavigationView {
            
            ZStack {
                ZStack {
                    
                    //pointer
                    Arrow(spread: self.target.bearingAccuracy)
                        .fill(.yellow)
                    //.stroke(lineWidth: 40)
                    //.fill(style: noFill)
                        .frame(width: 500, height: 500)
                        .rotationEffect(Angle(degrees: self.target.bearing))
                    
                    
                    //compass
                    ForEach(Marker.markers(), id: \.self) { marker in
                        CompassMarkerView(marker: marker,
                                          compassDegress: self.target.heading)
                    }
                    
                    
                    
                }
                .frame(width: 500,
                       height: 500)
                .rotationEffect(Angle(degrees: self.target.heading))
                
                
                
                
                ZStack {
                    
                    //cyan arc
                    ProgressArc(arcLength:  self.target.progress)
                        .fill(.cyan)
                        .frame(width: 100, height: 100)
                    
                    
                    //distance background
                    Circle()
                        .fill(.white)
                        .frame(width: 70, height: 70)
                    
                    
                    
                    //distance
                    Text(self.target.distanceText)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.black)
                        .frame(width:300)
                        .monospacedDigit()
                    
                    
                    
                    //units
                    Text(self.target.unitText)
                        .baselineOffset(-40)
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(.black)
                    
                        .frame(width:60)
                        .monospacedDigit()
                    
                }
                
                ZStack {
                    
                    //targetname
                    Text(self.target.targetName.uppercased())
                        .font(.system(size: 16))
                        .frame(width:400)
                        .monospacedDigit()
                    
                    
                }.frame(width: 500,
                        height: 500)
                .offset(x:0, y: 90)
                
            }.frame(width: 500,
                    height: 500)
            .offset(x:0, y: 5) //offset to center because of tabview dots
            .onTapGesture(){
                //switch units
                self.target.unitsMetric = !self.target.unitsMetric
            }
            
            
            
            
            //            .onTapGesture(count: 1){
            //                //next location. testing
            //                self.compassHeading.targetIndex += 1
            //                if(self.compassHeading.targetIndex >= self.compassHeading.targetMax){
            //                    self.compassHeading.targetIndex = 0
            //                }
            //            }
            
        }.onAppear(perform: tabAppeared)
        //.navigationTitle(self.compassHeading.targetName.uppercased())
        //.navigationBarTitleDisplayMode(.inline)
    }
    
    func tabAppeared(){
        self.target.loadDictionary()
        print("tabAppeared")
        
    }
    
}





struct Previews_ContentView_Previews: PreviewProvider {
    static var previews: some View {
        //Text("hello")
        ContentView()
            .preferredColorScheme(.dark)
    }
}


//tabs
//struct TabItem: Identifiable {
//    let id = UUID()
//    let lat: String
//    let lng: String
//    let address: String
//    let searchedText: String
//    let tag: Int
//
//}
//
//final class DynamicTabViewModel: ObservableObject {
//    @Published var tabItems: [TabItem] = []
//    @Published var tabCount = 1
//
//    func addTabItem() {
//        tabItems.append(TabItem(lat: "55.5", lng: "44.4", address: "123", searchedText: "test", tag: tabCount))
//        tabCount += 1
//    }
//
//    func removeTabItem() {
//        tabItems.removeLast()
//        tabCount -= 1
//    }
//}




