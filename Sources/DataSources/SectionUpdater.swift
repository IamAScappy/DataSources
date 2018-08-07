//
//  Updater.swift
//  DataSources
//
//  Created by muukii on 8/8/17.
//  Copyright © 2017 muukii. All rights reserved.
//

import UIKit

import DifferenceKit

final class SectionUpdater<T: Differentiable, A: Updating> {

  enum State {
    case idle
    case updating
  }

  enum UpdateMode {
    case everything
    case partial(animated: Bool)
  }

  let adapter: A

  private let queue = DispatchQueue.main
  private var state: State = .idle

  init(adapter: A) {
    self.adapter = adapter
  }

  func update(
    targetSection: Int,
    currentDisplayingItems: [T],
    newItems: [T],
    updateMode: UpdateMode,
    completion: @escaping () -> Void
    ) {

    assertMainThread()

    self.state = .updating

    switch updateMode {
    case .everything:
      adapter.reload {
        assertMainThread()
        self.state = .idle
        completion()
      }
    case .partial(let preferredAnimated):

      let stagedChangeset = StagedChangeset.init(source: currentDisplayingItems, target: newItems)

      let totalChangeCount = stagedChangeset.map { $0.changeCount }.reduce(0, +)

      guard totalChangeCount > 0 else {
        return
      }

      let animated: Bool

      if totalChangeCount > 300 {
        animated = false
      } else {
        animated = preferredAnimated
      }
      
      let _adapter = self.adapter
      
      
      
      self.adapter.performBatch(
        animated: animated,
        updates: {
          
          for changeset in stagedChangeset {
            
            _adapter.insertItems(at: changeset.elementInserted.map { IndexPath(item: $0.element, section: targetSection) })
            _adapter.deleteItems(at: changeset.elementDeleted.map { IndexPath(item: $0.element, section: targetSection) })
            _adapter.reloadItems(at: changeset.elementUpdated.map { IndexPath(item: $0.element, section: targetSection) })
            
            for (source, target) in changeset.elementMoved {
              _adapter.moveItem(
                at: IndexPath(item: source.element, section: targetSection),
                to: IndexPath(item: target.element, section: targetSection)
              )
            }
            
          }
          
      },
        completion: {
          assertMainThread()
          
          self.state = .idle
          completion()
          
      }
      )
      
      
    }
  }
}
