//
//  DayTableViewCell.swift
//

import Foundation
import UIKit

protocol AllowanceDayTableViewCellDelegate: class {
    func breakfastSwitchChanged(index:Int, isOn:Bool)
    func lunchSwitchChanged(index:Int, isOn:Bool)
    func accommodationSwitchChanged(index:Int, isOn:Bool)
}

class AllowanceDayTableViewCell : UITableViewCell {

    // Don't unwrap in case the cell is enqueued!
    weak var delegate : AllowanceDayTableViewCellDelegate?
    let minValue = 0

    var mIndex:Int = 0

    var allowanceDay : AllowanceDay? {
        didSet {
            dateLabel.text = allowanceDay?.dateString

            breakfastSwitch.setOn(allowanceDay?.breakfastProvided ?? false, animated: false)
            breakfastSwitch.isEnabled = allowanceDay?.getDayType() != AllowanceDay.DayType.HALF_START_DAY
            
            lunchSwitch.setOn(allowanceDay?.lunchProvided ?? false, animated: false)
            lunchSwitch.isEnabled = true 
            
            accommodationSwitch.setOn(allowanceDay?.ownAccommodation ?? false, animated: false)
            accommodationSwitch.isEnabled = allowanceDay?.getDayType() != AllowanceDay.DayType.HALF_END_DAY
        }
    }

    private let dateLabel : UILabel = {
        let lbl = UILabel()
        lbl.textColor = .black
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.textAlignment = .left
        return lbl
    }()

    private let breakfastLabel : UILabel = {
        let lbl = UILabel()
        lbl.textColor = .xpnsAppGreen
        lbl.font = UIFont.boldSystemFont(ofSize: 10)
        lbl.textAlignment = .left
        lbl.text = "inclbreakfast".localized()
        return lbl
    }()

    private let lunchLabel : UILabel = {
        let lbl = UILabel()
        lbl.textColor = .xpnsAppGreen
        lbl.font = UIFont.boldSystemFont(ofSize: 10)
        lbl.textAlignment = .left
        lbl.text = "incllunch"
        return lbl
    }()
    private let accomodationLabel : UILabel = {
        let lbl = UILabel()
        lbl.textColor = .xpnsAppGreen
        lbl.font = UIFont.boldSystemFont(ofSize: 10)
        lbl.textAlignment = .left
        lbl.text = "ownaccommodation".localized()
        return lbl
    }()

    lazy var breakfastSwitch: UISwitch = {
            let switcher = UISwitch()
            switcher.isOn = true
            switcher.isEnabled = true
            switcher.onTintColor = .xpnsAppGreen
            return switcher
        }()

    lazy var lunchSwitch: UISwitch = {
            let switcher = UISwitch()
            switcher.isOn = true
            switcher.isEnabled = true
        switcher.onTintColor = .xpnsAppGreen
            return switcher
        }()

    lazy var accommodationSwitch: UISwitch = {
            let switcher = UISwitch()
            switcher.isOn = true
            switcher.isEnabled = true
            switcher.onTintColor = .xpnsAppGreen
            return switcher
        }()

    @objc func breakfastSwitchChangedAction(_ sender: UISwitch) {
        // notify the viewcontroller through the defined delegate
        delegate?.breakfastSwitchChanged(index: mIndex, isOn: sender.isOn)
    }

    @objc func lunchSwitchChangedAction(_ sender: UISwitch) {
        // notify the viewcontroller through the defined delegate
        delegate?.lunchSwitchChanged(index: mIndex, isOn: sender.isOn)
    }

    @objc func accommodationSwitchChangedAction(_ sender: UISwitch) {
        // notify the viewcontroller through the defined delegate
        delegate?.accommodationSwitchChanged(index: mIndex, isOn: sender.isOn)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(dateLabel)

        addSubview(breakfastSwitch)
        addSubview(lunchSwitch)
        addSubview(accommodationSwitch)

        addSubview(breakfastLabel)
        addSubview(lunchLabel)
        addSubview(accomodationLabel)

        dateLabel.anchor(
            top: topAnchor, left: leftAnchor, bottom: nil, right: nil,
            paddingTop: 10, paddingLeft: 10, paddingBottom: 10, paddingRight: 10,
            width: frame.size.width / 2,
            height: 0,
            enableInsets: false)

        let switchStackView = UIStackView(arrangedSubviews: [breakfastSwitch,lunchSwitch,accommodationSwitch])
        switchStackView.distribution = .fillEqually
        switchStackView.axis = .horizontal
        switchStackView.spacing = 5
        addSubview(switchStackView)
        switchStackView.anchor(
            top: dateLabel.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor,
            paddingTop: 15, paddingLeft: 5, paddingBottom: 15, paddingRight: 10,
            width: 0,
            height: 0,
            enableInsets: false)

        let labelStackView = UIStackView(arrangedSubviews: [breakfastLabel, lunchLabel, accomodationLabel])
        labelStackView.distribution = .fillEqually
        labelStackView.axis = .horizontal
        labelStackView.spacing = 5
        addSubview(labelStackView)
        labelStackView.anchor(
            top: switchStackView.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor,
            paddingTop: 15, paddingLeft: 5, paddingBottom: 15, paddingRight: 10,
            width: 0,
            height: 0,
            enableInsets: false)

        breakfastSwitch.addTarget(self, action: #selector(breakfastSwitchChangedAction), for: UIControl.Event.valueChanged)
        lunchSwitch.addTarget(self, action: #selector(lunchSwitchChangedAction), for: UIControl.Event.valueChanged)
        accommodationSwitch.addTarget(self, action: #selector(accommodationSwitchChangedAction), for: UIControl.Event.valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
