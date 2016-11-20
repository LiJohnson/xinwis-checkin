//
//  ViewController.swift
//  checkin
//
//  Created by lcs on 02/11/2016.
//  Copyright © 2016 lcs.io. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var recordList: UITableView!
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var dateText: UITextField!
    @IBOutlet weak var position: UITextField!
    @IBOutlet weak var switchCheckin: UISwitch!
    @IBOutlet weak var checkinLable: UILabel!
    @IBOutlet weak var distanceText: UILabel!
    
    var dateFormatter:DateFormatter!
    var config:NSDictionary!
    var positionList:Array<String>!
    var recordListData:Array<Dictionary<String,String>>!
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    var checkinLocation: CLLocation!
    //var geoCodeer: CLGeocoder!
    var distance: Int!
    
    func initDate() {
        let datePickerView:UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.locale = Locale(identifier: "zh_CN")
        datePickerView.addTarget(self, action: #selector(ViewController.datePickerValueChanged), for: UIControlEvents.valueChanged)
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        toolBar.setItems([
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(ViewController.closePicker))
            ], animated: false)
        
        self.dateText.inputView = datePickerView
        self.dateText.inputAccessoryView = toolBar
    }
    
    func initPosition() {
        let positionPicker = UIPickerView()
        positionPicker.dataSource = self
        positionPicker.delegate = self
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        toolBar.setItems([
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(ViewController.closePicker))
            ], animated: false)
        
        self.position.inputAccessoryView = toolBar
        self.position.inputView = positionPicker
        self.position.text = self.positionList[Int(arc4random_uniform(UInt32(self.positionList.count)))]
   }
    
    func datePickerValueChanged(sender:UIDatePicker) {
        dateText.text = dateFormatter.string(from: sender.date)
    }
    
    func closePicker(sender:UIView)  {
        debugPrint(sender)
        if self.position.isEditing {
            debugPrint("endEditing position")
            self.position.endEditing(false)
        }
        if self.dateText.isEditing{
            debugPrint("endEditing dateText")
            self.dateText.endEditing(false)
        }
        
    }
    
    @IBAction func checkin(_ sender: UIButton) {
        dateText.text = dateFormatter.string(from: (dateText.inputView as! UIDatePicker).date )
        UserDefaults.standard.setValue(userName.text,forKey: "userName")
        UserDefaults.standard.setValue(password.text,forKey: "password")
        checkin()
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
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.recordList.dataSource = self
        self.recordList.delegate = self
        self.recordListData = Array()
        self.switchCheckin.isOn = !self.isCheckOut()
        self.dateFormatter = DateFormatter()
        self.dateFormatter.locale =  Locale(identifier: "zh_CN")
        self.dateFormatter.dateFormat = "yyyy-MM-dd EEEE"
        
        self.dateText.text = self.dateFormatter.string(from: (self.dateText.inputView as! UIDatePicker).date )
        self.userName.text = UserDefaults.standard.string(forKey: "userName")
        self.password.text = UserDefaults.standard.string(forKey: "password")
        self.checkinLable.text = self.getChecknText(isText: true)
        
        self.checkinLocation = CLLocation(
            latitude:self.config["checkinLatitude"] as! Double ,
            longitude:self.config["checkinLongitude"] as! Double)
        self.getLocaltion()
        self.position.text = "-----"
        record()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func login( done: @escaping () -> Swift.Void ) {
        self.recordListData.removeAll()
        self.recordList.reloadData()
        self.recordList.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
        
        post(url: self.config["loginUrl"]! as! String,
                param: String(format:self.config["loginParam"]! as! String,
                              userName.text!,
                              password.text!),
                done: { data in
                done()
            })
    }
    
    func checkin(){
        if !(self.currentLocation != nil) {
            self.alert(message: "no location")
            return
        }        
        
        if( (self.config["checkinRange"] as! Int) < Int(self.distanceText.text!)! ){
            self.alert(message: "too far away")
            return
        }
        self.position.text = "-----"
        self.login {
            self.getAddress { (address) in
                DispatchQueue.main.async {
                   self.position.text = address
                }
                
                debugPrint("update position \(address)")
            
                let date = self.dateText.text!.components(separatedBy: " ")
                let postData:String = String(format:self.config["checkinParam"] as! String,
                                         self.getChecknText(isText: false),
                                         date[1],
                                         self.position.text!,
                                         date[0]);
            
                self.post(url: self.config["checkinUrl"]! as! String ,
                          param: postData, done: { data in
                            self.record()
                })
            }
        }
    }
    
    func record(){
        login(done: {
            self.post( url:self.config["recordUrl"]! as! String , param:"", done:{ data in
                do{
                    let json = try JSONSerialization.jsonObject(with: data!,options:JSONSerialization.ReadingOptions.mutableContainers) as! [String:Any]
                    self.recordListData = json["rows"] as! Array<Dictionary<String,String>>
                    debugPrint("recordList \(self.recordListData)")
                    self.recordList.reloadData()
                    self.recordList.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: true)
                }catch{
                }
            })
        })
    
    }
    
    func getAddress(done: @escaping (String?) -> Void) {
        let url = String(format: self.config["addressUrl"]! as! String , self.currentLocation.coordinate.latitude,self.currentLocation.coordinate.longitude)
        self.post(url: url ,param:"",done:{ data in
            do{
                let json = try JSONSerialization.jsonObject(with: data!,options:JSONSerialization.ReadingOptions.mutableContainers) as! [String:Any]
                let result:Dictionary<String,Any> = json["result"] as! Dictionary<String,Any>
                let address:String = result["formatted_address"] as! String
                debugPrint("result[formatted_address] \(address)")
                done(address)
                
            }catch{
            }
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
    
    func alert(message:String){
        let alert = UIAlertController(title: "!!!", message: message , preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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

extension ViewController: UITableViewDelegate{
}

extension ViewController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.recordListData.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "recordCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "recordCell")

        let data:Dictionary<String,String> = self.recordListData[indexPath.row]

        debugPrint( data )

        cell.textLabel?.text = "\(data["AttDate"]!) \(data["ActTime"]!) , \(data["AttType"]!)-\(data["AttStatus"]!)"
        
        cell.detailTextLabel?.text = data["AttPosition"]

        return cell
    }
}

extension ViewController:CLLocationManagerDelegate{
    
    func getLocaltion(){
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }}
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        self.currentLocation = locations.last!
        
        self.distanceText.text = String( Int(self.currentLocation.distance(from: self.checkinLocation)) )
        debugPrint(self.currentLocation.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint(error)
    }
}

