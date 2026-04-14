# Document Formatting

## Table of Contents

- Include a clickable table of contents for any markdown document with 3 or more top-level sections
- List only top-level sections — do not nest subsections in the TOC
- Place an anchor `<a id="table-of-contents"></a>` directly above the TOC heading
- Each TOC entry links to its section: `[Section Title](#section-slug)`

## Section Headings

- Every `##` section heading links back to the TOC: `## [Section Title](#table-of-contents)`
- This creates bidirectional navigation — TOC → section and section → TOC

## Source References

### Inline citations

- Use numbered references in the format `[[N]](#source-N)` where the text appears
- The link target `#source-N` points to the corresponding entry in the Sources section
- Place the citation immediately after the claim it supports, before any punctuation

### Sources section

- Title the section `## [Sources](#table-of-contents)` (links back to TOC like all other sections)
- Each entry has three parts separated by line breaks:
  1. An anchor: `<a id="source-N"></a>`
  2. The numbered link: `**[N]** [Title — domain](url)`
  3. A one-line description on a new line forced by `<br>`

Example entry:

```markdown
<a id="source-1"></a>
**[1]** [Article Title — example.com](https://example.com/article)
<br>One-sentence description of what this source covers.
```

## When to Apply

- Technical documents, primers, handover docs, and any reference material with external sources
- Not required for short docs like changelogs, READMEs, or steering files themselves
