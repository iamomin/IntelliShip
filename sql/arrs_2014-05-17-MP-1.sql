/* Creates a new UPS2 ratetype to use with the API */
INSERT into ratetype values ('UPS2RATINGAPI',NULL,'UPS2 Ship Manager Server API','UPS2',0);

UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='upsndair00000';
UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='upsndairsaver';
UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='ups2dayairam0';
UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='ups2dayair000';
UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='ups3dayselect';
UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='upsground0000';
UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='upsndearlyam0';
UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='upsexpressplu';
UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='upsexpress000';
UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='upssaver00000';
UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='upsexpedited0';
UPDATE customerservice set ratetypeid='UPS2RATINGAPI' where customerserviceid='upsstandard00';