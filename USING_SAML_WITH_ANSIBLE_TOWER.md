<!-- https://www.ansible.com/blog/using-saml-with-red-hat-ansible-tower -->

Getting AWX to interoperate with IBM Cloud Identity SAML requires both systems to have values from each other. 

## Defined in AWX, needed by IBM Cloud Identity:

- Provider ID
- Assertion Consumer Service URL (HTTP-POST)
- Service Provider SSO URL

## Defined in IBM Cloud Identity, needed by AWX:

- entity_id
- url
- X.509 Certificate

# How to configure AWX and IBM Cloud Identity
## AWX
### (Settings --> System)

- Set the `Base URL of the Tower Host` 
<p align="center">
  <img width="75%" src="./USING_SAML_WITH_ANSIBLE_TOWER.images/image1.png">
</p>

### (Settings --> Authentication)
- Set the Saml Service Provider Entity ID 
- AWX ACS URL is auto-generated in tower by concatenating Host + /sso/complete/saml/
<p align="center">
  <img width="75%" src="./USING_SAML_WITH_ANSIBLE_TOWER.images/image2.png">
</p>

To summarize, there are now two fields in AWX that will be used by IBM Cloud Identity

| Ansible Tower Field | Value |
|---------------------|-------|
| ACS URL	            | https://awx.domain.nl/sso/complete/saml/
| Entity ID*          | awx.domain.nl

* You can set Entity ID to whatever you want.

Information in this step will not be used in IBM Cloud Identity, but we need to do it anyway in order to make things work anyway.

On the command-line run:
```
openssl req -new -x509 -days 365 -nodes -out saml.crt -keyout saml.key
```

- Paste the contents of saml.crt into the `SAML Service Provider Public Certificate` box
- Paste the contents of saml.key into the `SAML Service Provider Private Key` box
- Save it

<p align="center">
  <img width="75%" src="./USING_SAML_WITH_ANSIBLE_TOWER.images/image4.png">
</p>

There are some boxes left to fill in for the SAML section of the authentication page in Ansible Tower. 

<p align="center">
  <img width="75%" src="./USING_SAML_WITH_ANSIBLE_TOWER.images/image7.png">
</p>


#### SAML Service Provider Organization Info 
```
{
  "en-US": {
    "url": "https://domain.nl",
    "displayname": "",
    "name": ""
  }
}
```

#### SAML Service Provider Technical Contact
```
{
  "givenName": "",
  "emailAddress": ""
}
```

#### SAML Service Provider Support Contact
```
{
  "givenName": "",
  "emailAddress": ""
}
```

#### SAML Enabled Idenity Providers
```
{
 "idp": {
  "attr_last_name": "family_name",
  "attr_first_name": "given_name",
  "attr_username": "preferred_username",
  "entity_id": "https://tentant.ice.ibmcloud.com/saml/sps/saml20ip/saml20",
  "url": "https://tenant.ice.ibmcloud.com/saml/sps/saml20ip/saml20/login",
  "attr_user_permanent_id": "userID",
  "x509cert": "MIIDKDCCAhCgAwIBAgIECPYTzTANBgkqhk............",
  "attr_email": "userID"
 }
}
```

#### Org Mapping
```
{
  "Default": {
    "users": true
  }
}
```

Finished! Now you can login via Ansible Tower’s UI with any user accounts that you normally login with via SAML and they will be automatically imported to Ansible Tower. The section below walks through some common errors that you may run into along the way and reasons for these errors.
