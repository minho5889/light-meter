# GitHub 101 — Light Meter Project

This guide covers everything you need to work on the Light Meter iOS project using Git and GitHub. Follow each section in order.

## Prerequisites

Before starting, make sure you have:
- A GitHub account (sign up at https://github.com)
- Git installed on your Mac (open Terminal and type `git --version` — if it's not installed, macOS will prompt you to install it)
- A code editor (Kiro, VS Code, or Xcode)

## 1. Configure Git (One-Time Setup)

Open Terminal and set your name and email. These show up on your commits.

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

## 2. Clone the Repository

Cloning downloads the project from GitHub to your computer.

```bash
cd ~/Desktop
git clone https://github.com/minho5889/light-meter.git
cd light-meter
```

You now have the full project on your machine.

## 3. Create a Branch

Never work directly on `main`. Always create a branch for your changes.

```bash
git checkout -b your-branch-name
```

Use a descriptive name like `add-settings-view` or `fix-lux-label`. Keep it lowercase with hyphens.

## 4. Make Your Changes

Edit files in the project using your code editor. Save your work as you go.

## 5. Check What Changed

Before committing, see what files you modified:

```bash
git status
```

This shows files that are modified (red) or staged (green). To see the actual code changes:

```bash
git diff
```

## 6. Stage Your Changes

Staging tells Git which changes you want to include in your next commit.

To stage everything:

```bash
git add -A
```

To stage a specific file:

```bash
git add LightMeter/SomeFile.swift
```

## 7. Commit Your Changes

A commit is a snapshot of your work with a message describing what you did.

```bash
git commit -m "short description of what you changed"
```

This project follows a specific commit format. For work tied to a spec task:

```
[S01_T01_feat]: add lux calculator with formula implementation
```

For work outside of spec tasks:

```
[NT_chore]: update gitignore for derived data
```

Ask your teammate if you're unsure which format to use.

## 8. Push Your Branch to GitHub

Pushing uploads your branch and commits to GitHub so others can see them.

```bash
git push origin your-branch-name
```

The first time you push a new branch, Git will create it on GitHub automatically.

## 9. Create a Pull Request (PR)

A pull request is how you propose your changes to be merged into `main`.

1. Go to https://github.com/minho5889/light-meter
2. You'll see a banner saying your branch was recently pushed — click "Compare & pull request"
3. Add a title and description explaining what you changed and why
4. Click "Create pull request"

Your teammate will review the PR before it gets merged.

## 10. Pull Latest Changes

Before starting new work, always pull the latest changes from `main`:

```bash
git checkout main
git pull origin main
```

Then create a new branch from the updated `main` for your next task.

## Common Commands Reference

| Command | What It Does |
|---------|-------------|
| `git status` | Shows modified and staged files |
| `git diff` | Shows code changes line by line |
| `git add -A` | Stages all changes |
| `git commit -m "message"` | Saves a snapshot with a message |
| `git push origin branch-name` | Uploads your branch to GitHub |
| `git pull origin main` | Downloads latest changes from main |
| `git checkout -b branch-name` | Creates and switches to a new branch |
| `git checkout main` | Switches back to the main branch |
| `git log --oneline` | Shows recent commit history |

## Review Checklist

Go through this list to confirm you understand the basics:

- [ ] I have Git installed and configured with my name and email
- [ ] I cloned the light-meter repository to my computer
- [ ] I understand that I should never commit directly to `main`
- [ ] I know how to create a new branch with `git checkout -b`
- [ ] I can check what files changed with `git status` and `git diff`
- [ ] I know how to stage changes with `git add`
- [ ] I know how to commit with a message using `git commit -m`
- [ ] I know how to push my branch with `git push origin branch-name`
- [ ] I know how to create a Pull Request on GitHub
- [ ] I know to pull latest changes from `main` before starting new work
