//
//  AMCalendarViewController.swift
//  AMCalendar
//
//  Created by Askar Mustafin on 4/1/19.
//  Copyright © 2019 Asich. All rights reserved.
//

import UIKit

struct Style {
    public enum FirstWeekdayOptions {
        case sunday
        case monday
    }

    public static var firstWeekday = FirstWeekdayOptions.monday
    public static var timeZone = TimeZone.current
    public static var identifier = Calendar.Identifier.gregorian
    public static var locale: Locale {
        return Locale.current
    }
}

class AMCalendarViewController: UIViewController {
    public lazy var calendar: Calendar = {
        var calendarStyle = Calendar(identifier: Style.identifier)
        calendarStyle.timeZone = Style.timeZone
        return calendarStyle
    }()

    var proceedButton = UIButton(type: .system)
    var completion: ((Date, Date) -> Void)?

    var startDateCache = Date()
    var endDateCache = Date()
    var startOfMonthCache = Date()
    var endOfMonthCache = Date()
    var monthInfoForSection = [Int: (firstDay: Int, daysTotal: Int)]()
    var todayIndexPath: IndexPath?

    var startSelectedIndexPath: IndexPath?
    var endISelectedndexPath: IndexPath?

    var isBottom = false
    var maxDays: Int? = 14

    init(startDate: Date, endDate: Date) {
        startDateCache = endDate
        endDateCache = startDate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        waitForComplete()
    }

    private func waitForComplete() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let collectionView = (self.view.subviews.first { $0.tag == 111 }) as? UICollectionView {
                let lastSection = collectionView.numberOfSections - 1
                let lastRow = collectionView.numberOfItems(inSection: lastSection)
                let indexPath = IndexPath(row: lastRow - 1, section: lastSection)
                collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.bottom, animated: false)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    @objc
    private func hideModalVC() {
        dismiss(animated: true, completion: nil)
    }

    private func configUI() {
        let exitImage = UIImage(named: "close")
        let exitItem = UIBarButtonItem(image: exitImage, style: .plain, target: self, action: #selector(hideModalVC))
        navigationItem.rightBarButtonItem = exitItem

        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets.zero
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 100)
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.tag = 111
        view.addSubview(collectionView)

        collectionView.backgroundColor = UIColor.white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AMCell.self, forCellWithReuseIdentifier: AMCell.identifier)
        collectionView.register(AMHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: AMHeader.identifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        layout.scrollDirection = .vertical

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        let trailing = NSLayoutConstraint(item: collectionView, attribute: .trailing, relatedBy: .equal, toItem: collectionView.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let leading = NSLayoutConstraint(item: collectionView, attribute: .leading, relatedBy: .equal, toItem: collectionView.superview, attribute: .leading, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: collectionView.superview, attribute: .top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: collectionView.superview, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraints([top, leading, trailing, bottom])

        view.addSubview(proceedButton)
        proceedButton.setTitle("Показать", for: .normal)
        proceedButton.backgroundColor = UIColor(hexFromString: "49A8FF")
        proceedButton.layer.cornerRadius = 10
        proceedButton.setTitleColor(.white, for: .normal)
        proceedButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        proceedButton.addTarget(self, action: #selector(clickProceedButton), for: .touchUpInside)
        proceedButton.translatesAutoresizingMaskIntoConstraints = false
        proceedButton.isHidden = true
        let btrailing = NSLayoutConstraint(item: proceedButton, attribute: .trailing, relatedBy: .equal, toItem: proceedButton.superview, attribute: .trailing, multiplier: 1, constant: -16)
        let bleading = NSLayoutConstraint(item: proceedButton, attribute: .leading, relatedBy: .equal, toItem: proceedButton.superview, attribute: .leading, multiplier: 1, constant: 16)
        let bbottom = NSLayoutConstraint(item: proceedButton, attribute: .bottom, relatedBy: .equal, toItem: proceedButton.superview, attribute: .bottom, multiplier: 1, constant: -30)
        let bheight = NSLayoutConstraint(item: proceedButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 48)
        proceedButton.addConstraint(bheight)
        view.addConstraints([bleading, btrailing, bbottom])
    }

    @objc
    private func clickProceedButton() {
        dismiss(animated: true) { [weak self] in
            guard let completion = self?.completion,
                let startIndex = self?.startSelectedIndexPath,
                let endIndex = self?.endISelectedndexPath else {
                return
            }

            guard let startDate = self?.dateFromIndexPath(startIndex),
                let endDate = self?.dateFromIndexPath(endIndex) else {
                return
            }

            if startDate > endDate {
                completion(startDate, endDate)
            } else {
                completion(endDate, startDate)
            }
        }
    }

    private func dateFromIndexPath(_ indexPath: IndexPath) -> Date? {
        let month = indexPath.section

        guard let monthInfo = monthInfoForSection[month] else { return nil }

        var components = DateComponents()
        components.month = month
        components.day = indexPath.item - monthInfo.firstDay + 1

        return calendar.date(byAdding: components, to: startOfMonthCache)
    }
    
    deinit {
        print("AMCalendar deinit")
    }
}

extension AMCalendarViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = Int(UIScreen.main.bounds.width)
        let side = width / 7
        let rem = width % 7
        let addOne = indexPath.row % 7 < rem
        let ceilWidth = addOne ? side + 1 : side
        return CGSize(width: ceilWidth, height: side)
    }

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
                    dateFormatter.dateFormat = "LLLL yyyy"
                    let dateString = dateFormatter.string(from: date)
                    header.label.text = dateString.firstUppercased
                }
            }

            return header
        }

        return AMHeader()
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        guard startDateCache <= endDateCache else { fatalError("Start date cannot be later than end date.") }

        var firstDayOfStartMonthComponents = calendar.dateComponents([.era, .year, .month], from: startDateCache)
        firstDayOfStartMonthComponents.day = 1
        let firstDayOfStartMonthDate = calendar.date(from: firstDayOfStartMonthComponents)!
        startOfMonthCache = firstDayOfStartMonthDate

        var lastDayOfEndMonthComponents = calendar.dateComponents([.era, .year, .month], from: endDateCache)
        let range = calendar.range(of: .day, in: .month, for: endDateCache)!
        lastDayOfEndMonthComponents.day = range.count + 1
        endOfMonthCache = calendar.date(from: lastDayOfEndMonthComponents)!

        let today = Date()

        if (startOfMonthCache ... endOfMonthCache).contains(today) {
            let distanceFromTodayComponents = calendar.dateComponents([.month, .day], from: startOfMonthCache, to: today)
            todayIndexPath = IndexPath(item: distanceFromTodayComponents.day!, section: distanceFromTodayComponents.month!)
        }

        return calendar.dateComponents([.month], from: startOfMonthCache, to: endOfMonthCache).month!
    }

    public func getMonthInfo(for date: Date) -> (firstDay: Int, daysTotal: Int)? {
        var firstWeekdayOfMonthIndex = calendar.component(.weekday, from: date)
        firstWeekdayOfMonthIndex -= Style.firstWeekday == .monday ? 1 : 0
        firstWeekdayOfMonthIndex = (firstWeekdayOfMonthIndex + 6) % 7

        guard let rangeOfDaysInMonth = self.calendar.range(of: .day, in: .month, for: date) else { return nil }

        return (firstDay: firstWeekdayOfMonthIndex, daysTotal: rangeOfDaysInMonth.count)
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var monthOffsetComponents = DateComponents()
        monthOffsetComponents.month = section

        guard
            let correctMonthForSectionDate = self.calendar.date(byAdding: monthOffsetComponents, to: startOfMonthCache),
            let info = self.getMonthInfo(for: correctMonthForSectionDate) else { return 0 }

        monthInfoForSection[section] = info

        return 42
    }

    func collectionView(_: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let (firstDayIndex, _) = self.monthInfoForSection[indexPath.section] else { return }
        guard let cell = cell as? AMCell else { return }

        if let todayIndexPath = self.todayIndexPath {
            if indexPath == IndexPath(row: todayIndexPath.row + firstDayIndex, section: todayIndexPath.section) {
                cell.makeStyle(.emptyToday)
            } else if indexPath.section >= todayIndexPath.section {
                if indexPath.row > todayIndexPath.row + firstDayIndex {
                    cell.makeStyle(.disabled)
                }
            } else {
                cell.makeStyle(.empty)
            }
        } else {
            cell.makeStyle(.empty)
        }

        if indexPath == startSelectedIndexPath || indexPath == endISelectedndexPath {
            cell.makeStyle(.circle)
        }

        if let startSelectedIndexPath = self.startSelectedIndexPath,
            let endISelectedndexPath = self.endISelectedndexPath {
            if indexPath == startSelectedIndexPath {
                if startSelectedIndexPath.row < endISelectedndexPath.row {
                    cell.makeStyle(.circleRight)
                } else if startSelectedIndexPath.row > endISelectedndexPath.row {
                    cell.makeStyle(.circleLeft)
                }

                if startSelectedIndexPath.section < endISelectedndexPath.section {
                    cell.makeStyle(.circleRight)
                } else if startSelectedIndexPath.section > endISelectedndexPath.section {
                    cell.makeStyle(.circleLeft)
                }
            }

            if indexPath == endISelectedndexPath {
                if startSelectedIndexPath.row > endISelectedndexPath.row {
                    cell.makeStyle(.circleRight)
                } else if startSelectedIndexPath.row < endISelectedndexPath.row {
                    cell.makeStyle(.circleLeft)
                }

                if startSelectedIndexPath.section < endISelectedndexPath.section {
                    cell.makeStyle(.circleLeft)
                } else if startSelectedIndexPath.section > endISelectedndexPath.section {
                    cell.makeStyle(.circleRight)
                }
            }

            if indexPath > startSelectedIndexPath, indexPath < endISelectedndexPath {
                cell.makeStyle(.gray)
            }
            if indexPath > endISelectedndexPath, indexPath < startSelectedIndexPath {
                cell.makeStyle(.gray)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AMCell.identifier, for: indexPath) as! AMCell
        cell.makeStyle(.empty)

        guard let (firstDayIndex, numberOfDaysTotal) = self.monthInfoForSection[indexPath.section] else { return cell }

        let fromStartOfMonthIndexPath = IndexPath(item: indexPath.item - firstDayIndex, section: indexPath.section)

        let lastDayIndex = firstDayIndex + numberOfDaysTotal

        if (firstDayIndex ..< lastDayIndex).contains(indexPath.item) {
            cell.label.text = String(fromStartOfMonthIndexPath.item + 1)
            cell.isHidden = false

        } else {
            cell.label.text = ""
            cell.isHidden = true
        }

        // For index debug uncomment
        // cell.label.text = "\(indexPath.section) | \(indexPath.row)"

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let (firstDayIndex, _) = self.monthInfoForSection[indexPath.section] else { return }

        if let todayIndexPath = self.todayIndexPath {
            if indexPath.section >= todayIndexPath.section, indexPath.row > todayIndexPath.row + firstDayIndex {
                return
            }
        }

        if startSelectedIndexPath == nil {
            startSelectedIndexPath = indexPath
        } else {
            if endISelectedndexPath == nil {
                endISelectedndexPath = indexPath
            } else {
                if startSelectedIndexPath != nil, endISelectedndexPath != nil {
                    startSelectedIndexPath = indexPath
                    endISelectedndexPath = nil
                }
            }
        }

        if startSelectedIndexPath != nil, endISelectedndexPath != nil {
            if let startDate = dateFromIndexPath(startSelectedIndexPath!),
                let endDate = dateFromIndexPath(endISelectedndexPath!) {
                let date1 = calendar.startOfDay(for: startDate)
                let date2 = calendar.startOfDay(for: endDate)

                let components = calendar.dateComponents([.day], from: date1, to: date2)
                if let selectedDays = components.day,
                    let maxDays = self.maxDays {
                    if abs(selectedDays) < maxDays {
                        proceedButton.isHidden = false
                    }
                }
            }
        } else {
            proceedButton.isHidden = true
        }

        collectionView.reloadData()
    }
}

class AMHeader: UICollectionReusableView {
    static let identifier = "CollectionHeader"
    let label = UILabel()
    let daysStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configUI() {
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = .left

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        let leading = NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: label.superview, attribute: .leading, multiplier: 1, constant: 16)
        let trailing = NSLayoutConstraint(item: label, attribute: .trailing, relatedBy: .equal, toItem: label.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: label.superview, attribute: .top, multiplier: 1, constant: 0)
        addConstraints([top, leading, trailing])

        let line1 = UIView()
        line1.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        addSubview(line1)
        line1.translatesAutoresizingMaskIntoConstraints = false
        let line1Leading = NSLayoutConstraint(item: line1, attribute: .leading, relatedBy: .equal, toItem: line1.superview, attribute: .leading, multiplier: 1, constant: 0)
        let line1Trailing = NSLayoutConstraint(item: line1, attribute: .trailing, relatedBy: .equal, toItem: line1.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let line1Top = NSLayoutConstraint(item: line1, attribute: .top, relatedBy: .equal, toItem: label, attribute: .bottom, multiplier: 1, constant: 0)
        let line1Height = NSLayoutConstraint(item: line1, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 1)
        line1.addConstraint(line1Height)
        addConstraints([line1Top, line1Leading, line1Trailing])

        addSubview(daysStack)
        daysStack.translatesAutoresizingMaskIntoConstraints = false
        let strailing = NSLayoutConstraint(item: daysStack, attribute: .trailing, relatedBy: .equal, toItem: daysStack.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let sleading = NSLayoutConstraint(item: daysStack, attribute: .leading, relatedBy: .equal, toItem: daysStack.superview, attribute: .leading, multiplier: 1, constant: 0)
        let stop = NSLayoutConstraint(item: daysStack, attribute: .top, relatedBy: .equal, toItem: line1, attribute: .bottom, multiplier: 1, constant: 0)
        addConstraints([stop, sleading, strailing])

        let line2 = UIView()
        line2.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        addSubview(line2)
        line2.translatesAutoresizingMaskIntoConstraints = false
        let line2Leading = NSLayoutConstraint(item: line2, attribute: .leading, relatedBy: .equal, toItem: line2.superview, attribute: .leading, multiplier: 1, constant: 0)
        let line2Trailing = NSLayoutConstraint(item: line2, attribute: .trailing, relatedBy: .equal, toItem: line2.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let line2Top = NSLayoutConstraint(item: line2, attribute: .top, relatedBy: .equal, toItem: daysStack, attribute: .bottom, multiplier: 1, constant: 0)
        let line2Bottom = NSLayoutConstraint(item: line2, attribute: .bottom, relatedBy: .equal, toItem: line2.superview, attribute: .bottom, multiplier: 1, constant: 0)
        let line2Height = NSLayoutConstraint(item: line2, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 1)
        line2.addConstraint(line2Height)
        addConstraints([line2Top, line2Leading, line2Trailing, line2Bottom])

        daysStack.distribution = .fillEqually
        daysStack.axis = .horizontal
        daysStack.spacing = 3

        let fmt = DateFormatter()
        fmt.locale = Style.locale
        let firstWeekday = 2 // -> Monday
        if var symbols = fmt.shortWeekdaySymbols {
            symbols = Array(symbols[firstWeekday - 1 ..< symbols.count]) + symbols[0 ..< firstWeekday - 1]
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

class AMCell: UICollectionViewCell {
    enum CellStyle {
        case empty
        case circle
        case circleLeft
        case circleRight
        case gray
        case emptyToday
        case disabled
    }

    static let identifier = "Cell"
    let label = UILabel()

    let circleView = UIView()
    let squareView = UIView()

    var strailing: NSLayoutConstraint?
    var sleading: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configUI() {
        addSubview(squareView)
        squareView.translatesAutoresizingMaskIntoConstraints = false
        strailing = NSLayoutConstraint(item: squareView, attribute: .trailing, relatedBy: .equal, toItem: squareView.superview, attribute: .trailing, multiplier: 1, constant: 0)
        sleading = NSLayoutConstraint(item: squareView, attribute: .leading, relatedBy: .equal, toItem: squareView.superview, attribute: .leading, multiplier: 1, constant: 0)
        let stop = NSLayoutConstraint(item: squareView, attribute: .top, relatedBy: .equal, toItem: squareView.superview, attribute: .top, multiplier: 1, constant: 4)
        let sbottom = NSLayoutConstraint(item: squareView, attribute: .bottom, relatedBy: .equal, toItem: squareView.superview, attribute: .bottom, multiplier: 1, constant: -4)
        addConstraints([strailing!, sleading!, stop, sbottom])

        addSubview(circleView)
        circleView.layer.cornerRadius = ((UIScreen.main.bounds.width / 7) - 8) / 2
        circleView.translatesAutoresizingMaskIntoConstraints = false
        let ctrailing = NSLayoutConstraint(item: circleView, attribute: .trailing, relatedBy: .equal, toItem: circleView.superview, attribute: .trailing, multiplier: 1, constant: -4)
        let cleading = NSLayoutConstraint(item: circleView, attribute: .leading, relatedBy: .equal, toItem: circleView.superview, attribute: .leading, multiplier: 1, constant: 4)
        let ctop = NSLayoutConstraint(item: circleView, attribute: .top, relatedBy: .equal, toItem: circleView.superview, attribute: .top, multiplier: 1, constant: 4)
        let cbottom = NSLayoutConstraint(item: circleView, attribute: .bottom, relatedBy: .equal, toItem: circleView.superview, attribute: .bottom, multiplier: 1, constant: -4)
        addConstraints([ctrailing, cleading, ctop, cbottom])

        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        let trailing = NSLayoutConstraint(item: label, attribute: .trailing, relatedBy: .equal, toItem: label.superview, attribute: .trailing, multiplier: 1, constant: 0)
        let leading = NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: label.superview, attribute: .leading, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: label.superview, attribute: .top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: label.superview, attribute: .bottom, multiplier: 1, constant: 0)
        addConstraints([top, leading, trailing, bottom])
    }

    func makeStyle(_ style: CellStyle) {
        switch style {
        case .empty:
            circleView.isHidden = true
            squareView.isHidden = true
            backgroundColor = .white
            circleView.backgroundColor = .white
            squareView.backgroundColor = .white
            label.textColor = .black
            label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            sleading?.constant = 0
            strailing?.constant = 0
        case .circle:
            circleView.isHidden = false
            squareView.isHidden = true
            backgroundColor = .white
            circleView.backgroundColor = UIColor(hexFromString: "49A8FF")
            squareView.backgroundColor = .white
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            sleading?.constant = 0
            strailing?.constant = 0
        case .circleLeft:
            circleView.isHidden = false
            squareView.isHidden = false
            backgroundColor = .white
            circleView.backgroundColor = UIColor(hexFromString: "49A8FF")
            squareView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            sleading?.constant = 0
            strailing?.constant = -((UIScreen.main.bounds.width / 7) / 2)
        case .circleRight:
            circleView.isHidden = false
            squareView.isHidden = false
            backgroundColor = .white
            circleView.backgroundColor = UIColor(hexFromString: "49A8FF")
            squareView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            sleading?.constant = (UIScreen.main.bounds.width / 7) / 2
            strailing?.constant = 0
        case .gray:
            circleView.isHidden = true
            squareView.isHidden = false
            backgroundColor = .white
            circleView.backgroundColor = UIColor(hexFromString: "49A8FF")
            squareView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
            label.textColor = .black
            label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            sleading?.constant = 0
            strailing?.constant = 0
        case .emptyToday:
            circleView.isHidden = true
            squareView.isHidden = true
            backgroundColor = .white
            circleView.backgroundColor = .white
            squareView.backgroundColor = .white
            label.textColor = .black
            label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            sleading?.constant = 0
            strailing?.constant = 0
        case .disabled:
            circleView.isHidden = true
            squareView.isHidden = true
            backgroundColor = .white
            circleView.backgroundColor = .white
            squareView.backgroundColor = .white
            label.textColor = .lightGray
            label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            sleading?.constant = 0
            strailing?.constant = 0
        }
    }
}

extension UIColor {
    convenience init(hexFromString: String, alpha: CGFloat = 1.0) {
        var cString: String = hexFromString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        var rgbValue: UInt32 = 10_066_329

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if cString.count == 6 {
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
