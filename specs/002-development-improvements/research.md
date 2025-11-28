# Research: Development Improvements & Quality Assurance

**Date**: 2025-01-27  
**Feature**: Development Improvements & Quality Assurance  
**Research Phase**: Phase 0

## Research Objectives

1. Identify best practices for Bash script linting and static analysis
2. Determine optimal testing framework for Bash scripts
3. Research CI/CD pipeline patterns for Bash projects
4. Find best practices for pre-commit hooks configuration
5. Identify documentation standards and tools

## Findings

### 1. ShellCheck - Bash Linting

**Decision**: Use ShellCheck for static analysis of all Bash scripts

**Rationale**:
- Industry-standard tool for Bash script analysis
- Detects common errors, security issues, and best practice violations
- Integrates well with pre-commit hooks and CI/CD pipelines
- Provides clear error messages with line numbers and suggestions
- Supports directives for controlling linting behavior

**Alternatives Considered**:
- Manual code review: Too time-consuming and error-prone
- Other linters: ShellCheck has the best coverage and community support

**Implementation Details**:
- Installation: Available via APT on Debian 13 (`apt install shellcheck`)
- Configuration: Use `.shellcheckrc` for project-wide settings
- Directives: Use `# shellcheck disable=SC####` for intentional violations
- Pre-commit: Use `shellcheck-precommit` hook
- CI/CD: Run on all `.sh` files, including those with shebang

**Best Practices**:
- Run ShellCheck on all Bash scripts before commits
- Use severity levels (error, warning, info) appropriately
- Document intentional violations with rationale
- Include ShellCheck in CI/CD pipeline with zero-error policy
- Use `shellcheck shell=bash` directive when needed

**References**:
- ShellCheck GitHub: https://github.com/koalaman/shellcheck
- Pre-commit integration: https://github.com/koalaman/shellcheck-precommit

---

### 2. Bats-core - Bash Testing Framework

**Decision**: Use bats-core for unit and integration testing of Bash functions

**Rationale**:
- TAP-compliant testing framework designed specifically for Bash
- Simple syntax with `@test` annotations
- Supports setup/teardown functions for test isolation
- Can test idempotency, error handling, and function behavior
- Works well in CI/CD pipelines
- Active community and good documentation

**Alternatives Considered**:
- Manual testing scripts: Not scalable or maintainable
- Other testing frameworks: Bats is the most mature and widely used for Bash

**Implementation Details**:
- Installation: Available via APT on Debian 13 (`apt install bats`)
- Test structure: `tests/` directory with `.bats` files
- Test organization: Group tests by function or feature
- Helper libraries: Use `bats-assert` and `bats-file` for common assertions
- Tags: Use `# bats test_tags=` for test filtering

**Best Practices**:
- Write tests for all critical functions (user creation, Docker setup, XFCE config)
- Test idempotency by running functions twice
- Test error handling with invalid inputs
- Use setup/teardown for test isolation
- Tag tests for selective execution (unit, integration, slow)
- Aim for 80% coverage of critical functions

**Test Structure Example**:
```bash
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # Test setup
}

teardown() {
    # Test cleanup
}

@test "function_name handles valid input" {
    run function_name "valid_input"
    assert_success
    assert_output "expected_output"
}

@test "function_name is idempotent" {
    run function_name "input"
    run function_name "input"  # Run twice
    assert_success
    # Verify no duplicate actions
}
```

**References**:
- Bats-core GitHub: https://github.com/bats-core/bats-core
- Bats documentation: https://bats-core.readthedocs.io/

---

### 3. GitHub Actions - CI/CD Pipeline

**Decision**: Use GitHub Actions for automated quality checks and testing

**Rationale**:
- Native GitHub integration with minimal setup
- Free for public repositories
- Supports matrix builds for multiple environments
- Rich ecosystem of actions
- Good documentation and community support
- Can block merges on failures

**Alternatives Considered**:
- GitLab CI: Not using GitLab
- Jenkins: Too complex for this project
- Travis CI: Less integrated with GitHub

**Implementation Details**:
- Workflow file: `.github/workflows/ci.yml`
- Triggers: Push, pull_request, workflow_dispatch
- Jobs: Lint, Test, Quality checks
- Matrix: Test on Debian 13 (Trixie)
- Artifacts: Upload test results and logs
- Status checks: Required for merge protection

**Best Practices**:
- Run linting and tests on every push and PR
- Use matrix strategy for multiple OS versions if needed
- Cache dependencies to speed up runs
- Upload artifacts for failed tests
- Use workflow commands for better log organization
- Block merges if any check fails

**Workflow Structure**:
```yaml
name: CI
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Install ShellCheck
        run: sudo apt install shellcheck
      - name: Lint scripts
        run: shellcheck scripts/*.sh

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Install bats
        run: sudo apt install bats
      - name: Run tests
        run: bats tests/
```

**References**:
- GitHub Actions docs: https://docs.github.com/en/actions
- Actions marketplace: https://github.com/marketplace?type=actions

---

### 4. Pre-commit Hooks

**Decision**: Use pre-commit framework for local quality checks

**Rationale**:
- Prevents bad code from being committed
- Consistent checks across all developers
- Easy to configure and maintain
- Supports multiple languages and tools
- Can be bypassed with `--no-verify` if needed (with caution)

**Alternatives Considered**:
- Git hooks directly: Less maintainable and harder to share
- Husky (Node.js): Not applicable for Bash project
- Manual checks: Too easy to forget

**Implementation Details**:
- Configuration: `.pre-commit-config.yaml`
- Installation: `pre-commit install`
- Hooks: ShellCheck, trailing whitespace, end-of-file fixer
- Update: `pre-commit autoupdate` to keep hooks current
- CI: Run `pre-commit run --all-files` in CI for consistency

**Best Practices**:
- Run ShellCheck on all `.sh` files
- Check for trailing whitespace and missing EOF newlines
- Verify no secrets in commits (detect-secrets)
- Format code if applicable
- Keep hooks updated regularly
- Document bypass procedure (emergency only)

**Configuration Example**:
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/koalaman/shellcheck-precommit
    rev: v0.9.0
    hooks:
      - id: shellcheck
        args: ["--severity=error"]
```

**References**:
- Pre-commit: https://pre-commit.com/
- ShellCheck pre-commit: https://github.com/koalaman/shellcheck-precommit

---

### 5. Documentation Standards

**Decision**: Use Markdown for all documentation with clear structure

**Rationale**:
- Markdown is widely supported and readable
- Easy to maintain and version control
- Can be rendered on GitHub automatically
- Supports code blocks, tables, and formatting
- No special tools required

**Documentation Structure**:
- `README.md`: Quick start, installation, usage
- `CONTRIBUTING.md`: Development workflow, coding standards
- Function docs: Inline comments with standard format
- Troubleshooting: Common issues and solutions
- Changelog: Version history and changes

**Best Practices**:
- Keep README concise but complete
- Include installation instructions
- Provide usage examples
- Document all public functions
- Include troubleshooting section
- Maintain changelog for releases
- Use clear headings and structure
- Include code examples where helpful

**Function Documentation Format**:
```bash
#######################################
# Function: function_name
# Description: Brief description of what function does
# Globals: List of global variables used
# Arguments:
#   $1: Description of first argument
#   $2: Description of second argument
# Outputs: What the function outputs (stdout/stderr)
# Returns: Exit code and meaning
# Side Effects: System changes, file modifications
# Idempotency: Yes/No - explanation
#######################################
```

---

## Technical Decisions Summary

| Decision | Technology | Rationale |
|----------|-----------|-----------|
| Linting | ShellCheck | Industry standard, best coverage |
| Testing | bats-core | TAP-compliant, Bash-specific |
| CI/CD | GitHub Actions | Native integration, free for public repos |
| Pre-commit | pre-commit framework | Easy to configure, multi-tool support |
| Documentation | Markdown | Widely supported, no special tools |

## Dependencies

- **ShellCheck**: Available in Debian 13 APT repositories
- **bats-core**: Available in Debian 13 APT repositories
- **pre-commit**: Python package, installable via pip
- **GitHub Actions**: Built-in, no installation needed

## Constraints

- All tools must work on Debian 13 (Trixie)
- Must not require root for development setup
- Should integrate with existing Git workflow
- Must be maintainable by team members

## Open Questions Resolved

✅ **Q: Which linting tool?** → ShellCheck (industry standard)  
✅ **Q: Which testing framework?** → bats-core (Bash-specific, TAP-compliant)  
✅ **Q: CI/CD platform?** → GitHub Actions (native integration)  
✅ **Q: Pre-commit solution?** → pre-commit framework (multi-tool support)  
✅ **Q: Documentation format?** → Markdown (widely supported)

## Next Steps

1. Create `.pre-commit-config.yaml` with ShellCheck hook
2. Set up `tests/` directory structure for bats
3. Create `.github/workflows/ci.yml` for GitHub Actions
4. Write initial test cases for critical functions
5. Create documentation files (README, CONTRIBUTING)
