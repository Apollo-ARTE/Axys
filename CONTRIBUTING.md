# Contributing to Axys

Thank you for your interest in contributing to **Axys**, the VisionOS companion to (RhinoPlugin)[https://github.com/Apollo-ARTE/Axys-RhinoPlugin]!
We welcome feature requests, bug reports, and contributions to enhance the AR experience.

---

## Getting Started

### Fork the repository  
If you don’t have write access, please fork first. Otherwise, branch directly.

### Create a branch  
```bash
git checkout -b feature/your-feature-name
```

---

## Branch Naming

We follow a **feature-branch-based workflow**, where each feature, bugfix, or task is developed in its own branch.

Please use **clear and consistent branch names** based on the purpose of the branch. The following prefixes help us keep the repository organized:

| Type        | Prefix     | Example                       |
|-------------|------------|-------------------------------|
| Feature     | `feat/`    | `feat/interactive-panel`      |
| UI Update   | `ui/`      | `ui/navigation-bar-style`     |
| Bug Fix     | `bugfix/`  | `bugfix/export-crash`         |
| Chore       | `chore/`   | `chore/update-dependencies`   |
| Docs        | `docs/`    | `docs/update-readme`          |
| Test Branch | `test/`    | `test/sandbox-ui-tests`       |
| Junk        | `junk/`    | `junk/prototype-camera`       |

> ⚠️ Branches with the `junk/` prefix are intended for **throwaway work** and should **never be merged**.

The `main` branch always reflects **stable, production-ready** code.

---

## Making a Pull Request

When your implementation is ready:

1. Push your branch:
   ```bash
   git push origin feature/your-feature-name
   ```
2. Open a Pull Request (PR) on GitHub.
3. In the PR description, include:
   - What you changed
   - Why you did it
   - How to test on Vision Pro

Draft PRs are encouraged for early feedback.

---

## Code Review Process

PRs will be reviewed by maintainers.  
Please be open to feedback and iterative improvement.

### Best Practices
- Maintain respectful dialogue
- Give context (“see line X…”)
- Explain suggestions constructively
- Tag small style fixes with `(nitpick)`
- Keep commits focused and meaningful

### Reviewer Checklist
(Optional to copy into PR):

```
## Review Checklist

- [ ] Feature addresses the stated goal
- [ ] Code is well-structured and idiomatic Swift
- [ ] AR/visionOS flows tested on device
- [ ] Edge cases are considered
- [ ] Tests added or existing ones updated
- [ ] Commit messages are clear
- [ ] README or docs updated if needed
```

---

## Reporting Issues

Please include in bug reports:
- Device (Vision Pro) and visionOS version
- Steps to reproduce
- Error messages or logs
- Screenshots, if helpful

Check existing issues before submitting a new one.

---

## Credits

This project is developed and maintained by:

- The [Apollo ARTE](https://github.com/Apollo-ARTE) team
- [Salvatore Flauto](https://github.com/XlSolver)

We thank all contributors who help improve this project through their code, feedback, and ideas.
