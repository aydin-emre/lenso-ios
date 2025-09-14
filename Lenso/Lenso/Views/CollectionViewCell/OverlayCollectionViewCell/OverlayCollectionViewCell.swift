//
//  OverlayCollectionViewCell.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit
import DataProvider

final class OverlayCollectionViewCell: UICollectionViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var backgroundContainerView: UIView!

    private var thumbnailWidthConstraint: NSLayoutConstraint?
    private var thumbnailHeightConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.contentMode = .scaleAspectFit
        thumbnailImageView.clipsToBounds = true

        if thumbnailWidthConstraint == nil {
            let w = thumbnailImageView.widthAnchor.constraint(equalToConstant: 60)
            w.priority = .required
            w.isActive = true
            thumbnailWidthConstraint = w
        }
        if thumbnailHeightConstraint == nil {
            let h = thumbnailImageView.heightAnchor.constraint(equalToConstant: 60)
            h.priority = .required
            h.isActive = true
            thumbnailHeightConstraint = h
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        nameLabel.text = nil
        isSelected = false
    }

    func configure(with overlay: OverlayModel?, isSelected: Bool) {
        if let overlay = overlay {
            nameLabel.text = overlay.overlayName
            if let url = URL(string: overlay.overlayPreviewIconUrl) {
                loadImage(from: url)
            }
            thumbnailWidthConstraint?.constant = 60
            thumbnailHeightConstraint?.constant = 60
        } else {
            nameLabel.text = "overlay.none".localized
            thumbnailImageView.image = UIImage(systemName: "nosign")
            thumbnailImageView.tintColor = .gray
            thumbnailImageView.contentMode = .scaleAspectFit
            thumbnailWidthConstraint?.constant = 30
            thumbnailHeightConstraint?.constant = 30
        }
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
        backgroundContainerView.layer.borderWidth = 2
        backgroundContainerView.layer.borderColor = selected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
    }
}
