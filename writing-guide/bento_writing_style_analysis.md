# Bento Documentation Writing Style Analysis

## Overview
This document analyzes the writing style and patterns used in Bento's documentation to help maintain consistency when writing similar technical documentation.

## Tone & Voice

### Conversational and Friendly
- Uses a casual, approachable tone
- Employs contractions: "it's", "you're", "don't", "can't"
- Second person perspective ("you", "your")
- Occasionally playful or humorous language

**Examples:**
- "cool!" 
- "how whacky!"
- "Resist the temptation to play with this for hours"
- "I don't know about you but I'm going to need to lie down for a while"
- "How exciting!"

### Direct and Clear
- Gets straight to the point
- Explains concepts clearly without unnecessary jargon
- Uses simple, direct language even for complex topics

## Structure & Organization

### Document Frontmatter
All documentation files use YAML frontmatter:
```yaml
---
title: Component Name
sidebar_label: Label
description: Brief description
---
```

### Section Organization
1. **Brief introduction** - What the component/feature does
2. **Configuration examples** - Common and advanced tabs
3. **Detailed explanations** - How it works, use cases
4. **Field documentation** - Each config field explained
5. **Examples** - Practical use cases
6. **Troubleshooting** - Common issues and solutions

### Progressive Disclosure
- Starts with simple examples
- Builds up to more complex use cases
- Uses tabs to separate "Common" vs "Advanced" configurations

## Code Examples

### Extensive Use of Examples
- Every concept is demonstrated with code
- Shows input/output pairs when relevant
- Includes comments in code examples
- Uses realistic, practical scenarios

**Example Pattern:**
```yaml
# Comment explaining what this does
input:
  kafka:
    addresses: [ localhost:9092 ]
    topics: [ foo, bar ]

# In:  {"id":"wat1","message":"hello world"}
# Out: {"id":"wat1","message":"hello world","foo":"added value"}
```

### Configuration Examples
- Shows default values clearly
- Uses `# No default (required)` or `# No default (optional)` comments
- Provides multiple examples for complex fields
- Uses realistic placeholder values (TODO, localhost, etc.)

## Language Patterns

### Explanatory Style
- Explains "why" not just "what"
- Provides context for decisions
- Acknowledges limitations or trade-offs

**Example:**
> "Delivery guarantees can be a dodgy subject. Bento processes and acknowledges messages using an in-process transaction model with no need for any disk persisted state..."

### Direct Address
- Speaks directly to the reader
- Uses imperative mood for instructions
- Asks rhetorical questions occasionally

**Examples:**
- "You can add as many processing steps as you like"
- "Why? That's a good question."
- "Try running that config with some sample documents"

### Technical Precision
- Uses precise technical terminology
- Explains technical concepts clearly
- Provides links to related documentation
- Uses warnings/cautions for important information

## Documentation Features

### Cross-References
- Extensive use of internal links
- Links to related components/guides
- References to external resources when relevant

### Warnings and Cautions
- Uses `:::warning` blocks for security-sensitive fields
- Uses `:::caution` blocks for important limitations
- Clearly marks experimental features

### Troubleshooting Sections
- Addresses common issues directly
- Provides solutions or workarounds
- Explains error messages

**Example:**
> "I'm seeing logs that report `Failed to connect to kafka...` but the brokers are definitely reachable.
> 
> Unfortunately this error message will appear for a wide range of connection problems..."

## Writing Patterns

### Opening Sentences
- Start with what the component does
- Use active voice
- Be specific and concrete

**Examples:**
- "Connects to Kafka brokers and consumes one or more topics."
- "Prints a log event for each message."
- "Bento pipelines are configured in a YAML file..."

### Field Documentation
Each field follows this pattern:
1. **Name** - Brief description
2. **Type** - Data type
3. **Default** - Default value (if any)
4. **Examples** - Code examples showing usage
5. **Additional notes** - Special considerations, warnings, etc.

### Transitional Phrases
- "For more information..."
- "You can find..."
- "Check out..."
- "It's worth noting..."
- "However..."

## Key Characteristics Summary

1. **Accessible** - Technical but approachable, avoids unnecessary complexity
2. **Practical** - Focuses on real-world usage with concrete examples
3. **Conversational** - Friendly tone that doesn't feel overly formal
4. **Comprehensive** - Covers both simple and advanced use cases
5. **Helpful** - Anticipates questions and provides troubleshooting
6. **Progressive** - Builds from simple to complex concepts
7. **Well-organized** - Clear structure with good navigation
8. **Example-driven** - Code examples are central to understanding

## Best Practices to Emulate

1. **Start simple** - Begin with the most basic use case
2. **Show, don't just tell** - Always include code examples
3. **Explain the why** - Provide context for design decisions
4. **Be conversational** - Write like you're explaining to a colleague
5. **Use examples liberally** - Multiple examples for different scenarios
6. **Anticipate questions** - Include troubleshooting and common issues
7. **Link extensively** - Connect related concepts and components
8. **Mark important info** - Use warnings and cautions appropriately
9. **Progressive disclosure** - Use tabs or sections for simple vs advanced
10. **Be precise** - Use accurate technical terminology

## Example Template

```markdown
---
title: Component Name
description: Brief one-line description
---

Brief paragraph explaining what this component does and when you'd use it.

<Tabs>
<TabItem value="common">
```yaml
# Simple example
```

</TabItem>
<TabItem value="advanced">
```yaml
# Full example with all options
```

</TabItem>
</Tabs>

### How It Works

Explanation of the mechanism, with examples.

### Use Cases

When and why you'd use this component.

## Fields

### `field_name`

Description of what this field does.

**Type:** `string`  
**Default:** `"default"`

```yaml
# Examples
field_name: value1
field_name: value2
```

### Troubleshooting

Common issues and solutions.

[Links to related docs]
```

