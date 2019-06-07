//
//  PhotosCollectionViewController.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

	let cache = Cache<Int, UIImage>()

	let photoFetchQueue = OperationQueue()

	var imageLoadOperations = [Int: Operation]()

	override func viewDidLoad() {
		super.viewDidLoad()

		client.fetchMarsRover(named: "curiosity") { (rover, error) in
			if let error = error {
				NSLog("Error fetching info for curiosity: \(error)")
				return
			}

			self.roverInfo = rover
		}
	}

	// UICollectionViewDataSource/Delegate

	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photoReferences.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
		guard let imageCell = cell as? ImageCollectionViewCell else { return cell }

		imageCell.cache = cache
		imageCell.reference = photoReferences[indexPath.row]

		return cell
	}

	// Make collection view cells fill as much available width as possible
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
		var totalUsableWidth = collectionView.frame.width
		let inset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
		totalUsableWidth -= inset.left + inset.right

		let minWidth: CGFloat = 150.0
		let numberOfItemsInOneRow = Int(totalUsableWidth / minWidth)
		totalUsableWidth -= CGFloat(numberOfItemsInOneRow - 1) * flowLayout.minimumInteritemSpacing
		let width = totalUsableWidth / CGFloat(numberOfItemsInOneRow)
		return CGSize(width: width, height: width)
	}

	// Add margins to the left and right side
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets(top: 0, left: 10.0, bottom: 0, right: 10.0)
	}

	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		let photoReference = photoReferences[indexPath.row]
		imageLoadOperations[photoReference.id]?.cancel()
	}


	// Properties

	private let client = MarsRoverClient()

	private var roverInfo: MarsRover? {
		didSet {
			solDescription = roverInfo?.solDescriptions[100]
		}
	}
	private var solDescription: SolDescription? {
		didSet {
			if let rover = roverInfo,
				let sol = solDescription?.sol {
				client.fetchPhotos(from: rover, onSol: sol) { (photoRefs, error) in
					if let e = error { NSLog("Error fetching photos for \(rover.name) on sol \(sol): \(e)"); return }
					self.photoReferences = photoRefs ?? []
				}
			}
		}
	}
	private var photoReferences = [MarsPhotoReference]() {
		didSet {
			DispatchQueue.main.async { self.collectionView?.reloadData() }
		}
	}

	@IBOutlet var collectionView: UICollectionView!
}
