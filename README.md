Haneke
======
[![Build Status](https://travis-ci.org/hpique/Haneke.png)](https://travis-ci.org/hpique/Haneke)

###### A lightweight zero-config image cache for iOS. 

Haneke resizes images and caches the result on memory and disk. Everything is done in background, allowing for fast, responsive scrolling. Asking Haneke to produce and cache an appropiately sized image for an `UIImageView` is as simple as:


```objective-c
[imageView hnk_setImageFromFile:path];
```

_Really._

##Features

* First-level memory cache using `NSCache`.
* Second-level LRU disk cache using the file system.
* Asynchronous and synchronous image retrieval.
* Background image resizing and file reading.
* Thread-safe.
* Automatic cache eviction on memory warnings or disk capacity reached.
* Preloading images from the disk cache into memory on startup.
* Zero-config `UIImageView` category to use the cache, optimized for `UITableView` and `UICollectionView` cell reuse.

##Add Haneke to your project

1. Add the [Haneke](https://github.com/hpique/Haneke/tree/master/Haneke) folder to your project.
2. Profit!

##UIImageView category

Haneke provides convenience methods for `UIImageView` with optimizations for `UITableView` and `UICollectionView` cell reuse. Images will be resized appropiately and cached.

```
// Setting an image from disk
[imageView hnk_setImageFromFile:path];

// Setting an image manually. Requires you to provide a key.
[imageView hnk_setImage:image withKey:key];
```

The above lines takes care of:

* If cached, retreiving an appropiately sized image (based on the `bounds` and `contentMode` of the `UIImageView`) from the memory or disk cache. Disk access is performed in background.
* If not cached, reading the original image from disk/memory and producing an appropiately sized image, both in background.
* Setting the image and animating the change if appropiate.
* Or doing nothing if the `UIImageView` was reused before finishing retreiving the image.
* Caching the resulting image.
* If needed, evicting the least recently used images in the cache.



##Requirements

Haneke requires iOS 7.0 or above and ARC. 

##Roadmap

Haneke is in initial development and its public API should not be considered stable.

##License

 Copyright 2014 Hermes Pique (@hpique)
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.