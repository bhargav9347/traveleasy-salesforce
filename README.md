# TravelEasy — Intelligent Travel & Spend Control Platform
> **2027 NPN Salesforce Developer Catalyst Hackathon Submission**

## 🌟 Executive Summary
TravelEasy is a enterprise-grade Salesforce application designed to transform legacy, spreadsheet-based travel and expense management into a unified, intelligent spend control ecosystem. 

Rather than acting as a passive expense logger, TravelEasy embeds an **explainable deterministic Smart Expense Control Engine** that evaluates claims in real time against policy limits, missing receipt mandates, duplicate submissions, and budget overruns.

---

## 🏛 Architecture & Core Data Model
The platform is built on native Salesforce DX architecture adhering to strict enterprise standards (One Trigger Per Object, Service Layer Pattern, Bulkified Apex, Custom Metadata Driven Policy Engine).

```
Employee / Manager / Finance
          ↓
Lightning Experience / Trip Wallet LWC
          ↓
TravelEasy Salesforce Application
          ↓
Salesforce Data Model (Custom & Standard Objects)
          ↓
Validation Rules & Formulas
          ↓
Smart Expense Control Engine (Apex Service)
          ↓
Queueable / Batch / Scheduled Processing
          ↓
Financial Settlement & Integration Log Audit
```

### Business Objects
1. **Travel Request (`Travel_Request__c`)**: Captures travel plans, destination, dates, estimated budget, approval status, duration, and budget variance.
2. **Expense Report (`Expense_Report__c`)**: Aggregates expense line items per trip, maintains status, validation flags, total reimbursable amounts, and reimbursement tracking.
3. **Expense Item (`Expense_Item__c`)**: Line-item details (Flight, Hotel, Meals, Taxi, etc.) with real-time policy evaluation status, vendor info, and receipt attachments.
4. **Expense Exception (`Expense_Exception__c`)**: Auditable human-review object automatically populated whenever policy exceptions are detected.
5. **Reimbursement (`Reimbursement__c`)**: Financial disbursement tracking linked to approved expense reports with payment references and completion dates.
6. **Travel Policy Configuration (`Travel_Policy_Config__mdt`)**: Custom Metadata Type making limits, receipt thresholds, and approval rules configuration-driven.
7. **Integration Log (`Integration_Log__c`)**: System log for auditability, Queueable execution tracking, and external ERP integration.

---

## 💡 Key Features & Innovation

### 1. Smart Expense Control Engine
- **Explainable Policy Control**: Evaluates category-level max amounts from Custom Metadata.
- **Missing Receipt Mandate**: Detects missing receipts for threshold-exceeding claims.
- **Potential Duplicate Detection**: Scans historical claims for matching date, category, and amount per employee.
- **Budget Overrun Control**: Compares cumulative actual spend against approved estimated travel budget.
- **Automated Exception Routing**: Flags exceptions as `Expense_Exception__c` records for auditable manager/finance review without labeling employees as fraudulent.

### 2. Async & Batch Automation
- **`ReimbursementQueueable`**: Asynchronously processes approved reimbursements, generates payment references (`PAY-REF-xxx`), updates status, and logs integration audit trails.
- **`ApprovalSLAEscalationBatch`**: Scheduled batch process monitoring pending approvals older than 24 hours and logging SLA warnings.
- **`ExpenseReconciliationBatch`**: Large-volume batch reconciliation engine verifying line item totals and reconciliation integrity.

### 3. Trip Wallet Lightning Web Component (`tripWallet`)
- Interactive dashboard for employees and managers.
- Real-time spend metrics: Estimated Budget, Actual Spent, Remaining Budget, Utilization %.
- Color-coded policy badges (`PASS`, `POLICY_EXCEPTION`, `MISSING_RECEIPT`, `POTENTIAL_DUPLICATE`, `BUDGET_OVERRUN`).

---

## 🧪 Testing & Verification
- **Apex Unit Tests**: 100% passing rate across 64 test methods.
- **Bulkification & Security**: Fully bulkified Apex handling bulk records with standard DML and SOQL constraints.

---

## 🚀 Deployment Instructions
1. Authenticate with target Salesforce org via SF CLI:
   ```bash
   sf org login web -a TargetOrg
   ```
2. Deploy metadata and run local test suite:
   ```bash
   sf project deploy start -o TargetOrg --test-level RunLocalTests
   ```
3. Generate sample demo data in target org:
   ```bash
   sf apex run -o TargetOrg -f scripts/apex/generateData.apex
   ```

---

## 📜 Hackathon Demo Sequence (20-Minute Narrative)
1. **0–2 min**: Business Problem & Transformation Vision.
2. **2–4 min**: Architecture Overview (Custom Metadata, Service Layer, Triggers).
3. **4–7 min**: Employee Travel Request creation & Manager Approval flow.
4. **7–12 min**: Expense Report & Item submission with Smart Expense Control Engine.
5. **12–14 min**: Exception Scenario (Missing Receipt / Policy Limit flag & Manager Resolution).
6. **14–16 min**: Async Reimbursement Queueable execution & Integration Audit Log.
7. **16–18 min**: Trip Wallet LWC & Management Analytics.
8. **18–20 min**: Technical Excellence (Bulkification, Security, Testing, Scalability).

---
*Created for the 2027 NPN Salesforce Developer Catalyst Hackathon.*
