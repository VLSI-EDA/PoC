
# `*.rules` Files

If the pre- or post-processing rules (copying, patching, deleting) for IP cores
are to long or to many, then it's possible to out-source these rules into a
separate `*.rules` file. A rules file supports 2 main sections: `PreProcessRules`
and `PostProcessRules`. Line comments start with `#`.

### Main Sections

Rules files support two main sections:

  - `PreProcessRules .. End PreProcessRules`  
    The listed rules in this section are processed before the IP core generation.
    It's possible to copy additional source files into the working directory or to
    patch source files before usage.
		
		Allowed rules:
		
      - `Copy ...`
      - `File ...`
		
  - `PostProcessRules .. End PostProcessRules`  
    These rules are processed after the successful IP core generation. Additional
    to the rules from the `PreProcessRules`, it's possible to delete generated files.
    (Output directory clean-up.)
		
		Allowed rules:
		
      - `Copy ...`
      - `File ...`
      - `Delete ...`
		
### Rules
		
There are three possible rules:

  - `Copy "<SourceFile> To "<DestinationFile>"`  
    This rule copies a source file to a destination file. The destination file name
    can differ from source file (rename file while copying). Non existent parent
    directories in the path to the destination file, are created before copying.
  - `File "<File>" .. End File`  
    This rule allows several sub rules to be applied to a single file:
		
      - `Replace "<SearchPattern>" With "<ReplacePattern>" [Options <OptionList>]`  
        This file-base sub-rule applies a regular expression replacement to a file.
        The first parameter `<SearchPattern>` is a Python Regular Expression, which
        is used to find a match in the file. The second parameter `<ReplacePattern>` is
        the corresponding replacement pattern. Both strings have to escape `\` and `"`
        characters by an additional `\`-character. No other character has to be escaped.
        
        It's possible to pass one to three optional options to the Python `re` module:
				
          - `Multiline`
          - `DotAll`
          - `CaseInsensitive`

  - `Delete "<File>"`  
    This rule deletes a file.

### Using String Interpolation

Each string (file name, pattern) can include `${[<SectionName>:]<OptionName>}` variables.
These variables are looked up in the ini-file based database and interpolated according
to that rules. A variable can contain a single option name (search in the current section)
or a section name plus option name, delimited by a `:`-sign. Variables can be nested. The
interpolation starts at the section, which referenced the rules files.

*Note:* It's possible to create a new option in the netlist's section (in the ini-file) and
use it in the rules file like a local variable. This is useful for long concatenated paths.

*Note:* Look into the *.files file help for more details on string interpolation.

### Execution order

The listed rules are executed in order of appearance in the rules files. Here is the execution
order in relation to the IP core generation:

 1. Pre-process rules
     1. Copy rules
     2. Replace rules
 2. *Generate IP core*
 3. Pre-process rules
     1. Copy rules
     2. Replace rules
     2. Delete rules
