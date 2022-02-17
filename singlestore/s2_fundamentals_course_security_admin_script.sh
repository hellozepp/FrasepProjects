sdb-admin change-root-password –all --password <NEWPASSWORD>
GRANT SELECT on mydb.* TO user1 
IDENTIFIED BY 'sdb';
set global sync_permissions = ON;

ALTER USER user1 SET FAILED_LOGIN_ATTEMPTS = 4
PASSWORD_LOCKOUT_TIME = 14400;
ALTER USER user1 ACCOUNT UNLOCK;
