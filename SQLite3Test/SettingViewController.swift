//
//  SettingViewController.swift
//  SQLite3Test
//
//  Created by 天机否 on 17/1/13.
//  Copyright © 2017年 tianjifou. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var authorImage: UIImageView!
    @IBOutlet weak var ageTextField: UITextField!
    
    var model: UserModel?
    fileprivate var test: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        if let model = self.model {
            nameTextField.text = model.name
            ageTextField.text = String(model.age)
            if let image = model.imageData {
                 authorImage.image = UIImage.init(data: image)
            }
           
        }
        // Do any additional setup after loading the view.
    }
    @IBAction func commitBtn(_ sender: Any) {
        authorImage.image = UIImage.init(named: "user_author")
    }
    @IBAction func saveBtn(_ sender: Any) {
    
        if let model = self.model {
            model.name = nameTextField.text ?? "default"
            if let age = ageTextField.text ,Int(age) != nil{
                model.age = Int(age)!
            }
            if let image = authorImage.image {
              model.imageData = UIImagePNGRepresentation(image)
            }
           
          
           saveSql(_model: model)
            
        }else {
            
         createOneData()
           
        }
    }
    
    ///生成一组数据
    private func createOneData() {
        let model = UserModel()
        model.name = self.nameTextField.text ?? "default"
        if let age = self.ageTextField.text ,Int(age) != nil{
            model.age = Int(age)!
        }
        if let image = self.authorImage.image {
            model.imageData = UIImagePNGRepresentation(image)
        }
        let nowDate = Date().timeIntervalSince1970
        model.createTime = nowDate
        
        if let count = UserViewModel.getAllDataUseSql(sql: "select * from \(UserViewModel.USER_TABLENAME)")?.count {
            model.id = count + 1
        }else{
            model.id = 1
        }
        
        self.saveSql(_model: model)
    }
    ///测试批量操作数据库时查询 和 写入的优化效果
    private func createMoreData() {
        test = true
        let begin =  mach_absolute_time()
        SQLiteTable.shared.doTransaction(exec: { (db) in
        for index in 0..<50000{
           let model = UserModel()
            model.name = "\(self.nameTextField.text!)\(index+1)"
            if let age = self.ageTextField.text ,Int(age) != nil{
                model.age = Int(age)! + index
            }
            if let image = self.authorImage.image {
                model.imageData = UIImagePNGRepresentation(image)
            }
            let nowDate = Date().timeIntervalSince1970
            model.createTime = nowDate + Double(index)
            
            if let count = UserViewModel.getAllDataUseSql(sql: "select * from \(UserViewModel.USER_TABLENAME)")?.count {
                model.id = count + 1
            }else{
                model.id = 1
            }
            self.saveSql(_model: model)
            print("==================\(index)")
        }
        
        })
        let end = mach_absolute_time()
        let some = Double(end - begin)
        print("=====过了多长时间\(some*pow(10, -9))")
    }
    
    
    private func saveSql(_model:UserModel){
        if UserViewModel.insertOrUpdateTable(_model) {
            if !test {
                 _ = self.navigationController?.popViewController(animated: true)
            }
           
        }else {
            let alert = UIAlertController.init(title: "", message: "保存失败", preferredStyle: .alert)
            let action = UIAlertAction.init(title: "确认", style: .cancel, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            print("-----------------")
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
