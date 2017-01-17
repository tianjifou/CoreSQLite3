//
//  ViewController.swift
//  SQLite3Test
//
//  Created by 天机否 on 17/1/12.
//  Copyright © 2017年 tianjifou. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var arrData: [UserModel] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib.init(nibName: String.init(describing: TestTableViewCell.self), bundle: nil), forCellReuseIdentifier: String.init(describing: TestTableViewCell.self))
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSqlData(sql: "select * from \(UserViewModel.USER_TABLENAME)")
    }
    fileprivate func reloadSqlData(sql:String) {
       arrData.removeAll()
        if let arr = UserViewModel.getAllDataUseSql(sql: sql) {
            
            arrData += arr
        }
        
        tableView.reloadData()
    }
    @IBAction func settingAction(_ sender: Any) {

        self.performSegue(withIdentifier: "pushSettingViewController", sender: nil)
    }
    @IBAction func sortAction(_ sender: Any) {
        let alertController = UIAlertController(title: "排序", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler:nil)
        let deleteAction = UIAlertAction(title: "按年龄升序排序", style: UIAlertActionStyle.destructive){ [weak self](action: UIAlertAction!) in
            if let weakSelf = self {
                weakSelf.reloadSqlData(sql: "select * from \(UserViewModel.USER_TABLENAME)  order by age asc")
            }
        }
        let archiveAction = UIAlertAction(title: "按时间降序排序", style: UIAlertActionStyle.destructive){ [weak self](action: UIAlertAction!) in
            if let weakSelf = self {
                weakSelf.reloadSqlData(sql: "select * from \(UserViewModel.USER_TABLENAME)  order by createTime desc")
            }
        }
       
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        alertController.addAction(archiveAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if   let vc = segue.destination as? SettingViewController  {
            if let  model = sender as? UserModel {
                vc.model = model
            }
        }
    }

}

extension ViewController: UITableViewDelegate,UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return  arrData.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView.dequeueReusableCell(withIdentifier: String.init(describing: TestTableViewCell.self)) as! TestTableViewCell
        cell.setCell(model: arrData[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "pushSettingViewController", sender: arrData[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if  UserViewModel.delectData(arrData[indexPath.row]) {
            reloadSqlData(sql: "select * from \(UserViewModel.USER_TABLENAME)")
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
}
