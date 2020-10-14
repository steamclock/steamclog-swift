//
//  NetableExampleViewController.swift
//  SteamcLog_Example
//
//  Created by Brendan on 2020-05-19.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Netable
import SteamcLog
import UIKit

class NetableExampleViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let netable = Netable(baseURL: URL(string: "https://api.thecatapi.com/v1/")!, logDestination: RedactedLogDestination(clog: clog))

        netable.request(GetCatRequest()) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                clog.info("Success!")
            case .failure(let error):
                let alert = UIAlertController(
                    title: "Uh oh!",
                    message: "Get cat image failed with error: \(error)",
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

struct CatImage: Decodable {
    let id: String
    let url: String
}

struct GetCatRequest: Request {
    typealias Parameters = [String: String]
    typealias RawResource = [CatImage]
    typealias FinalResource = UIImage

    public var method: HTTPMethod { return .get }

    public var path: String {
        return "images/search"
    }

    public var parameters: [String: String] {
        return ["mime_type": "jpg,png"]
    }

    func finalize(raw: RawResource) -> Result<FinalResource, NetableError> {
        guard let catImage = raw.first else {
            return .failure(NetableError.resourceExtractionError("The expected cat image array is empty"))
        }

        guard let url = URL(string: catImage.url) else {
            return .failure(NetableError.resourceExtractionError("The expected cat image url is invalid"))
        }

        do {
            let data = try Data(contentsOf: url)

            if let image = UIImage(data: data) {
                return .success(image)
            } else {
                return .failure(NetableError.resourceExtractionError("Could not create image from the cat image data"))
            }
        } catch {
            return .failure(NetableError.resourceExtractionError("Could not load contents of the cat image url"))
        }
    }
}
