//
//  ViewController.swift
//  checkin
//
//  Created by lcs on 02/11/2016.
//  Copyright © 2016 lcs.io. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var userName: UITextField!
    
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var dateText: UITextField!
   
    @IBAction func datePicker(_ sender: UITextField) {
        let datePickerView:UIDatePicker = UIDatePicker()
        
        datePickerView.datePickerMode = UIDatePickerMode.date
        
        sender.inputView = datePickerView
        
        datePickerView.addTarget(self, action: #selector(ViewController.datePickerValueChanged), for: UIControlEvents.valueChanged)

    }
    
    func datePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale =  Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "yyyy-MM-dd EEEE"
        dateText.text = dateFormatter.string(from: sender.date)
        
    }
    
    @IBAction func checkin(_ sender: UIButton) {
        print(userName.text!)
        print(password.text!)
        print(dateText.text!.components(separatedBy: " "))
        UserDefaults.standard.setValue(userName.text,forKey: "userName")
        UserDefaults.standard.setValue(password.text,forKey: "password")
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dateFormatter = DateFormatter()
        dateFormatter.locale =  Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "yyyy-MM-dd EEEE"
        dateText.text = dateFormatter.string(from: Date())
        userName.text = UserDefaults.standard.string(forKey: "userName")
        password.text = UserDefaults.standard.string(forKey: "password")
        dateText.isUserInteractionEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

