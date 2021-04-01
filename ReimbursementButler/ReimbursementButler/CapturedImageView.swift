//
//  CapturedImageView.swift
//

import UIKit

class CapturedImageView : UIView {
    //MARK:- Vars
    var image : UIImage? {
        didSet {
            guard let image = image else {return}
            imageView.image = image
        }
    }

    let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView(){
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 8
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
        ])
    }
}


