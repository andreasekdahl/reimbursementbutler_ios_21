//
//  AllowanceItem.swift
//

import Foundation
import FirebaseDatabase

class AllowanceItem {
    var firebasekey: String?
    var description:String
    var destinationCountryRaw:Int
    var allowanceDays:[AllowanceDay] = []
    
    var startDate: Date
    var endDate: Date

    var isSubmitted: Bool
    init()  {
        self.isSubmitted = false
        self.description = ""
        self.destinationCountryRaw = 0 // overwritten by setCountry
        self.startDate = Date()
        self.endDate = Date()
        self.setCountry(countryType: CountryType.UNKNOWN)
    }

    static func parse(allowanceEntrySnapshot: DataSnapshot) -> AllowanceItem {

        let allowanceItem: AllowanceItem = AllowanceItem()
        allowanceItem.firebasekey = allowanceEntrySnapshot.key

        let entryDict:[String: Any] = allowanceEntrySnapshot.value as! [String: Any]

        allowanceItem.description = entryDict[Constants.FirebaseKeys.DESCRIPTION] as? String ?? "database error"
        allowanceItem.destinationCountryRaw = entryDict[Constants.FirebaseKeys.DESTINATION] as? Int ?? 0

        allowanceItem.isSubmitted = entryDict[Constants.FirebaseKeys.SUBMITTED] as? Bool ?? false

        let startTimeInterval:TimeInterval = entryDict[Constants.FirebaseKeys.STARTDATE] as? TimeInterval ?? 0
        allowanceItem.startDate = Date(timeIntervalSince1970: startTimeInterval)
        let endTimeInterval:TimeInterval = entryDict[Constants.FirebaseKeys.ENDDATE] as? TimeInterval ?? 0
        allowanceItem.endDate = Date(timeIntervalSince1970: endTimeInterval)
        
        let allowanceDaySnapshotChild:DataSnapshot = allowanceEntrySnapshot.childSnapshot(forPath: Constants.FirebaseKeys.DAYS)

        for allowanceDaySnapshotAny in allowanceDaySnapshotChild.children {
            let allowanceDay:AllowanceDay = AllowanceDay()
            let allowanceDaySnapshot:DataSnapshot = allowanceDaySnapshotAny as! DataSnapshot

            allowanceDay.firebasekey = allowanceDaySnapshot.key

            let dayDict:[String: Any] = allowanceDaySnapshot.value as! [String: Any]
            allowanceDay.breakfastProvided = dayDict[Constants.FirebaseKeys.BREAKFAST] as? Bool ?? false
            allowanceDay.lunchProvided = dayDict[Constants.FirebaseKeys.LUNCH] as? Bool ?? false
            allowanceDay.ownAccommodation = dayDict[Constants.FirebaseKeys.ACCOMMODATION] as? Bool ?? false
            allowanceDay.dateString = dayDict[Constants.FirebaseKeys.DATE] as? String ?? "database error"
            allowanceDay.dayTypeRaw = dayDict[Constants.FirebaseKeys.DAYTYPE] as? Int ?? 0

            allowanceItem.allowanceDays.append(allowanceDay)
        }
        return allowanceItem
    }

    
    public enum CountryType: Int {
        case UNKNOWN = 0
        case SWEDEN = 1
        case DENMARK = 2
        case NORWAY = 3
        case FINLAND = 4
        case GERMANY = 5
    }
    
    func setCountry(countryType: CountryType) {
        self.destinationCountryRaw = countryType.rawValue
    }

    func getCountry() -> CountryType {
        return CountryType(rawValue: self.destinationCountryRaw)!
    }

    func getCountryString() -> String {
        let countryType = getCountry()
        return AllowanceItem.getCountryStringForType(forCountryType: countryType)
    }
    
    static func getCountryStringForType(forCountryType type: CountryType) -> String {
        switch type {
        case .SWEDEN:
            return "sweden".localized()
        case .DENMARK:
            return "denmark".localized()
        case .FINLAND:
            return "finland".localized()
        case .NORWAY:
            return "norway".localized()
        case .GERMANY:
            return "germany".localized()
        case .UNKNOWN:
            return "countryunknown".localized()
        }
    }
    
    public func getPresentationString() -> String {
        return description + " " + String(calculateAllowance()) + " " + Constants.Allowance.CURRENCY;
    }
    
    // Calculates the allowance for the trip.
    // return -1 on error
    public func calculateAllowance() -> Int {
        print("calculateAllowance")
        var fullDayReembursement:Int
        var breakfastDeduction:Int
        var lunchDeduction:Int
        var ownAccommodationIncrease:Int

        switch getCountry() {
        case CountryType.SWEDEN:
            fullDayReembursement = Constants.Allowance.DAY_REEMBURSEMENT_SWEDEN
            breakfastDeduction = Int(0.35 * Double(fullDayReembursement))
            lunchDeduction = Int(0.15 * Double(fullDayReembursement))
            ownAccommodationIncrease = Constants.Allowance.DAY_OWNACCOMMODATION_SWEDEN
            print("calculateAllowance, Sweden")
        case CountryType.DENMARK:
            fullDayReembursement = Constants.Allowance.DAY_REEMBURSEMENT_DENMARK
            breakfastDeduction = Int(0.35 * Double(fullDayReembursement))
            lunchDeduction = Int(0.15 * Double(fullDayReembursement))
            ownAccommodationIncrease = Constants.Allowance.DAY_OWNACCOMMODATION_DENMARK
            print("calculateAllowance, Denmark")
        case CountryType.NORWAY:
            fullDayReembursement = Constants.Allowance.DAY_REEMBURSEMENT_NORWAY
            breakfastDeduction = Int(0.35 * Double(fullDayReembursement))
            lunchDeduction = Int(0.15 * Double(fullDayReembursement))
            ownAccommodationIncrease = Constants.Allowance.DAY_OWNACCOMMODATION_NORWAY
            print("calculateAllowance, Norway")
        case CountryType.FINLAND:
            fullDayReembursement = Constants.Allowance.DAY_REEMBURSEMENT_FINLAND
            breakfastDeduction = Int(0.35 * Double(fullDayReembursement))
            lunchDeduction = Int(0.15 * Double(fullDayReembursement))
            ownAccommodationIncrease = Constants.Allowance.DAY_OWNACCOMMODATION_FINLAND
            print("calculateAllowance, Finland")
        case CountryType.GERMANY:
            fullDayReembursement = Constants.Allowance.DAY_REEMBURSEMENT_GERMANY
            breakfastDeduction = Int(0.35 * Double(fullDayReembursement))
            lunchDeduction = Int(0.15 * Double(fullDayReembursement))
            ownAccommodationIncrease = Constants.Allowance.DAY_OWNACCOMMODATION_GERMANY
            print("calculateAllowance, Germany")
        case CountryType.UNKNOWN:
            print("Country type not set")
            return -1
        }
        
        print("calculateAllowance, nof days " + String(allowanceDays.count))

        var allowance = 0
        for allowanceDay in allowanceDays {
            switch allowanceDay.getDayType() {
            case AllowanceDay.DayType.FULL_DAY:
                allowance += fullDayReembursement
            case AllowanceDay.DayType.HALF_START_DAY:
                allowance += (fullDayReembursement / 2)
            case AllowanceDay.DayType.HALF_END_DAY:
                allowance += (fullDayReembursement / 2)
            }
            
            if allowanceDay.breakfastProvided {
                print("breakfast provided")
                allowance -= breakfastDeduction
            }
            if allowanceDay.lunchProvided {
                print("lunch provided")
                allowance -= lunchDeduction
            }
            if allowanceDay.ownAccommodation {
                print("own accommodation")
                allowance += ownAccommodationIncrease
            }
        }

        return allowance;
    }
}

