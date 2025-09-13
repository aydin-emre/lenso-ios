//
//  ViewController.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit
import DataProvider

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        fetchOverlays()
    }
    
    private func fetchOverlays() {
        let request = GetOverlaysRequest()
        
        apiDataProvider.request(for: request) { [weak self] result in
            switch result {
            case .success(let response):
                print("Successfully fetched \(response.overlays.count) overlays")
                for overlay in response.overlays {
                    print("Overlay ID: \(overlay.overlayId), Name: \(overlay.overlayName)")
                    print("Preview URL: \(overlay.overlayPreviewIconUrl)")
                    print("Overlay URL: \(overlay.overlayUrl)")
                    print("---")
                }
            case .failure(let error):
                print("Failed to fetch overlays: \(error.localizedDescription)")
            }
        }
    }
}

