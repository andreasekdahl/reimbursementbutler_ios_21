//
//  ExpenseItem.swift
//
import Foundation
import FirebaseDatabase

class ExpenseItem {
    var firebasekey: String?

    var text: String?
    var date: Date

    var amount: Double?
    var currency: String

    var isSubmitted: Bool

    @objc var imageURL: String?

    init(text: String,
         date: TimeInterval,
         amount: Double,
         currency: String,
         isSubmitted: Bool) {
        self.text = text
        self.date = Date(timeIntervalSince1970: date)
        self.amount = amount
        self.currency = currency
        self.isSubmitted = isSubmitted
    }

    convenience init(firebasekey: String,
                     text: String,
                     date: TimeInterval,
                     amount: Double,
                     currency: String,
                     isSubmitted: Bool) {
        self.init(text: text,
                  date:date,
                  amount:amount,
                  currency:currency,
                  isSubmitted:isSubmitted)
        self.firebasekey = firebasekey

    }

    convenience init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
              let text = dict["text"] as? String,
              let date = dict["date"] as? TimeInterval,
              let amount = dict["amount"] as? Double,
              let currency = dict["currency"] as? String,
              let isSubmitted = dict["isSubmitted"] as? Bool
        else { return nil }

        self.init(text: text,
                  date:date,
                  amount:amount,
                  currency:currency,
                  isSubmitted:isSubmitted)
        self.imageURL = dict["imageURL"] as? String


        self.firebasekey = snapshot.key

    }

    // Init - creation of new
    init() {
        self.date = Date()
        self.currency = "SEK"
        self.isSubmitted = false
    }

    static func parse(_ firebasekey:String, _ dict:[String:Any]) -> ExpenseItem? {
        guard let text = dict["text"] as? String,
              let date = dict["date"] as? TimeInterval,
              let amount = dict["amount"] as? Double,
              let currency = dict["currency"] as? String,
              let isSubmitted = dict["isSubmitted"] as? Bool
        else { return nil }

        let expenseItem  = ExpenseItem(firebasekey: firebasekey,
                                       text: text,
                                       date: date,
                                       amount: amount,
                                       currency: currency,
                                       isSubmitted: isSubmitted)

        expenseItem.imageURL = dict["imageURL"] as? String

        return expenseItem

    }

    var dictValue: [String : Any] {
        return ["text" : text,
                "date" : date.timeIntervalSince1970,
                "amount" : amount,
                "currency" : currency,
                "isSubmitted" : isSubmitted]
    }
    
    public func getPresentationString() -> String {
        return self.text! + " " + String(self.amount!) + " " + currency;
    }
}
