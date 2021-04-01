//
//  AllowanceDay.swift
//

import Foundation

public class AllowanceDay {
    var firebasekey: String?

    var breakfastProvided: Bool
    var lunchProvided: Bool
    var ownAccommodation: Bool
    var dateString: String
    var dayTypeRaw: Int
    
    init()  {
        self.breakfastProvided = false
        self.lunchProvided = false
        self.ownAccommodation = false
        self.dateString = ""
        self.dayTypeRaw = 0
    }

    init(breakfastProvided: Bool,
         lunchProvided: Bool,
         ownAccommodation: Bool,
         dateString: String,
         dayTypeRaw: Int)  {

        self.breakfastProvided = breakfastProvided
        self.lunchProvided = lunchProvided
        self.ownAccommodation = ownAccommodation
        self.dateString = dateString
        self.dayTypeRaw = dayTypeRaw
    }
    
    public enum DayType: Int {
        case HALF_START_DAY = 0
        case HALF_END_DAY = 1
        case FULL_DAY = 2
    }
    
    func setDayType(dayType: DayType) {
        self.dayTypeRaw = dayType.rawValue
    }

    func getDayType() -> DayType {
        return DayType(rawValue: self.dayTypeRaw)!
    }
    
    func getPresentationString() -> String {
        return dateString
    }
}

