//
//  ImageCollectionViewCell.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {

	@IBOutlet var indicatorView: UIView!
	
	var cache: Cache<Int, UIImage>?
	var reference: MarsPhotoReference? {
		didSet {
			updateViews()
		}
	}
	private var imageLoadOperation: BlockOperation?
	private let cellQueue: OperationQueue = {
		let q = OperationQueue()
		q.name = UUID().uuidString
		return q
	}()

	override func awakeFromNib() {
		indicatorView.layer.cornerRadius = 4
//		_ = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { _ in
//			self.statusCheck()
//		})
	}

	private func statusCheck() {
		if imageLoadOperation != nil, imageLoadOperation?.isCancelled == false {
			self.indicatorView.backgroundColor = .red
		} else {
			self.indicatorView.backgroundColor = .green
		}
	}
    
    override func prepareForReuse() {
        imageView.image = #imageLiteral(resourceName: "MarsPlaceholder")
        super.prepareForReuse()
    }

	func updateViews() {
		guard let reference = reference else { return }
		imageLoadOperation?.cancel()
		imageLoadOperation = nil
		if let image = cache?.value(forKey: reference.id) {
			imageView.image = image
			return
		}

		let photoFetchOp = PhotoFetchOperation(reference: reference)
		let cacheOp = BlockOperation { [weak self] in
			guard let imageData = photoFetchOp.imageData else { return }
			guard let image = UIImage(data: imageData) else { return }
			self?.cache?.cache(value: image, forKey: reference.id)
		}
		imageLoadOperation = BlockOperation()
		guard let imageLoadOperation = imageLoadOperation else { return }
		imageLoadOperation.addExecutionBlock { [weak self] in
			defer {
				self?.imageLoadOperation = nil
				self?.statusCheck()
			}

			guard let imageData = photoFetchOp.imageData, self?.imageLoadOperation?.isCancelled == false else { return }
			self?.imageView.image = UIImage(data: imageData)
		}

		cacheOp.addDependency(photoFetchOp)
		imageLoadOperation.addDependency(photoFetchOp)

		cellQueue.addOperations([photoFetchOp, cacheOp], waitUntilFinished: false)
		OperationQueue.main.addOperation(imageLoadOperation)
		statusCheck()

	}

    
    // MARK: Properties
    
    // MARK: IBOutlets
    
    @IBOutlet var imageView: UIImageView!
}
