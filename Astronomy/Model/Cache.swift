//
//  Cache.swift
//  Astronomy
//
//  Created by Michael Redig on 6/6/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation

class Cache <Key: Hashable, Value> {
	private(set) var contents = [Key: Value]()

	private let cacheQueue = DispatchQueue(label: "com.michael-lambda.cache")

	func cache(value: Value, forKey key: Key) {
		cacheQueue.sync {
			contents[key] = value
		}
	}

	func value(forKey key: Key) -> Value? {
		return cacheQueue.sync { contents[key] }
	}

	@discardableResult func removeValue(forKey key: Key) -> Value? {
		return cacheQueue.sync { contents.removeValue(forKey: key) }
	}
}
