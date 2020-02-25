<!-- https://www.ansible.com/blog/using-saml-with-red-hat-ansible-tower -->

<!-- TOC -->

- [1. Defined](#1-defined)
    - [1.1. Defined in AWX, needed by IBM Cloud Identity:](#11-defined-in-awx-needed-by-ibm-cloud-identity)
    - [1.2. Defined in IBM Cloud Identity, needed by AWX:](#12-defined-in-ibm-cloud-identity-needed-by-awx)
- [2. How to configure AWX and IBM Cloud Identity](#2-how-to-configure-awx-and-ibm-cloud-identity)
    - [2.1. AWX](#21-awx)
        - [2.1.1. (Settings --> System)](#211-settings----system)
        - [2.1.2. (Settings --> Authentication)](#212-settings----authentication)
            - [2.1.2.1. SAML Service Provider Organization Info](#2121-saml-service-provider-organization-info)
            - [2.1.2.2. SAML Service Provider Technical Contact](#2122-saml-service-provider-technical-contact)
            - [2.1.2.3. SAML Service Provider Support Contact](#2123-saml-service-provider-support-contact)
            - [2.1.2.4. SAML Enabled Idenity Providers](#2124-saml-enabled-idenity-providers)
            - [2.1.2.5. Org Mapping](#2125-org-mapping)
        - [2.1.3. Additional Samle Options/Samples:](#213-additional-samle-optionssamples)
            - [2.1.3.1. SAML Enabled Idenity Providers](#2131-saml-enabled-idenity-providers)
            - [2.1.3.2. SAML Organisation MAP](#2132-saml-organisation-map)
            - [2.1.3.3. SAML TEAM MAP](#2133-saml-team-map)
            - [2.1.3.4. SAML Team Attribute Mapping](#2134-saml-team-attribute-mapping)

<!-- /TOC -->

Getting AWX to interoperate with IBM Cloud Identity SAML requires both systems to have values from each other. 
# 1. Defined
## 1.1. Defined in AWX, needed by IBM Cloud Identity:

- Provider ID
- Assertion Consumer Service URL (HTTP-POST)
- Service Provider SSO URL

## 1.2. Defined in IBM Cloud Identity, needed by AWX:

- entity_id
- url
- X.509 Certificate

# 2. How to configure AWX and IBM Cloud Identity
## 2.1. AWX
### 2.1.1. (Settings --> System)

- Set the `Base URL of the Tower Host` 
<p align="center">
  <img width="75%" src="./USING_SAML_WITH_ANSIBLE_TOWER.images/image1.png">
</p>

### 2.1.2. (Settings --> Authentication)
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

There are some boxes left to fill in for the SAML section of the authentication page in AWX. 

<p align="center">
  <img width="75%" src="./USING_SAML_WITH_ANSIBLE_TOWER.images/image7.png">
</p>


#### 2.1.2.1. SAML Service Provider Organization Info 
```
{
  "en-US": {
    "url": "https://domain.nl",
    "displayname": "",
    "name": ""
  }
}
```

#### 2.1.2.2. SAML Service Provider Technical Contact
```
{
  "givenName": "",
  "emailAddress": ""
}
```

#### 2.1.2.3. SAML Service Provider Support Contact
```
{
  "givenName": "",
  "emailAddress": ""
}
```

#### 2.1.2.4. SAML Enabled Idenity Providers
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

#### 2.1.2.5. Org Mapping
```
{
  "Default": {
    "users": true
  }
}
```


### 2.1.3. Additional Samle Options/Samples:
Regex in this samples need to be checked...

Issues:
- https://github.com/ansible/awx/issues/5303  (Flagging users as superusers and auditors in SAML integration)
- 

#### 2.1.3.1. SAML Enabled Idenity Providers
```
{
 "saml_ms_adfs": {
  "attr_last_name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname",
  "entity_id": "http://signin.server.com/adfs/services/trust",
  "x509cert": "<redacted>",
  "url": "https://signin.server.com/adfs/ls/",
  "attr_username": "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname",
  "attr_email": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
  "attr_first_name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname",
  "attr_user_permanent_id": "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname"
 }
}
```

#### 2.1.3.2. SAML Organisation MAP
```
{
 "Default": {
  "users": true
 },
 "Test Org": {
  "users": true,
  "admins": [
   "admin@example.com"
  ]
 },
 "Test Org 2": {
  "users": "/^[^@].*?@example\\.com$/",
  "admins": [
   "admin@example.com",
   "/^tower-[^@]+?@.*$/i"
  ]
 }
}
```

#### 2.1.3.3. SAML TEAM MAP
```
{
    "My Team": {
        "organization": "Test Org",
        "users": ["/^[^@]+?@test\\.example\\.com$/"],
        "remove": true
    },
    "Other Team": {
        "organization": "Test Org 2",
        "users": ["/^[^@]+?@test\\.example\\.com$/"],
        "remove": false
    }
}
```

#### 2.1.3.4. SAML Team Attribute Mapping
```
{
 "team_org_map": [
  {
   "organization": "Default",
   "team": "awx-admins"
  }
 ],
 "saml_attr": "groupIds",
 "remove": true
}
```

or

This need chanes to sso/pipeline.py and sso/fields.py
```
{
 "team_org_map": [
  {
   "organization": "awx-members",
   "team": "awx-members"
  },
  {
   "admins": true,
   "organization": "awx-admins",
   "team": "awx-admins"
  },
  {
   "superusers": true,
   "organization": "awx-superusers",
   "team": "awx-superusers"
  }
 ],
 "admins_remove": true,
 "remove": true,
 "saml_attr": "groupIds",
 "superusers_remove": true
}
```



Finished! Now you can login via AWX’s UI with any user accounts that you normally login with via SAML and they will be automatically imported to AWX.
