//
//  ExpenseItemViewController.swift
//
import AVFoundation
import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage

class ExpenseItemViewController: UIViewController {

    var expenseItemData: ExpenseItem!

    var parentUIViewController: ExpenseListViewController!

    var captureSession : AVCaptureSession!
    var backCamera : AVCaptureDevice!
    var backInput : AVCaptureInput!

    var previewLayer : AVCaptureVideoPreviewLayer!

    var videoOutput : AVCaptureVideoDataOutput!

    var takePicture = false

    let captureImageButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .xpnsAppBlue
        button.tintColor = .xpnsAppBlue
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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

    let capturedImageView = CapturedImageView()

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

    let amountTextField : UITextField = {
        let textField = UITextField()
        textField.keyboardType = .decimalPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "amount".localized()
        textField.textColor = .xpnsAppBlue
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .xpnsAppLightGrey
        return textField
    }()

    let datePicker : UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.backgroundColor = .xpnsAppLightGrey
        picker.tintColor = .xpnsAppBlue
        return picker
    }()

    let currencyList = ["SEK", "EUR", "DKK"]
    let currencyButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .xpnsAppLightGrey
        button.setTitleColor(.xpnsAppBlue, for: .normal)
        button.layer.cornerRadius = 6
        button.setTitle("currency".localized(), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        initializeHideKeyboard()

        descriptionTextField.delegate = self
        amountTextField.delegate = self

        setupView()

        descriptionTextField.text = expenseItemData.text

        if let amount = expenseItemData.amount {
            amountTextField.text = String(amount)
        }

        if let currencyIndex = currencyList.firstIndex(of: expenseItemData.currency) {
            currencyButton.setTitle(currencyList[currencyIndex], for: .normal)
        }

        datePicker.setDate(expenseItemData.date , animated: true)

        saveButtonEvalute()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
        setupAndStartCaptureSession()
        self.capturedImageView.imageView.loadImage(expenseItemData.imageURL)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        descriptionTextField.resignFirstResponder()
        amountTextField.resignFirstResponder()
        datePicker.resignFirstResponder()

        parentUIViewController.loadExpenses()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let description = self.descriptionTextField.text, description.isEmpty{
            descriptionTextField.becomeFirstResponder()
        }
    }

    // Displays a overlaying alert dialog acting as a country picker
    @objc func currencyButtonClicked(_ sender: UIButton?){
        print("destination button clicked")

        // Create the action sheet
        let actionSheet = UIAlertController(
            title: "currency".localized(),
            message: "pleaseselectcurrency".localized(),
            preferredStyle: UIAlertController.Style.actionSheet)

        let currency0 = UIAlertAction(title: currencyList[0], style: UIAlertAction.Style.default) { (action) in
            self.expenseItemData.currency = self.currencyList[0] as String
            self.currencyButton.setTitle(self.currencyList[0], for: .normal)
            self.saveButtonEvalute()
        }

        let currency1 = UIAlertAction(title: currencyList[1], style: UIAlertAction.Style.default) { (action) in
            self.expenseItemData.currency = self.currencyList[1] as String
            self.currencyButton.setTitle(self.currencyList[1], for: .normal)
            self.saveButtonEvalute()
        }

        let currency2 = UIAlertAction(title: currencyList[2], style: UIAlertAction.Style.default) { (action) in
            self.expenseItemData.currency = self.currencyList[2] as String
            self.currencyButton.setTitle(self.currencyList[2], for: .normal)
            self.saveButtonEvalute()
        }

        actionSheet.addAction(currency0)
        actionSheet.addAction(currency1)
        actionSheet.addAction(currency2)

        // present the action sheet
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @objc func saveAction(_ sender: UIButton?) {
        if expenseItemData.isSubmitted {
            self.showAlert(alertTitle: "notallowededit".localized(), alertMessage: "notallowededitdescription".localized())
            return
        }
        guard let text = descriptionTextField.text else {
            self.showAlert(alertTitle: "moreinfoneeded".localized(), alertMessage: "entertraveldescr".localized())
            return
        }
        guard let amount = Double(amountTextField.text!)  else {
            self.showAlert(alertTitle: "moreinfoneeded".localized(), alertMessage: "enteramount".localized())
            return
        }

        let date = self.datePicker.date
        let currency = self.currencyButton.currentTitle!
        let isSubmitted = false

        let expenseDict = [
            "text" : text,
            "date" : date.timeIntervalSince1970,
            "amount" : amount,
            "currency" : currency,
            "isSubmitted" : isSubmitted
        ] as [String:Any]

        startProgress()

        if let image = capturedImageView.image {
            // Upload the image to Firebase Storage
            self.uploadExpenseImage(image) { url in
                if url != nil {
                    self.saveExpense(expenseDict, imageURL: url!) { success in
                        if success {
                            if self.expenseItemData.imageURL != nil {
                                self.deleteExpenseImage(imageURLString: self.expenseItemData.imageURL) { success in
                                    if !success {
                                        // Handle silently - just print error
                                        print("Error deliting old Image - fix leak!!")
                                    }
                                    self.dismiss(animated: true, completion: nil)
                                }
                            } else {
                                self.dismiss(animated: true, completion: nil)
                            }
                        } else {
                            self.showAlert(alertTitle: "errorsavingexpense".localized())
                        }
                    }
                } else {
                    self.showAlert(alertTitle: "errorsavingimage".localized())
                }
            }
        } else {
            self.saveExpense(expenseDict, imageURL: nil) { success in
                if success {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.showAlert(alertTitle: "errorsavingexpense".localized())
                }
            }
        }
    }

    func showAlertMessageAndStopProgress(alertTitle:String) {
        self.showAlert(alertTitle: alertTitle)
        saveButton.loadingIndicator(false)
    }

    func startProgress() {
        saveButton.loadingIndicator(true)
    }

    func uploadExpenseImage(_ image:UIImage, completion: @escaping ((_ url:URL?)->())) {
        // Maybe use further down - kept for later
        //guard let uid = Auth.auth().currentUser?.uid else { return }
        //Alt 2 generate file name from from uid
        //let storageRef = Constants.storageExpenseImages.child("\(uid)")

        //Alt 1 generate a new uuid to use as file name
        let imageName = UUID().uuidString
        let storageRef = Constants.FirebaseRefs.storageExpenseImages.child("\(imageName).jpg")

        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }

        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"

        storageRef.putData(imageData, metadata: metaData) { metaData, error in
            if error == nil, metaData != nil {
                storageRef.downloadURL { url, error in
                    completion(url)
                }
            } else {
                // failed
                completion(nil)
            }
        }
    }

    func saveExpense(_ expenseDict: [String : Any], imageURL:URL?, completion: @escaping ((_ success:Bool)->())) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Could not find auth user")
            return
        }
        let firebasekeyToSave = expenseItemData.firebasekey ??
            Constants.FirebaseRefs.databaseExpenses.child(uid).childByAutoId().key

        let expenseRef = Constants.FirebaseRefs.databaseExpenses.child(uid).child(firebasekeyToSave!)

        var saveDict = expenseDict
        if (imageURL != nil) {
            saveDict["imageURL"] = imageURL!.absoluteString
        }

        expenseRef.updateChildValues(saveDict) { error, ref in
            completion(error == nil)
        }
    }

    func deleteExpenseImage(imageURLString: String?, completion: @escaping ((_ success:Bool)->())) {
        let storageRef = Storage.storage().reference(forURL: imageURLString!)

        storageRef.delete { error in
            completion(error == nil)
        }
    }

}

extension ExpenseItemViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !takePicture {
            return //we have nothing to do with the image buffer
        }

        //try and get a CVImageBuffer out of the sample buffer
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        //get a CIImage out of the CVImageBuffer
        let ciImage = CIImage(cvImageBuffer: cvBuffer)

        //get UIImage out of CIImage
        let uiImage = UIImage(ciImage: ciImage)

        DispatchQueue.main.async {
            self.capturedImageView.image = uiImage
            self.takePicture = false
        }
    }

    func checkPermissions() {
        let cameraAuthStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthStatus {
          case .authorized:
            return
          case .denied:
            abort()
          case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
            { (authorized) in
              if(!authorized){
                abort()
              }
            })
          case .restricted:
            abort()
          @unknown default:
            fatalError()
        }
    }

    func setupAndStartCaptureSession(){
        DispatchQueue.global(qos: .userInitiated).async{
            //init session
            self.captureSession = AVCaptureSession()
            //start configuration
            self.captureSession.beginConfiguration()

            //session specific configuration
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true

            //setup inputs
            self.setupInputs()

            DispatchQueue.main.async {
                //setup preview layer
                self.setupPreviewLayer()
            }

            //setup output
            self.setupOutput()

            //commit configuration
            self.captureSession.commitConfiguration()
            //start running it
            self.captureSession.startRunning()
        }
    }

    private func setupPreviewLayer(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.insertSublayer(previewLayer, below: captureImageButton.layer)
        previewLayer.frame = self.view.layer.frame
    }

    private func setupInputs(){
        //get back camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            backCamera = device
        } else {
            fatalError("no back camera")
        }

        //now we need to create an input objects from our devices
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("could not create input device from back camera")
        }
        backInput = bInput
        if !captureSession.canAddInput(backInput) {
            fatalError("could not add back camera input to capture session")
        }

        //connect back camera input to session
        captureSession.addInput(backInput)
    }

    private func setupOutput(){
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("could not add video output")
        }

        videoOutput.connections.first?.videoOrientation = .portrait
    }

    @objc func captureImage(_ sender: UIButton?){
        takePicture = true
    }

}

extension ExpenseItemViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        saveButtonEvalute()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case descriptionTextField:
            descriptionTextField.resignFirstResponder()
            amountTextField.becomeFirstResponder()
            break
        case amountTextField:
            amountTextField.resignFirstResponder()
            break
        default:
            break
        }
        return true
    }
}

extension ExpenseItemViewController {
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
        let usernameText = descriptionTextField.text
        let amountText = amountTextField.text
        let allowSave = usernameText != nil && usernameText != "" && amountText != nil && amountText != ""
        saveButton.setEnabled(allowSave)
    }

    func setupView(){
        view.backgroundColor = .gray//.xpnsAppDarkGrey
        view.addSubview(captureImageButton)
        view.addSubview(capturedImageView)
        view.addSubview(descriptionTextField)
        view.addSubview(amountTextField)
        view.addSubview(currencyButton)
        view.addSubview(datePicker)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            captureImageButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            captureImageButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            captureImageButton.widthAnchor.constraint(equalToConstant: 50),
            captureImageButton.heightAnchor.constraint(equalToConstant: 50),

            capturedImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            capturedImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            capturedImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            capturedImageView.heightAnchor.constraint(equalToConstant: 170),

            descriptionTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            descriptionTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            descriptionTextField.trailingAnchor.constraint(equalTo: capturedImageView.leadingAnchor, constant: -10),
            descriptionTextField.heightAnchor.constraint(equalToConstant: 50),

            amountTextField.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 10),
            amountTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            amountTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.40),
            amountTextField.heightAnchor.constraint(equalToConstant: 50),

            currencyButton.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 10),
            currencyButton.leadingAnchor.constraint(equalTo: amountTextField.trailingAnchor, constant: 5),
            currencyButton.trailingAnchor.constraint(equalTo: capturedImageView.leadingAnchor, constant: -10),
            currencyButton.heightAnchor.constraint(equalToConstant: 50),

            datePicker.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 10),
            datePicker.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            datePicker.trailingAnchor.constraint(equalTo: capturedImageView.leadingAnchor, constant: -10),
            datePicker.heightAnchor.constraint(equalToConstant: 50),

            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            saveButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            saveButton.widthAnchor.constraint(equalToConstant: 120),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        captureImageButton.addTarget(self, action: #selector(captureImage(_:)), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveAction(_:)), for: .touchUpInside)
        currencyButton.addTarget(self, action: #selector(currencyButtonClicked(_:)), for: .touchUpInside)

    }

}

