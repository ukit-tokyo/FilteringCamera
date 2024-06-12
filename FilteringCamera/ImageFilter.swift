//
//  ImageFilter.swift
//  FilteringCamera
//
//  Created by Taichi Yuki on 2024/06/12.
//

import CoreImage

protocol PhotoFilter {
  var displayName: String { get }
  var filter: CIFilter? { get }
  var parameters: [String : Any]? { get }
}

extension PhotoFilter {
  var parameters: [String : Any]? { nil }
}

// MARK: -

let photoFilters: [PhotoFilter] = [
  Original(),
  ChromePhotoFilter(),
  FadePhotoFilter(),
  InstantPhotoFilter(),
  MonoPhotoFilter(),
  NoirPhotoFilter(),
  ProcessPhotoFilter(),
  TonalPhotoFilter(),
  TonePhotoFilter(),
  LinearPhotoFilter()
]

struct Original: PhotoFilter {
  let displayName = "Original"
  let filter: CIFilter? = nil
}

struct ChromePhotoFilter: PhotoFilter {
  let displayName = "Chrome"
  let filter = CIFilter(name: "CIPhotoEffectChrome")
}

struct FadePhotoFilter: PhotoFilter {
  let displayName = "Fade"
  let filter = CIFilter(name: "CIPhotoEffectFade")
}

struct InstantPhotoFilter: PhotoFilter {
  let displayName = "Instant"
  let filter = CIFilter(name: "CIPhotoEffectInstant")
}

struct MonoPhotoFilter: PhotoFilter {
  let displayName = "Mono"
  let filter = CIFilter(name: "CIPhotoEffectMono")
}

struct NoirPhotoFilter: PhotoFilter {
  let displayName = "Noir"
  let filter = CIFilter(name: "CIPhotoEffectNoir")
}

struct ProcessPhotoFilter: PhotoFilter {
  let displayName = "Process"
  let filter = CIFilter(name: "CIPhotoEffectProcess")
}

struct TonalPhotoFilter: PhotoFilter {
  let displayName = "Tonal"
  let filter = CIFilter(name: "CIPhotoEffectTonal")
}

struct TonePhotoFilter: PhotoFilter {
  let displayName = "Tone"
  let filter = CIFilter(name: "CILinearToSRGBToneCurve")
}

struct LinearPhotoFilter: PhotoFilter {
  let displayName = "Linear"
  let filter = CIFilter(name: "CISRGBToneCurveToLinear")
}
