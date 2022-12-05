//
//  UserInvite+CoreDataClass.swift
//  
//
//  Created by Tomas Timinskas on 06/11/2019.
//
//

import Foundation
import CoreData
import SwiftyJSON

@objc(UserInvite)
public class UserInvite: NSManagedObject {
    
    enum Status: Int {
        case Pending
        case Ready
        case Delivered
        case InProgress
        case Complete
        case Expired
        case PaymentPending
        case ProcessingPayment = 100
    }
    
    public static func getInviteInstance(inviteString: String, managedContext: NSManagedObjectContext) -> UserInvite {
        if let invite = UserInvite.getInviteWith(inviteString: inviteString) {
            return invite
        } else {
            return UserInvite(context: managedContext) as UserInvite
        }
    }
    
    public static func getInviteWith(inviteString: String) -> UserInvite? {
        let predicate = NSPredicate(format: "inviteString == %@", inviteString)
        let invite:UserInvite? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "UserInvite")
        return invite
    }
    
    public static func insertInvite(invite: JSON) -> UserInvite? {
        if let inviteS = invite["invite_string"].string {
            
            let inviteString = inviteS
            let welcomeMessage = invite["welcome_message"].string
            let inviteStatus = invite["status"].intValue
            let contactId = invite["contact_id"].intValue
            let price = invite["price"].doubleValue
            
            let invite = UserInvite.createObject(inviteString: inviteString, welcomeMessage: welcomeMessage, inviteStatus: inviteStatus, contactId: contactId, price: price)
            
            return invite
        }
        
        return nil
    }
    
    public static func createObject(inviteString: String, welcomeMessage: String?, inviteStatus: Int, contactId: Int, price: Double) -> UserInvite? {
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let invite = getInviteInstance(inviteString: inviteString, managedContext: managedContext)
        invite.inviteString = inviteString
        invite.welcomeMessage = welcomeMessage
        invite.status = inviteStatus
        invite.price = NSDecimalNumber(floatLiteral: price)

        if let contact = UserContact.getContactWith(id: contactId) {
            contact.invite = invite
        }
        
        return invite
    }
    
    public func isExpired() -> Bool {
        return status == Status.Expired.rawValue
    }
    
    public func isInProgress() -> Bool {
        return status == Status.InProgress.rawValue
    }
    
    public func isReady() -> Bool {
        return status == UserInvite.Status.Ready.rawValue || status == UserInvite.Status.Delivered.rawValue
    }
    
    public func isPending() -> Bool {
        return status == UserInvite.Status.Pending.rawValue
    }
    
    public func isPendingPayment() -> Bool {
        return status == UserInvite.Status.PaymentPending.rawValue
    }
    
    public func getInviteStatusForAlert() -> (Bool, String, String) {
        let userNickname = self.contact?.nickname ?? "new.user".localized
        
        if isReady() {
            return (true, "", "")
        } else if isExpired() {
            return (false, "invite.expired.title".localized, "invite.expired.message".localized)
        } else if isPending() {
            return (false, "invite.pending.title".localized, "invite.pending.message".localized)
        } else if isInProgress() {
            return (false, "invite.in.progress.title".localized, String(format: "invite.in.progress.message".localized, userNickname))
        } else if isPaymentProcessed() {
            return (false, "invite.pmt.in.progress.title".localized, "invite.pmt.in.progress.message".localized)
        }
        return (true, "", "")
    }
    
    public func getDataForRow() -> (String, UIColor, String) {
        let userNickname = self.contact?.nickname ?? "New user"
        
        switch(status) {
        case UserInvite.Status.Pending.rawValue:
            return ("error", UIColor.Sphinx.SphinxOrange, String(format: "invite.looking.available.node".localized, userNickname))
        case UserInvite.Status.PaymentPending.rawValue:
            if isPaymentProcessed() {
                return ("sync", UIColor.Sphinx.SecondaryText, "invite.payment.sent".localized)
            } else {
                return ("payment", UIColor.Sphinx.SecondaryText, "invite.pay".localized)
            }
        case UserInvite.Status.Ready.rawValue, UserInvite.Status.Delivered.rawValue:
            return ("done", UIColor.Sphinx.PrimaryGreen, "invite.ready".localized)
        case UserInvite.Status.InProgress.rawValue:
            return ("sync", UIColor.Sphinx.PrimaryBlue, String(format: "invite.signing.on".localized, userNickname))
        case UserInvite.Status.Expired.rawValue:
            return ("error", UIColor.Sphinx.PrimaryRed, "invite.expired".localized)
        default:
            return ("done", UIColor.Sphinx.PrimaryGreen, "invite.signup.complete".localized)
        }
    }
    
    func setPaymentProcessed() {
        if let inviteString = self.inviteString {
            var array = UserDefaults.Keys.paymentProcessedInvites.get(defaultValue: [String]())
            if !array.contains(inviteString) {
                array.append(inviteString)
            }
            UserDefaults.Keys.paymentProcessedInvites.set(array)
        }
    }
    
    func isPaymentProcessed() -> Bool {
        if let inviteString = self.inviteString {
            let array = UserDefaults.Keys.paymentProcessedInvites.get(defaultValue: [String]())
            return array.contains(inviteString)
        }
        return false
    }
    
    func removeFromPaymentProcessed() {
        if let inviteString = self.inviteString {
            var array = UserDefaults.Keys.paymentProcessedInvites.get(defaultValue: [String]())
            if let indexOf = array.index(of: inviteString) {
                array.remove(at: indexOf)
            }
        }
    }
}
