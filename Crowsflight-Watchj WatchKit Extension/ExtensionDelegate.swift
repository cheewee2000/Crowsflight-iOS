import WatchKit
import WatchConnectivity


var settings = Settings(unitsMetric: true, currentTargetIndex: 0, showInstructions: true)


//settings
struct Settings:  Decodable, Encodable {
    var unitsMetric: Bool
    var currentTargetIndex: Int
    var showInstructions: Bool
}

class ExtensionDelegate: NSObject, ObservableObject, WKExtensionDelegate, WCSessionDelegate {
    
    func applicationDidFinishLaunching() {
        print("watch launched")
        loadSettings()

        setupWatchConnectivity()
        loadLocations()
    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WC Session activation failed with error: " + "\(error.localizedDescription)")
            return
        }
        print("WC Session activated with state: \(activationState.rawValue)")
    }
    
    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext:[String:Any]) {
        if let data = applicationContext["data"] as? [String] {
            print(data)
            DispatchQueue.main.async {
                WKInterfaceController.reloadRootPageControllers( withNames: ["SomeController"], contexts: nil,
                                                                 orientation: WKPageOrientation.vertical, pageIndex: 0)
            }
        }
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        print("Received File with URL: \(file.fileURL)")
        print("Outstanding file transfers: \(WCSession.default.outstandingFileTransfers)")
        print("Has content pending: \(WCSession.default.hasContentPending)")
        
        let array=(NSArray(contentsOf:file.fileURL) as? [[String:Any]])!
        if(!array.isEmpty){
            print(array)
            let list=(NSArray(contentsOf: file.fileURL) as? [[String:Any]])!
            saveData(list);
            loadArrayToStruct(list: list)
        }
    }
    
    func session(_session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        print("file transfer complete")
        print("error: ", error as Any)
    }
    
        func loadArrayToStruct(list : [[String:Any]] ){
        tabViewModel.tabItems.removeAll()
        
        //save to struct
        var count = 0
        for item in list {
            //print(item)
            let target = TabItem(lat: item["lat"] as! Double, lng: item["lng"] as! Double, address: "", searchedText: item["searchedText"] as! String, tag: count)
            tabViewModel.tabItems.append(target)
            count += 1
        }
        
        //save to defaults
        UserDefaults.standard.set(try? PropertyListEncoder().encode(tabViewModel.tabItems), forKey:"locations")
    }
    
    
    func loadLocations(){
        if let data = UserDefaults.standard.value(forKey:"locations") as? Data {
            tabViewModel.tabItems = try! PropertyListDecoder().decode(Array<TabItem>.self, from: data)
        }
    }
    

    func loadSettings(){
        if let data = UserDefaults.standard.value(forKey:"settings") as? Data {
            settings = try! PropertyListDecoder().decode(Settings.self, from: data)
        }
    }
    
    func saveSettings(){
        //save to defaults
        UserDefaults.standard.set(try? PropertyListEncoder().encode(settings), forKey:"settings")
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
}

