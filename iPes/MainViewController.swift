//
//  ViewController.swift
//  iPes
//
//  Created by Matej Svrznjak on 13/05/2016.
//  Copyright © 2016 Matej Svrznjak. All rights reserved.
//

import UIKit

final class LoaderTableViewCell: UITableViewCell {
    @IBOutlet var spinner: UIActivityIndicatorView!
}

final class MainControllerView: UIView {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var seachBar: UISearchBar!
}

class MainViewController: UIViewController, UIScrollViewDelegate {
    var nativeView: MainControllerView! {
        return self.view as! MainControllerView
    }
    
    private var companys = [Company]()
    private var numberOfPages = 0
    private var currentPage = 0
    private var isLoading = false
    func requestWithSearchString(string: String, completion: ((NSError?) -> Void)?) {
        let strURL = "http://ajpes.intera.si/index/search?search=\(string)&type=title&page=\(self.currentPage)"
        
        guard let encodedString = strURL.stringByAddingPercentEncodingWithAllowedCharacters(.URLFragmentAllowedCharacterSet()), requestURL = NSURL(string: encodedString) else {
            
            return
        }
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        session.dataTaskWithURL(requestURL, completionHandler: { (data, response, error) -> Void in
            if error != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    if let completion = completion {
                        completion(error)
                    }
                }
                
                return
            } else if let jsonData = data {
                do {
                    if self.currentPage == 0 {
                        self.companys.removeAll()
                    }
                    
                    let parsedJSON = try NSJSONSerialization.JSONObjectWithData(jsonData, options: []) as! [String:AnyObject]
                    guard let results = parsedJSON["results"] as? [[String:AnyObject]] else {
                        dispatch_async(dispatch_get_main_queue()) {
                            if let completion = completion {
                                completion(nil)
                            }
                        }
                        
                        return
                    }
                    
                    for result in results {
                        let company = Company()
                        company.fillFromJSON(result)
                        self.companys.append(company)
                    }
                    
                    guard let count = parsedJSON["count"] as? Int else {
                        return
                    }
                    
                    var titleString = "iPes"
                    if count == 1 {
                        titleString = "iPes (\(count) \(NSLocalizedString("Rezultat", comment: "")))"
                    } else if count == 2 {
                        titleString = "iPes (\(count) \(NSLocalizedString("Rezultata", comment: "")))"
                    } else if count == 3 || count == 4 {
                        titleString = "iPes (\(count) \(NSLocalizedString("Rezultati", comment: "")))"
                    } else if count > 2 {
                        titleString = "iPes (\(count) \(NSLocalizedString("Rezultatov", comment: "")))"
                    }
                    
                    if let pages = parsedJSON["pages"] as? Int {
                        self.numberOfPages = pages
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.title = titleString

                        if let completion = completion {
                            completion(nil)
                        }
                    }
                } catch let error as NSError {
                    if let completion = completion {
                        completion(error)
                    }
                }
            }
        }).resume()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showCompanyDetail" {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            let destinationViewController = segue.destinationViewController as! DetailViewController
            
            if let company = sender as? Company {
                destinationViewController.company = company
            }
        }
    }
    
    @IBAction func infoTapped(sender: UIButton) {
        var version = "1.0"
        if let dictionary = NSBundle.mainBundle().infoDictionary {
            version = dictionary["CFBundleShortVersionString"] as! String
        }
        
        let alert = UIAlertController(title: "iPes", message: "\(NSLocalizedString("Verzija", comment: "")) \(version)\nBuild date: 16.05.2016\n\nIntera d.o.o.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "\(NSLocalizedString("Zapri", comment: ""))", style: .Cancel, handler:nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

extension MainViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.companys.removeAll()
        self.currentPage = 0
        
        if searchText.characters.count > 2 {
            self.requestWithSearchString(searchText, completion: { [unowned self] (error) in
                if let error = error {
                    let alert = UIAlertController(title: "\(NSLocalizedString("Napaka", comment: ""))", message: "\(NSLocalizedString("Error tekst", comment: "")) \(error.localizedDescription)", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler:nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                    return
                }
                
                if self.currentPage == 0 && self.companys.count > 0 {
                    self.nativeView.tableView.beginUpdates()
                    self.nativeView.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                    self.nativeView.tableView.endUpdates()
                } else {
                    self.nativeView.tableView.reloadData()
                }
            })
        } else {
            self.title = "iPes"
            self.nativeView.tableView.beginUpdates()
            self.nativeView.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            self.nativeView.tableView.endUpdates()
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        guard let text = searchBar.text else {
            return
        }
        
        if searchBar.text?.characters.count < 3 {
            let alert = UIAlertController(title: "\(NSLocalizedString("Napaka", comment: ""))", message: "\(NSLocalizedString("Napaka vnos", comment: ""))", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler:nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        
        self.companys.removeAll()
        self.currentPage = 0
        
        self.requestWithSearchString(text, completion: { [unowned self] (error) in
            if let error = error {
                let alert = UIAlertController(title: "\(NSLocalizedString("Napaka", comment: ""))", message: "\(NSLocalizedString("Error tekst", comment: "")) \(error.localizedDescription)", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler:nil))
                self.presentViewController(alert, animated: true, completion: nil)
                
                return
            }
            
            if self.currentPage == 0 && self.companys.count > 0 {
                self.nativeView.tableView.beginUpdates()
                self.nativeView.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                self.nativeView.tableView.endUpdates()
            } else {
                self.nativeView.tableView.reloadData()
            }
        })  
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(true)
        
        self.performSegueWithIdentifier("showCompanyDetail", sender: self.companys[indexPath.row])
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if self.companys.count == 1 {
            if self.companys[0].bankAccounts?.count > 0 && indexPath.row == 8 {
                
                var bankAccountsString = ""
                if let bankAccounts = self.companys[0].bankAccounts {
                    for account in bankAccounts {
                        let iban = account["iban"] as! String
                        let accountNumber = account["account_number"] as! String
                        
                        bankAccountsString += "\(iban) \(accountNumber)\n"
                    }
                    let height = bankAccountsString.boundingRectWithSize(CGSizeMake(tableView.bounds.width - 34, CGFloat.max), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName : UIFont.systemFontOfSize(12)], context: nil).height
                    
                    return height + 40
                }

                return 60
            } else if indexPath.row == 0 {
                
                if let name = self.companys[0].fullName {
                    let height = name.boundingRectWithSize(CGSizeMake(tableView.bounds.width - 34, CGFloat.max), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName : UIFont.systemFontOfSize(12)], context: nil).height
                    
                    return height + 40
                }
                
                return 80
            }
        }
        
        return 60
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.companys.count == 1 {
            return self.companys[0].bankAccounts?.count > 0 ? 9 : 8
        }
        
        if self.companys.count == 0 {
            return self.nativeView.seachBar.text?.characters.count > 2 ? 1 : self.companys.count
        }
        
        if self.nativeView.seachBar.text?.characters.count < 3 {
            self.title = "iPes"
            return 0
        }
        
        return self.companys.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if self.companys.count < 2 {
            return false
        }
        
        return true
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        tableView.separatorColor = UIColor.lightGrayColor()
        
        if indexPath.row == self.companys.count - 1 && self.numberOfPages > 1 && self.numberOfPages - 1 > self.currentPage && !self.isLoading {
            let cell = tableView.dequeueReusableCellWithIdentifier("loaderCell") as! LoaderTableViewCell
            cell.spinner.startAnimating()
            self.isLoading = true
            if let text = self.nativeView.seachBar.text {
                self.currentPage += 1
                
                weak var weakCell = cell
                self.requestWithSearchString(text, completion: { [unowned self] (error) in
                    if let error = error {
                        let alert = UIAlertController(title: "\(NSLocalizedString("Napaka", comment: ""))", message: "\(NSLocalizedString("Error tekst", comment: "")) \(error.localizedDescription)", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler:nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                        self.isLoading = false
                        
                        return
                    }
                    
                    weakCell?.spinner.stopAnimating()
                    self.nativeView.tableView.reloadData()
                    self.isLoading = false
                })
            }
            
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
        if self.companys.count < 1 {
            cell.textLabel?.text = "\(NSLocalizedString("Brez zadetkov", comment: "")) \"\(self.nativeView.seachBar.text ?? "")\""
            cell.detailTextLabel?.text = nil
        } else if self.companys.count > 1 {
            let company = self.companys[indexPath.row]
            cell.textLabel?.text = company.shortName == "/" ? company.fullName?.uppercaseString : company.shortName?.uppercaseString
            if let addressStreet = company.addressStreet, houseNumber = company.addressHouseNumber, postNumber = company.addressPostNumber, town = company.addressPost {
                cell.detailTextLabel?.text = "\(addressStreet.uppercaseString) \(houseNumber), \(postNumber) \(town.uppercaseString)"
            }
        } else {
            tableView.separatorColor = UIColor.clearColor()
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "\(NSLocalizedString("Polno ime", comment: ""))"
                cell.detailTextLabel?.text = self.companys[0].fullName?.uppercaseString
            case 1:
                cell.textLabel?.text = "\(NSLocalizedString("Kratko ime", comment: ""))"
                cell.detailTextLabel?.text = self.companys[0].shortName?.uppercaseString
            case 2:
                cell.textLabel?.text = "\(NSLocalizedString("Davčna številka", comment: ""))"
                cell.detailTextLabel?.text = "\(self.companys[0].taxNumber!)"
            case 3:
                cell.textLabel?.text = "\(NSLocalizedString("Matična številka", comment: ""))"
                cell.detailTextLabel?.text = self.companys[0].idNumber?.uppercaseString
            case 4:
                cell.textLabel?.text = "\(NSLocalizedString("Naslov", comment: ""))"
                cell.detailTextLabel?.text = self.companys[0].addressStreet!.uppercaseString + " " + self.companys[0].addressHouseNumber!.uppercaseString
            case 5:
                cell.textLabel?.text = "\(NSLocalizedString("Občina", comment: ""))"
                cell.detailTextLabel?.text = self.companys[0].addressMunicipality?.uppercaseString
            case 6:
                cell.textLabel?.text = "\(NSLocalizedString("Pošta", comment: ""))"
                cell.detailTextLabel?.text = self.companys[0].addressPost?.uppercaseString
            case 7:
                cell.textLabel?.text = "\(NSLocalizedString("Poštna številka", comment: ""))"
                cell.detailTextLabel?.text = self.companys[0].addressPostNumber?.uppercaseString
            case 8:
                var bankAccountsString = ""
                if let bankAccounts = self.companys[0].bankAccounts {
                    for account in bankAccounts {
                        let iban = account["iban"] as! String
                        let accountNumber = account["account_number"] as! String
                        
                        bankAccountsString += "\(iban) \(accountNumber)\n"
                    }
                    
                    cell.textLabel?.text = bankAccounts.count == 1 ? "\(NSLocalizedString("Transakcijski račun", comment: "")):" : "\(NSLocalizedString("Transakcijski račun", comment: ""))i:"
                    cell.detailTextLabel?.text = bankAccountsString
                }
                
            default:
                cell.textLabel?.text = ""
                cell.detailTextLabel?.text = ""
            }
        }
        
        return cell
    }
}