//
//  NetableExampleViewController.swift
//  SteamcLog_Example
//
//  Created by Brendan on 2020-05-19.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Netable
import SteamcLog
import SteamcLogNetable
import UIKit

class NetableExampleViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let netable = Netable(baseURL: URL(string: "https://api.thecatapi.com/v1/")!, logDestination: RedactedLogDestination(clog: clog))

        Task { @MainActor in
            do {
                try await netable.request(GetCatRequest())
                clog.info("Success!")
            } catch {
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

    func finalize(raw: RawResource) async throws -> FinalResource {
        guard let catImage = raw.first else {
            throw NetableError.resourceExtractionError("The expected cat image array is empty")
        }

        guard let url = URL(string: catImage.url) else {
            throw NetableError.resourceExtractionError("The expected cat image url is invalid")
        }

        guard let data = try? Data(contentsOf: url) else {
            throw NetableError.resourceExtractionError("Could not load contents of the cat image url")
        }

        guard let image = UIImage(data: data) else {
            throw NetableError.resourceExtractionError("Could not create image from the cat image data")
        }

        return image
    }
}
