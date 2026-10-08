import { LightningElement, api, wire, track } from 'lwc';
import getTripSummary from '@salesforce/apex/TripWalletController.getTripSummary';
import getExpenseItems from '@salesforce/apex/TripWalletController.getExpenseItems';

export default class TripWallet extends LightningElement {
    @api recordId;
    @track tripSummary;
    @track expenseItems = [];
    @track isLoading = true;

    @wire(getTripSummary, { recordId: '$recordId' })
    wiredSummary({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.tripSummary = data;
        } else if (error) {
            console.error('Error loading trip summary:', error);
        }
    }

    @wire(getExpenseItems, { travelRequestId: '$recordId' })
    wiredItems({ error, data }) {
        if (data) {
            this.expenseItems = data.map(item => {
                let badgeClass = 'slds-badge ';
                if (item.Policy_Result__c === 'PASS') {
                    badgeClass += 'slds-theme_success';
                } else if (item.Policy_Result__c === 'MISSING_RECEIPT' || item.Policy_Result__c === 'BUDGET_OVERRUN') {
                    badgeClass += 'slds-theme_warning';
                } else {
                    badgeClass += 'slds-theme_error';
                }
                return { ...item, badgeClass };
            });
        } else if (error) {
            console.error('Error loading expense items:', error);
        }
    }

    toggleAddForm() {
        // Toggle action handler
    }
}
