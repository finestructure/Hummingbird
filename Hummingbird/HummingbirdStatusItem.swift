//
//  HummingBirdStatusItem.swift
//  Hummingbird
//
//  Created by Robert Ehni on 24.12.20.
//  Copyright © 2020 finestructure. All rights reserved.
//

import Cocoa

class HummingbirdStatusItem {
    static let instance = HummingbirdStatusItem()
    
    private var statusItem: NSStatusItem!
    private var added: Bool = false
    public var statusMenu: NSMenu? {
        didSet {
            statusItem?.menu = statusMenu
        }
    }
    
    private init() {}
    
    public func refreshVisibility() {
        if Current.defaults().bool(forKey: DefaultsKeys.hideMenuIcon.rawValue) {
            remove()
        } else {
            add()
        }
    }
    
    public func openMenu() {
        if !added {
            add()
        }
        statusItem?.button?.performClick(self)
        refreshVisibility()
    }
    
    private func add() {
        added = true
        statusItem = {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem.menu = statusMenu
            statusItem.image = NSImage(named: "MenuIcon")
            statusItem.alternateImage = NSImage(named: "MenuIconHighlight")
            statusItem.highlightMode = true
            return statusItem
        }()
    }
    
    private func remove() {
        added = false
        guard let statusItem = statusItem else { return }
        NSStatusBar.system.removeStatusItem(statusItem)
    }
    
}

