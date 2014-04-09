CREATE TABLE statelist ( statelistid character(13) NOT NULL, counrtyiso2 character(2), statename character varying(100), stateiso2 character(2), stateiso3 character(3), CONSTRAINT statelist_pkey PRIMARY KEY (statelistid) ) WITH ( OIDS=FALSE );
ALTER TABLE statelist OWNER TO postgres;
GRANT ALL ON TABLE statelist TO postgres; GRANT ALL ON TABLE statelist TO webuser;

COPY statelist from STDIN;
21000	CA	Alberta	AB	AB
21100	CA	British Columbia	BC	BC
21200	CA	Manitoba	MB	MB
21300	CA	New Brunswick	NB	NB
21400	CA	Newfoundland	NL	NL
21450	CA	Labrador	NL	NL
21500	CA	Nova Scotia	NS	NS
21600	CA	Northwest Territories	NT	NT
21700	CA	Nunavut	NU	NU
21800	CA	Ontario	ON	ON
21900	CA	Prince Edward Island	PE	PE
22000	CA	Quebec	QC	QC
22100	CA	Saskatchewan	SK	SK
22200	CA	Yukon	YT	YT
12300	US	Alabama	AL	ALA
12400	US	Alaska	AK	ALK
12500	US	Arizona	AZ	ARZ
12600	US	Arkansas	AR	ARK
12700	US	California	CA	CAL
12800	US	Colorado	CO	COL
12900	US	Connecticut	CT	CON
13000	US	Delaware	DE	DEL
13100	US	District of Columbia	DC	DC
13200	US	Florida	FL	FLA
13300	US	Georgia	GA	GA
13400	US	Hawaii	HI	HAW
13500	US	Idaho	ID	IDA
13600	US	Illinois	IL	ILL
13700	US	Indiana	IN	IND
13800	US	Iowa	IA	IOW
13900	US	Kansas	KS	KAN
14000	US	Kentucky	KY	KY
14100	US	Louisiana	LA	LA
14200	US	Maine	ME	MAI
14300	US	Maryland	MD	MD
14400	US	Massachusetts	MA	MAS
14500	US	Michigan	MI	MIC
14600	US	Minnesota	MN	MIN
14700	US	Mississippi	MS	MIS
14800	US	Missouri	MO	MO
14900	US	Montana	MT	MON
15000	US	Nebraska	NE	NEB
15100	US	Nevada	NV	NEV
15200	US	New Hampshire	NH	NH
15300	US	New Jersey	NJ	NJ
15400	US	New Mexico	NM	NM
15500	US	New York	NY	NY
15600	US	North Carolina	NC	NC
15700	US	North Dakota	ND	ND
15800	US	Ohio	OH	OHI
15900	US	Oklahoma	OK	OKL
16000	US	Oregon	OR	ORE
16100	US	Pennsylvania	PA	PA
16200	US	Rhode Island	RI	RI
16300	US	South Carolina	SC	SC
16400	US	South Dakota	SD	SD
16500	US	Tennessee	TN	TEN
16600	US	Texas	TX	TEX
16700	US	Utah	UT	UTA
16800	US	Vermont	VT	VT
16900	US	Virginia	VA	VA
17000	US	Washington	WV	WAS
17100	US	West Virginia	WA	WV
17200	US	Wisconsin	WI	WIS
17300	US	Wyoming	WY	WYO
17400	MX	Aguascalientes	AG	AGU
17500	MX	Baja California	BC	BCN
17600	MX	Baja California Sur	BS	BCS
17700	MX	Campeche	CM	CAM
17800	MX	Chiapas	CS	CHP
17900	MX	Chihuahua	CH	CHH
18000	MX	Coahuila	CO	COA
18100	MX	Colima	CL	COL
18200	MX	Federal District	DF	DIF
18300	MX	Durango	DG	DUR
18400	MX	Guanajuato	GT	GUA
18500	MX	Guerrero	GR	GRO
18600	MX	Hidalgo	HG	HID
18700	MX	Jalisco	JA	JAL
18800	MX	Mexico State	ME	MEX
18900	MX	Michoac?	MI	MIC
19000	MX	Morelos	MO	MOR
19100	MX	Nayarit	NA	NAY
19200	MX	Nuevo Le??	NL	NLE
19300	MX	Oaxaca	OA	OAX
19400	MX	Puebla	PU	PUE
19500	MX	Quer?ro	QE	QUE
19600	MX	Quintana Roo	QR	ROO
19700	MX	San Luis Potos?	SL	SLP
19800	MX	Sinaloa	SI	SIN
19900	MX	Sonora	SO	SON
20000	MX	Tabasco	TB	TAB
20100	MX	Tamaulipas	TM	TAM
20200	MX	Tlaxcala	TL	TLA
20300	MX	Veracruz	VE	VER
20400	MX	Yucat?	YU	YUC
20500	MX	Zacatecas	ZA	ZAC
