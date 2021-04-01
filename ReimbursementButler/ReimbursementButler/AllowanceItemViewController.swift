//
//  AllowanceItemViewController.swift
//

import AVFoundation
import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage

class AllowanceItemViewController: UIViewController,
                                   UITableViewDelegate,
                                   UITableViewDataSource,
                                   AllowanceDayTableViewCellDelegate {
    static let DAY_CELL_ID = "day_cellId"

    var allowanceItem: AllowanceItem!

    var parentUIViewController: AllowanceListViewController!

    let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(AllowanceDayTableViewCell.self, forCellReuseIdentifier: DAY_CELL_ID)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    let descriptionTextField : UITextField = {
        let textField = UITextField()
        textField.keyboardType = .alphabet
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "description".localized()
        textField.textColor = .xpnsAppBlue
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .xpnsAppLightGrey
        return textField
    }()

    let datePickerStart : UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.timeZone = Constants.Allowance.TIMEZONE
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.backgroundColor = .xpnsAppLightGrey
        picker.tintColor = .xpnsAppBlue
        return picker
    }()

    let datePickerEnd : UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.timeZone = Constants.Allowance.TIMEZONE
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.backgroundColor = .xpnsAppLightGrey
        picker.tintColor = .xpnsAppBlue
        return picker
    }()

    let destinationButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .xpnsAppLightGrey
        button.setTitleColor(.xpnsAppBlue, for: .normal)
        button.layer.cornerRadius = 6
        button.setTitle("choosecountry".localized(),for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    let sumLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .xpnsAppBlue
        label.backgroundColor = .xpnsAppLightGrey
        label.layer.cornerRadius = 8.0
        label.layer.masksToBounds = true
        label.layer.borderColor = UIColor.white.cgColor
        label.layer.borderWidth = 1.0
        label.textAlignment = .center
        return label
    }()

    let saveButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .xpnsAppGreen
        button.tintColor = .xpnsAppBlue
        button.layer.cornerRadius = 25
        button.setTitle("save".localized(),for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()


        initializeHideKeyboard()
        tableView.dataSource = self
        tableView.delegate = self

        descriptionTextField.delegate = self
        descriptionTextField.text = allowanceItem.description

        datePickerStart.setDate(allowanceItem.startDate, animated: true)
        datePickerEnd.setDate(allowanceItem.endDate, animated: true)

        destinationButton.setTitle(allowanceItem.getCountryString(), for: .normal)

        refreshSaveButtonAndSumLabel()
        setupView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        descriptionTextField.resignFirstResponder()
        parentUIViewController.loadAllowances()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let description = self.descriptionTextField.text, description.isEmpty{
            descriptionTextField.becomeFirstResponder()
        }
    }

    // Note this is called both for changes on start and end DatePicker
    @objc func datePickerChanged(picker: UIDatePicker) {
        print("date changed")
        let numberOfDays:Int = Utils.daysBetweenTwoDates(startDate: datePickerStart.date, endDate: datePickerEnd.date)
        print("number of days" + String(numberOfDays))

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        allowanceItem.allowanceDays = []
        if (numberOfDays > 0) {
            for day in 1...numberOfDays {
                let allowanceDay:AllowanceDay = AllowanceDay()

                let thisDaysDate = Calendar.current.date(byAdding: .day, value: day - 1, to: datePickerStart.date)!
                allowanceDay.dateString = dateFormatter.string(from: thisDaysDate)

                if (day == 1) {
                    // could be a half start day
                    print("start day");
                    let hour = Calendar.current.component(.hour, from: datePickerStart.date)
                    print("start day hour" + String(hour));

                    if (hour >= Constants.Allowance.HALF_START_DAY_HOUR) {
                        allowanceDay.setDayType(dayType: AllowanceDay.DayType.HALF_START_DAY)
                        allowanceDay.breakfastProvided = false
                        allowanceDay.lunchProvided = true
                        allowanceDay.ownAccommodation = false
                    } else {
                        allowanceDay.setDayType(dayType: AllowanceDay.DayType.FULL_DAY)
                        allowanceDay.breakfastProvided = false
                        allowanceDay.lunchProvided = true
                        allowanceDay.ownAccommodation = false
                    }
                } else if (day == numberOfDays) {
                    // could be a half end day
                    print("end day");

                    let hour = Calendar.current.component(.hour, from: datePickerEnd.date)
                    let minute = Calendar.current.component(.minute, from: datePickerEnd.date)
                    print("end day hour" + String(hour));
                    print("end day minute" + String(minute));

                    if (hour < Constants.Allowance.HALF_END_DAY_HOUR) {
                        allowanceDay.setDayType(dayType: AllowanceDay.DayType.HALF_END_DAY)
                        allowanceDay.breakfastProvided = true
                        allowanceDay.lunchProvided = true
                        allowanceDay.ownAccommodation = false
                    } else {
                        allowanceDay.setDayType(dayType: AllowanceDay.DayType.FULL_DAY)
                        allowanceDay.breakfastProvided = true
                        allowanceDay.lunchProvided = true
                        allowanceDay.ownAccommodation = false
                    }
                } else {
                    // regular day
                    print("regular day");
                    allowanceDay.setDayType(dayType: AllowanceDay.DayType.FULL_DAY)
                    allowanceDay.breakfastProvided = true
                    allowanceDay.lunchProvided = true
                    allowanceDay.ownAccommodation = false
                }

                allowanceItem.allowanceDays.append(allowanceDay)
                refreshSaveButtonAndSumLabel()
            }
        }

        // This method runs on a background thread, but the UI should be updated on the main thread
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // Displays a overlaying alert dialog acting as a country picker
    @objc func destinationButtonClicked(_ sender: UIButton?){
        print("destination button clicked")

        // Create the action sheet
        let actionSheet = UIAlertController(title: "destination".localized(), message: "choosecountrydecription".localized(), preferredStyle: UIAlertController.Style.actionSheet)

        let swedenAction = UIAlertAction(title: "sweden".localized(), style: UIAlertAction.Style.default) { (action) in
            print("Sweden action button tapped")
            self.allowanceItem.setCountry(countryType: AllowanceItem.CountryType.SWEDEN)
            self.destinationButton.setTitle("sweden".localized(), for: .normal)
            self.refreshSaveButtonAndSumLabel()
        }

        let denmarkAction = UIAlertAction(title: "denmark".localized(), style: UIAlertAction.Style.default) { (action) in
            print("Denmark action button tapped")
            self.allowanceItem.setCountry(countryType: AllowanceItem.CountryType.DENMARK)
            self.destinationButton.setTitle("denmark".localized(), for: .normal)
            self.refreshSaveButtonAndSumLabel()
        }

        let norwayAction = UIAlertAction(title: "norway".localized(), style: UIAlertAction.Style.default) { (action) in
            print("Norway action button tapped")
            self.allowanceItem.setCountry(countryType: AllowanceItem.CountryType.NORWAY)
            self.destinationButton.setTitle("norway".localized(), for: .normal)
            self.refreshSaveButtonAndSumLabel()
        }

        let finlandAction = UIAlertAction(title: "finland".localized(), style: UIAlertAction.Style.default) { (action) in
            print("Finland action button tapped")
            self.allowanceItem.setCountry(countryType: AllowanceItem.CountryType.FINLAND)
            self.destinationButton.setTitle("finland".localized(), for: .normal)
            self.refreshSaveButtonAndSumLabel()
        }

        let germanyAction = UIAlertAction(title: "germany".localized(), style: UIAlertAction.Style.default) { (action) in
            print("Germany action button tapped")
            self.allowanceItem.setCountry(countryType: AllowanceItem.CountryType.GERMANY)
            self.destinationButton.setTitle("germany".localized(), for: .normal)
            self.refreshSaveButtonAndSumLabel()
        }

        actionSheet.addAction(swedenAction)
        actionSheet.addAction(denmarkAction)
        actionSheet.addAction(norwayAction)
        actionSheet.addAction(finlandAction)
        actionSheet.addAction(germanyAction)

        // present the action sheet
        self.present(actionSheet, animated: true, completion: nil)
    }

    @objc func saveButtonClicked(_ sender: UIButton?) {
        print("onAddButtonClicked")

        if allowanceItem.isSubmitted {
            self.showAlert(alertTitle: "notallowededit".localized(), alertMessage: "notallowededitdescription".localized())
            return
        }

        if let description = self.descriptionTextField.text, description.isEmpty{
            self.showAlert(alertTitle: "enterdescription".localized())
            return
        }

        if (allowanceItem.allowanceDays.count == 0) {
            self.showAlert(alertTitle: "enterdates".localized())
            return
        }

        if (allowanceItem.getCountry() == AllowanceItem.CountryType.UNKNOWN) {
            self.showAlert(alertTitle: "choosecountry".localized())
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else {
            self.showAlert(alertTitle: "couldnotfindauthuser".localized())
            return
        }

        allowanceItem.description = descriptionTextField.text!

        let firebasekeyToSave = allowanceItem.firebasekey ??
                    Constants.FirebaseRefs.databaseExpenses.child(uid).childByAutoId().key
        let newEntry = Constants.FirebaseRefs.databaseAllowances.child(uid).child(firebasekeyToSave!)

        
        let startTimeInterval:TimeInterval = self.datePickerStart.date.timeIntervalSince1970
        let endTimeInterval:TimeInterval = self.datePickerEnd.date.timeIntervalSince1970
        
        newEntry.updateChildValues(
            [Constants.FirebaseKeys.DESCRIPTION: allowanceItem.description,
             Constants.FirebaseKeys.DESTINATION: allowanceItem.destinationCountryRaw,
             Constants.FirebaseKeys.STARTDATE: startTimeInterval,
             Constants.FirebaseKeys.ENDDATE: endTimeInterval])
        
        let newDayEntries:DatabaseReference = newEntry.child(Constants.FirebaseKeys.DAYS)
        newDayEntries.removeValue() // remove previous entries to avoid duplicates

        for day in allowanceItem.allowanceDays {
            print("submit adding day")
            newDayEntries.childByAutoId().setValue(
                [Constants.FirebaseKeys.BREAKFAST: day.breakfastProvided,
                 Constants.FirebaseKeys.LUNCH: day.lunchProvided,
                 Constants.FirebaseKeys.ACCOMMODATION: day.ownAccommodation,
                 Constants.FirebaseKeys.DATE: day.dateString,
                 Constants.FirebaseKeys.DAYTYPE: day.dayTypeRaw])
        }

        dismiss(animated: true, completion: nil)
    }

    func showAlertMessageAndStopProgress(alertTitle:String) {
        self.showAlert(alertTitle: alertTitle)
        saveButton.loadingIndicator(false)
    }

    func startProgress() {
        saveButton.loadingIndicator(true)
    }

    func setupView(){
        view.backgroundColor = .gray
        view.addSubview(descriptionTextField)

        view.addSubview(datePickerStart)
        view.addSubview(datePickerEnd)
        view.addSubview(destinationButton)

        view.addSubview(tableView)
        view.addSubview(sumLabel)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            descriptionTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            descriptionTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            descriptionTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            descriptionTextField.heightAnchor.constraint(equalToConstant: 50),

            datePickerStart.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 10),
            datePickerStart.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            datePickerStart.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            datePickerStart.heightAnchor.constraint(equalToConstant: 50),


            datePickerEnd.topAnchor.constraint(equalTo: datePickerStart.bottomAnchor, constant: 10),
            datePickerEnd.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            datePickerEnd.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            datePickerEnd.heightAnchor.constraint(equalToConstant: 50),


            destinationButton.topAnchor.constraint(equalTo: datePickerEnd.bottomAnchor, constant: 10),
            destinationButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            destinationButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            destinationButton.heightAnchor.constraint(equalToConstant: 50),


            tableView.topAnchor.constraint(equalTo: destinationButton.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -10),

            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            saveButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            saveButton.widthAnchor.constraint(equalToConstant: 120),
            saveButton.heightAnchor.constraint(equalToConstant: 50),

            sumLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            sumLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            sumLabel.widthAnchor.constraint(equalToConstant: 150),
            sumLabel.heightAnchor.constraint(equalToConstant: 50),
        ])

        destinationButton.addTarget(self, action: #selector(destinationButtonClicked(_:)), for: .touchUpInside)
        datePickerStart.addTarget(self, action: #selector(datePickerChanged(picker:)), for: .valueChanged)
        datePickerEnd.addTarget(self, action: #selector(datePickerChanged(picker:)), for: .valueChanged)
        saveButton.addTarget(self, action: #selector(saveButtonClicked(_:)), for: .touchUpInside)
    }
}

extension AllowanceItemViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        saveButtonEvalute()
    }
    // This is called when enter is pressed in an textfield, see UITextFieldDelegate.
    // Action needs to be taken for closing the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        textField.resignFirstResponder()
        return true
    }
}

extension AllowanceItemViewController {
    func initializeHideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }

    func saveButtonEvalute() {
        let descriptionText = descriptionTextField.text
        let daysToSave = allowanceItem.allowanceDays.count
        let countryChosen = allowanceItem.getCountry() != AllowanceItem.CountryType.UNKNOWN
        let allowSave = descriptionText != nil && descriptionText != "" && countryChosen && daysToSave > 0
        saveButton.setEnabled(allowSave)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allowanceItem.allowanceDays.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AllowanceItemViewController.DAY_CELL_ID, for: indexPath) as! AllowanceDayTableViewCell
        let allowanceDay = allowanceItem.allowanceDays[indexPath.row]

        cell.allowanceDay = allowanceDay
        cell.contentView.isUserInteractionEnabled = false // <<-- the solution

        cell.mIndex = indexPath.row
        cell.delegate = self

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "allowancedays".localized()
    }

    // See AllowanceDayTableViewCellDelegate, implemented in AllowanceDayTableViewCell
    func breakfastSwitchChanged(index:Int, isOn:Bool) {
        print("AllowanceItemViewController breakfast switch " +
                String(index) + " toggled , value " + String(isOn));
        allowanceItem.allowanceDays[index].breakfastProvided = isOn
        refreshSaveButtonAndSumLabel()
    }

    // See AllowanceDayTableViewCellDelegate, implemented in AllowanceDayTableViewCell
    func lunchSwitchChanged(index:Int, isOn:Bool) {
        print("AllowanceItemViewController lunch switch " +
                String(index) + " toggled , value " + String(isOn));
        allowanceItem.allowanceDays[index].lunchProvided = isOn
        refreshSaveButtonAndSumLabel()
    }

    // See AllowanceDayTableViewCellDelegate, implemented in AllowanceDayTableViewCell
    func accommodationSwitchChanged(index:Int, isOn:Bool) {
        print("AllowanceItemViewController accommodation switch " +
                String(index) + " toggled , value " + String(isOn));
        allowanceItem.allowanceDays[index].ownAccommodation = isOn
        refreshSaveButtonAndSumLabel()
    }

    // Update the sum text
    func refreshSaveButtonAndSumLabel() {
        updateSum()
        saveButtonEvalute()
    }

    func updateSum() {
        let sum:Int = allowanceItem.calculateAllowance()
        if (sum >= 0) { // -1 on error
            sumLabel.text = "sum:".localized() + " " + String(sum) + " " + Constants.Allowance.CURRENCY
        } else {
            sumLabel.text = "sum:".localized() + " 0"
        }
    }
}
