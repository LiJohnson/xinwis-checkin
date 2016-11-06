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
    var dateFormatter:DateFormatter!
    
    func initDate() {
        let datePickerView:UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.locale = Locale(identifier: "zh_CN")
        dateText.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(ViewController.datePickerValueChanged), for: UIControlEvents.valueChanged)
    }
    
    func datePickerValueChanged(sender:UIDatePicker) {
        dateText.text = dateFormatter.string(from: sender.date)
    }
    
    @IBAction func checkin(_ sender: UIButton) {
        //print(userName.text!)
        //print(password.text!)
        //print(dateText.text!.components(separatedBy: " "))
        //print(dateFormatter.string(from: (dateText.inputView as! UIDatePicker).date))
        UserDefaults.standard.setValue(userName.text,forKey: "userName")
        UserDefaults.standard.setValue(password.text,forKey: "password")
        
        
        record()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initDate()
        dateFormatter = DateFormatter()
        dateFormatter.locale =  Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "yyyy-MM-dd EEEE"
        
        dateText.text = dateFormatter.string(from: (dateText.inputView as! UIDatePicker).date  )
        userName.text = UserDefaults.standard.string(forKey: "userName")
        password.text = UserDefaults.standard.string(forKey: "password")
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func login( done: @escaping () -> Swift.Void ) -> URLSessionDataTask {
        let  config = loadConfig()
        var request = URLRequest(url: URL(string: config["loginUrl"]! as! String)!)
        
        request.httpMethod = "POST"
        request.httpBody = String(format:"UserName=%@&Password=%@&x=39&y=8", userName.text! ,password.text! ).data(using: .utf8)
        
        let session = URLSession.shared

        print("request \(request)")

        let dataTask:URLSessionDataTask = session.dataTask(with: request , completionHandler:{
            (data, response, error)-> Void in
            let httpStatus = response as! HTTPURLResponse
            debugPrint("response : \(httpStatus.statusCode)")
            guard let data = data, error == nil else {                                                 // check for
                print("error=\(error)")
                return
            }
            done()
            //let responseString = String(data: data, encoding: .utf8)
            //print("responseString  \(responseString)")
        
        })
        
        dataTask.resume()
        
        return dataTask
    }
    
    func record(){
        login(done: {
            let  config = self.loadConfig()
            var request = URLRequest(url: URL(string: config["recordUrl"]! as! String)!)
            
            request.httpMethod = "GET"
                        print("request \(request)")
            
            let dataTask:URLSessionDataTask = URLSession.shared.dataTask(with: request , completionHandler:{
                (data, response, error)-> Void in
                let httpStatus = response as! HTTPURLResponse
                debugPrint("response : \(httpStatus.statusCode)")
                guard let data = data, error == nil else {                                                 // check for
                    print("error=\(error)")
                    return
                }
                let responseString = String(data: data, encoding: .utf8)
                print("responseString  \(responseString)")
                
            })
            
            dataTask.resume()
        })
        
    }
    
    
    func loadConfig() -> NSDictionary{
        let plistPath = Bundle.main.path(forResource: "config", ofType: "plist")
        return NSDictionary(contentsOfFile: plistPath!)!
        
    }
}

