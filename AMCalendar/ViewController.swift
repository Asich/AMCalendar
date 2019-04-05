//
//  ViewController.swift
//  AMCalendar
//
//  Created by Askar Mustafin on 3/26/19.
//  Copyright © 2019 Asich. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(type: .system)
        button.setTitle("show calendar", for: .normal)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint.init(item: button, attribute: .top, relatedBy: .equal, toItem: button.superview, attribute: .top, multiplier: 1, constant: 100)
        let leading = NSLayoutConstraint.init(item: button, attribute: .leading, relatedBy: .equal, toItem: button.superview, attribute: .leading, multiplier: 1, constant: 16)
        let trailing = NSLayoutConstraint.init(item: button, attribute: .trailing, relatedBy: .equal, toItem: button.superview, attribute: .trailing, multiplier: 1, constant: -16)
        let height = NSLayoutConstraint.init(item: button, attribute: .height, relatedBy: .equal, toItem: button, attribute: .height, multiplier: 1, constant: 0)
        button.addConstraint(height)
        view.addConstraints([top, leading, trailing])
        
        button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
    }
    
    @objc
    func clickButton() {
        
        var calendar = Calendar(identifier: Style.identifier)
        calendar.timeZone = Style.timeZone
        
        var dateComponents = DateComponents()
        dateComponents.year = -1
        let today = Date()
        let twoYearsFromNow = calendar.date(byAdding: dateComponents, to: today)!
        
        
        let vc = AMCalendarViewController.init(startDate: Date(), endDate: twoYearsFromNow)
        self.present(vc, animated: true, completion: nil)
    }
}
