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
    @IBOutlet var segmentControl: UISegmentedControl!
    @IBOutlet var seachBar: UISearchBar!
}

class MainViewController: UIViewController, UIScrollViewDelegate {
    var nativeView: MainControllerView! {
        return self.view as! MainControllerView
    }

    private enum Type: UInt8 {
        case Name = 0
        case Tax = 1
    }
    
    private var type: Type = .Name
    private var companys: [Company] = []
    private var numberOfPages = 0
    private var currentPage = 0
    
    func requestWithSearchString(string: String, completion: (() -> Void)?) {
        let strURL: String
        
        if self.type == .Name {
            strURL = "http://ajpes.intera.si/index/search?search=\(string)&type=title&page=\(self.currentPage)"
        } else {
            strURL = "http://ajpes.intera.si/index/search?search=\(string)&type=tax&page=\(self.currentPage)"
        }
        
        guard let encodedString = strURL.stringByAddingPercentEncodingWithAllowedCharacters(.URLFragmentAllowedCharacterSet()), requestURL = NSURL(string: encodedString) else {
            
            return
        }
        
        let urlRequest = NSMutableURLRequest(URL: requestURL)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) { [unowned self] (data, response, error) in
            if error != nil {
                return
            }
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                
                if let pages = json["pages"] as? Int {
                    self.numberOfPages = pages
                }
                
                if let results = json["results"] as? [[String: AnyObject]] {
                    for result in results {
                        let company = Company()
                        company.fillFromJSON(result)
                        self.companys.append(company)
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        if self.companys.count < 1 {
                            return
                        }
                        
                        if self.currentPage == 0 {
                            self.nativeView.tableView.setContentOffset(CGPointMake(0, 20), animated: true)
                            
                            self.nativeView.tableView.beginUpdates()
                            self.nativeView.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                            self.nativeView.tableView.endUpdates()
                        } else {
                            self.nativeView.tableView.reloadData()
                        }
                        
                        if let completion = completion {
                            completion()
                        }
                    }
                }
                
            }catch {
                print("Error with Json: \(error)")
            }
            
        }
        
        task.resume()
    }
    
    @IBAction func segmentControlTapped(sender: UISegmentedControl) {
        self.type = sender.selectedSegmentIndex == 0 ? .Name : .Tax
        self.nativeView.tableView.setContentOffset(CGPointMake(0, -64), animated: true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showCompanyDetail" {
            let destinationViewController = segue.destinationViewController as! DetailViewController
            
            if let company = sender as? Company {
                destinationViewController.company = company
            }
        }
    }
}

extension MainViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let text = searchBar.text {
            self.companys.removeAll()
            self.currentPage = 0
            searchBar.resignFirstResponder()
            self.requestWithSearchString(text, completion: nil)
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        UIView.animateWithDuration(0.3) {
            searchBar.showsCancelButton = false
            self.view.layoutIfNeeded()
        }
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(true)
        
        self.performSegueWithIdentifier("showCompanyDetail", sender: self.companys[indexPath.row])
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.companys.count ?? 0
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == self.companys.count - 1 && self.numberOfPages > 1 && self.numberOfPages - 1 > self.currentPage {
            let cell = tableView.dequeueReusableCellWithIdentifier("loaderCell") as! LoaderTableViewCell
            cell.spinner.startAnimating()

            if let text = self.nativeView.seachBar.text {
                self.currentPage += 1
                
                weak var weakCell = cell
                self.requestWithSearchString(text, completion: { 
                    weakCell?.spinner.stopAnimating()
                })
            }
            
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
        
        let company = self.companys[indexPath.row]
        cell.textLabel?.text = company.shortName == "/" ? company.fullName : company.shortName
        
        return cell
    }
}