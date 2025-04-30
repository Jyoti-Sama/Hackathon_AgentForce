// stripeCardForm.js
import { LightningElement, api, track } from 'lwc';
import {
  FlowAttributeChangeEvent,
  FlowNavigationNextEvent
} from 'lightning/flowSupport';

export default class StripeCardForm extends LightningElement {
  @api cardNumber   = '4111 1111 1111 1111';
  @api cardName     = 'JOHN DOE';
  @api expiry       = '12/25';
  @api cvv          = '123';
  @api isSubmitted  = false;

  @track isBack = false;

  // ——— new getter ———
  get dataFacing() {
    return this.isBack ? 'back' : 'front';
  }

  get formattedCardNumber() {
    const raw = this.cardNumber.replace(/\D/g, '').padEnd(16, '•');
    return raw.match(/.{1,4}/g).join(' ');
  }

  get cvvMasked() {
    return this.cvv.replace(/./g, '•');
  }

  handleNumberChange(evt) {
    const val = evt.target.value.replace(/[^\d]/g, '').slice(0,16);
    this.cardNumber = val.replace(/(.{4})/g, '$1 ').trim();
  }

  handleChange(evt) {
    const field = evt.target.dataset.id;
    this[field] = evt.target.value.toUpperCase();
  }

  showBack() {
    this.isBack = true;
  }

  showFront() {
    this.isBack = false;
  }

  handleSubmit() {
    this.isSubmitted = true;
    ['cardNumber','cardName','expiry','cvv','isSubmitted'].forEach(prop => {
      this.dispatchEvent(new FlowAttributeChangeEvent(prop, this[prop]));
    });
    this.dispatchEvent(new FlowNavigationNextEvent());
  }
}