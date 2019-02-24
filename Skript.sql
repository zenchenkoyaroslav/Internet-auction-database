set serveroutput on;
create table Regions(
  RegionId    number(5) primary key,
  RegionName  varchar2(20) not null
);
/
create sequence Region_Seq
increment by 1
start with 2
maxvalue 10
minvalue 2
nocycle;
/
create table Countries(
  CountryID   number(5) primary key,
  RegionId    number(5) references Regions (RegionID),
  CountryName  varchar2(30) not null
);
/
create sequence Countries_Seq
increment by 1
start with 1
maxvalue 1000
minvalue 1
nocycle;
/
create table Cities(
  CityID    number(5) primary key,
  CityName  varchar2(30) not null,
  CountryID number(5) references Countries(CountryID)
);
/
create sequence Cities_Seq
increment by 1
start with 126
maxvalue 1000
minvalue 126
nocycle;
/
create table AuctionUsers(
  UserLogin   varchar2(30) primary key,
  UserPassword  varchar2(30) not null,
  CityID      number(5) references Cities(CityID)
);
/
create table Categories(
  CategoryID    number(5) primary key,
  CategoryName  char(50) not null
);
/
create sequence Categories_Seq
increment by 1
start with 1
maxvalue 1000
minvalue 1
nocycle;
/
create table Lots(
  LotID       number(10) primary key,
  CategoryID  number(5) references Categories(CategoryID),
  LotName     char(40) not null,
  LotDescription char(200),
  SlayerLogin varchar2(30) references AuctionUsers (UserLogin),
  lSold     number(1) check (lSold in (0,1))
);
/
create sequence Lot_Seq
increment by 1
start with 1
maxvalue 10000
minvalue 1
nocycle;
/

create table Photos(
  PhotoID   number(10) primary key,
  LotID     number(10) references Lots(LotID),
  Photo     varchar(50)
);
/
create sequence Photos_Seq
increment by 1
start with 1
maxvalue 10000
minvalue 1
nocycle;
/
create table Bidding(
  ByuerLogin    varchar2(30) null references AuctionUsers(UserLogin),
  LotID         number(10) not null references Lots(LotID),
  bDateTime     date,
  bPrice        number(6),
  bSold         number(1) check (bSold in (0,1))
)
/
create package auc_pack as
    procedure AddUser ( UserLogin varchar2, UserPassword varchar2, CityID number );
    procedure AddLot (CategoryID number, LotName char, LotDescription char, SlayerLogin varchar2);
    procedure LotToBidding (p_LotID number, p_Price number);
    procedure UpdatePrice (Byuer varchar2, p_LotID number, p_Price number);
    procedure SoldLot (p_LotID number);
end auc_pack;
/
create package body auc_pack as

procedure AddUser ( UserLogin varchar2, UserPassword varchar2, CityID number )
is
begin
  insert into AuctionUsers values (userlogin, userpassword, cityid);
end AddUser;

procedure AddLot (CategoryID number, LotName char, LotDescription char, SlayerLogin varchar2)
is
begin
  insert into lots values (lot_seq.nextval, CategoryID, LotName, LotDescription, slayerlogin, 0);
end AddLot;

procedure LotToBidding (p_LotID number, p_Price number)
is
  e_LotIsAlredyOnBidding exception;
  e_LotIsNotExists exception;
  v_is_alredy_on_bidding number(1);
  v_is_not_exists number(1);
begin
  select count(*) 
  into v_is_not_exists
  from Lots where p_LotID = LotID;
  if v_is_not_exists = 0 then
    raise e_LotIsNotExists;
  end if;
  select count(*)
  into v_is_alredy_on_bidding
  from bidding where p_LotID = LotID;
  if v_is_alredy_on_bidding > 0 then
    raise e_LotIsAlredyOnBidding;
  end if;
  insert into Bidding values (null, p_LotID, sysdate, p_Price, 0);
exception
  when e_LotIsNotExists then
    dbms_output.put_line('Invalid lot');
  when e_LotIsAlredyOnBidding then
    dbms_output.put_line('This lot is alredy on bidding');
end LotToBidding;

procedure UpdatePrice (Byuer varchar2, p_LotID number, p_Price number)
is
  e_LotIsNotOnBidding exception;
  e_LotIsNotExists exception;
  e_ByuerIsNotExists exception;
  v_is_not_on_bidding number(1);
  v_is_not_exists number(1);
  v_is_not_buyer number(1);
begin
  select count(*) 
  into v_is_not_exists
  from Lots where p_lotid = lotid;
  if v_is_not_exists = 0 then
    raise e_LotIsNotExists;
  end if;
  select count(*)
  into v_is_not_on_bidding
  from bidding where p_lotid = lotid;
  if v_is_not_on_bidding = 0 then 
    raise e_LotIsNotOnBidding;
  end if;
  select count(*)
  into v_is_not_buyer
  from auctionusers where byuer = userlogin;
  if v_is_not_buyer = 0 then
    raise e_ByuerIsNotExists;
  end if;
  
  
  insert into Bidding values (Byuer, p_LotID, sysdate, p_Price, 0);
exception
  when e_LotIsNotExists then
    dbms_output.put_line('Invalid lot');
  when e_LotIsNotOnBidding then
    dbms_output.put_line('This lot is not on bidding');
  when e_ByuerIsNotExists then
    dbms_output.put_line('Invalid byuer');
end UpdatePrice;

procedure SoldLot (p_LotID number)
is
  e_LotIsNotOnBidding exception;
  e_LotIsNotExists exception;
  v_is_not_on_bidding number(1);
  v_is_not_exists number(1);
  v_byuerlogin  varchar2(30);
  v_lotid number(10);
  v_bprice number(6);
begin
  select count(*) 
  into v_is_not_exists
  from Lots where p_lotid = lotid;
  if v_is_not_exists = 0 then
    raise e_LotIsNotExists;
  end if;
  select count(*)
  into v_is_not_on_bidding
  from bidding where p_lotid = lotid;
  if v_is_not_on_bidding = 0 then 
    raise e_LotIsNotOnBidding;
  end if;
  
  select byuerlogin, lotid, bprice
  into v_byuerlogin, v_lotid, v_bprice
  from Bidding
  where lotid = p_lotid and bdatetime = (
                    select max(bdatetime)
                    from bidding
                    where lotid = p_lotid
                );
                
  insert into bidding values (v_byuerlogin, v_lotid, sysdate, v_bprice, 1);
exception
  when e_LotIsNotExists then
    dbms_output.put_line('Invalid lot');
  when e_LotIsNotOnBidding then
    dbms_output.put_line('This lot is not on bidding');
end SoldLot;
end auc_pack;
/
create or replace trigger ValidBidding
before insert on Bidding
for each row
declare
  v_buyer   varchar2(30);
  v_saler   varchar2(30);
  v_sold    number(1);
  v_price   number(6);
  v_lot     number(10);
  v_lot_is_sold number(1);
  v_max_price number(6);
begin
  v_buyer := :new.byuerlogin;
  v_sold := :new.bsold;
  v_price := :new.bprice;
  v_lot := :new.lotid;
  select slayerlogin
  into v_saler
  from Lots
  where lotid = v_lot;
  select lsold into v_lot_is_sold from lots where v_lot = lotid;
  select MAX(bprice) into v_max_price from bidding where v_lot = lotid;
  if v_buyer = v_saler then
    raise_application_error(-20001, 'Buyer is saler');
  end if;
  if v_lot_is_sold = 1 then
    raise_application_error(-20002, 'Lot had alredy gone');
  end if;
  if v_price < v_max_price then
    raise_application_error(-20003, 'Give price more then last');
  end if;
  if (v_price - v_max_price) > 1000 then
    raise_application_error(-20003, 'Give less price');
  end if;
  if v_sold = 1 then
    update Lots
    set lsold = 1
    where LotID = v_lot;
  end if;
end;
/
create or replace function check_state (p_id Lots.Lotid%TYPE)
return varchar2 
is
  v_state number(1);
begin
  select lsold
  into v_state
  from Lots where lotid = p_id;
  if (v_state = 0) then
    return 'Not sold';  
  else 
    return 'Sold';
  end if;
end;
/
create view LotsList(Name, Description, Saler, Category, State)
  as
  select l.lotname, l.lotdescription, l.slayerlogin, ca.categoryname, check_state(l.lotid)
  from lots l join categories ca
          on l.categoryid = ca.categoryid;
/
create view SoldLotsList (Name, Saler, Byuer, Time)
  as
  select l.lotname, l.slayerlogin, b.byuerlogin, b.bdatetime
  from lots l join bidding b
          on l.lotid = b.lotid and bsold = 1
  where l.lsold = 1;
/
create view NotSoldLotsList (Name, Description, Saler, Category)
  as
  select name, description, saler, category
  from LotsList
  where state = 'Not sold';
/
create view UserList (Login, City)
  as
  select au.userlogin, ci.cityname
  from auctionusers au join cities ci
            on au.cityid = ci.cityid;
/
create view BiddingList (name, saler, byuer, time, price, state)
  as
  select l.lotname, l.slayerlogin, b.byuerlogin, b.bdatetime, b.bdatetime, check_state(l.lotid)
  from lots l join bidding b on l.lotid = b.lotid
  where b.bdatetime = (select max(b1.bdatetime) from bidding b1 where b.lotid = b1.lotid);

insert into regions values (region_seq.nextval, 'Europe');
insert into regions values (region_seq.nextval, 'Asia');
insert into regions values (region_seq.nextval, 'Australia');
insert into regions values (region_seq.nextval, 'America');
insert into countries values (countries_seq.nextval, 4, 'Kazkhstan');
insert into countries values (countries_seq.nextval, 4, 'Chaina');
insert into countries values (countries_seq.nextval, 4, 'Turki');
insert into countries values (countries_seq.nextval, 4, 'Japen');
insert into countries values (countries_seq.nextval, 4, 'North Korea');
insert into countries values (countries_seq.nextval, 4, 'South Korea');
insert into countries values (countries_seq.nextval, 3, 'Italy');
insert into countries values (countries_seq.nextval, 3, 'Poland');
insert into countries values (countries_seq.nextval, 3, 'Switzerland');
insert into countries values (countries_seq.nextval, 3, 'England');
insert into countries values (countries_seq.nextval, 3, 'Germany');
insert into countries values (countries_seq.nextval, 3, 'Spane');
insert into countries values (countries_seq.nextval, 3, 'France');
insert into countries values (countries_seq.nextval, 3, 'Austria');
insert into countries values (countries_seq.nextval, 5, 'Australia');
insert into countries values (countries_seq.nextval, 6, 'USA');
insert into countries values (countries_seq.nextval, 6, 'Kanada');
insert into countries values (countries_seq.nextval, 6, 'Brazil');
insert into countries values (countries_seq.nextval, 6, 'Mexico');
insert into cities values (cities_seq.nextval, 'Almaty', 2);
insert into cities values (cities_seq.nextval, 'Astana', 2);
insert into cities values (cities_seq.nextval, 'Karaganda', 2);
insert into cities values (cities_seq.nextval, 'Kustanay', 2);
insert into cities values (cities_seq.nextval, 'Uralsk', 2);
insert into cities values (cities_seq.nextval, 'Bejing', 3);
insert into cities values (cities_seq.nextval, 'Nankin', 3);
insert into cities values (cities_seq.nextval, 'Urumchi', 3);
insert into cities values (cities_seq.nextval, 'Shanhai', 3);
insert into cities values (cities_seq.nextval, 'Stambul', 4);
insert into cities values (cities_seq.nextval, 'Antalia', 4);
insert into cities values (cities_seq.nextval, 'Tokio', 5);
insert into cities values (cities_seq.nextval, 'Seul', 6);
insert into cities values (cities_seq.nextval, 'Rome', 8);
insert into cities values (cities_seq.nextval, 'Florence', 8);
insert into cities values (cities_seq.nextval, 'Venice', 8);
insert into cities values (cities_seq.nextval, 'Varshava', 9);
insert into cities values (cities_seq.nextval, 'Krakov', 9);
insert into cities values (cities_seq.nextval, 'Vroclav', 9);
insert into cities values (cities_seq.nextval, 'Bern', 10);
insert into cities values (cities_seq.nextval, 'Zurich', 10);
insert into cities values (cities_seq.nextval, 'Geneva', 10);
insert into cities values (cities_seq.nextval, 'London', 11);
insert into cities values (cities_seq.nextval, 'Bath', 11);
insert into cities values (cities_seq.nextval, 'Cardiff', 11);
insert into cities values (cities_seq.nextval, 'Berlin', 12);
insert into cities values (cities_seq.nextval, 'Gamburg', 12);
insert into cities values (cities_seq.nextval, 'Munhen', 12);
insert into cities values (cities_seq.nextval, 'Madrid', 13);
insert into cities values (cities_seq.nextval, 'Parice', 14);
insert into cities values (cities_seq.nextval, 'Leon', 14);
insert into cities values (cities_seq.nextval, 'Vena', 15);
insert into cities values (cities_seq.nextval, 'Canberra', 16);
insert into cities values (cities_seq.nextval, 'New-York', 17);
insert into cities values (cities_seq.nextval, 'New-Orlean', 17);
insert into cities values (cities_seq.nextval, 'Los-Angeles', 17);
insert into cities values (cities_seq.nextval, 'Detroid', 17);
insert into cities values (cities_seq.nextval, 'Ottava', 18);
insert into cities values (cities_seq.nextval, 'Toronto', 18);
insert into cities values (cities_seq.nextval, 'Rio de Janeiro', 19);
insert into cities values (cities_seq.nextval, 'Brazilia', 19);
insert into cities values (cities_seq.nextval, 'Mehico', 20);
commit;
execute auc_pack.adduser('Yaroslav', 'jsdifjdslf', 127);
execute auc_pack.adduser('Artem', 'dfmgkldmf', 127);
execute auc_pack.adduser('Aidar', 'djfilsdfj', 127);
execute auc_pack.adduser('Adilkhan', 'sdfdsg', 128);
execute auc_pack.adduser('Zhuldyz', 'dfgfsf', 129);
execute auc_pack.adduser('Aleksey', 'jkhjhj,', 130);
execute auc_pack.adduser('Elzhan', 'zsrdsyt', 131);
execute auc_pack.adduser('Da', 'l78j5tehd', 132);
execute auc_pack.adduser('Ki', 'srtes645y', 133);
execute auc_pack.adduser('Ju', 'dsyd32534', 134);
execute auc_pack.adduser('Ksu', 'gjhkj', 135);
execute auc_pack.adduser('Batur', 'mgfdg', 136);
execute auc_pack.adduser('Aisu', 'sadfsdf', 137);
execute auc_pack.adduser('Ayaka', 'jkhjud', 138);
execute auc_pack.adduser('Than', 'seww', 139);
execute auc_pack.adduser('Vittorio', 'dfsdf', 140);
execute auc_pack.adduser('Ezio', 'asaas', 141);
execute auc_pack.adduser('Leonardo', 'jhkuh', 142);
execute auc_pack.adduser('Andjei', 'gdgfdsfs', 143);
execute auc_pack.adduser('Antoni', 'fhgjdgf', 144);
execute auc_pack.adduser('Josef', 'hkjkhj', 145);
execute auc_pack.adduser('Karl', 'fgjgh', 146);
execute auc_pack.adduser('Han', 'dfgdfghf', 147);
execute auc_pack.adduser('Rozi', 'dfhf', 148);
execute auc_pack.adduser('Jessica', 'dfhfhfj', 149);
execute auc_pack.adduser('Sam', 'dgffd', 150);
execute auc_pack.adduser('Iwan', 'sfdsfs', 151);
execute auc_pack.adduser('Adolf', 'sdfsdf', 152);
execute auc_pack.adduser('Wolf', 'djhkjhgfd', 153);
execute auc_pack.adduser('Johan', 'gfhj,hfgd', 154);
execute auc_pack.adduser('Marta', 'hkjkhj', 155);
execute auc_pack.adduser('Albert', 'dsgh', 156);
execute auc_pack.adduser('Admon', 'shdg', 157);
execute auc_pack.adduser('Amadeus', 'lliljk', 158);
execute auc_pack.adduser('Charlie', 'dfghfdassd', 159);
execute auc_pack.adduser('Chris', 'djkhj', 160);
execute auc_pack.adduser('Jecky', 'khjkhj', 161);
execute auc_pack.adduser('Kirk', 'dfhfgh', 162);
execute auc_pack.adduser('Duglas', 'dgjgf', 163);
execute auc_pack.adduser('Felix', 'khjkhj', 164);
execute auc_pack.adduser('Gabriel', 'hgdfsgd', 165);
execute auc_pack.adduser('Lucas', 'fgjgd', 166);
execute auc_pack.adduser('Ernest', 'dfggf', 167);
execute auc_pack.adduser('Paolo', 'khjkhj', 168);
commit;
insert into categories values (categories_seq.nextval, 'Collection');
insert into categories values (categories_seq.nextval, 'Housekeeping equipment');
insert into categories values (categories_seq.nextval, 'Books');
insert into categories values (categories_seq.nextval, 'Computers and electronics');
insert into categories values (categories_seq.nextval, 'Automobiles and com[lecting');
insert into categories values (categories_seq.nextval, 'For children');
insert into categories values (categories_seq.nextval, 'Art');
insert into categories values (categories_seq.nextval, 'Bijouterie');
insert into categories values (categories_seq.nextval, 'Others');
execute auc_pack.addlot (2, 'Ancient coins', 'Very, very ancient', 'Artem');
execute auc_pack.addlot (3, 'vacuum cleaner', 'Very, very vacuum', 'Elzhan');
execute auc_pack.addlot (4, 'Murakami completed', 'Very, very completed', 'Ayaka');
execute auc_pack.addlot (5, 'Videocard', 'Very, very powerfull', 'Antoni');
execute auc_pack.addlot (6, 'Motor for Toyota', 'New', 'Da');
execute auc_pack.addlot (7, 'Sand by Brookstone', 'Its a magic', 'Aleksey');
execute auc_pack.addlot (8, 'Mona Liza', 'Not stolen', 'Leonardo');
execute auc_pack.addlot (9, 'Ring', 'My precious', 'Charlie');
execute auc_pack.addlot (10, 'Biorobot', 'Living', 'Chris');
insert into photos values (photos_seq.nextval, 2, 'image_1');
insert into photos values (photos_seq.nextval, 3, 'image_2');
insert into photos values (photos_seq.nextval, 4, 'image_4');
insert into photos values (photos_seq.nextval, 4, 'image_5');
insert into photos values (photos_seq.nextval, 6, 'image_6');
insert into photos values (photos_seq.nextval, 7, 'image_7');
insert into photos values (photos_seq.nextval, 8, 'image_8');
insert into photos values (photos_seq.nextval, 9, 'image_9');
commit;
begin
 auc_pack.lottobidding (2, 1500);
 dbms_lock.sleep(2);
 auc_pack.lottobidding(3, 9000);
 dbms_lock.sleep(2);
 auc_pack.updateprice('Ksu', 2, 2000);
 dbms_lock.sleep(2);
 auc_pack.updateprice('Yaroslav', 2, 2500);
 dbms_lock.sleep(2);
 auc_pack.soldlot (2);
 dbms_lock.sleep(2);
 auc_pack.lottobidding (4, 1500);
 dbms_lock.sleep(2);
 auc_pack.lottobidding (5, 1500);
 dbms_lock.sleep(2);
 auc_pack.updateprice('Artem', 4, 2000);
 dbms_lock.sleep(2);
 auc_pack.updateprice('Da', 5, 2000);
 dbms_lock.sleep(2);
 auc_pack.updateprice('Da', 5, 2000);
 dbms_lock.sleep(2);
 auc_pack.soldlot (4);
 dbms_lock.sleep(2);
 auc_pack.updateprice('Adolf', 5, 5000);
 dbms_lock.sleep(2);
 auc_pack.soldlot (5);
 dbms_lock.sleep(2);
 auc_pack.lottobidding(8, 4000);
 dbms_lock.sleep(2);
 auc_pack.updateprice('Andjei', 8, 5000);
 commit;
end;

set serveroutput on;

declare
  cursor user_cur is
    select *
    from userlist
    order by city;
  v_us  user_cur%rowtype;
begin
  open user_cur;
  loop
    exit when user_cur%notfound;
    fetch user_cur into v_us;
    dbms_output.put_line(v_us.login || ' ' || v_us.city);
  end loop;
end;


execute auc_pack.updateprice('Batur', 8, 6000);