# Assignment 5 – Source Code Management Using Git and GitHub

**Course:** Software Engineering Principles and Practices (SEP)  
**Project:** Digital Mess Management Platform  
**Technology Stack:** Flutter (Dart), Firebase  
**Date:** March 2026  

---

## Table of Contents

1. [Introduction](#introduction)
2. [Current Repository State](#current-repository-state)
3. [Proposed Git Repository Structure](#proposed-git-repository-structure)
4. [Professional Branch Hierarchy (Git Flow)](#professional-branch-hierarchy)
5. [Git Commands – Step by Step](#git-commands-step-by-step)
6. [Repository Directory Structure](#repository-directory-structure)
7. [Commit History Example](#commit-history-example)
8. [Branching Diagram](#branching-diagram)
9. [Workflow Analysis](#workflow-analysis)
10. [Comparison of Git Workflows](#comparison-of-git-workflows)
11. [Transition Plan: From Name-Based to Feature-Based Branches](#transition-plan)
12. [Conclusion / Inference](#conclusion--inference)

---

## 1. Introduction

Version control is a fundamental practice in modern software engineering. It enables teams to track changes, collaborate without conflict, and maintain a stable history of the project's evolution. In this assignment, we explore Git and GitHub as version control tools applied to our project — the **Digital Mess Management Platform**.

The Digital Mess Management Platform is a Flutter-based mobile application with Firebase backend, designed to digitize mess operations for a college environment. The system manages student meal bookings, complaints, menu updates, billing, feedback, and administrative workflows. Given the multi-module nature of the project, effective source code management is essential.

This document covers the setup of a professional Git workflow, branching strategies, step-by-step Git operations, and a workflow analysis based on the real development history of our GitHub repository.

---

## 2. Current Repository State

### 2.1 Existing Repository (Actual)

The GitHub repository was initialized with an **Initial Commit** containing the base Flutter project. Development proceeded through collaborator branches named after team members.

**Observed Branch Structure (Actual):**

```
remotes/origin/main       ← Production branch
remotes/origin/vishnu     ← Team member branch (Vishnu Vineeth)
remotes/origin/danush     ← Team member branch (Danush)
```

**Actual Commit Log (extracted via `git log --oneline --all --graph`):**

```
*   b4a6a49  WIP on main: bea9f63 Initial commit - SEP project
|
| * 96f1a22  changed the login ui
| * b70747c  securing the api keys
| *   63e7621  Merge pull request #2 from VishnuVineeth14/vishnu
| |\
| | * e5ec135  added mess cancellation and medical certificate pdf upload and view
| | * 13db05f  Implemented food issue reporting feature and updates
| | * f6cae43  Updated Firebase keys after rotation
| | * 6b4b3e3  Added menu uploader + Firebase menu structure
| | * f293217  Database integrated
| | * bc9f4a4  Initial commit on branch vishnu
| |/
| * 3a7daa3  ger
| * 5e41224  Merge pull request #1 from SBK-07/vishnu
|/|
| * 672fd10  Add files via upload
|/
* bea9f63  Initial commit - SEP project
```

**Observation:** The current workflow uses **personal-name branches**, which is a common starting point for student projects but lacks the structure required for maintainable, scalable development. The following sections propose and document a professional alternative.

---

## 3. Proposed Git Repository Structure

### 3.1 Recommended Platform: GitHub

| Property | Value |
|---|---|
| Repository Name | `mess-management-platform` |
| Visibility | Private (with collaborators) |
| Default Branch | `main` |
| Version Tag Format | `v1.0.0`, `v1.1.0` |
| Collaborators | Team members added via Settings → Collaborators |

### 3.2 Branch Purpose Summary

| Branch | Purpose | Merge Target |
|---|---|---|
| `main` | Stable, production-ready code | — |
| `develop` | Integration of all completed features | `main` |
| `feature/user-management` | User registration, login, roles | `develop` |
| `feature/menu-management` | Menu CRUD, weekly upload | `develop` |
| `feature/feedback-processing` | Feedback forms, analytics | `develop` |
| `feature/replacement-management` | Meal replacement requests | `develop` |
| `feature/leave-wastage` | Leave/cancellation, wastage tracking | `develop` |
| `feature/billing-management` | Billing computation, PDF export | `develop` |
| `feature/analytics-reporting` | Admin dashboards, reports | `develop` |
| `hotfix/critical-bug` | Emergency fix on production | `main` + `develop` |
| `release/v1.0` | Pre-release stabilization | `main` |
| `docs/srs` | SRS and documentation files | `develop` |
| `docs/dfd-diagrams` | DFD Level 0, 1, 2 diagrams | `develop` |

---

## 4. Professional Branch Hierarchy (Git Flow)

Git Flow is a branching model introduced by Vincent Driessen. It defines a strict branching structure around project releases and is well-suited for projects with a defined release cycle.

### 4.1 Git Flow Structure

```
main
 └── release/v1.0       (stabilization before merge to main)
       └── develop
             ├── feature/user-management
             ├── feature/menu-management
             ├── feature/feedback-processing
             ├── feature/replacement-management
             ├── feature/leave-wastage
             ├── feature/billing-management
             ├── feature/analytics-reporting
             ├── docs/srs
             └── docs/dfd-diagrams

main ← hotfix/critical-bug (emergency production fix)
```

### 4.2 Feature Branch Mapping to System Modules

| System Module | Assigned Branch | Team Member |
|---|---|---|
| User Management | `feature/user-management` | All |
| Menu Management | `feature/menu-management` | Vishnu |
| Feedback Processing | `feature/feedback-processing` | Danush |
| Replacement Management | `feature/replacement-management` | Vishnu |
| Leave & Wastage Management | `feature/leave-wastage` | Danush |
| Billing Management | `feature/billing-management` | All |
| Analytics & Reporting | `feature/analytics-reporting` | All |

---

## 5. Git Commands – Step by Step

### 5.1 Initial Setup

```bash
# Configure Git identity (one-time setup)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify configuration
git config --list
```

---

### 5.2 Clone the Repository

```bash
# Clone the existing GitHub repository to local machine
git clone https://github.com/<username>/mess-management-platform.git

# Navigate into the project directory
cd mess-management-platform

# Verify remote origin
git remote -v
```

---

### 5.3 Create the `develop` Branch

```bash
# Ensure you are on main and it is up to date
git checkout main
git pull origin main

# Create and switch to develop branch
git checkout -b develop

# Push develop branch to GitHub
git push -u origin develop
```

---

### 5.4 Create Feature Branches

```bash
# Always branch off from develop
git checkout develop
git pull origin develop

# Create feature branch for User Management
git checkout -b feature/user-management

# Create feature branch for Menu Management
git checkout -b feature/menu-management

# Create feature branch for Feedback Processing
git checkout -b feature/feedback-processing

# Create feature branch for Replacement Management
git checkout -b feature/replacement-management

# Create feature branch for Leave & Wastage
git checkout -b feature/leave-wastage

# Create feature branch for Billing Management
git checkout -b feature/billing-management

# Create documentation branch for SRS
git checkout -b docs/srs

# Create documentation branch for DFD diagrams
git checkout -b docs/dfd-diagrams
```

---

### 5.5 Make Changes and Commit

```bash
# Stage specific files
git add lib/screens/login_screen.dart
git add lib/screens/signup_screen.dart

# Stage all modified files
git add .

# Commit with a descriptive message (conventional commits format)
git commit -m "feat(user-management): implement login and signup screens"

# Additional commit examples:
git commit -m "feat(menu): add weekly menu uploader with Firebase integration"
git commit -m "fix(auth): secure Firebase API keys using environment variables"
git commit -m "docs(srs): add SRS v1.0 document"
git commit -m "feat(cancellation): implement mess cancellation with date picker"
```

---

### 5.6 Push Feature Branch to GitHub

```bash
# Push the current feature branch to remote
git push -u origin feature/user-management

# For subsequent pushes on the same branch
git push origin feature/user-management
```

---

### 5.7 Merge Feature Branch into `develop`

```bash
# Method A: Via GitHub Pull Request (Recommended)
# 1. Push feature branch to GitHub
# 2. Open GitHub → Pull Requests → New Pull Request
# 3. Set base: develop, compare: feature/user-management
# 4. Add description, assign reviewers
# 5. Merge after approval

# Method B: Via Command Line
git checkout develop
git pull origin develop
git merge --no-ff feature/user-management
git push origin develop

# Delete the feature branch after successful merge
git branch -d feature/user-management
git push origin --delete feature/user-management
```

---

### 5.8 Merge `develop` into `main` (Release)

```bash
# Create a release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/v1.0

# Final testing and bug fixes on release branch
# After verification:
git checkout main
git merge --no-ff release/v1.0
git tag -a v1.0.0 -m "Release version 1.0.0 - Digital Mess Management Platform"
git push origin main
git push origin --tags

# Merge release fixes back into develop
git checkout develop
git merge --no-ff release/v1.0
git push origin develop

# Delete the release branch
git branch -d release/v1.0
git push origin --delete release/v1.0
```

---

### 5.9 Resolving Merge Conflicts

Merge conflicts occur when two branches modify the same lines in a file.

```bash
# Start the merge (conflict will be flagged)
git checkout develop
git merge feature/menu-management

# Git outputs:
# CONFLICT (content): Merge conflict in lib/screens/menu_screen.dart
# Automatic merge failed; fix conflicts and then commit the result.

# Open the conflicting file — it will contain conflict markers:
# <<<<<<< HEAD
#   Widget build(Context) { /* develop version */ }
# =======
#   Widget build(Context) { /* feature/menu-management version */ }
# >>>>>>> feature/menu-management

# Edit the file to keep the correct (or combined) version
# Remove all conflict markers (<<<<<<<, =======, >>>>>>>)

# Stage the resolved file
git add lib/screens/menu_screen.dart

# Complete the merge
git commit -m "merge: resolve conflict in menu_screen between develop and feature/menu-management"

# Push the resolved merge
git push origin develop
```

**Conflict Prevention Tips:**
- Always `git pull origin develop` before starting new work.
- Keep feature branches short-lived (merge frequently).
- Assign different modules to different team members to avoid overlap.

---

### 5.10 Hotfix Workflow

```bash
# Branch off main for emergency fix
git checkout main
git pull origin main
git checkout -b hotfix/fix-login-crash

# Apply the fix
git add lib/screens/login_screen.dart
git commit -m "hotfix: fix null pointer crash on login screen"

# Merge into main
git checkout main
git merge --no-ff hotfix/fix-login-crash
git tag -a v1.0.1 -m "Hotfix v1.0.1 - login crash fix"
git push origin main
git push origin --tags

# Also merge into develop to keep it in sync
git checkout develop
git merge --no-ff hotfix/fix-login-crash
git push origin develop

git branch -d hotfix/fix-login-crash
```

---

### 5.11 Useful Status and Inspection Commands

```bash
# Check current branch and file status
git status

# View commit history (one line per commit)
git log --oneline --all --graph

# View all local and remote branches
git branch -a

# View difference between working tree and last commit
git diff

# View difference between two branches
git diff develop feature/user-management

# Check remote repositories
git remote -v

# Fetch all remote changes without merging
git fetch --all

# Stash uncommitted changes temporarily
git stash
git stash pop
```

---

## 6. Repository Directory Structure

The following structure is recommended for the Digital Mess Management Platform repository:

```
mess-management-platform/
│
├── README.md                          ← Project overview, setup instructions
├── .gitignore                         ← Flutter/Dart/Firebase ignores
├── pubspec.yaml                       ← Flutter dependencies
├── analysis_options.yaml              ← Dart lint rules
│
├── docs/                              ← All documentation
│   ├── Assignment1_Problem_Identification.md
│   ├── Assignment2_SRS.md
│   ├── Assignment3_DFD.md
│   ├── Assignment4_Architecture.md
│   ├── Assignment5_Git_VersionControl.md    ← This document
│   └── diagrams/
│       ├── DFD_Level0.png
│       ├── DFD_Level1.png
│       ├── DFD_Level2.png
│       ├── Architecture_Layered.png
│       └── Git_BranchingDiagram.png
│
├── lib/                               ← Flutter source code (main)
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── models/                        ← Data models
│   │   ├── user.dart
│   │   ├── menu_item.dart
│   │   ├── meal_type.dart
│   │   ├── food_report.dart
│   │   ├── complaint.dart
│   │   ├── cancellation.dart
│   │   ├── replacement.dart
│   │   ├── notification.dart
│   │   └── week_day.dart
│   ├── screens/                       ← UI screens per module
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── home_screen.dart
│   │   ├── admin_dashboard.dart
│   │   ├── menu_screen.dart
│   │   ├── overall_menu_screen.dart
│   │   ├── feedback_screen.dart
│   │   ├── food_report_screen.dart
│   │   ├── mess_cancellation_screen.dart
│   │   ├── replacement_screen.dart
│   │   ├── staff_home_screen.dart
│   │   └── staff_today_menu_screen.dart
│   ├── services/                      ← Firebase and API services
│   ├── providers/                     ← State management (Provider)
│   ├── repositories/                  ← Data access layer
│   ├── widgets/                       ← Reusable UI components
│   └── utils/                         ← Helper functions and constants
│
├── assets/
│   └── images/                        ← App images and icons
│
├── android/                           ← Android platform code
├── ios/                               ← iOS platform code
├── web/                               ← Web platform code
└── test/                              ← Widget and unit tests
    └── widget_test.dart
```

---

## 7. Commit History Example

The following represents an ideal incremental commit history mapped to project phases:

```
*  v1.0.0 tag                          ← Production Release
|
*  a9f23c1  release(v1.0): merge release/v1.0 into main
|
*  f82a3d4  release(v1.0): final UI polish and bug fixes
|
*  e7c91b2  feat(analytics): admin dashboard with meal statistics
|
*  d6a04f5  feat(billing): meal billing calculation and PDF export
|
*  c5b38e1  feat(leave): mess leave cancellation with date validation
|
*  b4e27a3  feat(replacement): meal replacement request screen
|
*  a3d16f9  feat(feedback): student feedback form and rating system
|
*  96f1a22  fix(ui): redesign login screen with improved layout
|
*  b70747c  fix(security): move Firebase API keys to env config
|
*  e5ec135  feat(cancellation): mess cancellation + medical certificate upload
|
*  13db05f  feat(food-report): food issue reporting with image upload
|
*  f6cae43  fix(firebase): rotate and secure Firebase credentials
|
*  6b4b3e3  feat(menu): weekly menu uploader + Firebase menu structure
|
*  f293217  feat(database): Firebase Firestore integration
|
*  3a4d8b0  docs(dfd): add DFD Level-0, Level-1, Level-2 diagrams
|
*  2b6c1d5  docs(architecture): add layered architecture design diagram
|
*  1a5f2c4  docs(srs): add Software Requirements Specification v1.0
|
*  bea9f63  chore: initial Flutter project setup and Firebase config
```

### 7.1 Commit Message Convention

All commits follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <short description>

Types Used:
  feat     → New feature
  fix      → Bug fix
  docs     → Documentation only
  chore    → Build/config changes (no production code)
  refactor → Code refactoring (no behavior change)
  test     → Adding or updating tests
  release  → Version release commit
  hotfix   → Emergency production fix
```

---

## 8. Branching Diagram

The following ASCII diagram represents the Git Flow branching model for this project. It can be reproduced as a hand-drawn diagram in the lab record.

```
Timeline ──────────────────────────────────────────────────────────────────────►

main       ●───────────────────────────────────────────────────────────●  v1.0.0
            \                                                          /
             \                                                        /
release/v1.0  \                                             ●────────●
               \                                           /
                \                                         /
develop          ●─────────────●────────●────────────────●
                  \           / \      / \               /
                   \         /   \    /   \             /
feature/            ●───────●    ●──●     ●────────────●
user-management

develop          ●────────────────────●────────────────
                              \      /
                               \    /
feature/                        ●──●
menu-management

develop          ●──────────────────────────●───────────
                                      \    /
                                       \  /
feature/                                ●●
feedback


hotfix →  main ●──────────●  (emergency fix, merged back to develop)
                    ↑
              hotfix/fix-bug
```

### 8.1 Simplified Branch Flow for Lab Record

```
                    ┌─────────────────────────────────────────────────┐
                    │             MAIN BRANCH (Production)             │
                    └───────────┬─────────────────────┬───────────────┘
                                │ merge ▲             │ hotfix merge ▲
                    ┌───────────▼───────┴─────────────┴───────────────┐
                    │           DEVELOP BRANCH (Integration)           │
                    └──┬─────────┬─────────┬──────────┬───────────────┘
                       │         │         │          │  merge ▲▲▲▲▲
           ┌───────────▼┐  ┌─────▼──┐  ┌──▼──────┐  ┌▼──────────────┐
           │feature/user│  │feature/│  │feature/ │  │  feature/     │
           │management  │  │  menu  │  │feedback │  │  billing      │
           └────────────┘  └────────┘  └─────────┘  └───────────────┘

                    docs/srs ──┐
                               ├──► develop
                docs/dfd ──────┘
```

---

## 9. Workflow Analysis

### 9.1 Why Git Was Used

Git is a **distributed version control system (DVCS)** that enables multiple developers to work on the same codebase simultaneously without overwriting each other's work. Git was chosen for this project for the following reasons:

| Reason | Explanation |
|---|---|
| **Change Tracking** | Every commit records who changed what and when, providing a complete history. |
| **Parallel Development** | Branching allows multiple modules to be developed simultaneously. |
| **Recovery** | Any broken state can be reverted to a previous stable commit using `git revert` or `git reset`. |
| **Collaboration** | GitHub provides a centralized remote repository accessible to all team members. |
| **Code Review** | Pull Requests on GitHub enable peer review before code enters the main codebase. |
| **CI/CD Ready** | GitHub integrates with CI/CD pipelines (e.g., GitHub Actions) for automated testing. |

### 9.2 How Branching Improves Collaboration

In a multi-developer project, uncontrolled changes to a shared codebase lead to frequent conflicts and broken builds. Branching solves this by:

1. **Isolation:** Each feature or fix is developed in its own branch, isolated from others. A broken implementation does not affect teammates.
2. **Concurrent Development:** Team members work on different features simultaneously without stepping on each other.
3. **Controlled Integration:** Features are merged into `develop` only after being tested and reviewed, ensuring the integration branch always contains working code.
4. **Clear Ownership:** Each branch maps to a specific task or feature, making it clear who is responsible for what.

### 9.3 Why Feature-Based Branches Are Better Than Personal-Name Branches

Our repository initially used branches named after team members (`vishnu`, `danush`). While this works in the early stages, it becomes problematic at scale.

#### Problems with Personal-Name Branches:

| Problem | Impact |
|---|---|
| A branch like `vishnu` contains work from multiple modules | Impossible to selectively merge one feature without the others |
| No semantic meaning — branch name doesn't describe content | Team members can't determine what is safe to merge |
| One person owns the entire branch — no parallel work possible | Bottleneck if that member is unavailable |
| Conflicts accumulate over time | Large, difficult-to-resolve merge conflicts |
| Cannot be automatically tested per feature | No CI/CD granularity |

#### Advantages of Feature-Based Branches:

| Advantage | Explanation |
|---|---|
| Descriptive names | `feature/mess-cancellation` tells everyone exactly what the branch contains |
| Independent lifecycle | Branch is created, tested, merged, and deleted per feature |
| Multiple members can contribute | Any team member can work on `feature/billing` regardless of who started it |
| Clean `develop` branch | Only verified, complete features enter `develop` |
| Supports parallel development | All seven modules can be developed simultaneously |

### 9.4 How This Improves Maintainability and Scalability

**Maintainability:**
- When a bug is found in the billing module, a developer can trace the `feature/billing-management` branch's commits to identify the cause.
- Roll-back is scoped — reverting one feature does not disturb others.
- Commit messages following Conventional Commits make change logs readable and auto-generatable.

**Scalability:**
- New developers can be onboarded by assigning them a new feature branch without touching any existing code.
- As the system grows (e.g., adding an Analytics module), a new `feature/analytics-reporting` branch is created without disrupting existing workflows.
- Release branches (`release/v1.1`) allow planning for the next version while `main` remains stable.

---

## 10. Comparison of Git Workflows

### 10.1 Git Flow

**Description:** A strictly defined branching model with `main`, `develop`, `feature/*`, `release/*`, and `hotfix/*` branches. Best for projects with a scheduled release cycle.

| Aspect | Detail |
|---|---|
| Branches | main, develop, feature/*, release/*, hotfix/* |
| Release Cycle | Planned, versioned releases |
| Complexity | High — multiple branch types to manage |
| Best For | Large teams, enterprise software, versioned products |
| Tools | `git-flow` CLI extension available |

**Workflow:**
```
feature/* → develop → release/* → main (tagged)
                                 ↑
                           hotfix/* → main + develop
```

---

### 10.2 GitHub Flow

**Description:** A lightweight workflow with only `main` and short-lived feature branches. Every merge to `main` is deployable. Suitable for continuous delivery.

| Aspect | Detail |
|---|---|
| Branches | main, feature/* (no develop, no release) |
| Release Cycle | Continuous — every merge to main is production-ready |
| Complexity | Low — simple and easy to learn |
| Best For | Small teams, web apps, SaaS products, frequent deployments |
| Tools | Native GitHub Pull Request flow |

**Workflow:**
```
feature/* → (Pull Request + Review) → main (deploy immediately)
```

---

### 10.3 Feature Branch Workflow

**Description:** A general model where each feature is developed in its own branch and merged into a shared integration branch. It is the foundation of both Git Flow and GitHub Flow.

| Aspect | Detail |
|---|---|
| Branches | main (or develop), feature/* |
| Release Cycle | Flexible — release when ready |
| Complexity | Medium — manageable without special tooling |
| Best For | Most teams and project types |
| Tools | Standard Git |

**Workflow:**
```
feature/* → develop/main → (optional release branch) → main
```

---

### 10.4 Trunk-Based Development

**Description:** All developers commit directly to `main` (the "trunk"), using feature flags to hide incomplete work. Requires strong CI/CD.

| Aspect | Detail |
|---|---|
| Branches | main (trunk), very short-lived branches (<1 day) |
| Release Cycle | Continuous |
| Complexity | High — requires robust automated testing |
| Best For | Experienced teams with mature CI/CD pipelines |

---

### 10.5 Comparison Table

| Feature | Git Flow | GitHub Flow | Feature Branch | Trunk-Based |
|---|---|---|---|---|
| Number of long-lived branches | 2 (main, develop) | 1 (main) | 1–2 | 1 (trunk) |
| Release planning support | ✓ Excellent | ✗ Limited | ✓ Good | ✗ None |
| Hotfix support | ✓ Built-in | Partial | Partial | ✓ Via flags |
| Complexity | High | Low | Medium | Very High |
| Suitable for students | ✓ Good for learning | ✓ Simplest | ✓ Balanced | ✗ Advanced |
| CI/CD integration | ✓ | ✓ Excellent | ✓ | ✓ Required |
| Team size | Large | Small | Any | Large, expert |

---

### 10.6 Recommended Workflow for This Project

**Recommendation: Feature Branch Workflow with Git Flow principles.**

**Justification:**

1. **Multi-module project:** The platform has 7 independent modules (User Management, Menu, Feedback, Replacement, Leave, Billing, Analytics). Feature branches map directly to these modules.

2. **Academic and iterative delivery:** The project is submitted in phases (SRS → DFD → Architecture → Implementation). A `develop` branch collects completed phases while `main` represents the last submitted, stable version.

3. **Team of ~3 members:** Small enough that GitHub Flow would suffice, but Git Flow adds the `develop` buffer layer that protects `main` from accidental incomplete pushes.

4. **Firebase backend:** Multiple developers modifying `firebase_options.dart` and Firestore rules simultaneously is a common conflict source. Feature branches isolate these changes.

5. **Better than name-based branches:** Feature branches created from `develop` replace `vishnu` and `danush` branches while preserving the actual commits via proper merge history.

---

## 11. Transition Plan: From Name-Based to Feature-Based Branches

Since the repository already has `vishnu` and `danush` branches with meaningful commits, the transition should **preserve history** rather than discard it.

### Step 1: Create develop branch from current main

```bash
git checkout main
git pull origin main
git checkout -b develop
git push -u origin develop
```

### Step 2: Cherry-pick or reorganize commits from name branches

```bash
# View commits in vishnu branch that are not in main
git log main..origin/vishnu --oneline

# Example output:
# e5ec135  added mess cancellation and medical certificate pdf upload and view
# 13db05f  Implemented food issue reporting feature and updates
# 6b4b3e3  Added menu uploader + Firebase menu structure
# f293217  Database integrated

# Create feature branches from develop and cherry-pick relevant commits
git checkout develop
git checkout -b feature/mess-cancellation
git cherry-pick e5ec135        # mess cancellation commit

git checkout develop
git checkout -b feature/food-report
git cherry-pick 13db05f        # food issue reporting commit

git checkout develop
git checkout -b feature/menu-management
git cherry-pick 6b4b3e3 f293217   # menu + database commits
```

### Step 3: Merge feature branches into develop via Pull Requests

After cherry-picking, open Pull Requests on GitHub:
- `feature/mess-cancellation` → `develop`
- `feature/food-report` → `develop`
- `feature/menu-management` → `develop`

### Step 4: Clean up old name-based branches (after merging)

```bash
# Delete remote name-based branches
git push origin --delete vishnu
git push origin --delete danush
```

### Step 5: Protect main and develop branches on GitHub

Navigate to: **GitHub → Repository → Settings → Branches → Branch Protection Rules**

- `main`: Require Pull Request, require 1 review, disallow direct push
- `develop`: Require Pull Request, allow team members to merge

---

## 12. Conclusion / Inference

This assignment provided a comprehensive exploration of Git and GitHub as tools for professional source code management in the context of the **Digital Mess Management Platform**.

### Key Observations

1. **Git is essential for collaborative development.** Without version control, multiple developers working on the same Flutter codebase would inevitably overwrite each other's work. Git's branching model eliminates this by providing isolated workspaces for each feature or fix.

2. **Branch naming reflects team maturity.** Our initial use of personal-name branches (`vishnu`, `danush`) was a natural starting point but lacks semantic value. Transitioning to feature-based branches (`feature/menu-management`, `feature/mess-cancellation`) directly maps branches to system requirements, improving readability and traceability.

3. **Git Flow is well-suited for academic project delivery.** The separation of `main` (stable, submitted), `develop` (integration), and `feature/*` (active work) branches aligns perfectly with the phased submission structure of a software engineering course.

4. **Commit history is a form of documentation.** Using Conventional Commits, the commit log becomes a self-describing change log that maps implementation steps to project requirements, valuable both for grading and for future maintenance.

5. **Merge conflicts are manageable with discipline.** By assigning different modules to different branches and merging frequently into `develop`, we minimize the scope and frequency of conflicts.

6. **GitHub's Pull Request workflow enforces code review.** By requiring a Pull Request before merging into `develop` or `main`, every code change is reviewed by at least one other team member, improving code quality and knowledge sharing.

### Inference

The **Feature Branch Workflow combined with Git Flow principles** is the most appropriate strategy for the Digital Mess Management Platform. It provides structured branch management suitable for a team working on multiple modules simultaneously, supports incremental feature delivery aligned with assignment milestones, and prepares the codebase for eventual production deployment. The professional practices documented in this assignment — commit conventions, branch naming, protected branches, pull request reviews — form the foundation of industry-standard software development workflows.

---

*End of Assignment 5 – Source Code Management Using Git and GitHub*

---

**Submitted by:**  
Team – Digital Mess Management Platform  
Course: Software Engineering Principles and Practices (SEP)  
Date: March 2026
