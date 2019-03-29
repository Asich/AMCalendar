//
//  ViewController.swift
//  AMCalendar
//
//  Created by Askar Mustafin on 3/26/19.
//  Copyright © 2019 Asich. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    public struct Style {
        public enum FirstWeekdayOptions{
            case sunday
            case monday
        }
        public static var firstWeekday = FirstWeekdayOptions.monday
        public static var timeZone = TimeZone(abbreviation: "UTC")!
        public static var identifier = Calendar.Identifier.gregorian
        public static var locale = Locale.current
    }
    
    public lazy var calendar : Calendar = {
        var calendarStyle = Calendar(identifier: Style.identifier)
        calendarStyle.timeZone = Style.timeZone
        return calendarStyle
    }()
    
    var startDateCache     = Date()
    var endDateCache       = Date()
    var startOfMonthCache  = Date()
    var endOfMonthCache    = Date()
    var todayIndexPath: IndexPath?
    var monthInfoForSection = [Int:(firstDay: Int, daysTotal: Int)]()
    
    var startSelectedIndexPath : IndexPath?
    var endISelectedndexPath : IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configUI()
    }
    
    func configUI() {
        
        let layout = UICollectionViewFlowLayout.init()
        layout.itemSize = CGSize(width: (UIScreen.main.bounds.width / 7) - 6, height: (UIScreen.main.bounds.width / 7) - 6)
        layout.sectionInset = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        view.addSubview(collectionView)
        
        collectionView.backgroundColor = UIColor.red
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AMCell.self, forCellWithReuseIdentifier: AMCell.identifier)
        
        layout.scrollDirection = .vertical
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        let trailing = NSLayoutConstraint(item: collectionView, attribute: .trailing, relatedBy: .equal, toItem: collectionView.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let leading = NSLayoutConstraint(item: collectionView, attribute: .leading, relatedBy: .equal, toItem: collectionView.superview, attribute: .leading, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: collectionView.superview, attribute: .top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: collectionView.superview, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraints([top, leading, trailing, bottom])
        
    }
}


extension ViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            
        }
        
        return AMHeader()
    }
    
    func endDate() -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = -1
        let today = Date()
        let twoYearsFromNow = self.calendar.date(byAdding: dateComponents, to: today)!
        return twoYearsFromNow
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        self.startDateCache = endDate()
        self.endDateCache   = Date()
        
        guard self.startDateCache <= self.endDateCache else { fatalError("Start date cannot be later than end date.") }
        
        var firstDayOfStartMonthComponents = self.calendar.dateComponents([.era, .year, .month], from: self.startDateCache)
        firstDayOfStartMonthComponents.day = 1
        
        let firstDayOfStartMonthDate = self.calendar.date(from: firstDayOfStartMonthComponents)!
        
        self.startOfMonthCache = firstDayOfStartMonthDate
        
        var lastDayOfEndMonthComponents = self.calendar.dateComponents([.era, .year, .month], from: self.endDateCache)
        let range = self.calendar.range(of: .day, in: .month, for: self.endDateCache)!
        lastDayOfEndMonthComponents.day = range.count
        
        self.endOfMonthCache = self.calendar.date(from: lastDayOfEndMonthComponents)!
        
        let today = Date()
        
        if (self.startOfMonthCache ... self.endOfMonthCache).contains(today) {
            
            let distanceFromTodayComponents = self.calendar.dateComponents([.month, .day], from: self.startOfMonthCache, to: today)
            
            self.todayIndexPath = IndexPath(item: distanceFromTodayComponents.day!, section: distanceFromTodayComponents.month!)
        }
        
        return self.calendar.dateComponents([.month], from: startOfMonthCache, to: endOfMonthCache).month! + 1
    }
    
    public func getMonthInfo(for date: Date) -> (firstDay: Int, daysTotal: Int)? {
        
        var firstWeekdayOfMonthIndex    = self.calendar.component(.weekday, from: date)
        firstWeekdayOfMonthIndex       -= Style.firstWeekday == .monday ? 1 : 0
        firstWeekdayOfMonthIndex        = (firstWeekdayOfMonthIndex + 6) % 7
        
        guard let rangeOfDaysInMonth = self.calendar.range(of: .day, in: .month, for: date) else { return nil }
        
        return (firstDay: firstWeekdayOfMonthIndex, daysTotal: rangeOfDaysInMonth.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var monthOffsetComponents = DateComponents()
        monthOffsetComponents.month = section;
        
        guard
            let correctMonthForSectionDate = self.calendar.date(byAdding: monthOffsetComponents, to: startOfMonthCache),
            let info = self.getMonthInfo(for: correctMonthForSectionDate) else { return 0 }
        
        self.monthInfoForSection[section] = info
        
        return 42
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AMCell.identifier, for: indexPath) as! AMCell
        cell.backgroundColor = .green
        
        guard let (firstDayIndex, numberOfDaysTotal) = self.monthInfoForSection[indexPath.section] else { return cell }
        
        let fromStartOfMonthIndexPath = IndexPath(item: indexPath.item - firstDayIndex, section: indexPath.section)
        
        let lastDayIndex = firstDayIndex + numberOfDaysTotal
        
        if (firstDayIndex..<lastDayIndex).contains(indexPath.item) {
            cell.label.text = String(fromStartOfMonthIndexPath.item + 1)
            cell.isHidden = false
            
        } else {
            cell.label.text = ""
            cell.isHidden = true
        }
        
        
        if indexPath == startSelectedIndexPath || indexPath == endISelectedndexPath {
            cell.backgroundColor = .blue
        }
        
        if let startSelectedIndexPath = self.startSelectedIndexPath,
            let endISelectedndexPath = self.endISelectedndexPath {
                if indexPath > startSelectedIndexPath && indexPath < endISelectedndexPath {
                    cell.backgroundColor = .yellow
                }
            if indexPath > endISelectedndexPath && indexPath < startSelectedIndexPath {
                cell.backgroundColor = .yellow
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let (firstDayIndex, numberOfDaysTotal) = self.monthInfoForSection[indexPath.section] else { return }
        print("\(firstDayIndex) , \(numberOfDaysTotal)")
        
        if startSelectedIndexPath == nil {
            startSelectedIndexPath = indexPath
        } else {
            if endISelectedndexPath == nil {
                endISelectedndexPath = indexPath
            } else {
                if startSelectedIndexPath != nil && endISelectedndexPath != nil {
                    startSelectedIndexPath = indexPath
                    endISelectedndexPath = nil
                }
            }
        }
        
        collectionView.reloadData()
    }
}

class AMHeader : UICollectionReusableView {
    
    static let identifier = "CollectionHeader"
    
}

class AMCell : UICollectionViewCell {
    
    static let identifier = "Cell"
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configUI() {
        
        label.textAlignment = .center
        
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        let trailing = NSLayoutConstraint(item: label, attribute: .trailing, relatedBy: .equal, toItem: label.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let leading = NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: label.superview, attribute: .leading, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: label.superview, attribute: .top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: label.superview, attribute: .bottom, multiplier: 1, constant: 0)
        self.addConstraints([top, leading, trailing, bottom])
    }
}
