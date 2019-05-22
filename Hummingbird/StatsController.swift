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
    @IBOutlet weak var distanceMaxDate: NSTextField!
    @IBOutlet weak var areaMaxDate: NSTextField!
    

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
        do { // max distance
            if let (date, metrics) = tracker.metricsHistory.max(by: { $0.1.distanceMoved < $1.1.distanceMoved }) {
                distanceMaxDate.stringValue = "\(date)"
                distanceMax.stringValue = "\(distance: metrics.distanceMoved)"
            } else {
                distanceMaxDate.stringValue = ""
                distanceMax.stringValue = "-"
            }
        }
        do { // max area
            if let (date, metrics) = tracker.metricsHistory.max(by: { $0.1.areaResized < $1.1.areaResized }) {
                areaMaxDate.stringValue = "\(date)"
                areaMax.stringValue = "\(area: metrics.areaResized)"
            } else {
                areaMaxDate.stringValue = ""
                areaMax.stringValue = "-"
            }
        }
    }

}
