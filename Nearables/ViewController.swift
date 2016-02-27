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
        "generic": "0c2c5211518bf1c1",
        "shoe": "4a975635090429cc",
        "fridge": "7efbd1ffdbcf6fb6",
        "chair": "5236196e81f359fd",
        "keys": "6f5f658b0ac6c3c3",
        "bike": "0d307207d56db10a",
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
            Nearable(id:"0c2c5211518bf1c1",
                name: "generic",
                user: "fa2bb0ad-7610-4eaa-b0ca-10a3bcec1767",
                password:"7eLjm5NYB9De" ),
            Nearable(
                id: "4a975635090429cc",
                name: "shoe",
                user: "b3f3ce5b-770c-408d-9536-36c0599f4f7d",
                password: "IpjPtR0cq69A"),
            Nearable(
                id: "7efbd1ffdbcf6fb6",
                name: "fridge",
                user: "818ec1c6-6c0f-4faf-84e4-57036d53d55e",
                password: "MbCm0I7rwkAA"
            ),
            Nearable(
                id: "5236196e81f359fd",
                name: "chair",
                user: "7f7f055a-7e7c-4cb6-8de1-404bd905fd81",
                password: "qzHw3lxvdYb2"
            ),
            Nearable(
                id: "0d307207d56db10a",
                name: "bike",
                user: "e63c9313-f038-4e2b-a5ea-87d6f22df9fd",
                password:"i0hAVD7LC0xh"
            ),
            Nearable(
                id: "73125629c76f4925",
                name: "door",
                user: "7e5045b1-3bdd-49f2-8a8f-24740ca931b0",
                password: "6rf4Uqg1YM6q"
            ),
            Nearable(
                id: "79546c411374882e",
                name: "bed",
                user: "277e930c-4d8d-4bf3-bcff-beddafd51647",
                password: "Ncj9sI1spoqr"
            ),
            Nearable(
                id: "415f37c75e5ccf92",
                name: "car",
                user: "1a0674b8-b48b-42b3-9d09-4e06e7fdd83f",
                password: "r9TZwh6iLm_f"
            ),
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
            2, target: self, selector: "updateTimer", userInfo: nil, repeats: true)
        
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
