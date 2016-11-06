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
    
    func login( done: @escaping () -> Swift.Void ) {
        let  config = loadConfig()
        
        post(url: config["loginUrl"]! as! String,
             param: String(format:"UserName=%@&Password=%@&x=39&y=8", userName.text! ,password.text! ),
             done: { data in
                done()
            })
    }
    
    func record(){
        let  config = self.loadConfig()
        
        login(done: {
            self.post( url:config["recordUrl"]! as! String , param:"", done:{ data in
                debugPrint("check data \(data)")
                do{
                
                    let json = try JSONSerialization.jsonObject(with: data!,options:JSONSerialization.ReadingOptions.mutableContainers) as! [String:Any]
                    let recordList = json["rows"] as! Array<Dictionary<String,String>>
                debugPrint("recordList \(recordList)")
                }catch{
                }
            })
        })
    
    }
    
    func post( url:String , param:String , done:@escaping (Data?) -> Void ){
        var request = URLRequest(url: URL(string: url)!)
    
        request.httpMethod = "POST"
        request.httpBody = param.data(using: .utf8)
        
        debugPrint("request \(url) : \(param)")
        
        URLSession.shared.dataTask(with: request , completionHandler:{
            (data, response, error)-> Void in
            let httpStatus = response as! HTTPURLResponse
            debugPrint("response : \(httpStatus.statusCode)")
            guard let data = data, error == nil else {
                debugPrint("error=\(error)")
                return
            }
            let responseString = String(data: data, encoding: .utf8)
            debugPrint("responseString  \(responseString)")
            done(data)
            
        }).resume();
        
    }
    
    func loadConfig() -> NSDictionary{
        let plistPath = Bundle.main.path(forResource: "config", ofType: "plist")
        return NSDictionary(contentsOfFile: plistPath!)!
        
    }
}

