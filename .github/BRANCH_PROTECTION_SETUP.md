# Branch Protection Configuration Guide

## Current Setup

Branch `master` is currently protected and requires pull requests for all changes.

## Recommended Branch Protection Settings for Development

Untuk memudahkan development sambil tetap menjaga kualitas code, berikut adalah konfigurasi branch protection yang direkomendasikan:

### Option 1: Allow Direct Push dengan CI Checks (Recommended)

**Settings Path:** `Settings > Branches > Branch protection rules > master`

**Configuration:**
- ✅ Require a pull request before merging
- ✅ Require status checks to pass before merging
  - Required status checks: `lint`, `test`
- ✅ Require branches to be up to date before merging
- ✅ Include administrators
- ✅ Allow force pushes: **Disabled**
- ✅ Allow deletions: **Disabled**

**Untuk memungkinkan direct push (opsional):**
- ❌ Require a pull request before merging: **Disabled** (untuk development)
- ✅ Require status checks to pass before pushing
  - Required status checks: `lint`, `test`
- ✅ Require branches to be up to date before pushing

### Option 2: Auto-merge setelah CI Pass

Gunakan GitHub Actions untuk auto-merge setelah semua checks pass.

### Option 3: Flexible Protection (Current + Auto-approve)

Tetap require PR, tapi auto-approve jika:
- CI checks pass
- No conflicts
- Approved by maintainer

## Setup via GitHub CLI

Jika GitHub CLI (`gh`) terinstall, jalankan script berikut:

```bash
# Install GitHub CLI jika belum ada
# Debian/Ubuntu:
sudo apt-get install gh

# Login
gh auth login

# Set branch protection (require PR + CI checks)
gh api repos/:owner/:repo/branches/master/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["lint","test"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"dismissal_restrictions":{},"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":1}' \
  --field restrictions=null

# Atau untuk allow direct push dengan CI checks:
gh api repos/:owner/:repo/branches/master/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["lint","test"]}' \
  --field enforce_admins=false \
  --field restrictions=null
```

## Setup via GitHub Web UI

1. Buka repository di GitHub
2. Pergi ke **Settings** > **Branches**
3. Di bagian **Branch protection rules**, klik **Add rule** atau edit rule untuk `master`
4. Konfigurasi sesuai kebutuhan:
   - **Branch name pattern:** `master`
   - **Require a pull request before merging:** (pilih sesuai kebutuhan)
   - **Require status checks to pass before merging:** ✅
     - Pilih: `lint` dan `test`
   - **Require branches to be up to date before merging:** ✅
   - **Include administrators:** ✅ (opsional)

## Temporary: Bypass Protection untuk Development

Jika perlu push langsung ke master untuk development:

1. **Via GitHub UI:**
   - Settings > Branches > Edit rule untuk master
   - Sementara disable "Require a pull request before merging"
   - Push perubahan
   - Re-enable protection setelah selesai

2. **Via GitHub CLI:**
   ```bash
   # Disable protection sementara
   gh api repos/:owner/:repo/branches/master/protection --method DELETE

   # Push perubahan
   git push origin master

   # Re-enable protection
   gh api repos/:owner/:repo/branches/master/protection --method PUT \
     --field required_status_checks='{"strict":true,"contexts":["lint","test"]}' \
     --field enforce_admins=true
   ```

## Best Practice

Untuk development yang lebih fleksibel:

1. **Gunakan branch development:** Buat branch `develop` yang tidak protected
2. **Master tetap protected:** Hanya merge dari `develop` atau PR yang sudah di-review
3. **Auto-merge:** Setup GitHub Actions untuk auto-merge PR yang sudah pass semua checks

## Current Workflow

Saat ini workflow menggunakan:
- Pre-commit hooks untuk local validation
- GitHub Actions CI untuk lint dan test
- Branch protection untuk require PR

Untuk development yang lebih cepat, pertimbangkan:
- Mengurangi required approvals menjadi 0 (auto-merge setelah CI pass)
- Atau membuat branch `develop` yang lebih fleksibel
