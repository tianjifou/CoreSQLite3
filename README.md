#IOS中的SQLite3的封装与详细应用

SQLite是一个开源的嵌入式关系数据库，特点是易使用、高效、安全可靠、可移植性强。


##IOS中的本地持久化存储
**NSUserDefault**：一般用于存储小规模数据、业务逻辑弱的数据。

**keychain**: 苹果提供的可逆存储，因为有着只要app不重装系统、可以同步iCloud的特性，一般用来对用户的标识符或者一些需要加密的小数据进行存储。

**归档**：主要原理是对数据进行序列化、反序列化操作后，写入、读出数据。方便便捷易使用，缺点查询、更改数据耗时耗性能。

**数据库**：主要的有三种sqlite3、core data、realm。其中core data只是xcode对sqlite的界面化的封装原理相似，realm[官方文档](https://realm.io/cn/docs/swift/latest/#model).

关于sqlite本文将主要介绍。

##SQLite3中主要函数介绍
sqlite3_open(文件路径,sqlite3 **)：文件名若不存在，则会自动创建

sqlite3_close(sqlite3 *)：关闭数据库

sqlite3__finalize(sqlite3_stmt *pStmt): 释放数据库

sqlite3_errmsg(sqlite3*)：输出数据库错误

sqlite3__exec(sqlite3 *,const char *sql, sqlite3_callback,void *,char **errmsg)：

参数1：open函数得到的指针。

参数2：一条sql语句

参数3：sqlite3_callback是回调，当这条语句执行后，sqlite3会调用你提供的这个函数，回调函数

参数4：void *是自己提供的指针，可以传递任何指针到这里，这个参数最终会传到回调函数里面，如果不需要传到回调函数里面，则可以设置为NULL

参数5：错误信息，当执行失败时，可以查阅这个指针

sqlite3_prepare_v2(sqlite3 *db,const char *zSql, int nByte,sqlite3_stmt **ppStmt,const char **pzTail)：

参数3：表示前面sql语句的长度，如果小于0，sqlite会自动计算它的长度

参数4：sqlite3_stmt指针的指针，解析后的sql语句就放在该结构里

参数5：一般设为0

sqlite3_step(sqlite3_stmt*)：

参数为sqlite3_prepare_v2中的sqlite3_stmt
返回SQLITE_ROW 表示成功

sqlite3_bind_text(sqlite3_stmt*, int, const char*, int n,                                                                         void(*)(void*)):

参数1：sqlite3_prepare_v2中的sqlite3_stmt

参数2：对应行数

参数3：对应行数的值

参数4：对应行数的值的长度，小于0自动计算长度

参数5：函数指针，主要处理特殊类型的析构

sqlite3_key( sqlite3 *db, const void *pKey, int nKey)

参数2：密钥

参数3：密钥长度
##swift与c的类型转换
int => CInt

char => CChar / CSignedChar

char* => CString

unsigned long = > CUnsignedLong

wchar_t => CWideChar

double => CDouble

T* => CMutablePointer

void* => CMutableVoidPointer

const T* => CConstPointer

const void* => CConstVoidPointer

等等
[参考地址](http://www.cocoachina.com/industry/20140619/8884.html)

##创建或者打开数据库
程序中‘db’不能为空，如果为空，表示打开数据库失败或者关闭了数据库。

``` swift
@discardableResult   private func openDB() -> Bool{
    
    if db == nil {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/\(DB_NAME)"
        print(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        if sqlite3_open(path.cString(using: String.Encoding.utf8)!,&db) != SQLITE_OK {
            closeDb()
            return false
        }else {
            //对数据库进行加密
            sqlite3_key(db, SAFE_KEY.cString(using: String.Encoding.utf8), Int32(SAFE_KEY.characters.count))
        }
        sqlite3_busy_handler(db, { (ptr,count) in
            
            usleep(500000)//如果获取不到锁，表示数据库繁忙，等待0.5秒
            print("sqlite is locak now,can not write/read.")
            return 1   //回调函数返回值为1，则将不断尝试操作数据库。
            
        }, &db)
    }
        
        
        return true
    }
```
##通过sql执行数据库操作
由于防止多线程操作数据库，每次执行数据库操作添加同步锁。
sqlite3_exec函数基本上支持所有的数据库执行语句除了含有特殊类型的数据（二进制），含有特殊类型的数据会采用另一种方式处理下面会阐述。

``` swift
  @discardableResult public  func execSql(sql:String)->Bool {
        
        objc_sync_enter(self)
        if  !self.openDB() {
        objc_sync_exit(self)
        return false
        }
        var err: UnsafeMutablePointer<Int8>? = nil
        if sqlite3_exec(db,sql.cString(using: String.Encoding.utf8)!,nil,nil,&err) != SQLITE_OK {
            if let error = String(validatingUTF8:sqlite3_errmsg(db)) {
               print("execute failed to execute  Error: \(error)")
            }
            objc_sync_exit(self)
            return false
        }

        objc_sync_exit(self)
        return true
    }


```

##查询数据库
按照数据库的行数依次查询，输出sql条件的所有数据

``` swift
 public  func querySql(sql:String) -> [[String:Any]]? {
        objc_sync_enter(self)
        if  !self.openDB() {
            objc_sync_exit(self)
            return nil
        }
        var arr:[[String:Any]] = []
        var  statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db,sql.cString(using: String.Encoding.utf8)!,-1,&statement,nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let columns = sqlite3_column_count(statement)
                var row:[String:Any] = Dictionary()
                for i in 0..<columns {
                    let type = sqlite3_column_type(statement, i)
                    let chars = UnsafePointer<CChar>(sqlite3_column_name(statement, i))
                    let name =  String.init(cString: chars!, encoding: String.Encoding.utf8)
                    
                    var value: Any
                    switch type {
                    case SQLITE_INTEGER:
                        value = sqlite3_column_int(statement, i)
                    case SQLITE_FLOAT:
                        value = sqlite3_column_double(statement, i)
                    case SQLITE_TEXT:
                        let chars = UnsafePointer<CUnsignedChar>(sqlite3_column_text(statement, i))
                        value = String.init(cString: chars!)
                        
                    case SQLITE_BLOB:
                        let data = sqlite3_column_blob(statement, i)
                        let size = sqlite3_column_bytes(statement, i)
                        value = NSData(bytes:data, length:Int(size))
                    default:
                        value = ""
                        ()
                    }
                    
                    row.updateValue(value, forKey: "\(name!)")
                }
                arr.append(row)
            }
        }
        sqlite3_finalize(statement)

        objc_sync_exit(self)
        if arr.count == 0 {
            return nil
        }else{
            return arr
        }
        
    }
```

##引入事务，加快数据库写入
事务（Transaction）是一个对数据库执行工作单元。事务（Transaction）是以逻辑顺序完成的工作单位或序列，可以是由用户手动操作完成，也可以是由某种数据库程序自动完成。
事务（Transaction）是指一个或多个更改数据库的扩展。例如，如果您正在创建一个记录或者更新一个记录或者从表中删除一个记录，那么您正在该表上执行事务。重要的是要控制事务以确保数据的完整性和处理数据库错误。
实际上，您可以把许多的 SQLite 查询联合成一组，把所有这些放在一起作为事务的一部分进行执行

**BEGIN TRANSACTION** 开启一个事务

**COMMIT TRANSACTION** 提交事务是否成功

**ROLLBACK TRANSACTION** 回滚事务，当数据库事务操作失败后，还原之前的操作。

注意：事务并不能批量优化查询速度。

``` swift
   public func doTransaction(exec: ((_ db:OpaquePointer)->())?) {
        objc_sync_enter(self)
        if  !self.openDB() {
            objc_sync_exit(self)
            return
        }
        if exec != nil {
             var err: UnsafeMutablePointer<Int8>? = nil
            if sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, &err) == SQLITE_OK {
                exec!(db!)
                if sqlite3_exec(db, "COMMIT TRANSACTION", nil, nil, &err) == SQLITE_OK {
                    print("提交事务成功")
                }else {
                    print("提交事务失败原因\(err)")
                    if let error = String(validatingUTF8:sqlite3_errmsg(db)) {
                        print("execute failed to execute  Error: \(error)")
                    }
                    if sqlite3_exec(db, "ROLLBACK TRANSACTION", nil, nil, &err) == SQLITE_OK {
                        print("回滚事务成功")
                    }
                }
            }else {
                if sqlite3_exec(db, "ROLLBACK TRANSACTION", nil, nil, &err) == SQLITE_OK {
                    print("回滚事务成功")
                }
            }
           sqlite3_free(err)
           
        }

        objc_sync_exit(self)
    }
```


##SQLite3支持有限的 ALTER TABLE 操作
SQLite 有有限地 ALTER TABLE 支持。你可以使用它来在表的末尾增加一列,可更改表的名称。 如果需要对表结构做更复杂的改变,则必须重新建表。重建时可以先将已存在的数据放到一个临时表中,删除原表, 创建新表,然后将数据从临时表中复制回来。在增加表列时，需注意：因为app在市场上存在许多版本，各个版本的数据库表的结构可能存在梯度的差异，代码中使用就需要加入版本控制了。例如代码中添加一个‘id’字段。

```swift
        let defaults = UserDefaults.standard
        let version = defaults.value(forKey: USER_SQL_VERSION)//控制删除数据库的版本记录
        let update = defaults.value(forKey: USER_SQL_UPDATE)//控制增加数据库字段的版本记录
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
```
##SQLite3中添加索引

```swift
    /// 创建一张表
    ///
    /// - Parameters:
    ///   - tableName: 表名
    ///   - data: 数据字段
    ///   - dataArray: 添加索引的字段
    /// - Returns: 是否成功   
public func createTable(tableName:String, andColoumName data:[String:String] ,andAddIndex dataArray:[String]) -> Bool {
        let result = self.createTable(tableName: tableName, andColoumName: data)
        dataArray.forEach { (str) in
            self.execSql(sql: "CREATE INDEX IF NOT EXISTS index_\(str)  ON \(tableName) (\(str))")
        }
        
         return result
        
    }
    
```
##处理Dada类型数据
sqlite3__exec函数并不是万能的，它就无法处理二进制数据。处理二进制数据，需要的是另一种方法。
先对表的数据解析然后绑定到结构体中，然后对数据库进行INSERT DELETE 或者 UPDATE操作。

```swift
 private func bindSqlType(sql:String, params:[Any]?) -> OpaquePointer? {
        
        if  !self.openDB() {
            return nil
        }
        
        var stmt:OpaquePointer? = nil
        let someCharChar = unsafeBitCast(-1, to:sqlite3_destructor_type.self)
        let result = sqlite3_prepare_v2(db, sql.cString(using: String.Encoding.utf8)!, -1, &stmt, nil)
        if result != SQLITE_OK {
            sqlite3_finalize(stmt)
            if let error = String(validatingUTF8:sqlite3_errmsg(db)) {
                print("execute failed to execute  Error: \(error)")
            }
            return nil
        }
        
        if let  params = params {
            
            let count = CInt(params.count)
            if sqlite3_bind_parameter_count(stmt)  == count {
                var result:CInt = 0
                
                for index in 1...count {
                    
                    if let txt = params[index-1] as? String {
                        result = sqlite3_bind_text(stmt, CInt(index), txt, -1, someCharChar)
                    } else if let data = params[index-1] as? NSData {
                        result = sqlite3_bind_blob(stmt, CInt(index), data.bytes, CInt(data.length), someCharChar)
                    }else if let val = params[index-1] as? Double {
                        result = sqlite3_bind_double(stmt, CInt(index), CDouble(val))
                    } else if let val = params[index-1] as? Int {
                        result = sqlite3_bind_int64(stmt, index, Int64(val))
                    } else {
                        result = sqlite3_bind_null(stmt, CInt(index))
                    }
                    
                    if result != SQLITE_OK {
                        sqlite3_finalize(stmt)
                        if let error = String(validatingUTF8:sqlite3_errmsg(db)) {
                            print("execute failed to execute  Error: \(error)")
                        }
                        return nil
                    }
                }
            }
           
        }
        return stmt
    }

```



##SQLite3的一些小坑
1.SQL 标准规定,在字符串中,单引号需要使用逃逸字符(''),即在一行中使用两个单引号。

2.每次操作完数据库记得关闭数据库，防止多个数据库混淆。


##SQLite3中查询效率优化
1.添加索引 在demo中测试发现，插入50000行数据，同时做查询时发现，添加索引耗时76s,不添加花费256s。添加索引需注意：

* 添加索引的原则是为了查询更加快，但是一张表内不能创建太多索引，因为索引只增加了相应的 select 的效率，但同时也降低了 insert 及 update 的效率，一个表的索引数最好不要超过6个。

* 在使用索引字段作为条件时，如果该索引是复合索引，那么必须使用到该索引中的第一个字段作为条件时才能保证系统使用该索引，否则该索引将不会被使 用，并且应尽可能的让字段顺序与索引顺序相一致。

2.在使用索引字段时，需要避免使用OR/BETWEEN/LIKE这些语法，这样会避免使用索引而对表进行全局扫描。如demo中使用like语法与‘==’插入50000行数据，同时做查询时，对比发现分别耗时546s和76s。

##SQLite3加密
使用SQLCipher[链接地址](https://github.com/sqlcipher/sqlcipher.git)这个第三方库对数据库进行加密。

sqlite3_key 加密函数 

sqlite3_rekey 修改密码

##最后
点击[博客地址](http://www.jianshu.com/p/c64ec4c19ff7)。

具体请参考： http://www.jianshu.com/p/c64ec4c19ff7；（**转载请说明出处，编写代码不易如对您有用请点赞，谢谢支持！**）


