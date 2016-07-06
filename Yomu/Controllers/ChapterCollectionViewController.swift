//
//  ChapterCollectionViewController.swift
//  Yomu
//
//  Created by Sendy Halim on 6/16/16.
//  Copyright © 2016 Sendy Halim. All rights reserved.
//

import Cocoa
import Kingfisher
import RxSwift
import Swiftz

class ChapterCollectionViewController: NSViewController {
  @IBOutlet weak var collectionView: NSCollectionView!

  let vm = ChaptersViewModel()
  var disposeBag = DisposeBag()

  func setupConstraints() {
    let width = NSLayoutConstraint(
      item: view,
      attribute: .Width,
      relatedBy: .GreaterThanOrEqual,
      toItem: nil,
      attribute: .NotAnAttribute,
      multiplier: 1,
      constant: 450
    )

    let height = NSLayoutConstraint(
      item: view,
      attribute: .Height,
      relatedBy: .GreaterThanOrEqual,
      toItem: nil,
      attribute: .NotAnAttribute,
      multiplier: 1,
      constant: 300
    )

    NSLayoutConstraint.activateConstraints([
      width,
      height
    ])
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupConstraints()

    collectionView.delegate = self
    collectionView.dataSource = self

    vm.chapters
      .driveNext { [weak self] chapters in
        self!.collectionView.reloadData()
      } >>> disposeBag
  }
}

extension ChapterCollectionViewController: NSCollectionViewDataSource {
  func collectionView(
    collectionView: NSCollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    return vm.count
  }

  func collectionView(
    collectionView: NSCollectionView,
    didEndDisplayingItem item: NSCollectionViewItem,
    forRepresentedObjectAtIndexPath indexPath: NSIndexPath
  ) {
    let _item = item as! ChapterItem

    _item.didEndDisplaying()
  }

  func collectionView(
    collectionView: NSCollectionView,
    itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath
  ) -> NSCollectionViewItem {
    let item = collectionView.makeItemWithIdentifier(
      "ChapterItem",
      forIndexPath: indexPath
    ) as! ChapterItem

    let chapter = vm[indexPath.item]
    let chapterPageVm = ChapterPagesViewModel(chapterId: chapter.id)

    chapterPageVm.fetch()
    chapterPageVm
      .chapterPages
      .driveNext { _ in
        guard let image = chapterPageVm.chapterImage else { return }

        item.chapterPreview.kf_setImageWithURL(image.url)
      } >>> item.disposeBag

    item.chapterTitle.stringValue = chapter.title

    return item
  }
}

extension ChapterCollectionViewController: NSCollectionViewDelegateFlowLayout {
  func collectionView(
    collectionView: NSCollectionView,
    didSelectItemsAtIndexPaths indexPaths: Set<NSIndexPath>
  ) {
    let index = indexPaths.first!.item
    let chapterId = vm[index].id

    print(chapterId)
  }
}

extension ChapterCollectionViewController: MangaSelectionDelegate {
  func mangaDidSelected(manga: Manga) {
    disposeBag = DisposeBag()

    // At this point we are sure that manga.id will 100% available
    vm.fetch(manga.id!) >>> disposeBag
  }
}
