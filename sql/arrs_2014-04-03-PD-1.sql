INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode) VALUES ('USPS000000001', 'USPS000000003', 'First-Class', 'handler_local_usps.pl', '0', '1','USPSF');

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid) VALUES ('ENGAGEUSPSF00','0000000000001','USPS000000003','9999999999990');

UPDATE customerservice SET ratetypeid = 'QUOTERATING01' WHERE customerserviceid = 'ENGAGEUSPSF00'

UPDATE service SET timeneededmin = 1 WHERE serviceid = 'USPS000000003'

UPDATE service SET timeneededmax = 3 WHERE serviceid = 'USPS000000003'

INSERT INTO servicecsdata (servicecsdataid,ownertypeid,ownerid,datatypeid,datatypename,value) VALUES ('USPSFCLSMAXWT','3','USPS000000003','2','maxpackageweight','')

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000002', 'Standard Post', 'handler_local_usps.pl', '0', '1','USTPO',2,8);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEUSPSSTP','0000000000001','USPS000000002','9999999999990','QUOTERATING01');

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000004', 'Priority Mail Express', 'handler_local_usps.pl', '0', '1','UPME',1,3);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEUSPSPME','0000000000001','USPS000000004','9999999999990','QUOTERATING01');

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000005', 'Priority Mail', 'handler_local_usps.pl', '0', '1','UPRIORITY',1,3);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEUSPSPRM','0000000000001','USPS000000005','9999999999990','QUOTERATING01');

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000006', 'Media Mail', 'handler_local_usps.pl', '0', '1','USPSMM',2,8);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEUSPSMM0','0000000000001','USPS000000006','9999999999990','QUOTERATING01');

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000007', 'Library Mail', 'handler_local_usps.pl', '0', '1','USPSLM',2,8);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEUSPSLM0','0000000000001','USPS000000007','9999999999990','QUOTERATING01');








