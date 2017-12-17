//
//  ColleagueList.swift
//  GITGET
//
//  Created by Bo-Young PARK on 17/12/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import Foundation

class ColleagueList {
    private let fileName:String = "ColleagueList"
    private let fileType:String = "plist"
    private static var sharedInstance:ColleagueList = ColleagueList()
    private var colleagueData:[String]?
    
    //Singleton Instance 화
    class var standard:ColleagueList {
        return sharedInstance
    }
    
    func getList() -> [String] {
        guard let data = colleagueData else {return []}
        return data
    }
    
    func object(forIndex defaultIndex:Int) -> Any? {
        guard let data = colleagueData else {return nil}
        return data[defaultIndex]
    }
    
    func set(_ value:String?) {
        guard let _ = colleagueData,
            let realValue = value else {return}
        
        colleagueData!.append(realValue)
    }
    
    func removeObject(forIndex defaultIndex:Int) {
        guard colleagueData != nil else {return}
        colleagueData!.remove(at: defaultIndex)
    }
    
    func colleagueDataSave() {
        self.save()
    }
    
    init() {
        self.load()
    }
    
    deinit {
        self.save()
    }
    
    private func load() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let realPath = path[0] + "/" + self.fileName + "." + self.fileType
        colleagueData = NSArray(contentsOfFile: realPath) as? [String]
    }
    
    private func save() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let realPath = path[0] + "/" + self.fileName + "." + self.fileType
        
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: realPath) {
            if let bundlePath = Bundle.main.path(forResource: self.fileName, ofType: self.fileType) {
                do {
                    try fileManager.copyItem(atPath: bundlePath, toPath: realPath)
                }catch{
                    return
                }
            }else{
                return
            }
        }
        guard let realColleagueData = colleagueData else {return}
        let tempDic = NSArray(array: realColleagueData)
        tempDic.write(toFile: realPath, atomically: true)
    }
}
