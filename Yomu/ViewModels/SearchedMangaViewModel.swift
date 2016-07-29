//
//  SearchedMangaViewModel.swift
//  Yomu
//
//  Created by Sendy Halim on 7/29/16.
//  Copyright © 2016 Sendy Halim. All rights reserved.
//

import RxCocoa
import RxSwift

struct SearchedMangaViewModel {
  private let manga: Variable<SearchedManga>

  var previewUrl: Driver<NSURL> {
    return manga.asDriver().map { $0.image.url }
  }

  var title: Driver<String> {
    return manga.asDriver().map { $0.name }
  }

  init(manga: SearchedManga) {
    self.manga = Variable(manga)
  }
}
