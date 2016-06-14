//
//  ViewController.swift
//  Nearables
//
//  Created by Greg Dowling on 23/02/2016.
//  Copyright © 2016 Greg Dowling. All rights reserved.
//

import UIKit
import CocoaMQTT

class ViewController: UIViewController, ESTTriggerManagerDelegate, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var tableView: UITableView!
    
    let triggerManager = ESTTriggerManager()
    
    let beaconsToInitialize:[String: String] = [
//        "generic": "0c2c5211518bf1c1",
        "shoe": "4a975635090429cc",
        "fridge": "7efbd1ffdbcf6fb6",
//        "chair": "5236196e81f359fd",
//        "keys": "6f5f658b0ac6c3c3",
//        "bike": "0d307207d56db10a",
        "door": "73125629c76f4925",
        "bed": "79546c411374882e",
        "car": "415f37c75e5ccf92",
        "dog": "de7060c7ff7cea46",
    ]
    
    var beaconDict = [String: Nearable]()
    
    var mqtt: CocoaMQTT?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.triggerManager.delegate = self
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
            
        // Create the beacon objects
        let beacons = [
            Nearable(id:"4a975635090429cc",
                name: "Westminster(shoe)",
                user: "db57d5fa-bd4c-49c4-b0bf-62dc3e76ef84",
                password:"ictPDjoyQ6_e" ),
            Nearable(
                id: "7efbd1ffdbcf6fb6",
                name: "FCA (fridge)",
                user: "fddd8173-2a23-478f-b165-f0fc4e127ab2",
                password: "xV40f2Xi.VAw"),
            Nearable(
                id: "73125629c76f4925",
                name: "Deutsche (door)",
                user: "0ff32a44-6bd8-4aad-bef7-9327887e8003",
                password: "owNXJM4VPTE9"
            ),
            Nearable(
                id: "79546c411374882e",
                name: "TFL (bed)",
                user: "ebff6be5-c141-42e8-a892-d16f9f7c2e7a",
                password: "zpTsJLLGgl4N"
            ),
            Nearable(
                id: "415f37c75e5ccf92",
                name: "Britinsur (car)",
                user: "aa8c2b64-35f2-4939-8798-7d3a48f814f8",
                password:"NdCggrrzUZFf"
            ),
            Nearable(
                id: "de7060c7ff7cea46",
                name: "Hoxton (dog)",
                user: "82342961-c1f4-41e5-86fa-54dd17138695",
                password: "tZiPC5QnGy8y"
            )
//            Nearable(
//                id: "79546c411374882e",
//                name: "bed",
//                user: "277e930c-4d8d-4bf3-bcff-beddafd51647",
//                password: "Ncj9sI1spoqr"
//            ),
//            Nearable(
//                id: "415f37c75e5ccf92",
//                name: "car",
//                user: "1a0674b8-b48b-42b3-9d09-4e06e7fdd83f",
//                password: "r9TZwh6iLm_f"
//            ),
//            Nearable(id: "de7060c7ff7cea46", name: "dog", client_id: "TteH/YImbTAqiqvNWyM0wyA")
//            Nearable(id: "6f5f658b0ac6c3c3", name: "keys", client_id: "TteH/YImbTAqiqvNWyM0wyA"),
        ]

        
        for beacon in beacons {
            beaconDict[beacon.name] = beacon
        }
        
        for (_, beacon) in beaconDict
        {
            let rule = ESTMotionRule.motionStateEquals(
                true, forNearableIdentifier: beacon.id)
            let trigger = ESTTrigger(rules: [rule], identifier: "\(beacon.name)")
            self.triggerManager.startMonitoringForTrigger(trigger)
        }
        
        
        var _ = NSTimer.scheduledTimerWithTimeInterval(
            2, target: self, selector: #selector(ViewController.updateTimer), userInfo: nil, repeats: true)
        
        let inset = UIEdgeInsetsMake(20, 0, 0, 0);
        self.tableView.contentInset = inset;
    }
    
    func updateTimer() {
        let beaconArray = Array(beaconDict.values)
        for beacon in beaconArray{
            beacon.publish()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func triggerManager(manager: ESTTriggerManager,
        triggerChangedState trigger: ESTTrigger) {

            let beacon = beaconDict[trigger.identifier]!
            beacon.updateMotion(trigger.state)
            print("Trigger from \(beacon)")
            
            beacon.publish()
        
            self.tableView.reloadData()
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.beaconDict.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        
        let beaconArray = Array(beaconDict.values)
        cell.textLabel?.text = beaconArray[indexPath.row].friendlyText
        
        return cell

    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("You selected cell #\(indexPath.row)!")
        let beaconArray = Array(beaconDict.values)
        beaconArray[indexPath.row].publish()
    }
}


extension ViewController: CocoaMQTTDelegate {
    
    func mqtt(mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    func mqtt(mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck \(ack.rawValue)")
        if ack == .ACCEPT {
            print("connected OK")
        }
        
    }
    
    func mqtt(mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(message.string)")
        print("topic: \(message.topic)")
    }
    
    func mqtt(mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
    }
    
    func mqtt(mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        print("didReceivedMessage: \(message.string) with id \(id)")
    }
    
    func mqtt(mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
    }
    
    func mqtt(mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }
    
    func mqttDidPing(mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    func mqttDidReceivePong(mqtt: CocoaMQTT) {
        _console("didReceivePong")
    }
    
    func mqttDidDisconnect(mqtt: CocoaMQTT, withError err: NSError?) {
        _console("mqttDidDisconnect")
    }
    
    func _console(info: String) {
        print("Delegate: \(info)")
    }
    
}
