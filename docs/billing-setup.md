# GCP Billing Budget Setup

This is a one-time manual step in the GCP Console — no Terraform required.

## Steps

1. Go to [GCP Console → Billing → Budgets & alerts](https://console.cloud.google.com/billing/budgets)
2. Click **Create budget**
3. Configure:
   - **Scope:** Project `zaeem-dev`
   - **Budget type:** Specified amount
   - **Amount:** $50/month
4. Set alert thresholds:
   - 60% ($30) → email notification
   - 100% ($50) → email notification
5. Under **Actions**, check "Email alerts to billing admins and users"
6. Optionally enable **"Disable billing"** at 100% to hard-cap spend
   - ⚠️ This stops ALL GCP services in the project, not just the VM
   - Acceptable for a dedicated single-purpose project like this one

## Expected monthly cost

| Scenario | Compute | Disk | Total |
|---|---|---|---|
| Light (~80 hrs/mo) | ~$5 | ~$8.50 | **~$14** |
| Moderate (~160 hrs/mo) | ~$11 | ~$8.50 | **~$20** |

The 50GB SSD disk (~$8.50/mo) is the fixed baseline cost — it accrues whether the VM is running or not.

## Auto-stop

The VM also has a systemd idle timer (`devbox-idle.timer`) that powers it off after 30 minutes of inactivity. This is your primary cost defense — the billing budget is a backstop.
