//
//  ChapterPageCollectionViewController.swift
//  Yomu
//
//  Created by Sendy Halim on 7/20/16.
//  Copyright © 2016 Sendy Halim. All rights reserved.
//

import AppKit
import RxSwift
import Swiftz

protocol ChapterPageCollectionViewDelegate: class {
  func closeChapterPage()
}

class ChapterPageCollectionViewController: NSViewController {
  @IBOutlet weak var collectionView: NSCollectionView!
  @IBOutlet weak var close: NSButton!
  @IBOutlet weak var readingProgress: NSTextField!
  @IBOutlet weak var zoomIn: NSButton!
  @IBOutlet weak var zoomOut: NSButton!
  @IBOutlet weak var zoomScale: NSTextField!
  @IBOutlet weak var headerTitle: NSTextField!
  @IBOutlet weak var nextChapterButton: NSButton!
  @IBOutlet weak var previousChapterButton: NSButton!

  weak var delegate: ChapterPageCollectionViewDelegate?
  weak var chapterSelectionDelegate: ChapterSelectionDelegate?

  var vm: ChapterPageCollectionViewModel
  var navigator: ChapterNavigator
  var disposeBag = DisposeBag()

  init(viewModel: ChapterPageCollectionViewModel, navigator: ChapterNavigator) {
    self.vm = viewModel
    self.navigator = navigator

    super.init(nibName: "ChapterPageCollection", bundle: nil)!
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewWillLayout() {
    super.viewWillLayout()
    collectionView.collectionViewLayout?.invalidateLayout()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.dataSource = self
    collectionView.delegate = self
    setupSubscriptions()
  }

  func setupSubscriptions() {
    disposeBag = DisposeBag()

    zoomIn
      .rx.tap
      .bindTo(vm.zoomIn) ==> disposeBag

    zoomOut
      .rx.tap
      .bindTo(vm.zoomOut) ==> disposeBag

    close
      .rx.tap
      .subscribe(onNext: { [weak self] in
        self?.delegate?.closeChapterPage()
      }) ==> disposeBag

    nextChapterButton
      .rx.tap
      .subscribe(onNext: { [weak self] in
        guard let `self` = self else {
          return
        }

        guard let (navigator, nextChapterVM) = self.navigator.next() else {
          return
        }

        self.chapterSelectionDelegate?.chapterDidSelected(nextChapterVM.chapter, navigator: navigator)
      }) ==> disposeBag

    previousChapterButton
      .rx.tap
      .subscribe(onNext: { [weak self] in
        guard let `self` = self else {
          return
        }

        guard let (navigator, previousChapterVM) = self.navigator.previous() else {
          return
        }

        self.chapterSelectionDelegate?.chapterDidSelected(previousChapterVM.chapter, navigator: navigator)
      }) ==> disposeBag

    vm.reload ~~> collectionView.reloadData ==> disposeBag

    vm.invalidateLayout
      ~~> collectionView.collectionViewLayout!.invalidateLayout
      ==> disposeBag

    vm.readingProgress
      ~~> readingProgress.rx.text.orEmpty
      ==> disposeBag

    vm.zoomScale
      .asDriver(onErrorJustReturn: "")
      ~~> zoomScale.rx.text.orEmpty
      ==> disposeBag

    vm.headerTitle
      ~~> headerTitle.rx.text.orEmpty
      ==> disposeBag

    vm.zoomScroll ~~> scroll ==> disposeBag

    vm.fetch() ==> disposeBag

    zoomScale
      .rx.controlEvent
      .map { [weak self] in
        self!.zoomScale.stringValue
      }
      .filter {
        $0 != nil
      } ~~> vm.setZoomScale ==> disposeBag
  }

  func scroll(offset: ScrollOffset) {
    let targetRect = collectionView.visibleRect.offsetBy(dx: 0, dy: offset.deltaY)

    collectionView.scrollToVisible(targetRect)
  }
}

extension ChapterPageCollectionViewController: NSCollectionViewDataSource {
  func numberOfSections(in collectionView: NSCollectionView) -> Int {
    return 1
  }

  func collectionView(
    _ collectionView: NSCollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    return vm.count
  }

  func collectionView(
    _ collectionView: NSCollectionView,
    itemForRepresentedObjectAt indexPath: IndexPath
  ) -> NSCollectionViewItem {
    let cell = collectionView.makeItem(
      withIdentifier: "ChapterPageItem",
      for: indexPath
    ) as! ChapterPageItem

    cell.setup(withViewModel: vm[(indexPath as NSIndexPath).item])

    return cell
  }
}

extension ChapterPageCollectionViewController: NSCollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: NSCollectionView,
    willDisplay item: NSCollectionViewItem,
    forRepresentedObjectAt indexPath: IndexPath
  ) {
    vm.setCurrentPageIndex((indexPath as NSIndexPath).item)
  }

  func collectionView(
    _ collectionView: NSCollectionView,
    layout collectionViewLayout: NSCollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> NSSize {
    return vm.pageSize
  }
}
