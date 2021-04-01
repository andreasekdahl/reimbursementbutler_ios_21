//
//  Utils.swift
//  

import Foundation

public class Utils {
    
    // Checks the number of days between two Dates, including the days themselfs.
    // Example: Wednesday to Friday returns 3.
    // Returns 0 on error or if startDate is after endDate.
    public static func daysBetweenTwoDates(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current

        // Replace the hour (time) of both dates with 12:00 to be able to diff number of days
        guard let date1 = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startDate) else { return 0 }
        guard let date2 = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: endDate) else { return 0 }
        
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        let numberOfDays:Int = components.day ?? -1
        if (numberOfDays >= 0) {
            return numberOfDays + 1 // plus one to include the start and end day
        } else {
            return 0
        }
    }
}
