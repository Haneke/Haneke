Haneke
======

A lightweight zero-config image cache for iOS apps that display images in various sizes. Getting or creating an appropiately sized image is as simple as:


```objective-c
[imageView hnk_setImageFromPath:path];
```

_Really._

The above line takes care of:

* If cached, retreiving an appropiately sized image (based on the `bounds` and `contentMode` of the `UIImageView`) from the memory or disk cache. Disk access is performed in background.
* If not cached, reading the original image from disk and creating an appropiately sized image, both in background.
* Setting the image and animating the change if appropiate.
* Caching the resulting image.
* If needed, evicting the least recently used images in the cache.


##Add Haneke to your project

1. Add the [Haneke](https://github.com/hpique/Haneke/tree/master/Haneke) folder to your project.
2. Profit!


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