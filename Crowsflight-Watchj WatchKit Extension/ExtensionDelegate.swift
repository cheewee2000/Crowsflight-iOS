import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, ObservableObject, WKExtensionDelegate {
    
    func applicationDidFinishLaunching() {
        setupWatchConnectivity()
        print("watch launched")
    }
    
    var list : Array = [Any]() {
        didSet {
            objectWillChange.send()
        }
    }
    
}

extension ExtensionDelegate : WCSessionDelegate {
    
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

        
        //self.fileURL = file.fileURL
        
        let array=(NSArray(contentsOf:file.fileURL) as? [Any])!
        if(!array.isEmpty){
            print(array)
            self.list=(NSArray(contentsOf: file.fileURL) as? [Any])!
            saveData(self.list);

        }
        
        
    }
    
    func session(_session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        print("file transfer complete")
        print("error: ", error as Any)
    }
    
    
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        // just send back the first one, which ought to be the only one
        return paths[0]
    }
    

    func dataFilePath ()->URL{
        return self.getDocumentsDirectory().appendingPathComponent("locationList.plist")
    }
    
    func saveData(_ locations : [Any]) {
        (locations as NSArray).write(to: dataFilePath(), atomically: true)
        print("saved list to file")
        print(dataFilePath())
        
        //restart ContentView
        
     }
    
    
}
