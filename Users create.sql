create user auction
identified by oracle
default tablespace users
quota unlimited on users
temporary tablespace temp;

grant create session, create procedure, create sequence, create table, create trigger, create view, create role to auction;
/
grant drop any procedure, drop any sequence, drop any table, drop any trigger, drop any view, drop any index to auction;
/
grant execute any procedure to auction;
/
grant execute on sys.dbms_lock to auction;
/
grant insert any table to auction;
/
grant select any table, select any sequence to auction;
/
grant alter database, alter user, alter tablespace, alter any procedure, alter any role, alter any sequence, alter any table, alter any trigger, alter any index to auction;
/
commit;

drop user auction cascade;