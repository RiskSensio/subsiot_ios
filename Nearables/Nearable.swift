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
    var motion: Bool
    
    init(id: String, name: String){
        self.id = id
        self.name = name
        self.motion = false
    }
    
    public var description: String {
        return "Nearable: \(self.name) \(self.id) motion:\(self.motion)"
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
    }
    
    public func publish( mqtt: CocoaMQTT){
        let publishDict = [
            "id": self.id,
            "name": self.name,
            "motion": self.motion
        ]
        
        do {
            let json = try NSJSONSerialization.dataWithJSONObject(publishDict, options: [] )
            
            let count = json.length / sizeof(UInt8)
            var data = [UInt8](count: count, repeatedValue: 0)
            json.getBytes(&data, length:count * sizeof(UInt8))
            
            let message = CocoaMQTTMessage(topic: "name", payload: data)
            mqtt.publish(message )
         } catch {
            print("Nearable::updateMotion: JSON conversion error")
         }
        }
}