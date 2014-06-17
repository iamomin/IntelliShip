/* To delete existing records from servicecsdata table for matching serviceid from service table.*/

DELETE FROM servicecsdata WHERE servicecsdataid IN (SELECT csd.servicecsdataid FROM ((servicecsdata csd INNER JOIN customerservice cs ON csd.ownerid = cs.customerserviceid) INNER JOIN service s ON cs.serviceid = s.serviceid ) INNER JOIN carrier c ON s.carrierid = c.carrierid AND c.carriername = 'FedEx' AND csd.datatypename = 'dimfactor' AND csd.ownertypeid = '4');


/* Update value of DIM factor to 166 for domestic. */ 

UPDATE servicecsdata SET value = '166' where servicecsdataid IN (select csd.servicecsdataid from (servicecsdata csd INNER JOIN service s ON csd.ownerid = s.serviceid)INNER JOIN carrier c ON s.carrierid = c.carrierid AND c.carriername = 'FedEx' AND csd.datatypename = 'dimfactor' AND csd.ownertypeid = '3' AND s.international = '0');


/* Update value of DIM factor to 139 for international. */

UPDATE servicecsdata SET value = '139' where servicecsdataid IN (select csd.servicecsdataid from (servicecsdata csd INNER JOIN service s ON csd.ownerid = s.serviceid) INNER JOIN carrier c ON s.carrierid = c.carrierid AND c.carriername = 'FedEx' AND csd.datatypename = 'dimfactor' AND csd.ownertypeid = '3' AND s.international = '1');
