# Namespace `PoC.sort`

The namespace `PoC.sort` offers implementations of sorting algorithms.


## Sub-Namespace(s)

 -  [`PoC.sort.sortnet`][sort_sortnet] contains sorting network implementations.

## Package(s)

The package [`sort`][sort.pkg] holds all component declarations for this namespace.

```VHDL
library PoC;
use     PoC.sort.all;
```


## Entities

 -  [`sort_lru_cache`][sort_lru_cache] implements a list of least-recently-used (LRU) items. The implementation is optimized for the use in caches.


 [sort_sortnet]:				sortnet

 [sort.pkg]:					sort.pkg.vhdl

 [sort_lru_cache]:				sort_lru_cache.vhdl
