/*
customerid = '8ETK66F1SSJLY', '8ETK66F0Z35K5'
carrierid = 'UPSFREIGHT000'
serviceid = 'UPSFREIGHT000'
*/
INSERT INTO zonetype (typeid, serviceid, zonetypename, lookuptype) values ('UPSFREIGHT000', 'UPSFREIGHT000', 'UPS FREIGHT ZONES', '2');
INSERT INTO zonetype (typeid, serviceid, zonetypename, lookuptype) values ('UPSFREIGHT001', 'UPSFREIGHT000', 'UPS FREIGHT ZONES CANADA', '3');

INSERT INTO customerservice (customerserviceid,serviceid,zonetypeid,ratetypeid,customerid) VALUES ('AMFUPSFRT0001','UPSFREIGHT000','UPSFREIGHT000','CZ00020140430','8ETK66F0Z35K5');
INSERT INTO customerservice (customerserviceid,serviceid,zonetypeid,ratetypeid,customerid) VALUES ('AMFUPSFRT0002','UPSFREIGHT000','UPSFREIGHT000','CZ00020140430','8ETK66F1SSJLY');


INSERT INTO customerservice (customerserviceid,serviceid,zonetypeid,ratetypeid,customerid) VALUES ('AMFUPSFRTCN01','UPSFREIGHT000','UPSFREIGHT001','CZ00020140430','8ETK66F0Z35K5');
INSERT INTO customerservice (customerserviceid,serviceid,zonetypeid,ratetypeid,customerid) VALUES ('AMFUPSFRTCN02','UPSFREIGHT000','UPSFREIGHT001','CZ00020140430','8ETK66F1SSJLY');


insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000001','UPSFREIGHT000','VA','PA','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000002','UPSFREIGHT000','VA','AZ','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000003','UPSFREIGHT000','VA','FL','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000004','UPSFREIGHT000','VA','MT','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000005','UPSFREIGHT000','VA','LA','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000006','UPSFREIGHT000','VA','GU','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000007','UPSFREIGHT000','VA','NM','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000008','UPSFREIGHT000','VA','AK','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000009','UPSFREIGHT000','VA','NC','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000010','UPSFREIGHT000','VA','OR','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000011','UPSFREIGHT000','VA','VT','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000012','UPSFREIGHT000','VA','MS','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000013','UPSFREIGHT000','VA','AR','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000014','UPSFREIGHT000','VA','IL','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000015','UPSFREIGHT000','VA','MO','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000016','UPSFREIGHT000','VA','IN','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000017','UPSFREIGHT000','VA','HI','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000018','UPSFREIGHT000','VA','WY','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000019','UPSFREIGHT000','VA','UT','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000020','UPSFREIGHT000','VA','MI','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000021','UPSFREIGHT000','VA','KS','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000022','UPSFREIGHT000','VA','MD','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000023','UPSFREIGHT000','VA','VI','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000024','UPSFREIGHT000','VA','GA','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000025','UPSFREIGHT000','VA','MN','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000026','UPSFREIGHT000','VA','WI','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000027','UPSFREIGHT000','VA','DC','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000028','UPSFREIGHT000','VA','NE','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000029','UPSFREIGHT000','VA','OH','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000030','UPSFREIGHT000','VA','CT','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000031','UPSFREIGHT000','VA','NV','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000032','UPSFREIGHT000','VA','PR','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000033','UPSFREIGHT000','VA','OK','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000034','UPSFREIGHT000','VA','AL','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000035','UPSFREIGHT000','VA','CA','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000036','UPSFREIGHT000','VA','CO','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000037','UPSFREIGHT000','VA','ND','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000038','UPSFREIGHT000','VA','WV','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000039','UPSFREIGHT000','VA','DE','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000040','UPSFREIGHT000','VA','WA','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000041','UPSFREIGHT000','VA','KY','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000042','UPSFREIGHT000','VA','ME','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000043','UPSFREIGHT000','VA','RI','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000044','UPSFREIGHT000','VA','VA','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000045','UPSFREIGHT000','VA','SD','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000046','UPSFREIGHT000','VA','TN','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000047','UPSFREIGHT000','VA','NH','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000048','UPSFREIGHT000','VA','IA','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000049','UPSFREIGHT000','VA','SC','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000050','UPSFREIGHT000','VA','NY','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000051','UPSFREIGHT000','VA','MA','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000052','UPSFREIGHT000','VA','ID','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000053','UPSFREIGHT000','VA','TX','1');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000054','UPSFREIGHT000','VA','NJ','1');

insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000055','UPSFREIGHT000','PA','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000056','UPSFREIGHT000','AZ','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000057','UPSFREIGHT000','FL','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000058','UPSFREIGHT000','MT','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000059','UPSFREIGHT000','LA','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000060','UPSFREIGHT000','GU','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000061','UPSFREIGHT000','NM','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000062','UPSFREIGHT000','AK','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000063','UPSFREIGHT000','NC','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000064','UPSFREIGHT000','OR','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000065','UPSFREIGHT000','VT','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000066','UPSFREIGHT000','MS','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000067','UPSFREIGHT000','AR','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000068','UPSFREIGHT000','IL','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000069','UPSFREIGHT000','MO','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000070','UPSFREIGHT000','IN','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000071','UPSFREIGHT000','HI','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000072','UPSFREIGHT000','WY','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000073','UPSFREIGHT000','UT','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000074','UPSFREIGHT000','MI','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000075','UPSFREIGHT000','KS','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000076','UPSFREIGHT000','MD','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000077','UPSFREIGHT000','VI','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000078','UPSFREIGHT000','GA','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000079','UPSFREIGHT000','MN','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000080','UPSFREIGHT000','WI','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000081','UPSFREIGHT000','DC','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000082','UPSFREIGHT000','NE','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000083','UPSFREIGHT000','OH','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000084','UPSFREIGHT000','CT','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000085','UPSFREIGHT000','NV','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000086','UPSFREIGHT000','PR','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000087','UPSFREIGHT000','OK','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000088','UPSFREIGHT000','AL','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000089','UPSFREIGHT000','CA','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000090','UPSFREIGHT000','CO','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000091','UPSFREIGHT000','ND','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000092','UPSFREIGHT000','WV','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000093','UPSFREIGHT000','DE','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000094','UPSFREIGHT000','WA','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000095','UPSFREIGHT000','KY','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000096','UPSFREIGHT000','ME','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000097','UPSFREIGHT000','RI','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000098','UPSFREIGHT000','VA','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000099','UPSFREIGHT000','SD','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000100','UPSFREIGHT000','TN','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000101','UPSFREIGHT000','NH','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000102','UPSFREIGHT000','IA','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000103','UPSFREIGHT000','SC','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000104','UPSFREIGHT000','NY','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000105','UPSFREIGHT000','MA','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000106','UPSFREIGHT000','ID','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000107','UPSFREIGHT000','TX','VA','2');
insert into zone (zoneid,typeid,originstate,deststate,zonenumber) values ('UPSFRT0000108','UPSFREIGHT000','NJ','VA','2');

insert into zone (zoneid,typeid,origincountry,destcountry,zonenumber) values ('UPSFRT0000109','UPSFREIGHT001','US','CN','1');

insert into ratedata (ratedataid, ownertypeid, ownerid, unitsstart, unitsstop, ardiscount, armin, zone) values ('AMFUPSFRT0001','4','AMFUPSFRT0001', 0,999999,'0.7', '65', '1');
insert into ratedata (ratedataid, ownertypeid, ownerid, unitsstart, unitsstop, ardiscount, armin, zone) values ('AMFUPSFRT0002','4','AMFUPSFRT0001', 0,999999,'0.7', '65', '2');
insert into ratedata (ratedataid, ownertypeid, ownerid, unitsstart, unitsstop, ardiscount, armin, zone) values ('AMFUPSFRT0003','4','AMFUPSFRT0002', 0,999999,'0.7', '65', '1');
insert into ratedata (ratedataid, ownertypeid, ownerid, unitsstart, unitsstop, ardiscount, armin, zone) values ('AMFUPSFRT0004','4','AMFUPSFRT0002', 0,999999,'0.7', '65', '2');
insert into ratedata (ratedataid, ownertypeid, ownerid, unitsstart, unitsstop, ardiscount, armin, zone) values ('AMFUPSFRT0005','4','AMFUPSFRTCN01', 0,999999,'0.7', '92.5', '1');
insert into ratedata (ratedataid, ownertypeid, ownerid, unitsstart, unitsstop, ardiscount, armin, zone) values ('AMFUPSFRT0006','4','AMFUPSFRTCN02', 0,999999,'0.7', '92.5', '1');