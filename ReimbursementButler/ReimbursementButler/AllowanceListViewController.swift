//
//  ViewController.swift
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import MessageUI

class AllowanceListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    var allowanceItems = [AllowanceItem]()
    var allowanceItemsSubmitted = [AllowanceItem]()

    let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    let addButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .xpnsAppGreen
        button.tintColor = .xpnsAppBlue
        button.layer.cornerRadius = 25
        button.setTitle("add".localized(),for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    let submitButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .xpnsAppGreen
        button.tintColor = .xpnsAppBlue
        button.layer.cornerRadius = 25
        button.setTitle("submit".localized(), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        setupView()
    }

    func setupView(){
        view.backgroundColor = .gray
        view.addSubview(addButton)
        view.addSubview(submitButton)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            addButton.widthAnchor.constraint(equalToConstant: 120),
            addButton.heightAnchor.constraint(equalToConstant: 50),

            submitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            submitButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            submitButton.widthAnchor.constraint(equalToConstant: 120),
            submitButton.heightAnchor.constraint(equalToConstant: 50),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        ])

        addButton.addTarget(self, action: #selector(addAcion(_:)), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitAcion(_:)), for: .touchUpInside)
    }

    func navigateToAllowanceItem(allowanceItem: AllowanceItem?) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(
            withIdentifier: "allowanceItemViewController") as! AllowanceItemViewController
        viewController.allowanceItem = allowanceItem
        viewController.parentUIViewController = self

        self.present(viewController, animated: true, completion: nil)
    }

    @objc func addAcion(_ sender: UIButton?){
        navigateToAllowanceItem(allowanceItem: AllowanceItem())
    }

    @objc func submitAcion(_ sender: UIButton?){
        var htmlBody:String = String()
        htmlBody.append("<p> Allowances submitted: <br>")
        for allowance in allowanceItems {
            htmlBody.append(allowance.getPresentationString())
            htmlBody.append("<br>")
        }
        htmlBody.append("</p>")
        print("Submitting " + htmlBody)

        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(Constants.General.EMAILRECIPIENTS)
            mail.setMessageBody(htmlBody, isHTML: true)
            mail.setSubject("Allowances")
            present(mail, animated: true)
        } else {
            self.showAlert(alertTitle: "allowance_submit_fail".localized(), alertMessage: "allowance_submit_fail_missing_email".localized())
            return
        }

    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {

        if (result == MFMailComposeResult.sent && error == nil) {
            for allowanceItem in allowanceItems {
                updateAllowanceItemToSubmitted(allowanceItem: allowanceItem)
            }
            self.loadAllowances()
            self.showAlert(alertTitle: "allowance_submit_success".localized())

        } else {
            print("Submit canceled or failed")
            self.showAlert(alertTitle: "allowance_submit_canceled_or_fail".localized())
        }

        controller.dismiss(animated: true)
    }

    func updateAllowanceItemToSubmitted(allowanceItem: AllowanceItem){
        self.setAllowanceSubmitted(allowanceItem) { success in
            if success {
                print("updateAllowanceItemToSubmitted successfull")
            } else {
                self.showAlert(alertTitle: "allowance_submit_error".localized())
            }
        }
    }

    func setAllowanceSubmitted(_ allowanceItem: AllowanceItem, completion: @escaping ((_ success:Bool)->())) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Could not find auth user")
            return
        }
        guard let firebasekey = allowanceItem.firebasekey else {
            print("Missing firebasekey")
            return
        }

        let allowanceRef = Constants.FirebaseRefs.databaseAllowances.child(uid).child(firebasekey)

        let saveDict = [
            Constants.FirebaseKeys.SUBMITTED : true
        ] as [String:Any]

        allowanceRef.updateChildValues(saveDict) { error, ref in
            completion(error == nil)
        }
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAllowances()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let allowanceItem = getItemForIndexPath(at: indexPath)

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = allowanceItem.description
        cell.accessoryType = .disclosureIndicator


        let image = UIImage(systemName: "calendar.circle")
        cell.imageView?.image = image
        cell.imageView?.tintColor = .xpnsAppGreen

        return cell
    }

    func loadAllowances() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Could not find auth user")
            return
        }

        allowanceItems = []
        allowanceItemsSubmitted = []

        Constants.FirebaseRefs.databaseAllowances.child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {
                    let allowanceItem = AllowanceItem.parse(allowanceEntrySnapshot: childSnapshot)
                    if allowanceItem.isSubmitted {
                        self.allowanceItemsSubmitted.append(allowanceItem)
                    } else {
                        self.allowanceItems.append(allowanceItem)
                    }
                }
            }

            // This method runs on a background thread, but the UI should be updated on the main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }) { (error) in
            print(error.localizedDescription)
            return
        }

    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Could not find auth user")
            return
        }
        
        if editingStyle == .delete {

            let allowanceItem = getItemForIndexPath(at: indexPath)
            guard let firebasekey = allowanceItem.firebasekey
            else { return }

            // Remove the allowance from the DB
            Constants.FirebaseRefs.databaseAllowances.child(uid).child(firebasekey).removeValue(completionBlock: { (error, ref) in
                if let error = error {
                    print("Error: \(String(describing: error))")
                    return
                }
                if indexPath.section == 0 {
                    self.allowanceItems.remove(at: indexPath.row)
                } else {
                    self.allowanceItemsSubmitted.remove(at: indexPath.row)
                }

                // This method runs on a background thread, but the UI should be updated on the main thread
                DispatchQueue.main.async {
                    tableView.deleteRows (at: [indexPath], with: .fade)
                }

                print("Removed successfully")
            })
        }
    }

    // Delegate - click on a row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let allowanceItem = getItemForIndexPath(at: indexPath)

        navigateToAllowanceItem(allowanceItem: allowanceItem)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    let sectionHeaders = ["section_allowances".localized(), "section_submitted_allowances".localized()]

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < sectionHeaders.count {
            return sectionHeaders[section]
        }

        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return allowanceItems.count
        } else {
            return allowanceItemsSubmitted.count
        }
    }

    private func getListForSection(section: Int) -> [AllowanceItem] {
        var allowanceItemList: [AllowanceItem]
        if section == 0 {
            allowanceItemList = allowanceItems
        } else {
            allowanceItemList = allowanceItemsSubmitted
        }
        return allowanceItemList
    }

    private func getItemForIndexPath(at indexPath: IndexPath) -> AllowanceItem {
        let allowanceItemList: [AllowanceItem] = getListForSection(section: indexPath.section)
        let allowanceItem = allowanceItemList[indexPath.row]

        return allowanceItem
    }

}
