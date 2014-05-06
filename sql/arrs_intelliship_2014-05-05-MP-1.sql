/* USPS - Priority Mail - Flat Rate Envelope */

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000008', 'Priority Mail - Flat Rate Envelope', 'handler_local_usps.pl', '0', '1','USPSPMFRE',2,8);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEUSPSPFR','0000000000001','USPS000000008','9999999999990','QUOTERATING01');

/* USPS - Priority Mail - Padded Flat Rate Envelope */

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000009', 'Priority Mail - Padded Flat Rate Envelope', 'handler_local_usps.pl', '0', '1','USPSPMPFRE',2,8);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEUPMPFRE','0000000000001','USPS000000009','9999999999990','QUOTERATING01');

/* USPS - Priority Mail - Small Flat Rate Box */

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000010', 'Priority Mail - Small Flat Rate Box', 'handler_local_usps.pl', '0', '1','USPSPMSFRB',2,8);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEUPMSFRB','0000000000001','USPS000000010','9999999999990','QUOTERATING01');

/* USPS - Priority Mail - Medium Flat Rate Boxes */

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000011', 'Priority Mail - Medium Flat Rate Boxes', 'handler_local_usps.pl', '0', '1','USPSPMMFRB',2,8);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEUPMMFRB','0000000000001','USPS000000011','9999999999990','QUOTERATING01');

/* USPS - Priority Mail - Large Flat Rate Box */

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000012', 'Priority Mail - Large Flat Rate Box', 'handler_local_usps.pl', '0', '1','USPSPMLFRB',2,8);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEUPMLFRB','0000000000001','USPS000000012','9999999999990','QUOTERATING01');

/* USPS - Priority Mail Express - Flat Rate Envelope */


INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000013', 'Priority Mail Express - Flat Rate Envelope', 'handler_local_usps.pl', '0', '1','USPSPMEFRE',2,8);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEUPMEFRE','0000000000001','USPS000000013','9999999999990','QUOTERATING01');

/* USPS - Priority Mail Express - Padded Flat Rate Envelope */

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000014', 'Priority Mail Express - Padded Flat Rate Envelope', 'handler_local_usps.pl', '0', '1','USPSPMEPFRE',2,8);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEPMEPFRE','0000000000001','USPS000000014','9999999999990','QUOTERATING01');

/* USPS - Priority Mail Express - Flat Rate Boxes */

INSERT INTO service (carrierid, serviceid, servicename, webhandlername, international, modetypeid,servicecode,timeneededmin,timeneededmax) VALUES ('USPS000000001', 'USPS000000015', 'Priority Mail Express - Flat Rate Boxes', 'handler_local_usps.pl', '0', '1','USPSPMESFRB',2,8);

INSERT INTO customerservice (customerserviceid,customerid,serviceid,zonetypeid,ratetypeid) VALUES ('ENGAGEPMESFRB','0000000000001','USPS000000015','9999999999990','QUOTERATING01');