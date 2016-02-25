//
//  ViewController.swift
//  Nearables
//
//  Created by Greg Dowling on 23/02/2016.
//  Copyright © 2016 Greg Dowling. All rights reserved.
//

import UIKit
import CocoaMQTT

let HOST: String = "localhost"
let PORT: UInt16 = 1883
let SECURE = false

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
        for (name, id) in beaconsToInitialize {
            beaconDict[name] = Nearable(id: id, name: name)
        }
        
        for (_, beacon) in beaconDict
        {
            let rule = ESTMotionRule.motionStateEquals(
                true, forNearableIdentifier: beacon.id)
            let trigger = ESTTrigger(rules: [rule], identifier: "\(beacon.name)")
            self.triggerManager.startMonitoringForTrigger(trigger)
        }
        
        let inset = UIEdgeInsetsMake(20, 0, 0, 0);
        self.tableView.contentInset = inset;
        self.mqttSetting()
    }
    
    func mqttSetting() {
        let clientIdPid = "NearablesApp-" + String(NSProcessInfo().processIdentifier)
        mqtt = CocoaMQTT(clientId: clientIdPid, host: HOST, port: PORT)
        if let mqtt = mqtt {
            mqtt.username = "test"
            mqtt.password = "public"
            mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
            mqtt.keepAlive = 90
            mqtt.secureMQTT = SECURE
            mqtt.delegate = self
            mqtt.connect()
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
            
            if let mqtt = mqtt {
                beacon.publish(mqtt)
            }
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
        let beacon = beaconArray[indexPath.row]
        if let mqtt = mqtt {
            beacon.publish(mqtt)

        }
    }
}


extension ViewController: CocoaMQTTDelegate {
    
    func mqtt(mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    func mqtt(mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck \(ack.rawValue)")
        if ack == .ACCEPT {
        }
        
    }
    
    func mqtt(mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(message.string)")
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
