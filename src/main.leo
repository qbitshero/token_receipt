// The 'token_receipt' program.
program token_receipt.aleo {
    // On-chain storage of an `account` map, with `address` as the key,
    // and `u64` as the value.
    mapping account: address => u64;

    record token {              // Note
        owner: address,         // The token owner.
        microcredits: u64,      // The Aleo balance (in microcredits).
        amount: u64,            // The token amount.
    }

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

    // receipt information filled by consumter
    struct receipt_info {
        category: u32,          // consumption type, 1-meal, 2-travel, 3-purchase, 4-medical, 5-lease, 6-transport, 7-other
        date: u32,              // date, yyyymmdd
        company: address,       // company account
        dep: u32,               // department, 1 - human resource, 2 - Administrative, 3 - market, 4 - research and development, 5 - ceo office, 6 - other
        approver: address,      // The approver
    }

    /* Mint */

    // The function `mint_private` initializes a new record with the specified amount of tokens for the receiver.
    transition mint_private(receiver: address, amount: u64) -> token {
        // assert_eq(self.caller, aleo1s6axzuxkxz8ksxdzqpnvktglraf7k3mayt05lhx652vc5zw53gqs326sjn); 
        return token {
            owner: receiver,
            microcredits: 0u64,
            amount: amount,
        };
    }

    // The function `transfer_private` sends the specified token amount to the token receiver from the specified token record.
    transition transfer_private(sender: token, receiver: address, amount: u64) -> (token, token) {
        assert_eq(self.caller, sender.owner);
        assert(sender.amount >= amount);

        // Checks the given token record has sufficient balance.
        // This `sub` operation is safe, and the proof will fail if an overflow occurs.
        // `difference` holds the change amount to be returned to sender.
        let difference: u64 = sender.amount - amount;

        // Produce a token record with the change amount for the sender.
        let remaining: token = token {
            owner: sender.owner,
            microcredits: sender.microcredits,
            amount: difference,
        };

        // Produce a token record for the specified receiver.
        let transferred: token = token {
            owner: receiver,
            microcredits: 0u64,
            amount: amount,
        };

        // Output the sender's change record and the receiver's record.
        return (remaining, transferred);
    }

    // The function `transfer_private_with_receipt` sends the specified token amount to the token receiver from the specified token record,
    // and produces a receipt for approver
    // sender - token owned by sender
    // receiver - address of receiver
    // amount - amount
    // info - receipt information filled by consumer, which describes the consumption process
    // returns remaining token, token belongs to receiver, and receipt
    transition transfer_private_with_receipt(sender: token, receiver: address, amount: u64, info: receipt_info)
        -> (token, token, receipt) {
        assert_eq(self.caller, sender.owner);

        // Checks the given token record has sufficient balance.
        // This `sub` operation is safe, and the proof will fail if an overflow occurs.
        // `difference` holds the change amount to be returned to sender.
        let difference: u64 = sender.amount - amount;

        // Produce a token record with the change amount for the sender.
        let remaining: token = token {
            owner: sender.owner,
            microcredits: sender.microcredits,
            amount: difference,
        };

        // Produce a token record for the specified receiver.
        let transferred: token = token {
            owner: receiver,
            microcredits: 0u64,
            amount: amount,
        };

        // Produce a receipt
        let rcpt: receipt =  receipt {
            owner: info.approver,
            microcredits: 0u64,
            consumer: sender.owner,
            provider: receiver,
            amount: amount,
            category: info.category,
            date: info.date,
            company: info.company,
            dep: info.dep,
            state: 2u32,            // default to approving state
        };

        // Output the sender's change record, the receiver's record and the receipt
        return (remaining, transferred, rcpt);
    }

    // check receipt, approve or reject the request
    // to_check - the receipt to check validity and existence
    // next_approver - next approver if the receipt needs be checked by multiple approvers
    // state - state of the receipt, it must be approving
    // returns a receipt with new state, and owned by next approver
    transition check_receipt(to_check: receipt, next_approver: address, state: u32) -> receipt {
        assert_eq(self.caller, to_check.owner);
        assert_eq(to_check.state, 2u32);       // only approving state is accepted

        // Produce a receipt for next approver
        let rcpt: receipt = receipt {
            owner: next_approver,
            microcredits: to_check.microcredits,
            consumer: to_check.consumer,
            provider: to_check.provider,
            amount: to_check.amount,
            category: to_check.category,
            date: to_check.date,
            company: to_check.company,
            dep: to_check.dep,
            state: state,
        };

        return rcpt;
    }

    // reimburse the receipt
    // the state of receipt must be approved
    // returns remaining token, and new token owned by the consumer
    transition reimburse(rcpt: receipt, sender: token) -> (token, token) {
        assert_eq(rcpt.state, 0u32); // must be approved
        assert_eq(self.caller, sender.owner);
        assert(sender.amount >= rcpt.amount);

        // Checks the given token record has sufficient balance.
        // This `sub` operation is safe, and the proof will fail if an overflow occurs.
        // `difference` holds the change amount to be returned to sender.
        let difference: u64 = sender.amount - rcpt.amount;

        // Produce a token record with the change amount for the sender.
        let remaining: token = token {
            owner: sender.owner,
            microcredits: sender.microcredits,
            amount: difference,
        };

        // Produce a token record for the consumer.
        let transferred: token = token {
            owner: rcpt.consumer,
            microcredits: 0u64,
            amount: rcpt.amount,
        };

        // Output the sender's change record and the consumer's record.
        return (remaining, transferred);
    }
}
