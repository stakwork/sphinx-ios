//
//  VoIPPushMessage.swift
//  sphinx
//
//  Created by James Carucci on 2/27/23.
//  Copyright © 2023 sphinx. All rights reserved.
//
import Foundation

public class VoIPPushMessage : Codable{
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //try container.encode(self.body, forKey: .body)
        try container.encode(self.type, forKey: .type)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        //let callerName = try values.decode(String.self, forKey: .callerName)
        //let linkURL = try values.decode(String.self, forKey: .linkURL)
        
        let type = try values.decode(String.self, forKey: .type)
        let body = try values.decode(VoIPPushMessageBody.self, forKey: .body)
        
        self.body = body
        self.type = type
    }
    
    public var type: String
    public var body: AnyObject
    
    init(
        date:String,
        type:String,
        body:AnyObject
    ) {
        self.body = body
        self.type = type
    }
    
    
    static func voipMessage(jsonString: String) -> VoIPPushMessage? {
        let data = Data(jsonString.utf8)
        let jsonDecoder = JSONDecoder()
        var voipMessage: VoIPPushMessage! = nil
        do {
            voipMessage = try jsonDecoder.decode(VoIPPushMessage.self, from: data)
        } catch let error {
            print(error.localizedDescription)
            print(String(describing: error))
            return nil
        }
        return voipMessage
    }
}


extension VoIPPushMessage {
    enum CodingKeys: String, CodingKey {
        case body = "body"
        case type = "type"
    }
}



public class VoIPPushMessageBody : Codable{
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.linkURL, forKey: .linkURL)
        try container.encode(self.callerName, forKey: .callerName)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let callerName = try values.decode(String.self, forKey: .callerName)
        let linkURL = try values.decode(String.self, forKey: .linkURL)

        self.linkURL = linkURL
        self.callerName = callerName
        
    }
    
    public var callerName: String
    public var linkURL: String
    
    func isVideoCall() -> Bool {
        return !linkURL.contains("startAudioOnly=true")
    }
    
    init(
        callerName: String,
        linkURL: String
    ) {
        self.callerName = callerName
        self.linkURL = linkURL
    }
    
    
    static func voIPMessageBody(jsonString: String) -> VoIPPushMessage? {
        let data = Data(jsonString.utf8)
        let jsonDecoder = JSONDecoder()
        var voipMessage: VoIPPushMessage! = nil
        do {
            voipMessage = try jsonDecoder.decode(VoIPPushMessage.self, from: data)
        } catch let error {
            print(error.localizedDescription)
            print(String(describing: error))
            return nil
        }
        return voipMessage
    }
    
}


extension VoIPPushMessageBody {
    enum CodingKeys: String, CodingKey {
        case linkURL = "link_url"
        case callerName = "caller_name"
    }
}
