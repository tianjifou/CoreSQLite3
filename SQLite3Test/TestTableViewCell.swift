//
//  TestTableViewCell.swift
//  SQLite3Test
//
//  Created by 天机否 on 17/1/12.
//  Copyright © 2017年 tianjifou. All rights reserved.
//

import UIKit

class TestTableViewCell: UITableViewCell {

    @IBOutlet weak var authorImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var createTimeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func setCell(model:UserModel) {
        if let data = model.imageData {
              authorImage.image = UIImage.init(data: data)
        }
      nameLabel.text = "姓名： \(model.name)"
      ageLabel.text  = "年龄：  \(model.age)"
      createTimeLabel.text = "时间：  \(makeTimeStr(time: model.createTime))"
    }
    
    func makeTimeStr(time: Double) -> String {
       let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        formatter.timeZone = TimeZone.init(identifier: "shanghai")
        return formatter.string(from: Date.init(timeIntervalSince1970: time))
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
