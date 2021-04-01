//
//  ViewController.swift
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import MessageUI

class ExpenseListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {

    var expenseItems = [ExpenseItem]()
    var expenseItemsSubmitted = [ExpenseItem]()
    
    // Used for caching the images so that the image data is available when submitting.
    var imageCache:UIImageView = UIImageView()

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
        button.setTitle("submit".localized(),for: .normal)
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
        submitButton.addTarget(self, action: #selector(submitAction(_:)), for: .touchUpInside)

    }

    func navigateToExpenseItem(expenseItem: ExpenseItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(
            withIdentifier: "expenseItemViewController") as! ExpenseItemViewController
        viewController.expenseItemData = expenseItem
        viewController.parentUIViewController = self

        self.present(viewController, animated: true, completion: nil)
    }

    @objc func addAcion(_ sender: UIButton?){
        navigateToExpenseItem(expenseItem: ExpenseItem())
    }
    
    @objc func submitAction(_ sender: UIButton?) {
        if (expenseItems.isEmpty) {
            self.showAlert(alertTitle: "expencescannotsubmit".localized(), alertMessage: "expencescannotsubmitdescription".localized())
        } else {
            var htmlBody:String = String()
            htmlBody.append("<p> Expenses submitted: <br>")
            for expense in expenseItems {
                htmlBody.append(expense.getPresentationString())
                htmlBody.append("<br>")
            }
            htmlBody.append("</p>")
            print("Submitting " + htmlBody)

            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients(Constants.General.EMAILRECIPIENTS)
                mail.setMessageBody(htmlBody, isHTML: true)
                mail.setSubject("Expenses")

                for expense in expenseItems {
                    if (expense.imageURL != nil) {
                        // should already be cached at this stage
                        let image:UIImage = imageCache.readCachedImage(expense.imageURL)
                        let imageData:Data? = image.jpegData(compressionQuality: 0.5)

                        if (imageData != nil) {
                            if (imageData != nil) {
                                print("Adding attachment for item \(String(describing: expense.text)) with URL \(String(describing: expense.imageURL))")
                                mail.addAttachmentData(imageData!, mimeType: "image/jpeg", fileName: expense.imageURL!)
                            }
                        }
                    }
                }

                present(mail, animated: true)
            } else {
                self.showAlert(alertTitle: "allowance_submit_fail".localized(), alertMessage: "allowance_submit_fail_missing_email".localized())
                return
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        if (result == MFMailComposeResult.sent && error == nil) {
            for expenseItem in expenseItems {
                updateExpenseItemToSubmitted(expenseItem: expenseItem)
            }
            self.loadExpenses()
            self.showAlert(alertTitle: "expensesubmissionsuccessful".localized())

        } else {
            print("Submit canceled or failed")
            self.showAlert(alertTitle: "expense_submit_canceled_or_fail".localized())

        }
        
        controller.dismiss(animated: true)
    }

    func updateExpenseItemToSubmitted(expenseItem: ExpenseItem){
        self.setExpenseSubmitted(expenseItem) { success in
            if success {
                print("updateExpenseItemToSubmitted successfull")
            } else {
                self.showAlert(alertTitle: "Error updating Expense to submitted")
            }
        }
    }

    func setExpenseSubmitted(_ expenseItem: ExpenseItem, completion: @escaping ((_ success:Bool)->())) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Could not find auth user")
            return
        }
        guard let firebasekey = expenseItem.firebasekey else {
            print("Missing firebasekey")
            return
        }

        let expenseRef = Constants.FirebaseRefs.databaseExpenses.child(uid).child(firebasekey)

        let saveDict = [
            "isSubmitted" : true
        ] as [String:Any]

        expenseRef.updateChildValues(saveDict) { error, ref in
            completion(error == nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        loadExpenses()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //tableView.frame = view.bounds
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let expenseItem = getItemForIndexPath(at: indexPath)

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = expenseItem.text

        let image = UIImage(systemName: "photo.on.rectangle")
        cell.imageView?.image = image

        if(expenseItem.imageURL != nil) {
            cell.imageView?.tintColor = .xpnsAppGreen
        } else {
            cell.imageView?.tintColor = .lightGray
        }
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func loadExpenses() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Could not find auth user")
            return
        }
        expenseItems = []
        expenseItemsSubmitted = []

        Constants.FirebaseRefs.databaseExpenses.child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            self.expenseItems.removeAll()
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let data = childSnapshot.value as? [String:Any],
                   let expenseItem = ExpenseItem.parse(childSnapshot.key, data) {
                    if expenseItem.isSubmitted {
                        self.expenseItemsSubmitted.append(expenseItem)
                    } else {
                        self.expenseItems.append(expenseItem)
                        if (expenseItem.imageURL != nil) {
                            // added to the image cache so that image data is available when submitting.
                            self.imageCache.loadImage(expenseItem.imageURL)
                        }
                    }
                }
            }

            // This method runs on a background thread, but the UI should be updated on the main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }) { (error) in
            print(error.localizedDescription)
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

            let expenseItem = getItemForIndexPath(at: indexPath)
            guard let firebasekey = expenseItem.firebasekey
            else { return }

             // Remove the expense from the DB
             Constants.FirebaseRefs.databaseExpenses.child(uid).child(firebasekey).removeValue(completionBlock: { (error, ref) in
                 if let error = error {
                     print("Error: \(String(describing: error))")
                     return
                 }

                if indexPath.section == 0 {
                    self.expenseItems.remove(at: indexPath.row)
                } else {
                    self.expenseItemsSubmitted.remove(at: indexPath.row)
                }

                // This method runs on a background thread, but the UI should be updated on the main thread
                DispatchQueue.main.async {
                    tableView.deleteRows (at: [indexPath], with: .fade)
                }

                print("Removed successfully")

                 // Remove the image from storage
                 let expenseImageRef = Constants.FirebaseRefs.storageExpenseImages.child(firebasekey)
                 expenseImageRef.delete { error in
                     if let error = error {
                         print("Error: \(String(describing: error))")
                     } else {
                         // File deleted successfully
                     }
                 }
             })
        }
    }

    // Delegate - click on a row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let expenseItem = getItemForIndexPath(at: indexPath)

        navigateToExpenseItem(expenseItem: expenseItem)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    let sectionHeaders = ["section_expenses".localized(), "section_submitted_expenses".localized()]

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < sectionHeaders.count {
            return sectionHeaders[section]
        }

        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return expenseItems.count
        } else {
            return expenseItemsSubmitted.count
        }
    }

    private func getListForSection(section: Int) -> [ExpenseItem] {
        var expenseItemList: [ExpenseItem]
        if section == 0 {
            expenseItemList = expenseItems
        } else {
            expenseItemList = expenseItemsSubmitted
        }
        return expenseItemList
    }

    private func getItemForIndexPath(at indexPath: IndexPath) -> ExpenseItem {
        let expenseItemList: [ExpenseItem] = getListForSection(section: indexPath.section)
        let expenseItem = expenseItemList[indexPath.row]

        return expenseItem
    }
}
