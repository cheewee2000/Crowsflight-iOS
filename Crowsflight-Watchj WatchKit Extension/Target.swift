//
//  Compass.swift
//  Compass
//
//  Created by ProgrammingWithSwift on 2019/10/06.
//  Copyright © 2019 ProgrammingWithSwift. All rights reserved.
//

//todo
/*
 Save index and unit preference to default settings
 
 Reload everything when view appears
 
 Last page of instructions
 Set to the front most app
 
 Long press to save current location
 Check if iCloud backup exists and download if it does
 */

import Foundation
import Combine
import CoreLocation
import WatchConnectivity
import WatchKit

class Target: NSObject, ObservableObject, CLLocationManagerDelegate{
    //var extensionDelegate = ExtensionDelegate();
    //var locationManager = LocationManager()
    
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
        let path = self.dataFilePath()
        let defaultManager = FileManager()

        //print(path)
        if defaultManager.fileExists(atPath: path) {
            print("path exists")
            let url = URL(fileURLWithPath: path)
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
        //self.targetIndex = targetIndex

        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.setup()

    }
    
    //    init(targetIndex : Int) {
    //        self.targetIndex = targetIndex
    ////        index = targetIndex
    //       }
    
    
    private func setup() {
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.headingAvailable() {
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        }
        
        //let extensionDelegate = ExtensionDelegate();
        loadData()
        loadDictionary()
        
        calculateBearing()
        calculateDistance()

        print("target setup complete")
        print(self.targetName)
    }
    
    
    func loadDictionary(){
        //let locationManager = LocationManager()
        if(self.targetList.count<1){
            return
        }
        let targetDictionary = self.targetList[targetIndex]  as? [String: Any];
        
        if(targetDictionary == nil){
            return
        }
        
        self.targetName = targetDictionary?["searchedText"] as! String
        
        //print (self.targetName)
        //        print (targetDictionary?["lat"])
        //        print (targetDictionary?["lng"])
        
        
        let lat = targetDictionary?["lat"] as? Double ?? 0.0
        //print(lat)
        
        let lng = targetDictionary?["lng"] as? Double ?? 0.0
        //print(lng)
        
        //print("locations loaded")
        self.target = CLLocation(latitude: lat  , longitude: lng  )
        

    }
    

    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = -1 * newHeading.trueHeading
        self.headingAccuracy = newHeading.headingAccuracy
        calculateBearing()
        calculateDistance()

    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        let location = locations[0]
        
        self.lat = location.coordinate.latitude
        self.lng = location.coordinate.longitude
        
        if(self.lat != 0 && self.lng != 0){
            self.here = CLLocation(latitude:self.lat, longitude: self.lng)
        }

        self.horizontalAccuracy = location.horizontalAccuracy
        calculateBearing()
        calculateDistance()
    }
    
    
    
    
    func calculateDistance() {
        
        let lat = self.lat
        let lng = self.lng
        
        if(lat != 0 && lng != 0){
            self.here = CLLocation(latitude:lat, longitude: lng)
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

        

            //calculate progress
            self.progress = ((log(1+self.distance)/log(100)) * 0.275 - 0.2) * 360.0;
 
        }
    }
    
    
    
    
    func calculateBearing(){
        //let locationManager = LocationManager()

        //measure bearing
        self.bearing = getBearing(L1: self.here, L2: self.target)
        //print("bearing: \(self.bearing)")
        
        //bearing accuracy
        let offset = self.bearing+90.0;
        
        let xMeters=Double(cosf(Float(offset / 180.0 * Double.pi))) * self.horizontalAccuracy;
        let yMeters=Double(sinf(Float(offset / 180.0 * Double.pi))) * self.horizontalAccuracy;
        
        //111111 meters / degree (approximate) +- 10m
        let olat1 = self.lat+xMeters/111111.0;
        let olng1 = self.lng+yMeters/111111.0;
        
        
        let _lat1 = olat1
        let _lng1 = olng1
        let _lat2 = self.target.coordinate.latitude
        let _lng2 = self.target.coordinate.longitude
        
        let lat1 = (_lat1 / 180.0 * Double.pi)
        let lat2 = (_lat2 / 180.0 * Double.pi)
        let dLon = (_lng2 / 180.0 * Double.pi) - (_lng1 / 180.0 * Double.pi)
        
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let brng = atan2(y, x);
        let altBearing = Int(brng * (180.0 / Double.pi) + 360) % 360;
        
        let bearingAccuracy = Int(self.bearing - Double(altBearing) + 360) % 360;
        
        self.bearingAccuracy = self.headingAccuracy + Double(bearingAccuracy)
        
        if(self.bearingAccuracy <= 1.0){self.bearingAccuracy = 20.0};
        if(self.bearingAccuracy > 180.0){self.bearingAccuracy = 180.0};
        
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




