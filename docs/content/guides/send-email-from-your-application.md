# How to send email from your application deployed on OpenShift
For OpenShift a mail connector is created. Everyone who deploys an application on OpenShift may use this connector.
To use this connector you need to request credentials via Topdesk. With this request you need to provide the email address of the owner of the application. 
The owner of the application will be contacted in case of any issues/questions from the team that manages the mail connector.

## Request credentials
To request credentials for the mail connector, please create a ticket in Topdesk. You may copy/paste the following text and update it accordingly:

```text
Beste,

Via deze weg wil ik graag credentials aanvragen om te kunnen mailen vanuit mijn applicatie welke gedeployed is op OpenShift.
De eigenaar van deze applicatie is: <emailadres>

Alvast bedankt!
```

## Using the mail connector
The mail connector is available on the following: 

| SMTP server | Port | TLS/SSL |
|-------------|------|---------|
| smtp.uu.nl  | 587  | STARTTLS |

You can use the mail connector in your application by configuring it to use the SMTP server `smtp.uu.nl` on port `587` with STARTTLS enabled.

