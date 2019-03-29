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
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 50)
        let collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        view.addSubview(collectionView)
        
        collectionView.backgroundColor = UIColor.red
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AMCell.self, forCellWithReuseIdentifier: AMCell.identifier)
        collectionView.register(AMHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: AMHeader.identifier)
        
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
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: AMHeader.identifier, for: indexPath) as! AMHeader
            
            //header.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50)

//            let monthComponents = self.calendar.dateComponents([.month], from: self.startDateCache, to: self.endDateCache)
//            let monthComponent = monthComponents

            return header
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
        
        if let todayIndexPath = self.todayIndexPath {
            if indexPath == IndexPath(row: todayIndexPath.row + firstDayIndex, section: todayIndexPath.section) {
                cell.label.textColor = .gray
            } else {
                cell.label.textColor = .black
            }
        } else {
            cell.label.textColor = .black
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
//    let label = UILabel()
    let daysStack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configUI() {
        
//        label.textAlignment = .center
//
//        self.addSubview(label)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        let trailing = NSLayoutConstraint(item: label, attribute: .trailing, relatedBy: .equal, toItem: label.superview, attribute: .trailing, multiplier: 1, constant: 0)
//        let leading = NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: label.superview, attribute: .leading, multiplier: 1, constant: 0)
//        let top = NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: label.superview, attribute: .top, multiplier: 1, constant: 0)
//        self.addConstraints([top, leading, trailing])
//
        self.addSubview(daysStack)
        daysStack.translatesAutoresizingMaskIntoConstraints = false
        let strailing = NSLayoutConstraint(item: daysStack, attribute: .trailing, relatedBy: .equal, toItem: daysStack.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let sleading = NSLayoutConstraint(item: daysStack, attribute: .leading, relatedBy: .equal, toItem: daysStack.superview, attribute: .leading, multiplier: 1, constant: 0)
        let stop = NSLayoutConstraint(item: daysStack, attribute: .top, relatedBy: .equal, toItem: daysStack.superview, attribute: .top, multiplier: 1, constant: 0)
        let sbottom = NSLayoutConstraint(item: daysStack, attribute: .bottom, relatedBy: .equal, toItem: daysStack.superview, attribute: .bottom, multiplier: 1, constant: 0)
        self.addConstraints([stop, sleading, strailing, sbottom])


        daysStack.distribution = .fillEqually
        daysStack.axis = .horizontal
        daysStack.spacing = 3

        let fmt = DateFormatter()
        let firstWeekday = 2 // -> Monday
        if var symbols = fmt.shortWeekdaySymbols {
            symbols = Array(symbols[firstWeekday-1..<symbols.count]) + symbols[0..<firstWeekday-1]
            for day in symbols {
                let v = UILabel()
                v.backgroundColor = .yellow
                v.textAlignment = .center
                let width = (UIScreen.main.bounds.width / 7) - 6
                v.addConstraint(NSLayoutConstraint(item: v, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: width))
                v.addConstraint(NSLayoutConstraint(item: v, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: width))
                v.text = day
                daysStack.addArrangedSubview(v)
            }
        }
    }
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
