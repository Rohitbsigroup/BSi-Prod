import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import login from '@salesforce/apex/PortalAccessController.login';

export default class PortalAccessComponent extends LightningElement {
 
    currentPageReference = null; 
    urlStateParameters = null;
    username = null;
    password = null;
    errorMessage = '';
    isLoading = true;
 
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('##### getStateParameters');
       if (currentPageReference) {
          this.urlStateParameters = currentPageReference.state;
          this.setParametersBasedOnUrl();
       }
    }
 
    setParametersBasedOnUrl() {
       this.username = this.urlStateParameters.un || null;
       this.password = this.urlStateParameters.pw || null;
       this.errorMessage = '';
       if(this.username && this.password){
            login({
                username: this.username,
                password : this.password
            }).then( result => {
                if(result.isSuccess){
                    this.isLoading = false;
                    window.location = result.returnUrl;
                } else {
                    this.errorMessage = result.errorMessage;
                    this.isLoading = false;
                }
            }).catch( error => {
                this.errorMessage = error;
                this.isLoading = false;
            });
       } else {
           this.errorMessage = 'Username or password empty.';
       }
    }
}