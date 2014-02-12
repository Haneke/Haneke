Haneke
======

A lightweight zero-config image cache for iOS apps that need to display images in sizes that differ from the original. Resizing an image in background using the cache is as simple as:


```objective-c
[imageView hnk_setImageFromPath:path];
```

Really. 

The above line takes care of:

* If cached, retreiving an appropiately sized (based on the `bounds` and `contentMode` of the `UIImageView`) from the memory or disk cache. Disk access is performed in background.
* If not cached, reading the original image from disk and creating an appropiately sized image in background.
* Setting the image and animating the image change if appropiate.
* Caching the resulting image.
* If needed, evicting the least recently used images in the cache.


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