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

 -  [`sort_ExpireList`][sort_ExpireList] *TODO: undocumented*.
 -  [`sort_InsertSort`][sort_InsertSort] implements a serial insert sort algorithm.
 -  [`sort_LeastFrequentlyUsed`][sort_LeastFrequentlyUsed] implements a list of least-frequently-used (LFU) items.
 -  [`sort_LeastRecentlyUsed`][sort_LeastRecentlyUsed] implements a list of least-recently-used (LRU) items.


 [sort_sortnet]:				sortnet

 [sort.pkg]:					sort.pkg.vhdl

 [sort_ExpireList]:				sort_ExpireList.vhdl
 [sort_InsertSort]:				sort_InsertSort.vhdl
 [sort_LeastFrequentlyUsed]:	sort_LeastFrequentlyUsed.vhdl
 [sort_LeastRecentlyUsed]:		sort_LeastRecentlyUsed.vhdl
