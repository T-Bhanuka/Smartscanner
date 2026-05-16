# first_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


The app has signs of AI-generated / partially integrated logic:
GeminiService exists but is unused.
_processReceipt saves to Firestore only, but UI loads receipts from local storage (StorageService), so data flow is inconsistent.
GalleryImage model + save API exist, but no actual gallery image save path is wired in main.dart.
test/widget_test.dart is still the default counter test and does not match this app.
README is still Flutter template (“first_project”), so docs don’t reflect actual Smartscanner functionality.


# Documentation 
Here is the breakdown of the core differences between Ask and Plan modes in GitHub Copilot, followed by a structured strategy to optimize your vibe coding workflow.

### The Core Difference: Ask vs. Plan

* **Ask Mode (Chat):** This is your sparring partner and code reviewer. It explains existing code, reviews logic, and suggests high-level architectural approaches. **Crucially, Ask mode does not modify your files.** Use this when you need to understand *why* something works or want to brainstorm a structure.
* **Plan Mode (Agentic Planning):** This is your lead architect and executor. It analyzes your entire workspace, breaks a complex goal into a step-by-step implementation plan, and can autonomously edit multiple files, run terminal commands, and self-correct. Use this when you are ready to build a feature end-to-end.

---

### Step-by-Step: Maximizing Vibe Coding Efficiency

Vibe coding relies on you functioning as the director while the AI acts as the production crew. To stop the AI from generating inefficient "slop" code, you must enforce structure.

**Step 1: Front-Load the Architecture (The "Plan First" Rule)**
Never ask the AI to simply "build a feature." Always force it to think through the architecture first.

* Prompt the Plan agent with: *"Outline the logic, file structure, and potential breaking points for [Feature]. Do not write the code yet."*
* Review, refine the plan, and only authorize code generation once the blueprint is solid.

**Step 2: Establish Universal Constraints**
Your AI needs a strict code of conduct to prevent it from guessing your preferences.

* Create a `.github/copilot-instructions.md` file in your repository root.
* Define your exact tech stack, naming conventions, testing requirements (e.g., "Use TDD"), and a strict "never do this" list. The AI will automatically pull this context into every session.

**Step 3: Optimize Contextual Targeting**
Vibe coding fails when the AI lacks context. Manually point it to exactly what it needs to see.

* Use `#file` or `#selection` to lock the AI's focus on relevant code blocks.
* Use `#terminalLastCommand` to feed error logs directly into the chat for immediate debugging.

**Step 4: Verify Before Coding**
Stop the AI from writing perfect code for a database or API that does not exist.

* Mandate a "Verify-then-Code" workflow. Instruct the agent to run terminal commands to inspect your current database schema or API endpoints *before* it begins writing the integration logic.

---

### Key Takeaways & Action Items

* **Ask = Understand.** Use it to review and brainstorm.
* **Plan = Execute.** Use it for multi-file, agent-driven feature building.
* **Action Item 1:** Create your `.github/copilot-instructions.md` file today to define your baseline project rules.
* **Action Item 2:** For your next feature, force Copilot to output a step-by-step architectural plan before allowing it to write any code.

Remember to schedule a check-in to reflect and review progress against these steps weekly. Which project are you planning to apply this workflow to first?