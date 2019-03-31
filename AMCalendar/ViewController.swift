//
//  ViewController.swift
//  AMCalendar
//
//  Created by Askar Mustafin on 3/26/19.
//  Copyright © 2019 Asich. All rights reserved.
//

import UIKit

struct Style {
    public enum FirstWeekdayOptions{
        case sunday
        case monday
    }
    public static var firstWeekday = FirstWeekdayOptions.monday
    public static var timeZone = TimeZone.current
    public static var identifier = Calendar.Identifier.gregorian
    public static var locale = getPreferredLocale()
    
    static func getPreferredLocale() -> Locale {
        guard let preferredIdentifier = Locale.preferredLanguages.first else {
            return Locale.current
        }
        return Locale(identifier: preferredIdentifier)
    }
}

class ViewController: UIViewController {
    
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
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 100)
        let collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        view.addSubview(collectionView)
        
        collectionView.backgroundColor = UIColor.white
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
            
            let month = indexPath.section
            if let _ = monthInfoForSection[month] {
                var components = DateComponents()
                components.month = month
                if let date = self.calendar.date(byAdding: components, to: self.startDateCache) {
                    let dateFormatter = DateFormatter()
                    dateFormatter.locale = Style.locale
                    dateFormatter.dateFormat = "MMMM yyyy"
                    let dateString = dateFormatter.string(from: date)
                    header.label.text = dateString.firstUppercased
                }
            }
            
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
        lastDayOfEndMonthComponents.day = range.count + 1
        self.endOfMonthCache = self.calendar.date(from: lastDayOfEndMonthComponents)!
        
        let today = Date()
        
        if (self.startOfMonthCache ... self.endOfMonthCache).contains(today) {
            let distanceFromTodayComponents = self.calendar.dateComponents([.month, .day], from: self.startOfMonthCache, to: today)
            self.todayIndexPath = IndexPath(item: distanceFromTodayComponents.day!, section: distanceFromTodayComponents.month!)
        }
        
        return self.calendar.dateComponents([.month], from: startOfMonthCache, to: endOfMonthCache).month!
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let (firstDayIndex, _) = self.monthInfoForSection[indexPath.section] else { return }
        guard let cell = cell as? AMCell else { return }
        
        if let todayIndexPath = self.todayIndexPath {
            if indexPath == IndexPath(row: todayIndexPath.row + firstDayIndex, section: todayIndexPath.section) {
                cell.label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            } else {
                cell.label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            }
        } else {
            cell.label.textColor = .black
        }
        
        if indexPath == startSelectedIndexPath || indexPath == endISelectedndexPath {
            cell.backgroundColor = UIColor(hexFromString: "49A8FF")
        }
        
        if let startSelectedIndexPath = self.startSelectedIndexPath,
            let endISelectedndexPath = self.endISelectedndexPath {
            if indexPath > startSelectedIndexPath && indexPath < endISelectedndexPath {
                cell.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
            }
            if indexPath > endISelectedndexPath && indexPath < startSelectedIndexPath {
                cell.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AMCell.identifier, for: indexPath) as! AMCell
        cell.backgroundColor = .white
        
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
    
//    func dateFromIndexPath(_ indexPath: IndexPath) -> Date? {
//
//        let month = indexPath.section
//        guard let monthInfo = monthInfoForSection[month] else { return nil }
//
//        var components      = DateComponents()
//        components.month    = month
//        components.day      = indexPath.item - monthInfo.firstDay
//
//        return self.calendar.date(byAdding: components, to: self.startOfMonthCache)
//    }
}

class AMHeader : UICollectionReusableView {
    
    static let identifier = "CollectionHeader"
    let label = UILabel()
    let daysStack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configUI() {
        
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = .left

        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        let leading = NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: label.superview, attribute: .leading, multiplier: 1, constant: 16)
        let trailing = NSLayoutConstraint(item: label, attribute: .trailing, relatedBy: .equal, toItem: label.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: label.superview, attribute: .top, multiplier: 1, constant: 0)
        self.addConstraints([top, leading, trailing])
        
        
        let line1 = UIView()
        line1.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        self.addSubview(line1)
        line1.translatesAutoresizingMaskIntoConstraints = false
        let line1Leading = NSLayoutConstraint(item: line1, attribute: .leading, relatedBy: .equal, toItem: line1.superview, attribute: .leading, multiplier: 1, constant: 0)
        let line1Trailing = NSLayoutConstraint(item: line1, attribute: .trailing, relatedBy: .equal, toItem: line1.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let line1Top = NSLayoutConstraint(item: line1, attribute: .top, relatedBy: .equal, toItem: label, attribute: .bottom, multiplier: 1, constant: 0)
        let line1Height = NSLayoutConstraint(item: line1, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 1)
        line1.addConstraint(line1Height)
        self.addConstraints([line1Top, line1Leading, line1Trailing])
        
        
        self.addSubview(daysStack)
        daysStack.translatesAutoresizingMaskIntoConstraints = false
        let strailing = NSLayoutConstraint(item: daysStack, attribute: .trailing, relatedBy: .equal, toItem: daysStack.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let sleading = NSLayoutConstraint(item: daysStack, attribute: .leading, relatedBy: .equal, toItem: daysStack.superview, attribute: .leading, multiplier: 1, constant: 0)
        let stop = NSLayoutConstraint(item: daysStack, attribute: .top, relatedBy: .equal, toItem: line1, attribute: .bottom, multiplier: 1, constant: 0)
        self.addConstraints([stop, sleading, strailing])
        
        
        let line2 = UIView()
        line2.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        self.addSubview(line2)
        line2.translatesAutoresizingMaskIntoConstraints = false
        let line2Leading = NSLayoutConstraint(item: line2, attribute: .leading, relatedBy: .equal, toItem: line2.superview, attribute: .leading, multiplier: 1, constant: 0)
        let line2Trailing = NSLayoutConstraint(item: line2, attribute: .trailing, relatedBy: .equal, toItem: line2.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let line2Top = NSLayoutConstraint(item: line2, attribute: .top, relatedBy: .equal, toItem: daysStack, attribute: .bottom, multiplier: 1, constant: 0)
         let line2Bottom = NSLayoutConstraint(item: line2, attribute: .bottom, relatedBy: .equal, toItem: line2.superview, attribute: .bottom, multiplier: 1, constant: 0)
        let line2Height = NSLayoutConstraint(item: line2, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 1)
        line2.addConstraint(line2Height)
        self.addConstraints([line2Top, line2Leading, line2Trailing, line2Bottom])


        daysStack.distribution = .fillEqually
        daysStack.axis = .horizontal
        daysStack.spacing = 3

        let fmt = DateFormatter()
        fmt.locale = Style.locale
        let firstWeekday = 2 // -> Monday
        if var symbols = fmt.shortWeekdaySymbols {
            symbols = Array(symbols[firstWeekday-1..<symbols.count]) + symbols[0..<firstWeekday-1]
            for day in symbols {
                let v = UILabel()
                v.textColor = UIColor.lightGray.withAlphaComponent(0.7)
                v.backgroundColor = .white
                v.textAlignment = .center
                let width = (UIScreen.main.bounds.width / 7) - 6
                v.addConstraint(NSLayoutConstraint(item: v, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: width))
                v.addConstraint(NSLayoutConstraint(item: v, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: width))
                v.text = day.uppercased()
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
        label.font = UIFont.systemFont(ofSize: 16)
        
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        let trailing = NSLayoutConstraint(item: label, attribute: .trailing, relatedBy: .equal, toItem: label.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let leading = NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: label.superview, attribute: .leading, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: label.superview, attribute: .top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: label.superview, attribute: .bottom, multiplier: 1, constant: 0)
        self.addConstraints([top, leading, trailing, bottom])
    }
}

extension UIColor {
    convenience init(hexFromString:String, alpha:CGFloat = 1.0) {
        var cString:String = hexFromString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        var rgbValue:UInt32 = 10066329 //color #999999 if string has wrong format
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) == 6) {
            Scanner(string: cString).scanHexInt32(&rgbValue)
        }
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

extension StringProtocol {
    var firstUppercased: String {
        return prefix(1).uppercased() + dropFirst()
    }
}
