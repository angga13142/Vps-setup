# Pre-commit Interface Contract

**Feature**: Development Improvements & Quality Assurance  
**Date**: 2025-01-27

## Hook Configuration

### Configuration File

**Location**: `.pre-commit-config.yaml` (repository root)  
**Format**: YAML  
**Schema**: pre-commit framework schema

### Hook Definitions

```yaml
repos:
  - repo: https://github.com/koalaman/shellcheck-precommit
    rev: v0.9.0
    hooks:
      - id: shellcheck
        args: ['--severity=error']
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
```

### Required Hooks

1. **ShellCheck**: Lint all `.sh` files with error severity
2. **Trailing Whitespace**: Remove trailing whitespace
3. **End of File Fixer**: Ensure files end with newline

---

## Hook Execution

### Execution Order

1. Trailing whitespace fixer (automatic fix)
2. End of file fixer (automatic fix)
3. ShellCheck (validation only, no auto-fix)

### Execution Context

- Runs automatically on `git commit`
- Can be run manually: `pre-commit run --all-files`
- Runs on staged files by default
- Can run on all files with `--all-files` flag

### Performance Requirements

- All hooks must complete in < 10 seconds
- If hooks exceed time limit, consider optimizing or splitting

---

## Error Handling

### Hook Failure

**Behavior**:
- Commit is blocked
- Error messages displayed to developer
- Developer must fix issues before committing

### Error Message Format

```
[hook-name]: Failed
[file:line:column] [SC####] [severity] [message]
```

Example:
```
shellcheck: Failed
scripts/setup-workstation.sh:42:5 SC2086: Double quote to prevent globbing and word splitting.
```

### Recovery Procedures

**Pre-commit Hook Failure Recovery**:
1. Developer receives error message with file:line:column and SC code
2. Developer fixes issues in code:
   - Review error message for specific issue
   - Fix code according to ShellCheck recommendations
   - Re-run `pre-commit run --all-files` to verify fixes
3. Developer commits again (hook will re-run automatically)
4. If bypass needed (emergency only):
   - Use `git commit --no-verify` flag
   - Must include justification in commit message: `[SKIP HOOKS] <reason>`
   - Bypass should be rare and documented

### Bypass Mechanism

**When to Use**:
- Emergency hotfixes (documented in commit message)
- Pre-commit hook configuration issues (temporary)
- Known false positives (with issue reference)

**Requirements**:
- Must include `[SKIP HOOKS]` tag in commit message
- Must include justification for bypass
- Should be followed by PR that fixes the issue
- Should be rare (<1% of commits)

**Format**:
```
[SKIP HOOKS] Emergency hotfix for production issue #123
```

---

## Reliability Requirements

- **Success Rate**: 99% (allows for rare environment issues)
- **Performance**: < 10 seconds execution time
- **Accuracy**: Zero false positives for blocking errors

---

## Hook Installation

### Initial Setup

```bash
# Install pre-commit framework
pip3 install --user pre-commit

# Install hooks
pre-commit install
```

### Verification

```bash
# Test hooks manually
pre-commit run --all-files

# Verify hooks are installed
pre-commit --version
```

---

## Maintenance

### Hook Updates

- Review hook updates monthly
- Test updates in feature branch before merging
- Pin hook versions for stability
- Document any hook changes in CHANGELOG.md

### Configuration Changes

- All changes must be reviewed in PR
- Changes must not break existing workflow
- Performance impact must be assessed
