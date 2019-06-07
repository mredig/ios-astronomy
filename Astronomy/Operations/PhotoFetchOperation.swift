//
//  File.swift
//  Astronomy
//
//  Created by Michael Redig on 6/6/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation

class PhotoFetchOperation: ConcurrentOperation {
	let reference: MarsPhotoReference
	var imageData: Data?
	private var currentTask: URLSessionDataTask?

	init(reference: MarsPhotoReference) {
		self.reference = reference
	}

	override func start() {
		guard let request = reference.imageURL.usingHTTPS?.request else {
			NSLog("Operation for \(reference) never started - invalid URL.")
			return
		}
		state = .isExecuting
		currentTask = NetworkHandler.default.transferMahDatas(with: request, completion: { [weak self] (result: Result<Data, NetworkError>) in
			guard let self = self else { return }
			defer {
				self.state = .isFinished
				self.currentTask = nil
			}
			do {
				let imageData = try result.get()
				self.imageData = imageData
			} catch {
				NSLog("There was an error loading an image: \(error)")
			}
		})
	}

	override func cancel() {
		currentTask?.cancel()
	}
}
