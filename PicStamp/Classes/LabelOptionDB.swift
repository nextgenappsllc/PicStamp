//
//  LabelOptionDB.swift
//  Pic Stamp
//
//  Created by Jose Castellanos on 5/31/16.
//  Copyright © 2016 NextGen Apps LLC. All rights reserved.
//

import Foundation
import SQLite
import NGAEssentials
import NGAUI

open class SnapDB {
    private struct _Singleton { static var sharedInstance:SnapDB? }
    open class func sharedInstance() -> SnapDB? {
        _Singleton.sharedInstance ||= SnapDB()
        return _Singleton.sharedInstance
    }
    
    open class func closeDB() {
        _Singleton.sharedInstance = nil
    }
    
    open static var defaultDocumentsDirectory:String? {
        get {
            return NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first
        }
    }
    
    open class func documentSubDirectoryWithName(name:String?) -> String? {
        guard let name = name, let dir = defaultDocumentsDirectory?.stringByAddingPathComponent(name) else {return nil}
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: dir) else {return dir}
        do {try fileManager.createDirectory(atPath: dir, withIntermediateDirectories: false, attributes: nil)
            return dir } catch {return nil}
    }
    
    open static var dbDirectoryName = "SnapDB"
    
    open class func dbDirectory() -> String? {
        return documentSubDirectoryWithName(name: dbDirectoryName)
    }
    
    open static var dbName:String = "db"
    
    open class func dbPath(dbName:String? = nil) -> String? {
        guard let path = dbDirectory()?.stringByAddingPathComponent("\(dbName ?? self.dbName).sqlite3") else {return nil}
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) || fileManager.createFile(atPath: path, contents: nil, attributes: nil) else {return nil}
        return path
    }
    
    open class func removeDBNamed(name:String) {
        guard let path = dbPath(dbName: name) else {return}
        let _ = try? FileManager.default.removeItem(atPath: path)
    }
    
    open static var db:Connection? {
        get {
            guard let path = dbPath() else {return nil}
            do {return try Connection(path)} catch _ {return nil}
        }
    }
    
    open static var labelOptions:Table? {
        get {
            return labelOptionsFromDB()
        }
    }
    
    open class func labelOptionsFromDB(db:Connection? = nil) -> Table? {
        guard let db = db ?? self.db else {return nil}
        let table = Table("label_options")
        do {try db.run(table.create(temporary: false, ifNotExists: true, block: buildLabelOptionsTable))} catch _ {return nil}
        return table
    }
    
    open class func buildLabelOptionsTable(t:TableBuilder) {
        t.column(LabelOptionModel.id, primaryKey: .autoincrement)
        t.column(LabelOptionModel.name)
        t.column(LabelOptionModel.text)
        t.column(LabelOptionModel.gps)
        t.column(LabelOptionModel.timestamp)
        t.column(LabelOptionModel.textColor)
        t.column(LabelOptionModel.backgroundColorEnabled)
        t.column(LabelOptionModel.backgroundColor)
        t.column(LabelOptionModel.textAlignment)
        t.column(LabelOptionModel.labelPosition)
    }
    
    
    open let db:Connection
    open let labelOptions:Table
    public init?() {
        guard let db = SnapDB.db, let labelOptions = SnapDB.labelOptionsFromDB(db: db) else {return nil}
        self.db = db ; self.labelOptions = labelOptions
    }
    
}







public struct PictureLabelSettings {
    public enum TextAlignment:String {
        case Left, Center, Right
    }
    
    public enum LabelPosition:String {
        case TopLeft = "Top left"
        case TopRight = "Top right"
        case BottomLeft = "Bottom left"
        case BottomRight = "Bottom right"
    }
}



open class LabelOption {
    open var id:Int?
    open var name:String?
    open var text:String?
    open var timestamp:Bool = false
    open var gps:Bool = false
    open var textColor:UIColor = UIColor.black
    open var backgroundColor:UIColor = UIColor.clear
    open var labelPosition:PictureLabelSettings.LabelPosition = .TopLeft
    open var textAlignment:PictureLabelSettings.TextAlignment = .Left
    public init() {}
    public init(formValues:[String:Any?]) {
        updateFromFormValues(formValues: formValues)
    }
    
    public init( id:Int? = nil,
          name:String?,
          text:String?,
          gps:Bool,
          timestamp:Bool,
          textColor:UIColor,
          backgroundColor:UIColor,
          textAlignment:PictureLabelSettings.TextAlignment,
          labelPosition:PictureLabelSettings.LabelPosition) {
        self.id = id
        self.name = name
        self.text = text
        self.gps = gps
        self.timestamp = timestamp
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.textAlignment = textAlignment
        self.labelPosition = labelPosition
    }
    
    
    open func updateFromFormValues(formValues:[String:Any?]) {
        text = formValues.stringForKey("custom text")
        timestamp =? formValues.boolForKey("timestamp")
        gps =? formValues.boolForKey("gps")
        labelPosition =? PictureLabelSettings.LabelPosition(raw: formValues.stringForKey("label position"))
        textAlignment =? PictureLabelSettings.TextAlignment(raw: formValues.stringForKey("text alignment"))
        textColor = UIColor(red: (formValues.valueForKey("rt") as? Float)?.toCGFloat() ?? 0,
                            green: (formValues.valueForKey("gt") as? Float)?.toCGFloat() ?? 0,
                            blue: (formValues.valueForKey("bt") as? Float)?.toCGFloat() ?? 0,
                            alpha: 1.0)
        backgroundColor = formValues.boolForKey("background") ?? false ?
            UIColor(red: (formValues.valueForKey("rb") as? Float)?.toCGFloat() ?? 0,
                    green: (formValues.valueForKey("gb") as? Float)?.toCGFloat() ?? 0,
                    blue: (formValues.valueForKey("bb") as? Float)?.toCGFloat() ?? 0,
                    alpha: 1.0) :
            .clear
    }
    
    open func save() -> Bool {
        guard let model = LabelOptionModel.save(labelOption: self) else {return false}
        id = model.id
        return true
    }
    open func delete() -> Bool {
        return LabelOptionModel.delete(labelOption: self)
    }
}




class LabelOptionModel {
    static let id = Expression<Int64>("id")
    static let name = Expression<String?>("name")
    static let text = Expression<String?>("text")
    static let gps = Expression<Bool>("gps")
    static let timestamp = Expression<Bool>("timestamp")
    static let textColor = Expression<String>("text_color")
    static let backgroundColorEnabled = Expression<Bool>("background_color_enabled")
    static let backgroundColor = Expression<String>("background_color")
    static let labelPosition = Expression<String>("label_position")
    static let textAlignment = Expression<String>("text_alignment")
    
    static var db:Connection? {get{return SnapDB.sharedInstance()?.db}}
    static var table:Table? {get{return SnapDB.sharedInstance()?.labelOptions}}
    
    private let _row:SQLite.Row
    private let _db:Connection
    private let _table:Table
    private var _query:Table {get{return _table.filter(LabelOptionModel.id == Int64(id))}}
    
    var id:Int {get{return Int(_row[LabelOptionModel.id])}}
    var name:String? {get{return _row[LabelOptionModel.name]} set{let _ = update(values: [LabelOptionModel.name <- newValue])}}
    var text:String? {get{return _row[LabelOptionModel.text]} set{let _ = update(values: [LabelOptionModel.name <- newValue])}}
    var gps:Bool {get{return _row[LabelOptionModel.gps]} set{let _ = update(values: [LabelOptionModel.gps <- newValue])}}
    var timestamp:Bool {get{return _row[LabelOptionModel.timestamp]} set{let _ = update(values: [LabelOptionModel.timestamp <- newValue])}}
    var textColor:UIColor {get{return UIColor(hexString:_row[LabelOptionModel.textColor])} set{let _ = update(values: [LabelOptionModel.textColor <- newValue.toHexString()])}}
    var backgroundColorEnabled:Bool {get{return _row[LabelOptionModel.backgroundColorEnabled]} set{let _ = update(values: [LabelOptionModel.backgroundColorEnabled <- newValue])}}
    var backgroundColor:UIColor {
        get{
            guard backgroundColorEnabled else {return .clear}
            return UIColor(hexString:_row[LabelOptionModel.backgroundColor])
        }
        set{let _ = update(values: [LabelOptionModel.backgroundColor <- newValue.toHexString()])}
    }
    var labelPosition:PictureLabelSettings.LabelPosition {
        get{
            return PictureLabelSettings.LabelPosition(rawValue: _row[LabelOptionModel.labelPosition]) ?? .TopLeft
        }
        set{let _ = update(values: [LabelOptionModel.labelPosition <- newValue.rawValue])}
    }
    var textAlignment:PictureLabelSettings.TextAlignment {
        get{
            return PictureLabelSettings.TextAlignment(rawValue: _row[LabelOptionModel.textAlignment]) ?? .Left
        }
        set{let _ = update(values: [LabelOptionModel.textAlignment <- newValue.rawValue])}
    }
    
    init?(row:SQLite.Row?) {
        guard let row = row, let db = LabelOptionModel.db, let table = LabelOptionModel.table else {return nil}
        _row = row
        _db = db
        _table = table
    }
    
    convenience init?(id:Int?) {
        guard let id = id else {return nil}
        self.init(filter: LabelOptionModel.id == Int64(id))
    }
    
    init?(filter:Expression<Bool>) {
        guard let db = LabelOptionModel.db, let table = LabelOptionModel.table, let row = try? db.pluck(table.filter(filter)), let r = row else {return nil}
        _row = r
        _db = db
        _table = table
    }
    init?(filter:Expression<Bool?>) {
        guard let db = LabelOptionModel.db, let table = LabelOptionModel.table, let row = try? db.pluck(table.filter(filter)), let r = row else {return nil}
        _row = r
        _db = db
        _table = table
    }
    
    class func filtered(filters: [Expression<Bool?>]) -> Table? {
        var t = table
        for filter in filters {
            t = t?.filter(filter)
        }
        return t
    }
    
    class func filteredRows(filters: [Expression<Bool?>]) -> [Row] {
        guard let t = filtered(filters: filters), let db = db, let q = try? db.prepare(t) else {return []}
        return Array(q)
    }
    class func filteredLabelOptions(filters: [Expression<Bool?>]) -> [LabelOption] {
        return filteredRows(filters: filters).mapToNewArray() {e -> LabelOption? in LabelOptionModel(row: e)?.toLabelOption()}
    }
    
    convenience init?(name:String?,
                      text:String?,
                      gps:Bool,
                      timestamp:Bool,
                      textColor:UIColor,
                      backgroundColor:UIColor,
                      textAlignment:PictureLabelSettings.TextAlignment,
                      labelPosition:PictureLabelSettings.LabelPosition ,
                      onConflict:OnConflict = .replace) {
        guard let db = LabelOptionModel.db,
            let table = LabelOptionModel.table,
            let id = try? db.run(table.insert(or: onConflict,[
                LabelOptionModel.name <- name,
                LabelOptionModel.text <- text,
                LabelOptionModel.gps <- gps,
                LabelOptionModel.timestamp <- timestamp,
                LabelOptionModel.textColor <- textColor.toHexString(),
                LabelOptionModel.backgroundColorEnabled <- (backgroundColor != .clear),
                LabelOptionModel.backgroundColor <- backgroundColor.toHexString(),
                LabelOptionModel.textAlignment <- textAlignment.rawValue,
                LabelOptionModel.labelPosition <- labelPosition.rawValue
                ]))
            else {return nil}
        self.init(id: Int(id))
    }
    
    func update(values: [Setter]) -> Int? {
        return try? _db.run(_query.update(values))
    }
    
    
    func update(labelOption:LabelOption?) -> Int? {
        guard let labelOption = labelOption else {return nil}
        let i = update(values: [
            LabelOptionModel.name <- labelOption.name,
            LabelOptionModel.text <- labelOption.text,
            LabelOptionModel.gps <- labelOption.gps,
            LabelOptionModel.timestamp <- labelOption.timestamp,
            LabelOptionModel.textColor <- labelOption.textColor.toHexString(),
            LabelOptionModel.backgroundColorEnabled <- (labelOption.backgroundColor != UIColor.clear),
            LabelOptionModel.backgroundColor <- labelOption.backgroundColor.toHexString(),
            LabelOptionModel.textAlignment <- labelOption.textAlignment.rawValue,
            LabelOptionModel.labelPosition <- labelOption.labelPosition.rawValue])
        labelOption.id = i
        return i
    }
    
    class func save(labelOption:LabelOption?) -> LabelOptionModel? {
        guard let labelOption = labelOption else {return nil}
        if let l = LabelOptionModel(id: labelOption.id) {
            let _ = l.update(labelOption: labelOption)
            return l
        } else if let l = LabelOptionModel(name: labelOption.name, text: labelOption.text, gps: labelOption.gps, timestamp: labelOption.timestamp, textColor: labelOption.textColor, backgroundColor: labelOption.backgroundColor, textAlignment: labelOption.textAlignment, labelPosition: labelOption.labelPosition) {
            labelOption.id = l.id
            return l
        }
        return nil
    }
    
    class func delete(labelOption:LabelOption?) -> Bool {
        guard let db = db, let table = table, let id = labelOption?.id else {return true}
        return (try? db.run(table.filter(self.id == Int64(id)).delete())) != nil
    }
    
    func toLabelOption() -> LabelOption {
        return LabelOption(id: id,name: name, text: text, gps: gps, timestamp: timestamp, textColor: textColor, backgroundColor: backgroundColor, textAlignment: textAlignment, labelPosition: labelPosition)
    }
    
    class func allRows() -> [Row] {
        guard let t = table, let db = db, let q = try? db.prepare(t) else {return []}
        return Array(q)
    }
    class func allLabelOptions() -> [LabelOption] {
        return allRows().mapToNewArray() {e -> LabelOption? in LabelOptionModel(row: e)?.toLabelOption()}
    }
    
}
