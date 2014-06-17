UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFEDGROU';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFEDGROU';
INSERT INTO servicecsdata VALUES ('SPRIMETGROUN0',4,'SPRINTFEDGROU',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFEDSAVE';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFEDSAVE';
INSERT INTO servicecsdata VALUES ('SPRIMETSAVER0',4,'SPRINTFEDSAVE',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED2DAY';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED2DAY';
INSERT INTO servicecsdata VALUES ('SPRIMET2DAY00',4,'SPRINTFED2DAY',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFEDPOOV';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFEDPOOV';
INSERT INTO servicecsdata VALUES ('SPRIMETPOOV00',4,'SPRINTFEDPOOV',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0000';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0000';
INSERT INTO servicecsdata VALUES ('SPRIMET000000',4,'SPRINTFED0000',2,'meternumber','307045','now',NULL);

DELETE FROM servicecsdata where ownertypeid=3 and ownerid in ('0000000000201','0000000000202','0000000000203') and datatypename='aggregateweightcost';

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0001';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0001';
INSERT INTO servicecsdata VALUES ('SPRIMET000001',4,'SPRINTFED0001',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0002';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0002';
INSERT INTO servicecsdata VALUES ('SPRINTFEDM002',4,'SPRINTFED0002',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0003';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0003';
INSERT INTO servicecsdata VALUES ('SPRINTFEDM003',4,'SPRINTFED0003',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0004';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0004';
INSERT INTO servicecsdata VALUES ('SPRINTFEDM004',4,'SPRINTFED0004',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0005';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0005';
INSERT INTO servicecsdata VALUES ('SPRINTFEDM005',4,'SPRINTFED0005',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0006';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0006';
INSERT INTO servicecsdata VALUES ('SPRINTFEDM006',4,'SPRINTFED0006',2,'meternumber','307045','now',NULL);

/* Creates a new ratetype to use with the API */
INSERT into ratetype values ('FDXSHPSERVAPI',NULL,'FedEx Ship Manager Server API','FEDEX',0);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFEDGROU';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFEDGROU';
INSERT INTO servicecsdata VALUES ('SPRIMETGROUN0',4,'SPRINTFEDGROU',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFEDSAVE';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFEDSAVE';
INSERT INTO servicecsdata VALUES ('SPRIMETSAVER0',4,'SPRINTFEDSAVE',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED2DAY';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED2DAY';
INSERT INTO servicecsdata VALUES ('SPRIMET2DAY00',4,'SPRINTFED2DAY',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFEDPOOV';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFEDPOOV';
INSERT INTO servicecsdata VALUES ('SPRIMETPOOV00',4,'SPRINTFEDPOOV',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0000';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0000';
INSERT INTO servicecsdata VALUES ('SPRIMET000000',4,'SPRINTFED0000',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0000';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0000';
INSERT INTO servicecsdata VALUES ('SPRIMET000000',4,'SPRINTFED0000',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0001';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0001';
INSERT INTO servicecsdata VALUES ('SPRIMET000001',4,'SPRINTFED0001',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0002';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0002';
INSERT INTO servicecsdata VALUES ('SPRINTFEDM002',4,'SPRINTFED0002',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0003';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0003';
INSERT INTO servicecsdata VALUES ('SPRINTFEDM003',4,'SPRINTFED0003',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0004';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0004';
INSERT INTO servicecsdata VALUES ('SPRINTFEDM004',4,'SPRINTFED0004',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0005';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0005';
INSERT INTO servicecsdata VALUES ('SPRINTFEDM005',4,'SPRINTFED0005',2,'meternumber','307045','now',NULL);

UPDATE customerservice set ratetypeid='FDXSHPSERVAPI' where customerserviceid='SPRINTFED0006';
UPDATE customerservice set webaccount='188214380' where customerserviceid='SPRINTFED0006';
INSERT INTO servicecsdata VALUES ('SPRINTFEDM006',4,'SPRINTFED0006',2,'meternumber','307045','now',NULL);

