# Vulcan Book Writing Style Guide

**Inspired by Bento's documentation style: fluid, personal, direct, factual, engaging**

---

## Core Principles

### 1. **Fluid and Personal**
Write like you're talking to a colleague. Be direct, engaging, and human.

**DO:**
- "Vulcan is a complete stack for building data products."
- "You can test transformations locally without touching your warehouse."
- "Ready to ship data products like software?"

**DON'T:**
- "Vulcan enables organizations to leverage comprehensive data product capabilities."
- "Users may utilize the local testing functionality."
- "Are you prepared to revolutionize your data product development workflow?"

### 2. **Direct and Factual**
State what things are and what they do. No marketing fluff.

**DO:**
- "Vulcan has assertions built in. Bad data gets blocked before it hits production."
- "Define metrics and dimensions. Vulcan generates the APIs automatically."
- "It does CI/CD for data transformations."

**DON'T:**
- "Vulcan empowers teams with comprehensive data quality management capabilities."
- "Our platform facilitates seamless API generation through intelligent automation."
- "It provides enterprise-grade CI/CD solutions for modern data workflows."

### 3. **Conversational but Professional**
Engage the reader with questions and direct address. Stay professional.

**DO:**
- "Tired of stitching together tools?"
- "You write SQL or Python. Vulcan handles the rest."
- "It's simple to deploy, comes with testing built in, and works with your existing infrastructure."

**DON'T:**
- "Are you experiencing challenges with tool fragmentation?"
- "Users may leverage SQL or Python capabilities."
- "The solution offers simplified deployment, integrated testing, and seamless infrastructure compatibility."

---

## Voice and Tone

### Voice: Second Person ("You")
Address the reader directly. Make it personal.

**Examples:**
- "You write transformations in SQL or Python."
- "Test your models locally before deploying."
- "Define your metrics once. Vulcan generates everything else."

### Tone: Confident, Helpful, Matter-of-Fact

**Confident:**
- "Vulcan does X" not "Vulcan can do X"
- "It works" not "It may work"
- "You get Y" not "You might get Y"

**Helpful:**
- Explain what things do clearly
- Show, don't just tell
- Provide context when needed

**Matter-of-Fact:**
- List capabilities directly
- No exaggeration
- Technical accuracy over marketing

---

## Language Guidelines

### Use Active Voice
**DO:** "Vulcan processes data"  
**DON'T:** "Data is processed by Vulcan"

### Use Present Tense
**DO:** "Vulcan generates APIs automatically"  
**DON'T:** "Vulcan will generate APIs automatically"

### Use Simple, Direct Language
**DO:** "Test locally"  
**DON'T:** "Execute local testing procedures"

**DO:** "Block bad data"  
**DON'T:** "Implement data quality validation mechanisms"

### Avoid Marketing Language
**DON'T USE:**
- "Enable", "Empower", "Leverage", "Facilitate"
- "Revolutionary", "Cutting-edge", "Enterprise-grade"
- "Seamless", "Effortless", "Intuitive" (unless truly accurate)
- "Comprehensive", "Robust", "Scalable" (without specifics)

**USE INSTEAD:**
- "Does", "Has", "Provides", "Gives you"
- Specific facts: "Handles 1M rows", "Runs in 5 seconds"
- Direct statements: "Works with X", "Integrates with Y"

### Be Specific, Not Vague
**DO:** "Test transformations locally without warehouse costs"  
**DON'T:** "Test transformations efficiently"

**DO:** "Generate REST, Python, and Graph APIs automatically"  
**DON'T:** "Generate various APIs automatically"

---

## Structure Guidelines

### Opening Hooks
Start with something engaging and direct.

**Examples:**
- "Vulcan is a complete stack for building data products."
- "Ready to ship data products like software?"
- "Tired of stitching together tools for data quality, testing, and APIs?"

### Matter-of-Fact Lists
When listing features or capabilities, be direct and factual.

**DO:**
```markdown
Vulcan gives you:

- **CI/CD for data** - Plan changes, test in virtual environments, deploy safely
- **Unit testing** - Test transformations locally without touching your warehouse
- **Data quality** - Assertions that block bad data, checks that monitor quality
```

**DON'T:**
```markdown
Vulcan provides comprehensive capabilities:

- **Enterprise CI/CD Solutions** - Enables seamless planning and deployment workflows
- **Advanced Testing Framework** - Facilitates local testing capabilities
- **Robust Data Quality Management** - Empowers teams with validation mechanisms
```

### Conversational Bridges
Use questions and statements to transition between sections.

**Examples:**
- "Ready to get started?"
- "Here's how it works:"
- "The complete stack includes:"

### Technical Accuracy
Be precise about what things do. No exaggeration.

**DO:** "Vulcan generates REST APIs from your semantic layer definitions."  
**DON'T:** "Vulcan automatically generates comprehensive REST APIs with full OpenAPI documentation."

(Unless it actually does generate full OpenAPI docs - then say that specifically)

---

## Content Organization

### Start with What, Then How
1. **What it is** - Direct statement
2. **What it does** - Matter-of-fact list
3. **How it works** - Technical details
4. **How to use it** - Practical examples

### Progressive Disclosure
- Start simple
- Build complexity gradually
- Each section stands alone
- Cross-reference when needed

### Examples First
Show before you explain. Code examples should be:
- Copy-paste ready
- Realistic (not toy examples)
- Well-commented when needed
- Complete enough to work

---

## Formatting Guidelines

### Headings
Use clear, descriptive headings. Prefer questions or statements.

**DO:**
- "What is Vulcan?"
- "How It Works"
- "Getting Started"

**DON'T:**
- "Introduction to Vulcan"
- "Overview of Functionality"
- "Initial Setup Procedures"

### Lists
Use bullet points for features, capabilities, steps. Be direct.

**Format:**
```markdown
- **Feature name** - What it does (brief explanation)
```

### Code Blocks
Always include context. Explain what the code does.

**DO:**
```markdown
Define a metric in your semantic layer:

```yaml
metrics:
  - name: total_revenue
    type: sum
    expression: amount
```
```

**DON'T:**
```markdown
```yaml
metrics:
  - name: total_revenue
```
```

### Emphasis
Use **bold** for important terms, features, or concepts. Use *italics* sparingly.

---

## Specific Style Rules

### No Dependency Mentions
Don't mention underlying technologies unless necessary.

**DON'T:** "Vulcan is built on SQLMesh"  
**DO:** "Vulcan is a complete stack for building data products"

**DON'T:** "Uses Soda for quality checks"  
**DO:** "Has assertions and checks built in"

### Use "Stack" Not "Platform"
**DO:** "Complete stack", "Data product stack", "Full stack"  
**DON'T:** "Platform", "Solution", "Framework" (unless specifically accurate)

### Direct Statements Over Descriptions
**DO:** "Vulcan does X"  
**DON'T:** "Vulcan is a tool that enables X"

**DO:** "It has Y built in"  
**DON'T:** "It provides Y capabilities"

### Questions for Engagement
Use questions to engage readers, but keep them genuine.

**DO:**
- "Ready to get started?"
- "Tired of manual testing?"
- "Want to see how it works?"

**DON'T:**
- "Are you ready to revolutionize your data workflow?" (too marketing-y)
- "Have you ever wondered about data quality?" (too vague)

---

## Examples: Good vs. Bad

### Example 1: Introduction

**BAD:**
> Vulcan is a comprehensive, enterprise-grade platform that empowers data teams to build, deploy, and manage data products with unprecedented efficiency. Our revolutionary solution seamlessly integrates cutting-edge technologies to facilitate end-to-end data lifecycle management.

**GOOD:**
> Vulcan is a complete stack for building data products. It does CI/CD for data transformations, has testing and quality built in, and generates APIs automatically. Ready to ship data products like software?

### Example 2: Feature List

**BAD:**
> Vulcan provides comprehensive capabilities including:
> - Advanced CI/CD solutions that enable seamless deployment workflows
> - Robust testing frameworks that facilitate local development
> - Enterprise-grade data quality management with intelligent validation

**GOOD:**
> Vulcan gives you:
> - **CI/CD for data** - Plan changes, test in virtual environments, deploy safely
> - **Unit testing** - Test transformations locally without touching your warehouse
> - **Data quality** - Assertions that block bad data, checks that monitor quality

### Example 3: Technical Explanation

**BAD:**
> The system facilitates the generation of comprehensive REST APIs through intelligent analysis of semantic layer definitions, enabling seamless integration with various downstream systems and applications.

**GOOD:**
> Define metrics and dimensions in your semantic layer. Vulcan generates REST, Python, and Graph APIs automatically. No manual API code needed.

---

## Checklist for Writers

Before publishing, ask:

- [ ] Is this written in second person ("you")?
- [ ] Are statements direct and factual?
- [ ] Is there any marketing language I can remove?
- [ ] Are examples copy-paste ready?
- [ ] Does this sound like I'm talking to a colleague?
- [ ] Are technical details accurate and specific?
- [ ] Have I avoided mentioning dependencies?
- [ ] Is the tone confident but not arrogant?
- [ ] Are questions genuine and engaging?
- [ ] Does it flow naturally?

---

## Inspiration

This style guide is inspired by [Bento's documentation](https://warpstreamlabs.github.io/bento/docs/about), which demonstrates:
- Personal, direct address
- Matter-of-fact feature lists
- Conversational but professional tone
- Technical accuracy without marketing fluff
- Engaging questions and hooks

**Study Bento's docs for examples of this style in practice.**

---

## Questions?

When in doubt:
1. Be direct
2. Be factual
3. Be personal
4. Be helpful

Write like you're explaining to a colleague, not selling to a customer.

