cas casauto;

proc cas;
	action search.searchIndex / 
		index={name='VIYALOGS', caslib='SystemData'}, 
		json='{"query":
				{"andquery":[
					{"rangefilter":{"field":"datetime","gte":"2022-01-04T20:36:12Z","lte":"2022-01-04T21:06:12Z"}},
					{"simplequery":{"query":"\"[\"viyademo01\",\"action\"]\"","operator":"and","fields":["message"]}}]}}', 
		jsonOut=false,
		casOut={name='LevelCounts', caslib='SystemData', replace=true};
quit;



cas _all_ terminate;
