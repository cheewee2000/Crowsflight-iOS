


import Foundation
import Combine
//import CoreLocation
import WatchKit
import SwiftUI


//struct target: Identifiable {
//    let lat: Double
//    let lng: Double
//    let searchedText: String
//}


class LocationManager: NSObject, ObservableObject{
    //var extensionDelegate = ExtensionDelegate();

    var objectWillChange = PassthroughSubject<Void, Never>()
    
    var heading: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var lat: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var lng: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    var bearing: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }

    var horizontalAccuracy: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var headingAccuracy: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var here: CLLocation = .init(latitude: 0, longitude: 0) {
        didSet {
            objectWillChange.send()
        }
    }
    

    var targetMax: Int = 1 {
        didSet {
            objectWillChange.send()
        }
    }
    
    var targetList : Array = [Any]() {
        didSet {
            objectWillChange.send()
        }
    }
    
    
//    @Published var targetList: Array = []

    
    var list : Array = [Any]() {
        didSet {
            objectWillChange.send()
        }
    }
    
    
    var defaultTargetList : Array =      [
        ["searchedText": "BOTA",
         "lat": 42.460549,
         "lng": 18.766894,
         "address": ""]
        ,
        ["searchedText": "POLIEGOS",
         "lat": 36.774635,
         "lng": 24.641630,
         "address": ""]
        ,
        ["searchedText": "TURN 2",
         "lat": 36.8087908,
         "lng": 24.5551709,
         "address": ""]
        ,
        ["searchedText": "SKIADI",
         "lat": 36.8091440,
         "lng": 24.5392309,
         "address": ""]
        
    ]
    
    func loadData() {
//        let path = self.dataFilePath() as String
//        let defaultManager = FileManager()
//
//        //print(path)
//        if defaultManager.fileExists(atPath: path) {
//            print("path exists")
//            let url = URL(fileURLWithPath: path)
//            print (url)
//            let arr = NSArray(contentsOfFile: path) as? [Any]
//            self.targetList = arr ?? self.defaultTargetList
//            self.targetMax = self.targetList.count
//
//
//        }
//
//        var tabStructArray = functionsStruct()
//        tabs.add(item:tabStructArray[0])
//        tabs.add(item:tabStructArray[1])
//        tabs.add(item:tabStructArray[3])
//
//
        
        
    }
    
    

    
    
//    private let locationManager: CLLocationManager
    
    override init() {
        //self.targetIndex = targetIndex
        
        //self.locationManager = CLLocationManager()
        super.init()
        //self.locationManager.delegate = self
        self.setup()

    }
    
    
    private func setup() {
//        self.locationManager.requestWhenInUseAuthorization()
//
//        if CLLocationManager.headingAvailable() {
//            self.locationManager.startUpdatingLocation()
//            self.locationManager.startUpdatingHeading()
//        }
        
        //let extensionDelegate = ExtensionDelegate();
        loadData()
        //print("target setup complete")
    }
    
    

    
//    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        self.heading = -1 * newHeading.trueHeading
//        self.headingAccuracy = newHeading.headingAccuracy
//    }
//
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//
//        let location = locations[0]
//
//        self.lat = location.coordinate.latitude
//        self.lng = location.coordinate.longitude
//
//        if(self.lat != 0 && self.lng != 0){
//            self.here = CLLocation(latitude:self.lat, longitude: self.lng)
//        }
//
//        self.horizontalAccuracy = location.horizontalAccuracy
//
//    }
    
//
//    func getBearing(L1: CLLocation,  L2: CLLocation) -> Double{
//
//        let lat1 = (L1.coordinate.latitude / 180.0 * Double.pi);
//        let lat2 = (L2.coordinate.latitude / 180.0 * Double.pi);
//        let dLon = (L2.coordinate.longitude / 180.0 * Double.pi) - (L1.coordinate.longitude / 180.0 * Double.pi);
//        let y = sin(dLon) * cos(lat2);
//        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
//        let brng = atan2(y, x);
//
//        let bearing = Int(brng * (180.0 / Double.pi) + 360.0) % 360;
//
//
//        return Double(bearing)
//    }
    
    

}
