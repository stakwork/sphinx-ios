//
//  SphinOnionManager+InvoicesExtension.swift
//  
//
//  Created by James Carucci on 3/5/24.
//


import Foundation

extension SphinxOnionManager{//invoices related
    
    func createInvoice(amountMsat:Int,description:String?=nil)->String?{
        guard let seed = getAccountSeed(),
            let selfContact = UserContact.getSelfContact(),
            let nickname = selfContact.nickname else{
            return nil
        }
        let rr = try! makeInvoice(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), amtMsat: UInt64(amountMsat), description: description ?? "")
        handleRunReturn(rr: rr)
        return rr.invoice
    }
    
    func payInvoice(invoice:String){
        guard let seed = getAccountSeed() else{
            return
        }
        let rr = try! sphinx.payInvoice(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), bolt11: invoice, overpayMsat: nil)
        handleRunReturn(rr: rr)
    }
    
    func sendPaymentOfInvoiceMessage(message:TransactionMessage){
        guard message.type == TransactionMessage.TransactionMessageType.payment.rawValue,
              let invoice = message.invoice,
              let seed = getAccountSeed(),
              let selfContact = UserContact.getSelfContact(),
              let chat = message.chat,
              let nickname = selfContact.nickname ?? chat.name else{
            return
        }
       let rr = try! payContactInvoice(seed: seed, uniqueTime: getTimeWithEntropy(), state: loadOnionStateAsData(), bolt11: invoice, myAlias: nickname, myImg: selfContact.avatarUrl ?? "",isTribe: false)
        handleRunReturn(rr: rr)
    }
    
    
    func sendInvoiceMessage(
        contact:UserContact,
        chat:Chat,
        invoiceString:String
    ){
        let type = TransactionMessage.TransactionMessageType.invoice.rawValue
        let result = self.sendMessage(to: contact, content: "", chat: chat,msgType: UInt8(type), threadUUID: nil, replyUUID: nil,invoiceString: invoiceString)
    }
}
