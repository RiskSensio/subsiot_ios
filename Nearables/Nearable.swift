//
//  Nearable.swift
//  Nearables
//
//  Created by Greg Dowling on 23/02/2016.
//  Copyright © 2016 Greg Dowling. All rights reserved.
//

import Foundation
import CocoaMQTT

public class  Nearable: CustomStringConvertible
{
    let id: String
    let name: String

    let user: String
    let password: String
    let mqtt: CocoaMQTT
    
    var motion: Bool
    
    var humidity : Float64
    var temperature :Float64
    var vibration: Float64
    
    init(id: String, name: String, user: String, password: String){
        self.id = id
        self.name = name

        self.user = user
        self.password = password
        
        self.motion = false

        self.humidity = 40.0
        self.temperature = 7.0
        self.vibration = 0
        
        self.mqtt = CocoaMQTT(clientId: self.user, host: MQTTBrokerDetails.host, port: MQTTBrokerDetails.port)

        self.mqtt.username = self.user
        self.mqtt.password = self.password
        self.mqtt.port = MQTTBrokerDetails.port
        self.mqtt.keepAlive = 60
        self.mqtt.secureMQTT = false

        self.temperature += 20 * self.rand()
        self.humidity += 25.0 * self.rand()

        self.mqtt.delegate = self
        self.connect()
        
    }
    
    public var description: String {
        return "Nearable: \(self.name) \(self.id) motion:\(self.motion)"
    }
    
    func connect() {
        self.mqtt.connect()
    }

    public var friendlyText: String {
        var desc: String
        if self.motion {
            desc = "moving"
        }
        else {
            desc = "still"
        }
        return "\(self.name):\(desc)"
    }
    
    public func updateMotion(moving: Bool){
        self.motion = moving
  
        self.humidity += 3 * (self.rand() - 0.5)
        if self.humidity < 0.0 {
            self.humidity = 0.0
        }
        
        self.temperature += 0.1 * self.rand() - 0.5
        if self.temperature < 0.0 {
            self.temperature = 0.0
        }
        
        
        if self.motion{
            self.vibration = 750.0 + 500.0 * self.rand()

        }
        else {
            self.vibration = 20.0 * self.rand()
        }
        
        if self.vibration < 5.0 {
            self.vibration = 5.0
        }
    }
    
    func rand()-> Float64{
        return Float64(arc4random()) / 0x100000000
    }
    
    public func publish(){
        self.humidity += self.rand() - 0.5
        self.temperature += 0.1 * self.rand() - 0.05
        
        if self.motion{
            self.vibration = 750.0 + 500.0 * self.rand()
            
        }
        else {
            self.vibration = 20.0 * self.rand()
        }
        
        
        let publishArray = [
            [
                "meaning": "motion",
                "value": self.motion
            ],
            [
                "meaning": "name",
                "value": self.name
            ],
            [
                "meaning": "vibration",
                "value": self.vibration
            ],
            
            [
                "meaning": "temperature",
                "value": self.temperature
            ],

            [
                "meaning": "humidity",
                "value": self.humidity
            ]
        ]
        
        do {
            let json = try NSJSONSerialization.dataWithJSONObject(publishArray, options: [] )
            let count = json.length / sizeof(UInt8)
            var data = [UInt8](count: count, repeatedValue: 0)
            json.getBytes(&data, length:count * sizeof(UInt8))
            
            let topic = "/v1/\(self.user)/" + "data"
            let message = CocoaMQTTMessage(topic: topic, payload: data, retained: true)
            mqtt.publish(message )
         } catch {
            print("Nearable::updateMotion: JSON conversion error")
         }
        }
}


extension Nearable: CocoaMQTTDelegate {
    
    public func mqtt(mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(self) \(host):\(port)")
    }
    
    public func mqtt(mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck \(ack.rawValue)")
        if ack == .ACCEPT {
            print("connected OK")
        }
        
    }
    
    public func mqtt(mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(message.string)")
        print("topic: \(message.topic)")
    }
    
    public func mqtt(mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
    }
    
    public func mqtt(mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        print("didReceivedMessage: \(message.string) with id \(id)")
    }
    
    public func mqtt(mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
    }
    
    public func mqtt(mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }
    
    public func mqttDidPing(mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    public func mqttDidReceivePong(mqtt: CocoaMQTT) {
        _console("didReceivePong")
    }
    
    public func mqttDidDisconnect(mqtt: CocoaMQTT, withError err: NSError?) {
        _console("mqttDidDisconnect")
        self.connect()
    }
    
    func _console(info: String) {
        print("Delegate: \(info)")
    }
    
}