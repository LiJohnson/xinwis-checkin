//
//  RecordListDataSorce.swift
//  checkin
//
//  Created by lcs on 07/11/2016.
//  Copyright © 2016 lcs.io. All rights reserved.
//

import Foundation
import UIKit

class RecordListDataList :NSObject, UITableViewDataSource{
   
    var list:Array<Any> = []
    
    init( aList:Array<Any> ){
        self.list = aList
        
    }
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.list.count
    }
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let data = list[indexPath.row]
        cell.textLabel?.text = "adf \(data)"
        cell.detailTextLabel?.text="subtitle#\(indexPath.row)"
        
        return cell
    }
    
}
