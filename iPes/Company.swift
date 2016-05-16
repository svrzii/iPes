//
//  Company.swift
//  iPes
//
//  Created by Matej Svrznjak on 13/05/2016.
//  Copyright © 2016 Matej Svrznjak. All rights reserved.
//

import Foundation

class Company: NSObject {
    var fullName: String?
    var shortName: String?
    var taxNumber: Int?
    var idNumber: String?
    var addressStreet: String?
    var addressHouseNumber: String?
    var addressMunicipality: String?
    var addressPost: String?
    var addressPostNumber: String?
    var bankAccounts: [[String: AnyObject]]?
    
    func fillFromJSON(result: [String: AnyObject]) {
        self.fullName = result["full_name"] as? String
        self.shortName = result["short_name"] as? String
        self.taxNumber = result["tax_number"] as? Int
        self.idNumber = result["id_number"] as? String
        self.addressStreet = result["address_street"] as? String
        self.addressPost = result["address_post"] as? String
        self.addressHouseNumber = result["address_house_num"] as? String
        self.addressMunicipality = result["address_municipality"] as? String
        self.addressPostNumber = result["address_post_num"] as? String
        self.bankAccounts = result["trs"] as? [[String: AnyObject]]
    }
}

