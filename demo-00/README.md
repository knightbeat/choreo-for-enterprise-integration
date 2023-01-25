# choreo-for-enterprise-integration

### Salesforce account
#####Generate Access Token
######With VS Code REST Client
```
@sf_user=user@org.com
@sf_password=pWd****
@sf_client_id=3M******XS
@sf_client_secret=CE******25

# @name createToken
POST https://login.salesforce.com/services/oauth2/token 
Content-Type: application/x-www-form-urlencoded

grant_type=password&client_id={{sf_client_id}}&client_secret={{sf_client_secret}}&username={{sf_user}}&password={{sf_password}}

###
@sf_token={{createToken.response.body.access_token}}
@sf_instance_url={{createToken.response.body.instance_url}}

```
**or with cURL**
```
curl -v https://login.salesforce.com/services/oauth2/token \
     -d "grant_type=password" \
     -d "client_id=3M******XS" \
     -d "client_secret=CE******25" \
     -d "username=user@org.com" \
     -d "password=pWd****"
```
You will recieve this
```
{
  "access_token": "00******DL",
  "instance_url": "https://<your-domain>.my.salesforce.com",
  "id": "https://login.salesforce.com/id/0***A",
  "token_type": "Bearer",
  "issued_at": "16****15",
  "signature": "cQm****jgI="
}
```
**Optional:** Check the latest API version and set the version number acordingly (note: `@sf_api_version=56.0`)
```
### Salesforce API version
GET {{sf_instance_url}}/services/data
Authorization: Bearer {{sf_token}}

###

@sf_api_version=56.0
```

Use the Token to create an Account on Salesforce
```
# @name createAccount
POST https://demoteam-dev-ed.my.salesforce.com/services/data/v56.0/sobjects/Account
Content-Type: application/json
Authorization: Bearer {{sf_token}}

{
    "Name":"WSO2 Choreo Demo"
}

###

@sf_account_id={{createAccount.response.body.$.id}}
```
Create a contact in using the `id` returned by the Account creation (note `@sf_account_id`)
```
###
POST https://demoteam-dev-ed.my.salesforce.com/services/data/v56.0/sobjects/Contact
Content-Type: application/json
Authorization: Bearer {{sf_token}}

{
    "FirstName": "Jessy",
    "LastName": "Pinkman",
    "AccountId": "{{sf_account_id}}",
    "Title": "Mr",
    "Email": "jessey@demoteam.com",
    "Phone": "+447428254632"
}
```
List Contacts and verify the Salesforce REST API access
```
###
GET https://demoteam-dev-ed.my.salesforce.com/services/data/v56.0/sobjects/Contact
Authorization: Bearer {{sf_token}}
```