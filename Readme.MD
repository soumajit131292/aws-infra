Create secret in aws secret manager fro Aurora RDS:

aws secretsmanager create-secret   --name dev/aurora/app-credentials   --description "Aurora DB app credentials"   --secret-string '{
    "username":"app_user",
    "password":"StrongPaAs0w0rd123"
  }'

