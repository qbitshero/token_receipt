# token_receipt.aleo

## Introduction
In the circulation of privacy coins, there is a need to address an issue of reimbursement. For example, when an employee requests reimbursement for business trips. Now, we give a solution for this issue. In this program '_token_receipt.aleo_', there is a transaction '_transfer_private_with_receipt_' which produces a receipt owned by approver during the reimbursement. Then the approver can check the receipt on the chain, and get a new receipt for next approver. Here let's assume there are multiple approvers involved. Continue the approving process, at last we can send '_reimburse_' transaction to finish the reimbursement.

## Records and structs
```
    record token {
        owner: address,         // The token owner.
        microcredits: u64,      // The Aleo balance (in microcredits).
        amount: u64,            // The token amount.
    }
```
Token is the privacy coin during consumption.

```
    // receipt produced during consumption process
    record receipt {
        owner: address,         // The approver
        microcredits: u64,      // The Aleo balance (in microcredits).
        consumer: address,      // The consumer.
        provider: address,      // The service provider
        amount: u64,            // The token amount.
        category: u32,          // consumption type, 1-meal, 2-travel, 3-purchase, 4-medical, 5-lease, 6-transport, 7-other
        date: u32,              // date, yyyymmdd
        company: address,       // company account
        dep: u32,               // department, 1 - human resource, 2 - Administrative, 3 - market, 4 - research and development, 5 - ceo office, 6 - other
        state: u32,             // 0-approved, 1-rejected, 2-approving
    }
```
Receipt is produced during consumption, and it is the basis of reimbursement. So it contains consumer, service provider, approver, company, and other infomation.

```
    // receipt information filled by consumter
    struct receipt_info {
        category: u32,          // consumption type, 1-meal, 2-travel, 3-purchase, 4-medical, 5-lease, 6-transport, 7-other
        date: u32,              // date, yyyymmdd
        company: address,       // company account
        dep: u32,               // department, 1 - human resource, 2 - Administrative, 3 - market, 4 - research and development, 5 - ceo office, 6 - other
        approver: address,      // The approver
    }
```
receipt_info is provided by consumer, which is not in the transaction but required by reimbursement in company.

## Transactions

### mint_private
```
transition mint_private(receiver: address, amount: u64) -> token
```
Initializes a new record with the specified amount of tokens for the receiver.
Example:
```
leo run mint_private aleo1s6axzuxkxz8ksxdzqpnvktglraf7k3mayt05lhx652vc5zw53gqs326sjn 10000000000000u64
```

### transfer_private
```
transition transfer_private(sender: token, receiver: address, amount: u64) -> (token, token)
```
Sends the specified token amount to the token receiver from the specified token record.
Example:
```
leo run transfer_private '{
  owner: aleo1gtf4fjgvc54em4n3t445wml4f0j95x756zqtnujw84nkzny2659snvf9kn.private,
  microcredits: 0u64.private,
  amount: 10000000000000u64.private,
  _nonce: 5749804103085962805662160253547982255102932590895691274495344900952111627119group.public

}' aleo1yk5l3lrk60ty6cvehlx94xwpu9deh834tpe2k70t8nketucz658sxpd0xj 300000u64
```

### transfer_private_with_receipt
```
transition transfer_private_with_receipt(sender: token, receiver: address, amount: u64, info: receipt_info)
        -> (token, token, receipt)
```
Sends the specified token amount to the token receiver from the specified token record, and produces a receipt for approver.
Example:
```
leo run transfer_private_with_receipt "{
  owner: aleo1gtf4fjgvc54em4n3t445wml4f0j95x756zqtnujw84nkzny2659snvf9kn.private,
  microcredits: 0u64.private,
  amount: 400000000u64.private,
  _nonce: 521964075565377111087652020455877867454596103645997985820152650490303342626group.public
}" aleo18pfln645uyxsg5x7qq6pc4wca8gegkfgk83j9e89vllvlr8cccpq97l6sj 30000u64 "{
  category: 2u32,
  date: 20230720u32,
  company: aleo1s6axzuxkxz8ksxdzqpnvktglraf7k3mayt05lhx652vc5zw53gqs326sjn,
  dep: 4u32,
  approver: aleo1aw28a8kgvu7nh040pj4jcgpzz6z6vfwzkx9x8y2ajjsdkrtcp5qqjpd4k0
}"
```

### check_receipt
```
transition check_receipt(to_check: receipt, next_approver: address, state: u32) -> receipt
```
Check receipt, approve or reject the request. Returns a receipt with new state, and owned by next approver.
Example:
```
leo run check_receipt "{
  owner: aleo1aw28a8kgvu7nh040pj4jcgpzz6z6vfwzkx9x8y2ajjsdkrtcp5qqjpd4k0.private,
  microcredits: 0u64.private,
  consumer: aleo1gtf4fjgvc54em4n3t445wml4f0j95x756zqtnujw84nkzny2659snvf9kn.private,
  provider: aleo18pfln645uyxsg5x7qq6pc4wca8gegkfgk83j9e89vllvlr8cccpq97l6sj.private,
  amount: 30000u64.private,
  category: 1u32.private,
  date: 20230720u32.private,
  company: aleo1s6axzuxkxz8ksxdzqpnvktglraf7k3mayt05lhx652vc5zw53gqs326sjn.private,
  dep: 4u32.private,
  state: 2u32.private,
  _nonce: 3050220034997032858763158530129206135679273731869185575789294606486795440861group.public
}" aleo1s6axzuxkxz8ksxdzqpnvktglraf7k3mayt05lhx652vc5zw53gqs326sjn 2u32
```

### reimburse
```
transition reimburse(rcpt: receipt, sender: token) -> (token, token)
```
Reimburse the receipt and return remaining token, and new token owned by the consumer.
The state of receipt must be approved. Example:
```
leo run reimburse "{
  owner: aleo1s6axzuxkxz8ksxdzqpnvktglraf7k3mayt05lhx652vc5zw53gqs326sjn.private,
  microcredits: 0u64.private,
  consumer: aleo1gtf4fjgvc54em4n3t445wml4f0j95x756zqtnujw84nkzny2659snvf9kn.private,
  provider: aleo18pfln645uyxsg5x7qq6pc4wca8gegkfgk83j9e89vllvlr8cccpq97l6sj.private,
  amount: 30000u64.private,
  category: 1u32.private,
  date: 20230720u32.private,
  company: aleo1s6axzuxkxz8ksxdzqpnvktglraf7k3mayt05lhx652vc5zw53gqs326sjn.private,
  dep: 2u32.private,
  state: 0u32.private,
  _nonce: 6611922052483135109876984090182481505649431950966382533808548582344043684236group.public
}" "{
  owner: aleo1s6axzuxkxz8ksxdzqpnvktglraf7k3mayt05lhx652vc5zw53gqs326sjn.private,
  microcredits: 0u64.private,
  amount: 9596910000u64.private,
  _nonce: 241222459545766784073600196059509517964994369973851036957009218115969285313group.public
}"
```

## The whole process
Let's suppose that, an employee has a meal in a restaurant, and he requests reimbursement for this meal to the company.
To simplify the process, we also suppose that, the employee owns some tokens.

step1: The employee fills '_receipt_info_', with company, department, approver and other information. Calls '_transfer_private_with_receipt_', pays the meal and gets a receipt record. The approver here is the first approver of reimbursement process in company.

step2: The approver approves the receipt, calls '_check_receipt_'. If the reimbursement is rejected, the state of receipt will be set as '_rejected_', and the process finish. Otherwise, the state will be set as '_approving_', and a new receipt be produced owned by next approver.

step3: Repeat step2 until the last approver. The state of receipt will be set as '_approved_'.

step4: The last approver transfers token to the employee, calls '_reimburse_'. Now the employee has reimbursed the meal, and the receipt can't be used next time.

## Build Guide

To compile this Aleo program, run:
```bash
leo build
```

To execute this Aleo program, run:
```bash
leo run function [inputs]
```

## Demo
The complete demo is on <https://github.com/qbitshero/reimburse>.
