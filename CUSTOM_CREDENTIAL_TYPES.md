<!--https://www.unixarena.com/2018/12/ansible-tower-awx-store-credential-custom-credentials-type.html/-->


Inputs define the value types that are used for this credential – such as a username, a password, a token, or any other identifier that’s part of the credential.
Injectors describe how these credentials are exposed for Ansible to use – this can be Ansible extra variables, environment variables, or templated file content.


# Jenkins Credentials Type
## Input:
```
fields:
  - type: string
    id: username
    label: Jenkins username

  - type: string
    id: password
    label: "Jenkins password"
    secret: True

required:
  - username
  - password
```

## Injector:
```
extra_vars:
  Jenkins_username: '{{ username }}'
  Jenkins_password: '{{ password }}'
```
