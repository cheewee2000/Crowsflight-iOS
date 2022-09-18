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

struct ContentView : View {
    @StateObject private var viewModel = tabViewModel
    @State private var showDetails = settings.showInstructions
    //@State private var selectedTab = settings.currentTargetIndex
    @State private var selectedTab = 0
    
    init() {
        //viewModel.addTabItem
        //print(tabViewModel.count)
        
    }
    
    
    var body: some View {
        
        NavigationView {
            
            TabView(selection: $selectedTab) {
            //TabView() {
                if(showDetails && settings.showInstructions){
                    Text("Welcome to Crowsflight. Swipe to choose locations.")
                }
                
                ForEach(viewModel.tabItems) { item in
                    CFTabView(targetIndex:item.tag ?? 0)
                }
                
                if(viewModel.tabItems.count == 0 ){
                    Text("No locations to display. Open the Crowsflight iPhone app to edit and sync locations.")
                }
                if(showDetails && settings.showInstructions){
                    //if(0 == 0){
                    VStack{
                        Text("Open the iPhone Crowsflight App to edit and sync locations.")
                        Text(" ")
                        Button("Dismiss") {
                            showDetails.toggle()
                            //showDetails = false
                            settings.showInstructions = false
                            ExtensionDelegate().saveSettings()
                        }.buttonStyle(BorderedButtonStyle(tint: .blue))
                    }
                    .transition(.slide)
                }
            }
        }
    }
}


func viewAppeared(){
    print("main view Appeared")
}



struct CFTabView : View {
    //var index = 0;
    @ObservedObject var destination = Target()
    var tIndex = 0
    
    init(targetIndex : Int) {
        tIndex = targetIndex
        //self.target.targetIndex = targetIndex
        //print(targetIndex)
        if(tIndex < tabViewModel.tabItems.count){
            self.destination.targetName = tabViewModel.tabItems[tIndex].searchedText
            self.destination.target = CLLocation(latitude:  tabViewModel.tabItems[tIndex].lat, longitude: tabViewModel.tabItems[tIndex].lng)
        }
        //print("init CFTabView")
    }
    
    var body: some View {
        
        NavigationView {
            
            ZStack {
                ZStack {
                    
                    //pointer
                    Arrow(spread: self.destination.bearingAccuracy)
                        .fill(.yellow)
                    //.stroke(lineWidth: 40)
                    //.fill(style: noFill)
                        .frame(width: 500, height: 500)
                        .rotationEffect(Angle(degrees: self.destination.bearing))
                    
                    
                    //compass
                    ForEach(Marker.markers(), id: \.self) { marker in
                        CompassMarkerView(marker: marker,
                                          compassDegress: self.destination.heading)
                    }
                    
                    
                    
                }
                .frame(width: 500,
                       height: 500)
                .rotationEffect(Angle(degrees: self.destination.heading))
                
                
                
                
                ZStack {
                    //cyan arc
                    ProgressArc(arcLength:  self.destination.progress)
                        .fill(.cyan)
                        .frame(width: 100, height: 100)
                    
                    
                    //distance background
                    Circle()
                        .fill(.white)
                        .frame(width: 70, height: 70)
                    
                    
                    
                    //distance
                    Text(self.destination.distanceText)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.black)
                        .frame(width:300)
                        .monospacedDigit()
                    
                    
                    
                    //units
                    Text(self.destination.unitText)
                        .baselineOffset(-40)
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(.black)
                    
                        .frame(width:60)
                        .monospacedDigit()
                    
                }
                
                ZStack {
                    
                    //targetname
                    Text(self.destination.targetName.uppercased())
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
                //self.destination.unitsMetric = !self.destination.unitsMetric
                settings.unitsMetric = !settings.unitsMetric
                self.destination.calculateDistance() //force update unit display
                ExtensionDelegate().saveSettings()
            }
            
            
            
            
            //            .onTapGesture(count: 1){
            //                //next location. testing
            //                self.compassHeading.targetIndex += 1
            //                if(self.compassHeading.targetIndex >= self.compassHeading.targetMax){
            //                    self.compassHeading.targetIndex = 0
            //                }
            //            }
            
        }.onAppear(perform: tabAppeared)
            .tag(tIndex)
        //.navigationTitle(self.compassHeading.targetName.uppercased())
        //.navigationBarTitleDisplayMode(.inline)
    }
    
    func tabAppeared(){
        self.destination.calculateDistance() //force update unit display
        
    }
    
}





struct Previews_ContentView_Previews: PreviewProvider {
    static var previews: some View {
        //Text("hello")
        ContentView()
    }
}





