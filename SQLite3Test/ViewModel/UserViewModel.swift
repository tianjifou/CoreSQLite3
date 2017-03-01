//
//  UserViewModel.swift
//  SQLite3Test
//
//  Created by 天机否 on 17/1/12.
//  Copyright © 2017年 tianjifou. All rights reserved.
//

import UIKit

class UserViewModel: NSObject {
   static let USER_TABLENAME = "USER_TABLENAME"//表名
   static let USER_SQL_VERSION = "USER_SQL_VERSION"//本地清除数据库版本名
   static let USER_SQL_VERSION_CODE = "1.0.0"//上个版本需要清空数据库的版本号
   static let USER_SQL_UPDATE = "USER_SQL_UPDATE"//升级本地数据库版本名
   static let USER_SQL_UPDATE_CODE = "1.0.1"//上个版本需要改变数据库的表的字段
   static let USER_SQL_TYPE = true //表中是否含有特殊类型（如Data类型）
  ///创建数据库
  @discardableResult  static func createTable() -> Bool {
        let defaults = UserDefaults.standard
        let version = defaults.value(forKey: USER_SQL_VERSION)
        let update = defaults.value(forKey: USER_SQL_UPDATE)
        if let version = version ,(version as! String) == USER_SQL_VERSION_CODE {
            if let update = update as? String{
                if  let intUpdate = Int(update.replacingOccurrences(of: ".", with: "")) {
                    if intUpdate > 100 {
                        
                        if let _ = SQLiteTable.shared.querySql(sql: "select id from \(USER_TABLENAME)"){
                            
                        } else {
                             SQLiteTable.shared.execSql(sql: "ALTER TABLE \(USER_TABLENAME)  ADD COLUMN  \("id") INTEGER DEFAULT 0 IF NOT EXISTS")
                
                        }
                        
                        
                    }
                }
               
            }
            
            defaults.setValue(USER_SQL_UPDATE_CODE, forKey: USER_SQL_UPDATE)
        }else {
            SQLiteTable.shared.dropTable(tableName: USER_TABLENAME)
            defaults.setValue(USER_SQL_VERSION_CODE, forKey: USER_SQL_VERSION)
        }
    
        let result = SQLiteTable.shared.createTable(tableName: USER_TABLENAME, andColoumName: ["auto_index":"INTEGER PRIMARY KEY AUTOINCREMENT",
                                                                                               "name":SQLITE_TEXT_TYPE,
                                                                                               "age":SQLITE_INT_TYPE,
                                                                                               "imageData":SQLITE_BLOB_TYPE,
                                                                                               "createTime":SQLITE_DOUBLE_TYPE,
                                                                                               "id": "INTEGER Default 0"
                                                                                               ], andAddIndex: ["age","createTime"])
      return result
    }
    
    ///插入一条数据
   @discardableResult static func insertOrUpdateTable(_ model:UserModel) -> Bool {
        var dic: [String:AnyObject] = Dictionary()
        var whereParam: [String:AnyObject] = Dictionary()
            dic.updateValue(model.name as AnyObject, forKey: "name")
            dic.updateValue(model.age as AnyObject, forKey: "age")
        
          if  let value =  model.imageData  {
            dic.updateValue(value as AnyObject, forKey: "imageData")
          }
        
            dic.updateValue(model.createTime as AnyObject, forKey: "createTime")
            whereParam.updateValue(model.createTime as AnyObject, forKey: "createTime")
         if model.id > 0 {
           dic.updateValue(model.id as AnyObject, forKey: "id")
          }
    
        
        var result = false
    if !USER_SQL_TYPE {
        if UserViewModel.getOneDataWithAge(model.age)  {
            result = SQLiteTable.shared.updateTable(tableName: USER_TABLENAME, andColoumValue: dic, andWhereParam: whereParam)
          
        }else{
            result = SQLiteTable.shared.insertTable(tableName: USER_TABLENAME, andColoumValue: dic)
        }
       

    }else{
        if UserViewModel.getOneData(model.createTime){
            result = SQLiteTable.shared.updateTableSql(tableName: USER_TABLENAME, andColoumValue: dic, andWhereParam: whereParam)
            
        }else {
            result = SQLiteTable.shared.insertTableSql(tableName: USER_TABLENAME, andColoumValue: dic)
           
        }
    }
    
     return result
    }
    
    
    
    ///获取一条数据
   @discardableResult static func getOneData(_ createTime:Double) -> Bool {
    
        let sql = "select * from \(USER_TABLENAME) where createTime like \(createTime)"
        if let arr = UserViewModel.getAllDataUseSql(sql: sql) ,  arr.count > 0 {
            return true
        }
        return false
    }
    
    ///获取一条数据
    @discardableResult static func getOneDataWithAge(_ age:Int) -> Bool {
        
        let sql = "select * from \(USER_TABLENAME) where age == \(age)"
        if let arr = UserViewModel.getAllDataUseSql(sql: sql) ,  arr.count > 0 {
            return true
        }
        return false
    }
    ///查询数据库
    @discardableResult static func getAllDataUseSql(sql: String) -> [UserModel]? {
        if let arr = SQLiteTable.shared.querySql(sql: sql) ,  arr.count > 0 {
            var arrModel: [UserModel] = []
           arr.forEach({ (dic) in
            if dic.count > 0 {
                let model = UserModel()
                if let value = dic["name"] as? String{
                    model.name = value
                }
                if let value = dic["age"] as? Int32{
                    model.age = Int(value)
                }
                if let value = dic["imageData"] as? Data{
                    model.imageData = value
                }
                if let value = dic["createTime"] as? Double{
                    model.createTime = value
                }
                if let value = dic["id"] as? Int32{
                    model.id = Int(value)
                }
                arrModel.append(model)
            }
            
           })
            return arrModel
        }
       return nil
    }
    ///删除数据
    
    @discardableResult static func delectData(_ model:UserModel) ->Bool {
       
        var whereParam: [String:AnyObject] = Dictionary()
        whereParam.updateValue(model.name.searchSql() as AnyObject, forKey: "name")
//        whereParam.updateValue(model.imageData as AnyObject, forKey: "imageData")
        var result = false
        if !USER_SQL_TYPE {
             result = SQLiteTable.shared.deleteTable(tableName: USER_TABLENAME, andWhereParam: whereParam)
        }else {
            result = SQLiteTable.shared.deleteTableSql(tableName: USER_TABLENAME, andWhereParam: whereParam)
        }
    
       return result
        
    }
}


