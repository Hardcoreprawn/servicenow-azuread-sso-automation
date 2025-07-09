# Pre-Publish Checklist for Public Repos

Before making this repository public, ensure the following:

## 1. No Secrets or Sensitive Data
- [ ] No secrets, credentials, tokens, or sensitive values in any file (including history and branches).
- [ ] No real customer, internal, or production data in examples or test files.
- [ ] All secrets are referenced via Key Vault or pipeline variables only.

## 2. Ignore Sensitive/Local Files
- [ ] `.gitignore` is present and excludes `.terraform/`, state files, `.tfvars`, `.env`, and other sensitive or local files.

## 3. Documentation
- [ ] README and setup docs clearly state that secrets must be supplied by the user and never committed.
- [ ] Example pipelines reference secrets by name only, never by value.
- [ ] All environment-specific values are variables, not hardcoded.

## 4. Code & Scripts
- [ ] No hardcoded resource group names, subscription IDs, or other sensitive Azure details.
- [ ] All scripts are generic and do not expose internal-only information.

## 5. Repo Hygiene
- [ ] No old branches, tags, or files with sensitive data in their history.
- [ ] No leftover debug logs, crash logs, or temp files.

## 6. Review
- [ ] Final review by a team member for accidental exposure.
- [ ] (Optional) Use a tool like `git-secrets` or `truffleHog` to scan for secrets.

---

If all boxes are checked, you are ready to publish this repo publicly!
