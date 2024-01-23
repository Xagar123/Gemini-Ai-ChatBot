//
//  ResponseTableViewCell.swift
//  GemeniAi project
//
//  Created by Sagar on 22/01/24.
//

import UIKit

class ResponseTableViewCell: UITableViewCell {

    @IBOutlet weak var responseLabel: UILabel!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
