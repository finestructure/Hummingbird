//
//  StatsController.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 14/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa

class StatsController: NSViewController {

    @IBOutlet weak var distanceToday: NSTextField!
    @IBOutlet weak var areaToday: NSTextField!
    @IBOutlet weak var distanceTotal: NSTextField!
    @IBOutlet weak var areaTotal: NSTextField!
    @IBOutlet weak var distanceMax: NSTextField!
    @IBOutlet weak var areaMax: NSTextField!


    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func updateView() {
        guard let tracker = Tracker.shared else {
            print("No tracker")
            return
        }
        distanceToday.stringValue = "\(distance: tracker.metricsHistory.currentValue.distanceMoved)"
        areaToday.stringValue = "\(area: tracker.metricsHistory.currentValue.areaResized)"
        distanceTotal.stringValue = "\(distance: tracker.metricsHistory.total.distanceMoved)"
        areaTotal.stringValue = "\(area: tracker.metricsHistory.total.areaResized)"
        distanceMax.stringValue = "\(distance: tracker.metricsHistory.maxDistanceMoved ?? 0)"
        areaMax.stringValue = "\(area: tracker.metricsHistory.maxAreaResized ?? 0)"
    }

}


extension DefaultStringInterpolation {
    mutating func appendInterpolation(distance: CGFloat) {
        appendInterpolation("\(scaled: Decimal(Double(distance))) pixels")
    }

    mutating func appendInterpolation(area: CGFloat) {
        appendInterpolation("\(scaled: Decimal(Double(area))) pixels²")
    }
}
