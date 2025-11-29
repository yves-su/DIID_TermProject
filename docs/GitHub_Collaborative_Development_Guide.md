# 📚 GitHub Collaborative Development Complete Guide

> This guide is designed for term project team collaborative development, providing detailed explanations of GitHub operations in various development scenarios

---

## 📋 Table of Contents

- [📚 GitHub Collaborative Development Complete Guide](#-github-collaborative-development-complete-guide)
  - [📋 Table of Contents](#-table-of-contents)
  - [1. Quick Start - Joining the Project for the First Time](#1-quick-start---joining-the-project-for-the-first-time)
    - [1.1 Prerequisites](#11-prerequisites)
    - [1.2 Clone Project to Local](#12-clone-project-to-local)
    - [1.3 Configure Git User Information](#13-configure-git-user-information)
    - [1.4 Check Project Status](#14-check-project-status)
  - [2. Development Mode Selection](#2-development-mode-selection)
    - [2.1 Mode One: Independent Development (No Version Merging)](#21-mode-one-independent-development-no-version-merging)
    - [2.2 Mode Two: Collaborative Development (Version Merging Required)](#22-mode-two-collaborative-development-version-merging-required)
  - [3. Mode One: Independent Development Workflow](#3-mode-one-independent-development-workflow)
    - [3.1 Create Personal Development Branch](#31-create-personal-development-branch)
    - [3.2 Develop on Branch](#32-develop-on-branch)
    - [3.3 Commit Changes to Personal Branch](#33-commit-changes-to-personal-branch)
    - [3.4 Sync Latest Changes from Main Branch](#34-sync-latest-changes-from-main-branch)
    - [3.5 Pros and Cons of Independent Branches](#35-pros-and-cons-of-independent-branches)
  - [4. Mode Two: Collaborative Development and Merge Workflow](#4-mode-two-collaborative-development-and-merge-workflow)
    - [4.1 Create Feature Branch](#41-create-feature-branch)
    - [4.2 Develop on Feature Branch](#42-develop-on-feature-branch)
    - [4.3 Commit Changes](#43-commit-changes)
    - [4.4 Push Branch to Remote](#44-push-branch-to-remote)
    - [4.5 Create Pull Request](#45-create-pull-request)
    - [4.6 Code Review Process](#46-code-review-process)
    - [4.7 Merge Pull Request](#47-merge-pull-request)
    - [4.8 Clean Up Merged Branches](#48-clean-up-merged-branches)
  - [5. Taking Over Others' Modified Code](#5-taking-over-others-modified-code)
    - [5.1 View Others' Changes](#51-view-others-changes)
    - [5.2 Pull Latest Code](#52-pull-latest-code)
    - [5.3 Understand Change Content](#53-understand-change-content)
    - [5.4 Continue Development Based on Others' Code](#54-continue-development-based-on-others-code)
    - [5.5 Handle Conflict Situations](#55-handle-conflict-situations)
  - [6. Adding Files Workflow](#6-adding-files-workflow)
    - [6.1 Add General Program Files](#61-add-general-program-files)
    - [6.2 Add Machine Learning Related Files](#62-add-machine-learning-related-files)
    - [6.3 Handle Large Files](#63-handle-large-files)
    - [6.4 Configuration File Notes](#64-configuration-file-notes)
  - [7. Modifying Existing Files Workflow](#7-modifying-existing-files-workflow)
    - [7.1 Preparation Before Modifying](#71-preparation-before-modifying)
    - [7.2 View File History](#72-view-file-history)
    - [7.3 Make Modifications](#73-make-modifications)
    - [7.4 Commit Modifications](#74-commit-modifications)
    - [7.5 Modify Multiple Files](#75-modify-multiple-files)
  - [8. Machine Learning Related Development Workflow](#8-machine-learning-related-development-workflow)
    - [8.1 Create Machine Learning Development Branch](#81-create-machine-learning-development-branch)
    - [8.2 Add Training Data](#82-add-training-data)
    - [8.3 Add Model Training Script](#83-add-model-training-script)
    - [8.4 Add Model Files](#84-add-model-files)
    - [8.5 Integrate Model into Main Project](#85-integrate-model-into-main-project)
    - [8.6 Model Version Management](#86-model-version-management)
  - [9. Detailed Steps for Handling Conflicts](#9-detailed-steps-for-handling-conflicts)
    - [9.1 Causes of Conflicts](#91-causes-of-conflicts)
    - [9.2 Handling When Conflicts Occur](#92-handling-when-conflicts-occur)
    - [9.3 Resolve Conflicts Using Git Tools](#93-resolve-conflicts-using-git-tools)
    - [9.4 Resolve Conflicts Using VS Code](#94-resolve-conflicts-using-vs-code)
    - [9.5 Steps After Resolving Conflicts](#95-steps-after-resolving-conflicts)
  - [10. Common Git Commands Quick Reference](#10-common-git-commands-quick-reference)
    - [10.1 Status Query Commands](#101-status-query-commands)
    - [10.2 Branch Operation Commands](#102-branch-operation-commands)
    - [10.3 Commit Operation Commands](#103-commit-operation-commands)
    - [10.4 Remote Operation Commands](#104-remote-operation-commands)
    - [10.5 History Query Commands](#105-history-query-commands)
  - [11. Common Issues and Solutions](#11-common-issues-and-solutions)
    - [11.1 Cannot Push Changes](#111-cannot-push-changes)
    - [11.2 Forgot to Switch Branch Before Starting Development](#112-forgot-to-switch-branch-before-starting-development)
    - [11.3 Committed Wrong Changes](#113-committed-wrong-changes)
    - [11.4 Want to Undo Local Changes](#114-want-to-undo-local-changes)
    - [11.5 Want to Undo Pushed Commits](#115-want-to-undo-pushed-commits)
  - [12. Best Practices](#12-best-practices)
    - [12.1 Commit Message Standards](#121-commit-message-standards)
    - [12.2 Branch Naming Standards](#122-branch-naming-standards)
    - [12.3 Development Frequency Recommendations](#123-development-frequency-recommendations)
    - [12.4 Collaborative Development Notes](#124-collaborative-development-notes)
  - [📝 Appendix: Quick Reference](#-appendix-quick-reference)
    - [Daily Development Workflow (Independent Branch)](#daily-development-workflow-independent-branch)
    - [Daily Development Workflow (Collaborative Development)](#daily-development-workflow-collaborative-development)
    - [Emergency Handling](#emergency-handling)
  - [🎓 Conclusion](#-conclusion)

---

## 1. Quick Start - Joining the Project for the First Time

### 1.1 Prerequisites

Before starting, please ensure you have completed the following preparations:

1. **Install Git**
   - Windows: Download and install [Git for Windows](https://git-scm.com/download/win)
   - After installation, open Command Prompt or PowerShell and enter `git --version` to confirm successful installation

2. **Register GitHub Account**
   - If you don't have a GitHub account yet, please register at [GitHub](https://github.com)

3. **Get Project Access Permission**
   - Ask the project initiator to add you as a Collaborator
   - Or ask the initiator to provide the project's GitHub URL

4. **Choose Development Tools**
   - **Command Line**: Git Bash, PowerShell, Command Prompt
   - **Graphical Tools**: GitHub Desktop, SourceTree, VS Code built-in Git
   - **IDE Integration**: Android Studio, VS Code

### 1.2 Clone Project to Local

**Step 1: Get Project URL**
- On the GitHub project page, click the green "Code" button
- Copy the HTTPS URL (e.g., `https://github.com/username/DIID_TermProject.git`)

**Step 2: Open Terminal**
- Windows: Open PowerShell or Git Bash
- Navigate to the directory where you want to store the project (e.g., `cd D:\DevProjects`)

**Step 3: Execute Clone Command**
```bash
git clone https://github.com/username/DIID_TermProject.git
```

**Step 4: Enter Project Directory**
```bash
cd DIID_TermProject
```

**Step 5: Confirm Clone Success**
```bash
git status
```
Should display "On branch main" or "On branch master", indicating successful clone

### 1.3 Configure Git User Information

**First time using Git requires setting your identity information:**

```bash
# Set your name (can use Chinese or English)
git config --global user.name "Your Name"

# Set your Email (use the Email registered with GitHub)
git config --global user.email "your.email@example.com"
```

**Confirm if settings are successful:**
```bash
git config --global user.name
git config --global user.email
```

**Note**: `--global` means this setting applies to all Git projects on your computer. If you only want to set it for this project, remove `--global`.

### 1.4 Check Project Status

**View current branch:**
```bash
git branch
```
The branch with `*` is your current branch

**View project's remote repository settings:**
```bash
git remote -v
```
Should display `origin` pointing to the project URL on GitHub

**View project's commit history:**
```bash
git log --oneline
```
Will display a simplified version of commit history

---

## 2. Development Mode Selection

Before starting development, you need to decide which development mode to use. This depends on your work style and team collaboration needs.

### 2.1 Mode One: Independent Development (No Version Merging)

**Applicable Scenarios:**
- The functional module you're responsible for is completely independent from others
- No need to integrate with others' code
- Want to keep your development progress unaffected
- Only need to submit your part for the term project

**Features:**
- Develop independently on personal branch
- No need to create Pull Request
- Won't affect main branch (main/master)
- Can sync latest changes from main branch anytime

### 2.2 Mode Two: Collaborative Development (Version Merging Required)

**Applicable Scenarios:**
- Need to integrate with others' code
- Multiple people modifying the same file simultaneously
- Need code review
- Need to merge features into main branch for others to use

**Features:**
- Develop on feature branch
- Need to create Pull Request
- Merge into main branch after review
- Everyone can use merged features

---

## 3. Mode One: Independent Development Workflow

### 3.1 Create Personal Development Branch

**Step 1: Ensure you're on main branch and it's the latest version**
```bash
# Switch to main branch
git checkout main
# or
git checkout master

# Pull latest changes
git pull origin main
```

**Step 2: Create and switch to your personal branch**
```bash
# Create new branch and immediately switch to it
git checkout -b your-name-dev
# Example: git checkout -b john-dev
```

**Step 3: Confirm branch switch success**
```bash
git branch
```
Should see `* your-name-dev`, indicating you're now on this branch

**Step 4: Push branch to remote (let others know about your branch)**
```bash
git push -u origin your-name-dev
```
The `-u` parameter sets the upstream branch, so you can use `git push` directly without specifying branch name later

### 3.2 Develop on Branch

Now you can freely develop on this branch:

1. **Modify existing files**
   - Use your preferred editor (VS Code, Android Studio, etc.)
   - Make any modifications

2. **Add files**
   - Add any needed files in the project directory
   - For example: add Python training scripts, add Java classes, etc.

3. **Test your changes**
   - Ensure the program can compile and run normally
   - Test if functionality works correctly

### 3.3 Commit Changes to Personal Branch

**Step 1: View what changes you made**
```bash
git status
```
Will display:
- Modified files (red)
- New but untracked files (red)
- Staged files (green)

**Step 2: Add changes to staging area (Staging Area)**

**Method A: Add all changes**
```bash
git add .
```

**Method B: Selectively add specific files**
```bash
git add file-path
# Example:
git add src/main/main.ino
git add APP/android/app/src/main/java/com/example/smartbadmintonracket/MainActivity.java
```

**Step 3: Confirm staged changes**
```bash
git status
```
Now should see staged files displayed in green

**Step 4: Commit changes**
```bash
git commit -m "Describe your changes"
# Examples:
git commit -m "Add machine learning model training script"
git commit -m "Fix BLE connection stability issue"
git commit -m "Add voltage monitoring feature"
```

**Step 5: Push to remote branch**
```bash
git push
```
If this is the first time pushing this branch, use:
```bash
git push -u origin your-name-dev
```

### 3.4 Sync Latest Changes from Main Branch

Even when developing on an independent branch, sometimes you need to sync latest changes from main branch (e.g., others fixed important bugs, or added shared utility functions).

**Step 1: Save your current changes (if there are uncommitted changes)**
```bash
# Check if there are uncommitted changes
git status

# If yes, commit or stash first
git add .
git commit -m "Work in progress"
```

**Step 2: Switch to main branch**
```bash
git checkout main
```

**Step 3: Pull latest changes from main branch**
```bash
git pull origin main
```

**Step 4: Switch back to your development branch**
```bash
git checkout your-name-dev
```

**Step 5: Merge main branch changes into your branch**
```bash
git merge main
```

**If conflicts occur:**
- Refer to [Chapter 9: Detailed Steps for Handling Conflicts](#9-detailed-steps-for-handling-conflicts)

**Step 6: Push merged changes**
```bash
git push
```

### 3.5 Pros and Cons of Independent Branches

**Pros:**
- ✅ Development process unaffected by others
- ✅ Can commit anytime without waiting for review
- ✅ Suitable for independent functional module development
- ✅ Won't accidentally break main branch

**Cons:**
- ❌ Others can't see your progress (unless they check your branch)
- ❌ Your features can't be directly used by others
- ❌ If not updated for a long time, may diverge too much from main branch

---

## 4. Mode Two: Collaborative Development and Merge Workflow

### 4.1 Create Feature Branch

**Step 1: Ensure main branch is latest**
```bash
git checkout main
git pull origin main
```

**Step 2: Create feature branch**
```bash
# Branch naming suggestion: feature-name-your-name
git checkout -b feature/zero-point-calibration-john
# or
git checkout -b ml-model-training-mary
# or
git checkout -b fix/ble-connection-issue-tom
```

**Branch naming standards:**
- `feature/` - New feature
- `fix/` - Bug fix
- `ml/` - Machine learning related
- `docs/` - Documentation related

**Step 3: Push branch to remote**
```bash
git push -u origin feature/zero-point-calibration-john
```

### 4.2 Develop on Feature Branch

Development workflow is the same as independent branch:
1. Make modifications
2. Test functionality
3. Commit changes

**Recommendations:**
- Frequently commit small changes, rather than accumulating many changes before one commit
- Write clearly what you did in each commit
- Ensure program can compile normally after each commit

### 4.3 Commit Changes

**Step 1: View changes**
```bash
git status
```

**Step 2: Add changes to staging area**
```bash
# Add all changes
git add .

# Or selectively add
git add specific-file-path
```

**Step 3: Commit changes**
```bash
git commit -m "Clear change description"
```

**Good commit message examples:**
```
✅ "Add zero-point calibration feature"
✅ "Fix occasional BLE disconnection issue"
✅ "Add CNN model training script, supports 5 classifications"
✅ "Update Android App UI, improve chart display performance"
```

**Bad commit message examples:**
```
❌ "Update"
❌ "Fix bug"
❌ "Change"
❌ "test"
```

### 4.4 Push Branch to Remote

**Push changes to remote branch:**
```bash
git push
```

If this is the first time pushing this branch:
```bash
git push -u origin feature/zero-point-calibration-john
```

**Note:** After pushing, others can see your branch and changes on GitHub.

### 4.5 Create Pull Request

**Step 1: Go to GitHub project page**

**Step 2: Click "Pull requests" tab**

**Step 3: Click green "New pull request" button**

**Step 4: Select branches**
- **Base branch (target branch)**: Select `main` or `master`
- **Compare branch (source branch)**: Select your feature branch (e.g., `feature/zero-point-calibration-john`)

**Step 5: Fill in Pull Request information**
- **Title**: Briefly describe what this PR does
  - Example: "Add zero-point calibration feature"
- **Description**: Detailed explanation
  - What this PR does
  - Why this change is needed
  - How to test
  - Related issues or discussions

**Pull Request description example:**
```markdown
## Changes
- Add zero-point calibration feature, allowing users to manually calibrate IMU sensor
- Calibration data stored in local SharedPreferences
- All subsequent data automatically applies calibration values

## Testing Method
1. Connect SmartRacket device
2. Click "Zero-Point Calibration" button
3. Keep racket still and flat for 10 seconds
4. Confirm calibration values are saved
5. Confirm subsequent data has applied calibration

## Related Files
- `CalibrationManager.java`
- `CalibrationStorage.java`
- `MainActivity.java`
```

**Step 6: Select reviewers**
- Click "Reviewers" on the right
- Select project initiator or relevant team members

**Step 7: Click "Create pull request"**

### 4.6 Code Review Process

**If you are a reviewer:**

**Step 1: View Pull Request**
- Go to GitHub's Pull Request page
- Click "Files changed" to view all changes

**Step 2: Review code**
- Check if code logic is correct
- Check for obvious bugs
- Check if code style is consistent
- Check for security issues

**Step 3: Leave comments**
- Click the `+` next to line numbers
- Enter your comment
- Can choose:
  - **Comment**: General comment
  - **Approve**: Approve merge
  - **Request changes**: Needs modification

**Step 4: Submit review**
- Click "Submit review"

**If you are the PR initiator:**

**Step 1: View review comments**
- View reviewer's comments on PR page

**Step 2: Respond to comments**
- Click "Reply" below comments
- Explain your thoughts or confirm you'll modify

**Step 3: Modify code according to feedback**
```bash
# Make modifications on your feature branch
git add .
git commit -m "Fix according to review comments: ..."
git push
```

**Step 4: Mark as resolved**
- On GitHub, if issue is fixed, can mark comment as "Resolved"

### 4.7 Merge Pull Request

**When review is approved:**

**Step 1: Confirm all review comments are handled**

**Step 2: Confirm no conflicts**
- GitHub automatically checks for conflicts
- If conflicts exist, need to resolve first (refer to Chapter 9)

**Step 3: Merge PR**
- On PR page, click green "Merge pull request" button
- Choose merge method:
  - **Create a merge commit**: Preserve complete commit history (recommended)
  - **Squash and merge**: Merge all commits into one
  - **Rebase and merge**: Linear history (not recommended unless team is familiar)

**Step 4: Confirm merge**
- Enter confirmation message
- Click "Confirm merge"

**Step 5: Delete merged branch (optional)**
- GitHub will ask if you want to delete source branch
- Recommend clicking "Delete branch" to keep repository clean

### 4.8 Clean Up Merged Branches

**Delete merged branch locally:**

**Step 1: Switch to main branch**
```bash
git checkout main
```

**Step 2: Pull latest changes (including the PR you just merged)**
```bash
git pull origin main
```

**Step 3: Delete local branch**
```bash
git branch -d feature/zero-point-calibration-john
```

If branch hasn't been merged, Git will warn you. If you're sure you want to force delete:
```bash
git branch -D feature/zero-point-calibration-john
```

**Step 4: Delete remote branch (if not automatically deleted)**
```bash
git push origin --delete feature/zero-point-calibration-john
```

---

## 5. Taking Over Others' Modified Code

### 5.1 View Others' Changes

**Method One: View on GitHub**

**Step 1: Go to project page**

**Step 2: View recent commits**
- Click "Commits" to view all commit records
- Click specific commit to view detailed changes

**Step 3: View Pull Request**
- Click "Pull requests"
- View open or merged PRs
- Click PR to view change content and discussions

**Method Two: View locally**

**Step 1: Pull latest changes**
```bash
git checkout main
git pull origin main
```

**Step 2: View commit history**
```bash
# Simplified history
git log --oneline

# Detailed history
git log

# View specific file's history
git log -- file-path
```

**Step 3: View specific commit's changes**
```bash
# View latest commit's changes
git show

# View specific commit's changes
git show commit-hash
# Example: git show abc1234
```

### 5.2 Pull Latest Code

**Step 1: Confirm current branch**
```bash
git branch
```

**Step 2: If not on main branch, switch first**
```bash
git checkout main
```

**Step 3: Pull latest changes**
```bash
git pull origin main
```

**Step 4: Confirm pull success**
```bash
git log --oneline -5
```
Should see latest commit records

### 5.3 Understand Change Content

**View specific file's changes:**

**Step 1: View file's change history**
```bash
git log -- file-path
# Example:
git log -- APP/android/app/src/main/java/com/example/smartbadmintonracket/MainActivity.java
```

**Step 2: View differences between two versions**
```bash
# View differences with previous version
git diff HEAD~1 file-path

# View differences with specific commit
git diff commit-hash file-path
```

**Step 3: View file's complete change content**
```bash
git show commit-hash:file-path
```

**Using graphical tools:**
- VS Code: Right-click file → "Open Timeline" to view history
- GitHub Desktop: Click file to view changes
- Android Studio: VCS → Git → Show History

### 5.4 Continue Development Based on Others' Code

**Scenario A: Others committed changes on main branch, you want to continue development**

**Step 1: Ensure your branch is latest**
```bash
# Switch to your development branch
git checkout your-branch-name

# Pull latest changes from main branch
git fetch origin main

# Merge main branch changes into your branch
git merge origin/main
```

**Scenario B: Others developing on another branch, you want to continue based on their branch**

**Step 1: View remote branches**
```bash
git fetch origin
git branch -r
```

**Step 2: Create local branch tracking remote branch**
```bash
git checkout -b local-branch-name origin/remote-branch-name
```

**Step 3: Continue development on this branch**
```bash
# Make your modifications
# ...
# Commit changes
git add .
git commit -m "Continue development based on others' changes: ..."
git push
```

**Scenario C: You want to modify code that others have already committed**

**Step 1: Pull latest changes**
```bash
git checkout main
git pull origin main
```

**Step 2: Create new branch**
```bash
git checkout -b improve/feature-name
```

**Step 3: Make modifications**
- Find files to modify
- Make your improvements

**Step 4: Commit changes**
```bash
git add .
git commit -m "Improve: Based on someone's implementation, optimize..."
git push -u origin improve/feature-name
```

**Step 5: Create Pull Request**
- Refer to [4.5 Create Pull Request](#45-create-pull-request)

### 5.5 Handle Conflict Situations

When you and others modify the same part of the same file, conflicts occur. For detailed handling methods, please refer to [Chapter 9: Detailed Steps for Handling Conflicts](#9-detailed-steps-for-handling-conflicts).

---

## 6. Adding Files Workflow

### 6.1 Add General Program Files

**Step 1: Add file in project**
- Use your editor or IDE to add files
- For example: add a new Java class, Python script, etc.

**Step 2: Confirm file is created**
```bash
git status
```
Should see new file displayed in red (untracked)

**Step 3: Add file to Git tracking**
```bash
# Add single file
git add file-path

# Examples:
git add APP/android/app/src/main/java/com/example/smartbadmintonracket/NewClass.java
git add examples/train_model.py
```

**Step 4: Confirm file is added to staging area**
```bash
git status
```
Now should see file displayed in green (staged)

**Step 5: Commit file**
```bash
git commit -m "Add: File function description"
# Examples:
git commit -m "Add: Machine learning data preprocessing tool"
git commit -m "Add: BLE connection status monitoring class"
```

**Step 6: Push to remote**
```bash
git push
```

### 6.2 Add Machine Learning Related Files

Machine learning related files usually include:
- Training scripts (Python)
- Data processing scripts
- Model files (.tflite, .h5, .pkl, etc.)
- Training datasets
- Configuration files

**Step 1: Create appropriate directory structure**

Recommended directory structure:
```
DIID_TermProject/
├── ml/
│   ├── training/
│   │   ├── train_model.py          # Training script
│   │   ├── preprocess_data.py      # Data preprocessing
│   │   └── evaluate_model.py       # Model evaluation
│   ├── models/
│   │   ├── badminton_model_v1.tflite
│   │   └── badminton_model_v2.tflite
│   ├── data/
│   │   ├── raw/                     # Raw data
│   │   └── processed/               # Processed data
│   └── config/
│       └── model_config.json
```

**Step 2: Add training script**
```bash
# Create directory (if doesn't exist)
mkdir -p ml/training

# Add file (using your editor)
# Then add to Git
git add ml/training/train_model.py
git commit -m "Add: CNN model training script, supports 5 classifications"
git push
```

**Step 3: Add model files**

**Note: Handling large model files (> 50MB)**

GitHub has a 100MB limit for single files. If model files are large:

**Option A: Use Git LFS (Large File Storage)**
```bash
# Install Git LFS (if not installed)
# Windows: Download https://git-lfs.github.com/

# Initialize Git LFS
git lfs install

# Track specific file types
git lfs track "*.tflite"
git lfs track "*.h5"
git lfs track "*.pkl"

# Commit .gitattributes file
git add .gitattributes
git commit -m "Configure Git LFS to track model files"

# Add model file
git add ml/models/badminton_model.tflite
git commit -m "Add: Trained CNN model"
git push
```

**Option B: Don't upload model files, only upload training scripts**
- Add model files to `.gitignore`
- Explain how to train model in README
- Or use cloud storage (Google Drive, Dropbox) to share models

**Option C: Use compression**
```bash
# Compress model file
zip badminton_model.zip badminton_model.tflite

# Add compressed file
git add badminton_model.zip
git commit -m "Add: CNN model (compressed)"
git push
```

**Step 4: Add training data**

**Note: Dataset files are usually large**

Recommended approach:
1. **Small datasets (< 10MB)**: Can directly add to Git
2. **Medium datasets (10-50MB)**: Use Git LFS
3. **Large datasets (> 50MB)**: 
   - Add to `.gitignore`
   - Use cloud storage to share
   - Or explain data source in README

**If using Git LFS:**
```bash
git lfs track "*.xlsx"
git lfs track "*.csv"
git add .gitattributes
git commit -m "Configure Git LFS to track dataset files"

git add ml/data/training_data.xlsx
git commit -m "Add: Training dataset (labeled IMU data)"
git push
```

### 6.3 Handle Large Files

**Check file size:**
```bash
# Windows PowerShell
Get-Item file-path | Select-Object Length

# Git Bash
ls -lh file-path
```

**If file exceeds 50MB, recommend:**

1. **Use Git LFS** (recommended)
2. **Split files**
3. **Use external storage** (Google Drive, OneDrive)
4. **Only upload sample data**, share complete data separately

### 6.4 Configuration File Notes

**Sensitive information handling:**

Configuration files may contain sensitive information (API Keys, passwords, etc.), **absolutely do not** directly commit to Git!

**Step 1: Create example configuration file**
```bash
# Create config.example.json
{
  "api_key": "YOUR_API_KEY_HERE",
  "database_url": "YOUR_DATABASE_URL"
}
```

**Step 2: Add example file to Git**
```bash
git add config.example.json
git commit -m "Add: Configuration file example"
```

**Step 3: Add actual configuration file to .gitignore**
```bash
# Edit .gitignore, add:
config.json
google-services.json  # If contains sensitive information
*.secret
```

**Step 4: Commit .gitignore changes**
```bash
git add .gitignore
git commit -m "Update: Ignore sensitive configuration files"
git push
```

**Note:** If you've accidentally committed sensitive files:
1. Immediately remove sensitive information from files
2. Refer to [11.5 Want to Undo Pushed Commits](#115-want-to-undo-pushed-commits)
3. Consider regenerating all API Keys and passwords

---

## 7. Modifying Existing Files Workflow

### 7.1 Preparation Before Modifying

**Step 1: Confirm you're on the correct branch**
```bash
git branch
```

**Step 2: Ensure branch is latest**
```bash
git pull
```

**Step 3: View file to modify**
```bash
# View file content
cat file-path

# Or open with editor
code file-path  # VS Code
```

### 7.2 View File History

**Understanding file's change history helps understand code:**

**Step 1: View file's commit history**
```bash
git log -- file-path
# Example:
git log -- APP/android/app/src/main/java/com/example/smartbadmintonracket/MainActivity.java
```

**Step 2: View file's detailed changes**
```bash
# View specific commit's changes to this file
git show commit-hash -- file-path
```

**Step 3: Compare differences between two versions**
```bash
# Compare with previous version
git diff HEAD~1 file-path

# Compare with specific commit
git diff commit-hash file-path

# Compare with another branch
git diff branch-name file-path
```

### 7.3 Make Modifications

**Step 1: Use editor to modify file**
- Make your needed modifications
- Ensure code can compile normally
- Test if functionality works correctly

**Step 2: View modification content**
```bash
git status
```
Will display modified files

**Step 3: View what was specifically modified**
```bash
# View all modifications
git diff

# View specific file's modifications
git diff file-path
```

### 7.4 Commit Modifications

**Step 1: Add modifications to staging area**
```bash
# Add all modifications
git add .

# Or selectively add
git add file-path
```

**Step 2: Confirm staged changes**
```bash
git status
```

**Step 3: Commit modifications**
```bash
git commit -m "Modify: Clear description of what was changed"
# Examples:
git commit -m "Modify: Optimize BLE data reception buffer size"
git commit -m "Modify: Fix zero-point calibration calculation logic"
git commit -m "Modify: Improve chart update performance, reduce memory usage"
```

**Step 4: Push to remote**
```bash
git push
```

### 7.5 Modify Multiple Files

**Scenario: You need to modify multiple related files**

**Method A: Commit all related changes at once**
```bash
# After modifying multiple files
git add file1 file2 file3
git commit -m "Modify: Implement new feature, involves multiple files"
git push
```

**Method B: Commit different types of changes separately**
```bash
# First commit function-related modifications
git add MainActivity.java BLEManager.java
git commit -m "Modify: Add zero-point calibration feature"

# Then commit UI-related modifications
git add activity_main.xml
git commit -m "Modify: Update zero-point calibration button style"

# Finally push
git push
```

**Recommendation:** If changes are all for the same feature, recommend committing together. If changes have different purposes, recommend committing separately for clearer history.

---

## 8. Machine Learning Related Development Workflow

### 8.1 Create Machine Learning Development Branch

**Step 1: Create ML branch from main branch**
```bash
git checkout main
git pull origin main
git checkout -b ml/model-training-v1
```

**Step 2: Push to remote**
```bash
git push -u origin ml/model-training-v1
```

### 8.2 Add Training Data

**Step 1: Create data directory**
```bash
mkdir -p ml/data/raw
mkdir -p ml/data/processed
```

**Step 2: Prepare data files**
- Put Excel or CSV data into `ml/data/raw/`
- Ensure data format meets requirements

**Step 3: Decide whether to add to Git**

**Small datasets (< 10MB):**
```bash
git add ml/data/raw/training_data.xlsx
git commit -m "Add: IMU training dataset (labeled)"
```

**Large datasets (> 10MB):**
- Use Git LFS (refer to 6.2)
- Or add to `.gitignore`, use cloud sharing

**Step 4: Push to remote**
```bash
git push
```

### 8.3 Add Model Training Script

**Step 1: Create training script**
```bash
# Create in ml/training/ directory
# train_badminton_model.py
```

**Step 2: Develop training script**
- Implement data loading
- Implement data preprocessing
- Implement model architecture
- Implement training process
- Implement model saving

**Step 3: Test script**
```bash
# Execute training script
python ml/training/train_badminton_model.py
```

**Step 4: Add to Git**
```bash
git add ml/training/train_badminton_model.py
git commit -m "Add: CNN model training script, supports 5 classifications (Smash, Drive, Toss, Drop, Other)"
git push
```

### 8.4 Add Model Files

**Step 1: Execute training to generate model**
```bash
python ml/training/train_badminton_model.py
# Generates ml/models/badminton_model_v1.tflite
```

**Step 2: Check model file size**
```bash
ls -lh ml/models/badminton_model_v1.tflite
```

**Step 3: Decide handling method based on size**

**Small models (< 10MB):**
```bash
git add ml/models/badminton_model_v1.tflite
git commit -m "Add: Trained CNN model v1.0"
git push
```

**Large models (> 10MB):**
- Use Git LFS (refer to 6.2)
- Or compress before uploading
- Or use cloud sharing

### 8.5 Integrate Model into Main Project

**Step 1: Copy model file to Android project**
```bash
# Copy model to Android assets directory
cp ml/models/badminton_model_v1.tflite APP/android/app/src/main/assets/
```

**Step 2: Modify Android code to load model**
- Modify relevant Java files
- Implement model loading and inference logic

**Step 3: Test integration**
- Compile Android App
- Test if model can load and execute normally

**Step 4: Commit changes**
```bash
git add APP/android/app/src/main/assets/badminton_model_v1.tflite
git add APP/android/app/src/main/java/com/example/smartbadmintonracket/ModelInference.java
git commit -m "Integrate: Integrate CNN model into Android App"
git push
```

**Step 5: Create Pull Request**
- Refer to [4.5 Create Pull Request](#45-create-pull-request)
- In description, explain:
  - Model architecture
  - Training data source
  - Model accuracy
  - How to use model

### 8.6 Model Version Management

**Recommended version management methods:**

**Method A: Use version number naming**
```
ml/models/
├── badminton_model_v1.0.tflite  # Initial version
├── badminton_model_v1.1.tflite  # Minor improvement
├── badminton_model_v2.0.tflite  # Major update
└── badminton_model_latest.tflite  # Latest version (symbolic link)
```

**Method B: Use Git Tag**
```bash
# After training completes, create tag
git tag -a v1.0 -m "CNN model v1.0: 5 classifications, 85% accuracy"
git push origin v1.0

# Can return to this version anytime later
git checkout v1.0
```

**Method C: Use branch management**
```
ml/
├── models/
│   ├── v1/
│   │   └── badminton_model.tflite
│   ├── v2/
│   │   └── badminton_model.tflite
│   └── latest -> v2/  # Symbolic link pointing to latest version
```

---

## 9. Detailed Steps for Handling Conflicts

### 9.1 Causes of Conflicts

Conflicts occur in the following situations:
1. You and others simultaneously modify the same part of the same file
2. When you try to merge branches, both branches modified the same place
3. When you pull remote changes, local and remote both modified the same place

### 9.2 Handling When Conflicts Occur

**When you execute `git merge` or `git pull`, if conflicts appear:**

```
Auto-merging MainActivity.java
CONFLICT (content): Merge conflict in MainActivity.java
Automatic merge failed; fix conflicts and then commit the result.
```

**Step 1: Don't panic! This is normal**

**Step 2: View which files have conflicts**
```bash
git status
```
Will display:
```
Unmerged paths:
  (use "git add <file>..." to mark as resolved)
        both modified:   MainActivity.java
```

### 9.3 Resolve Conflicts Using Git Tools

**Step 1: Open file with conflicts**

You'll see conflict markers:
```java
<<<<<<< HEAD
// Your changes
public void yourMethod() {
    // Your code
}
=======
// Others' changes
public void theirMethod() {
    // Others' code
}
>>>>>>> branch-name
```

**Conflict marker explanation:**
- `<<<<<<< HEAD`: Your current changes (HEAD points to your current version)
- `=======`: Separator
- `>>>>>>> branch-name`: Changes to merge in (from other branch or remote)

**Step 2: Decide how to resolve conflict**

**Option A: Keep your changes**
```java
// Delete conflict markers, only keep your code
public void yourMethod() {
    // Your code
}
```

**Option B: Keep others' changes**
```java
// Delete conflict markers, only keep others' code
public void theirMethod() {
    // Others' code
}
```

**Option C: Merge both changes**
```java
// Keep both sides' code, but ensure logic is correct
public void yourMethod() {
    // Your code
}

public void theirMethod() {
    // Others' code
}
```

**Option D: Completely rewrite**
```java
// Based on both sides' changes, write a better version
public void improvedMethod() {
    // Code combining both sides' advantages
}
```

**Step 3: Delete all conflict markers**
- Ensure no `<<<<<<<`, `=======`, `>>>>>>>` markers remain in file

**Step 4: Test modified code**
- Ensure program can compile normally
- Test if functionality works correctly

**Step 5: Mark conflict as resolved**
```bash
# Add resolved file to staging area
git add file-path
# Example:
git add MainActivity.java
```

**Step 6: Complete merge**
```bash
git commit -m "Resolve merge conflict: Integrate both sides' changes"
```

**Step 7: Push to remote**
```bash
git push
```

### 9.4 Resolve Conflicts Using VS Code

**VS Code provides visual conflict resolution tools:**

**Step 1: Open file with conflicts**
- VS Code will automatically detect conflicts
- Conflict areas will be marked with different colors

**Step 2: Use VS Code's conflict resolution tools**
- Above conflict area, you'll see three options:
  - **Accept Current Change**: Keep your changes
  - **Accept Incoming Change**: Keep others' changes
  - **Accept Both Changes**: Keep both sides' changes

**Step 3: Click selected option**
- VS Code will automatically remove conflict markers and apply your choice

**Step 4: Manually adjust (if needed)**
- If choosing "Accept Both Changes", may need to manually adjust code logic

**Step 5: Save file**

**Step 6: Mark as resolved**
```bash
git add file-path
git commit -m "Resolve merge conflict"
git push
```

### 9.5 Steps After Resolving Conflicts

**Step 1: Confirm all conflicts are resolved**
```bash
git status
```
Should no longer display "Unmerged paths"

**Step 2: Test program**
- Compile program
- Run tests
- Ensure functionality works correctly

**Step 3: Commit merge**
```bash
git commit -m "Resolve merge conflict: Describe how it was resolved"
```

**Step 4: Push to remote**
```bash
git push
```

**If push fails:**
- Remote may have new changes
- Pull first: `git pull`
- If new conflicts exist, repeat resolution process
- Then push again: `git push`

---

## 10. Common Git Commands Quick Reference

### 10.1 Status Query Commands

```bash
# View current status
git status

# View simplified status
git status -s

# View current branch
git branch

# View all branches (including remote)
git branch -a

# View commit history (simplified)
git log --oneline

# View commit history (detailed)
git log

# View commit history (graphical)
git log --graph --oneline --all
```

### 10.2 Branch Operation Commands

```bash
# Create new branch
git branch branch-name

# Create and switch to new branch
git checkout -b branch-name

# Switch branch
git checkout branch-name

# Delete local branch
git branch -d branch-name

# Force delete local branch
git branch -D branch-name

# Delete remote branch
git push origin --delete branch-name

# View remote branches
git branch -r
```

### 10.3 Commit Operation Commands

```bash
# View change content
git diff

# View specific file's changes
git diff file-path

# Add all changes to staging area
git add .

# Add specific file
git add file-path

# Add specific directory
git add directory-path/

# Commit changes
git commit -m "Commit message"

# Modify last commit's message
git commit --amend -m "New commit message"

# Add changes to last commit
git add .
git commit --amend --no-edit
```

### 10.4 Remote Operation Commands

```bash
# View remote repository
git remote -v

# Pull remote changes
git pull

# Pull specific branch
git pull origin branch-name

# Push changes to remote
git push

# Push specific branch
git push origin branch-name

# Push and set upstream branch
git push -u origin branch-name

# Fetch remote changes (no merge)
git fetch

# Fetch all remote branches
git fetch --all
```

### 10.5 History Query Commands

```bash
# View commit history
git log

# View specific file's history
git log -- file-path

# View specific commit's changes
git show commit-hash

# View differences between two commits
git diff commit-hash1 commit-hash2

# View differences with previous version
git diff HEAD~1

# View specific file's change history
git log -p -- file-path
```

---

## 11. Common Issues and Solutions

### 11.1 Cannot Push Changes

**Issue:** Error occurs when executing `git push`

**Possible causes and solutions:**

**Cause A: Remote has new changes, you didn't pull first**
```bash
# Solution: Pull first then push
git pull origin branch-name
# If conflicts occur, resolve conflicts then
git push
```

**Cause B: No upstream branch set**
```bash
# Solution: Set upstream branch
git push -u origin branch-name
```

**Cause C: No permission**
- Confirm you've been added as Collaborator
- Or confirm you have write permission

**Cause D: Authentication issue**
```bash
# Reset authentication
git config --global credential.helper store
# Next time you push, enter username and password, will remember automatically
```

### 11.2 Forgot to Switch Branch Before Starting Development

**Issue:** Started development directly on main branch, forgot to create new branch

**Solution:**

**Step 1: Don't commit! View changes first**
```bash
git status
```

**Step 2: Stash current changes**
```bash
git stash
# or
git stash save "Description of changes"
```

**Step 3: Create new branch**
```bash
git checkout -b new-branch-name
```

**Step 4: Restore changes**
```bash
git stash pop
```

**Step 5: Continue development and commit**
```bash
git add .
git commit -m "Your changes"
git push -u origin new-branch-name
```

### 11.3 Committed Wrong Changes

**Scenario A: Commit message is wrong (not pushed yet)**
```bash
# Modify last commit's message
git commit --amend -m "Correct commit message"
```

**Scenario B: Missed some files (not pushed yet)**
```bash
# Add missed files
git add missed-file
# Add to last commit
git commit --amend --no-edit
```

**Scenario C: Want to undo last commit (not pushed yet)**
```bash
# Keep changes, only undo commit
git reset --soft HEAD~1

# Or completely undo changes
git reset --hard HEAD~1
```

**Scenario D: Already pushed wrong commit**
- Refer to [11.5 Want to Undo Pushed Commits](#115-want-to-undo-pushed-commits)

### 11.4 Want to Undo Local Changes

**Scenario A: Not added to staging area yet (not git add yet)**
```bash
# Undo single file's changes
git checkout -- file-path

# Undo all changes
git checkout -- .
```

**Scenario B: Already added to staging area but not committed**
```bash
# Remove from staging area, but keep file changes
git reset HEAD file-path

# Then undo file changes
git checkout -- file-path
```

**Scenario C: Want to temporarily store changes, handle later**
```bash
# Stash changes
git stash

# View stashed changes
git stash list

# Restore stashed changes
git stash pop

# Or restore without deleting stash
git stash apply
```

### 11.5 Want to Undo Pushed Commits

**⚠️ Warning: Undoing pushed commits will affect others, use with caution!**

**Scenario A: Last commit is wrong, want to completely remove**

**Method 1: Use revert (recommended, safe)**
```bash
# Create a new commit to undo previous changes
git revert HEAD
git push
```

**Method 2: Use reset (dangerous, rewrites history)**
```bash
# Only use on personal branches, don't use on main branch!
git reset --hard HEAD~1
git push --force
```

**Scenario B: Want to modify pushed commit message**

**⚠️ Only do this on personal branches!**
```bash
git commit --amend -m "New commit message"
git push --force
```

**Scenario C: Want to return to specific commit**

```bash
# View commit history, find target commit's hash
git log --oneline

# Return to that commit (keep changes)
git reset --soft commit-hash

# Or completely return to that commit (discard changes)
git reset --hard commit-hash

# Force push (dangerous!)
git push --force
```

**Important reminders:**
- `--force` will force overwrite remote history, may affect others
- If others have already continued development based on your commits, don't use `--force`
- On main branch, never use `--force`
- If must use, notify all team members first

---

## 12. Best Practices

### 12.1 Commit Message Standards

**Good commit message format:**

```
Type: Brief description (within 50 characters)

Detailed explanation (optional):
- Why this change was made
- How it was implemented
- Related issues or discussions
```

**Type examples:**
- `Add:` - New feature
- `Modify:` - Modify existing feature
- `Fix:` - Bug fix
- `Optimize:` - Performance optimization
- `Refactor:` - Code refactoring
- `Docs:` - Documentation update
- `Test:` - Test related
- `Style:` - UI/style changes

**Example:**
```
Add: Zero-point calibration feature

- Implement manual trigger calibration process
- Calibration data stored in SharedPreferences
- All subsequent data automatically applies calibration values
```

### 12.2 Branch Naming Standards

**Recommended naming format:**

```
type/feature-description-your-name
```

**Types:**
- `feature/` - New feature
- `fix/` - Bug fix
- `ml/` - Machine learning related
- `docs/` - Documentation related
- `refactor/` - Refactoring
- `test/` - Testing

**Examples:**
```
feature/zero-point-calibration-john
fix/ble-connection-issue-mary
ml/model-training-v2-tom
docs/update-readme-alice
```

### 12.3 Development Frequency Recommendations

**Recommended development rhythm:**

1. **Before starting work each day:**
   ```bash
   git checkout main
   git pull origin main
   git checkout your-branch
   git merge main  # Sync latest changes
   ```

2. **After completing a small feature:**
   ```bash
   git add .
   git commit -m "Clear description"
   git push
   ```

3. **Before ending work each day:**
   ```bash
   # Ensure all changes are committed and pushed
   git status
   git push
   ```

4. **Weekly:**
   - Check if there are PRs that need merging
   - Clean up merged branches
   - Sync latest changes from main branch

### 12.4 Collaborative Development Notes

**Communication first:**
- Before starting major changes, discuss with team members first
- If it will affect others' code, notify first
- When encountering problems, seek help promptly

**Small step commits:**
- Don't accumulate many changes before committing
- Each commit should be a complete small feature or fix
- Makes it easier to backtrack when problems occur

**Test before committing:**
- Ensure program can compile normally
- Test if basic functionality works correctly
- Don't commit code that can't compile

**Sync promptly:**
- Frequently pull latest changes from main branch
- Avoid diverging too much from others' changes
- Resolve conflicts promptly when discovered

**Make good use of Pull Request:**
- Even for small changes, recommend creating PR
- PR description should clearly explain change content
- Actively participate in code reviews

**Protect main branch:**
- Don't develop directly on main branch
- Important changes must go through PR and review
- Main branch should maintain stable and usable state

---

## 📝 Appendix: Quick Reference

### Daily Development Workflow (Independent Branch)

```bash
# 1. Start work
git checkout main
git pull origin main
git checkout your-branch
git merge main

# 2. Develop
# ... modify files ...

# 3. Commit changes
git add .
git commit -m "Describe changes"
git push

# 4. End work
git status  # Confirm no uncommitted changes
```

### Daily Development Workflow (Collaborative Development)

```bash
# 1. Start work
git checkout main
git pull origin main
git checkout feature/your-feature
git merge main

# 2. Develop
# ... modify files ...

# 3. Commit changes
git add .
git commit -m "Describe changes"
git push

# 4. Create/Update Pull Request
# Go to GitHub to create or update PR

# 5. Wait for review and merge
```

### Emergency Handling

**Forgot to switch branch before starting development:**
```bash
git stash
git checkout -b correct-branch
git stash pop
```

**Committed wrong changes (not pushed yet):**
```bash
git commit --amend -m "Correct message"
```

**Want to undo local changes:**
```bash
git checkout -- file-path
```

**Encounter conflicts:**
```bash
# 1. View conflict files
git status

# 2. Manually resolve conflicts

# 3. Mark as resolved
git add file-path

# 4. Complete merge
git commit
```

---

## 🎓 Conclusion

This guide covers various scenarios of GitHub collaborative development. Remember:

1. **Don't be afraid of mistakes** - Git can undo most operations
2. **Commit frequently** - Small step commits are safer than large changes
3. **Sync promptly** - Avoid diverging too much from others
4. **Make good use of branches** - Protect main branch stability
5. **Communicate actively** - Discuss promptly when encountering problems

Happy coding! 🏸

---

**Last Updated:** 2024
**Maintainer:** DIID Term Project Team

