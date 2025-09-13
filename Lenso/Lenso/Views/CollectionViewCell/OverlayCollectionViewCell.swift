//
//  OverlayCollectionViewCell.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit
import DataProvider

final class OverlayCollectionViewCell: UICollectionViewCell {

    private let thumbnailImageView = UIImageView()
    private let nameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        nameLabel.text = nil
        isSelected = false
    }
    
    private func setupUI() {
        // Configure cell appearance
        layer.cornerRadius = 8
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor
        
        // Configure thumbnail image view
        thumbnailImageView.contentMode = .scaleAspectFit
        thumbnailImageView.layer.cornerRadius = 6
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure name label
        nameLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(nameLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            // Thumbnail image view
            thumbnailImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 60),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Name label
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])
    }
    
    func configure(with overlay: OverlayModel, isSelected: Bool) {
        nameLabel.text = overlay.overlayName
        
        // Load thumbnail image using overlayPreviewIconUrl
        if let url = URL(string: overlay.overlayPreviewIconUrl) {
            loadImage(from: url)
        }
        
        // Update selection state
        updateSelectionState(isSelected)
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self?.thumbnailImageView.image = image
            }
        }.resume()
    }
    
    private func updateSelectionState(_ selected: Bool) {
        isSelected = selected
        layer.borderColor = selected ? UIColor.systemPink.cgColor : UIColor.clear.cgColor
        backgroundColor = selected ? UIColor.systemPink.withAlphaComponent(0.1) : UIColor.systemBackground
    }
}
