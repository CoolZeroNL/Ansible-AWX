<!--https://www.unixarena.com/2018/12/ansible-tower-awx-store-credential-custom-credentials-type.html/-->

Input:
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

Injector:
```
extra_vars:
  Jenkins_username: '{{ username }}'
  Jenkins_password: '{{ password }}'
```
