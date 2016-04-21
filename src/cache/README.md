# Namespace `PoC.cache`

The namespace `PoC.cache` offers different cache implementations.


## Package

The package [`PoC.cache`][cache.pkg] holds all component declarations for this namespace.


## Entities

 -  [`cache_par`][cache_par] - Cache with parallel tag-unit and data memory.  
    The cache can be configured as:
      - Full-associative cache
      - Direct-mapped cache
      - Set-assoziative cache
    
    as well as in data and tag memory size (`CACHE_LINES`, `ADDRESS_BITS`, `DATA_BITS`)
 -  [`cache_replacement_policy`][cache_replacement_policy] - Wrap different cache replacement policies.
    Selectable replacement policies:
      - LRU
      - *TODO: implement more policies*
 -  [`cache_tagunit_par`][cache_tagunit_par] - Tag-unit with fully-parallel compare of tag.
    The tagunit can be configured as:
      - Full-associative cache
      - Direct-mapped cache
      - Set-assoziative cache
    
    as well as in tag memory size (`CACHE_LINES`, `ADDRESS_BITS`)
 -  [`cache_tagunit_seq`][cache_tagunit_seq] - Tag-unit with sequential compare of tag.


 [cache.pkg]:					cache.pkg.vhdl

 [cache_par]:					cache_par.vhdl
 [cache_replacement_policy]:	cache_replacement_policy.vhdl
 [cache_tagunit_par]:			cache_tagunit_par.vhdl
 [cache_tagunit_seq]:			cache_tagunit_seq.vhdl
