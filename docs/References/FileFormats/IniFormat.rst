.. _FileFormat:ini:

.. raw:: html

   <style>
   ddiv svg.railroad-diagram {
     width: 80%;    /* Scale to the width of the parent */
     height: 100%;  /* Preserve the ratio. Could be related to https://bugs.webkit.org/show_bug.cgi?id=82489 */
   }
   </style>
   <link rel="stylesheet" href="../../_static/css/railroad-diagrams.css" />
   <script type="text/javascript" src="../../_static/javascript/railroad-diagrams.js" ></script>

*.ini Format
############

.. contents:: Contents of this Page
   :local:

**Document rule:**

.. raw:: html

   <div>
     <script type="text/javascript">
     ComplexDiagram(
       ZeroOrMore(
         NonTerminal('DocumentLine')
       )
     ).addTo(this.parentElement);
     </script>
   </div>

**DocumentLine rule:**

.. raw:: html

   <div>
     <script type="text/javascript">
     ComplexDiagram(
       Choice(0,
         NonTerminal('Section'),
         Sequence(
           Choice(0,
             Sequence('#', NonTerminal('CommentText')),
             Sequence(NonTerminal('WhiteSpace'))
           ),
           Choice(0, '\\n', '\\r\\n', '\\r')
         )
       )
     ).addTo(this.parentElement);
     </script>
   </div>

**Section rule:**

.. raw:: html

   <div>
     <script type="text/javascript">
     ComplexDiagram(
       Stack(
         Sequence('[', Choice(0,
             NonTerminal('FQSectionName'),
             'PoC',
             'BOARDS',
             'SPECIAL'
           ), ']', Choice(0, '\\n', '\\r\\n', '\\r')
         ),
         ZeroOrMore(Sequence(NonTerminal('OptionLine'), Choice(0, '\\n', '\\r\\n', '\\r')))
       )
     ).addTo(this.parentElement);
     </script>
   </div>

**OptionLine rule:**

.. raw:: html

   <div>
     <script type="text/javascript">
     ComplexDiagram(
       Choice(0,
         Sequence(NonTerminal('ReferenceName'), '\\s*', '=', '\\s*', NonTerminal('Keyword')),
         Sequence(NonTerminal('OptionName'), '\\s*', '=', '\\s*', NonTerminal('OptionValue')),
         Sequence(NonTerminal('VariableName'), '\\s*', '=', '\\s*', NonTerminal('VariableValue'))
       )
     ).addTo(this.parentElement);
     </script>
   </div>

**FQSectionName rule:**

.. raw:: html

   <div>
     <script type="text/javascript">
     ComplexDiagram(
       Sequence(NonTerminal('PREFIX'), '.', OneOrMore(NonTerminal('SectionNamePart')))
     ).addTo(this.parentElement);
     </script>
   </div>


..
   productionlist::
   Document: `DocumentLine`*
   DocumentLine: `SpecialSection` | `Section` | `CommentLine` | `EmptyLine`
   CommentLine: "#" `CommentText` `LineBreak`
   EmptyLine: `WhiteSpace`* `LineBreak`
   SpecialSection: "[" `SimpleString` "]"
                 : (`OptionLine`)*
   Section: "[" `FQSectionName` "]"
          : (`OptionLine`)*
   OptionLine: `Reference` | `Option` | `UserDefVariable`
   Reference: `ReferenceName` `WhiteSpace`* "=" `WhiteSpace`* `Keyword`
   Option: `OptionName` `WhiteSpace`* "=" `WhiteSpace`* `OptionValue`
   UserDefVariable: `VariableName` `WhiteSpace`* "=" `WhiteSpace`* `VariableValue`
   FQSectionName: `Prefix` "." `SectionName`
   SectionName: `SectionNamePart` ("." `SectionNamePart`)*
   SectionNamePart: `SimpleString`
   ReferenceName: `SimpleString`
   OptionName: `SimpleString`
   VariableName: `SimpleString`
