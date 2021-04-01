//
//  Constants.swift
//

import UIKit
import Firebase
import Foundation

struct Constants {

    struct FirebaseRefs {
        static let databaseRef = Database.database().reference()
        static let databaseExpenses = databaseRef.child("expenses")
        static let databaseAllowances = databaseRef.child("allowances")

        static let storageRef = Storage.storage().reference()
        static let storageExpenseImages = storageRef.child("expense_images")
    }
    
    struct FirebaseKeys {
        // AllowanceItem
        public static let DESCRIPTION:String = "description"
        public static let DESTINATION:String = "destinationenumval"
        public static let DAYS:String = "days"

        public static let SUBMITTED:String = "issubmitted"
        public static let STARTDATE:String = "startdate"
        public static let ENDDATE:String = "enddate"

        // AllowanceDay
        public static let BREAKFAST:String = "breakfast"
        public static let LUNCH:String = "lunch"
        public static let ACCOMMODATION:String = "ownaccommodation"
        public static let DATE:String = "datestring"
        public static let DAYTYPE:String = "daytypeenumval"
    }

    struct Allowance {
        public static let CURRENCY:String = "SEK"
        
        // Numbers for 2020
        // Sources:  https://skatteverket.se/utlandstraktamente
        // https://www.skatteverket.se/privat/skatter/arbeteochinkomst/traktamente.4.dfe345a107ebcc9baf80006547.html
       // https://www.utlandstraktamente.se
        public static let DAY_REEMBURSEMENT_SWEDEN:Int = 240
        public static let DAY_REEMBURSEMENT_DENMARK:Int = 1016
        public static let DAY_REEMBURSEMENT_NORWAY:Int = 894
        public static let DAY_REEMBURSEMENT_FINLAND:Int = 759
        public static let DAY_REEMBURSEMENT_GERMANY:Int = 668

        public static let DAY_OWNACCOMMODATION_SWEDEN:Int = 120
        public static let DAY_OWNACCOMMODATION_DENMARK:Int = 508
        public static let DAY_OWNACCOMMODATION_NORWAY:Int = 446
        public static let DAY_OWNACCOMMODATION_FINLAND:Int = 379
        public static let DAY_OWNACCOMMODATION_GERMANY:Int = 334
        
        // Halv day if journey ends before 19:00
        public static let HALF_END_DAY_HOUR:Int = 19
        // Halv day if journey start after 12:00
        public static let HALF_START_DAY_HOUR:Int = 12
        
        // As this is ment for the Swedish market, hardcoding to Swedish timezone
        public static let TIMEZONE:TimeZone = TimeZone(identifier: "CET")!
    }
    
    struct General {
        public static let EMAILRECIPIENTS:[String] = [ "ekdahl@inlight.se"]
    }
}
