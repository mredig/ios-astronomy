//
//  PhotosCollectionViewController.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

	let networkHandler = NetworkHandler()
	let cache = Cache<Int, UIImage>()

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

		loadImage(forCell: imageCell, forItemAt: indexPath)

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

	// MARK: - Private

	private func loadImage(forCell cell: ImageCollectionViewCell, forItemAt indexPath: IndexPath) {

		let photoReference = photoReferences[indexPath.item]
		guard let photoURL = photoReference.imageURL.usingHTTPS else { return }

		if let image = cache.value(for: photoReference.id) {
			cell.imageView.image = image
			return
		}

		networkHandler.transferMahDatas(with: photoURL.request) { [weak self] (result: Result<Data, NetworkError>) in
			DispatchQueue.main.async {
				do {
					let imageData = try result.get()
					guard let image = UIImage(data: imageData) else { throw NetworkError.imageDecodeError }
					self?.cache.cache(value: image, for: photoReference.id)

					// broken idea 1
//					guard let cellCheck = self?.collectionView.cellForItem(at: indexPath) else {
//						print("no cell at \(indexPath)")
//						return
//					}
//					guard cellCheck == cell else { return }

					// broken idea 2
					guard let cellPath = self?.collectionView.indexPath(for: cell) else {
						print("cell has no path...")
						return
					}
					print("cellPath: \(cellPath) indexPathFromRequest: \(indexPath)")

					if cellPath == indexPath {
						cell.imageView.image = image
					}
				} catch {
					let alert = UIAlertController(error: error)
					self?.present(alert, animated: true)
				}
			}
		}

		// TODO: Implement image loading here
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
