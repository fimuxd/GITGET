//
//  SettingTableViewCell.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import RxSwift
import RxCocoa

class SettingTableViewCell: UITableViewCell {
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let iconImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(data menu: SettingMenu) {
        titleLabel.do {
            $0.text = menu.title
            $0.font = .systemFont(ofSize: 18, weight: .black)
            $0.textColor = .darkGray
            $0.numberOfLines = 0
        }
        
        descriptionLabel.do {
            $0.text = menu.description
            $0.font = .systemFont(ofSize: 16, weight: .light)
            $0.textColor = .gray
            $0.numberOfLines = 0
        }
        
        iconImageView.do {
            $0.image = menu.iconImage
            $0.clipsToBounds = true
            $0.contentMode = .scaleAspectFit
            
        }
    }
    
    func layout() {
        [titleLabel, descriptionLabel, iconImageView].forEach {
            addSubview($0)
        }
        
        iconImageView.snp.makeConstraints {
            $0.centerY.equalToSuperview().inset(16)
            $0.left.equalToSuperview().inset(12)
            $0.width.height.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.left.equalTo(iconImageView.snp.right).offset(12)
            $0.right.equalToSuperview().offset(-8)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.bottom.lessThanOrEqualToSuperview().offset(-10)
            $0.left.equalTo(titleLabel)
            $0.right.equalToSuperview().offset(-8)
        }
    }
}
