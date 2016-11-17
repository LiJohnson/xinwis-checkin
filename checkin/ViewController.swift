//
//  ViewController.swift
//  checkin
//
//  Created by lcs on 02/11/2016.
//  Copyright © 2016 lcs.io. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    @IBOutlet weak var recordList: UITableView!
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var dateText: UITextField!
    @IBOutlet weak var position: UITextField!
    @IBOutlet weak var switchCheckin: UISwitch!
    
    var dateFormatter:DateFormatter!
    var config:NSDictionary!
    var positionList:Array<String>!
    
    @IBOutlet weak var checkinLable: UILabel!
    
    func initDate() {
        let datePickerView:UIDatePicker = UIDatePicker()
    
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.locale = Locale(identifier: "zh_CN")
        self.dateText.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(ViewController.datePickerValueChanged), for: UIControlEvents.valueChanged)
    }
    
    func initPosition() {
        let positionPicker = UIPickerView()
        positionPicker.dataSource = self
        positionPicker.delegate = self
        self.position.inputView = positionPicker
        self.position.text = self.positionList[Int(arc4random_uniform(UInt32(self.positionList.count)))]
        
   }
    
    func datePickerValueChanged(sender:UIDatePicker) {
        dateText.text = dateFormatter.string(from: sender.date)
    }
    
    @IBAction func checkin(_ sender: UIButton) {
        dateText.text = dateFormatter.string(from: (dateText.inputView as! UIDatePicker).date )
        UserDefaults.standard.setValue(userName.text,forKey: "userName")
        UserDefaults.standard.setValue(password.text,forKey: "password")
        checkin()
        record()
    }
    @IBAction func switchCheckinValue(_ sender: UISwitch) {
        print(sender.isOn)
        self.checkinLable.text = self.getChecknText(isText: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.config = self.loadConfig()
        self.positionList = self.config["positionList"] as! Array<String>
        self.initDate()
        self.initPosition()
        self.switchCheckin.isOn = !self.isCheckOut()
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale =  Locale(identifier: "zh_CN")
        self.dateFormatter.dateFormat = "yyyy-MM-dd EEEE"
        
        self.dateText.text = self.dateFormatter.string(from: (self.dateText.inputView as! UIDatePicker).date )
        self.userName.text = UserDefaults.standard.string(forKey: "userName")
        self.password.text = UserDefaults.standard.string(forKey: "password")
        self.checkinLable.text = self.getChecknText(isText: true)
        
        recordList.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func login( done: @escaping () -> Swift.Void ) {
        let  config = loadConfig()
        post(url: config["loginUrl"]! as! String,
                param: String(format:"UserName=%@&Password=%@&x=39&y=8&gourl=r?wf_num=R_Happ013_B002", userName.text! ,password.text!),
                done: { data in
                done()
            })
    }
    
    func checkin(){
        let date = dateText.text!.components(separatedBy: " ")
        let postData:String = String(format:"AttType=%@&AttWeek=%@&AttPosition=%@&AttDate=%@&AttRule=广州打卡&AttLongitude=113.3662&AttLatitude=23.10571&InTime=09:10&OutTime=18:00",
                                     self.getChecknText(isText: false),
                                     date[1],
                                     self.position.text!,
                                     date[0]);
        self.login {
            self.post(url: self.config["checkinUrl"]! as! String ,
                      param: postData, done: { data in
                        print("lclslsl \(data)")
            })
        }
    }
    
    func record(){
        login(done: {
            self.post( url:self.config["recordUrl"]! as! String , param:"", done:{ data in
                debugPrint("check data \(data)")
                do{
                    let json = try JSONSerialization.jsonObject(with: data!,options:JSONSerialization.ReadingOptions.mutableContainers) as! [String:Any]
                    let recordList = json["rows"] as! Array<Dictionary<String,String>>
                    debugPrint("recordList \(recordList)")
                    self.recordList.dataSource = RecordListDataList(aList:recordList)
                    self.recordList.reloadData()
                    self.recordList.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
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
    
    func getChecknText(isText:Bool) -> String {
        if(isText){
            return self.switchCheckin.isOn ? "签到" :"签退"
        }else{
            return self.switchCheckin.isOn ? "1" :"2"
        }
        
        
    }
    
    func loadConfig() -> NSDictionary{
        let plistPath = Bundle.main.path(forResource: "config", ofType: "plist")
        return NSDictionary(contentsOfFile: plistPath!)!
        
    }
    
    func isCheckOut() -> Bool {
        let now = Date();
        let fmt = DateFormatter()
        fmt.dateFormat = "HH"
        let hour:Int = Int(fmt.string(from: now))!
        
        debugPrint("now time is \(hour)")
        
        return hour >= 18
    }
}

extension ViewController: UIPickerViewDelegate {
    @available(iOS 2.0, *)
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
 
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        return self.positionList[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        self.position.text = self.positionList[row]
    }
}


extension ViewController: UIPickerViewDataSource {
    @available(iOS 2.0, *)
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.positionList.count
    }
}


