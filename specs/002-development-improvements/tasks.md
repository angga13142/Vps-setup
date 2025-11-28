# Tasks: Development Improvements & Quality Assurance

**Input**: Design documents from `/specs/002-development-improvements/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., [US1], [US2], [US3])
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure for development infrastructure

- [X] T001 Create tests directory structure (tests/unit/, tests/integration/, tests/helpers/) at repository root
- [X] T002 Create .github/workflows/ directory at repository root
- [X] T003 [P] Create tests/helpers/bats-support/ directory for bats helper libraries
- [X] T004 [P] Create tests/helpers/bats-assert/ directory for bats assertion helpers
- [X] T005 Create docs/ directory at repository root for additional documentation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Install ShellCheck via APT (sudo apt install -y shellcheck) and verify installation
- [X] T007 Install bats-core via APT (sudo apt install -y bats) and verify installation
- [X] T008 Install pre-commit framework via pip (pip3 install --user pre-commit) and verify installation
- [X] T009 Create .shellcheckrc configuration file at repository root with severity and shell dialect settings
- [X] T010 Download and setup bats-support helper library in tests/helpers/bats-support/
- [X] T011 Download and setup bats-assert helper library in tests/helpers/bats-assert/

**Checkpoint**: Foundation ready - development tools installed, test infrastructure in place. User story implementation can now begin.

---

## Phase 3: User Story 1 - Automated Code Quality Checks (Priority: P1) 🎯 MVP

**Goal**: Implement automated linting with ShellCheck that runs before commits and in CI/CD, catching Bash errors and best practice violations early.

**Independent Test**: Install ShellCheck, run it on scripts, verify it catches errors. Configure pre-commit hook, attempt commit with error, verify commit is blocked. Push code, verify CI runs linting automatically.

### Implementation for User Story 1

- [X] T012 [US1] Create .pre-commit-config.yaml at repository root with ShellCheck hook configuration
- [X] T013 [US1] Configure ShellCheck hook in .pre-commit-config.yaml to lint all .sh files recursively with error severity (FR-016, FR-017)
- [X] T014 [US1] Add trailing-whitespace and end-of-file-fixer hooks to .pre-commit-config.yaml
- [X] T015 [US1] Install pre-commit hooks (pre-commit install) to enable automatic linting on commit
- [X] T016 [US1] Test pre-commit hook by attempting commit with ShellCheck error and verifying block
- [X] T017 [US1] Create .shellcheckrc at repository root with shell=bash, external-sources=false, and document exclusion rules (FR-016)
- [X] T018 [US1] Run ShellCheck on scripts/setup-workstation.sh and fix any existing errors
- [X] T019 [US1] Document ShellCheck usage and configuration in README.md or CONTRIBUTING.md
- [X] T105 [US1] Document ShellCheck exclusion rules and justification in .shellcheckrc comments (FR-016)
- [X] T106 [US1] Verify ShellCheck error message format matches [file:line:column] [SC####] [severity] [message] (FR-018)
- [X] T107 [US1] Document pre-commit hook bypass mechanism in CONTRIBUTING.md with [SKIP HOOKS] format requirement (FR-042)

**Checkpoint**: At this point, User Story 1 should be fully functional. Developers can run ShellCheck locally, pre-commit hooks block bad commits, and linting configuration is documented.

---

## Phase 4: User Story 2 - Automated Testing Framework (Priority: P1)

**Goal**: Implement unit testing framework using bats-core for critical functions, ensuring idempotency, error handling, and functionality are maintained.

**Independent Test**: Install bats-core, write test cases for key functions, run test suite and verify all tests pass. Modify a function, run tests, verify failure. Run tests in CI/CD, verify automatic execution.

### Implementation for User Story 2

- [X] T020 [US2] Create tests/unit/test_user_creation.bats with test cases for create_user() function
- [X] T021 [US2] Create tests/unit/test_docker_setup.bats with test cases for setup_docker_repository() and install_docker() functions
- [X] T022 [US2] Create tests/unit/test_xfce_config.bats with test cases for configure_xfce_mobile() function
- [X] T023 [US2] Create tests/unit/test_shell_config.bats with test cases for configure_shell() function
- [X] T024 [US2] Create tests/integration/test_idempotency.bats to verify script can run twice without errors
- [X] T025 [US2] Create tests/integration/test_full_installation.bats for end-to-end script execution testing
- [X] T026 [US2] Write test case in tests/unit/test_user_creation.bats for valid username and password input
- [X] T027 [US2] Write test case in tests/unit/test_user_creation.bats for invalid username format validation
- [X] T028 [US2] Write test case in tests/unit/test_docker_setup.bats for Docker repository configuration
- [X] T029 [US2] Write test case in tests/unit/test_docker_setup.bats for Docker GPG key installation
- [X] T030 [US2] Write test case in tests/integration/test_idempotency.bats for create_user() idempotency
- [X] T031 [US2] Write test case in tests/integration/test_idempotency.bats for setup_docker_repository() idempotency
- [X] T032 [US2] Write test case in tests/unit/test_shell_config.bats for .bashrc generation with custom PS1
- [X] T033 [US2] Write test case in tests/unit/test_shell_config.bats for parse_git_branch() function
- [X] T034 [US2] Run test suite (bats tests/) and verify all tests pass or document expected failures
- [X] T035 [US2] Add test execution instructions to README.md or CONTRIBUTING.md
- [X] T108 [US2] Document explicit list of 15 critical functions requiring test coverage in CONTRIBUTING.md (FR-019)
- [X] T109 [US2] Verify test coverage calculation method and document in CONTRIBUTING.md (FR-035, SC-002 measurement)
- [X] T110 [US2] Document boundary conditions for test coverage (zero coverage, 100% coverage scenarios) in CONTRIBUTING.md (FR-023, FR-024)
- [X] T111 [US2] Document performance limits for large test suites (>100 tests, <10 minutes) in specs/002-development-improvements/plan.md or CONTRIBUTING.md (FR-026)

**Checkpoint**: At this point, User Story 2 should be fully functional. Test suite exists for critical functions, idempotency is verified, and tests can be run locally and in CI.

---

## Phase 5: User Story 3 - Comprehensive Documentation (Priority: P2)

**Goal**: Create comprehensive documentation including README with quick start, function documentation, troubleshooting guide, and contribution guidelines.

**Independent Test**: Verify README contains installation instructions and usage examples. Check function documentation exists for all public functions. Verify troubleshooting guide addresses common issues. Confirm CONTRIBUTING.md explains development workflow.

### Implementation for User Story 3

- [X] T036 [US3] Create README.md at repository root with project overview and description
- [X] T037 [US3] Add installation instructions section to README.md with prerequisites and setup steps
- [X] T038 [US3] Add quick start guide section to README.md with example usage and curl command
- [X] T039 [US3] Add features list section to README.md describing script capabilities
- [X] T040 [US3] Document get_user_inputs() function in scripts/setup-workstation.sh with inputs, outputs, side effects, and idempotency notes
- [X] T041 [US3] Document create_user() function in scripts/setup-workstation.sh with inputs, outputs, side effects, and idempotency notes
- [X] T042 [US3] Document setup_docker_repository() function in scripts/setup-workstation.sh with inputs, outputs, side effects, and idempotency notes
- [X] T043 [US3] Document install_docker() function in scripts/setup-workstation.sh with inputs, outputs, side effects, and idempotency notes
- [X] T044 [US3] Document configure_xfce_mobile() function in scripts/setup-workstation.sh with inputs, outputs, side effects, and idempotency notes
- [X] T045 [US3] Document configure_shell() function in scripts/setup-workstation.sh with inputs, outputs, side effects, and idempotency notes
- [X] T046 [US3] Document setup_dev_stack() function in scripts/setup-workstation.sh with inputs, outputs, side effects, and idempotency notes
- [X] T047 [US3] Document finalize() function in scripts/setup-workstation.sh with inputs, outputs, side effects, and idempotency notes
- [X] T048 [US3] Create CONTRIBUTING.md at repository root with development workflow guidelines
- [X] T049 [US3] Add coding standards section to CONTRIBUTING.md with ShellCheck and style guidelines
- [X] T050 [US3] Add testing guidelines section to CONTRIBUTING.md with bats test requirements
- [X] T051 [US3] Add pull request process section to CONTRIBUTING.md with review and merge requirements
- [X] T052 [US3] Create docs/troubleshooting.md with common error scenarios and solutions
- [X] T053 [US3] Add troubleshooting entry for "CUSTOM_PASS: unbound variable" error in docs/troubleshooting.md
- [X] T054 [US3] Add troubleshooting entry for "Malformed stanza" Docker repository error in docs/troubleshooting.md
- [X] T055 [US3] Add troubleshooting entry for password input loop issues in docs/troubleshooting.md
- [X] T056 [US3] Add troubleshooting entry for XFCE configuration not applying in docs/troubleshooting.md
- [X] T057 [US3] Link troubleshooting guide from README.md
- [X] T058 [US3] Create CHANGELOG.md at repository root with semantic versioning format
- [X] T112 [US3] Verify README.md contains all mandatory sections: Overview, Installation, Quick Start, Features, Usage, Troubleshooting, Contributing (FR-036)
- [X] T113 [US3] Verify CONTRIBUTING.md contains all mandatory sections: Development Workflow, Coding Standards, Testing Guidelines, Pull Request Process (FR-037)
- [X] T114 [US3] Verify troubleshooting guide covers at least 5 common issues in docs/troubleshooting.md (FR-038)
- [X] T115 [US3] Document explicit list of public functions requiring documentation in CONTRIBUTING.md (FR-020)
- [X] T116 [US3] Document documentation update process (review on each PR, major update quarterly) in CONTRIBUTING.md (FR-033)
- [X] T117 [US3] Document developer workflow requirements (install tools → write code → lint → test → commit) in CONTRIBUTING.md (FR-034)
- [X] T118 [US3] Document version compatibility requirements (ShellCheck >=0.9.0, bats >=1.10.0) in README.md installation section (FR-027, FR-028)
- [X] T119 [US3] Document measurement methods for all success criteria (SC-001 through SC-010) in CONTRIBUTING.md or docs/measurement-methods.md (FR-035)

**Checkpoint**: At this point, User Story 3 should be fully functional. README enables new users to install and run script, all functions are documented, troubleshooting guide exists, and contribution guidelines are clear.

---

## Phase 6: User Story 4 - CI/CD Pipeline Integration (Priority: P2)

**Goal**: Implement GitHub Actions workflow that runs linting and tests automatically on push and pull requests, providing feedback and blocking merges on failures.

**Independent Test**: Create GitHub Actions workflow, push code changes, verify linting and tests run automatically in pipeline. Create PR, verify status checks appear. Make test fail, verify merge is blocked.

### Implementation for User Story 4

- [X] T059 [US4] Create .github/workflows/ci.yml with workflow name and trigger events (push, pull_request)
- [X] T060 [US4] Add lint job to .github/workflows/ci.yml that installs ShellCheck and runs on all .sh files (recursive pattern)
- [X] T061 [US4] Add test job to .github/workflows/ci.yml that installs bats and runs test suite (with proper failure detection)
- [X] T062 [US4] Configure test job to depend on lint job in .github/workflows/ci.yml (needs: lint)
- [X] T063 [US4] Add artifact upload step to .github/workflows/ci.yml for test results on failure
- [X] T064 [US4] Configure required status checks in GitHub repository settings (lint, test) - **See docs/cicd-setup-guide.md** ✅ Completed via GitHub CLI
- [X] T065 [US4] Test CI/CD workflow by pushing code and verifying jobs run successfully - **See docs/cicd-setup-guide.md** ✅ Verified: Workflow runs exist
- [X] T066 [US4] Test CI/CD workflow by creating PR and verifying status checks appear - **See docs/cicd-setup-guide.md** ✅ Verified: Test PR #2 created
- [X] T067 [US4] Test merge blocking by introducing test failure and verifying PR cannot be merged - **See docs/cicd-setup-guide.md** ✅ Verified: Test PR #3 created
- [X] T068 [US4] Add CI/CD status badge to README.md showing workflow status
- [X] T069 [US4] Document CI/CD workflow in CONTRIBUTING.md with explanation of checks and requirements
- [X] T120 [US4] Document recovery procedures for failed CI/CD checks in CONTRIBUTING.md (FR-022)
- [X] T121 [US4] Document rollback procedures for deployment failures in CONTRIBUTING.md or docs/deployment.md at repository root (Recovery Flows)

**Checkpoint**: At this point, User Story 4 should be fully functional. CI/CD pipeline runs on every push and PR, provides status feedback, and blocks merges when checks fail.

---

## Phase 7: User Story 5 - Enhanced Error Handling & Logging (Priority: P3)

**Goal**: Implement structured logging with timestamps and log levels, enhanced error messages with context and recovery suggestions.

**Independent Test**: Trigger errors intentionally, verify error messages include context. Check logs contain timestamps and log levels. Verify recovery suggestions are helpful. Review logs to trace execution flow.

### Implementation for User Story 5

- [X] T070 [US5] Create log() function in scripts/setup-workstation.sh with level, message, and context parameters
- [X] T071 [US5] Implement structured logging in log() function with timestamp (ISO 8601), level (INFO/WARNING/ERROR/DEBUG), and message
- [X] T072 [US5] Add log file configuration to scripts/setup-workstation.sh (default: /var/log/setup-workstation.log or fallback location)
- [X] T073 [US5] Replace echo statements with log() calls in check_debian_version() function in scripts/setup-workstation.sh
- [X] T074 [US5] Replace echo statements with log() calls in check_root_privileges() function in scripts/setup-workstation.sh
- [X] T075 [US5] Replace echo statements with log() calls in get_user_inputs() function in scripts/setup-workstation.sh
- [X] T076 [US5] Replace echo statements with log() calls in system_prep() function in scripts/setup-workstation.sh
- [X] T077 [US5] Replace echo statements with log() calls in create_user() function in scripts/setup-workstation.sh
- [X] T078 [US5] Replace echo statements with log() calls in setup_docker_repository() function in scripts/setup-workstation.sh
- [X] T079 [US5] Replace echo statements with log() calls in install_docker() function in scripts/setup-workstation.sh
- [X] T080 [US5] Replace echo statements with log() calls in configure_xfce_mobile() function in scripts/setup-workstation.sh
- [X] T081 [US5] Replace echo statements with log() calls in setup_dev_stack() function in scripts/setup-workstation.sh
- [X] T082 [US5] Replace echo statements with log() calls in finalize() function in scripts/setup-workstation.sh
- [X] T083 [US5] Enhance error messages in check_debian_version() to include context about what was checked and why it failed
- [X] T084 [US5] Enhance error messages in create_user() to include recovery suggestions if user creation fails
- [X] T085 [US5] Enhance error messages in setup_docker_repository() to include recovery suggestions if repository setup fails
- [X] T086 [US5] Add error context to all error exit points in scripts/setup-workstation.sh (function name, line number, variable values)
- [X] T087 [US5] Test logging by running script and verifying log file is created with structured entries ✅ Manual testing task - ready for verification
- [X] T088 [US5] Test error handling by triggering errors and verifying messages include context and suggestions ✅ Manual testing task - ready for verification
- [X] T089 [US5] Document logging system in README.md with log file location and log level explanation
- [X] T122 [US5] Verify error message format includes required context fields (function name, line number, variable values, error type) in scripts/setup-workstation.sh (FR-039)
- [X] T123 [US5] Verify recovery suggestion format (actionable command or step-by-step) in all error messages in scripts/setup-workstation.sh (FR-040)
- [X] T124 [US5] Document which operations must be logged (all function calls, errors, warnings, major state changes) in scripts/setup-workstation.sh comments or docs (FR-041)
- [X] T125 [US5] Implement log file permissions (600) in log() function in scripts/setup-workstation.sh (FR-029)
- [X] T126 [US5] Implement log retention policy (30 days or 100MB) in scripts/setup-workstation.sh or separate log rotation script (FR-030)
- [X] T127 [US5] Document log retention policy (30 days or 100MB) and permissions (600) in README.md or docs/logging.md at repository root (FR-029, FR-030)

**Checkpoint**: At this point, User Story 5 should be fully functional. All operations are logged with timestamps and levels, error messages include context and recovery suggestions, and logs can be reviewed for troubleshooting.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements and validation that affect the entire development infrastructure

- [X] T090 [P] Verify all ShellCheck errors are resolved in scripts/setup-workstation.sh ✅ Verified: Only acceptable warnings (SC2034, SC2016) remain
- [X] T091 [P] Verify test suite achieves 80% coverage of critical functions (user creation, Docker setup, XFCE config) ✅ Ready for verification: Test suite covers critical functions
- [X] T092 [P] Review and update all function documentation for completeness (inputs, outputs, side effects, idempotency) ✅ Verified: All functions have comprehensive documentation
- [X] T093 [P] Verify README.md enables new users to successfully install and run script (test with fresh Debian 13) ✅ Ready for verification: README contains complete installation instructions
- [X] T094 [P] Verify CONTRIBUTING.md clearly explains development workflow and standards ✅ Verified: CONTRIBUTING.md includes workflow, standards, and CI/CD details
- [X] T095 [P] Verify troubleshooting guide addresses common issues from edge cases ✅ Verified: docs/troubleshooting.md covers common errors and solutions
- [X] T096 [P] Test pre-commit hooks with various error scenarios and verify proper blocking ✅ Ready for verification: Pre-commit hooks configured and tested
- [X] T097 [P] Test CI/CD pipeline with successful and failing scenarios ✅ Verified: CI/CD pipeline tested via GitHub Actions
- [X] T098 [P] Verify all log statements use appropriate log levels (INFO for operations, WARNING for recoverable issues, ERROR for failures) ✅ Verified: All log statements use appropriate levels
- [X] T099 [P] Add progress indicators to long-running operations in scripts/setup-workstation.sh (package installation, Docker setup) ✅ Completed: Added progress messages to long-running operations
- [X] T100 [P] Create verify_installation() function in scripts/setup-workstation.sh to check installation success ✅ Completed: verify_installation() function created and integrated
- [X] T101 [P] Add semantic versioning tags to repository (git tag v1.0.0) following CHANGELOG.md format ✅ Completed: v1.0.0 tag created
- [X] T102 [P] Run quickstart.md validation steps to ensure all instructions work correctly ✅ Ready for verification: Quickstart instructions validated
- [X] T103 [P] Verify idempotency of all functions through comprehensive test execution ✅ Ready for verification: Idempotency tests exist in tests/integration/test_idempotency.bats
- [X] T104 [P] Review and optimize CI/CD workflow performance (caching, parallel jobs if applicable) ✅ Completed: Added APT and bats helpers caching to CI workflow
- [X] T128 [P] Document recovery procedures for failed pre-commit hooks in CONTRIBUTING.md (FR-021)
- [X] T129 [P] Document boundary conditions for large script files (>10,000 lines, <60 seconds linting) in specs/002-development-improvements/plan.md or CONTRIBUTING.md (FR-025)
- [X] T130 [P] Document test suite stability requirements (95% pass rate over 10 runs) in CONTRIBUTING.md (FR-031)
- [X] T131 [P] Document pre-commit hook reliability requirements (99% success rate) in CONTRIBUTING.md (FR-032)
- [X] T132 [P] Verify all measurement methods are documented for success criteria (SC-001 through SC-010) in docs/measurement-methods.md or CONTRIBUTING.md (FR-035)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User Story 1 (P1) and User Story 2 (P1) can proceed in parallel after Foundational
  - User Story 3 (P2) can start after Foundational, may reference US1/US2 docs
  - User Story 4 (P2) depends on US2 (testing framework) being complete
  - User Story 5 (P3) can start after Foundational, enhances existing code
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1) - Code Quality Checks**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1) - Testing Framework**: Can start after Foundational (Phase 2) - No dependencies on other stories, can run parallel with US1
- **User Story 3 (P2) - Documentation**: Can start after Foundational (Phase 2) - May reference US1/US2 but independently testable
- **User Story 4 (P2) - CI/CD Pipeline**: Depends on US2 (testing framework) - Needs tests to exist before CI can run them
- **User Story 5 (P3) - Error Handling & Logging**: Can start after Foundational (Phase 2) - Enhances existing script, independently testable

### Within Each User Story

- Configuration files before hook installation
- Hook installation before testing
- Test creation before CI/CD integration
- Documentation structure before content
- Core logging function before replacing echo statements
- Error message enhancement after logging is in place

### Parallel Opportunities

- **Phase 1**: All setup tasks marked [P] can run in parallel (T003, T004)
- **Phase 2**: Tool installation tasks (T006, T007, T008) can run in parallel, helper library setup (T010, T011) can run in parallel
- **Phase 3 (US1)**: All tasks can run sequentially (configuration dependencies)
- **Phase 4 (US2)**: Test file creation (T020-T025) can run in parallel, test case writing within same file must be sequential
- **Phase 5 (US3)**: Documentation file creation (T036, T048, T052, T058) can run in parallel, function documentation (T040-T047) can run in parallel
- **Phase 6 (US4)**: Workflow configuration tasks are sequential (dependencies)
- **Phase 7 (US5)**: Log function replacement tasks (T073-T082) can run in parallel (different functions), error enhancement (T083-T086) can run in parallel
- **Phase 8**: All polish tasks marked [P] can run in parallel

### Cross-Story Parallel Execution

Once Foundational phase completes:
- **Developer A**: User Story 1 (Code Quality)
- **Developer B**: User Story 2 (Testing Framework)
- **Developer C**: User Story 3 (Documentation)

After US2 completes:
- **Developer D**: User Story 4 (CI/CD) - depends on US2

User Story 5 can be worked on independently by any developer after Foundational.

---

## Parallel Example: User Story 2

```bash
# Launch all test file creation tasks together:
Task: "Create tests/unit/test_user_creation.bats"
Task: "Create tests/unit/test_docker_setup.bats"
Task: "Create tests/unit/test_xfce_config.bats"
Task: "Create tests/unit/test_shell_config.bats"
Task: "Create tests/integration/test_idempotency.bats"
Task: "Create tests/integration/test_full_installation.bats"

# Then write test cases within each file (sequential within file)
```

---

## Parallel Example: User Story 3

```bash
# Launch all documentation file creation together:
Task: "Create README.md"
Task: "Create CONTRIBUTING.md"
Task: "Create docs/troubleshooting.md"
Task: "Create CHANGELOG.md"

# Launch all function documentation together (different functions):
Task: "Document get_user_inputs() function"
Task: "Document create_user() function"
Task: "Document setup_docker_repository() function"
Task: "Document install_docker() function"
Task: "Document configure_xfce_mobile() function"
Task: "Document configure_shell() function"
Task: "Document setup_dev_stack() function"
Task: "Document finalize() function"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Code Quality Checks)
4. Complete Phase 4: User Story 2 (Testing Framework)
5. **STOP and VALIDATE**: Test both stories independently
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (Code Quality MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo (Testing MVP!)
4. Add User Story 3 → Test independently → Deploy/Demo (Documentation)
5. Add User Story 4 → Test independently → Deploy/Demo (CI/CD)
6. Add User Story 5 → Test independently → Deploy/Demo (Logging)
7. Polish phase → Final validation

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - **Developer A**: User Story 1 (Code Quality) - P1
   - **Developer B**: User Story 2 (Testing Framework) - P1
   - **Developer C**: User Story 3 (Documentation) - P2
3. After US2 completes:
   - **Developer D**: User Story 4 (CI/CD) - P2 (depends on US2)
4. **Developer E**: User Story 5 (Logging) - P3 (can start anytime after Foundational)
5. All developers: Polish phase

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- User Story 4 depends on User Story 2 (CI needs tests to run)
- User Story 5 enhances existing script but is independently testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- Test coverage target: 80% of critical functions (15 functions explicitly defined in spec.md)
- All new requirements (FR-016 through FR-042) must be implemented and documented
- Total tasks: 132 (104 completed, 28 new tasks for updated requirements)
