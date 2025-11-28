# CI/CD Setup and Testing Guide

This guide provides step-by-step instructions for completing the CI/CD setup tasks (T064-T067). You can use either **GitHub CLI (`gh`)** for automation or **GitHub UI** for manual setup.

## Prerequisites

- GitHub repository access (admin or maintainer permissions)
- CI/CD workflow file already created (`.github/workflows/ci.yml`)
- At least one successful workflow run (for status checks to appear)
- **For CLI method**: GitHub CLI (`gh`) installed and authenticated
  ```bash
  # Check if gh is installed
  gh --version

  # Authenticate if needed
  gh auth login
  ```

## Task T064: Configure Required Status Checks

**Goal**: Configure GitHub repository settings to require CI/CD status checks before merging pull requests.

### Method 1: Using GitHub CLI (`gh`) - Recommended

**Prerequisites**: Ensure you're authenticated and in the repository directory:
```bash
gh auth status  # Verify authentication
```

**Steps**:

1. **Get default branch name**:
   ```bash
   DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
   echo "Default branch: $DEFAULT_BRANCH"
   ```

2. **Configure branch protection with required status checks**:
   ```bash
   # Set branch protection rule
   gh api repos/:owner/:repo/branches/$DEFAULT_BRANCH/protection \
     --method PUT \
     --field required_status_checks='{"strict":true,"contexts":["lint","test"]}' \
     --field enforce_admins=true \
     --field required_pull_request_reviews='{"required_approving_review_count":0}' \
     --field restrictions=null
   ```

   **Alternative**: If the above doesn't work, use the interactive command:
   ```bash
   gh api repos/:owner/:repo/branches/$DEFAULT_BRANCH/protection \
     --method PUT \
     -H "Accept: application/vnd.github+json" \
     -f required_status_checks='{"strict":true,"contexts":["lint","test"]}' \
     -f enforce_admins=true \
     -f required_pull_request_reviews='{"required_approving_review_count":0}'
   ```

3. **Verify the protection rule**:
   ```bash
   gh api repos/:owner/:repo/branches/$DEFAULT_BRANCH/protection \
     --jq '.required_status_checks.contexts'
   ```

   Expected output:
   ```json
   ["lint", "test"]
   ```

**Note**: Replace `:owner/:repo` with your repository owner and name, or use:
```bash
# Auto-detect from current directory
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
gh api repos/$REPO/branches/$DEFAULT_BRANCH/protection ...
```

### Method 2: Using GitHub UI

1. **Navigate to Repository Settings**:
   - Go to your GitHub repository
   - Click on **Settings** (top menu bar)
   - In the left sidebar, click **Branches**

2. **Add Branch Protection Rule**:
   - Click **Add rule** or **Add branch protection rule**
   - In the **Branch name pattern** field, enter:
     - `master` (or `main` if that's your default branch)
     - Or use pattern: `*` to protect all branches

3. **Configure Protection Settings**:
   - ✅ Check **Require a pull request before merging**
   - ✅ Check **Require status checks to pass before merging**
   - ✅ Check **Require branches to be up to date before merging**

4. **Select Required Status Checks**:
   - In the **Status checks that are required** section, check:
     - ✅ `lint` (Lint (ShellCheck))
     - ✅ `test` (Test (bats))
   - **Note**: These checks will only appear after at least one workflow run has completed

5. **Save the Rule**:
   - Click **Create** or **Save changes**
   - Confirm the rule is created

### Verification

**Using GitHub CLI**:
```bash
# Check branch protection status
gh api repos/:owner/:repo/branches/$DEFAULT_BRANCH/protection \
  --jq '{required_status_checks: .required_status_checks.contexts, enforce_admins: .enforce_admins.enabled}'

# List all protected branches
gh api repos/:owner/:repo/branches --jq '.[] | select(.protected == true) | .name'
```

**Using GitHub UI**:
- Go to **Settings** → **Branches**
- Verify the rule appears in the list
- Check that `lint` and `test` are listed as required checks

### Troubleshooting

**Issue**: Status checks don't appear in the list
- **Solution**: Run the workflow at least once by pushing code or creating a PR. Status checks only appear after they've run at least once.

**Issue**: Can't find "Require status checks" option
- **Solution**: Ensure you have admin or maintainer permissions on the repository.

---

## Task T065: Test CI/CD Workflow by Pushing Code

**Goal**: Verify that the CI/CD workflow runs automatically when code is pushed to a branch.

### Steps

1. **Create a Test Branch**:
   ```bash
   git checkout -b test/ci-workflow
   ```

2. **Make a Small Change**:
   ```bash
   # Add a comment or update documentation
   echo "# CI/CD Test" >> README.md
   git add README.md
   git commit -m "test: Verify CI/CD workflow on push"
   ```

3. **Push to Remote**:
   ```bash
   git push origin test/ci-workflow
   ```

4. **Verify Workflow Runs**:

   **Using GitHub CLI**:
   ```bash
   # List recent workflow runs
   gh run list --workflow=ci.yml --limit 5

   # Watch the latest workflow run
   gh run watch

   # Get detailed status of latest run
   gh run view --web  # Opens in browser
   # Or get status in terminal
   gh run view --json status,conclusion,jobs --jq '.'
   ```

   **Using GitHub UI**:
   - Go to GitHub repository
   - Click on **Actions** tab
   - You should see a new workflow run with:
     - Workflow name: **CI**
     - Trigger: **push**
     - Status: Running or completed

5. **Check Workflow Status**:

   **Using GitHub CLI**:
   ```bash
   # Get latest run ID
   RUN_ID=$(gh run list --workflow=ci.yml --limit 1 --json databaseId -q '.[0].databaseId')

   # View run details
   gh run view $RUN_ID

   # View jobs in the run
   gh run view $RUN_ID --log

   # Check specific job status
   gh run view $RUN_ID --json jobs --jq '.jobs[] | {name: .name, status: .status, conclusion: .conclusion}'
   ```

   **Using GitHub UI**:
   - Click on the workflow run
   - Verify both jobs run:
     - ✅ `lint` job completes successfully
     - ✅ `test` job completes successfully (after lint)
   - Check that jobs show green checkmarks (✅)

### Expected Results

- ✅ Workflow triggers automatically on push
- ✅ Both `lint` and `test` jobs run
- ✅ All jobs complete successfully
- ✅ Workflow run shows green checkmarks

### Troubleshooting

**Issue**: Workflow doesn't trigger
- **Solution**:
  - Check branch name matches trigger pattern in `.github/workflows/ci.yml`
  - Verify workflow file syntax is correct
  - Check GitHub Actions is enabled for the repository

**Issue**: Jobs fail
- **Solution**:
  - Click on failed job to see error messages
  - Fix issues locally and push again
  - Review logs in the Actions tab

---

## Task T066: Test CI/CD Workflow by Creating PR

**Goal**: Verify that status checks appear on pull requests and block merging when checks fail.

### Steps

1. **Ensure Test Branch Exists** (from T065):
   ```bash
   git checkout test/ci-workflow
   ```

2. **Create Pull Request**:

   **Using GitHub CLI**:
   ```bash
   # Get default branch
   DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)

   # Create PR
   gh pr create \
     --base "$DEFAULT_BRANCH" \
     --head test/ci-workflow \
     --title "test: Verify CI/CD workflow on PR" \
     --body "Testing CI/CD workflow to verify status checks appear on PRs."

   # Note the PR number from output
   ```

   **Using GitHub UI**:
   - Go to GitHub repository
   - Click **Pull requests** tab
   - Click **New pull request**
   - Select:
     - **Base**: `master` (or `main`)
     - **Compare**: `test/ci-workflow`
   - Fill in PR title and description
   - Click **Create pull request**

3. **Verify Status Checks Appear**:

   **Using GitHub CLI**:
   ```bash
   # Get PR number (if not noted)
   PR_NUMBER=$(gh pr list --head test/ci-workflow --json number -q '.[0].number')

   # View PR status checks
   gh pr checks $PR_NUMBER

   # Watch checks in real-time
   gh pr checks $PR_NUMBER --watch

   # Get detailed check status
   gh api repos/:owner/:repo/pulls/$PR_NUMBER --jq '.statuses_url' | xargs gh api --jq '.[] | {name: .context, state: .state, description: .description}'
   ```

   **Using GitHub UI**:
   - On the PR page, scroll down to see **Checks** section
   - You should see:
     - ✅ `lint` (Lint (ShellCheck)) - Running or completed
     - ✅ `test` (Test (bats)) - Running or completed
   - Status checks show as:
     - ⏳ Yellow circle: In progress
     - ✅ Green checkmark: Passed
     - ❌ Red X: Failed

4. **Wait for Checks to Complete**:

   **Using GitHub CLI**:
   ```bash
   # Wait for all checks to complete
   gh pr checks $PR_NUMBER --watch

   # Check if PR is mergeable
   gh pr view $PR_NUMBER --json mergeable,mergeStateStatus --jq '{mergeable: .mergeable, status: .mergeStateStatus}'
   ```

   **Using GitHub UI**:
   - Wait for both checks to finish
   - Verify both show green checkmarks (✅)

5. **Verify Merge Blocking** (if T064 is configured):

   **Using GitHub CLI**:
   ```bash
   # Check mergeability status
   gh pr view $PR_NUMBER --json mergeable,mergeStateStatus,statusCheckRollup --jq '{
     mergeable: .mergeable,
     mergeStateStatus: .mergeStateStatus,
     checks: .statusCheckRollup.nodes[] | {name: .name, state: .state, conclusion: .conclusion}
   }'

   # If checks are required, this will show mergeable: false until checks pass
   ```

   **Using GitHub UI**:
   - If branch protection is enabled, you should see:
     - "Merging is blocked" message
     - List of required checks that must pass
   - After all checks pass, merge button should become available

### Expected Results

- ✅ Status checks appear on PR page
- ✅ Both `lint` and `test` checks run
- ✅ Checks show green checkmarks when passing
- ✅ Merge is blocked until checks pass (if T064 configured)

### Troubleshooting

**Issue**: Status checks don't appear on PR
- **Solution**:
  - Ensure workflow has run at least once
  - Check that PR is targeting a protected branch
  - Verify workflow triggers on `pull_request` event

**Issue**: Merge button is available even when checks are running
- **Solution**: This is expected if branch protection (T064) is not yet configured. Configure T064 first.

---

## Task T067: Test Merge Blocking by Introducing Test Failure

**Goal**: Verify that merge is blocked when CI/CD checks fail.

### Prerequisites

- T064 must be completed (branch protection configured)
- T065 and T066 must be completed (workflow tested)

### Steps

1. **Create a Branch with Intentional Failure**:
   ```bash
   git checkout -b test/merge-blocking
   ```

2. **Introduce a ShellCheck Error**:
   ```bash
   # Create a test file with a ShellCheck error
   cat > test-failure.sh << 'EOF'
   #!/bin/bash
   # Intentional ShellCheck error: unquoted variable
   VAR=test
   echo $VAR  # SC2086: Double quote to prevent globbing
   EOF

   git add test-failure.sh
   git commit -m "test: Introduce ShellCheck error to test merge blocking"
   git push origin test/merge-blocking
   ```

   **Alternative**: Introduce a test failure:
   ```bash
   # Modify a test to fail
   # Edit tests/unit/test_user_creation.bats
   # Add: @test "intentional failure" { assert_failure }  # This will fail
   ```

3. **Create Pull Request**:

   **Using GitHub CLI**:
   ```bash
   DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)

   gh pr create \
     --base "$DEFAULT_BRANCH" \
     --head test/merge-blocking \
     --title "test: Verify merge blocking on failed checks" \
     --body "Testing merge blocking when CI/CD checks fail."

   PR_NUMBER=$(gh pr list --head test/merge-blocking --json number -q '.[0].number')
   ```

   **Using GitHub UI**:
   - Go to GitHub repository
   - Create PR from `test/merge-blocking` to `master`/`main`

4. **Verify Checks Fail**:

   **Using GitHub CLI**:
   ```bash
   # Watch checks and wait for failure
   gh pr checks $PR_NUMBER --watch

   # View failed checks
   gh pr checks $PR_NUMBER | grep -i "failure\|error"

   # Get detailed check status
   gh api repos/:owner/:repo/pulls/$PR_NUMBER --jq '.statuses_url' | xargs gh api --jq '.[] | select(.state == "failure") | {name: .context, state: .state, description: .description}'

   # View workflow run logs for failed job
   gh run list --workflow=ci.yml --limit 1
   RUN_ID=$(gh run list --workflow=ci.yml --limit 1 --json databaseId -q '.[0].databaseId')
   gh run view $RUN_ID --log-failed
   ```

   **Using GitHub UI**:
   - On PR page, check **Checks** section
   - One or more checks should show:
     - ❌ Red X: Failed
     - Error message visible when clicking on failed check

5. **Verify Merge is Blocked**:

   **Using GitHub CLI**:
   ```bash
   # Check mergeability (should be false)
   gh pr view $PR_NUMBER --json mergeable,mergeStateStatus --jq '{
     mergeable: .mergeable,
     mergeStateStatus: .mergeStateStatus,
     message: "Merge should be blocked when checks fail"
   }'

   # Expected output: mergeable: false

   # View blocking reasons
   gh pr view $PR_NUMBER --json mergeStateStatus,statusCheckRollup --jq '{
     status: .mergeStateStatus,
     failedChecks: [.statusCheckRollup.nodes[] | select(.conclusion == "FAILURE") | .name]
   }'
   ```

   **Using GitHub UI**:
   - Scroll to bottom of PR page
   - You should see:
     - "Merging is blocked" message
     - List of failed checks
     - Merge button is disabled/grayed out
   - Message should say: "Required status checks must pass"

6. **Fix the Issue**:
   ```bash
   # Remove the test file or fix the error
   git rm test-failure.sh
   git commit -m "fix: Remove test failure file"
   git push origin test/merge-blocking
   ```

7. **Verify Merge is Allowed**:

   **Using GitHub CLI**:
   ```bash
   # Watch checks re-run
   gh pr checks $PR_NUMBER --watch

   # Verify mergeability after fix
   gh pr view $PR_NUMBER --json mergeable,mergeStateStatus --jq '{
     mergeable: .mergeable,
     mergeStateStatus: .mergeStateStatus,
     message: "Merge should be allowed when all checks pass"
   }'

   # Expected output: mergeable: true, mergeStateStatus: "CLEAN"
   ```

   **Using GitHub UI**:
   - After pushing fix, checks should re-run
   - When all checks pass, merge button should become available
   - "Merging is blocked" message should disappear

### Expected Results

- ✅ CI/CD checks fail when error is introduced
- ✅ Merge button is disabled when checks fail
- ✅ "Merging is blocked" message appears
- ✅ After fixing error, checks pass and merge is allowed

### Troubleshooting

**Issue**: Merge is not blocked even when checks fail
- **Solution**:
  - Verify T064 is completed (branch protection configured)
  - Check that required status checks are selected in branch protection rules
  - Ensure you're testing on a protected branch

**Issue**: Can't see failed check details
- **Solution**:
  - Click on the failed check (red X)
  - Review logs in the Actions tab
  - Check error messages for details

---

## Verification Checklist

After completing all tasks (T064-T067), verify:

- [ ] Branch protection rule is configured
- [ ] Required status checks (`lint`, `test`) are selected
- [ ] Workflow runs automatically on push
- [ ] Workflow runs automatically on PR
- [ ] Status checks appear on PR page
- [ ] Merge is blocked when checks fail
- [ ] Merge is allowed when checks pass
- [ ] All workflow jobs complete successfully

## Summary

These tasks ensure that:
1. **T064**: CI/CD checks are required before merging (branch protection)
2. **T065**: Workflow runs automatically on code push
3. **T066**: Status checks appear on pull requests
4. **T067**: Merge is blocked when checks fail

All tasks work together to provide automated quality gates that protect the main branch from broken code.

---

## Quick Reference: GitHub CLI Commands

### Common `gh` Commands for CI/CD Tasks

```bash
# Authentication
gh auth login
gh auth status

# Repository info
gh repo view --json defaultBranchRef -q .defaultBranchRef.name

# Branch protection
gh api repos/:owner/:repo/branches/BRANCH/protection --method PUT \
  -f required_status_checks='{"strict":true,"contexts":["lint","test"]}' \
  -f enforce_admins=true

# Workflow runs
gh run list --workflow=ci.yml
gh run watch
gh run view RUN_ID

# Pull requests
gh pr create --base BRANCH --head BRANCH --title TITLE
gh pr checks PR_NUMBER
gh pr view PR_NUMBER --json mergeable,mergeStateStatus
gh pr checks PR_NUMBER --watch
```

### Helper Script

You can create a helper script to automate T064:

```bash
#!/bin/bash
# configure-branch-protection.sh

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)

echo "Configuring branch protection for $REPO:$DEFAULT_BRANCH"

gh api repos/$REPO/branches/$DEFAULT_BRANCH/protection \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  -f required_status_checks='{"strict":true,"contexts":["lint","test"]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"required_approving_review_count":0}'

echo "✅ Branch protection configured"
gh api repos/$REPO/branches/$DEFAULT_BRANCH/protection \
  --jq '.required_status_checks.contexts'
```

**Note**: You can use either **GitHub CLI (`gh`)** for automation or **GitHub UI** for manual setup. The CLI method is recommended for faster setup and easier automation.
