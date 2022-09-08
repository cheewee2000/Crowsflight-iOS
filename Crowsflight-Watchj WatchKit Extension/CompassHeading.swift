//
//  Compass.swift
//  Compass
//
//  Created by ProgrammingWithSwift on 2019/10/06.
//  Copyright © 2019 ProgrammingWithSwift. All rights reserved.
//

import Foundation
import Combine
import CoreLocation
import WatchConnectivity
import WatchKit

class CompassHeading: NSObject, ObservableObject, CLLocationManagerDelegate{
    
   
    
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
    var distance: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var distanceText: String = "" {
        didSet {
            objectWillChange.send()
        }
    }
    
    var unitText: String = "" {
        didSet {
            objectWillChange.send()
        }
    }
   
    var headingAccuracy: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    var bearingAccuracy: Double = .zero {
        didSet {
            objectWillChange.send()
        }
    }
    
    var here: CLLocation = .init(latitude: 0, longitude: 0) {
        didSet {
            objectWillChange.send()
        }
    }
    
    var target: CLLocation = .init(latitude: 0, longitude: 0) {
        didSet {
            objectWillChange.send()
        }
    }
    
    var targetName: String = "LOADING" {
        didSet {
            objectWillChange.send()
        }
    }
    
    var unitsMetric: Bool = true {
        didSet {
            objectWillChange.send()
        }
    }
    var progress: Double = 0.0 {
        didSet {
            objectWillChange.send()
        }
    }
    
    var targetIndex: Int = 0 {
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
        ["searchedText": "ROAD TO TURN",
         "lat": 36.7967806,
         "lng": 24.5681360,
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
          ,
        ["searchedText": "LOVCEN",
         "lat": 42.398985,
         "lng": 18.818506,
           "address": ""]

           ]
    
    func loadData() {
            let path = self.dataFilePath()
            let defaultManager = FileManager()
            //var arr = [locations]()
        
        //print(path)
            if defaultManager.fileExists(atPath: path) {
                print("path exists")

             
                let url = URL(fileURLWithPath: path)
                //let data = try! Data(contentsOf: url)
                
                print (url)
                let arr = NSArray(contentsOfFile: path) as? [Any]


                
                self.targetList = arr ?? self.defaultTargetList

            }
        }
    
    func documentsDirectory()->String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths.first!
        return documentsDirectory
    }

    func dataFilePath ()->String{
        return self.documentsDirectory().appendingFormat("/locationList.plist")
    }

    func saveData(_ locations : [[String:Any]]) {
           let archiver = NSKeyedArchiver(requiringSecureCoding: true)
           archiver.encode(locations, forKey: "locationList")
           let data = archiver.encodedData
           try! data.write(to: URL(fileURLWithPath: dataFilePath()))
     }
    
    
    private let locationManager: CLLocationManager
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        self.locationManager.delegate = self
        self.setup()


    }
    
    private func setup() {
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.headingAvailable() {
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        }
        
        //let extensionDelegate = ExtensionDelegate();
        loadData()

        loadDictionary()
        

        print("setup complete")
    }
    
    
    func loadDictionary(){

         let targetDictionary = self.targetList[targetIndex]  as? [String: Any];

        if(targetDictionary == nil){
            return
        }

        self.targetName = targetDictionary?["searchedText"] as! String
        
        print (self.targetName)

//        print (targetDictionary?["lat"])
//        print (targetDictionary?["lng"])

        
        let lat = targetDictionary?["lat"] as? Double ?? 0.0
        print(lat)
        
        let lng = targetDictionary?["lng"] as? Double ?? 0.0
        print(lng)
        

        self.target = CLLocation(latitude: lat  , longitude: lng  )

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = -1 * newHeading.trueHeading
        self.headingAccuracy = newHeading.headingAccuracy
    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //loadData()
        
      //print("LocationManager didUpdateLocations: numberOfLocation: \(locations.count)")
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
      
        
    loadDictionary()

        
      locations.forEach { (location) in
        //print("LocationManager didUpdateLocations: \(dateFormatter.string(from: location.timestamp)); \(location.coordinate.latitude), \(location.coordinate.longitude)")
//        print("LocationManager altitude: \(location.altitude)")
        //print("LocationManager horizontalAccuracy: \(location.horizontalAccuracy)")


          self.lat = location.coordinate.latitude
          self.lng = location.coordinate.longitude
          
          if(self.lat != 0 && self.lng != 0){
              self.here = CLLocation(latitude:self.lat, longitude: self.lng)
          }
                    
          self.targetMax = self.targetList.count
          
        //pull from dictionary
          if(self.targetList.count<1){
              return
          }
                
          
 
          //measure distance
          self.distance = here.distance(from: self.target)

          //always update distance
          if(self.unitsMetric == false){
              let miles = self.distance*0.000621371
              let feet = self.distance*3.28084
                if(feet<1000){ //.25 miles in meters
                    self.distanceText = String (format:"%.0f",feet);
                    self.unitText="FEET";

                }else if(miles<1000){
                    self.distanceText = String (format:"%.02f",miles);
                    self.unitText="MILES";
                }
              else if(miles<10000){
                  self.distanceText = String (format:"%.01f",miles);
                  self.unitText="MILES";
              }
              else {
                  self.distanceText = String (format:"%.0f",miles);
                  self.unitText="MILES";
              }
            }
            else {

          
          if(self.distance<1000){
              self.distanceText = String(format:"%.0f", self.distance)
              self.unitText = "METERS";
                  
                  
              }else if(self.distance<10000){
                  self.distanceText = String(format:"%.02f", self.distance/1000.0)
                  self.unitText="KM";
                  
              }
          else  if(self.distance<100000) {
              self.distanceText = String(format:"%.01f", self.distance/1000.0)
              self.unitText="KM";
              
          }
          else{
              self.distanceText = String(format:"%.0f", self.distance/1000.0)
              self.unitText="KM";
              
          }
          }
          
          
          
          //measure bearing
          self.bearing = getBearing(L1: self.here, L2: self.target)
          //print("bearing: \(self.bearing)")
          
          //bearing accuracy
          let offset = self.bearing+90.0;
          
          let xMeters=Double(cosf(Float(offset / 180.0 * Double.pi))) * location.horizontalAccuracy;
          let yMeters=Double(sinf(Float(offset / 180.0 * Double.pi))) * location.horizontalAccuracy;
          
          //111111 meters / degree (approximate) +- 10m
          let olat1 = self.lat+xMeters/111111.0;
          let olng1 = self.lng+yMeters/111111.0;
          
          let oLoc =  CLLocation.init(latitude: olat1, longitude: olng1)
          let altBearing = getBearing(L1: oLoc, L2: self.target)

          let bearingAccuracy = Int(bearing-altBearing + 360) % 360;
          
          self.bearingAccuracy=self.headingAccuracy + Double(bearingAccuracy)
          
          if(self.bearingAccuracy <= 1.0){self.bearingAccuracy = 60.0};
          if(self.bearingAccuracy > 180.0){self.bearingAccuracy = 180.0};
          
          //print("accuracy: \(self.bearingAccuracy)")

          //calculate progress
          self.progress = ((log(1+self.distance)/log(100)) * 0.275 - 0.2) * 360.0;

          
          
//        print("LocationManager verticalAccuracy: \(location.verticalAccuracy)")
//        print("LocationManager speedAccuracy: \(location.speedAccuracy)")
//        print("LocationManager speed: \(location.speed)")
//        print("LocationManager timestamp: \(location.timestamp)")
//        print("LocationManager courseAccuracy: \(location.courseAccuracy)") // 13.4
//        print("LocationManager course: \(location.course)")
      }
    }
    
    
    func getBearing(L1: CLLocation,  L2: CLLocation) -> Double{
           
        let lat1 = (L1.coordinate.latitude / 180.0 * Double.pi);
        let lat2 = (L2.coordinate.latitude / 180.0 * Double.pi);
        let dLon = (L2.coordinate.longitude / 180.0 * Double.pi) - (L1.coordinate.longitude / 180.0 * Double.pi);
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let brng = atan2(y, x);
        
        let bearing = Int(brng * (180.0 / Double.pi) + 360.0) % 360;
        
        
        return Double(bearing)
    }

}





