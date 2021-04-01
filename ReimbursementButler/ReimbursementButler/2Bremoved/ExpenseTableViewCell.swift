//
//  ExpenseTableViewCell.swift
//

import UIKit

class ExpenseTableViewCell: UITableViewCell {
    @IBOutlet weak var expenseLabel: UILabel!

    @IBOutlet weak var photoIndicatorImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setExpenseItem(expenseItem: ExpenseItem) {

        expenseLabel.text = expenseItem.text

        if(expenseItem.imageURL != nil) {
            let image = UIImage(systemName: "photo.on.rectangle")
            photoIndicatorImageView.image = image
        } else {
            photoIndicatorImageView.image = nil
        }
    }

}
