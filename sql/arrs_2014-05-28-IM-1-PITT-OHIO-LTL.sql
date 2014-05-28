/*

Carrier    : Pitt-Ohio Express
carrierid  : PITTOHIOEXPRS
Service    : LTL
serviceid  : PITTOHIOEXPRL
customerid : 8ETK66F1SSJLY,8ETK66F0Z35K5

customerserviceid: AMFPITTOHIO01,AMFPITTOHIO02
zonetypeid : PITTOHIOZONE1
ratetypeid : CZ00020140430 (CZarlite LTL Rates)

*/

INSERT INTO zonetype (typeid,serviceid,zonetypename,logiczonetable,lookuptype) VALUES ('PITTOHIOZONE1','PITTOHIOEXPRL','Pitt-Ohio Trucking Zone',NULL,2);

INSERT INTO customerservice (customerserviceid,serviceid,customerid,ratetypeid,zonetypeid) VALUES ('AMFPITTOHIO01','PITTOHIOEXPRL','8ETK66F0Z35K5','CZ00020140430','PITTOHIOZONE1');
INSERT INTO customerservice (customerserviceid,serviceid,customerid,ratetypeid,zonetypeid) VALUES ('AMFPITTOHIO02','PITTOHIOEXPRL','8ETK66F1SSJLY','CZ00020140430','PITTOHIOZONE1');

INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE01','PITTOHIOZONE1','VA','MD', 1);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE02','PITTOHIOZONE1','VA','PA', 2);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE03','PITTOHIOZONE1','VA','NJ', 3);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE04','PITTOHIOZONE1','VA','MI', 4);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE05','PITTOHIOZONE1','VA','VA', 5);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE06','PITTOHIOZONE1','OH','VA', 6);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE07','PITTOHIOZONE1','IL','VA', 7);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE08','PITTOHIOZONE1','KY','VA', 8);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE09','PITTOHIOZONE1','MI','VA', 9);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE10','PITTOHIOZONE1','IN','VA',10);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE11','PITTOHIOZONE1','MD','VA',11);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE12','PITTOHIOZONE1','PA','VA',12);
INSERT INTO zone (zoneid,typeid,originstate,deststate,zonenumber) VALUES ('AMFPTOHZONE13','PITTOHIOZONE1','NJ','VA',13);

INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0001','4','AMFPITTOHIO01','0.815','63','1');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0002','4','AMFPITTOHIO01','0.815','63','2');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0003','4','AMFPITTOHIO01','0.815','63','3');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0004','4','AMFPITTOHIO01','0.715','93','4');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0005','4','AMFPITTOHIO01','0.815','63','5');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0006','4','AMFPITTOHIO01','0.770','65','6');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0007','4','AMFPITTOHIO01','0.740','75','7');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0008','4','AMFPITTOHIO01','0.740','75','8');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0009','4','AMFPITTOHIO01','0.740','75','9');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0010','4','AMFPITTOHIO01','0.740','75','10');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0011','4','AMFPITTOHIO01','0.815','63','11');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0012','4','AMFPITTOHIO01','0.815','63','12');
INSERT INTO ratedata (ratedataid,ownertypeid,ownerid,ardiscount,armin,zone) VALUES ('AMFPTOHRD0013','4','AMFPITTOHIO01','0.815','63','13');
