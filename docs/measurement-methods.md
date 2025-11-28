# Measurement Methods for Success Criteria

This document defines how each success criterion (SC-001 through SC-010) is measured and validated. All measurement methods are objective and verifiable.

## SC-001: 100% of Bash scripts pass ShellCheck linting

**Target**: 100% of Bash scripts pass ShellCheck with zero errors

**Measurement Method**:
1. Count total `.sh` files in repository (excluding `.git/` and `tests/helpers/`)
2. Run ShellCheck on all files: `find . -name "*.sh" -type f -not -path "./.git/*" -not -path "./tests/helpers/*" -exec shellcheck {} \;`
3. Verify zero errors reported
4. Tool: ShellCheck exit code (0 = pass, non-zero = fail)

**Calculation**:
```
Pass Rate = (files with zero errors / total .sh files) × 100%
Target: 100% (all files must pass)
```

**Verification**:
- CI/CD pipeline runs ShellCheck on all files
- Exit code 0 = all files pass
- Exit code non-zero = one or more files have errors

**Status**: ✅ Measurable via ShellCheck exit code

---

## SC-002: Test suite covers at least 80% of critical functions

**Target**: ≥80% of 15 critical functions have test coverage

**Measurement Method**:
1. List all 15 critical functions from spec.md
2. Identify which functions have test cases in `tests/unit/` or `tests/integration/`
3. Count tested functions (functions with at least one test case)
4. Calculate: `(tested functions / 15) × 100%`
5. Tool: Manual review or automated tool (e.g., `bats-coverage`)

**Calculation**:
```
Coverage % = (tested critical functions / total critical functions) × 100%
Target: ≥80% (at least 12 out of 15 functions)
```

**Critical Functions** (15 total):
1. `create_user()`
2. `setup_docker_repository()`
3. `install_docker()`
4. `configure_xfce_mobile()`
5. `configure_shell()`
6. `get_user_inputs()`
7. `system_prep()`
8. `finalize()`
9. `setup_desktop_mobile()`
10. `setup_dev_stack()`
11. `install_nvm_nodejs()`
12. `verify_python()`
13. `verify_installation()`
14. `log()`
15. `check_debian_version()`

**Verification**:
- Review test files to identify covered functions
- Manual count or automated coverage tool
- Document coverage percentage in test results

**Status**: ✅ Measurable via manual review or coverage tool

---

## SC-003: All public functions have complete documentation

**Target**: 100% of public functions have documentation with all required fields

**Measurement Method**:
1. List all public functions from source code (functions called from `main()` or exported)
2. Verify each function has documentation block with:
   - Purpose/description
   - Input parameters
   - Return values
   - Side effects
   - Idempotency notes
3. Tool: Manual review or automated doc parser

**Calculation**:
```
Documentation Coverage = (functions with complete docs / total public functions) × 100%
Target: 100% (all public functions must be documented)
```

**Required Documentation Fields**:
- Purpose: What the function does
- Inputs: Parameters and their types/constraints
- Outputs: Return values and side effects
- Idempotency: Whether function is safe to run multiple times

**Verification**:
- Review function comments in `scripts/setup-workstation.sh`
- Check for all required fields
- Document any missing fields

**Status**: ✅ Measurable via manual review or doc parser

---

## SC-004: README enables 90% first-attempt success rate

**Target**: ≥90% of new users successfully install and run script on first attempt

**Measurement Method**:
1. Track new user installations via survey or analytics
2. Count successful first attempts (users who complete installation without errors)
3. Count total first attempts
4. Calculate: `(successful first attempts / total first attempts) × 100%`
5. Tool: User survey, GitHub analytics, or installation logs

**Calculation**:
```
Success Rate = (successful first attempts / total first attempts) × 100%
Target: ≥90%
```

**Data Collection**:
- GitHub repository analytics (clones, stars)
- User surveys (optional)
- Issue tracker (installation failures)
- Installation logs (if available)

**Verification**:
- Monitor GitHub Issues for installation problems
- Track installation success vs failures
- Update README based on common failure points

**Status**: ✅ Measurable via user feedback and analytics

---

## SC-005: CI/CD pipeline runs successfully on 100% of pushes and pull requests

**Target**: 100% of CI/CD pipeline runs complete successfully

**Measurement Method**:
1. Monitor GitHub Actions workflow runs
2. Count successful runs (all jobs pass)
3. Count total runs (push + pull_request events)
4. Calculate: `(successful runs / total runs) × 100%`
5. Tool: GitHub Actions API or workflow run history

**Calculation**:
```
Success Rate = (successful runs / total runs) × 100%
Target: 100%
```

**Verification**:
- Check GitHub Actions workflow runs
- Review workflow run history
- Identify and fix any recurring failures
- Monitor workflow execution time

**Status**: ✅ Measurable via GitHub Actions API

---

## SC-006: Failed CI checks block 100% of merges

**Target**: 100% of merge attempts are blocked when CI checks fail

**Measurement Method**:
1. Verify branch protection rules require status checks
2. Monitor merge attempts blocked by failed checks
3. Count blocked merges due to failed CI checks
4. Count total merge attempts with failed checks
5. Calculate: `(blocked merges / total attempts with failed checks) × 100%`
6. Tool: GitHub branch protection settings, merge logs

**Calculation**:
```
Blocking Rate = (blocked merges / total attempts with failed checks) × 100%
Target: 100%
```

**Verification**:
- Check branch protection rules in GitHub settings
- Verify required status checks are configured
- Test merge blocking with intentional failures
- Monitor merge attempts and blocking behavior

**Status**: ✅ Measurable via GitHub branch protection settings

---

## SC-007: Error messages include actionable context in 100% of failure cases

**Target**: 100% of error messages include required context fields

**Measurement Method**:
1. Review all error messages in codebase
2. Verify each error message includes:
   - Function name
   - Line number (if applicable)
   - Variable values (relevant context)
   - Error type
   - Recovery suggestion
3. Tool: Manual review or automated parsing

**Calculation**:
```
Context Coverage = (errors with full context / total errors) × 100%
Target: 100%
```

**Required Context Fields**:
- Function name: Where the error occurred
- Line number: Location in code (if applicable)
- Variable values: Relevant variable states
- Error type: Category of error
- Recovery suggestion: Actionable steps to resolve

**Verification**:
- Review error messages in `scripts/setup-workstation.sh`
- Check log files for error message format
- Test error scenarios to verify context inclusion

**Status**: ✅ Measurable via code review and log analysis

---

## SC-008: Logging captures all major operations with appropriate log levels

**Target**: All major operations have log entries with appropriate levels

**Measurement Method**:
1. Review log files
2. Verify all major operations have log entries
3. Verify log levels are appropriate:
   - INFO: Normal operations
   - WARNING: Recoverable issues
   - ERROR: Failures requiring attention
   - DEBUG: Detailed debugging (optional)
4. Tool: Manual review or log analysis tool

**Calculation**:
```
Logging Coverage = (operations with logs / total major operations) × 100%
Target: 100%
```

**Major Operations** (must be logged):
- All function calls
- All errors
- All warnings
- Major state changes (user creation, package installation, configuration)

**Verification**:
- Review log files: `/var/log/setup-workstation.log` or `~/.setup-workstation.log`
- Check for log entries for all major operations
- Verify log levels are appropriate
- Test logging during script execution

**Status**: ✅ Measurable via log file review

---

## SC-009: Troubleshooting guide resolves 80% of common user issues

**Target**: ≥80% of common user issues are resolved via troubleshooting guide

**Measurement Method**:
1. Track user support requests (GitHub Issues, discussions)
2. Identify issues covered in troubleshooting guide
3. Count issues resolved via guide (users found solution in guide)
4. Count total common issues
5. Calculate: `(resolved via guide / total common issues) × 100%`
6. Tool: GitHub Issues tracker, user feedback

**Calculation**:
```
Resolution Rate = (resolved via guide / total common issues) × 100%
Target: ≥80%
```

**Common Issues** (minimum 5 must be covered):
1. CUSTOM_PASS: unbound variable
2. Malformed stanza Docker repository error
3. Password input loop issues
4. XFCE configuration not applying
5. Script not executable
6. Debian 13 requirement error
7. Root privileges error
8. Docker installation fails
9. NVM/Node.js installation fails
10. Cannot connect via RDP

**Verification**:
- Review GitHub Issues for common problems
- Check if troubleshooting guide addresses them
- Update guide based on new common issues
- Track user feedback on guide effectiveness

**Status**: ✅ Measurable via issue tracker and user feedback

---

## SC-010: Code review time reduced by 50%

**Target**: 50% reduction in average code review time

**Measurement Method**:
1. Establish baseline: Average review time in 3 months before implementation
2. Measure review time after implementation
3. Calculate reduction: `((baseline - current) / baseline) × 100%`
4. Tool: GitHub PR review timestamps, manual tracking

**Calculation**:
```
Time Reduction = ((baseline - current) / baseline) × 100%
Target: ≥50% reduction
```

**Baseline Establishment**:
- Review PR history for 3 months before implementation
- Calculate average time from PR creation to merge approval
- Document baseline average

**Post-Implementation Measurement**:
- Track PR review times after implementation
- Calculate average review time
- Compare to baseline

**Factors Contributing to Reduction**:
- Automated quality checks catch issues early
- Pre-commit hooks prevent common errors
- CI/CD provides immediate feedback
- Clear documentation reduces questions

**Verification**:
- Track PR review times in GitHub
- Compare pre/post implementation averages
- Document contributing factors

**Status**: ✅ Measurable via PR review time tracking

---

## Summary

All success criteria (SC-001 through SC-010) have objective, verifiable measurement methods:

| SC | Criterion | Measurement Method | Status |
|----|-----------|-------------------|--------|
| SC-001 | 100% ShellCheck pass | Exit code verification | ✅ Automated |
| SC-002 | 80% test coverage | Function count / manual review | ✅ Manual/Automated |
| SC-003 | 100% function docs | Documentation review | ✅ Manual/Automated |
| SC-004 | 90% first-attempt success | User feedback / analytics | ✅ User feedback |
| SC-005 | 100% CI/CD success | GitHub Actions API | ✅ Automated |
| SC-006 | 100% merge blocking | Branch protection settings | ✅ Automated |
| SC-007 | 100% error context | Code/log review | ✅ Manual |
| SC-008 | 100% operation logging | Log file review | ✅ Manual |
| SC-009 | 80% issue resolution | Issue tracker | ✅ User feedback |
| SC-010 | 50% review time reduction | PR time tracking | ✅ Manual |

**Last Updated**: 2025-01-27  
**Version**: 1.0.0
